<template>
  <component :is="ActiveView" v-if="oemReady" />
</template>

<script setup>
import { computed, defineAsyncComponent, onMounted, ref } from 'vue'
import { storeToRefs } from 'pinia'
import { useApiStatsStore } from '@/stores/apistats'

const LegacyView = defineAsyncComponent(() => import('./InsightsLegacyView.vue'))
const ClaudeView = defineAsyncComponent(() => import('./InsightsClaudeView.vue'))

const apiStatsStore = useApiStatsStore()
const { oemSettings, oemLoading } = storeToRefs(apiStatsStore)

// Fallback 保险丝：即使 OEM 加载卡住或失败，N 秒后也强制渲染 Legacy
const timedOut = ref(false)

const oemReady = computed(() => timedOut.value || !oemLoading.value)

const ActiveView = computed(() =>
  oemSettings.value?.useClaudeStyleStats === true ? ClaudeView : LegacyView
)

onMounted(() => {
  if (!oemSettings.value?.updatedAt) {
    apiStatsStore.loadOemSettings()
  }
  setTimeout(() => {
    timedOut.value = true
  }, 2500)
})
</script>
