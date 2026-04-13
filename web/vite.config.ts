import { defineConfig, loadEnv } from 'vite'
import vue from '@vitejs/plugin-vue'
import * as path from 'path'

function normalizeBaseURL(raw: string): string {
  return String(raw || '').trim().replace(/\/+$/, '')
}

export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), '')
  const devApiTarget = normalizeBaseURL(env.VITE_API_BASE || 'http://localhost:8080')

  return {
    plugins: [vue() as any],
    root: '.',
    publicDir: 'public',
    resolve: {
      alias: {
        '@': path.resolve(__dirname, './src')
      }
    },
    build: {
      // 代码分割优化
      rollupOptions: {
        output: {
          // 手动配置代码分割策略
          manualChunks: {
            // 将 Vue 相关库打包到一起
            'vue-vendor': ['vue', 'vue-router'],
            // 将 Ant Design Vue 单独打包
            'antd-vendor': ['ant-design-vue', '@ant-design/icons-vue'],
            // 将应用管理相关页面打包到一起
            'app-pages': [
              './src/views/application/ApplicationList.vue',
              './src/views/application/ApplicationDetail.vue',
              './src/views/application/TrafficManagementEntry.vue',
              './src/views/application/AppTrafficManagement.vue',
              './src/views/application/DeployHistory.vue'
            ],
            // 将流水线相关页面打包到一起
            'pipeline-pages': [
              './src/views/pipeline/PipelineList.vue',
              './src/views/pipeline/PipelineDetail.vue',
              './src/views/pipeline/PipelineEditor.vue',
              './src/views/pipeline/PipelineDesigner.vue',
              './src/views/pipeline/PipelineStats.vue'
            ],
            // 将 K8s 相关页面打包到一起
            'k8s-pages': [
              './src/views/k8s/K8sClusters.vue',
              './src/views/k8s/K8sResources.vue',
              './src/views/k8s/PodManagement.vue',
              './src/views/k8s/DeploymentManagement.vue',
              './src/views/k8s/ClusterOverview.vue'
            ]
          },
          // 为每个 chunk 生成独立的文件名
          chunkFileNames: 'js/[name]-[hash].js',
          entryFileNames: 'js/[name]-[hash].js',
          assetFileNames: '[ext]/[name]-[hash].[ext]'
        }
      },
      // 设置 chunk 大小警告阈值
      chunkSizeWarningLimit: 1000,
      // 启用 CSS 代码分割
      cssCodeSplit: true,
      // 启用源码映射（生产环境可关闭）
      sourcemap: false
    },
    server: {
      host: '0.0.0.0',
      port: 3000,
      proxy: {
        '/app/api': {
          target: devApiTarget,
          changeOrigin: true,
          ws: true, // 启用 WebSocket 代理
          configure: (proxy) => {
            proxy.on('proxyReq', (proxyReq, req) => {
              // 设置更长的超时
              proxyReq.setTimeout(120000)
            })
            proxy.on('error', (err, req, res) => {
              console.log('proxy error', err)
            })
          }
        }
      }
    }
  }
})
