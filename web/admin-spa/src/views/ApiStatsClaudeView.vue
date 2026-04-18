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
            <span class="cr-brand-sub">Stats</span>
          </span>
        </div>
        <div class="cr-nav-links">
          <router-link class="cr-nav-a" to="/insights">Insights</router-link>
          <a class="cr-nav-a" @click="currentTab = 'tutorial'">Tutorial</a>
          <ThemeToggle class="cr-theme-toggle" mode="dropdown" />
          <router-link
            v-if="oemSettings.showAdminButton !== false"
            class="cr-nav-a cr-nav-a-primary"
            to="/dashboard"
            >Admin</router-link
          >
        </div>
      </nav>

      <!-- 登录态：未输入 API Key -->
      <section v-if="!apiId && currentTab !== 'tutorial'" class="cr-auth">
        <div class="cr-card cr-auth-card">
          <h1 class="cr-serif cr-auth-title">Enter your API key</h1>
          <p class="cr-auth-sub">Sign in to view your usage, quota and model breakdown.</p>
          <ApiKeyInput />
        </div>
      </section>

      <!-- 教程 tab -->
      <section v-else-if="currentTab === 'tutorial'" class="cr-tut">
        <div class="cr-page-title">
          <a class="cr-back" @click="currentTab = 'stats'">← Back to stats</a>
          <h1 class="cr-serif">Usage tutorial</h1>
        </div>
        <div class="cr-card cr-tut-card">
          <TutorialView />
        </div>
      </section>

      <!-- 统计主体 -->
      <section v-else class="cr-main">
        <div class="cr-page-title">
          <h1 class="cr-serif">Your API usage</h1>
          <p>Track spend, limits, and model breakdown across all connected services.</p>
        </div>

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
                {{ statsData?.isActive === false ? 'Inactive' : 'Active' }}
                <span v-if="multiKeyMode" class="cr-sep">·</span>
                <span v-if="multiKeyMode" class="cr-badge">{{ apiIds.length }} keys</span>
                <span v-if="statsData?.expiresAt" class="cr-sep">·</span>
                <span v-if="statsData?.expiresAt">Expires {{ expiresInText }}</span>
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
                Today
              </button>
              <button
                :class="{ active: statsPeriod === 'monthly' }"
                :disabled="loading"
                @click="switchPeriod('monthly')"
              >
                This month
              </button>
              <button
                :class="{ active: statsPeriod === 'alltime' }"
                :disabled="loading"
                @click="switchPeriod('alltime')"
              >
                All time
              </button>
            </div>
            <button class="cr-btn-ghost" @click="handleSignOut">Sign out</button>
          </div>
        </div>

        <!-- Hero / Quota+Services / Models / Per-key 续下（后续任务） -->
        <div class="cr-card" style="padding: 18px; margin-top: 24px">
          <p>Stats body — continued in Task 8+</p>
        </div>
      </section>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { storeToRefs } from 'pinia'
import { useApiStatsStore } from '@/stores/apistats'
import { useThemeStore } from '@/stores/theme'
import ApiKeyInput from '@/components/apistats/ApiKeyInput.vue'
import ThemeToggle from '@/components/common/ThemeToggle.vue'
import TutorialView from './TutorialView.vue'
import '@/styles/claude-tokens.css'

const apiStatsStore = useApiStatsStore()
const themeStore = useThemeStore()

// eslint-disable-next-line no-unused-vars
const { apiId, apiKey, loading, statsPeriod, statsData, oemSettings, multiKeyMode, apiIds } =
  storeToRefs(apiStatsStore)

const { loadOemSettings, loadApiKeyFromStorage, loadServiceRates, switchPeriod, reset } =
  apiStatsStore

const isDarkMode = computed(() => themeStore.isDarkMode)

const currentTab = ref('stats')

const expiresInText = computed(() => {
  const exp = statsData.value?.expiresAt
  if (!exp) return ''
  const days = Math.max(0, Math.round((new Date(exp) - Date.now()) / 86400000))
  if (days === 0) return 'today'
  if (days === 1) return 'in 1 day'
  if (days < 30) return `in ${days} days`
  if (days < 365) return `in ${Math.round(days / 30)} months`
  return `in ${Math.round(days / 365)} years`
})

function handleSignOut() {
  reset()
  currentTab.value = 'stats'
}

onMounted(() => {
  loadOemSettings()
  loadApiKeyFromStorage()
  loadServiceRates()
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
  padding: 10px 16px 10px 10px;
  margin-bottom: 28px;
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
</style>
