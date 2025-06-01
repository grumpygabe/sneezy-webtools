<script setup>
import { ref, defineProps } from "vue";

const props = defineProps(["ttdata", "ttpos", "tthidden"]);
</script>

<template>
    <div
        class="absolute z-50 rounded-lg bg-neutral-300 border-neutral-800 border border-solid"
        :class="{
            hidden: tthidden,
            block: !tthidden,
        }"
        :style="{
            top: ttpos.top + 'px',
            left: ttpos.left + 'px',
        }"
    >
        {{ props.ttdata }}
    </div>
</template>
