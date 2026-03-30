---
name: "vue"
matches: ["vue", "vuejs", "vue.js", "vue3"]
version: "3"
updated: "2026-03-30"
status: "beta"
---

# Vue 3 Composition API — Seed

## Critical Rules (LLM MUST follow these)
1. Always use `<script setup lang="ts">` — never the Options API (`data`, `methods`, `computed` blocks) in new code.
2. Use `ref()` for primitives and `reactive()` for objects. Access `ref` values with `.value` in script, without `.value` in template.
3. Use `computed()` for any derived/calculated state — never recalculate in the template or with a watcher.
4. Define props with `defineProps<T>()` and emits with `defineEmits<T>()` using TypeScript generics for full type safety.
5. Extract reusable stateful logic into composables (`use`-prefixed functions) in a `composables/` directory.
6. Use Pinia for global/shared state — never Vuex in new projects.
7. Use `v-model` with `defineModel()` for two-way binding on custom components.

## Golden Example
```vue
<!-- composables/useCounter.ts -->
<script lang="ts">
import { ref, computed } from "vue";

export function useCounter(initial = 0) {
  const count = ref(initial);
  const doubled = computed(() => count.value * 2);

  function increment() {
    count.value++;
  }

  function reset() {
    count.value = initial;
  }

  return { count, doubled, increment, reset };
}
</script>

<!-- components/CounterDisplay.vue -->
<script setup lang="ts">
interface CounterDisplayProps {
  label: string;
  max?: number;
}

const props = defineProps<CounterDisplayProps>();

const emit = defineEmits<{
  limitReached: [count: number];
}>();

const { count, doubled, increment, reset } = useCounter(0);

function handleIncrement() {
  increment();
  if (props.max && count.value >= props.max) {
    emit("limitReached", count.value);
  }
}
</script>

<template>
  <div class="counter">
    <h2>{{ label }}</h2>
    <p>Count: {{ count }} (doubled: {{ doubled }})</p>
    <button @click="handleIncrement">+1</button>
    <button @click="reset">Reset</button>
    <p v-if="max">Limit: {{ max }}</p>
  </div>
</template>

<!-- stores/user.ts (Pinia) -->
<script lang="ts">
import { defineStore } from "pinia";
import { ref, computed } from "vue";

export const useUserStore = defineStore("user", () => {
  const name = ref("");
  const email = ref("");
  const isLoggedIn = computed(() => !!email.value);

  function login(userName: string, userEmail: string) {
    name.value = userName;
    email.value = userEmail;
  }

  function logout() {
    name.value = "";
    email.value = "";
  }

  return { name, email, isLoggedIn, login, logout };
});
</script>
```

## Common LLM Mistakes
- Generating Options API (`export default { data() {}, methods: {} }`) — this is the legacy pattern; Composition API with `<script setup>` is the standard for Vue 3.
- Mutating props directly (`props.value = x`) — props are read-only; emit an event or use `defineModel()` for two-way binding.
- Recalculating derived values in templates or watchers instead of using `computed()` — loses reactivity caching and hurts performance.
- Using `Vue.set()` or `this.$set()` — these are Vue 2 reactivity workarounds that do not exist in Vue 3.
- Using Vuex instead of Pinia — Vuex is in maintenance mode; Pinia is the officially recommended store for Vue 3.
