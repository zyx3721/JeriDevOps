// Package feishu 飞书客户端封装
// 本文件包含消息发送相关的方法
package feishu

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"strings"
)

// ========== 消息发送 ==========

// CreateCard 创建飞书卡片
// 返回卡片ID（本地生成，用于追踪）
func (c *Client) CreateCard(ctx context.Context, title, content string) (string, error) {
	c.logger.Debug("Creating card with title: %s", title)

	cardJSON := fmt.Sprintf(`{
		"schema":"2.0",
		"header":{
			"title":{
				"content":"%s",
				"tag":"plain_text"
			}
		},
		"body":{
			"elements":[
				{
					"tag":"markdown",
					"content":"%s"
				}
			]
		}
	}`, title, content)

	c.logger.Debug("Card content: %s", cardJSON)

	cardID := fmt.Sprintf("card_%s", generateUUID())

	c.logger.Info("Card created successfully, card_id: %s", cardID)
	return cardID, nil
}

// SendMessage 发送消息
// 支持 text 和 interactive 两种消息类型
func (c *Client) SendMessage(ctx context.Context, receiveID, receiveIdType, msgType, content string) error {
	c.logger.Debug("Sending message to %s, type: %s", receiveID, msgType)

	token, err := c.GetTenantAccessToken(ctx)
	if err != nil {
		c.logger.Error("Failed to get tenant access token: %v", err)
		return fmt.Errorf("failed to get tenant access token: %w", err)
	}

	sendURL := fmt.Sprintf("https://open.feishu.cn/open-apis/im/v1/messages?receive_id_type=%s", receiveIdType)

	// 飞书 API content 字段规则：
	// - text 类型：content 是字符串，值为 {"text":"..."} 序列化后的字符串
	// - post/interactive 类型：content 是 JSON 对象，直接嵌入
	messagePayload := map[string]any{
		"receive_id": receiveID,
		"msg_type":   msgType,
	}

	switch msgType {
	case "text":
		// 提取纯文本，统一包装成 {"text":"..."} 字符串
		trimmed := strings.TrimSpace(content)
		var plain string
		if len(trimmed) > 0 && trimmed[0] == '{' {
			// 前端传入 {"text":"..."} 格式，提取 text 字段值
			var obj map[string]string
			if err := json.Unmarshal([]byte(trimmed), &obj); err == nil {
				plain = obj["text"]
			} else {
				plain = content
			}
		} else if len(trimmed) > 0 && trimmed[0] == '"' {
			// 带引号的 JSON 字符串，unescape
			if err := json.Unmarshal([]byte(trimmed), &plain); err != nil {
				plain = content
			}
		} else {
			plain = content
		}
		wrapped, _ := json.Marshal(map[string]string{"text": plain})
		messagePayload["content"] = string(wrapped)
	case "post", "interactive":
		// post/interactive：content 是 JSON 对象，用 RawMessage 直接嵌入避免二次序列化
		messagePayload["content"] = json.RawMessage(strings.TrimSpace(content))
	default:
		c.logger.Error("Unsupported message type: %s", msgType)
		return fmt.Errorf("unsupported message type: %s", msgType)
	}

	payloadData, err := json.Marshal(messagePayload)
	if err != nil {
		c.logger.Error("Failed to marshal message payload: %v", err)
		return fmt.Errorf("failed to marshal message payload: %w", err)
	}

	c.logger.Debug("Message payload: %s", string(payloadData))

	req, err := http.NewRequestWithContext(ctx, "POST", sendURL, bytes.NewBuffer(payloadData))
	if err != nil {
		c.logger.Error("Failed to create message request: %v", err)
		return fmt.Errorf("failed to create message request: %w", err)
	}

	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+token)

	resp, err := c.httpClient.Do(req)
	if err != nil {
		c.logger.Error("Failed to send message request: %v", err)
		return fmt.Errorf("failed to send message request: %w", err)
	}
	defer resp.Body.Close()

	var response map[string]any
	if err := json.NewDecoder(resp.Body).Decode(&response); err != nil {
		c.logger.Error("Failed to decode message response: %v", err)
		return fmt.Errorf("failed to decode message response: %w", err)
	}

	if resp.StatusCode != http.StatusOK {
		c.logger.Error("Message send failed: status=%d, response=%v", resp.StatusCode, response)
		return fmt.Errorf("message send failed: status=%d, response=%v", resp.StatusCode, response)
	}

	if code, ok := response["code"].(float64); ok && code != 0 {
		msg, _ := response["msg"].(string)
		c.logger.Error("Message API error: code=%v, msg=%s", code, msg)
		return fmt.Errorf("message API error: code=%v, msg=%s", code, msg)
	}

	data, ok := response["data"].(map[string]any)
	if !ok {
		c.logger.Error("Invalid response data format: %v", response)
		return fmt.Errorf("invalid response data format")
	}

	messageID, ok := data["message_id"].(string)
	if !ok {
		c.logger.Error("Message ID not found in response: %v", data)
		return fmt.Errorf("message ID not found in response")
	}

	c.logger.Info("Message sent successfully, message_id: %s", messageID)

	return nil
}
