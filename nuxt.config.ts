// Minimal Nuxt SSR config for the sample Blokkli theme (ADR-0061).
// Deployed as an Appwrite Site with adapter "ssr": the platform builds with
// `npm run build` and serves the Nitro node-server output from `.output`.
export default defineNuxtConfig({
  compatibilityDate: '2025-01-01',
  ssr: true,
  nitro: {
    // node-server is the default preset; the Appwrite Sites nuxt/server.sh
    // helper runs `.output/server/index.mjs`.
    preset: 'node-server',
  },
  devtools: { enabled: false },
})
