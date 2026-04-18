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
            <span class="cr-brand-sub">Insights</span>
          </span>
        </div>
        <div class="cr-nav-links">
          <router-link class="cr-nav-a" to="/api-stats">Stats</router-link>
          <ThemeToggle class="cr-theme-toggle" mode="dropdown" />
          <router-link
            v-if="oemSettings.showAdminButton !== false"
            class="cr-nav-a cr-nav-a-primary"
            to="/dashboard"
            >Admin</router-link
          >
        </div>
      </nav>

      <!-- Page title -->
      <div class="cr-page-title">
        <h1 class="cr-serif">Insights &amp; rankings</h1>
        <p>Top users, efficiency leaders, and aggregate spend across your organization.</p>
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
          <div class="cr-fun-meta">
            {{ (funStats.todayRequests || 0).toLocaleString() }} requests
          </div>
        </div>
      </div>

      <!-- Rank list -->
      <div class="cr-sec-head">
        <h3 class="cr-serif">Top users</h3>
        <div class="cr-period">
          <button :class="{ active: selectedRange === 'today' }" @click="switchRange('today')">
            Today
          </button>
          <button :class="{ active: selectedRange === '7days' }" @click="switchRange('7days')">
            7 days
          </button>
          <button :class="{ active: selectedRange === '30days' }" @click="switchRange('30days')">
            30 days
          </button>
          <button :class="{ active: selectedRange === 'all' }" @click="switchRange('all')">
            All time
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
      <div v-else class="cr-card cr-empty">No data for this range.</div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { storeToRefs } from 'pinia'
import { useApiStatsStore } from '@/stores/apistats'
import { useThemeStore } from '@/stores/theme'
import ThemeToggle from '@/components/common/ThemeToggle.vue'
import request from '@/utils/request'
import '@/styles/claude-tokens.css'

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

// ---- Lifecycle ----
onMounted(() => {
  apiStatsStore.loadOemSettings()
  loadRankData()
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
:deep(.cr-theme-toggle) {
  margin: 0 2px;
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
</style>
