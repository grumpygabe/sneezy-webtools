<script setup>
import { ref, defineProps } from "vue";
import rooms from "@/assets/rooms.json";
import zones from "@/assets/zones.json";

const props = defineProps(["room"]);

console.log(props.room);
</script>

<template>
    <div
        v-if="room && rooms[room]"
        class="flex flex-col items-center absolute top-0 left-0 right-0 px-auto bg-neutral-300 z-50 w-80 tablet:w-96 m-auto pb-1 rounded-b-lg border border-solid border-t-0 border-neutral-800"
    >
        <div class="w-full">
            <div class="text-xl font-bold mb-0 text-center">
                {{ rooms[room].name.replace(/<.>/gm, "") }} [{{ room }}]
            </div>
            <div class="text-center text-xs text-neutral-600">
                {{ zones[rooms[room].zone].name }}
            </div>
            <div class="text-center w-full flex-wrap flex-col">
                <span
                    v-for="flag in rooms[room].flags"
                    :key="flag"
                    class="text-xs bg-purple-800 text-neutral-300 rounded-lg px-2 py-0.5 mr-1 inline-block"
                    >{{ flag }}
                </span>
            </div>
        </div>
    </div>
</template>
