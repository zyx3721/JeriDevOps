package handler

import (
	"devops/internal/service/kubernetes"
	"devops/pkg/response"
	"net/http"
	"strconv"

	_ "devops/pkg/dto" // swagger 文档需要

	"github.com/gin-gonic/gin"
)

// K8sMetricsHandler K8s 资源监控处理器
type K8sMetricsHandler struct {
	metricsService kubernetes.K8sMetricsService
}

// NewK8sMetricsHandler 创建 K8s 资源监控处理器
func NewK8sMetricsHandler(metricsSvc kubernetes.K8sMetricsService) *K8sMetricsHandler {
	return &K8sMetricsHandler{
		metricsService: metricsSvc,
	}
}

// GetPodMetrics 获取 Pod 资源指标
// @Summary 获取 Pod 资源指标
// @Tags K8s Metrics
// @Param id path int true "集群ID"
// @Param ns path string true "命名空间"
// @Param name path string true "Pod名称"
// @Success 200 {object} response.Response{data=dto.PodMetricsResponse}
// @Router /api/v1/k8s/clusters/{id}/namespaces/{ns}/pods/{name}/metrics [get]
func (h *K8sMetricsHandler) GetPodMetrics(c *gin.Context) {
	clusterID, _ := strconv.ParseUint(c.Param("id"), 10, 32)
	namespace := c.Param("ns")
	name := c.Param("name")

	metrics, err := h.metricsService.GetPodMetrics(c.Request.Context(), uint(clusterID), namespace, name)
	if err != nil {
		response.Error(c, http.StatusInternalServerError, err.Error())
		return
	}

	response.Success(c, metrics)
}

// GetPodListMetrics 获取命名空间下所有 Pod 的资源指标
// @Summary 获取 Pod 列表资源指标
// @Tags K8s Metrics
// @Param id path int true "集群ID"
// @Param ns path string true "命名空间"
// @Success 200 {object} response.Response{data=dto.PodMetricsListResponse}
// @Router /api/v1/k8s/clusters/{id}/namespaces/{ns}/metrics/pods [get]
func (h *K8sMetricsHandler) GetPodListMetrics(c *gin.Context) {
	clusterID, _ := strconv.ParseUint(c.Param("id"), 10, 32)
	namespace := c.Param("ns")

	metrics, err := h.metricsService.GetPodListMetrics(c.Request.Context(), uint(clusterID), namespace)
	if err != nil {
		response.Error(c, http.StatusInternalServerError, err.Error())
		return
	}

	response.Success(c, metrics)
}

// GetNodeMetrics 获取节点资源指标
// @Summary 获取节点资源指标
// @Tags K8s Metrics
// @Param id path int true "集群ID"
// @Success 200 {object} response.Response{data=dto.NodeMetricsListResponse}
// @Router /api/v1/k8s/clusters/{id}/metrics/nodes [get]
func (h *K8sMetricsHandler) GetNodeMetrics(c *gin.Context) {
	clusterID, _ := strconv.ParseUint(c.Param("id"), 10, 32)

	metrics, err := h.metricsService.GetNodeMetrics(c.Request.Context(), uint(clusterID))
	if err != nil {
		response.Error(c, http.StatusInternalServerError, err.Error())
		return
	}

	response.Success(c, metrics)
}

// CheckMetricsServer 检查 metrics-server 是否可用
// @Summary 检查 metrics-server 可用性
// @Tags K8s Metrics
// @Param id path int true "集群ID"
// @Success 200 {object} response.Response
// @Router /api/v1/k8s/clusters/{id}/metrics/status [get]
func (h *K8sMetricsHandler) CheckMetricsServer(c *gin.Context) {
	clusterID, _ := strconv.ParseUint(c.Param("id"), 10, 32)

	available, err := h.metricsService.IsMetricsServerAvailable(c.Request.Context(), uint(clusterID))
	if err != nil {
		response.Error(c, http.StatusInternalServerError, err.Error())
		return
	}

	response.Success(c, map[string]interface{}{
		"available": available,
		"message":   getMetricsStatusMessage(available),
	})
}

func getMetricsStatusMessage(available bool) string {
	if available {
		return "metrics-server 运行正常"
	}
	return "metrics-server 不可用，请确保已在集群中安装 metrics-server"
}
