<template>
  <component :is="ActiveView" v-if="oemReady" />
</template>

<script setup>
import { computed, defineAsyncComponent, onMounted } from 'vue'
import { storeToRefs } from 'pinia'
import { useApiStatsStore } from '@/stores/apistats'

const LegacyView = defineAsyncComponent(() => import('./ApiStatsLegacyView.vue'))
const ClaudeView = defineAsyncComponent(() => import('./ApiStatsClaudeView.vue'))

const apiStatsStore = useApiStatsStore()
const { oemSettings, oemLoading } = storeToRefs(apiStatsStore)

// OEM 加载完成（无论成功或失败）后才决定渲染哪个视图；oemLoading 在 finally 里总会置 false，
// 即使网络失败也不会死锁到空白页。
const oemReady = computed(() => !oemLoading.value)

const ActiveView = computed(() =>
  oemSettings.value?.useClaudeStyleStats === true ? ClaudeView : LegacyView
)

onMounted(() => {
  if (!oemSettings.value?.updatedAt) {
    apiStatsStore.loadOemSettings()
  }
})
</script>
