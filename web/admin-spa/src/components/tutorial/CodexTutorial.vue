<template>
  <div class="tutorial-section">
    <!-- 第一步：安装 Node.js -->
    <NodeInstallTutorial :platform="platform" :step-number="1" tool-name="Codex" />

    <!-- 第二步：安装 Codex -->
    <div class="mb-4 sm:mb-10 sm:mb-6">
      <h4
        class="mb-3 flex items-center text-lg font-semibold text-gray-800 dark:text-gray-300 sm:mb-4 sm:text-xl"
      >
        <span
          class="mr-2 flex h-6 w-6 items-center justify-center rounded-full bg-green-500 text-xs font-bold text-white sm:mr-3 sm:h-8 sm:w-8 sm:text-sm"
          >2</span
        >
        安装 Codex
      </h4>

      <div class="space-y-4">
        <!-- Codex CLI 安装 -->
        <div
          class="rounded-xl border border-green-100 bg-gradient-to-r from-green-50 to-emerald-50 p-4 dark:border-green-500/40 dark:from-green-950/30 dark:to-emerald-950/30 sm:p-6"
        >
          <h5
            class="mb-2 flex items-center text-base font-semibold text-gray-800 dark:text-gray-200 sm:mb-3 sm:text-lg"
          >
            <i class="fas fa-terminal mr-2 text-green-600" />
            安装 Codex CLI
          </h5>
          <p class="mb-3 text-sm text-gray-700 dark:text-gray-300 sm:mb-4 sm:text-base">
            {{ platform === 'windows' ? '打开 PowerShell' : '打开终端' }}，运行以下命令：
          </p>
          <div
            class="mb-4 overflow-x-auto rounded-lg bg-gray-900 p-3 font-mono text-xs text-green-400 sm:p-4 sm:text-sm"
          >
            <div class="mb-2"># 全局安装 Codex CLI</div>
            <div class="whitespace-nowrap text-gray-300">
              {{
                platform === 'windows'
                  ? 'npm install -g @openai/codex'
                  : 'sudo npm install -g @openai/codex'
              }}
            </div>
          </div>

          <!-- 验证安装 -->
          <div
            class="rounded-lg border border-green-200 bg-green-50 p-3 dark:border-green-500/40 dark:bg-green-950/30 sm:p-4"
          >
            <h6 class="mb-2 font-medium text-green-800 dark:text-green-300">验证 Codex CLI 安装</h6>
            <p class="mb-3 text-sm text-green-700 dark:text-green-300">
              安装完成后，输入以下命令检查是否安装成功：
            </p>
            <div
              class="overflow-x-auto rounded bg-gray-900 p-2 font-mono text-xs text-green-400 sm:p-3 sm:text-sm"
            >
              <div class="whitespace-nowrap text-gray-300">codex --version</div>
            </div>
            <p class="mt-2 text-sm text-green-700 dark:text-green-300">
              如果显示版本号，说明 Codex CLI 安装成功。
            </p>
          </div>
        </div>

        <!-- Codex App (VS Code 插件) -->
        <div
          class="rounded-xl border border-indigo-100 bg-gradient-to-r from-indigo-50 to-blue-50 p-4 dark:border-indigo-500/40 dark:from-indigo-950/30 dark:to-blue-950/30 sm:p-6"
        >
          <h5
            class="mb-2 flex items-center text-base font-semibold text-gray-800 dark:text-gray-200 sm:mb-3 sm:text-lg"
          >
            <i class="fas fa-puzzle-piece mr-2 text-indigo-600" />
            安装 Codex App（VS Code 插件）
          </h5>
          <p class="mb-3 text-sm text-gray-700 dark:text-gray-300 sm:mb-4 sm:text-base">
            如果你使用 VS Code，可以安装 Codex 插件获得更好的集成体验：
          </p>

          <div class="space-y-3">
            <div>
              <p class="mb-2 text-sm font-medium text-gray-700 dark:text-gray-300">
                方法一：VS Code 扩展商店（推荐）
              </p>
              <ol
                class="ml-2 list-inside list-decimal space-y-1 text-xs text-gray-600 dark:text-gray-400 sm:ml-4 sm:space-y-2 sm:text-sm"
              >
                <li>打开 VS Code</li>
                <li>
                  按
                  <code class="rounded bg-gray-100 px-1 dark:bg-gray-800 dark:text-yellow-400"
                    >Ctrl+Shift+X</code
                  >
                  打开扩展面板
                </li>
                <li>
                  搜索
                  <code class="rounded bg-gray-100 px-1 dark:bg-gray-800 dark:text-yellow-400"
                    >Codex</code
                  >，找到 OpenAI 发布的 <strong>Codex</strong> 插件
                </li>
                <li>点击 "Install" 安装</li>
              </ol>
            </div>

            <div>
              <p class="mb-2 text-sm font-medium text-gray-700 dark:text-gray-300">
                方法二：命令行安装
              </p>
              <div
                class="overflow-x-auto rounded-lg bg-gray-900 p-3 font-mono text-xs text-green-400 sm:p-4 sm:text-sm"
              >
                <div class="whitespace-nowrap text-gray-300">
                  code --install-extension openai.codex
                </div>
              </div>
            </div>
          </div>

          <div
            class="mt-4 rounded-lg border border-indigo-200 bg-indigo-50 p-3 dark:border-indigo-500/40 dark:bg-indigo-950/30 sm:p-4"
          >
            <h6 class="mb-2 text-sm font-medium text-indigo-800 dark:text-indigo-300 sm:text-base">
              提示
            </h6>
            <ul class="space-y-1 text-xs text-indigo-700 dark:text-indigo-300 sm:text-sm">
              <li>Codex CLI 和 Codex App 可以独立使用，也可以同时安装</li>
              <li>
                Codex App 内置了 Codex CLI，安装插件后可在 VS Code 终端内直接使用
                <code class="rounded bg-indigo-100 px-1 dark:bg-indigo-900">codex</code> 命令
              </li>
            </ul>
          </div>
        </div>
      </div>
    </div>

    <!-- 第三步：配置 Codex -->
    <div class="mb-4 sm:mb-10 sm:mb-6">
      <h4
        class="mb-3 flex items-center text-lg font-semibold text-gray-800 dark:text-gray-300 sm:mb-4 sm:text-xl"
      >
        <span
          class="mr-2 flex h-6 w-6 items-center justify-center rounded-full bg-indigo-500 text-xs font-bold text-white sm:mr-3 sm:h-8 sm:w-8 sm:text-sm"
          >3</span
        >
        配置 Codex
      </h4>
      <p class="mb-3 text-sm text-gray-700 dark:text-gray-300 sm:mb-4 sm:text-base">
        配置 Codex 以连接到中转服务：
      </p>

      <div class="space-y-4">
        <!-- config.toml 配置 -->
        <div
          class="rounded-lg border border-yellow-200 bg-yellow-50 p-3 dark:border-yellow-500/40 dark:bg-yellow-950/30 sm:p-4"
        >
          <h6 class="mb-2 font-medium text-yellow-800 dark:text-yellow-300">
            1. 配置文件 config.toml
          </h6>
          <p class="mb-3 text-sm text-yellow-700 dark:text-yellow-300">
            在
            <code class="rounded bg-yellow-100 px-1 dark:bg-yellow-900">{{ configPath }}</code>
            文件开头添加以下配置：
          </p>
          <div
            class="overflow-x-auto rounded bg-gray-900 p-2 font-mono text-xs text-green-400 sm:p-3 sm:text-sm"
          >
            <div
              v-for="line in configTomlLines"
              :key="line"
              class="whitespace-nowrap text-gray-300"
              :class="{ 'mt-2': line === '' }"
            >
              {{ line || '&nbsp;' }}
            </div>
          </div>
          <p class="mt-3 text-sm text-yellow-600 dark:text-yellow-400">一键写入命令：</p>
          <div
            class="mt-2 overflow-x-auto rounded bg-gray-900 p-2 font-mono text-xs text-green-400 sm:p-3 sm:text-sm"
          >
            <div class="whitespace-nowrap text-gray-300">{{ configTomlWriteCmd }}</div>
          </div>
        </div>

        <!-- auth.json 配置 -->
        <div
          class="rounded-lg border border-orange-200 bg-orange-50 p-3 dark:border-orange-500/40 dark:bg-orange-950/30 sm:p-4"
        >
          <h6 class="mb-2 font-medium text-orange-800 dark:text-orange-300">
            2. 认证文件 auth.json
          </h6>
          <p class="mb-3 text-sm text-orange-700 dark:text-orange-300">
            在
            <code class="rounded bg-orange-100 px-1 dark:bg-orange-900">{{ authPath }}</code>
            文件中配置：
          </p>
          <div
            class="overflow-x-auto rounded bg-gray-900 p-2 font-mono text-xs text-green-400 sm:p-3 sm:text-sm"
          >
            <div class="whitespace-nowrap text-gray-300">{</div>
            <div class="whitespace-nowrap text-gray-300">
              &nbsp;&nbsp;"OPENAI_API_KEY": "后台创建的API密钥"
            </div>
            <div class="whitespace-nowrap text-gray-300">}</div>
          </div>
          <p class="mt-3 text-sm text-orange-600 dark:text-orange-400">一键写入命令：</p>
          <div
            class="mt-2 overflow-x-auto rounded bg-gray-900 p-2 font-mono text-xs text-green-400 sm:p-3 sm:text-sm"
          >
            <div class="whitespace-nowrap text-gray-300">{{ authJsonWriteCmd }}</div>
          </div>
        </div>

        <!-- 提示 -->
        <div
          class="rounded-lg border border-yellow-200 bg-yellow-50 p-3 dark:border-yellow-500/40 dark:bg-yellow-950/30 sm:p-4"
        >
          <p class="text-sm text-yellow-700 dark:text-yellow-300">
            请将示例中的
            <code class="rounded bg-yellow-100 px-1 dark:bg-yellow-900">cr_xxxxxxxxxx</code>
            替换为您的实际 API 密钥
          </p>
        </div>
      </div>
    </div>

    <!-- 一键安装脚本 -->
    <div class="mb-4 sm:mb-10 sm:mb-6">
      <h4
        class="mb-3 flex items-center text-lg font-semibold text-gray-800 dark:text-gray-300 sm:mb-4 sm:text-xl"
      >
        <i class="fas fa-bolt mr-2 text-amber-500 sm:mr-3" />
        一键安装脚本
      </h4>
      <p class="mb-3 text-sm text-gray-700 dark:text-gray-300 sm:mb-4 sm:text-base">
        下载脚本后运行，自动完成 Codex 安装和配置（需提前安装 Node.js）：
      </p>

      <div class="space-y-4">
        <!-- macOS / Linux -->
        <div
          v-if="platform !== 'windows'"
          class="rounded-xl border border-emerald-100 bg-gradient-to-r from-emerald-50 to-teal-50 p-4 dark:border-emerald-500/40 dark:from-emerald-950/30 dark:to-teal-950/30 sm:p-6"
        >
          <h5
            class="mb-2 flex items-center text-base font-semibold text-gray-800 dark:text-gray-200 sm:mb-3 sm:text-lg"
          >
            <i class="fas fa-terminal mr-2 text-emerald-600" />
            {{ platform === 'macos' ? 'macOS' : 'Linux / WSL2' }} 一键安装
          </h5>
          <p class="mb-3 text-sm text-gray-700 dark:text-gray-300">
            复制以下命令到终端运行，会提示你输入 API 密钥：
          </p>
          <div
            class="overflow-x-auto rounded-lg bg-gray-900 p-3 font-mono text-xs text-green-400 sm:p-4 sm:text-sm"
          >
            <div class="whitespace-nowrap text-gray-300">{{ bashOneliner }}</div>
          </div>
          <div class="mt-3">
            <p class="mb-2 text-sm text-gray-600 dark:text-gray-400">或者下载脚本后运行：</p>
            <div
              class="overflow-x-auto rounded-lg bg-gray-900 p-3 font-mono text-xs text-green-400 sm:p-4 sm:text-sm"
            >
              <div class="whitespace-nowrap text-gray-300">
                curl -fsSL {{ scriptBaseUrl }}/codex-setup.sh -o codex-setup.sh
              </div>
              <div class="whitespace-nowrap text-gray-300">chmod +x codex-setup.sh</div>
              <div class="whitespace-nowrap text-gray-300">./codex-setup.sh YOUR_API_KEY</div>
            </div>
          </div>
        </div>

        <!-- Windows -->
        <div
          v-else
          class="rounded-xl border border-blue-100 bg-gradient-to-r from-blue-50 to-indigo-50 p-4 dark:border-blue-500/40 dark:from-blue-950/30 dark:to-indigo-950/30 sm:p-6"
        >
          <h5
            class="mb-2 flex items-center text-base font-semibold text-gray-800 dark:text-gray-200 sm:mb-3 sm:text-lg"
          >
            <i class="fab fa-windows mr-2 text-blue-600" />
            Windows 一键安装（PowerShell）
          </h5>
          <p class="mb-3 text-sm text-gray-700 dark:text-gray-300">
            以管理员身份打开 PowerShell，复制以下命令运行：
          </p>
          <div
            class="overflow-x-auto rounded-lg bg-gray-900 p-3 font-mono text-xs text-green-400 sm:p-4 sm:text-sm"
          >
            <div class="whitespace-nowrap text-gray-300">{{ psOneliner }}</div>
          </div>
          <div class="mt-3">
            <p class="mb-2 text-sm text-gray-600 dark:text-gray-400">或者下载脚本后运行：</p>
            <div
              class="overflow-x-auto rounded-lg bg-gray-900 p-3 font-mono text-xs text-green-400 sm:p-4 sm:text-sm"
            >
              <div class="whitespace-nowrap text-gray-300">
                Invoke-WebRequest -Uri "{{ scriptBaseUrl }}/codex-setup.ps1" -OutFile
                "codex-setup.ps1"
              </div>
              <div class="whitespace-nowrap text-gray-300">
                .\codex-setup.ps1 -ApiKey "YOUR_API_KEY"
              </div>
            </div>
          </div>
        </div>

        <!-- 脚本说明 -->
        <div
          class="rounded-lg border border-gray-200 bg-gray-50 p-3 dark:border-gray-700 dark:bg-gray-800 sm:p-4"
        >
          <h6 class="mb-2 font-medium text-gray-800 dark:text-gray-300">脚本功能说明</h6>
          <ul class="space-y-1 text-xs text-gray-600 dark:text-gray-400 sm:text-sm">
            <li>1. 检测 Node.js 是否已安装</li>
            <li>
              2. 安装 Codex CLI（<code class="rounded bg-gray-200 px-1 dark:bg-gray-700"
                >@openai/codex</code
              >）
            </li>
            <li>3. 自动生成 config.toml 和 auth.json 配置文件</li>
            <li>4. 验证安装结果</li>
          </ul>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import { useTutorialUrls } from '@/utils/useTutorialUrls'
import NodeInstallTutorial from './NodeInstallTutorial.vue'

const props = defineProps({
  platform: {
    type: String,
    required: true,
    validator: (value) => ['windows', 'macos', 'linux'].includes(value)
  }
})

const { openaiBaseUrl } = useTutorialUrls()

const scriptBaseUrl = computed(() => {
  const origin = window.location.origin || ''
  return origin + '/web'
})

const configPath = computed(() =>
  props.platform === 'windows' ? '%USERPROFILE%\\.codex\\config.toml' : '~/.codex/config.toml'
)

const authPath = computed(() =>
  props.platform === 'windows' ? '%USERPROFILE%\\.codex\\auth.json' : '~/.codex/auth.json'
)

const configTomlLines = computed(() => [
  'model_provider = "crs"',
  'model = "gpt-5-codex"',
  'model_reasoning_effort = "high"',
  'disable_response_storage = true',
  'preferred_auth_method = "apikey"',
  '',
  '[model_providers.crs]',
  'name = "crs"',
  `base_url = "${openaiBaseUrl.value}"`,
  'wire_api = "responses"',
  'requires_openai_auth = true'
])

const configTomlContent = computed(() => configTomlLines.value.join('\n'))

const configTomlWriteCmd = computed(() => {
  if (props.platform === 'windows') {
    const escaped = configTomlContent.value.replace(/"/g, '`"').replace(/\n/g, '`n')
    return `New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\\.codex" | Out-Null; "${escaped}" | Set-Content -Path "$env:USERPROFILE\\.codex\\config.toml" -Force`
  }
  const escaped = configTomlContent.value.replace(/\n/g, '\\n')
  return `mkdir -p ~/.codex && printf '${escaped}\\n' > ~/.codex/config.toml`
})

const authJsonWriteCmd = computed(() => {
  if (props.platform === 'windows') {
    return `New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\\.codex" | Out-Null; '{"OPENAI_API_KEY": null}' | Set-Content -Path "$env:USERPROFILE\\.codex\\auth.json" -Force`
  }
  return `mkdir -p ~/.codex && echo '{"OPENAI_API_KEY": null}' > ~/.codex/auth.json`
})

const bashOneliner = computed(
  () => `curl -fsSL ${scriptBaseUrl.value}/codex-setup.sh | bash -s -- YOUR_API_KEY`
)

const psOneliner = computed(() => `irm "${scriptBaseUrl.value}/codex-setup.ps1" | iex`)
</script>
