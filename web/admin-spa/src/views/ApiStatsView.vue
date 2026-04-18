<template>
  <component :is="ActiveView" />
</template>

<script setup>
import { computed, defineAsyncComponent, onMounted } from 'vue'
import { storeToRefs } from 'pinia'
import { useApiStatsStore } from '@/stores/apistats'

const LegacyView = defineAsyncComponent(() => import('./ApiStatsLegacyView.vue'))
const ClaudeView = defineAsyncComponent(() => import('./ApiStatsClaudeView.vue'))

const apiStatsStore = useApiStatsStore()
const { oemSettings } = storeToRefs(apiStatsStore)

// Shell 在 OEM 加载完成前默认走 Legacy 以避免闪烁
const ActiveView = computed(() =>
  oemSettings.value?.useClaudeStyleStats === true ? ClaudeView : LegacyView
)

onMounted(() => {
  // 如果 store 之前没加载过 OEM，这里兜底加载一次
  if (typeof apiStatsStore.loadOemSettings === 'function' && !oemSettings.value?.updatedAt) {
    apiStatsStore.loadOemSettings()
  }
})
</script>
