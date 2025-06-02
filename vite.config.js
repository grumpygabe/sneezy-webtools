import { fileURLToPath, URL } from "node:url";
import svgLoader from "vite-svg-loader";
import { defineConfig } from "vite";
import vue from "@vitejs/plugin-vue";

// https://vitejs.dev/config/
export default defineConfig({
    plugins: [vue(), svgLoader()],
    base: "/",
    resolve: {
        alias: {
            "@": fileURLToPath(new URL("./src", import.meta.url)),
        },
    },
    build: {
        rollupOptions: {
          output: {
            manualChunks: {
              'map-assets': ['./src/assets/optimized-map.svg'],
              'zone-data': ['./src/assets/zones.json'],
              'room-data': ['./src/assets/rooms.json']
            }
          }
        }
    }
});

