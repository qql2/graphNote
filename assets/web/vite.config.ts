import { defineConfig } from "vite";

export default defineConfig({
  build: {
    lib: {
      entry: "x6_graph.ts",
      name: "x6Graph",
      formats: ["iife"],
      fileName: "x6_graph",
    },
    rollupOptions: {
      output: {
        globals: {
          "@antv/x6": "X6",
        },
      },
    },
  },
  define: {
    "process.env.NODE_ENV": '"production"',
    "process.env.DEBUG": "false",
    global: "window",
  },
});
