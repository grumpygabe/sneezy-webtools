<script setup>
import { onMounted, computed, reactive, ref, watch } from "vue";
import { useRoute, useRouter } from "vue-router";
import MapSVG from "@/assets/map.svg?skipsvgo";
import RoomDetails from "@/components/RoomDetails.vue";
import $ from "jquery";
import svgPanZoom from "svg-pan-zoom";
import Hammer from "hammerjs";
import zonesRaw from "@/assets/zones.json";
import roomsRaw from "@/assets/rooms.json";
import BaseSearchAndSelect from "./BaseSearchAndSelect.vue";

const router = useRouter();
const route = useRoute();

let svgElement = null;
let panZoomMap = null;

const zLevelsData = reactive({
    current: null,
    all: true,
    range: [],
});

const zonesData = reactive({
    current: route.params.zoneId ? route.params.zoneId : null,
    all: true,
    range: [],
});

const roomsData = [];
const autohide = ref(false);
const telelinks = ref(false);
const vnum = ref(null);
const controlsHidden = ref(false);

const selectedRoom = ref(null);
const selectedZone = ref(null);

watch(autohide, () => {
    updateLayers();
});
watch(telelinks, () => {
    updateLayers();
});

var eventsHandler;
eventsHandler = {
    haltEventListeners: ["touchstart", "touchend", "touchmove", "touchleave", "touchcancel"],
    init: function (options) {
        var instance = options.instance,
            initialScale = 1,
            pannedX = 0,
            pannedY = 0;

        // Init Hammer
        // Listen only for pointer and touch events
        this.hammer = Hammer(options.svgElement, {
            inputClass: Hammer.SUPPORT_POINTER_EVENTS ? Hammer.PointerEventInput : Hammer.TouchInput,
        });

        // Enable pinch
        this.hammer.get("pinch").set({ enable: true });

        // Handle double tap
        this.hammer.on("doubletap", function (ev) {
            instance.zoomIn();
        });

        // Handle pan
        this.hammer.on("panstart panmove", function (ev) {
            // On pan start reset panned variables
            if (ev.type === "panstart") {
                pannedX = 0;
                pannedY = 0;
            }

            // Pan only the difference
            instance.panBy({ x: ev.deltaX - pannedX, y: ev.deltaY - pannedY });
            pannedX = ev.deltaX;
            pannedY = ev.deltaY;
        });

        // Handle pinch
        this.hammer.on("pinchstart pinchmove", function (ev) {
            // On pinch start remember initial zoom
            if (ev.type === "pinchstart") {
                initialScale = instance.getZoom();
                instance.zoomAtPoint(initialScale * ev.scale, {
                    x: ev.center.x,
                    y: ev.center.y,
                });
            }

            instance.zoomAtPoint(initialScale * ev.scale, {
                x: ev.center.x,
                y: ev.center.y,
            });
        });

        // Prevent moving the page on some devices when panning over SVG
        options.svgElement.addEventListener("touchmove", function (e) {
            e.preventDefault();
        });
    },

    destroy: function () {
        this.hammer.destroy();
    },
};

watch(
    () => route.params.zoneId,
    (newVal, oldVal) => {
        if (newVal !== oldVal) {
            selectZone(zoneById(newVal));
        }
    }
);
watch(
    () => route.params.roomId,
    (newVal, oldVal) => {
        if (newVal !== oldVal) {
            selectRoomByVnum(newVal);
            gotoVnum();
        }
    }
);

onMounted(() => {
    svgElement = document.getElementById("map");

    panZoomMap = svgPanZoom("#map", {
        zoomEnabled: true,
        zoomScaleSensitivity: 0.4,
        maxZoom: 30,
        fit: true,
        customEventsHandler: eventsHandler,
    });
    updateLayers();
    panZoomMap.zoom(4);
    panZoomMap.panBy({ x: -0, y: 100 });

    loadOpts();

    setTimeout(() => {
        if (route.params.zoneId !== undefined) {
            selectZone(zoneById(route.params.zoneId));
        } else if (route.params.roomId !== undefined) {
            selectRoomByVnum(route.params.roomId);
            gotoVnum();
        } else {
            selectZone(zoneById(2)); // Grimhaven
        }
    }, 1000);

    loadClicks(svgElement);
});

const zoneById = (id) => {
    return zonesData.range.find((zone) => zone.zonenr === parseInt(id));
};

const roomByVnum = (vnum) => {
    return roomsData.find((room) => room.vnum === parseInt(vnum));
};

const selectRoomByVnum = (room_vnum) => {
    let selected = document.getElementsByClassName("selected");
    if (selected.length > 0) {
        selected[0].classList.remove("selected");
        vnum.value = null;
        selectedRoom.value = null;
    }
    let target = document.getElementsByClassName(`rm vn${room_vnum}`);
    if (target.length > 0) {
        target[0].classList.add("selected");
        vnum.value = room_vnum;
        selectedRoom.value = roomsRaw[room_vnum];
    }
};

const loadClicks = (svgElement) => {
    svgElement.addEventListener("click", (e) => {
        let selected = document.getElementsByClassName("selected");
        if (selected.length > 0) {
            selected[0].classList.remove("selected");
            vnum.value = null;
            selectedRoom.value = null;
        }
        if (e.target.classList.contains("rm")) {
            // console.log("click", e.target);
            vnum.value = e.target.id;
            selectedRoom.value = roomsRaw[e.target.id];
            e.target.classList.add("selected");
        }
    });
};

const selectZone = (zone) => {
    console.log("selectZone", zone);
    zonesData.current = zone.zonenr;
    zLevelsData.current = null;
    updateLayers();
    zoomToZone(zone);
};

const selectRoom = (room) => {
    //console.log("selectZone", zone.name, zone.zonenr);
    //selectedRoom.value = roomsRaw[room.vnum].name.replace(/<.>/gm, "");
    vnum.value = room.vnum;
    gotoVnum();
};

const zoomToZone = (zone = zonesData.range[0]) => {
    //console.log("zoomToZone", zone.name, zone.zonenr);
    if (zone !== undefined) {
        selectedZone.value = zone;
    }

    const targetElement = document.getElementsByClassName(`zb zn${zone.zonenr}`);
    panToElem(targetElement[0]);
};

const gotoVnum = () => {
    //console.log("gotoVnum", vnum.value);
    const targetElement = document.getElementsByClassName(`vn${vnum.value}`);
    selectRoomByVnum(vnum.value);

    zLevelsData.current = null;
    zonesData.current = null;
    updateLayers();
    panToElem(targetElement[0]);
};

const updateLayers = () => {
    // console.log(
    //     "updateLayers",
    //     zLevelsData.current,
    //     zonesData.current,
    //     autohide.value,
    //     telelinks.value
    // );

    if (telelinks.value) {
        let teles = document.getElementsByClassName("tp");
        for (const tele of teles) {
            tele.classList.remove("hidden");
        }
        let ports = document.getElementsByClassName("pp");
        for (const port of ports) {
            port.classList.remove("hidden");
        }
    }

    let mapgroups = document.getElementsByClassName("mg");
    for (const mapgroup of mapgroups) {
        let mgzone = mapgroup.classList[1].slice(2);
        let mgzlevel = mapgroup.classList[2].slice(2);
        if (
            (parseInt(mgzone) == zonesData.current || zonesData.current === null || autohide.value == false) &&
            (parseInt(mgzlevel) == zLevelsData.current || zLevelsData.current === null)
        ) {
            mapgroup.classList.remove("hidden");
        } else {
            mapgroup.classList.add("hidden");
        }
        //console.log(mapgroup.classList);
    }
    if (!telelinks.value) {
        let teles = document.getElementsByClassName("tp");
        for (const tele of teles) {
            tele.classList.add("hidden");
        }
        let ports = document.getElementsByClassName("pp");
        for (const port of ports) {
            port.classList.add("hidden");
        }
    }
};

const zLevelUp = () => {
    let old = zLevelsData.current;
    if (zLevelsData.current === null) {
        zLevelsData.current = 0;
    } else if (zLevelsData.range.includes(old + 1)) {
        zLevelsData.current = old + 1;
    } else {
        return;
    }
    updateLayers();
};

const zLevelDown = () => {
    let old = zLevelsData.current;
    if (zLevelsData.current === null) {
        zLevelsData.current = 0;
    } else if (zLevelsData.range.includes(old - 1)) {
        zLevelsData.current = old - 1;
    } else {
        return;
    }
    updateLayers();
};

const zLevelReset = () => {
    zLevelsData.current = null;
    updateLayers();
};

const zoneReset = () => {
    zonesData.current = null;
    updateLayers();
};

function loadOpts() {
    let zlevelset = new Set();

    for (const room in roomsRaw) {
        let roomData = roomsRaw[room];
        roomData.vnum = room;
        roomsData.push(roomData);
    }

    let zones = [];
    let zmin = 0;
    let zmax = 0;
    for (const zn in zonesRaw) {
        let zone = zonesRaw[zn];
        if (zone.zmin < zmin) zmin = zone.zmin;
        if (zone.zmax > zmax) zmax = zone.zmax;
        zone.zonenr = parseInt(zn);
        zones.push(zone);
    }

    for (let i = zmin; i <= zmax; i++) {
        zlevelset.add(i);
    }

    let zlevels = [...zlevelset].sort((a, b) => a - b).reverse();

    zLevelsData.range = zlevels;
    zonesData.range = zones;
    console.log("loadOpts", zLevelsData.range, zonesData.range);
}

function customPanByZoomAtEnd(amount, endZoomLevel, animationTime) {
    // {x: 1, y: 2}
    if (typeof animationTime == "undefined") {
        animationTime = 300; // ms
    }
    var viewPort = $(".svg-pan-zoom_viewport")[0];
    //viewPort.style.transition = "all " + animationTime / 1000 + "s ease";
    //panZoomMap.zoom(3);
    viewPort.style.transition = "none";
    var animationStepTime = 15, // one frame per 30 ms
        animationSteps = animationTime / animationStepTime,
        animationStep = 0,
        intervalID = null,
        stepX = amount.x / animationSteps,
        stepY = amount.y / animationSteps;

    // intervalID = setInterval(function () {
    //     if (animationStep++ < animationSteps) {
    //         panZoomMap.panBy({ x: stepX, y: stepY });
    //     } else {
    //         // Cancel interval
    //         if (typeof endZoomLevel != "undefined") {
    //             viewPort.style.transition = "all " + animationTime / 1000 + "s ease";
    //             panZoomMap.zoom(endZoomLevel);
    //             setTimeout(function () {
    //                 viewPort.style.transition = "none";
    //                 $("svg")[0].style.pointerEvents = "all"; // re-enable the pointer events after auto-panning/zooming.
    //                 panZoomMap.enablePan();
    //                 panZoomMap.enableZoom();
    //                 panZoomMap.enableControlIcons();
    //                 panZoomMap.enableDblClickZoom();
    //                 panZoomMap.enableMouseWheelZoom();
    //             }, animationTime + 50);
    //         }
    //         clearInterval(intervalID);
    //     }
    // }, animationStepTime);

    viewPort.style.transition = "all " + animationTime / 1000 + "s ease-in-out";
    panZoomMap.panBy({ x: amount.x, y: amount.y });
    setTimeout(() => {
        viewPort.style.transition = "all " + animationTime / 1000 + "s ease";
        panZoomMap.zoom(endZoomLevel);
        setTimeout(() => {
            viewPort.style.transition = "none";
            $("svg")[0].style.pointerEvents = "all"; // re-enable the pointer events after auto-panning/zooming.
            panZoomMap.enablePan();
            panZoomMap.enableZoom();
            panZoomMap.enableControlIcons();
            panZoomMap.enableDblClickZoom();
            panZoomMap.enableMouseWheelZoom();
        }, animationTime + 50);
    }, animationTime);
}

function panToElem(targetElem) {
    let animationTime = 700;
    // var viewPort = $(".svg-pan-zoom_viewport")[0];
    // viewPort.style.transition = "all " + animationTime / 1000 + "s ease";
    // panZoomMap.zoom(4);
    // setTimeout(() => {
    var initialSizes = panZoomMap.getSizes();
    var initialLoc = panZoomMap.getPan();
    var initialBounds = targetElem.getBoundingClientRect();
    var viewBox = panZoomMap.getSizes().viewBox;
    var boundingBox = targetElem.getBBox();
    var initialZoom = panZoomMap.getZoom();
    var initialCX = initialBounds.x + initialBounds.width / 2;
    var initialCY = initialBounds.y + initialBounds.height / 2;
    var zoom = Math.min(viewBox.width / boundingBox.width, viewBox.height / boundingBox.height);

    var dX = initialSizes.width / 2 - initialCX;
    var dY = initialSizes.height / 2 - initialCY;

    customPanByZoomAtEnd({ x: dX, y: dY }, zoom, animationTime);
    // }, 1000);
}

const copyRoom = () => {
    let room = selectedRoom.value;
    if (room !== null) {
        let url = `/sneezy/webmap/#/room/${room.vnum}`;
        let fullUrl = window.location.origin + url;
        navigator.clipboard.writeText(fullUrl);
    }
};

const copyZone = () => {
    let zone = selectedZone.value;
    if (zone !== null) {
        let url = `/sneezy/webmap/#/zone/${zone.zonenr}`;
        let fullUrl = window.location.origin + url;
        navigator.clipboard.writeText(fullUrl);
    }
};
</script>

<template>
    <MapSVG
        id="map"
        class="absolute top-0 bottom-0 left-0 w-full h-full bg-parchment" />
    <div
        class="absolute px-2 py-0 border rounded-lg right-2 bottom-2 text-neutral-800 bg-neutral-300 border-neutral-700">
        <div>
            <h5
                class="relative w-full text-lg font-extrabold text-center uppercase rounded-md text-neutral-800 min-w-64">
                Controls
            </h5>
            <div
                @click="controlsHidden = !controlsHidden"
                class="absolute right-1 top-0.5 text-neutral-800 hover:text-purple-700">
                <i
                    v-if="!controlsHidden"
                    class="pi pi-window-minimize"></i>
                <i
                    v-if="controlsHidden"
                    class="pi pi-window-maximize"></i>
            </div>
        </div>
        <div
            v-if="!controlsHidden"
            class="flex flex-col items-start justify-start pb-1">
            <h5 class="w-full font-extrabold text-center text-purple-800 uppercase rounded-md">Rooms</h5>
            <div class="flex flex-row content-center w-full justify-stretch">
                <input
                    @keyup.enter="gotoVnum()"
                    type="number"
                    name="vnum"
                    v-model="vnum"
                    class="w-20 p-0 px-2 mb-1 mr-1 text-center border rounded-md border-neutral-500 bg-neutral-100 focus:outline-none" />
                <button
                    @click="gotoVnum()"
                    class="rounded-md bg-purple-800 text-neutral-100 flex-1 w-full px-2 hover:bg-purple-700 active:bg-purple-900 py-0.5 text-sm mb-1">
                    Go to VNUM
                </button>
            </div>

            <div class="relative w-full m-0">
                <div class="relative flex flex-row w-full justify-stretch">
                    <BaseSearchAndSelect
                        name="room"
                        prefix="rooms"
                        @select="
                            (r) => {
                                vnum = r;
                                gotoVnum();
                            }
                        "
                        :opts="
                            roomsData.map((room) => ({
                                label: '[' + room.vnum + '] ' + room.name.replace(/<.>/gm, ''),
                                value: room.vnum,
                            }))
                        " />

                    <button
                        @click="copyRoom()"
                        class="flex-shrink rounded-md bg-purple-800 text-neutral-100 ml-1 px-2 hover:bg-purple-700 active:bg-purple-900 py-0.5 mb-1">
                        <i class="pi pi-copy"></i>
                    </button>
                </div>
            </div>

            <h5 class="w-full font-extrabold text-center text-purple-800 uppercase rounded-md">z-Levels</h5>
            <button
                @click="zLevelReset()"
                class="rounded-md bg-purple-800 text-neutral-100 w-full px-2 hover:bg-purple-700 active:bg-purple-900 py-0.5 mb-1">
                All z-Levels
            </button>
            <div class="flex flex-row content-center w-full justify-stretch">
                <button
                    @click="zLevelUp"
                    class="w-1/6 rounded-md bg-purple-800 text-neutral-100 px-2 hover:bg-purple-700 active:bg-purple-900 py-0.5 text-sm">
                    <i class="pi pi-plus"></i>
                </button>
                <select
                    v-model="zLevelsData.current"
                    @change="updateLayers()"
                    class="flex-grow border mx-1 border-neutral-500 bg-neutral-100 rounded-md px-2 py-0.5 flex justify-between items-center text-center cursor-pointer">
                    <option :value="null">All</option>
                    <option
                        v-for="zlevel in zLevelsData.range"
                        :value="zlevel">
                        {{ zlevel }}
                    </option>
                </select>
                <button
                    @click="zLevelDown"
                    class="w-1/6 rounded-md bg-purple-800 text-neutral-100 px-2 hover:bg-purple-700 active:bg-purple-900 py-0.5 text-sm">
                    <i class="pi pi-minus"></i>
                </button>
            </div>
            <h5 class="w-full font-extrabold text-center text-purple-800 uppercase rounded-md">Zones</h5>
            <button
                @click="zoneReset()"
                class="rounded-md bg-purple-800 text-neutral-100 w-full px-2 hover:bg-purple-700 active:bg-purple-900 py-0.5 mb-1">
                All Zones
            </button>
            <div class="relative flex flex-row w-full m-0">
                <BaseSearchAndSelect
                    name="zone"
                    prefix="zones"
                    @select="(z) => selectZone(zoneById(z))"
                    :opts="zonesData.range.map((zone) => ({ label: zone.name, value: zone.zonenr }))" />

                <button
                    @click="copyZone()"
                    class="flex-shrink rounded-md bg-purple-800 text-neutral-100 ml-1 px-2 hover:bg-purple-700 active:bg-purple-900 py-0.5 mb-1">
                    <i class="pi pi-copy"></i>
                </button>
            </div>
            <h5 class="w-full font-extrabold text-center text-purple-800 uppercase rounded-md">Other Settings</h5>
            <label
                class="text-neutral-800"
                for="autohide">
                <input
                    class="accent-purple-800"
                    type="checkbox"
                    id="autohide"
                    v-model="autohide" />
                Auto-hide other Zones</label
            >
            <label
                class="text-neutral-800"
                for="telelinks">
                <input
                    class="accent-purple-800"
                    type="checkbox"
                    id="telelinks"
                    v-model="telelinks" />
                Show Portal/Teleport Links</label
            >
        </div>
    </div>
    <RoomDetails :room="vnum" />
</template>

<style scoped></style>
