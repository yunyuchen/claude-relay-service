<template>
  <div
    class="min-h-screen p-2 sm:p-4 md:p-6"
    :class="isDarkMode ? 'gradient-bg-dark' : 'gradient-bg'"
  >
    <!-- 顶部导航 -->
    <div
      class="glass-strong mb-4 rounded-2xl p-3 shadow-xl sm:mb-6 sm:rounded-3xl sm:p-4 md:mb-8 md:p-6"
    >
      <div class="flex flex-col items-center justify-between gap-3 sm:gap-4 md:flex-row">
        <LogoTitle
          :loading="oemLoading"
          :logo-src="oemSettings.siteIconData || oemSettings.siteIcon"
          subtitle="排行榜 & 洞察"
          :title="oemSettings.siteName"
        />
        <div class="flex items-center gap-2 md:gap-4">
          <ThemeToggle mode="dropdown" />
          <div
            class="h-8 w-px bg-gradient-to-b from-transparent via-gray-300 to-transparent opacity-50 dark:via-gray-600"
          />
          <router-link
            class="admin-button-refined flex items-center gap-2 rounded-2xl px-4 py-2 transition-all duration-300 md:px-5 md:py-2.5"
            to="/api-stats"
          >
            <i class="fas fa-chart-line text-sm md:text-base" />
            <span class="text-xs font-semibold tracking-wide md:text-sm">统计查询</span>
          </router-link>
        </div>
      </div>
    </div>

    <!-- 趣味统计卡片 -->
    <div class="mb-3 grid grid-cols-2 gap-2 sm:mb-4 sm:gap-3 lg:grid-cols-4">
      <div class="stat-card">
        <div class="flex items-center justify-between">
          <div>
            <p class="mb-1 text-xs font-semibold text-gray-600 dark:text-gray-400 sm:text-sm">
              {{ rangeLabel }}卷王
            </p>
            <p
              class="max-w-[140px] truncate text-lg font-bold text-gray-900 dark:text-gray-100 sm:text-xl"
              :title="funStats.topUser?.name"
            >
              {{ funStats.topUser?.name || '-' }}
            </p>
            <p class="mt-1 text-xs text-gray-500 dark:text-gray-400">
              ${{ funStats.topUser?.cost?.toFixed(2) || '0.00' }}
            </p>
          </div>
          <div class="stat-icon flex-shrink-0 bg-gradient-to-br from-amber-400 to-orange-500">
            <i class="fas fa-crown text-white" />
          </div>
        </div>
      </div>

      <div class="stat-card">
        <div class="flex items-center justify-between">
          <div>
            <p class="mb-1 text-xs font-semibold text-gray-600 dark:text-gray-400 sm:text-sm">
              效率之星
            </p>
            <p
              class="max-w-[140px] truncate text-lg font-bold text-gray-900 dark:text-gray-100 sm:text-xl"
              :title="funStats.cacheKing?.name"
            >
              {{ funStats.cacheKing?.name || '-' }}
            </p>
            <p class="mt-1 text-xs text-gray-500 dark:text-gray-400">
              缓存率 {{ funStats.cacheKing?.rate || '0' }}%
            </p>
          </div>
          <div class="stat-icon flex-shrink-0 bg-gradient-to-br from-emerald-400 to-teal-500">
            <i class="fas fa-bolt text-white" />
          </div>
        </div>
      </div>

      <div class="stat-card">
        <div class="flex items-center justify-between">
          <div>
            <p class="mb-1 text-xs font-semibold text-gray-600 dark:text-gray-400 sm:text-sm">
              Token 大户
            </p>
            <p
              class="max-w-[140px] truncate text-lg font-bold text-gray-900 dark:text-gray-100 sm:text-xl"
              :title="funStats.tokenKing?.name"
            >
              {{ funStats.tokenKing?.name || '-' }}
            </p>
            <p class="mt-1 text-xs text-gray-500 dark:text-gray-400">
              {{ formatTokens(funStats.tokenKing?.tokens) }}
            </p>
          </div>
          <div class="stat-icon flex-shrink-0 bg-gradient-to-br from-violet-500 to-purple-600">
            <i class="fas fa-coins text-white" />
          </div>
        </div>
      </div>

      <div class="stat-card">
        <div class="flex items-center justify-between">
          <div>
            <p class="mb-1 text-xs font-semibold text-gray-600 dark:text-gray-400 sm:text-sm">
              {{ rangeLabel }}总花费
            </p>
            <p class="text-2xl font-bold text-gray-900 dark:text-gray-100 sm:text-3xl">
              ${{ funStats.todayCost?.toFixed(2) || '0.00' }}
            </p>
            <p class="mt-1 text-xs text-gray-500 dark:text-gray-400">
              {{ funStats.todayRequests?.toLocaleString() || '0' }} 请求
            </p>
          </div>
          <div class="stat-icon flex-shrink-0 bg-gradient-to-br from-blue-500 to-indigo-600">
            <i class="fas fa-chart-line text-white" />
          </div>
        </div>
      </div>
    </div>

    <!-- 主内容区 -->
    <div class="grid grid-cols-1 gap-3 sm:gap-4 lg:grid-cols-3">
      <!-- 费用排行榜 -->
      <div class="lg:col-span-2">
        <div class="glass-strong rounded-xl p-3 shadow-xl sm:rounded-2xl sm:p-4">
          <div class="mb-2 flex items-center justify-between">
            <h3 class="text-sm font-bold text-gray-900 dark:text-gray-100 sm:text-base">
              <i class="fas fa-trophy mr-2 text-amber-500" />费用排行榜
            </h3>
            <div class="flex gap-1">
              <button
                v-for="range in timeRanges"
                :key="range.key"
                :class="[
                  'rounded-lg px-2 py-1 text-xs font-medium transition-all sm:px-3',
                  selectedRange === range.key
                    ? 'bg-indigo-500 text-white shadow-sm'
                    : 'text-gray-500 hover:bg-gray-100 dark:text-gray-400 dark:hover:bg-gray-700'
                ]"
                @click="switchRange(range.key)"
              >
                {{ range.label }}
              </button>
            </div>
          </div>

          <div v-if="loadingRank" class="flex items-center justify-center py-6">
            <i class="fas fa-spinner fa-spin text-2xl text-gray-400" />
          </div>

          <div v-else-if="rankList.length === 0" class="py-12 text-center text-gray-400">
            <i class="fas fa-inbox mb-2 text-3xl" />
            <p>暂无数据</p>
          </div>

          <div v-else class="space-y-1">
            <div
              v-for="(item, index) in rankList"
              :key="index"
              class="flex items-center gap-2 rounded-lg px-2 py-1.5 transition-colors hover:bg-white/50 dark:hover:bg-gray-800/50"
            >
              <div class="flex w-8 flex-shrink-0 items-center justify-center">
                <span v-if="index === 0" class="text-2xl">🥇</span>
                <span v-else-if="index === 1" class="text-2xl">🥈</span>
                <span v-else-if="index === 2" class="text-2xl">🥉</span>
                <span v-else class="text-sm font-bold text-gray-400">#{{ index + 1 }}</span>
              </div>

              <div class="min-w-0 flex-1">
                <div class="flex items-center justify-between">
                  <p class="truncate text-sm font-semibold text-gray-900 dark:text-gray-100">
                    {{ item.name }}
                  </p>
                  <p
                    class="ml-2 flex-shrink-0 text-sm font-bold text-indigo-600 dark:text-indigo-400"
                  >
                    ${{ item.cost.toFixed(2) }}
                  </p>
                </div>
                <div
                  class="mt-1.5 h-2 w-full overflow-hidden rounded-full bg-gray-100 dark:bg-gray-700"
                >
                  <div
                    class="h-full rounded-full transition-all duration-500"
                    :class="[
                      index === 0
                        ? 'bg-gradient-to-r from-amber-400 to-orange-500'
                        : index === 1
                          ? 'bg-gradient-to-r from-gray-300 to-gray-400'
                          : index === 2
                            ? 'bg-gradient-to-r from-amber-600 to-amber-700'
                            : 'bg-gradient-to-r from-indigo-400 to-indigo-500'
                    ]"
                    :style="{ width: getBarWidth(item.cost) + '%' }"
                  />
                </div>
                <div class="mt-1 flex items-center gap-3 text-xs text-gray-400">
                  <span>{{ item.requests?.toLocaleString() || 0 }} 请求</span>
                  <span>{{ formatTokens(item.allTokens) }}</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- 右侧面板 -->
      <div class="space-y-3 sm:space-y-4">
        <!-- 模型热度榜 -->
        <div class="glass-strong rounded-xl p-3 shadow-xl sm:rounded-2xl sm:p-4">
          <h3 class="mb-2 text-sm font-bold text-gray-900 dark:text-gray-100 sm:text-base">
            <i class="fas fa-fire mr-2 text-red-500" />今日模型热度
          </h3>

          <div v-if="loadingModels" class="flex items-center justify-center py-4">
            <i class="fas fa-spinner fa-spin text-xl text-gray-400" />
          </div>

          <div v-else-if="modelRank.length === 0" class="py-8 text-center text-gray-400">
            暂无数据
          </div>

          <div v-else class="space-y-2">
            <div v-for="(model, index) in modelRank" :key="model.model">
              <div class="flex items-center justify-between text-sm">
                <div class="flex items-center gap-2 truncate">
                  <span class="font-mono text-xs text-gray-400">{{ index + 1 }}</span>
                  <span class="truncate font-medium text-gray-700 dark:text-gray-300">
                    {{ model.model }}
                  </span>
                </div>
                <span
                  class="ml-2 flex-shrink-0 text-xs font-semibold text-gray-500 dark:text-gray-400"
                >
                  {{ model.requests.toLocaleString() }}次
                </span>
              </div>
              <div
                class="mt-1 h-1.5 w-full overflow-hidden rounded-full bg-gray-100 dark:bg-gray-700"
              >
                <div
                  class="h-full rounded-full bg-gradient-to-r from-red-400 to-orange-400 transition-all duration-500"
                  :style="{ width: getModelBarWidth(model.requests) + '%' }"
                />
              </div>
            </div>
          </div>
        </div>

        <!-- 活跃度热力图 -->
        <div class="glass-strong rounded-xl p-3 shadow-xl sm:rounded-2xl sm:p-4">
          <h3 class="mb-2 text-sm font-bold text-gray-900 dark:text-gray-100 sm:text-base">
            <i class="fas fa-calendar-alt mr-2 text-green-500" />近30天活跃度
          </h3>

          <div v-if="loadingHeatmap" class="flex items-center justify-center py-4">
            <i class="fas fa-spinner fa-spin text-xl text-gray-400" />
          </div>

          <div v-else>
            <div class="grid grid-cols-10 gap-1 sm:grid-cols-10">
              <div
                v-for="day in heatmapData"
                :key="day.date"
                class="aspect-square rounded-sm transition-colors"
                :class="getHeatmapColor(day.requests)"
                :title="`${day.date}: ${day.requests} 请求`"
              />
            </div>
            <div class="mt-3 flex items-center justify-end gap-1 text-xs text-gray-400">
              <span>少</span>
              <div class="h-3 w-3 rounded-sm bg-gray-100 dark:bg-gray-700" />
              <div class="h-3 w-3 rounded-sm bg-green-200 dark:bg-green-900" />
              <div class="h-3 w-3 rounded-sm bg-green-400 dark:bg-green-700" />
              <div class="h-3 w-3 rounded-sm bg-green-600 dark:bg-green-500" />
              <div class="h-3 w-3 rounded-sm bg-green-800 dark:bg-green-300" />
              <span>多</span>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- 第二屏：深度洞察 -->
    <div class="mt-3 sm:mt-4">
      <!-- 费用趋势 + 高峰时段 -->
      <div class="mb-3 grid grid-cols-1 gap-3 sm:mb-4 sm:gap-4 lg:grid-cols-2">
        <!-- 14天费用趋势 -->
        <div class="glass-strong rounded-xl p-3 shadow-xl sm:rounded-2xl sm:p-4">
          <div class="mb-2 flex items-center justify-between">
            <h3 class="text-sm font-bold text-gray-900 dark:text-gray-100 sm:text-base">
              <i class="fas fa-chart-area mr-2 text-blue-500" />费用趋势 (近14天)
            </h3>
            <div v-if="overview.costProjection" class="text-right">
              <p class="text-xs text-gray-400">本月预估</p>
              <p class="text-sm font-bold text-indigo-600 dark:text-indigo-400">
                ${{ overview.costProjection.projected }}
              </p>
            </div>
          </div>
          <div v-if="loadingOverview" class="flex items-center justify-center py-6">
            <i class="fas fa-spinner fa-spin text-xl text-gray-400" />
          </div>
          <div v-else-if="overview.dailyCosts" class="space-y-1">
            <div v-for="day in overview.dailyCosts" :key="day.date" class="flex items-center gap-2">
              <span class="w-16 flex-shrink-0 text-xs text-gray-400">
                {{ day.date.slice(5) }}
              </span>
              <div class="h-4 flex-1 overflow-hidden rounded-full bg-gray-100 dark:bg-gray-700">
                <div
                  class="h-full rounded-full bg-gradient-to-r from-blue-400 to-indigo-500 transition-all duration-500"
                  :style="{ width: getDailyCostWidth(day.cost) + '%' }"
                />
              </div>
              <span
                class="w-16 flex-shrink-0 text-right text-xs font-medium text-gray-600 dark:text-gray-300"
              >
                ${{ day.cost.toFixed(1) }}
              </span>
            </div>
          </div>
        </div>

        <!-- 高峰时段 -->
        <div class="glass-strong rounded-xl p-3 shadow-xl sm:rounded-2xl sm:p-4">
          <h3 class="mb-2 text-sm font-bold text-gray-900 dark:text-gray-100 sm:text-base">
            <i class="fas fa-clock mr-2 text-orange-500" />今日时段分布
          </h3>
          <div v-if="loadingOverview" class="flex items-center justify-center py-6">
            <i class="fas fa-spinner fa-spin text-xl text-gray-400" />
          </div>
          <div v-else-if="overview.hourlyStats" class="flex items-end gap-0.5" style="height: 80px">
            <div
              v-for="h in overview.hourlyStats"
              :key="h.hour"
              class="group relative flex-1 cursor-default"
              :title="`${h.hour}:00 - ${h.requests} 请求`"
            >
              <div
                class="absolute bottom-0 w-full rounded-t transition-all duration-300"
                :class="
                  h.requests > 0
                    ? 'bg-gradient-to-t from-orange-400 to-amber-300'
                    : 'bg-gray-100 dark:bg-gray-700'
                "
                :style="{ height: getHourBarHeight(h.requests) + '%', minHeight: '4px' }"
              />
            </div>
          </div>
          <div v-if="overview.hourlyStats" class="mt-1 flex justify-between text-xs text-gray-400">
            <span>0时</span><span>6时</span><span>12时</span><span>18时</span><span>23时</span>
          </div>
        </div>
      </div>

      <!-- 模型偏好 + 连续活跃 + 缓存节省 -->
      <div class="grid grid-cols-1 gap-3 sm:gap-4 lg:grid-cols-3">
        <!-- 模型偏好画像 -->
        <div class="glass-strong rounded-2xl p-4 shadow-xl sm:rounded-3xl sm:p-6 lg:col-span-2">
          <h3 class="mb-2 text-sm font-bold text-gray-900 dark:text-gray-100 sm:text-base">
            <i class="fas fa-fingerprint mr-2 text-purple-500" />模型偏好画像
          </h3>
          <div v-if="loadingOverview" class="flex items-center justify-center py-6">
            <i class="fas fa-spinner fa-spin text-xl text-gray-400" />
          </div>
          <div v-else class="space-y-1">
            <div
              v-for="user in (overview.userProfiles || []).slice(0, 8)"
              :key="user.name"
              class="flex items-center gap-2 rounded-lg px-2 py-1.5 transition-colors hover:bg-white/50 dark:hover:bg-gray-800/50"
            >
              <div class="min-w-0 flex-1">
                <div class="flex items-center justify-between">
                  <span class="text-sm font-semibold text-gray-900 dark:text-gray-100">
                    {{ user.name }}
                  </span>
                  <span class="text-xs text-gray-400">
                    {{ user.totalRequests.toLocaleString() }} 请求 · {{ user.modelCount }} 模型
                  </span>
                </div>
                <div class="mt-1 flex items-center gap-1">
                  <span
                    v-for="m in user.models"
                    :key="m.model"
                    class="inline-flex items-center gap-1 rounded-full px-2 py-0.5 text-xs"
                    :class="
                      m === user.models[0]
                        ? 'bg-purple-100 text-purple-700 dark:bg-purple-900/30 dark:text-purple-300'
                        : 'bg-gray-100 text-gray-600 dark:bg-gray-700 dark:text-gray-400'
                    "
                  >
                    {{ m.model }}
                    <span class="font-medium">{{ m.requests }}</span>
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- 右侧小卡片 -->
        <div class="space-y-3 sm:space-y-4">
          <!-- 连续活跃排行 -->
          <div class="glass-strong rounded-xl p-3 shadow-xl sm:rounded-2xl sm:p-4">
            <h3 class="mb-2 text-sm font-bold text-gray-900 dark:text-gray-100 sm:text-base">
              <i class="fas fa-fire-alt mr-2 text-red-500" />连续活跃
            </h3>
            <div v-if="loadingOverview" class="flex items-center justify-center py-6">
              <i class="fas fa-spinner fa-spin text-xl text-gray-400" />
            </div>
            <div v-else class="space-y-2">
              <div
                v-for="(s, i) in (overview.streaks || []).slice(0, 5)"
                :key="s.name"
                class="flex items-center justify-between"
              >
                <div class="flex items-center gap-2">
                  <span class="text-sm">{{ i === 0 ? '🔥' : i === 1 ? '⚡' : '✨' }}</span>
                  <span class="text-sm font-medium text-gray-700 dark:text-gray-300">
                    {{ s.name }}
                  </span>
                </div>
                <span class="text-sm font-bold text-orange-500"> {{ s.streak }}天 </span>
              </div>
              <div v-if="!overview.streaks?.length" class="py-4 text-center text-sm text-gray-400">
                暂无数据
              </div>
            </div>
          </div>

          <!-- 缓存节省 -->
          <div class="glass-strong rounded-xl p-3 shadow-xl sm:rounded-2xl sm:p-4">
            <h3 class="mb-2 text-sm font-bold text-gray-900 dark:text-gray-100 sm:text-base">
              <i class="fas fa-piggy-bank mr-2 text-pink-500" />本月缓存节省
            </h3>
            <div v-if="loadingOverview" class="flex items-center justify-center py-6">
              <i class="fas fa-spinner fa-spin text-xl text-gray-400" />
            </div>
            <div v-else class="text-center">
              <p class="text-3xl font-bold text-emerald-600 dark:text-emerald-400">
                ${{ overview.cache?.saving?.toFixed(2) || '0.00' }}
              </p>
              <p class="mt-1 text-xs text-gray-400">缓存命中率 {{ overview.cache?.rate || 0 }}%</p>
              <p class="mt-0.5 text-xs text-gray-400">
                {{ formatTokens(overview.cache?.totalCacheReadTokens) }} tokens 命中缓存
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue'
import { useThemeStore } from '@/stores/theme'
import { useAuthStore } from '@/stores/auth'
import request from '@/utils/request'
import LogoTitle from '@/components/common/LogoTitle.vue'
import ThemeToggle from '@/components/common/ThemeToggle.vue'

// ======================== 主题 & OEM ========================

const themeStore = useThemeStore()
const authStore = useAuthStore()
const isDarkMode = computed(() => themeStore.isDarkMode)
const oemSettings = computed(() => authStore.oemSettings || {})
const oemLoading = ref(false)

// ======================== 状态 ========================

const loadingRank = ref(true)
const loadingModels = ref(true)
const loadingHeatmap = ref(true)

const selectedRange = ref('today')
const rangeLabel = computed(() => {
  const map = { today: '今日', '7days': '7天', '30days': '30天', all: '累计' }
  return map[selectedRange.value] || '今日'
})
const timeRanges = [
  { key: 'today', label: '今日' },
  { key: '7days', label: '7天' },
  { key: '30days', label: '30天' },
  { key: 'all', label: '累计' }
]

const loadingOverview = ref(true)

const rankList = ref([])
const modelRank = ref([])
const heatmapData = ref([])
const overview = ref({})
const funStats = ref({
  topUser: null,
  cacheKing: null,
  tokenKing: null,
  todayRequests: 0,
  todayCost: 0
})

// ======================== 生命周期 ========================

onMounted(async () => {
  // 加载 OEM 设置
  if (!authStore.oemSettings?.siteName) {
    oemLoading.value = true
    try {
      await authStore.loadOemSettings()
    } catch {
      /* ignore */
    }
    oemLoading.value = false
  }

  await Promise.all([loadRankData(), loadModelStats(), loadHeatmapData(), loadOverview()])
})

// ======================== 数据加载 ========================

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

  // 今日汇总
  funStats.value.todayCost = ranking.reduce((sum, k) => sum + (k.cost || 0), 0)
  funStats.value.todayRequests = ranking.reduce((sum, k) => sum + (k.requests || 0), 0)
}

async function loadModelStats() {
  loadingModels.value = true
  try {
    const result = await request({
      url: '/apiStats/insights/models',
      method: 'GET'
    })

    if (result.success) {
      modelRank.value = result.data || []
    }
  } catch (error) {
    console.error('Failed to load model stats:', error)
  } finally {
    loadingModels.value = false
  }
}

async function loadHeatmapData() {
  loadingHeatmap.value = true
  try {
    const result = await request({
      url: '/apiStats/insights/activity',
      method: 'GET'
    })

    if (result.success) {
      heatmapData.value = result.data || []
    }
  } catch (error) {
    console.error('Failed to load activity:', error)
  } finally {
    loadingHeatmap.value = false
  }
}

async function loadOverview() {
  loadingOverview.value = true
  try {
    const result = await request({
      url: '/apiStats/insights/overview',
      method: 'GET'
    })
    if (result.success) {
      overview.value = result.data || {}
    }
  } catch (error) {
    console.error('Failed to load overview:', error)
  } finally {
    loadingOverview.value = false
  }
}

// ======================== 操作 ========================

async function switchRange(range) {
  selectedRange.value = range
  await loadRankData()
}

// ======================== 工具函数 ========================

function getBarWidth(cost) {
  if (rankList.value.length === 0) return 0
  const maxCost = rankList.value[0]?.cost || 1
  return Math.max(2, (cost / maxCost) * 100)
}

function getModelBarWidth(requests) {
  if (modelRank.value.length === 0) return 0
  const maxRequests = modelRank.value[0]?.requests || 1
  return Math.max(2, (requests / maxRequests) * 100)
}

function getHeatmapColor(count) {
  if (!count || count === 0) return 'bg-gray-100 dark:bg-gray-700'
  if (count < 10) return 'bg-green-200 dark:bg-green-900'
  if (count < 50) return 'bg-green-400 dark:bg-green-700'
  if (count < 200) return 'bg-green-600 dark:bg-green-500'
  return 'bg-green-800 dark:bg-green-300'
}

function getDailyCostWidth(cost) {
  const costs = overview.value.dailyCosts || []
  const maxCost = Math.max(...costs.map((d) => d.cost), 1)
  return Math.max(1, (cost / maxCost) * 100)
}

function getHourBarHeight(requests) {
  const stats = overview.value.hourlyStats || []
  const maxReqs = Math.max(...stats.map((h) => h.requests), 1)
  return requests > 0 ? Math.max(5, (requests / maxReqs) * 100) : 2
}

function formatTokens(tokens) {
  if (!tokens) return '0'
  if (tokens >= 1_000_000_000) return (tokens / 1_000_000_000).toFixed(1) + 'B'
  if (tokens >= 1_000_000) return (tokens / 1_000_000).toFixed(1) + 'M'
  if (tokens >= 1_000) return (tokens / 1_000).toFixed(1) + 'K'
  return tokens.toString()
}
</script>
