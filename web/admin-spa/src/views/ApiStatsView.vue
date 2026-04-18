<template>
  <component :is="ActiveView" />
</template>

<script setup>
import { computed, defineAsyncComponent, onMounted } from 'vue'
import { storeToRefs } from 'pinia'
import { useApiStatsStore } from '@/stores/apistats'
import { useClaudeBodyTheme } from '@/composables/useClaudeBodyTheme'

const LegacyView = defineAsyncComponent(() => import('./ApiStatsLegacyView.vue'))
const ClaudeView = defineAsyncComponent(() => import('./ApiStatsClaudeView.vue'))

const apiStatsStore = useApiStatsStore()
const { oemSettings } = storeToRefs(apiStatsStore)

// flag 未就绪时默认走 Legacy（体验优先：立即渲染，避免白屏等 OEM）。
// OEM 加载完成后若 flag=true，自动切到 Claude 视图（短暂一次重渲染）。
const isClaudeMode = computed(() => oemSettings.value?.useClaudeStyleStats === true)

const ActiveView = computed(() => (isClaudeMode.value ? ClaudeView : LegacyView))

// Shell 层接管 body/html 背景：
// 在 Shell mount 时就根据 flag 直接 apply/restore，避免 ClaudeView 异步 mount
// 造成的 race condition（刷新后冷色背景闪烁或锁死）。
useClaudeBodyTheme({ enabled: isClaudeMode })

onMounted(() => {
  if (!oemSettings.value?.updatedAt) {
    apiStatsStore.loadOemSettings()
  }
})
</script>
