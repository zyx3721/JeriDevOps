<template>
  <div class="dingtalk-message">
    <div class="page-header">
      <h1>钉钉管理</h1>
      <a-space>
        <a-button v-if="activeTab === 'apps'" type="primary" size="small" @click="showAppModal()">
          <template #icon><PlusOutlined /></template>
          添加应用
        </a-button>
        <a-button v-if="activeTab === 'bots'" type="primary" size="small" @click="showBotModal()">
          <template #icon><PlusOutlined /></template>
          添加机器人
        </a-button>
      </a-space>
    </div>

    <a-tabs v-model:activeKey="activeTab">
      <!-- 应用管理 Tab -->
      <a-tab-pane key="apps" tab="应用管理">
        <a-card :bordered="false">
          <a-table :columns="appColumns" :data-source="appList" :loading="loadingApps" row-key="id" :pagination="{ pageSize: 10 }">
            <template #bodyCell="{ column, record }">
              <template v-if="column.key === 'app_key'">
                <a-typography-text copyable :content="record.app_key">{{ record.app_key }}</a-typography-text>
              </template>
              <template v-if="column.key === 'status'">
                <a-badge :status="record.status === 'active' ? 'success' : 'default'" :text="record.status === 'active' ? '启用' : '禁用'" />
              </template>
              <template v-if="column.key === 'is_default'">
                <a-tag v-if="record.is_default" color="blue">默认</a-tag>
                <a-button v-else type="link" size="small" @click="setDefaultApp(record.id)">设为默认</a-button>
              </template>
              <template v-if="column.key === 'bindings'">
                <div v-if="record.bindings">
                  <a-tooltip v-for="jenkins in record.bindings.jenkins_instances" :key="'j'+jenkins.id" :title="jenkins.url">
                    <a-tag color="orange" style="margin: 2px;">Jenkins: {{ jenkins.name }}</a-tag>
                  </a-tooltip>
                  <a-tag v-for="k8s in record.bindings.k8s_clusters" :key="'k'+k8s.id" color="blue" style="margin: 2px;">K8s: {{ k8s.name }}</a-tag>
                  <span v-if="!record.bindings.jenkins_instances?.length && !record.bindings.k8s_clusters?.length" style="color: #999">-</span>
                </div>
                <span v-else style="color: #999">-</span>
              </template>
              <template v-if="column.key === 'action'">
                <a-space>
                  <a-button type="link" size="small" @click="showAppModal(record)">编辑</a-button>
                  <a-popconfirm title="确定删除？" @confirm="() => deleteApp(record.id)" :disabled="!record.id">
                    <a-button type="link" size="small" danger :disabled="record.is_default">删除</a-button>
                  </a-popconfirm>
                </a-space>
              </template>
            </template>
          </a-table>
        </a-card>
      </a-tab-pane>

      <!-- 机器人管理 Tab -->
      <a-tab-pane key="bots" tab="机器人管理">
        <a-card :bordered="false">
          <a-table :columns="botColumns" :data-source="botList" :loading="loadingBots" row-key="id" :pagination="{ pageSize: 10 }">
            <template #bodyCell="{ column, record }">
              <template v-if="column.key === 'webhook_url'">
                <a-typography-text copyable :content="record.webhook_url" ellipsis style="max-width: 300px">{{ record.webhook_url }}</a-typography-text>
              </template>
              <template v-if="column.key === 'status'">
                <a-badge :status="record.status === 'active' ? 'success' : 'default'" :text="record.status === 'active' ? '启用' : '禁用'" />
              </template>
              <template v-if="column.key === 'action'">
                <a-space>
                  <a-button type="link" size="small" @click="showBotModal(record)">编辑</a-button>
                  <a-popconfirm title="确定删除？" @confirm="() => deleteBot(record.id)" :disabled="!record.id">
                    <a-button type="link" size="small" danger>删除</a-button>
                  </a-popconfirm>
                </a-space>
              </template>
            </template>
          </a-table>
        </a-card>
      </a-tab-pane>

      <!-- 发送消息 Tab -->
      <a-tab-pane key="message" tab="发送消息">
        <a-row :gutter="24">
          <a-col :xs="24" :lg="12">
            <a-card title="工作通知" :bordered="false">
              <a-form :model="messageForm" layout="vertical">
                <a-form-item label="选择应用">
                  <a-select v-model:value="messageForm.app_id" placeholder="使用默认应用" style="width: 100%" allow-clear>
                    <a-select-option v-for="app in appList" :key="app.id" :value="app.id">{{ app.name }}</a-select-option>
                  </a-select>
                </a-form-item>
                <a-form-item label="接收用户ID" required>
                  <a-input v-model:value="messageForm.userid_list" placeholder="多个用户用逗号分隔" />
                </a-form-item>
                <a-form-item label="消息类型" required>
                  <a-radio-group v-model:value="messageForm.msg_type" button-style="solid">
                    <a-radio-button value="text">文本</a-radio-button>
                    <a-radio-button value="markdown">Markdown</a-radio-button>
                  </a-radio-group>
                </a-form-item>
                <a-form-item v-if="messageForm.msg_type === 'markdown'" label="标题">
                  <a-input v-model:value="messageForm.title" placeholder="消息标题" />
                </a-form-item>
                <a-form-item label="消息内容" required>
                  <a-textarea v-model:value="messageForm.content" :placeholder="messageContentPlaceholder" :rows="6" />
                </a-form-item>
                <a-form-item>
                  <a-button type="primary" @click="sendMessage" :loading="sendingMessage" block>
                    <template #icon><SendOutlined /></template>发送工作通知
                  </a-button>
                </a-form-item>
              </a-form>
            </a-card>
          </a-col>
          <a-col :xs="24" :lg="12">
            <a-card title="Webhook消息" :bordered="false">
              <a-form :model="webhookForm" layout="vertical">
                <a-form-item label="选择机器人" required>
                  <a-select v-model:value="webhookForm.bot_id" placeholder="请选择机器人" style="width: 100%">
                    <a-select-option v-for="bot in botList" :key="bot.id" :value="bot.id">{{ bot.name }}</a-select-option>
                  </a-select>
                </a-form-item>
                <a-form-item label="消息类型" required>
                  <a-radio-group v-model:value="webhookForm.msg_type" button-style="solid">
                    <a-radio-button value="text">文本</a-radio-button>
                    <a-radio-button value="markdown">Markdown</a-radio-button>
                  </a-radio-group>
                </a-form-item>
                <a-form-item v-if="webhookForm.msg_type === 'markdown'" label="标题">
                  <a-input v-model:value="webhookForm.title" placeholder="消息标题" />
                </a-form-item>
                <a-form-item label="消息内容" required>
                  <a-textarea v-model:value="webhookForm.content" :placeholder="webhookContentPlaceholder" :rows="4" />
                </a-form-item>
                <a-form-item label="@用户">
                  <a-select v-model:value="webhookForm.at_users" mode="tags" placeholder="输入用户ID后回车" style="width: 100%" />
                </a-form-item>
                <a-form-item><a-checkbox v-model:checked="webhookForm.at_all">@所有人</a-checkbox></a-form-item>
                <a-form-item>
                  <a-button type="primary" @click="sendWebhook" :loading="sendingWebhook" block>
                    <template #icon><SendOutlined /></template>发送Webhook消息
                  </a-button>
                </a-form-item>
              </a-form>
            </a-card>
          </a-col>
        </a-row>
      </a-tab-pane>

      <!-- 发送记录 Tab -->
      <a-tab-pane key="logs" tab="发送记录">
        <a-card :bordered="false">
          <template #extra>
            <a-space>
              <a-select v-model:value="logFilter.source" placeholder="来源" style="width: 120px" allow-clear @change="fetchLogs">
                <a-select-option value="manual">手动发送</a-select-option>
              </a-select>
              <a-button @click="fetchLogs"><template #icon><ReloadOutlined /></template></a-button>
            </a-space>
          </template>
          <a-table :columns="logColumns" :data-source="logList" :loading="loadingLogs" row-key="id" :pagination="logPagination" @change="onLogTableChange">
            <template #bodyCell="{ column, record }">
              <template v-if="column.key === 'msg_type'">
                <a-tag :color="record.msg_type === 'markdown' ? 'blue' : 'default'">{{ record.msg_type }}</a-tag>
              </template>
              <template v-if="column.key === 'status'">
                <a-badge :status="record.status === 'success' ? 'success' : 'error'" :text="record.status === 'success' ? '成功' : '失败'" />
              </template>
              <template v-if="column.key === 'created_at'">{{ formatTime(record.created_at) }}</template>
              <template v-if="column.key === 'action'">
                <a-button type="link" size="small" @click="viewLogDetail(record)">详情</a-button>
              </template>
            </template>
          </a-table>
        </a-card>
      </a-tab-pane>

      <!-- 用户搜索 Tab -->
      <a-tab-pane key="users" tab="用户搜索">
        <a-card :bordered="false">
          <a-row :gutter="16" style="margin-bottom: 16px">
            <a-col :span="16">
              <a-input-search v-model:value="userSearchQuery" placeholder="输入用户名搜索" enter-button="搜索" @search="searchUsers" :loading="searchingUsers" />
            </a-col>
          </a-row>
          <a-table :columns="userColumns" :data-source="userList" :loading="searchingUsers" row-key="userid" :pagination="false">
            <template #bodyCell="{ column, record }">
              <template v-if="column.key === 'userid'">
                <a-typography-text copyable :content="record.userid">{{ record.userid }}</a-typography-text>
              </template>
              <template v-if="column.key === 'action'">
                <a-button type="link" size="small" @click="selectUser(record)">选择</a-button>
              </template>
            </template>
          </a-table>
        </a-card>
      </a-tab-pane>
    </a-tabs>

    <!-- 应用编辑弹窗 -->
    <a-modal v-model:open="appModalVisible" :title="editingAppId ? '编辑应用' : '添加应用'" @ok="saveApp" :confirm-loading="savingApp" width="600px">
      <a-form :model="editingApp" layout="vertical">
        <a-row :gutter="16">
          <a-col :span="12"><a-form-item label="应用名称" required><a-input v-model:value="editingApp.name" placeholder="我的钉钉应用" /></a-form-item></a-col>
          <a-col :span="12"><a-form-item label="项目" required><a-input v-model:value="editingApp.project" placeholder="项目标识" /></a-form-item></a-col>
        </a-row>
        <a-row :gutter="16">
          <a-col :span="12"><a-form-item label="App Key" required><a-input v-model:value="editingApp.app_key" placeholder="应用AppKey" /></a-form-item></a-col>
          <a-col :span="12"><a-form-item label="App Secret" required><a-input-password v-model:value="editingApp.app_secret" placeholder="应用密钥" /></a-form-item></a-col>
        </a-row>
        <a-form-item label="Agent ID" required><a-input-number v-model:value="editingApp.agent_id" placeholder="应用AgentId" style="width: 100%" /></a-form-item>
        <a-form-item label="描述"><a-textarea v-model:value="editingApp.description" :rows="2" /></a-form-item>
        <a-row :gutter="16">
          <a-col :span="12">
            <a-form-item label="状态">
              <a-select v-model:value="editingApp.status" style="width: 100%">
                <a-select-option value="active">启用</a-select-option>
                <a-select-option value="inactive">禁用</a-select-option>
              </a-select>
            </a-form-item>
          </a-col>
          <a-col :span="12"><a-form-item label=" "><a-checkbox v-model:checked="editingApp.is_default">设为默认应用</a-checkbox></a-form-item></a-col>
        </a-row>
      </a-form>
    </a-modal>

    <!-- 机器人编辑弹窗 -->
    <a-modal v-model:open="botModalVisible" :title="editingBotId ? '编辑机器人' : '添加机器人'" @ok="saveBot" :confirm-loading="savingBot" width="600px">
      <a-form :model="editingBot" layout="vertical">
        <a-form-item label="机器人名称" required><a-input v-model:value="editingBot.name" placeholder="我的机器人" /></a-form-item>
        <a-form-item label="Webhook URL" required><a-input v-model:value="editingBot.webhook_url" placeholder="https://oapi.dingtalk.com/robot/send?access_token=xxx" /></a-form-item>
        <a-form-item label="签名密钥"><a-input-password v-model:value="editingBot.secret" placeholder="可选，用于签名验证" /></a-form-item>
        <a-form-item label="描述"><a-textarea v-model:value="editingBot.description" :rows="2" /></a-form-item>
        <a-form-item label="状态">
          <a-select v-model:value="editingBot.status" style="width: 100%">
            <a-select-option value="active">启用</a-select-option>
            <a-select-option value="inactive">禁用</a-select-option>
          </a-select>
        </a-form-item>
      </a-form>
    </a-modal>

    <!-- 日志详情抽屉 -->
    <a-drawer v-model:open="logDetailVisible" title="发送详情" placement="right" :width="500">
      <a-descriptions :column="1" bordered size="small">
        <a-descriptions-item label="发送时间">{{ formatTime(currentLog?.created_at) }}</a-descriptions-item>
        <a-descriptions-item label="消息类型"><a-tag>{{ currentLog?.msg_type }}</a-tag></a-descriptions-item>
        <a-descriptions-item label="接收者">{{ currentLog?.target }}</a-descriptions-item>
        <a-descriptions-item label="标题">{{ currentLog?.title || '-' }}</a-descriptions-item>
        <a-descriptions-item label="状态">
          <a-badge :status="currentLog?.status === 'success' ? 'success' : 'error'" :text="currentLog?.status === 'success' ? '成功' : '失败'" />
        </a-descriptions-item>
        <a-descriptions-item v-if="currentLog?.error_msg" label="错误信息">
          <a-typography-text type="danger">{{ currentLog?.error_msg }}</a-typography-text>
        </a-descriptions-item>
      </a-descriptions>
      <a-divider orientation="left">消息内容</a-divider>
      <pre class="content-preview">{{ currentLog?.content }}</pre>
    </a-drawer>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted } from 'vue'
import { message } from 'ant-design-vue'
import { SendOutlined, PlusOutlined, ReloadOutlined } from '@ant-design/icons-vue'
import { dingtalkAppApi, dingtalkBotApi, dingtalkApi, dingtalkLogApi, type DingtalkApp, type DingtalkBot, type DingtalkMessageLog, type DingtalkUser } from '@/services/dingtalk'

const activeTab = ref('apps')
const sendingMessage = ref(false)
const sendingWebhook = ref(false)
const loadingApps = ref(false)
const loadingBots = ref(false)
const loadingLogs = ref(false)
const savingApp = ref(false)
const savingBot = ref(false)
const searchingUsers = ref(false)
const appModalVisible = ref(false)
const botModalVisible = ref(false)
const logDetailVisible = ref(false)
const appList = ref<DingtalkApp[]>([])
const botList = ref<DingtalkBot[]>([])
const logList = ref<DingtalkMessageLog[]>([])
const userList = ref<DingtalkUser[]>([])
const currentLog = ref<DingtalkMessageLog | null>(null)
const editingAppId = ref<number | undefined>(undefined)
const editingBotId = ref<number | undefined>(undefined)
const userSearchQuery = ref('')

const editingApp = reactive<Partial<DingtalkApp>>({ name: '', app_key: '', app_secret: '', agent_id: 0, project: '', description: '', status: 'active', is_default: false })
const editingBot = reactive<Partial<DingtalkBot>>({ name: '', webhook_url: '', secret: '', description: '', status: 'active' })
const messageForm = reactive({ app_id: undefined as number | undefined, userid_list: '', msg_type: 'text', content: '', title: '' })
const webhookForm = reactive({ bot_id: undefined as number | undefined, msg_type: 'text', content: '', title: '', at_users: [] as string[], at_all: false })
const logFilter = reactive({ source: '', msg_type: '' })
const logPagination = reactive({ current: 1, pageSize: 20, total: 0, showSizeChanger: true, showTotal: (total: number) => `共 ${total} 条` })

const appColumns = [
  { title: '名称', dataIndex: 'name', key: 'name', width: 120 },
  { title: 'App Key', dataIndex: 'app_key', key: 'app_key', width: 180 },
  { title: 'Agent ID', dataIndex: 'agent_id', key: 'agent_id', width: 120 },
  { title: '绑定资源', key: 'bindings', width: 200 },
  { title: '项目', dataIndex: 'project', key: 'project', width: 100 },
  { title: '状态', dataIndex: 'status', key: 'status', width: 80 },
  { title: '默认', dataIndex: 'is_default', key: 'is_default', width: 100 },
  { title: '操作', key: 'action', width: 120 }
]

const botColumns = [
  { title: '名称', dataIndex: 'name', key: 'name', width: 150 },
  { title: 'Webhook URL', dataIndex: 'webhook_url', key: 'webhook_url', ellipsis: true },
  { title: '描述', dataIndex: 'description', key: 'description', ellipsis: true },
  { title: '状态', dataIndex: 'status', key: 'status', width: 80 },
  { title: '操作', key: 'action', width: 120 }
]

const logColumns = [
  { title: '时间', dataIndex: 'created_at', key: 'created_at', width: 180 },
  { title: '类型', dataIndex: 'msg_type', key: 'msg_type', width: 100 },
  { title: '接收者', dataIndex: 'target', key: 'target', width: 180, ellipsis: true },
  { title: '标题', dataIndex: 'title', key: 'title', ellipsis: true },
  { title: '状态', dataIndex: 'status', key: 'status', width: 80 },
  { title: '操作', key: 'action', width: 80 }
]

const userColumns = [
  { title: '姓名', dataIndex: 'name', key: 'name', width: 100 },
  { title: 'User ID', dataIndex: 'userid', key: 'userid', width: 200 },
  { title: '手机', dataIndex: 'mobile', key: 'mobile', width: 150 },
  { title: '操作', key: 'action', width: 80 }
]

const formatTime = (time?: string) => time ? new Date(time).toLocaleString('zh-CN') : '-'

const fetchApps = async () => {
  loadingApps.value = true
  try {
    const res = await dingtalkAppApi.list()
    if (res.code === 0) {
      const apps = res.data?.list || []
      // 获取每个应用的绑定信息
      for (const app of apps) {
        if (app.id) {
          try {
            const bindingsRes = await dingtalkAppApi.getBindings(app.id)
            if (bindingsRes.code === 0 && bindingsRes.data) {
              (app as any).bindings = bindingsRes.data
            }
          } catch {}
        }
      }
      appList.value = apps
    }
  } catch (e) { message.error('获取应用列表失败') }
  finally { loadingApps.value = false }
}

const fetchBots = async () => {
  loadingBots.value = true
  try {
    const res = await dingtalkBotApi.list()
    if (res.code === 0) botList.value = res.data?.list || []
  } catch (e) { message.error('获取机器人列表失败') }
  finally { loadingBots.value = false }
}

const fetchLogs = async () => {
  loadingLogs.value = true
  try {
    const res = await dingtalkLogApi.list(logPagination.current, logPagination.pageSize, logFilter.msg_type, logFilter.source)
    if (res.code === 0) { logList.value = res.data?.list || []; logPagination.total = res.data?.total || 0 }
  } catch (e) { message.error('获取日志失败') }
  finally { loadingLogs.value = false }
}

const onLogTableChange = (pagination: any) => { logPagination.current = pagination.current; logPagination.pageSize = pagination.pageSize; fetchLogs() }

const showAppModal = (app?: DingtalkApp) => {
  if (app) {
    editingAppId.value = app.id; Object.assign(editingApp, app)
  } else {
    editingAppId.value = undefined; Object.assign(editingApp, { name: '', app_key: '', app_secret: '', agent_id: 0, project: '', description: '', status: 'active', is_default: false })
  }
  appModalVisible.value = true
}

const saveApp = async () => {
  savingApp.value = true
  try {
    const res = editingAppId.value ? await dingtalkAppApi.update(editingAppId.value, editingApp) : await dingtalkAppApi.create(editingApp)
    if (res.code === 0) { message.success('保存成功'); appModalVisible.value = false; fetchApps() }
    else message.error(res.message || '保存失败')
  } catch (e) { message.error('保存失败') }
  finally { savingApp.value = false }
}

const deleteApp = async (id: number) => {
  try {
    const res = await dingtalkAppApi.delete(id)
    if (res.code === 0) { message.success('删除成功'); fetchApps() }
    else message.error(res.message || '删除失败')
  } catch (e) { message.error('删除失败') }
}

const setDefaultApp = async (id: number) => {
  try {
    const res = await dingtalkAppApi.setDefault(id)
    if (res.code === 0) { message.success('设置成功'); fetchApps() }
    else message.error(res.message || '设置失败')
  } catch (e) { message.error('设置失败') }
}

const showBotModal = (bot?: DingtalkBot) => {
  if (bot) {
    editingBotId.value = bot.id; Object.assign(editingBot, bot)
  } else {
    editingBotId.value = undefined; Object.assign(editingBot, { name: '', webhook_url: '', secret: '', description: '', status: 'active' })
  }
  botModalVisible.value = true
}

const saveBot = async () => {
  savingBot.value = true
  try {
    const res = editingBotId.value ? await dingtalkBotApi.update(editingBotId.value, editingBot) : await dingtalkBotApi.create(editingBot)
    if (res.code === 0) { message.success('保存成功'); botModalVisible.value = false; fetchBots() }
    else message.error(res.message || '保存失败')
  } catch (e) { message.error('保存失败') }
  finally { savingBot.value = false }
}

const deleteBot = async (id: number) => {
  try {
    const res = await dingtalkBotApi.delete(id)
    if (res.code === 0) { message.success('删除成功'); fetchBots() }
    else message.error(res.message || '删除失败')
  } catch (e) { message.error('删除失败') }
}

const sendMessage = async () => {
  if (!messageForm.userid_list || !messageForm.content) { message.warning('请填写必填项'); return }
  sendingMessage.value = true
  try {
    const res = await dingtalkApi.sendMessage(messageForm)
    if (res.code === 0) { message.success('发送成功'); fetchLogs() }
    else message.error(res.message || '发送失败')
  } catch (e) { message.error('发送失败') }
  finally { sendingMessage.value = false }
}

const sendWebhook = async () => {
  if (!webhookForm.bot_id || !webhookForm.content) { message.warning('请填写必填项'); return }
  sendingWebhook.value = true
  try {
    const content = webhookForm.msg_type === 'markdown' ? { title: webhookForm.title, text: webhookForm.content } : { content: webhookForm.content }
    const res = await dingtalkApi.sendWebhook({ bot_id: webhookForm.bot_id, msg_type: webhookForm.msg_type, content, at_all: webhookForm.at_all, at_users: webhookForm.at_users })
    if (res.code === 0) message.success('发送成功')
    else message.error(res.message || '发送失败')
  } catch (e) { message.error('发送失败') }
  finally { sendingWebhook.value = false }
}

const searchUsers = async () => {
  if (!userSearchQuery.value) return
  searchingUsers.value = true
  try {
    const res = await dingtalkApi.searchUser(userSearchQuery.value)
    if (res.code === 0) userList.value = res.data || []
    else message.error(res.message || '搜索失败')
  } catch (e) { message.error('搜索失败') }
  finally { searchingUsers.value = false }
}

const selectUser = (user: DingtalkUser) => {
  messageForm.userid_list = messageForm.userid_list ? `${messageForm.userid_list},${user.userid}` : user.userid
  activeTab.value = 'message'
  message.success(`已选择用户: ${user.name}`)
}

const viewLogDetail = (log: DingtalkMessageLog) => { currentLog.value = log; logDetailVisible.value = true }

const messageContentPlaceholder = computed(() => {
  if (messageForm.msg_type === 'markdown') {
    return '示例：\n## 标题\n**加粗文字**\n普通文字\n[链接](https://example.com)'
  }
  return '示例：\n你好，这是一条测试消息'
})

const webhookContentPlaceholder = computed(() => {
  if (webhookForm.msg_type === 'markdown') {
    return '示例：\n## 标题\n**加粗文字**\n普通文字\n[链接](https://example.com)'
  }
  return '示例：\n你好，这是一条测试消息'
})

onMounted(() => { fetchApps(); fetchBots(); fetchLogs() })
</script>

<style scoped>
.dingtalk-message { padding: 0; }
.page-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px; }
.page-header h1 { margin: 0; font-size: 20px; }
.content-preview { background: #f5f5f5; padding: 12px; border-radius: 4px; white-space: pre-wrap; word-break: break-all; max-height: 300px; overflow: auto; }
</style>
