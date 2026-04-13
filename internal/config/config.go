package config

import (
	"fmt"
	"net/http"
	"os"
	"path/filepath"
	"runtime/debug"
	"strconv"
	"sync"
	"time"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"github.com/go-redis/redis/v8"
	"github.com/joho/godotenv"
	"gorm.io/gorm"

	apperrors "devops/pkg/errors"
	"devops/pkg/logger"
	"devops/pkg/response"
)

// Config 应用配置
type Config struct {
	// 服务器配置
	Port            string
	ReadTimeout     time.Duration
	WriteTimeout    time.Duration
	ShutdownTimeout time.Duration
	LogLevel        string

	// HTTP 客户端配置
	MaxIdleConns        int
	MaxIdleConnsPerHost int
	IdleConnTimeout     time.Duration

	// MySQL 配置
	MySQLHost            string
	MySQLPort            int
	MySQLUser            string
	MySQLPassword        string
	MySQLDatabase        string
	MySQLMaxIdleConns    int
	MySQLMaxOpenConns    int
	MySQLConnMaxLifetime time.Duration
	Debug                bool

	// Redis 配置
	RedisAddr     string
	RedisPassword string
	RedisDB       int

	// Jenkins 配置
	JenkinsURL   string
	JenkinsUser  string
	JenkinsToken string

	// K8s 配置
	K8sKubeConfigPath string
	K8sNamespace      string
	K8sCheckTimeout   int

	// 飞书配置
	FeishuAppID     string
	FeishuAppSecret string

	// JWT 配置
	JWTSecret     string
	JWTExpiration int

	Application *Application

	// 内部缓存（向后兼容）
	db  *gorm.DB
	rdb *redis.Client
	mu  sync.RWMutex
}

// Application Gin 应用
type Application struct {
	server *gin.Engine
	lock   sync.Mutex
	root   gin.IRouter
}

var (
	cfg  *Config
	once sync.Once
)

// LoadConfig 加载配置
func LoadConfig() (*Config, error) {
	var err error
	once.Do(func() {
		loadDotEnv()

		cfg = &Config{
			// 服务器配置
			Port:            getEnv("PORT", "8080"),
			LogLevel:        getEnv("LOG_LEVEL", "info"),
			ReadTimeout:     getDurationEnv("READ_TIMEOUT", 10*time.Second),
			WriteTimeout:    getDurationEnv("WRITE_TIMEOUT", 10*time.Second),
			ShutdownTimeout: getDurationEnv("SHUTDOWN_TIMEOUT", 5*time.Second),

			// HTTP 客户端配置
			MaxIdleConns:        getIntEnv("MAX_IDLE_CONNS", 100),
			MaxIdleConnsPerHost: getIntEnv("MAX_IDLE_CONNS_PER_HOST", 10),
			IdleConnTimeout:     getDurationEnv("IDLE_CONN_TIMEOUT", 90*time.Second),

			// MySQL 配置
			MySQLHost:            getEnv("MYSQL_HOST", "localhost"),
			MySQLPort:            getIntEnv("MYSQL_PORT", 3306),
			MySQLUser:            getEnv("MYSQL_USER", "root"),
			MySQLPassword:        getEnv("MYSQL_PASSWORD", "123456"),
			MySQLDatabase:        getEnv("MYSQL_DATABASE", "devops"),
			MySQLMaxIdleConns:    getIntEnv("MYSQL_MAX_IDLE_CONNS", 10),
			MySQLMaxOpenConns:    getIntEnv("MYSQL_MAX_OPEN_CONNS", 100),
			MySQLConnMaxLifetime: getDurationEnv("MYSQL_CONN_MAX_LIFETIME", 3600*time.Second),
			Debug:                getEnv("DEBUG", "false") == "true",

			// Redis 配置
			RedisAddr:     getEnv("REDIS_ADDR", "localhost:6379"),
			RedisPassword: getEnv("REDIS_PASSWORD", ""),
			RedisDB:       getIntEnv("REDIS_DB", 0),

			// Jenkins 配置
			JenkinsURL:   getEnv("JENKINS_URL", "http://localhost:8080"),
			JenkinsUser:  getEnv("JENKINS_USER", "admin"),
			JenkinsToken: getEnv("JENKINS_TOKEN", ""),

			// K8s 配置
			K8sKubeConfigPath: getEnv("K8S_KUBECONFIG_PATH", ""),
			K8sNamespace:      getEnv("K8S_NAMESPACE", "default"),
			K8sCheckTimeout:   getIntEnv("K8S_CHECK_TIMEOUT", 300),

			// 飞书配置
			FeishuAppID:     getEnv("FEISHU_APP_ID", ""),
			FeishuAppSecret: getEnv("FEISHU_APP_SECRET", ""),

			// JWT 配置
			JWTSecret:     getEnv("JWT_SECRET", "your-secret-key"),
			JWTExpiration: getIntEnv("JWT_EXPIRATION", 24),

			Application: &Application{},
		}

		if vErr := cfg.Validate(); vErr != nil {
			err = fmt.Errorf("config validation failed: %w", vErr)
		}
	})
	return cfg, err
}

// GetConfig 获取全局配置
func GetConfig() *Config { return cfg }

// Validate 验证配置
func (c *Config) Validate() error {
	if c.JWTSecret == "" || c.JWTSecret == "your-secret-key" {
		logger.L().Warn("JWT_SECRET not configured, using default (not recommended for production)")
	}
	return nil
}

// DSN 返回 MySQL DSN
func (c *Config) DSN() string {
	return fmt.Sprintf("%s:%s@tcp(%s:%d)/%s?charset=utf8mb4&parseTime=True&loc=Local",
		c.MySQLUser, c.MySQLPassword, c.MySQLHost, c.MySQLPort, c.MySQLDatabase)
}

// SetDB 设置数据库连接（由 infrastructure 调用）
func (c *Config) SetDB(db *gorm.DB) {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.db = db
}

// GetDB 获取数据库连接（向后兼容）
func (c *Config) GetDB() *gorm.DB {
	c.mu.RLock()
	defer c.mu.RUnlock()
	return c.db
}

// SetRedis 设置 Redis 连接（由 infrastructure 调用）
func (c *Config) SetRedis(rdb *redis.Client) {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.rdb = rdb
}

// GetRedis 获取 Redis 连接（向后兼容）
func (c *Config) GetRedis() *redis.Client {
	c.mu.RLock()
	defer c.mu.RUnlock()
	return c.rdb
}

// GinServer 获取 Gin 引擎
func (a *Application) GinServer() *gin.Engine {
	a.lock.Lock()
	defer a.lock.Unlock()
	if a.server == nil {
		a.server = gin.New()

		// 基础中间件
		a.server.Use(gin.Logger())
		a.server.Use(ErrorRecovery())
		a.server.Use(SecureHeaders())
		a.server.Use(cors.Default())

		// 404 和 405 处理
		a.server.NoRoute(NotFoundHandler())
		a.server.NoMethod(MethodNotAllowedHandler())
	}
	return a.server
}

// GinRootRouter 获取 API 根路由
func (a *Application) GinRootRouter() gin.IRouter {
	r := a.GinServer()
	if a.root == nil {
		a.root = r.Group("app").Group("api").Group("v1")
	}
	return a.root
}

// ErrorRecovery 错误恢复中间件
func ErrorRecovery() gin.HandlerFunc {
	return func(c *gin.Context) {
		defer func() {
			if err := recover(); err != nil {
				stack := string(debug.Stack())
				logger.L().WithFields(map[string]any{
					"error":      err,
					"path":       c.Request.URL.Path,
					"method":     c.Request.Method,
					"client_ip":  c.ClientIP(),
					"user_agent": c.Request.UserAgent(),
				}).Error("panic recovered:\n%s", stack)

				c.AbortWithStatusJSON(http.StatusInternalServerError, response.Response{
					Code:    apperrors.ErrCodeInternalError,
					Message: "服务器内部错误",
				})
			}
		}()
		c.Next()
	}
}

// SecureHeaders 安全响应头中间件
func SecureHeaders() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Header("X-Content-Type-Options", "nosniff")
		c.Header("X-Frame-Options", "DENY")
		c.Header("X-XSS-Protection", "1; mode=block")
		c.Header("Referrer-Policy", "strict-origin-when-cross-origin")
		c.Next()
	}
}

// NotFoundHandler 404 处理
func NotFoundHandler() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.JSON(http.StatusNotFound, response.Response{
			Code:    apperrors.ErrCodeNotFound,
			Message: "接口不存在",
		})
	}
}

// MethodNotAllowedHandler 405 处理
func MethodNotAllowedHandler() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.JSON(http.StatusMethodNotAllowed, response.Response{
			Code:    apperrors.ErrCodeMethodNotAllowed,
			Message: "请求方法不允许",
		})
	}
}

// 环境变量辅助函数
func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

func getIntEnv(key string, defaultValue int) int {
	if value := os.Getenv(key); value != "" {
		if intValue, err := strconv.Atoi(value); err == nil {
			return intValue
		}
	}
	return defaultValue
}

func getDurationEnv(key string, defaultValue time.Duration) time.Duration {
	if value := os.Getenv(key); value != "" {
		if intValue, err := strconv.Atoi(value); err == nil {
			return time.Duration(intValue) * time.Second
		}
	}
	return defaultValue
}

func loadDotEnv() {
	wd, err := os.Getwd()
	if err != nil {
		return
	}

	envPath := findEnvFile(wd)
	if envPath == "" {
		return
	}

	_ = godotenv.Load(envPath)
}

func findEnvFile(startDir string) string {
	dir := startDir
	for {
		envPath := filepath.Join(dir, ".env")
		if info, err := os.Stat(envPath); err == nil && !info.IsDir() {
			return envPath
		}

		parent := filepath.Dir(dir)
		if parent == dir {
			return ""
		}
		dir = parent
	}
}
