# Storefront — sample Blokkli theme

A minimal, runnable **Blokkli theme** for the revenexx platform. It exercises
the contract introduced in **ADR-0061 — Sites and Blokkli Themes as Shareable
Registry Resources**, the same way `sample-app/` exercises the App manifest
contract.

It is a **real Nuxt SSR site** (so it can be deployed as an Appwrite Site and be
reachable) plus the registry **manifest pair** (`theme.json` + `billing.json`).
The Nuxt app is intentionally minimal — it server-renders the request host and
the injected tenant context to prove reachability and the ADR-0057 §8 host→
tenant routing. Wiring an actual Blokkli editor + adapter onto it is done
elsewhere; our interface ends where the Cockpit reads the `kind`/`engine` marker.

## Run / deploy

```bash
npm install
npm run build          # → .output (Nitro node-server)
npm run preview        # serve locally

# Deploy to the platform as an Appwrite Site (manual code upload):
ENDPOINT=https://app.revenexx.com/v1 PROJECT=<projectId> API_KEY=<sites.write key> \
  TENANT=revenexx ./deploy.sh
```

The platform builds the uploaded source (`npm install` + `npm run build`,
Nuxt SSR adapter → `.output`) and auto-creates a preview domain
`{id}.sites.revenexx.com` for the deployment — that is the reachable URL.

## What it demonstrates

| Concept (ADR-0061) | Where in `theme.json` |
|---|---|
| **The Cockpit marker** — "this is a Blokkli theme" | `kind: "theme"` + `engine: "blokkli"` |
| **Shared registry, App semantics** | `type: "public"`, `name`, `vendor`, `version` — registered, published, installed, consented exactly like an App |
| **Frontend routed by DOMAIN, not the gateway** | `site` block (`framework: nuxt`, `adapter: ssr`, `domains: ["{{tenant_domain}}"]`) — served on the public Sites entrypoint, tenant resolved from the request Host (ADR-0057 §8) |
| **`requires` — hard install dependency + auto-suggest** | `requires: [{ capability: "products.list" }]` — Console blocks the install on any tenant without that capability routed, and suggests the App(s) that provide it |
| **The access register** (consented at install) | `permissions` — same discriminated shape as an App (ADR-0058 §2) |
| **The Blokkli payload** (opaque to the platform) | `blokkli.blocks` / `blokkli.presets` |
| **Billing, reused unchanged** | `billing.json` — pricing only, resource-agnostic |

## Two traffic classes (the routing split)

A theme has two kinds of traffic that take **two different paths** — this is the
load-bearing constraint of ADR-0061:

- **Frontend** (HTML / SSR / assets) → the theme's **own domain** on the
  **public** Sites entrypoint. **Never the gateway.**
- **Adapter** (Blokkli edits, product reads, capability calls) → the **API
  gateway** via the SDK, carrying the per-tenant brokered JWT (ADR-0054/0056).

The SSR runtime receives the same per-invocation tenant context as any Site
(ADR-0057 §8), so server-side data fetches are tenant-correct without the
frontend itself being a gateway route.

## The install gate ("Hart + Auto-Vorschlag")

This theme `requires` `products.list`. On install, Console checks the tenant's
active capability routing:

- **Routed** → install proceeds.
- **Not routed** → install is **blocked** with `AppRequiresUnmetException`,
  which carries the installable App(s) that implement `products.list` (e.g. the
  `products` app). The Cockpit renders these as "install Products to enable this
  theme" — a marketplace cross-sell rather than a dead end.

## Files

- `theme.json` — the theme manifest (validated against `theme.schema.json`).
- `billing.json` — pricing (validated against `billing.schema.json`).
- `README.md` — this file.
