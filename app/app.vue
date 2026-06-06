<script setup lang="ts">
// SSR proof for the sample Blokkli theme (ADR-0061).
//
// The platform injects per-invocation context as request headers (ADR-0057):
//   - the tenant is resolved from the request Host on the public Sites
//     entrypoint (§8) — this frontend is served by DOMAIN, never the gateway;
//   - x-revenexx-context carries the brokered per-tenant JWT that the Blokkli
//     adapter / SDK would present to the API gateway for data + capability calls.
// Here we just render them server-side to prove the theme is reachable and the
// context arrives.
const headers = useRequestHeaders(['host', 'x-revenexx-tenant', 'x-revenexx-context'])
const host = headers['host'] || 'unknown'
const tenant = headers['x-revenexx-tenant'] || '(resolved by host)'
const hasContext = Boolean(headers['x-revenexx-context'])
</script>

<template>
  <main class="page">
    <section class="card">
      <p class="eyebrow">revenexx · Blokkli theme</p>
      <h1>Storefront</h1>
      <p class="lead">This sample theme is live and server-rendered.</p>

      <dl class="ctx">
        <dt>Host</dt>
        <dd>{{ host }}</dd>
        <dt>Tenant</dt>
        <dd>{{ tenant }}</dd>
        <dt>Brokered context</dt>
        <dd>{{ hasContext ? 'present' : 'none (preview domain)' }}</dd>
      </dl>

      <p class="foot">
        Rendered by Nuxt SSR · routed by domain on the public Sites entrypoint
        (ADR-0057 §8) · adapter traffic goes through the API gateway (ADR-0061).
      </p>
    </section>
  </main>
</template>

<style>
:root { color-scheme: light dark; }
* { box-sizing: border-box; }
body { margin: 0; font-family: ui-sans-serif, system-ui, -apple-system, "Segoe UI", Roboto, sans-serif; }
.page {
  min-height: 100vh;
  display: grid;
  place-items: center;
  padding: 2rem;
  background: radial-gradient(120% 120% at 0% 0%, #1d1147 0%, #0b0b16 55%, #05050a 100%);
  color: #f4f4fb;
}
.card {
  width: min(640px, 100%);
  padding: 2.5rem;
  border-radius: 20px;
  background: rgba(255,255,255,0.04);
  border: 1px solid rgba(255,255,255,0.10);
  backdrop-filter: blur(10px);
  box-shadow: 0 20px 60px rgba(0,0,0,0.45);
}
.eyebrow { margin: 0 0 .5rem; font-size: .8rem; letter-spacing: .12em; text-transform: uppercase; color: #b9a9ff; }
h1 { margin: 0 0 .25rem; font-size: 2.5rem; }
.lead { margin: 0 0 1.75rem; color: #c9c9da; }
.ctx { display: grid; grid-template-columns: max-content 1fr; gap: .5rem 1.25rem; margin: 0 0 1.75rem; }
.ctx dt { color: #9a9ab2; }
.ctx dd { margin: 0; font-variant-numeric: tabular-nums; word-break: break-all; }
.foot { margin: 0; font-size: .8rem; line-height: 1.5; color: #7e7e98; }
</style>
