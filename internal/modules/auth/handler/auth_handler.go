package handler

import (
	"fmt"

	"github.com/gin-gonic/gin"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"

	"devops/internal/config"
	"devops/internal/models"
	"devops/pkg/dto"
	"devops/pkg/ioc"
	"devops/pkg/middleware"
	"devops/pkg/response"
	"devops/pkg/validator"
)

func init() {
	ioc.Api.RegisterContainer("AuthHandler", &AuthApiHandler{})
}

type AuthApiHandler struct {
	handler *AuthHandler
}

func (h *AuthApiHandler) Init() error {
	cfg, _ := config.LoadConfig()
	db := cfg.GetDB()

	// 初始化 JWT 认证中间件（设置全局 jwtSecret 用于 token 验证）
	if err := middleware.InitAuth(cfg.JWTSecret); err != nil {
		return fmt.Errorf("failed to init auth middleware: %w", err)
	}

	h.handler = NewAuthHandler(db, cfg.JWTSecret, cfg.JWTExpiration)

	root := cfg.Application.GinRootRouter().Group("auth")
	h.Register(root)

	return nil
}

func (h *AuthApiHandler) Register(r gin.IRouter) {
	r.POST("/login", h.handler.Login)
	r.POST("/register", h.handler.Register)
}

type AuthHandler struct {
	db            *gorm.DB
	jwtSecret     string
	jwtExpiration int
}

func NewAuthHandler(db *gorm.DB, jwtSecret string, jwtExpiration int) *AuthHandler {
	return &AuthHandler{db: db, jwtSecret: jwtSecret, jwtExpiration: jwtExpiration}
}

// Login godoc
// @Summary 用户登录
// @Description 用户登录获取 JWT Token
// @Tags 认证
// @Accept json
// @Produce json
// @Param request body dto.LoginRequest true "登录请求"
// @Success 200 {object} response.Response{data=object{token=string,user=object{id=int,username=string,email=string,role=string}}} "登录成功"
// @Failure 400 {object} response.Response "参数错误"
// @Failure 401 {object} response.Response "用户名或密码错误"
// @Failure 403 {object} response.Response "账户已被禁用"
// @Router /auth/login [post]
func (h *AuthHandler) Login(c *gin.Context) {
	var req dto.LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "参数错误")
		return
	}

	// 使用验证器验证
	if ok, msg := validator.ValidateAndFormat(&req); !ok {
		response.BadRequest(c, msg)
		return
	}

	var user models.User
	if err := h.db.Where("username = ?", req.Username).First(&user).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			response.Unauthorized(c, "用户名或密码错误")
			return
		}
		response.InternalError(c, "查询用户失败")
		return
	}

	if err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(req.Password)); err != nil {
		response.Unauthorized(c, "用户名或密码错误")
		return
	}

	if user.Status != "active" {
		response.Forbidden(c, "账户已被禁用")
		return
	}

	token, err := middleware.GenerateToken(user.ID, user.Username, user.Role, h.jwtSecret, h.jwtExpiration)
	if err != nil {
		response.InternalError(c, "生成Token失败")
		return
	}

	response.SuccessWithMessage(c, "登录成功", gin.H{
		"token": token,
		"user":  gin.H{"id": user.ID, "username": user.Username, "email": user.Email, "role": user.Role},
	})
}

// Register godoc
// @Summary 用户注册
// @Description 注册新用户
// @Tags 认证
// @Accept json
// @Produce json
// @Param request body dto.RegisterRequest true "注册请求"
// @Success 200 {object} response.Response{data=object{id=int,username=string,email=string}} "注册成功"
// @Failure 400 {object} response.Response "参数错误或用户名已存在"
// @Failure 500 {object} response.Response "服务器错误"
// @Router /auth/register [post]
func (h *AuthHandler) Register(c *gin.Context) {
	var req dto.RegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "参数错误")
		return
	}

	// 使用验证器验证
	if ok, msg := validator.ValidateAndFormat(&req); !ok {
		response.BadRequest(c, msg)
		return
	}

	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		response.InternalError(c, "密码加密失败")
		return
	}

	user := &models.User{
		Username: req.Username,
		Password: string(hashedPassword),
		Email:    req.Email,
		Phone:    req.Phone,
		Role:     "user",
		Status:   "active",
	}

	// 使用 FirstOrCreate 避免并发竞态条件
	// 如果用户名已存在则返回现有记录，否则创建新记录
	result := h.db.Where("username = ?", req.Username).FirstOrCreate(&user)
	if result.Error != nil {
		response.InternalError(c, "创建用户失败")
		return
	}

	// 检查是否是新创建的记录
	if result.RowsAffected == 0 {
		response.BadRequest(c, "用户名已存在，请选择其他用户名")
		return
	}

	response.SuccessWithMessage(c, "注册成功", gin.H{
		"id":       user.ID,
		"username": user.Username,
		"email":    user.Email,
	})
}
