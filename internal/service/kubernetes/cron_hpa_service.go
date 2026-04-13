package kubernetes

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"time"

	mysqlDriver "github.com/go-sql-driver/mysql"
	"github.com/robfig/cron/v3"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/types"

	"devops/internal/models"
	"devops/pkg/dto"
	apperrors "devops/pkg/errors"
	"devops/pkg/logger"

	"gorm.io/gorm"
)

// CronHPAService CronHPA 管理服务
type CronHPAService struct {
	db        *gorm.DB
	clientMgr *K8sClientManager
	scheduler *cron.Cron
	entries   map[string][]cron.EntryID // 记录每个 CronHPA 的调度任务 ID，key 为 "namespace/name"
}

// NewCronHPAService 创建 CronHPA 服务
func NewCronHPAService(db *gorm.DB, clientMgr *K8sClientManager) *CronHPAService {
	log := logger.L().WithField("module", "CronHPA")
	log.Info("初始化 CronHPA 服务")

	svc := &CronHPAService{
		db:        db,
		clientMgr: clientMgr,
		scheduler: cron.New(), // 使用标准5字段格式（分 时 日 月 周）
		entries:   make(map[string][]cron.EntryID),
	}
	// 启动调度器
	svc.scheduler.Start()
	log.Info("调度器已启动")

	// 加载所有启用的 CronHPA
	go svc.loadAndScheduleAll()
	return svc
}

// ListCronHPAs 获取 CronHPA 列表
func (s *CronHPAService) ListCronHPAs(ctx context.Context, clusterID uint, namespace string) ([]dto.K8sCronHPA, error) {
	var cronHPAs []models.CronHPA
	query := s.db.Where("cluster_id = ?", clusterID)
	if namespace != "" {
		query = query.Where("namespace = ?", namespace)
	}
	if err := query.Find(&cronHPAs).Error; err != nil {
		return nil, apperrors.Wrap(err, apperrors.ErrCodeDBQuery, "查询CronHPA失败")
	}

	result := make([]dto.K8sCronHPA, len(cronHPAs))
	for i, ch := range cronHPAs {
		var schedules []dto.CronSchedule
		if err := json.Unmarshal(ch.Schedules, &schedules); err != nil {
			schedules = []dto.CronSchedule{}
		}
		result[i] = dto.K8sCronHPA{
			Name:       ch.Name,
			Namespace:  ch.Namespace,
			TargetKind: ch.TargetKind,
			TargetName: ch.TargetName,
			Enabled:    ch.Enabled,
			Schedules:  schedules,
			CreatedAt:  ch.CreatedAt.Format("2006-01-02 15:04:05"),
		}
	}
	return result, nil
}

// GetCronHPA 获取单个 CronHPA
func (s *CronHPAService) GetCronHPA(ctx context.Context, clusterID uint, namespace, name string) (*dto.K8sCronHPA, error) {
	var cronHPA models.CronHPA
	if err := s.db.Where("cluster_id = ? AND namespace = ? AND name = ?", clusterID, namespace, name).First(&cronHPA).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, apperrors.New(apperrors.ErrCodeNotFound, "CronHPA不存在")
		}
		return nil, apperrors.Wrap(err, apperrors.ErrCodeDBQuery, "查询CronHPA失败")
	}

	var schedules []dto.CronSchedule
	if err := json.Unmarshal(cronHPA.Schedules, &schedules); err != nil {
		schedules = []dto.CronSchedule{}
	}

	return &dto.K8sCronHPA{
		Name:       cronHPA.Name,
		Namespace:  cronHPA.Namespace,
		TargetKind: cronHPA.TargetKind,
		TargetName: cronHPA.TargetName,
		Enabled:    cronHPA.Enabled,
		Schedules:  schedules,
		CreatedAt:  cronHPA.CreatedAt.Format("2006-01-02 15:04:05"),
	}, nil
}

// CreateCronHPA 创建 CronHPA
func (s *CronHPAService) CreateCronHPA(ctx context.Context, clusterID uint, req *dto.CreateCronHPARequest) error {
	// 验证 cron 表达式（支持标准5字段格式）
	parser := cron.NewParser(cron.Minute | cron.Hour | cron.Dom | cron.Month | cron.Dow)
	for _, schedule := range req.Schedules {
		if _, err := parser.Parse(schedule.Cron); err != nil {
			return apperrors.New(apperrors.ErrCodeInvalidParams, fmt.Sprintf("无效的cron表达式: %s (错误: %v)", schedule.Cron, err))
		}
	}

	schedulesJSON, err := json.Marshal(req.Schedules)
	if err != nil {
		return apperrors.Wrap(err, apperrors.ErrCodeInternalError, "序列化调度规则失败")
	}

	cronHPA := &models.CronHPA{
		ClusterID:  clusterID,
		Name:       req.Name,
		Namespace:  req.Namespace,
		TargetKind: req.TargetKind,
		TargetName: req.TargetName,
		Enabled:    req.Enabled,
		Schedules:  schedulesJSON,
	}

	if err := s.db.Create(cronHPA).Error; err != nil {
		return apperrors.Wrap(err, apperrors.ErrCodeDBQuery, "创建CronHPA失败")
	}

	// 如果启用，立即添加到调度器
	if req.Enabled {
		s.scheduleCronHPA(cronHPA)
	}

	return nil
}

// UpdateCronHPA 更新 CronHPA
func (s *CronHPAService) UpdateCronHPA(ctx context.Context, clusterID uint, namespace, name string, req *dto.UpdateCronHPARequest) error {
	// 验证 cron 表达式（支持标准5字段格式）
	parser := cron.NewParser(cron.Minute | cron.Hour | cron.Dom | cron.Month | cron.Dow)
	for _, schedule := range req.Schedules {
		if _, err := parser.Parse(schedule.Cron); err != nil {
			return apperrors.New(apperrors.ErrCodeInvalidParams, fmt.Sprintf("无效的cron表达式: %s (错误: %v)", schedule.Cron, err))
		}
	}

	var cronHPA models.CronHPA
	if err := s.db.Where("cluster_id = ? AND namespace = ? AND name = ?", clusterID, namespace, name).First(&cronHPA).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return apperrors.New(apperrors.ErrCodeNotFound, "CronHPA不存在")
		}
		return apperrors.Wrap(err, apperrors.ErrCodeDBQuery, "查询CronHPA失败")
	}

	schedulesJSON, err := json.Marshal(req.Schedules)
	if err != nil {
		return apperrors.Wrap(err, apperrors.ErrCodeInternalError, "序列化调度规则失败")
	}

	updates := map[string]interface{}{
		"enabled":   req.Enabled,
		"schedules": schedulesJSON,
	}

	if err := s.db.Model(&cronHPA).Updates(updates).Error; err != nil {
		return apperrors.Wrap(err, apperrors.ErrCodeDBQuery, "更新CronHPA失败")
	}

	// 重新调度
	s.rescheduleCronHPA(&cronHPA)

	return nil
}

// DeleteCronHPA 删除 CronHPA
func (s *CronHPAService) DeleteCronHPA(ctx context.Context, clusterID uint, namespace, name string) error {
	result := s.db.Where("cluster_id = ? AND namespace = ? AND name = ?", clusterID, namespace, name).Delete(&models.CronHPA{})
	if result.Error != nil {
		return apperrors.Wrap(result.Error, apperrors.ErrCodeDBQuery, "删除CronHPA失败")
	}
	if result.RowsAffected == 0 {
		return apperrors.New(apperrors.ErrCodeNotFound, "CronHPA不存在")
	}

	// 从调度器中移除对应的任务
	key := fmt.Sprintf("%s/%s", namespace, name)
	if entryIDs, ok := s.entries[key]; ok {
		log := logger.L().WithField("module", "CronHPA")
		for _, entryID := range entryIDs {
			s.scheduler.Remove(entryID)
			log.Info("移除调度任务: entryID=%d", entryID)
		}
		delete(s.entries, key)
		log.Info("CronHPA调度任务已清理: %s", key)
	}

	return nil
}

// scheduleCronHPA 将 CronHPA 添加到调度器
func (s *CronHPAService) scheduleCronHPA(cronHPA *models.CronHPA) {
	log := logger.L().WithFields(map[string]interface{}{
		"module":    "CronHPA",
		"namespace": cronHPA.Namespace,
		"name":      cronHPA.Name,
	})

	var schedules []dto.CronSchedule
	if err := json.Unmarshal(cronHPA.Schedules, &schedules); err != nil {
		log.WithError(err).Error("解析调度规则失败")
		return
	}

	key := fmt.Sprintf("%s/%s", cronHPA.Namespace, cronHPA.Name)
	var entryIDs []cron.EntryID

	log.Info("添加 %d 个调度任务", len(schedules))
	for _, schedule := range schedules {
		schedule := schedule
		entryID, err := s.scheduler.AddFunc(schedule.Cron, func() {
			s.executeSchedule(cronHPA.ClusterID, cronHPA.Namespace, cronHPA.TargetKind, cronHPA.TargetName, &schedule)
		})
		if err != nil {
			log.WithError(err).Error("添加调度任务失败: %s", schedule.Name)
		} else {
			entryIDs = append(entryIDs, entryID)
			log.Info("调度任务已添加: %s (cron=%s, entryID=%d)", schedule.Name, schedule.Cron, entryID)
		}
	}

	// 记录 entryIDs
	s.entries[key] = entryIDs
}

// rescheduleCronHPA 重新调度 CronHPA
func (s *CronHPAService) rescheduleCronHPA(cronHPA *models.CronHPA) {
	log := logger.L().WithField("module", "CronHPA")

	// 先移除旧的调度任务
	key := fmt.Sprintf("%s/%s", cronHPA.Namespace, cronHPA.Name)
	if entryIDs, ok := s.entries[key]; ok {
		for _, entryID := range entryIDs {
			s.scheduler.Remove(entryID)
		}
		delete(s.entries, key)
		log.Info("移除旧的调度任务: %s", key)
	}

	// 重新添加调度任务
	s.scheduleCronHPA(cronHPA)
}

// executeSchedule 执行调度任务
func (s *CronHPAService) executeSchedule(clusterID uint, namespace, targetKind, targetName string, schedule *dto.CronSchedule) {
	log := logger.L().WithFields(map[string]interface{}{
		"module":     "CronHPA",
		"cluster_id": clusterID,
		"namespace":  namespace,
		"target":     fmt.Sprintf("%s/%s", targetKind, targetName),
		"schedule":   schedule.Name,
	})

	log.Info("执行定时调度任务: min=%d, max=%d", schedule.MinReplicas, schedule.MaxReplicas)

	ctx := context.Background()
	client, err := s.clientMgr.GetClient(ctx, clusterID)
	if err != nil {
		log.WithError(err).Error("获取K8s客户端失败")
		return
	}

	// 先尝试查找关联到该资源的 HPA
	hpaList, err := client.AutoscalingV2().HorizontalPodAutoscalers(namespace).List(ctx, metav1.ListOptions{})
	var targetHPA string
	if err == nil {
		for _, hpa := range hpaList.Items {
			// 检查 HPA 的 scaleTargetRef 是否指向当前资源
			if hpa.Spec.ScaleTargetRef.Kind == targetKind && hpa.Spec.ScaleTargetRef.Name == targetName {
				targetHPA = hpa.Name
				log.Info("找到关联的HPA: %s", targetHPA)
				break
			}
		}
	}

	// 如果没找到，尝试使用与资源同名的 HPA
	if targetHPA == "" {
		targetHPA = targetName
		log.Info("未找到关联HPA，尝试使用同名HPA: %s", targetHPA)
	}

	// 更新 HPA 的 min/max 范围
	patch := fmt.Sprintf(`{"spec":{"minReplicas":%d,"maxReplicas":%d}}`, schedule.MinReplicas, schedule.MaxReplicas)
	_, patchErr := client.AutoscalingV2().HorizontalPodAutoscalers(namespace).Patch(
		ctx, targetHPA, types.MergePatchType, []byte(patch), metav1.PatchOptions{})

	if patchErr != nil {
		log.WithError(patchErr).Warn("HPA不存在，降级为直接设置副本数")

		// 如果 HPA 不存在，使用 min_replicas 作为目标副本数
		patch = fmt.Sprintf(`{"spec":{"replicas":%d}}`, schedule.MinReplicas)
		log.Info("设置副本数为 min_replicas: %d", schedule.MinReplicas)

		switch targetKind {
		case "Deployment":
			_, err := client.AppsV1().Deployments(namespace).Patch(ctx, targetName, types.StrategicMergePatchType, []byte(patch), metav1.PatchOptions{})
			if err != nil {
				log.WithError(err).Error("更新Deployment副本数失败")
				return
			}
			log.Info("Deployment副本数更新成功")
		case "StatefulSet":
			_, err := client.AppsV1().StatefulSets(namespace).Patch(ctx, targetName, types.StrategicMergePatchType, []byte(patch), metav1.PatchOptions{})
			if err != nil {
				log.WithError(err).Error("更新StatefulSet副本数失败")
				return
			}
			log.Info("StatefulSet副本数更新成功")
		default:
			log.Error("不支持的资源类型: %s", targetKind)
			return
		}
		return
	}

	log.Info("HPA更新成功: %s (min=%d, max=%d)", targetHPA, schedule.MinReplicas, schedule.MaxReplicas)
}

// loadAndScheduleAll 加载并调度所有启用的 CronHPA
func (s *CronHPAService) loadAndScheduleAll() {
	log := logger.L().WithField("module", "CronHPA")
	time.Sleep(2 * time.Second) // 等待数据库初始化

	var cronHPAs []models.CronHPA
	if err := s.db.Where("enabled = ?", true).Find(&cronHPAs).Error; err != nil {
		if isMySQLTableNotFound(err) {
			log.Warn("cron_hpa table is missing, skipping CronHPA bootstrap load until migrations are applied")
			return
		}
		log.WithError(err).Error("加载CronHPA失败")
		return
	}

	log.Info("加载到 %d 个启用的CronHPA", len(cronHPAs))
	for _, cronHPA := range cronHPAs {
		log.Info("调度CronHPA: %s/%s", cronHPA.Namespace, cronHPA.Name)
		s.scheduleCronHPA(&cronHPA)
	}
	log.Info("调度器启动完成")
}

// Stop 停止调度器
func (s *CronHPAService) Stop() {
	s.scheduler.Stop()
}

func isMySQLTableNotFound(err error) bool {
	var mysqlErr *mysqlDriver.MySQLError
	return errors.As(err, &mysqlErr) && mysqlErr.Number == 1146
}
