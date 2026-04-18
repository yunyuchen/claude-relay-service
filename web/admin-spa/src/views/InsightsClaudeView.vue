<template>
  <div class="cr-theme min-h-screen" :class="{ dark: isDarkMode }">
    <div class="cr-page">
      <!-- Top nav -->
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
            <span class="cr-brand-sub">排行榜</span>
          </span>
        </div>
        <div class="cr-nav-links">
          <router-link class="cr-nav-a" to="/api-stats">使用统计</router-link>
          <ThemeToggleClaude />
          <router-link
            v-if="oemSettings.showAdminButton !== false"
            class="cr-nav-a cr-nav-a-primary"
            to="/dashboard"
            >管理后台</router-link
          >
        </div>
      </nav>

      <!-- Page title -->
      <div class="cr-page-title">
        <h1 class="cr-serif">排行榜 &amp; 洞察</h1>
        <p>全部成员的用量排行、效率分布和聚合花费</p>
      </div>

      <!-- Fun stats row (4 cards) -->
      <div class="cr-fun-row">
        <div class="cr-card cr-fun-card">
          <div class="cr-fun-label">{{ rangeLabel }} 卷王</div>
          <div class="cr-fun-name">{{ funStats.topUser?.name || '—' }}</div>
          <div class="cr-fun-meta cr-mono">${{ (funStats.topUser?.cost || 0).toFixed(2) }}</div>
        </div>
        <div class="cr-card cr-fun-card">
          <div class="cr-fun-label">效率之星</div>
          <div class="cr-fun-name">{{ funStats.cacheKing?.name || '—' }}</div>
          <div class="cr-fun-meta">缓存率 {{ funStats.cacheKing?.rate || 0 }}%</div>
        </div>
        <div class="cr-card cr-fun-card">
          <div class="cr-fun-label">Token 大户</div>
          <div class="cr-fun-name">{{ funStats.tokenKing?.name || '—' }}</div>
          <div class="cr-fun-meta cr-mono">{{ formatTokens(funStats.tokenKing?.tokens) }}</div>
        </div>
        <div class="cr-card cr-fun-card">
          <div class="cr-fun-label">{{ rangeLabel }} 总花费</div>
          <div class="cr-fun-name cr-serif cr-fun-big">
            ${{ (funStats.todayCost || 0).toFixed(2) }}
          </div>
          <div class="cr-fun-meta">{{ (funStats.todayRequests || 0).toLocaleString() }} 请求</div>
        </div>
      </div>

      <!-- Rank list -->
      <div class="cr-sec-head">
        <h3 class="cr-serif">用户排行</h3>
        <div class="cr-period">
          <button :class="{ active: selectedRange === 'today' }" @click="switchRange('today')">
            今日
          </button>
          <button :class="{ active: selectedRange === '7days' }" @click="switchRange('7days')">
            7 天
          </button>
          <button :class="{ active: selectedRange === '30days' }" @click="switchRange('30days')">
            30 天
          </button>
          <button :class="{ active: selectedRange === 'all' }" @click="switchRange('all')">
            累计
          </button>
        </div>
      </div>

      <div v-if="loadingRank" class="cr-card cr-loading">
        <div class="cr-skel cr-skel-row"></div>
        <div class="cr-skel cr-skel-row"></div>
        <div class="cr-skel cr-skel-row"></div>
      </div>
      <div v-else-if="rankList.length" class="cr-card">
        <div v-for="(row, i) in rankRows" :key="row.id || row.name || i" class="cr-row cr-rank-row">
          <span class="cr-rank-badge">
            <span v-if="i === 0">🥇</span>
            <span v-else-if="i === 1">🥈</span>
            <span v-else-if="i === 2">🥉</span>
            <span v-else class="cr-mono">{{ String(i + 1).padStart(2, '0') }}</span>
          </span>
          <span class="cr-rank-name">{{ row.name }}</span>
          <div class="cr-bar"><div :style="{ width: row.percent + '%' }"></div></div>
          <span class="cr-val cr-mono">${{ row.cost.toFixed(2) }}</span>
          <span class="cr-t cr-mono">{{ formatTokens(row.tokens) }}</span>
        </div>
      </div>
      <div v-else class="cr-card cr-empty">当前时段暂无数据</div>

      <!-- 二级网格：模型热度 + 活跃度 -->
      <div class="cr-insights-dual">
        <div>
          <div class="cr-sec-head">
            <h3 class="cr-serif">今日模型热度</h3>
          </div>
          <div v-if="loadingModels" class="cr-card cr-loading">
            <div class="cr-skel cr-skel-row"></div>
            <div class="cr-skel cr-skel-row"></div>
          </div>
          <div v-else-if="modelRank.length === 0" class="cr-card cr-empty">暂无数据</div>
          <div v-else class="cr-card" style="padding: 12px 18px">
            <div v-for="(m, i) in modelRank.slice(0, 8)" :key="m.model" class="cr-mod-heat-row">
              <div class="cr-mod-heat-top">
                <span class="cr-mod-heat-rank cr-mono">{{ String(i + 1).padStart(2, '0') }}</span>
                <span class="cr-mod-heat-name">{{ m.model }}</span>
                <span class="cr-mod-heat-val cr-mono">{{ m.requests.toLocaleString() }} 次</span>
              </div>
              <div class="cr-bar">
                <div :style="{ width: getModelBarWidth(m.requests) + '%' }"></div>
              </div>
            </div>
          </div>
        </div>

        <div>
          <div class="cr-sec-head">
            <h3 class="cr-serif">近 30 天活跃度</h3>
          </div>
          <div v-if="loadingHeatmap" class="cr-card cr-loading">
            <div class="cr-skel cr-skel-row"></div>
          </div>
          <div v-else class="cr-card" style="padding: 14px 18px">
            <div class="cr-heatmap">
              <div
                v-for="day in heatmapData"
                :key="day.date"
                class="cr-heatmap-cell"
                :data-level="getHeatmapLevel(day.requests)"
                :title="`${day.date}: ${day.requests} 请求`"
              ></div>
            </div>
            <div class="cr-heatmap-legend">
              <span>少</span>
              <span class="cr-heatmap-cell" data-level="0"></span>
              <span class="cr-heatmap-cell" data-level="1"></span>
              <span class="cr-heatmap-cell" data-level="2"></span>
              <span class="cr-heatmap-cell" data-level="3"></span>
              <span class="cr-heatmap-cell" data-level="4"></span>
              <span>多</span>
            </div>
          </div>
        </div>
      </div>

      <!-- 三级网格：费用趋势 + 时段分布 + 缓存节省 -->
      <div class="cr-insights-trio">
        <div>
          <div class="cr-sec-head">
            <h3 class="cr-serif">费用趋势 · 近 14 天</h3>
            <span v-if="overview.costProjection" class="cr-sec-meta">
              本月预估
              <span class="cr-mono" style="color: var(--cr-coral)"
                >${{ overview.costProjection.projected }}</span
              >
            </span>
          </div>
          <div v-if="loadingOverview" class="cr-card cr-loading">
            <div class="cr-skel cr-skel-row"></div>
            <div class="cr-skel cr-skel-row"></div>
          </div>
          <div v-else-if="overview.dailyCosts" class="cr-card" style="padding: 14px 18px">
            <div v-for="day in overview.dailyCosts" :key="day.date" class="cr-trend-row">
              <span class="cr-trend-date cr-mono">{{ day.date.slice(5) }}</span>
              <div class="cr-bar">
                <div :style="{ width: getDailyCostWidth(day.cost) + '%' }"></div>
              </div>
              <span class="cr-trend-val cr-mono">${{ day.cost.toFixed(1) }}</span>
            </div>
          </div>
        </div>

        <div>
          <div class="cr-sec-head"><h3 class="cr-serif">今日时段分布</h3></div>
          <div v-if="loadingOverview" class="cr-card cr-loading">
            <div class="cr-skel cr-skel-row"></div>
          </div>
          <div v-else-if="overview.hourlyStats" class="cr-card" style="padding: 14px 18px">
            <div class="cr-hourly">
              <div
                v-for="h in overview.hourlyStats"
                :key="h.hour"
                class="cr-hourly-bar"
                :style="{ height: Math.max(4, getHourBarHeight(h.requests)) + '%' }"
                :title="`${h.hour}:00 · ${h.requests} 请求`"
              ></div>
            </div>
            <div class="cr-hourly-axis">
              <span>0</span><span>6</span><span>12</span><span>18</span><span>23</span>
            </div>
          </div>
        </div>

        <div>
          <div class="cr-sec-head"><h3 class="cr-serif">本月缓存节省</h3></div>
          <div v-if="loadingOverview" class="cr-card cr-loading">
            <div class="cr-skel cr-skel-row"></div>
          </div>
          <div v-else class="cr-card" style="padding: 22px; text-align: center">
            <div class="cr-cache-n cr-serif cr-mono">
              ${{ overview.cache?.saving?.toFixed(2) || '0.00' }}
            </div>
            <div class="cr-cache-meta">
              缓存命中率 <span class="cr-mono">{{ overview.cache?.rate || 0 }}%</span>
            </div>
            <div class="cr-cache-meta">
              <span class="cr-mono">{{ formatTokens(overview.cache?.totalCacheReadTokens) }}</span>
              Token 命中缓存
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { storeToRefs } from 'pinia'
import { useApiStatsStore } from '@/stores/apistats'
import { useThemeStore } from '@/stores/theme'
import ThemeToggleClaude from '@/components/common/ThemeToggleClaude.vue'
import request from '@/utils/request'
import { useClaudeBodyTheme } from '@/composables/useClaudeBodyTheme'
import '@/styles/claude-tokens.css'

useClaudeBodyTheme()

// ---- Store / theme ----
const apiStatsStore = useApiStatsStore()
const themeStore = useThemeStore()
const { oemSettings } = storeToRefs(apiStatsStore)
const isDarkMode = computed(() => themeStore.isDarkMode)

// ---- State (ported verbatim from InsightsLegacyView) ----
const loadingRank = ref(true)
const selectedRange = ref('today')

const rangeLabel = computed(() => {
  const map = { today: '今日', '7days': '7天', '30days': '30天', all: '累计' }
  return map[selectedRange.value] || '今日'
})

const rankList = ref([])
const funStats = ref({
  topUser: null,
  cacheKing: null,
  tokenKing: null,
  todayRequests: 0,
  todayCost: 0
})

// ---- Derived rows with percent bar ----
const rankRows = computed(() => {
  const maxCost = rankList.value[0]?.cost || 1
  return rankList.value.map((k) => ({
    id: k.id || k.apiKeyId,
    name: k.name,
    cost: k.cost || 0,
    tokens: k.allTokens || 0,
    percent: Math.max(2, ((k.cost || 0) / maxCost) * 100)
  }))
})

// ---- Data loading (ported verbatim from InsightsLegacyView) ----
async function loadRankData() {
  loadingRank.value = true
  try {
    const result = await request({
      url: `/apiStats/insights/ranking?timeRange=${selectedRange.value}&limit=10`,
      method: 'GET'
    })

    if (result.success) {
      rankList.value = result.data || []
      computeFunStats(rankList.value)
    }
  } catch (error) {
    console.error('Failed to load ranking:', error)
  } finally {
    loadingRank.value = false
  }
}

function computeFunStats(ranking) {
  if (ranking.length === 0) return

  // 今日卷王
  funStats.value.topUser = {
    name: ranking[0].name,
    cost: ranking[0].cost
  }

  // 效率之星 (缓存命中率最高)
  let bestRate = 0
  let cacheKing = null
  for (const k of ranking) {
    if (k.requests > 5) {
      const totalInput =
        (k.inputTokens || 0) + (k.cacheReadTokens || 0) + (k.cacheCreateTokens || 0)
      if (totalInput > 0) {
        const rate = ((k.cacheReadTokens || 0) / totalInput) * 100
        if (rate > bestRate) {
          bestRate = rate
          cacheKing = { name: k.name, rate: rate.toFixed(1) }
        }
      }
    }
  }
  funStats.value.cacheKing = cacheKing

  // Token 大户
  const tokenKing = ranking.reduce(
    (max, k) => ((k.allTokens || 0) > (max?.allTokens || 0) ? k : max),
    ranking[0]
  )
  funStats.value.tokenKing = { name: tokenKing.name, tokens: tokenKing.allTokens || 0 }

  // 汇总
  funStats.value.todayCost = ranking.reduce((sum, k) => sum + (k.cost || 0), 0)
  funStats.value.todayRequests = ranking.reduce((sum, k) => sum + (k.requests || 0), 0)
}

async function switchRange(range) {
  selectedRange.value = range
  await loadRankData()
}

// ---- Helpers ----
function formatTokens(tokens) {
  if (!tokens) return '0'
  if (tokens >= 1_000_000_000) return (tokens / 1_000_000_000).toFixed(1) + 'B'
  if (tokens >= 1_000_000) return (tokens / 1_000_000).toFixed(1) + 'M'
  if (tokens >= 1_000) return (tokens / 1_000).toFixed(1) + 'K'
  return tokens.toString()
}

// ---- Additional data ----
const loadingModels = ref(true)
const loadingHeatmap = ref(true)
const loadingOverview = ref(true)
const modelRank = ref([])
const heatmapData = ref([])
const overview = ref({})

async function loadModelStats() {
  loadingModels.value = true
  try {
    const result = await request({ url: '/apiStats/insights/models', method: 'GET' })
    if (result.success) modelRank.value = result.data || []
  } catch (error) {
    console.error('Failed to load model stats:', error)
  } finally {
    loadingModels.value = false
  }
}

async function loadHeatmapData() {
  loadingHeatmap.value = true
  try {
    const result = await request({ url: '/apiStats/insights/activity', method: 'GET' })
    if (result.success) heatmapData.value = result.data || []
  } catch (error) {
    console.error('Failed to load activity:', error)
  } finally {
    loadingHeatmap.value = false
  }
}

async function loadOverview() {
  loadingOverview.value = true
  try {
    const result = await request({ url: '/apiStats/insights/overview', method: 'GET' })
    if (result.success) overview.value = result.data || {}
  } catch (error) {
    console.error('Failed to load overview:', error)
  } finally {
    loadingOverview.value = false
  }
}

function getModelBarWidth(requests) {
  if (modelRank.value.length === 0) return 0
  const max = modelRank.value[0]?.requests || 1
  return (requests / max) * 100
}

function getDailyCostWidth(cost) {
  const costs = (overview.value.dailyCosts || []).map((d) => d.cost)
  const max = Math.max(...costs, 0) || 1
  return (cost / max) * 100
}

function getHourBarHeight(requests) {
  const hourly = overview.value.hourlyStats || []
  const max = Math.max(...hourly.map((h) => h.requests), 0) || 1
  return (requests / max) * 100
}

function getHeatmapLevel(requests) {
  if (!requests) return 0
  if (requests < 10) return 1
  if (requests < 50) return 2
  if (requests < 100) return 3
  return 4
}

// ---- Lifecycle ----
onMounted(() => {
  apiStatsStore.loadOemSettings()
  Promise.all([loadRankData(), loadModelStats(), loadHeatmapData(), loadOverview()])
})
</script>

<style scoped>
.cr-page {
  padding: 24px;
  position: relative;
}
@media (min-width: 1024px) {
  .cr-page {
    padding: 32px 48px;
  }
}
@media (min-width: 1440px) {
  .cr-page {
    padding: 40px 80px;
  }
}
@media (min-width: 1920px) {
  .cr-page {
    padding: 48px 120px;
  }
}

/* ---- Nav ---- */
.cr-nav {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 28px;
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
/* ---- Page title ---- */
.cr-page-title {
  margin-bottom: 24px;
}
.cr-page-title h1 {
  font-weight: 500;
  font-size: 32px;
  letter-spacing: -0.02em;
  color: var(--cr-text);
  line-height: 1.1;
}
.cr-page-title p {
  font-size: 14px;
  color: var(--cr-text-sec);
  margin-top: 6px;
}

/* ---- Section head ---- */
.cr-sec-head {
  display: flex;
  justify-content: space-between;
  align-items: baseline;
  margin: 32px 0 12px 0;
  gap: 12px;
  flex-wrap: wrap;
}
.cr-sec-head h3 {
  font-size: 20px;
  color: var(--cr-text);
  letter-spacing: -0.01em;
  font-weight: 500;
}
.cr-sec-head .cr-sec-meta {
  font-size: 13px;
  color: var(--cr-text-ter);
}

/* ---- Period switcher ---- */
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
.cr-period > button:hover:not(.active) {
  color: var(--cr-text);
}

/* ---- Card ---- */
.cr-card {
  background: var(--cr-surface);
  border: 1px solid var(--cr-border);
  border-radius: 16px;
  overflow: hidden;
}

/* ---- Row ---- */
.cr-row {
  display: grid;
  align-items: center;
  padding: 14px 22px;
  border-bottom: 1px solid var(--cr-border);
  gap: 16px;
}
.cr-row:last-child {
  border-bottom: 0;
}

/* ---- Bar ---- */
.cr-bar {
  height: 6px;
  background: var(--cr-surface-soft);
  border-radius: 3px;
  overflow: hidden;
}
.cr-bar > div {
  height: 100%;
  border-radius: 3px;
  background: var(--cr-coral);
}

/* ---- Loading / empty ---- */
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
.cr-skel-row {
  height: 32px;
  margin-bottom: 8px;
}
.cr-skel-row:last-child {
  margin-bottom: 0;
}
@keyframes crshimmer {
  0% {
    background-position: 200% 0;
  }
  100% {
    background-position: -200% 0;
  }
}
.cr-empty {
  padding: 18px 22px;
  color: var(--cr-text-ter);
  font-size: 13px;
}

/* ---- Fun stats row ---- */
.cr-fun-row {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 14px;
  margin-bottom: 24px;
}
@media (max-width: 900px) {
  .cr-fun-row {
    grid-template-columns: 1fr 1fr;
  }
}
@media (max-width: 480px) {
  .cr-fun-row {
    grid-template-columns: 1fr;
  }
}
.cr-fun-card {
  padding: 18px 20px;
}
.cr-fun-label {
  font-size: 12px;
  color: var(--cr-text-sec);
  font-weight: 500;
  letter-spacing: 0.02em;
}
.cr-fun-name {
  font-size: 18px;
  color: var(--cr-text);
  font-weight: 600;
  margin-top: 4px;
  letter-spacing: -0.01em;
}
.cr-fun-name.cr-fun-big {
  font-size: 26px;
  font-weight: 500;
  letter-spacing: -0.02em;
}
.cr-fun-meta {
  font-size: 12px;
  color: var(--cr-text-ter);
  margin-top: 4px;
}

/* ---- Rank row ---- */
.cr-rank-row {
  grid-template-columns: 48px 1fr 1fr 100px 90px;
  gap: 14px;
}
@media (max-width: 700px) {
  .cr-rank-row {
    grid-template-columns: 40px 1fr 80px;
  }
  .cr-rank-row .cr-bar,
  .cr-rank-row .cr-t {
    display: none;
  }
}
.cr-rank-badge {
  font-size: 20px;
  text-align: center;
  color: var(--cr-text-ter);
}
.cr-rank-name {
  font-size: 14px;
  color: var(--cr-text);
  font-weight: 500;
}
.cr-val {
  font-size: 14px;
  text-align: right;
  color: var(--cr-text);
}
.cr-t {
  font-size: 13px;
  color: var(--cr-text-ter);
  text-align: right;
}

.cr-insights-dual {
  display: grid;
  grid-template-columns: 1fr;
  gap: 24px;
  margin-top: 20px;
}
@media (min-width: 1024px) {
  .cr-insights-dual {
    grid-template-columns: 2fr 1fr;
  }
}
.cr-insights-trio {
  display: grid;
  grid-template-columns: 1fr;
  gap: 24px;
  margin-top: 20px;
}
@media (min-width: 1024px) {
  .cr-insights-trio {
    grid-template-columns: 2fr 1fr 1fr;
  }
}

.cr-mod-heat-row {
  padding: 8px 0;
  border-bottom: 1px dashed var(--cr-border);
}
.cr-mod-heat-row:last-child {
  border-bottom: 0;
}
.cr-mod-heat-top {
  display: grid;
  grid-template-columns: 30px 1fr 90px;
  gap: 10px;
  align-items: baseline;
  margin-bottom: 6px;
}
.cr-mod-heat-rank {
  color: var(--cr-text-ter);
  font-size: 12px;
  text-align: center;
}
.cr-mod-heat-name {
  color: var(--cr-text);
  font-size: 13px;
  font-weight: 500;
  word-break: break-all;
}
.cr-mod-heat-val {
  color: var(--cr-text-sec);
  font-size: 12px;
  text-align: right;
}

.cr-heatmap {
  display: grid;
  grid-template-columns: repeat(10, 1fr);
  gap: 4px;
}
.cr-heatmap-cell {
  aspect-ratio: 1;
  border-radius: 3px;
  background: var(--cr-surface-soft);
  display: inline-block;
  width: 12px;
  height: 12px;
}
.cr-heatmap .cr-heatmap-cell {
  width: 100%;
  height: auto;
}
.cr-heatmap-cell[data-level='1'] {
  background: var(--cr-coral-soft);
}
.cr-heatmap-cell[data-level='2'] {
  background: color-mix(in srgb, var(--cr-coral) 35%, var(--cr-surface));
}
.cr-heatmap-cell[data-level='3'] {
  background: color-mix(in srgb, var(--cr-coral) 70%, var(--cr-surface));
}
.cr-heatmap-cell[data-level='4'] {
  background: var(--cr-coral);
}
.cr-heatmap-legend {
  display: flex;
  align-items: center;
  gap: 4px;
  justify-content: flex-end;
  margin-top: 10px;
  font-size: 11px;
  color: var(--cr-text-ter);
}

.cr-trend-row {
  display: grid;
  grid-template-columns: 50px 1fr 70px;
  gap: 10px;
  align-items: center;
  padding: 5px 0;
}
.cr-trend-date,
.cr-trend-val {
  font-size: 12px;
  color: var(--cr-text-sec);
}
.cr-trend-val {
  text-align: right;
  color: var(--cr-text);
  font-weight: 500;
}

.cr-hourly {
  display: grid;
  grid-template-columns: repeat(24, 1fr);
  align-items: end;
  gap: 2px;
  height: 100px;
}
.cr-hourly-bar {
  background: var(--cr-coral);
  border-radius: 2px 2px 0 0;
  min-height: 4px;
}
.cr-hourly-axis {
  display: flex;
  justify-content: space-between;
  margin-top: 6px;
  font-size: 11px;
  color: var(--cr-text-ter);
}

.cr-cache-n {
  font-size: 36px;
  font-weight: 500;
  color: var(--cr-coral);
  line-height: 1;
  margin-bottom: 8px;
}
.cr-cache-meta {
  font-size: 12px;
  color: var(--cr-text-ter);
  margin-top: 3px;
}
</style>
