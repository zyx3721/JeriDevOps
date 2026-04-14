package middleware

import (
	"errors"
	"slices"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"

	apperrors "devops/pkg/errors"
	"devops/pkg/logger"
)

// Claims JWT声明
type Claims struct {
	UserID   uint   `json:"user_id"`
	Username string `json:"username"`
	Role     string `json:"role"`
	jwt.RegisteredClaims
}

var jwtSecret []byte

// InitAuth 初始化认证中间件
// jwtSecretStr: JWT 签名密钥
func InitAuth(jwtSecretStr string) error {
	if jwtSecretStr == "" {
		return errors.New("JWT secret cannot be empty")
	}
	jwtSecret = []byte(jwtSecretStr)
	return nil
}

// AuthMiddleware JWT认证中间件
func AuthMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		var tokenString string

		// 优先从 Header 获取 token
		authHeader := c.GetHeader("Authorization")
		if authHeader != "" {
			parts := strings.SplitN(authHeader, " ", 2)
			if len(parts) == 2 && parts[0] == "Bearer" {
				tokenString = parts[1]
			}
		}

		// 如果 Header 中没有，尝试从 query 参数获取（用于 WebSocket）
		if tokenString == "" {
			tokenString = c.Query("token")
		}

		// 检查是否是 WebSocket 请求
		isWebSocket := c.GetHeader("Upgrade") == "websocket"

		if tokenString == "" {
			if isWebSocket {
				// WebSocket 请求不返回 JSON，直接关闭连接
				logger.NewLogger("warn").Warn("WebSocket 请求缺少 token")
				c.AbortWithStatus(401)
			} else {
				Error(c, apperrors.ErrUnauthorized)
				c.Abort()
			}
			return
		}

		claims, err := parseToken(tokenString)
		if err != nil {
			logger.NewLogger("warn").Warn("Token解析失败: %v", err)
			if isWebSocket {
				c.AbortWithStatus(401)
			} else {
				Error(c, apperrors.ErrTokenInvalid)
				c.Abort()
			}
			return
		}

		c.Set("user_id", claims.UserID)
		c.Set("username", claims.Username)
		c.Set("role", claims.Role)

		c.Next()
	}
}

func parseToken(tokenString string) (*Claims, error) {
	if len(jwtSecret) == 0 {
		return nil, apperrors.New(apperrors.ErrCodeInternalError, "JWT密钥未配置")
	}

	token, err := jwt.ParseWithClaims(tokenString, &Claims{}, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, apperrors.ErrTokenInvalid
		}
		return jwtSecret, nil
	})

	if err != nil {
		return nil, err
	}

	if claims, ok := token.Claims.(*Claims); ok && token.Valid {
		return claims, nil
	}

	return nil, apperrors.ErrTokenInvalid
}

// GenerateToken 生成JWT token
func GenerateToken(userID uint, username, role string, secret string, expirationHours int) (string, error) {
	secretBytes := []byte(secret)
	if len(secretBytes) == 0 {
		return "", apperrors.New(apperrors.ErrCodeInternalError, "JWT密钥未配置")
	}

	nowTime := time.Now()
	expireTime := nowTime.Add(time.Duration(expirationHours) * time.Hour)

	claims := Claims{
		UserID:   userID,
		Username: username,
		Role:     role,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(expireTime),
			IssuedAt:  jwt.NewNumericDate(nowTime),
			NotBefore: jwt.NewNumericDate(nowTime),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString(secretBytes)
}

// GetUserID 从上下文获取用户ID
func GetUserID(c *gin.Context) (uint, bool) {
	userID, exists := c.Get("user_id")
	if !exists {
		return 0, false
	}
	id, ok := userID.(uint)
	return id, ok
}

// GetUsername 从上下文获取用户名
func GetUsername(c *gin.Context) (string, bool) {
	username, exists := c.Get("username")
	if !exists {
		return "", false
	}
	name, ok := username.(string)
	return name, ok
}

// GetRole 从上下文获取用户角色
func GetRole(c *gin.Context) (string, bool) {
	role, exists := c.Get("role")
	if !exists {
		return "", false
	}
	roleStr, ok := role.(string)
	if !ok {
		logger.L().Warn("GetRole: role is not string, type=%T", role)
		return "", false
	}
	return roleStr, true
}

// RequireRole 角色验证中间件
func RequireRole(allowedRoles ...string) gin.HandlerFunc {
	return func(c *gin.Context) {
		role, exists := GetRole(c)
		if !exists {
			Error(c, apperrors.ErrUnauthorized)
			c.Abort()
			return
		}

		if slices.Contains(allowedRoles, role) {
			c.Next()
			return
		}

		Error(c, apperrors.ErrForbidden)
		c.Abort()
	}
}
