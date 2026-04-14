package wechatwork

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"strings"
	"sync"
	"time"

	"devops/pkg/logger"
)

// Client 企业微信客户端
type Client struct {
	corpID        string
	agentID       int64
	secret        string
	logger        *logger.Logger
	httpClient    *http.Client
	accessToken   string
	tokenExpireAt time.Time
	mu            sync.RWMutex
}

// NewClient 创建企业微信客户端
func NewClient(corpID string, agentID int64, secret string) *Client {
	return &Client{
		corpID:  corpID,
		agentID: agentID,
		secret:  secret,
		logger:  logger.NewLogger("INFO"),
		httpClient: &http.Client{
			Timeout: 30 * time.Second,
		},
	}
}

// GetAccessToken 获取访问令牌
func (c *Client) GetAccessToken(ctx context.Context) (string, error) {
	c.mu.RLock()
	if c.accessToken != "" && time.Now().Before(c.tokenExpireAt) {
		token := c.accessToken
		c.mu.RUnlock()
		return token, nil
	}
	c.mu.RUnlock()

	c.mu.Lock()
	defer c.mu.Unlock()

	// 双重检查
	if c.accessToken != "" && time.Now().Before(c.tokenExpireAt) {
		return c.accessToken, nil
	}

	tokenURL := fmt.Sprintf("https://qyapi.weixin.qq.com/cgi-bin/gettoken?corpid=%s&corpsecret=%s", c.corpID, c.secret)

	req, err := http.NewRequestWithContext(ctx, "GET", tokenURL, nil)
	if err != nil {
		return "", fmt.Errorf("create request failed: %w", err)
	}

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return "", fmt.Errorf("request failed: %w", err)
	}
	defer resp.Body.Close()

	var result TokenResponse
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return "", fmt.Errorf("decode response failed: %w", err)
	}

	if result.ErrCode != 0 {
		return "", fmt.Errorf("API error: %d - %s", result.ErrCode, result.ErrMsg)
	}

	c.accessToken = result.AccessToken
	c.tokenExpireAt = time.Now().Add(time.Duration(result.ExpiresIn-300) * time.Second)

	c.logger.Info("WechatWork access token obtained, expires at: %v", c.tokenExpireAt)
	return c.accessToken, nil
}

// SendMessage 发送应用消息
func (c *Client) SendMessage(ctx context.Context, msg *AppMessage) error {
	token, err := c.GetAccessToken(ctx)
	if err != nil {
		return err
	}

	sendURL := fmt.Sprintf("https://qyapi.weixin.qq.com/cgi-bin/message/send?access_token=%s", token)

	msg.AgentID = c.agentID

	data, err := json.Marshal(msg)
	if err != nil {
		return fmt.Errorf("marshal message failed: %w", err)
	}

	req, err := http.NewRequestWithContext(ctx, "POST", sendURL, bytes.NewBuffer(data))
	if err != nil {
		return fmt.Errorf("create request failed: %w", err)
	}
	req.Header.Set("Content-Type", "application/json")

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("request failed: %w", err)
	}
	defer resp.Body.Close()

	var result map[string]any
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return fmt.Errorf("decode response failed: %w", err)
	}

	if errcode, ok := result["errcode"].(float64); ok && errcode != 0 {
		errmsg, _ := result["errmsg"].(string)
		return fmt.Errorf("API error: %v - %s", errcode, errmsg)
	}

	c.logger.Info("App message sent successfully")
	return nil
}

// SendWebhookMessage 发送Webhook消息
func (c *Client) SendWebhookMessage(ctx context.Context, webhookURL string, msg *WebhookMessage) error {
	data, err := json.Marshal(msg)
	if err != nil {
		return fmt.Errorf("marshal message failed: %w", err)
	}

	req, err := http.NewRequestWithContext(ctx, "POST", webhookURL, bytes.NewBuffer(data))
	if err != nil {
		return fmt.Errorf("create request failed: %w", err)
	}
	req.Header.Set("Content-Type", "application/json")

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("request failed: %w", err)
	}
	defer resp.Body.Close()

	var result map[string]any
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return fmt.Errorf("decode response failed: %w", err)
	}

	if errcode, ok := result["errcode"].(float64); ok && errcode != 0 {
		errmsg, _ := result["errmsg"].(string)
		return fmt.Errorf("webhook error: %v - %s", errcode, errmsg)
	}

	c.logger.Info("Webhook message sent successfully")
	return nil
}

// SearchUser 搜索用户
// 支持通过姓名、手机号、邮箱搜索
func (c *Client) SearchUser(ctx context.Context, query string) ([]UserInfo, error) {
	token, err := c.GetAccessToken(ctx)
	if err != nil {
		return nil, err
	}

	// 先获取部门用户列表（简单信息）
	listURL := fmt.Sprintf("https://qyapi.weixin.qq.com/cgi-bin/user/simplelist?access_token=%s&department_id=1&fetch_child=1", token)

	req, err := http.NewRequestWithContext(ctx, "GET", listURL, nil)
	if err != nil {
		return nil, fmt.Errorf("create request failed: %w", err)
	}

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("request failed: %w", err)
	}
	defer resp.Body.Close()

	var result map[string]any
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return nil, fmt.Errorf("decode response failed: %w", err)
	}

	if errcode, ok := result["errcode"].(float64); ok && errcode != 0 {
		errmsg, _ := result["errmsg"].(string)
		return nil, fmt.Errorf("API error: %v - %s", errcode, errmsg)
	}

	var users []UserInfo
	if userList, ok := result["userlist"].([]any); ok {
		c.logger.Info("Total users in simplelist: %d", len(userList))

		// 遍历用户列表，获取详细信息
		for _, item := range userList {
			if u, ok := item.(map[string]any); ok {
				userid := getString(u, "userid")
				if userid == "" {
					continue
				}

				// 获取用户详细信息（包含手机号、邮箱）
				userDetail, err := c.getUserDetail(ctx, token, userid)
				if err != nil {
					c.logger.Error("Failed to get user detail for %s: %v (可能是应用权限不足)", userid, err)
					// 如果获取详情失败，使用简单信息
					users = append(users, UserInfo{
						UserID: userid,
						Name:   getString(u, "name"),
						Mobile: "",
						Email:  "",
					})
					continue
				}

				// 支持姓名、手机号、邮箱搜索（不区分大小写）
				queryLower := toLower(query)
				if query == "" ||
					containsIgnoreCaseChinese(userDetail.Name, queryLower) ||
					containsIgnoreCaseChinese(userDetail.Mobile, queryLower) ||
					containsIgnoreCaseChinese(userDetail.Email, queryLower) ||
					containsIgnoreCaseChinese(userDetail.UserID, queryLower) {
					users = append(users, userDetail)
				}
			}
		}
	}

	c.logger.Info("Found %d users for query: %s", len(users), query)
	return users, nil
}

// getUserDetail 获取用户详细信息
func (c *Client) getUserDetail(ctx context.Context, token, userid string) (UserInfo, error) {
	detailURL := fmt.Sprintf("https://qyapi.weixin.qq.com/cgi-bin/user/get?access_token=%s&userid=%s", token, userid)

	req, err := http.NewRequestWithContext(ctx, "GET", detailURL, nil)
	if err != nil {
		return UserInfo{}, fmt.Errorf("create request failed: %w", err)
	}

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return UserInfo{}, fmt.Errorf("request failed: %w", err)
	}
	defer resp.Body.Close()

	var result map[string]any
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return UserInfo{}, fmt.Errorf("decode response failed: %w", err)
	}

	if errcode, ok := result["errcode"].(float64); ok && errcode != 0 {
		errmsg, _ := result["errmsg"].(string)
		return UserInfo{}, fmt.Errorf("API error: %v - %s", errcode, errmsg)
	}

	name := getString(result, "name")
	mobile := getString(result, "mobile")
	email := getString(result, "email")

	c.logger.Info("User detail: userid=%s, name=%s, mobile=%s, email=%s", userid, name, mobile, email)

	user := UserInfo{
		UserID: userid,
		Name:   name,
		Mobile: mobile,
		Email:  email,
	}

	// 获取头像
	if avatar, ok := result["avatar"].(string); ok {
		user.Avatar = avatar
	}

	// 获取部门信息
	if depts, ok := result["department"].([]any); ok {
		departments := make([]int, 0, len(depts))
		for _, d := range depts {
			if deptID, ok := d.(float64); ok {
				departments = append(departments, int(deptID))
			}
		}
		user.Department = departments
	}

	return user, nil
}

func getString(m map[string]any, key string) string {
	if v, ok := m[key].(string); ok {
		return v
	}
	return ""
}

func toLower(s string) string {
	return strings.ToLower(s)
}

func containsIgnoreCaseChinese(s, substrLower string) bool {
	if substrLower == "" {
		return true
	}
	sLower := strings.ToLower(s)
	return strings.Contains(sLower, substrLower)
}

// GetLogger 获取日志记录器
func (c *Client) GetLogger() *logger.Logger {
	return c.logger
}
