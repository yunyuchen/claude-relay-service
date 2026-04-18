<template>
  <div class="cr-theme min-h-screen" :class="{ dark: isDarkMode }">
    <div class="cr-page">
      <!-- 顶栏 -->
      <nav class="cr-nav">
        <div class="cr-brand">
          <img
            v-if="oemSettings.siteIconData || oemSettings.siteIcon"
            alt="logo"
            class="cr-logo-img"
            :src="oemSettings.siteIconData || oemSettings.siteIcon"
          />
          <div v-else class="cr-logo-fallback cr-serif">
            {{ (oemSettings.siteName || 'R').charAt(0).toUpperCase() }}
          </div>
          <span class="cr-brand-text">
            {{ oemSettings.siteName || 'Claude Relay' }}
            <span class="cr-sep">·</span>
            <span class="cr-brand-sub">统计</span>
          </span>
        </div>
        <div class="cr-nav-links">
          <router-link class="cr-nav-a" to="/insights">排行榜</router-link>
          <a class="cr-nav-a" @click="currentTab = 'tutorial'">使用教程</a>
          <ThemeToggleClaude />
          <router-link
            v-if="oemSettings.showAdminButton !== false"
            class="cr-nav-a cr-nav-a-primary"
            to="/dashboard"
            >管理后台</router-link
          >
        </div>
      </nav>

      <!-- 登录态：未输入 API Key -->
      <section v-if="!apiId && currentTab !== 'tutorial'" class="cr-auth">
        <div class="cr-card cr-auth-card">
          <h1 class="cr-serif cr-auth-title">输入 API Key</h1>
          <p class="cr-auth-sub">输入你的 API Key 查看用量、限额和模型使用情况</p>
          <ApiKeyInputClaude />
        </div>
      </section>

      <!-- 教程 tab -->
      <section v-else-if="currentTab === 'tutorial'" class="cr-tut">
        <div class="cr-page-title">
          <a class="cr-back" @click="currentTab = 'stats'">← 返回统计</a>
          <h1 class="cr-serif">使用教程</h1>
        </div>
        <div class="cr-card cr-tut-card">
          <TutorialView />
        </div>
      </section>

      <!-- 统计主体 -->
      <section v-else class="cr-main">
        <div class="cr-page-title">
          <h1 class="cr-serif">我的用量</h1>
          <p>查看花费、限额和各服务的模型使用情况</p>
        </div>

        <!-- Inline error -->
        <div v-if="error" class="cr-alert">
          <i class="fas fa-exclamation-triangle cr-alert-icon"></i>
          <span>{{ error }}</span>
        </div>

        <template v-if="loading && !statsData">
          <!-- Loading skeleton -->
          <div class="cr-card cr-loading">
            <div class="cr-skel cr-skel-hero"></div>
            <div class="cr-skel cr-skel-row"></div>
            <div class="cr-skel cr-skel-row"></div>
          </div>
        </template>
        <template v-else>
          <!-- Toolbar: identity + period + signout -->
          <div class="cr-toolbar">
            <div class="cr-identity">
              <div class="cr-avatar cr-serif">
                {{ (statsData?.name || 'K').charAt(0).toUpperCase() }}
              </div>
              <div>
                <div class="cr-id-name">{{ statsData?.name || apiId }}</div>
                <div class="cr-id-meta">
                  <span class="cr-status-dot"></span>
                  {{ statsData?.isActive === false ? '已停用' : '活跃' }}
                  <span v-if="multiKeyMode" class="cr-sep">·</span>
                  <span v-if="multiKeyMode" class="cr-badge">{{ apiIds.length }} 个 Key</span>
                  <span v-if="statsData?.expiresAt" class="cr-sep">·</span>
                  <span v-if="statsData?.expiresAt">{{ expiresInText }} 过期</span>
                </div>
              </div>
            </div>
            <div class="cr-toolbar-right">
              <div class="cr-period">
                <button
                  :class="{ active: statsPeriod === 'daily' }"
                  :disabled="loading"
                  @click="switchPeriod('daily')"
                >
                  今日
                </button>
                <button
                  :class="{ active: statsPeriod === 'yesterday' }"
                  :disabled="loading"
                  @click="switchPeriod('yesterday')"
                >
                  昨日
                </button>
                <button
                  :class="{ active: statsPeriod === 'monthly' }"
                  :disabled="loading"
                  @click="switchPeriod('monthly')"
                >
                  本月
                </button>
                <button
                  :class="{ active: statsPeriod === 'alltime' }"
                  :disabled="loading"
                  @click="switchPeriod('alltime')"
                >
                  全部
                </button>
              </div>
              <button class="cr-btn-ghost" @click="handleSignOut">退出</button>
            </div>
          </div>

          <!-- Hero row -->
          <div class="cr-hero-row">
            <div class="cr-hero">
              <div class="cr-hero-label">{{ periodLabel }}花费</div>
              <div class="cr-hero-n cr-serif cr-mono">
                {{ formatCurrencyHero(currentPeriodData.cost) }}
              </div>
              <div class="cr-delta-row">
                <span
                  v-if="costDelta !== null"
                  class="cr-delta"
                  :class="costDelta < 0 ? 'neg' : ''"
                >
                  {{ costDelta >= 0 ? '↑' : '↓' }} {{ Math.abs(costDelta).toFixed(0) }}% 对比上期
                </span>
                <span class="cr-sub-note">刚刚更新</span>
              </div>
            </div>

            <div class="cr-kpi">
              <div class="cr-kpi-label">Token</div>
              <div class="cr-kpi-n cr-serif cr-mono">
                {{ formatTokensShort(currentPeriodData.allTokens) }}
              </div>
              <div class="cr-kpi-d">
                <span class="cr-pill cr-mono"
                  >输入 {{ formatTokensShort(currentPeriodData.inputTokens) }}</span
                >
                <span class="cr-pill cr-mono"
                  >输出 {{ formatTokensShort(currentPeriodData.outputTokens) }}</span
                >
                <span
                  v-if="
                    (currentPeriodData.cacheReadTokens || 0) +
                      (currentPeriodData.cacheCreateTokens || 0) >
                    0
                  "
                  class="cr-pill cr-mono"
                  >缓存
                  {{
                    formatTokensShort(
                      (currentPeriodData.cacheReadTokens || 0) +
                        (currentPeriodData.cacheCreateTokens || 0)
                    )
                  }}</span
                >
              </div>
            </div>

            <div class="cr-kpi">
              <div class="cr-kpi-label">请求</div>
              <div class="cr-kpi-n cr-serif cr-mono">
                {{ (currentPeriodData.requests || 0).toLocaleString() }}
              </div>
              <div class="cr-kpi-d">
                <span v-if="successRate !== null" class="cr-pill cr-mono"
                  >成功率 {{ successRate.toFixed(1) }}%</span
                >
              </div>
            </div>

            <div v-if="avgLatencyMs !== null" class="cr-kpi cr-kpi-lat">
              <div class="cr-kpi-label">延迟</div>
              <div class="cr-kpi-n cr-serif cr-mono">
                {{ Math.round(avgLatencyMs) }}<span class="cr-unit">ms</span>
              </div>
              <div class="cr-kpi-d">
                <span class="cr-pill cr-mono">均值</span>
              </div>
            </div>
          </div>

          <!-- Dual block: quota + services -->
          <div class="cr-dual">
            <div>
              <div class="cr-sec-head">
                <h3 class="cr-serif">额度状态</h3>
                <span v-if="quotaRows.length" class="cr-sec-meta"
                  >已配置 {{ quotaRows.length }} 项限额</span
                >
                <span v-else class="cr-sec-meta">未配置限额</span>
              </div>
              <div
                v-if="quotaRows.length"
                class="cr-card cr-rings"
                :class="`n-${quotaRows.length}`"
              >
                <div
                  v-for="row in quotaRows"
                  :key="row.key"
                  class="cr-ring"
                  :class="row.stateClass"
                >
                  <div class="cr-ring-circle" :style="{ '--pct': row.percent + '%' }">
                    <div class="cr-ring-core">
                      <div class="cr-ring-pct cr-serif cr-mono">
                        {{ row.percent }}<span class="cr-ring-pct-unit">%</span>
                      </div>
                      <div class="cr-ring-lbl">{{ row.label }}</div>
                    </div>
                  </div>
                  <div class="cr-ring-meta cr-mono">{{ row.valueText }}</div>
                </div>
              </div>
              <div v-else class="cr-card cr-empty">当前 Key 未配置任何限额</div>
            </div>

            <div>
              <div class="cr-sec-head">
                <h3 class="cr-serif">服务分布</h3>
                <span class="cr-sec-meta"
                  >{{ serviceRows.length }} 项中 {{ activeServicesCount }} 项在用</span
                >
              </div>
              <div class="cr-card">
                <div
                  v-for="row in serviceRows"
                  :key="row.name"
                  class="cr-row cr-svc-row"
                  :class="{ empty: !row.cost }"
                >
                  <span class="cr-name">{{ row.label }}</span>
                  <span class="cr-val cr-mono">{{
                    row.cost ? formatCurrency(row.cost) : '—'
                  }}</span>
                  <div class="cr-bar">
                    <div v-if="row.cost" :style="{ width: row.percent + '%' }"></div>
                  </div>
                  <span class="cr-pct cr-mono">{{ row.cost ? row.percent + '%' : '—' }}</span>
                </div>
              </div>
            </div>
          </div>

          <!-- Top models -->
          <div class="cr-sec-head">
            <h3 class="cr-serif">模型排行</h3>
            <span class="cr-sec-meta">
              展示 {{ displayedModels.length }} / {{ sortedModels.length }}
            </span>
          </div>
          <div class="cr-card">
            <div v-for="(m, i) in displayedModels" :key="m.model" class="cr-row cr-mod-row">
              <span class="cr-rank cr-serif">{{ String(i + 1).padStart(2, '0') }}</span>
              <span class="cr-m">{{ m.model }}</span>
              <span class="cr-val cr-mono">{{ formatCurrency(m.cost) }}</span>
              <span class="cr-t cr-mono">{{ formatTokensShort(m.allTokens) }} tok</span>
            </div>
            <div v-if="sortedModels.length > 5 && !modelsExpanded" class="cr-mod-more">
              <a @click="modelsExpanded = true">展开全部 →</a>
            </div>
            <div v-else-if="modelsExpanded && sortedModels.length > 5" class="cr-mod-more">
              <a @click="modelsExpanded = false">收起 ↑</a>
            </div>
          </div>

          <!-- Per-key breakdown (multi-key only) -->
          <template v-if="multiKeyMode && individualStats && individualStats.length">
            <div class="cr-sec-head">
              <h3 class="cr-serif">分 Key 明细</h3>
              <span class="cr-sec-meta">共 {{ individualStats.length }} 个 Key</span>
            </div>
            <div class="cr-card">
              <div v-for="(row, i) in perKeyRows" :key="row.id" class="cr-row cr-key-row">
                <span class="cr-rank cr-serif">{{ String(i + 1).padStart(2, '0') }}</span>
                <span class="cr-key-name">{{ row.name }}</span>
                <span class="cr-val cr-mono">{{ formatCurrency(row.cost) }}</span>
                <span class="cr-t cr-mono">{{ formatTokensShort(row.tokens) }} tok</span>
              </div>
            </div>
          </template>
        </template>

        <div class="cr-footer">
          <span><span class="cr-status-dot"></span>{{ error ? '检测到问题' : '系统正常' }}</span>
          <span v-if="statsData?.updatedAt" class="cr-mono">{{ lastSyncText }}同步</span>
          <span v-if="appVersion" class="cr-mono">{{ appVersion }}</span>
        </div>
      </section>
    </div>

    <!-- Notification modal (OEM apiStatsNotice) -->
    <Teleport to="body">
      <Transition name="fade">
        <div v-if="showNotice" class="cr-modal-overlay" @click.self="dismissNotice">
          <div class="cr-card cr-modal" @click.stop>
            <div class="cr-modal-head">
              <div class="cr-modal-icon">
                <i class="fas fa-bell"></i>
              </div>
              <h3 class="cr-serif">{{ oemSettings.apiStatsNotice?.title || '通知' }}</h3>
            </div>
            <p class="cr-modal-body">{{ oemSettings.apiStatsNotice?.content }}</p>
            <label class="cr-modal-check">
              <input v-model="dontShowAgain" type="checkbox" />
              <span>本次会话不再显示</span>
            </label>
            <button class="cr-btn-primary" @click="dismissNotice">知道了</button>
          </div>
        </div>
      </Transition>
    </Teleport>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, watch } from 'vue'
import { storeToRefs } from 'pinia'
import { useApiStatsStore } from '@/stores/apistats'
import { useThemeStore } from '@/stores/theme'
import ApiKeyInputClaude from '@/components/apistats/ApiKeyInputClaude.vue'
import ThemeToggleClaude from '@/components/common/ThemeToggleClaude.vue'
import TutorialView from './TutorialView.vue'

const apiStatsStore = useApiStatsStore()
const themeStore = useThemeStore()

/* eslint-disable no-unused-vars */
const {
  apiId,
  apiKey,
  loading,
  error,
  statsPeriod,
  statsData,
  oemSettings,
  multiKeyMode,
  apiIds,
  modelStats,
  individualStats
} = storeToRefs(apiStatsStore)
/* eslint-enable no-unused-vars */

const { loadOemSettings, loadApiKeyFromStorage, loadServiceRates, switchPeriod, reset } =
  apiStatsStore

const periodLabel = computed(() => {
  const map = { daily: '今日', yesterday: '昨日', monthly: '本月', alltime: '全部' }
  return map[statsPeriod.value] || '今日'
})

const currentPeriodData = computed(() => apiStatsStore.currentPeriodData)

const costDelta = computed(() => {
  // 若后端提供 previous period cost 则计算；否则 null 不渲染 delta
  const cur = currentPeriodData.value?.cost || 0
  const prev = currentPeriodData.value?.previousCost
  if (prev == null || prev === 0) return null
  return ((cur - prev) / prev) * 100
})

const successRate = computed(() => {
  const total = currentPeriodData.value?.requests || 0
  const failed = currentPeriodData.value?.failedRequests
  if (!total || failed == null) return null
  return ((total - failed) / total) * 100
})

const avgLatencyMs = computed(() => {
  const ms = currentPeriodData.value?.avgLatencyMs
  return typeof ms === 'number' && isFinite(ms) ? ms : null
})

function formatCurrencyHero(cost) {
  if (cost == null) return '$0.00'
  return '$' + (Number(cost) || 0).toFixed(2)
}

function formatTokensShort(n) {
  n = Number(n) || 0
  if (n >= 1e9) return (n / 1e9).toFixed(2).replace(/\.?0+$/, '') + 'B'
  if (n >= 1e6) return (n / 1e6).toFixed(2).replace(/\.?0+$/, '') + 'M'
  if (n >= 1e3) return (n / 1e3).toFixed(1).replace(/\.?0+$/, '') + 'K'
  return String(n)
}

const isDarkMode = computed(() => themeStore.isDarkMode)

const currentTab = ref('stats')

const expiresInText = computed(() => {
  const exp = statsData.value?.expiresAt
  if (!exp) return ''
  const days = Math.max(0, Math.round((new Date(exp) - Date.now()) / 86400000))
  if (days === 0) return '今日'
  if (days === 1) return '1 天后'
  if (days < 30) return `${days} 天后`
  if (days < 365) return `${Math.round(days / 30)} 个月后`
  return `${Math.round(days / 365)} 年后`
})

function handleSignOut() {
  reset()
  currentTab.value = 'stats'
}

const quotaRows = computed(() => {
  const rows = []
  const limits = statsData.value?.limits || {}

  // 总费用限制
  if (limits.totalCostLimit != null && limits.totalCostLimit > 0) {
    const used = limits.currentTotalCost || 0
    const pct = Math.min(100, Math.round((used / limits.totalCostLimit) * 100))
    rows.push({
      key: 'totalCost',
      label: '总花费',
      percent: pct,
      valueText: `$${used.toFixed(2)} / $${Number(limits.totalCostLimit).toFixed(2)}`,
      stateClass: pct >= 90 ? 'danger' : pct >= 60 ? 'warn' : 'ok'
    })
  }

  // 每日费用限制
  if (limits.dailyCostLimit != null && limits.dailyCostLimit > 0) {
    const used = limits.currentDailyCost || 0
    const pct = Math.min(100, Math.round((used / limits.dailyCostLimit) * 100))
    rows.push({
      key: 'daily',
      label: '今日花费',
      percent: pct,
      valueText: `$${used.toFixed(2)} / $${Number(limits.dailyCostLimit).toFixed(2)}`,
      stateClass: pct >= 90 ? 'danger' : pct >= 60 ? 'warn' : 'ok'
    })
  }

  // 时间窗口 Token 限制
  if (limits.tokenLimit != null && limits.tokenLimit > 0) {
    const used = limits.currentWindowTokens || 0
    const pct = Math.min(100, Math.round((used / limits.tokenLimit) * 100))
    rows.push({
      key: 'token',
      label: 'Token',
      percent: pct,
      valueText: `${used.toLocaleString()} / ${Number(limits.tokenLimit).toLocaleString()}`,
      stateClass: pct >= 90 ? 'danger' : pct >= 60 ? 'warn' : 'ok'
    })
  }

  // 时间窗口请求数限制
  if (limits.rateLimitRequests != null && limits.rateLimitRequests > 0) {
    const used = limits.currentWindowRequests || 0
    const pct = Math.min(100, Math.round((used / limits.rateLimitRequests) * 100))
    rows.push({
      key: 'requests',
      label: '请求/分',
      percent: pct,
      valueText: `${used} / ${limits.rateLimitRequests}`,
      stateClass: pct >= 90 ? 'danger' : pct >= 60 ? 'warn' : 'ok'
    })
  }

  return rows
})

const KNOWN_SERVICES = [
  { key: 'claude', label: 'Claude' },
  { key: 'codex', label: 'Codex' },
  { key: 'gemini', label: 'Gemini' },
  { key: 'droid', label: 'Droid' },
  { key: 'bedrock', label: 'Bedrock' },
  { key: 'azure', label: 'Azure OpenAI' },
  { key: 'ccr', label: 'CCR' }
]

function getServiceFromModel(model) {
  if (!model) return 'claude'
  const m = model.toLowerCase()
  if (m.includes('claude') || m.includes('sonnet') || m.includes('opus') || m.includes('haiku'))
    return 'claude'
  if (m.includes('gpt') || m.includes('o1') || m.includes('o3') || m.includes('o4')) return 'codex'
  if (m.includes('gemini')) return 'gemini'
  if (m.includes('droid') || m.includes('factory')) return 'droid'
  if (m.includes('bedrock') || m.includes('amazon')) return 'bedrock'
  if (m.includes('azure')) return 'azure'
  return 'claude'
}

const serviceRows = computed(() => {
  const stats = {}
  KNOWN_SERVICES.forEach(({ key }) => {
    stats[key] = 0
  })

  const models = modelStats.value || []
  models.forEach((model) => {
    const svc = getServiceFromModel(model.model)
    if (stats[svc] !== undefined) {
      stats[svc] += model.costs?.real ?? model.costs?.total ?? 0
    }
  })

  const totalCost = Object.values(stats).reduce((a, b) => a + b, 0) || 1

  return KNOWN_SERVICES.map(({ key, label }) => {
    const cost = stats[key] || 0
    return {
      name: key,
      label,
      cost,
      percent: Math.round((cost / totalCost) * 100)
    }
  }).sort((a, b) => b.cost - a.cost)
})

const activeServicesCount = computed(() => serviceRows.value.filter((r) => r.cost > 0).length)

const modelsExpanded = ref(false)

const sortedModels = computed(() => {
  const raw = apiStatsStore.modelStats || []
  return [...raw]
    .map((m) => ({
      model: m.model || m.name || 'unknown',
      cost: Number(m.costs?.real ?? m.costs?.total ?? m.cost ?? m.totalCost ?? 0),
      allTokens: Number(m.allTokens ?? m.tokens ?? m.totalTokens ?? 0)
    }))
    .sort((a, b) => b.cost - a.cost)
})

const displayedModels = computed(() =>
  modelsExpanded.value ? sortedModels.value : sortedModels.value.slice(0, 5)
)

function formatCurrency(v) {
  const n = Number(v) || 0
  return '$' + n.toFixed(2)
}

const perKeyRows = computed(() => {
  if (!multiKeyMode.value || !individualStats.value) return []
  return individualStats.value
    .map((k) => {
      let usagePeriod
      if (statsPeriod.value === 'daily') {
        usagePeriod = k?.dailyUsage
      } else if (statsPeriod.value === 'monthly') {
        usagePeriod = k?.monthlyUsage
      } else {
        usagePeriod = k?.alltimeUsage
      }
      const cost = Number(usagePeriod?.cost ?? 0)
      const tokens = Number(usagePeriod?.allTokens ?? 0)
      return {
        id: k.apiId || k.id || k.name,
        name: k.name || k.apiId || 'unnamed',
        cost,
        tokens
      }
    })
    .sort((a, b) => b.cost - a.cost)
})

// 版本号（若 Vite 未注入 __APP_VERSION__ 宏，显示为空）
const appVersion = typeof __APP_VERSION__ !== 'undefined' ? __APP_VERSION__ : ''

const lastSyncText = computed(() => {
  const t = statsData.value?.updatedAt
  if (!t) return ''
  const sec = Math.round((Date.now() - new Date(t).getTime()) / 1000)
  if (sec < 60) return `${sec} 秒前`
  if (sec < 3600) return `${Math.round(sec / 60)} 分钟前`
  return `${Math.round(sec / 3600)} 小时前`
})

// Notice modal
const showNotice = ref(false)
const dontShowAgain = ref(false)
const NOTICE_STORAGE_KEY = 'apiStatsNoticeRead'

function dismissNotice() {
  showNotice.value = false
  if (dontShowAgain.value) {
    try {
      sessionStorage.setItem(NOTICE_STORAGE_KEY, '1')
    } catch (e) {
      /* ignore */
    }
  }
}

// 监听 OEM 加载 + apiId 就绪后决定是否展示通知
watch(
  () => [oemSettings.value?.apiStatsNotice?.enabled, apiId.value],
  ([enabled, id]) => {
    if (!enabled || !id) return
    try {
      if (sessionStorage.getItem(NOTICE_STORAGE_KEY) !== '1') {
        showNotice.value = true
      }
    } catch (e) {
      showNotice.value = true
    }
  }
)

onMounted(() => {
  loadOemSettings()
  loadApiKeyFromStorage()
  loadServiceRates()
})
</script>

<style scoped>
.cr-page {
  padding: 18px;
  position: relative;
}
@media (min-width: 1024px) {
  .cr-page {
    padding: 24px 40px;
  }
}
@media (min-width: 1440px) {
  .cr-page {
    padding: 28px 64px;
  }
}
@media (min-width: 1920px) {
  .cr-page {
    padding: 32px 96px;
  }
}

.cr-nav {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
  gap: 12px;
  flex-wrap: wrap;
}
.cr-brand {
  display: flex;
  align-items: center;
  gap: 10px;
  font-weight: 500;
  font-size: 16px;
  color: var(--cr-text);
}
.cr-logo-img,
.cr-logo-fallback {
  width: 28px;
  height: 28px;
  border-radius: 8px;
}
.cr-logo-fallback {
  background: var(--cr-coral);
  color: #fff;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 14px;
  font-weight: 600;
}
.cr-brand-text {
  line-height: 1;
}
.cr-sep {
  color: var(--cr-text-ter);
  font-weight: 400;
  margin: 0 4px;
}
.cr-brand-sub {
  color: var(--cr-text-sec);
  font-weight: 400;
}
.cr-nav-links {
  display: flex;
  gap: 4px;
  align-items: center;
}
.cr-nav-a {
  font-size: 13px;
  padding: 8px 14px;
  border-radius: 8px;
  color: var(--cr-text-sec);
  font-weight: 500;
  cursor: pointer;
  transition: all 0.15s;
  text-decoration: none;
}
.cr-nav-a:hover {
  color: var(--cr-text);
  background: var(--cr-surface-soft);
}
.cr-nav-a-primary {
  background: var(--cr-text);
  color: var(--cr-bg);
}
.cr-nav-a-primary:hover {
  background: var(--cr-text);
  color: var(--cr-bg);
  opacity: 0.9;
}
.cr-page-title {
  margin-bottom: 14px;
}
.cr-page-title h1 {
  font-weight: 500;
  font-size: 28px;
  letter-spacing: -0.02em;
  color: var(--cr-text);
  line-height: 1.1;
}
.cr-page-title p {
  font-size: 13px;
  color: var(--cr-text-sec);
  margin-top: 4px;
}

.cr-auth {
  max-width: 480px;
  margin: 48px auto;
}
.cr-auth-card {
  padding: 32px;
  text-align: center;
}
.cr-auth-title {
  font-size: 28px;
  font-weight: 500;
  letter-spacing: -0.02em;
  margin-bottom: 6px;
}
.cr-auth-sub {
  font-size: 13px;
  color: var(--cr-text-sec);
  margin-bottom: 20px;
}

.cr-tut-card {
  padding: 24px;
}
.cr-back {
  display: inline-block;
  font-size: 13px;
  color: var(--cr-coral);
  cursor: pointer;
  margin-bottom: 8px;
  font-weight: 500;
}
.cr-back:hover {
  color: var(--cr-coral-hover);
}

.cr-toolbar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 14px;
  flex-wrap: wrap;
  background: var(--cr-surface);
  border: 1px solid var(--cr-border);
  border-radius: 12px;
  padding: 8px 14px 8px 8px;
  margin-bottom: 14px;
}
.cr-identity {
  display: flex;
  align-items: center;
  gap: 12px;
}
.cr-avatar {
  width: 36px;
  height: 36px;
  border-radius: 10px;
  background: var(--cr-coral-soft);
  color: var(--cr-coral);
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 600;
  font-size: 14px;
}
.cr-id-name {
  font-weight: 500;
  font-size: 14px;
  color: var(--cr-text);
  letter-spacing: -0.01em;
}
.cr-id-meta {
  display: flex;
  align-items: center;
  gap: 8px;
  color: var(--cr-text-sec);
  font-size: 12px;
  margin-top: 1px;
  flex-wrap: wrap;
}
.cr-status-dot {
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background: var(--cr-ok);
  box-shadow: 0 0 0 3px rgba(101, 134, 110, 0.15);
  display: inline-block;
}
.cr-badge {
  padding: 1px 8px;
  border-radius: 999px;
  background: var(--cr-coral-soft);
  color: var(--cr-coral);
  font-weight: 500;
  font-size: 11px;
}
.cr-toolbar-right {
  display: flex;
  gap: 10px;
  align-items: center;
  flex-wrap: wrap;
}
.cr-btn-ghost {
  font-size: 13px;
  padding: 8px 14px;
  border: 1px solid var(--cr-border);
  background: var(--cr-surface);
  border-radius: 8px;
  color: var(--cr-text-sec);
  cursor: pointer;
  font-weight: 500;
  font-family: inherit;
  transition: all 0.15s;
}
.cr-btn-ghost:hover {
  border-color: var(--cr-border-strong);
  color: var(--cr-text);
  background: var(--cr-surface-soft);
}
.cr-period {
  display: inline-flex;
  background: var(--cr-surface);
  border: 1px solid var(--cr-border);
  border-radius: 999px;
  padding: 3px;
}
.cr-period > button {
  font-size: 13px;
  font-weight: 500;
  padding: 7px 16px;
  border: 0;
  background: transparent;
  border-radius: 999px;
  cursor: pointer;
  color: var(--cr-text-sec);
  font-family: inherit;
  transition: all 0.15s;
}
.cr-period > button.active {
  background: var(--cr-text);
  color: var(--cr-bg);
}
.cr-period > button:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}
.cr-period > button:hover:not(.active):not(:disabled) {
  color: var(--cr-text);
}

.cr-hero-row {
  display: grid;
  grid-template-columns: 2fr 1fr 1fr 1fr;
  gap: 12px;
  margin-bottom: 14px;
}
@media (max-width: 1200px) {
  .cr-hero-row {
    grid-template-columns: 2fr 1fr 1fr;
  }
  .cr-hero-row .cr-kpi-lat {
    display: none;
  }
}
@media (max-width: 800px) {
  .cr-hero-row {
    grid-template-columns: 1fr 1fr;
  }
  .cr-hero-row .cr-hero {
    grid-column: 1 / -1;
  }
  .cr-hero-row .cr-kpi-lat {
    display: block;
  }
}
.cr-hero {
  background: var(--cr-surface);
  border: 1px solid var(--cr-border);
  border-radius: 16px;
  padding: 18px 22px;
  position: relative;
  overflow: hidden;
}
.cr-hero::before {
  content: '';
  position: absolute;
  top: -80px;
  right: -80px;
  width: 240px;
  height: 240px;
  background: radial-gradient(circle, var(--cr-coral-soft) 0%, transparent 70%);
  pointer-events: none;
}
.cr-hero-label {
  font-size: 13px;
  color: var(--cr-text-sec);
  font-weight: 500;
  position: relative;
}
.cr-hero-n {
  font-size: 44px;
  line-height: 1.05;
  letter-spacing: -0.03em;
  color: var(--cr-text);
  margin-top: 6px;
  position: relative;
  font-weight: 500;
}
.cr-delta-row {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-top: 12px;
  position: relative;
  flex-wrap: wrap;
}
.cr-delta {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  padding: 3px 10px;
  border-radius: 999px;
  font-size: 12px;
  font-weight: 500;
  background: var(--cr-ok-soft);
  color: var(--cr-ok);
}
.cr-delta.neg {
  background: var(--cr-danger-soft);
  color: var(--cr-danger);
}
.cr-sub-note {
  font-size: 13px;
  color: var(--cr-text-sec);
}
.cr-kpi {
  background: var(--cr-surface);
  border: 1px solid var(--cr-border);
  border-radius: 16px;
  padding: 18px 22px;
}
.cr-kpi-label {
  font-size: 13px;
  color: var(--cr-text-sec);
  font-weight: 500;
}
.cr-kpi-n {
  font-size: 30px;
  line-height: 1.1;
  letter-spacing: -0.02em;
  margin-top: 6px;
  color: var(--cr-text);
  font-weight: 500;
}
.cr-kpi-n .cr-unit {
  color: var(--cr-text-ter);
  font-size: 18px;
  font-weight: 400;
  font-family: var(--cr-sans);
}
.cr-kpi-d {
  font-size: 12px;
  color: var(--cr-text-ter);
  margin-top: 8px;
  display: flex;
  gap: 6px;
  flex-wrap: wrap;
}
.cr-pill {
  background: var(--cr-surface-soft);
  padding: 2px 8px;
  border-radius: 6px;
  color: var(--cr-text-sec);
}

.cr-sec-head {
  display: flex;
  justify-content: space-between;
  align-items: baseline;
  margin: 20px 0 8px 0;
  gap: 12px;
  flex-wrap: wrap;
}
.cr-sec-head h3 {
  font-size: 17px;
  color: var(--cr-text);
  letter-spacing: -0.01em;
  font-weight: 500;
}
.cr-sec-head .cr-sec-meta {
  font-size: 13px;
  color: var(--cr-text-ter);
}
.cr-dual {
  display: grid;
  grid-template-columns: 1fr;
  gap: 16px;
  align-items: start;
}
@media (min-width: 1280px) {
  .cr-dual {
    grid-template-columns: 1fr 1fr;
  }
}
.cr-row {
  display: grid;
  align-items: center;
  padding: 10px 18px;
  border-bottom: 1px solid var(--cr-border);
  gap: 16px;
}
.cr-row:last-child {
  border-bottom: 0;
}
.cr-lim-row {
  grid-template-columns: 90px 1fr 130px 80px;
}
.cr-lim-row .cr-k {
  font-size: 14px;
  color: var(--cr-text);
  font-weight: 500;
}
.cr-bar {
  height: 6px;
  background: var(--cr-surface-soft);
  border-radius: 3px;
  overflow: hidden;
}
.cr-bar > div {
  height: 100%;
  border-radius: 3px;
}
.cr-bar > div.ok {
  background: var(--cr-ok);
}
.cr-bar > div.warn {
  background: var(--cr-warn);
}
.cr-bar > div.danger {
  background: var(--cr-danger);
}
.cr-lim-row .cr-v {
  font-size: 13px;
  text-align: right;
  color: var(--cr-text-sec);
}
.cr-state {
  font-size: 12px;
  font-weight: 500;
  padding: 3px 10px;
  border-radius: 999px;
  text-align: center;
}
.cr-state.ok {
  background: var(--cr-ok-soft);
  color: var(--cr-ok);
}
.cr-state.warn {
  background: var(--cr-warn-soft);
  color: var(--cr-warn);
}
.cr-state.danger {
  background: var(--cr-danger-soft);
  color: var(--cr-danger);
}
@media (max-width: 600px) {
  .cr-lim-row {
    grid-template-columns: 1fr 80px;
    row-gap: 6px;
  }
  .cr-lim-row .cr-bar {
    display: none;
  }
  .cr-lim-row .cr-v {
    text-align: right;
  }
  .cr-lim-row .cr-state {
    grid-column: 2;
  }
}
.cr-svc-row {
  grid-template-columns: 110px 100px 1fr 50px;
}
.cr-svc-row .cr-name {
  font-size: 14px;
  color: var(--cr-text);
  font-weight: 500;
}
.cr-svc-row .cr-val {
  font-size: 14px;
  text-align: right;
  color: var(--cr-text);
}
.cr-svc-row.empty .cr-val,
.cr-svc-row.empty .cr-name {
  color: var(--cr-text-ter);
}
.cr-svc-row .cr-bar > div {
  background: var(--cr-coral);
}
.cr-svc-row .cr-pct {
  font-size: 13px;
  color: var(--cr-text-ter);
  text-align: right;
}
@media (max-width: 600px) {
  .cr-svc-row {
    grid-template-columns: 1fr 60px;
  }
  .cr-svc-row .cr-bar,
  .cr-svc-row .cr-pct {
    display: none;
  }
}
.cr-empty {
  padding: 14px 18px;
  color: var(--cr-text-ter);
  font-size: 13px;
}

.cr-rings {
  display: grid;
  gap: 24px 20px;
  padding: 28px 22px;
  align-content: center;
  justify-items: center;
  min-height: 340px;
  grid-template-columns: 1fr;
}
.cr-rings.n-2 {
  grid-template-columns: 1fr 1fr;
}
.cr-rings.n-3,
.cr-rings.n-4 {
  grid-template-columns: 1fr 1fr;
}
@media (max-width: 600px) {
  .cr-rings,
  .cr-rings.n-2,
  .cr-rings.n-3,
  .cr-rings.n-4 {
    grid-template-columns: 1fr;
    min-height: 0;
    padding: 18px;
  }
}
.cr-ring {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 10px;
  width: 100%;
}
.cr-ring-circle {
  --pct: 0%;
  --ring-color: var(--cr-ok);
  width: 180px;
  height: 180px;
  border-radius: 50%;
  background: conic-gradient(var(--ring-color) var(--pct), var(--cr-surface-soft) var(--pct));
  display: grid;
  place-items: center;
  transition: background 0.4s ease;
}
.cr-rings.n-2 .cr-ring-circle,
.cr-rings.n-3 .cr-ring-circle,
.cr-rings.n-4 .cr-ring-circle {
  width: 140px;
  height: 140px;
}
.cr-ring.warn .cr-ring-circle {
  --ring-color: var(--cr-warn);
}
.cr-ring.danger .cr-ring-circle {
  --ring-color: var(--cr-danger);
}
.cr-ring-core {
  width: calc(100% - 24px);
  height: calc(100% - 24px);
  border-radius: 50%;
  background: var(--cr-surface);
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
}
.cr-ring-pct {
  font-size: 30px;
  font-weight: 500;
  color: var(--cr-text);
  letter-spacing: -0.02em;
  line-height: 1;
}
.cr-rings.n-2 .cr-ring-pct,
.cr-rings.n-3 .cr-ring-pct,
.cr-rings.n-4 .cr-ring-pct {
  font-size: 24px;
}
.cr-ring-pct-unit {
  font-size: 0.55em;
  color: var(--cr-text-sec);
  margin-left: 2px;
  font-weight: 400;
}
.cr-ring-lbl {
  font-size: 12px;
  color: var(--cr-text-sec);
  margin-top: 4px;
  letter-spacing: 0.02em;
}
.cr-ring-meta {
  font-size: 12px;
  color: var(--cr-text-ter);
  text-align: center;
  word-break: break-all;
}
.cr-mod-row {
  grid-template-columns: 32px 1fr 110px 100px;
  gap: 14px;
}
.cr-mod-row .cr-rank {
  font-size: 14px;
  color: var(--cr-text-ter);
  text-align: center;
}
.cr-mod-row .cr-m {
  font-size: 14px;
  color: var(--cr-text);
  font-weight: 500;
  word-break: break-all;
}
.cr-mod-row .cr-val {
  font-size: 14px;
  text-align: right;
  color: var(--cr-text);
}
.cr-mod-row .cr-t {
  font-size: 13px;
  color: var(--cr-text-ter);
  text-align: right;
}
@media (max-width: 600px) {
  .cr-mod-row {
    grid-template-columns: 32px 1fr 80px;
  }
  .cr-mod-row .cr-t {
    display: none;
  }
}
.cr-mod-more {
  padding: 10px 18px;
  display: flex;
  justify-content: center;
  border-top: 1px solid var(--cr-border);
}
.cr-mod-more a {
  font-size: 13px;
  color: var(--cr-coral);
  font-weight: 500;
  cursor: pointer;
}
.cr-mod-more a:hover {
  color: var(--cr-coral-hover);
  text-decoration: underline;
}
.cr-key-row {
  grid-template-columns: 32px 1fr 110px 120px;
  gap: 14px;
}
.cr-key-row .cr-key-name {
  font-size: 14px;
  color: var(--cr-text);
  font-weight: 500;
  word-break: break-all;
}
@media (max-width: 600px) {
  .cr-key-row {
    grid-template-columns: 32px 1fr 80px;
  }
  .cr-key-row .cr-t {
    display: none;
  }
}

.cr-alert {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 12px 16px;
  background: var(--cr-danger-soft);
  border: 1px solid var(--cr-danger);
  border-radius: 10px;
  color: var(--cr-danger);
  font-size: 14px;
  margin-bottom: 20px;
}
.cr-alert-icon {
  font-size: 14px;
}

.cr-loading {
  padding: 24px;
}
.cr-skel {
  background: linear-gradient(
    90deg,
    var(--cr-surface-soft) 25%,
    var(--cr-border) 50%,
    var(--cr-surface-soft) 75%
  );
  background-size: 200% 100%;
  animation: crshimmer 1.4s infinite;
  border-radius: 8px;
}
.cr-skel-hero {
  height: 80px;
  margin-bottom: 12px;
}
.cr-skel-row {
  height: 32px;
  margin-bottom: 8px;
}
@keyframes crshimmer {
  0% {
    background-position: 200% 0;
  }
  100% {
    background-position: -200% 0;
  }
}

.cr-footer {
  margin-top: 22px;
  padding-top: 14px;
  border-top: 1px solid var(--cr-border);
  font-size: 12px;
  color: var(--cr-text-ter);
  display: flex;
  justify-content: space-between;
  flex-wrap: wrap;
  gap: 10px;
}

.cr-modal-overlay {
  position: fixed;
  inset: 0;
  background: rgba(43, 36, 32, 0.5);
  backdrop-filter: blur(4px);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 50;
  padding: 16px;
}
.cr-modal {
  max-width: 440px;
  width: 100%;
  padding: 24px;
}
.cr-modal-head {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 14px;
}
.cr-modal-icon {
  width: 40px;
  height: 40px;
  border-radius: 10px;
  background: var(--cr-coral-soft);
  color: var(--cr-coral);
  display: flex;
  align-items: center;
  justify-content: center;
}
.cr-modal-head h3 {
  font-size: 18px;
  font-weight: 500;
  color: var(--cr-text);
}
.cr-modal-body {
  font-size: 14px;
  color: var(--cr-text-sec);
  white-space: pre-wrap;
  margin-bottom: 14px;
}
.cr-modal-check {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 13px;
  color: var(--cr-text-sec);
  margin-bottom: 16px;
  cursor: pointer;
}
.cr-btn-primary {
  width: 100%;
  padding: 10px 16px;
  background: var(--cr-coral);
  color: #fff;
  border: 0;
  border-radius: 8px;
  font-weight: 500;
  font-size: 14px;
  cursor: pointer;
  font-family: inherit;
}
.cr-btn-primary:hover {
  background: var(--cr-coral-hover);
}

.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.2s ease;
}
.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}
</style>
