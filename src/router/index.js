import { createRouter, createWebHashHistory } from "vue-router";
import SneezyMap from "../components/SneezyMap.vue";

const router = createRouter({
    history: createWebHashHistory(),
    routes: [
        {
            path: "/",
            name: "Home",
            component: SneezyMap,
            children: [
                {
                    path: "room/:roomId",
                    name: "Room",
                    component: SneezyMap,
                },
                {
                    path: "zone/:zoneId",
                    name: "Zone",
                    component: SneezyMap,
                },
            ],
        },
    ],
});

export default router;
