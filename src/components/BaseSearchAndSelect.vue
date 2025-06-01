<script setup>
import { ref, computed } from "vue";

const props = defineProps(["name", "opts", "prefix"]);
const emit = defineEmits(["select"]);

const search = ref("");
const input = ref("");
const inputVal = ref(null);
const selection = ref("");
const isOpen = ref(false);
const results = computed(() => {
    return props.opts
        .filter((option) => {
            if (search.value === "" || search.value === null) return true;
            return option.label.toLowerCase().includes(search.value.toLowerCase());
        })
        .slice(0, 100);
});

function open() {
    isOpen.value = true;
    document.getElementById(`${props.name}-search`).select();
    search.value = "";
    selection.value = results.value.find((option) => option.label == input.value) || "";
    if (selection.value == "") selection.value = results.value.length > 0 ? results.value[0] : "";
}

function change() {
    isOpen.value = true;

    search.value = input.value;
    selection.value = results.value.length > 0 ? results.value[0] : "";
}

const tab = (event) => {
    if (isOpen.value && results.value.length > 0) {
        doSelect(selection.value);
        event.preventDefault();
    }
    isOpen.value = false;
};

const focusout = () => {
    setTimeout(() => {
        isOpen.value = false;
    }, 200);
};

const clickselect = (option) => {
    doSelect(option);
};

const doSelect = (option) => {
    emit("select", option.value);
    input.value = option.label;
    isOpen.value = false;
};
</script>

<template>
    <div
        class="relative flex w-full mb-1 justify-stretch"
        @focusout.prevent="focusout()">
        <input
            type="text"
            :id="`${name}-search`"
            class="w-full pl-1 pr-6 border rounded-md cursor-pointer placeholder:text-gray-500 placeholder:opacity-50 border-neutral-500 bg-neutral-100 focus:outline-none overflow-clip text-ellipsis"
            :name="name"
            v-model="input"
            placeholder="Search or select..."
            @click="open()"
            @focus="open()"
            @input="change()"
            @keydown.tab="(e) => tab(e)"
            @keydown.enter="(e) => tab(e)"
            @keydown.arrow-up.prevent="
                selection =
                    results[results.map((option) => option.value).indexOf(selection.value) - 1] ||
                    results[results.length - 1]
            "
            @keydown.arrow-down.prevent="
                selection = results[results.map((option) => option.value).indexOf(selection.value) + 1] || results[0]
            "
            @keydown.esc="isOpen = false" />
        <ul
            v-if="isOpen && results.length > 0"
            class="absolute w-full mt-1 overflow-scroll list-none border-t border-l border-r rounded-b-none max-h-96 bottom-6 border-neutral-500 bg-neutral-100 focus:outline-none">
            <li
                v-for="option in results"
                :key="option.value"
                @click.prevent="clickselect(option)"
                @mouseover="selection = option"
                class="w-full pl-1 cursor-pointer text-nowrap overflow-clip text-ellipsis"
                :class="{ 'bg-purple-700 text-white': option.value === selection.value }">
                {{ option.label }}
            </li>
        </ul>
        <div
            v-if="opts.length > 0"
            class="absolute inset-y-0 right-0 flex items-center px-2 pointer-events-none">
            <svg
                class="w-4 h-4 fill-pink"
                xmlns="http://www.w3.org/2000/svg"
                viewBox="0 0 20 20">
                <path d="M9.293 12.95l.707.707L15.657 8l-1.414-1.414L10 10.828 5.757 6.586 4.343 8z" />
            </svg>
        </div>
    </div>
</template>
