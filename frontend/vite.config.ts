import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import path from 'path';

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
  server: {
    port: 5173,
    host: true,
    open: true,
    proxy: {
      '/v1': {
        target: process.env.API_PORT ? `http://localhost:${process.env.API_PORT}` : 'http://localhost:8000',
        changeOrigin: true,
      },
    },
  },
});
