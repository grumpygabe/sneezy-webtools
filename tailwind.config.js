/** @type {import('tailwindcss').Config} */
export default {
  content: [],
  theme: {
    extend: {},
  },
  plugins: [],
}

/** @type {import('tailwindcss').Config} */
export default {
  content: ["./index.html", "./src/**/*.{vue,js,ts,jsx,tsx}"],
  theme: {
      extend: {
        colors: {
          'parchment': 'tan',
        }
      },
      fontFamily: {
        default: ["Roboto Condensed", "sans-serif"],
      },

      screens: {
          tablet: "768px",
          desktop: "1280px",
      },
  },
  plugins: [],
};
