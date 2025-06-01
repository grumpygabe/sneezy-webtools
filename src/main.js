import "./assets/main.css";
import "primeicons/primeicons.css";

import { createApp } from "vue";
import App from "./App.vue";
import router from "./router";

// import panZoom from "vue-panzoom";

const app = createApp(App);
// app.use(panZoom);
app.use(router);

app.mount("#app");
