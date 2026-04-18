<template>
  <component :is="ActiveView" />
</template>

<script setup>
import { computed, defineAsyncComponent, onMounted } from 'vue'
import { storeToRefs } from 'pinia'
import { useApiStatsStore } from '@/stores/apistats'

const LegacyView = defineAsyncComponent(() => import('./InsightsLegacyView.vue'))
const ClaudeView = defineAsyncComponent(() => import('./InsightsClaudeView.vue'))

const apiStatsStore = useApiStatsStore()
const { oemSettings } = storeToRefs(apiStatsStore)

// flag 未就绪时默认走 Legacy（体验优先：立即渲染，避免白屏等 OEM）。
// OEM 加载完成后若 flag=true，自动切到 Claude 视图（短暂一次重渲染）。
const ActiveView = computed(() =>
  oemSettings.value?.useClaudeStyleStats === true ? ClaudeView : LegacyView
)

onMounted(() => {
  if (!oemSettings.value?.updatedAt) {
    apiStatsStore.loadOemSettings()
  }
})
</script>
