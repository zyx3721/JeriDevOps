package handler

import (
	"strconv"

	"github.com/gin-gonic/gin"

	"devops/internal/config"
	"devops/internal/service/pipeline"
	"devops/pkg/dto"
	"devops/pkg/ioc"
	"devops/pkg/middleware"
	"devops/pkg/response"
)

func init() {
	ioc.Api.RegisterContainer("PipelineHandler", &PipelineApiHandler{})
}

// PipelineApiHandler IOC容器注册的处理器
type PipelineApiHandler struct {
	handler *PipelineHandler
}

func (h *PipelineApiHandler) Init() error {
	cfg, err := config.LoadConfig()
	if err != nil {
		return err
	}

	db := cfg.GetDB()
	pipelineSvc := pipeline.NewPipelineService(db)
	runSvc := pipeline.NewRunService(db)
	templateSvc := pipeline.NewTemplateService(db)
	credentialSvc := pipeline.NewCredentialService(db)
	variableSvc := pipeline.NewVariableService(db)

	h.handler = NewPipelineHandler(pipelineSvc, runSvc, templateSvc, credentialSvc, variableSvc)

	root := cfg.Application.GinRootRouter().Group("pipelines")
	root.Use(middleware.AuthMiddleware())
	h.Register(root)

	return nil
}

func (h *PipelineApiHandler) Register(r gin.IRouter) {
	// 流水线管理
	r.GET("", h.handler.ListPipelines)
	r.GET("/:id", h.handler.GetPipeline)
	r.POST("", h.handler.CreatePipeline)
	r.PUT("/:id", h.handler.UpdatePipeline)
	r.DELETE("/:id", middleware.RequireAdmin(), h.handler.DeletePipeline)
	r.POST("/:id/toggle", h.handler.TogglePipeline)

	// 流水线执行
	r.POST("/:id/run", h.handler.RunPipeline)
	r.POST("/runs/:id/cancel", h.handler.CancelRun)
	r.POST("/runs/:id/retry", h.handler.RetryRun)

	// 执行历史
	r.GET("/runs", h.handler.ListRuns)
	r.GET("/runs/:id", h.handler.GetRun)
	r.GET("/runs/:id/steps/:step_id/logs", h.handler.GetStepLogs)

	// 统计
	r.GET("/stats", h.handler.GetStats)

	// 模板
	r.GET("/templates", h.handler.ListTemplates)
	r.GET("/templates/:id", h.handler.GetTemplate)
	r.POST("/from-template", h.handler.CreateFromTemplate)

	// 凭证
	r.GET("/credentials", h.handler.ListCredentials)
	r.POST("/credentials", middleware.RequireAdmin(), h.handler.CreateCredential)
	r.PUT("/credentials/:id", middleware.RequireAdmin(), h.handler.UpdateCredential)
	r.DELETE("/credentials/:id", middleware.RequireAdmin(), h.handler.DeleteCredential)

	// 变量
	r.GET("/variables", h.handler.ListVariables)
	r.POST("/variables", h.handler.CreateVariable)
	r.PUT("/variables/:id", h.handler.UpdateVariable)
	r.DELETE("/variables/:id", h.handler.DeleteVariable)
}

// PipelineHandler 流水线处理器
type PipelineHandler struct {
	pipelineSvc   *pipeline.PipelineService
	runSvc        *pipeline.RunService
	templateSvc   *pipeline.TemplateService
	credentialSvc *pipeline.CredentialService
	variableSvc   *pipeline.VariableService
}

// NewPipelineHandler 创建流水线处理器
func NewPipelineHandler(
	pipelineSvc *pipeline.PipelineService,
	runSvc *pipeline.RunService,
	templateSvc *pipeline.TemplateService,
	credentialSvc *pipeline.CredentialService,
	variableSvc *pipeline.VariableService,
) *PipelineHandler {
	return &PipelineHandler{
		pipelineSvc:   pipelineSvc,
		runSvc:        runSvc,
		templateSvc:   templateSvc,
		credentialSvc: credentialSvc,
		variableSvc:   variableSvc,
	}
}

// ListPipelines 获取流水线列表
// @Summary 获取流水线列表
// @Description 分页获取流水线列表，支持按名称、状态筛选
// @Tags Pipeline
// @Accept json
// @Produce json
// @Param page query int false "页码" default(1)
// @Param page_size query int false "每页数量" default(20)
// @Param name query string false "流水线名称（模糊搜索）"
// @Param status query string false "状态筛选"
// @Success 200 {object} response.Response{data=dto.PipelineListResponse}
// @Failure 400 {object} response.Response
// @Router /pipelines [get]
func (h *PipelineHandler) ListPipelines(c *gin.Context) {
	var req dto.PipelineListRequest
	if err := c.ShouldBindQuery(&req); err != nil {
		response.BadRequest(c, "参数错误")
		return
	}

	result, err := h.pipelineSvc.List(c.Request.Context(), &req)
	if err != nil {
		response.FromError(c, err)
		return
	}

	response.Success(c, result)
}

// GetPipeline 获取流水线详情
// @Summary 获取流水线详情
// @Description 根据ID获取流水线详细信息
// @Tags Pipeline
// @Accept json
// @Produce json
// @Param id path int true "流水线ID"
// @Success 200 {object} response.Response{data=dto.PipelineDetailResponse}
// @Failure 400 {object} response.Response
// @Failure 404 {object} response.Response
// @Router /pipelines/{id} [get]
func (h *PipelineHandler) GetPipeline(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		response.BadRequest(c, "无效的ID")
		return
	}

	result, err := h.pipelineSvc.Get(c.Request.Context(), uint(id))
	if err != nil {
		response.FromError(c, err)
		return
	}

	response.Success(c, result)
}

// CreatePipeline 创建流水线
// @Summary 创建流水线
// @Description 创建新的CI/CD流水线
// @Tags Pipeline
// @Accept json
// @Produce json
// @Param body body dto.PipelineRequest true "流水线配置"
// @Success 200 {object} response.Response
// @Failure 400 {object} response.Response
// @Router /pipelines [post]
func (h *PipelineHandler) CreatePipeline(c *gin.Context) {
	var req dto.PipelineRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "参数错误")
		return
	}

	// 验证配置
	if err := h.pipelineSvc.Validate(c.Request.Context(), &req); err != nil {
		response.BadRequest(c, err.Error())
		return
	}

	userID := c.GetUint("userID")
	if err := h.pipelineSvc.Create(c.Request.Context(), &req, userID); err != nil {
		response.FromError(c, err)
		return
	}

	response.SuccessWithMessage(c, "创建成功", nil)
}

// UpdatePipeline 更新流水线
// @Summary 更新流水线
// @Description 更新流水线配置
// @Tags Pipeline
// @Accept json
// @Produce json
// @Param id path int true "流水线ID"
// @Param body body dto.PipelineRequest true "流水线配置"
// @Success 200 {object} response.Response
// @Failure 400 {object} response.Response
// @Failure 404 {object} response.Response
// @Router /pipelines/{id} [put]
func (h *PipelineHandler) UpdatePipeline(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		response.BadRequest(c, "无效的ID")
		return
	}

	var req dto.PipelineRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "参数错误")
		return
	}
	req.ID = uint(id)

	// 验证配置
	if err := h.pipelineSvc.Validate(c.Request.Context(), &req); err != nil {
		response.BadRequest(c, err.Error())
		return
	}

	if err := h.pipelineSvc.Update(c.Request.Context(), &req); err != nil {
		response.FromError(c, err)
		return
	}

	response.SuccessWithMessage(c, "更新成功", nil)
}

// DeletePipeline 删除流水线
// @Summary 删除流水线
// @Description 删除指定的流水线（需要管理员权限）
// @Tags Pipeline
// @Accept json
// @Produce json
// @Param id path int true "流水线ID"
// @Success 200 {object} response.Response
// @Failure 400 {object} response.Response
// @Failure 403 {object} response.Response
// @Router /pipelines/{id} [delete]
func (h *PipelineHandler) DeletePipeline(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		response.BadRequest(c, "无效的ID")
		return
	}

	if err := h.pipelineSvc.Delete(c.Request.Context(), uint(id)); err != nil {
		response.FromError(c, err)
		return
	}

	response.SuccessWithMessage(c, "删除成功", nil)
}

// TogglePipeline 切换流水线状态
// @Summary 切换流水线状态
// @Description 启用或禁用流水线
// @Tags Pipeline
// @Accept json
// @Produce json
// @Param id path int true "流水线ID"
// @Success 200 {object} response.Response
// @Failure 400 {object} response.Response
// @Router /pipelines/{id}/toggle [post]
func (h *PipelineHandler) TogglePipeline(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		response.BadRequest(c, "无效的ID")
		return
	}

	if err := h.pipelineSvc.ToggleStatus(c.Request.Context(), uint(id)); err != nil {
		response.FromError(c, err)
		return
	}

	response.SuccessWithMessage(c, "操作成功", nil)
}

// RunPipeline 运行流水线
// @Summary 运行流水线
// @Description 手动触发流水线执行
// @Tags Pipeline
// @Accept json
// @Produce json
// @Param id path int true "流水线ID"
// @Param body body dto.RunPipelineRequest false "运行参数"
// @Success 200 {object} response.Response{data=dto.PipelineRunDetailResponse}
// @Failure 400 {object} response.Response
// @Router /pipelines/{id}/run [post]
func (h *PipelineHandler) RunPipeline(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		response.BadRequest(c, "无效的ID")
		return
	}

	var req dto.RunPipelineRequest
	c.ShouldBindJSON(&req)

	username := c.GetString("username")
	result, err := h.runSvc.Run(c.Request.Context(), uint(id), &req, "manual", username)
	if err != nil {
		response.FromError(c, err)
		return
	}

	response.Success(c, result)
}

// CancelRun 取消执行
// @Summary 取消流水线执行
// @Description 取消正在运行的流水线
// @Tags Pipeline
// @Accept json
// @Produce json
// @Param id path int true "执行ID"
// @Success 200 {object} response.Response
// @Failure 400 {object} response.Response
// @Router /pipelines/runs/{id}/cancel [post]
func (h *PipelineHandler) CancelRun(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		response.BadRequest(c, "无效的ID")
		return
	}

	if err := h.runSvc.Cancel(c.Request.Context(), uint(id)); err != nil {
		response.FromError(c, err)
		return
	}

	response.SuccessWithMessage(c, "取消成功", nil)
}

// RetryRun 重试执行
// @Summary 重试流水线执行
// @Description 重试失败的流水线执行
// @Tags Pipeline
// @Accept json
// @Produce json
// @Param id path int true "执行ID"
// @Param from_stage query string false "从指定阶段开始重试"
// @Success 200 {object} response.Response
// @Failure 400 {object} response.Response
// @Router /pipelines/runs/{id}/retry [post]
func (h *PipelineHandler) RetryRun(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		response.BadRequest(c, "无效的ID")
		return
	}

	fromStage := c.Query("from_stage")
	if err := h.runSvc.Retry(c.Request.Context(), uint(id), fromStage); err != nil {
		response.FromError(c, err)
		return
	}

	response.SuccessWithMessage(c, "重试已启动", nil)
}

// ListRuns 获取执行历史
// @Summary 获取执行历史
// @Description 分页获取流水线执行历史记录
// @Tags Pipeline
// @Accept json
// @Produce json
// @Param pipeline_id query int false "流水线ID"
// @Param status query string false "状态筛选"
// @Param page query int false "页码" default(1)
// @Param page_size query int false "每页数量" default(20)
// @Success 200 {object} response.Response{data=dto.PipelineRunListResponse}
// @Failure 400 {object} response.Response
// @Router /pipelines/runs [get]
func (h *PipelineHandler) ListRuns(c *gin.Context) {
	var req dto.PipelineRunListRequest
	if err := c.ShouldBindQuery(&req); err != nil {
		response.BadRequest(c, "参数错误")
		return
	}

	result, err := h.runSvc.ListRuns(c.Request.Context(), &req)
	if err != nil {
		response.FromError(c, err)
		return
	}

	response.Success(c, result)
}

// GetRun 获取执行详情
// @Summary 获取执行详情
// @Description 获取流水线执行的详细信息，包括各阶段和步骤状态
// @Tags Pipeline
// @Accept json
// @Produce json
// @Param id path int true "执行ID"
// @Success 200 {object} response.Response{data=dto.PipelineRunDetailResponse}
// @Failure 400 {object} response.Response
// @Failure 404 {object} response.Response
// @Router /pipelines/runs/{id} [get]
func (h *PipelineHandler) GetRun(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		response.BadRequest(c, "无效的ID")
		return
	}

	result, err := h.runSvc.GetRun(c.Request.Context(), uint(id))
	if err != nil {
		response.FromError(c, err)
		return
	}

	response.Success(c, result)
}

// GetStepLogs 获取步骤日志
// @Summary 获取步骤日志
// @Description 获取指定步骤的执行日志
// @Tags Pipeline
// @Accept json
// @Produce json
// @Param id path int true "执行ID"
// @Param step_id path int true "步骤ID"
// @Success 200 {object} response.Response{data=string}
// @Failure 400 {object} response.Response
// @Router /pipelines/runs/{id}/steps/{step_id}/logs [get]
func (h *PipelineHandler) GetStepLogs(c *gin.Context) {
	stepID, err := strconv.ParseUint(c.Param("step_id"), 10, 64)
	if err != nil {
		response.BadRequest(c, "无效的步骤ID")
		return
	}

	result, err := h.runSvc.GetStepLogs(c.Request.Context(), uint(stepID))
	if err != nil {
		response.FromError(c, err)
		return
	}

	response.Success(c, result)
}

// GetStats 获取流水线统计
// @Summary 获取流水线统计
// @Description 获取流水线执行统计数据
// @Tags Pipeline
// @Accept json
// @Produce json
// @Param pipeline_id query int false "流水线ID"
// @Param start_date query string false "开始日期"
// @Param end_date query string false "结束日期"
// @Success 200 {object} response.Response{data=dto.PipelineStatsResponse}
// @Failure 400 {object} response.Response
// @Router /pipelines/stats [get]
func (h *PipelineHandler) GetStats(c *gin.Context) {
	var req dto.PipelineStatsRequest
	if err := c.ShouldBindQuery(&req); err != nil {
		response.BadRequest(c, "参数错误")
		return
	}

	result, err := h.runSvc.GetStats(c.Request.Context(), &req)
	if err != nil {
		response.FromError(c, err)
		return
	}

	response.Success(c, result)
}

// ListTemplates 获取模板列表
func (h *PipelineHandler) ListTemplates(c *gin.Context) {
	category := c.Query("category")

	result, err := h.templateSvc.List(c.Request.Context(), category)
	if err != nil {
		response.FromError(c, err)
		return
	}

	response.Success(c, result)
}

// GetTemplate 获取模板详情
func (h *PipelineHandler) GetTemplate(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		response.BadRequest(c, "无效的ID")
		return
	}

	result, err := h.templateSvc.Get(c.Request.Context(), uint(id))
	if err != nil {
		response.FromError(c, err)
		return
	}

	response.Success(c, result)
}

// CreateFromTemplate 从模板创建流水线
func (h *PipelineHandler) CreateFromTemplate(c *gin.Context) {
	var req dto.CreateFromTemplateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "参数错误")
		return
	}

	userID := c.GetUint("userID")
	if err := h.templateSvc.CreateFromTemplate(c.Request.Context(), &req, userID); err != nil {
		response.FromError(c, err)
		return
	}

	response.SuccessWithMessage(c, "创建成功", nil)
}

// ListCredentials 获取凭证列表
func (h *PipelineHandler) ListCredentials(c *gin.Context) {
	result, err := h.credentialSvc.List(c.Request.Context())
	if err != nil {
		response.FromError(c, err)
		return
	}

	response.Success(c, result)
}

// CreateCredential 创建凭证
func (h *PipelineHandler) CreateCredential(c *gin.Context) {
	var req dto.CredentialRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "参数错误")
		return
	}

	if err := h.credentialSvc.Create(c.Request.Context(), &req); err != nil {
		response.FromError(c, err)
		return
	}

	response.SuccessWithMessage(c, "创建成功", nil)
}

// UpdateCredential 更新凭证
func (h *PipelineHandler) UpdateCredential(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		response.BadRequest(c, "无效的ID")
		return
	}

	var req dto.CredentialRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "参数错误")
		return
	}
	req.ID = uint(id)

	if err := h.credentialSvc.Update(c.Request.Context(), &req); err != nil {
		response.FromError(c, err)
		return
	}

	response.SuccessWithMessage(c, "更新成功", nil)
}

// DeleteCredential 删除凭证
func (h *PipelineHandler) DeleteCredential(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		response.BadRequest(c, "无效的ID")
		return
	}

	if err := h.credentialSvc.Delete(c.Request.Context(), uint(id)); err != nil {
		response.FromError(c, err)
		return
	}

	response.SuccessWithMessage(c, "删除成功", nil)
}

// ListVariables 获取变量列表
func (h *PipelineHandler) ListVariables(c *gin.Context) {
	scope := c.Query("scope")
	pipelineID, _ := strconv.ParseUint(c.Query("pipeline_id"), 10, 64)

	result, err := h.variableSvc.List(c.Request.Context(), scope, uint(pipelineID))
	if err != nil {
		response.FromError(c, err)
		return
	}

	response.Success(c, result)
}

// CreateVariable 创建变量
func (h *PipelineHandler) CreateVariable(c *gin.Context) {
	var req dto.VariableRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "参数错误")
		return
	}

	if err := h.variableSvc.Create(c.Request.Context(), &req); err != nil {
		response.FromError(c, err)
		return
	}

	response.SuccessWithMessage(c, "创建成功", nil)
}

// UpdateVariable 更新变量
func (h *PipelineHandler) UpdateVariable(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		response.BadRequest(c, "无效的ID")
		return
	}

	var req dto.VariableRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "参数错误")
		return
	}
	req.ID = uint(id)

	if err := h.variableSvc.Update(c.Request.Context(), &req); err != nil {
		response.FromError(c, err)
		return
	}

	response.SuccessWithMessage(c, "更新成功", nil)
}

// DeleteVariable 删除变量
func (h *PipelineHandler) DeleteVariable(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		response.BadRequest(c, "无效的ID")
		return
	}

	if err := h.variableSvc.Delete(c.Request.Context(), uint(id)); err != nil {
		response.FromError(c, err)
		return
	}

	response.SuccessWithMessage(c, "删除成功", nil)
}
