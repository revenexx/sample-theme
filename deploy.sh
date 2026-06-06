#!/usr/bin/env bash
#
# Deploy this sample Blokkli theme to the revenexx platform as an Appwrite Site
# via the manual code-upload endpoints (ADR-0061). Builds happen on the
# platform; we upload a source tarball and let the Sites build worker run
# `npm install` + `npm run build` (Nuxt SSR → .output).
#
# This fork resolves the project from `?project=` or the X-Revenexx-Tenant
# header (app/init/resources.php: getParam('project', getHeader('x-revenexx-tenant'))).
# There is NO X-Revenexx-Project header — the tenant value IS the project id.
#
# Required env:
#   ENDPOINT   platform API base, e.g. https://app.revenexx.com/v1
#   TENANT     X-Revenexx-Tenant — resolves the project (e.g. "revenexx")
#   API_KEY    API key with sites.write + deployments.write (X-Revenexx-Key)
# Optional env:
#   SITE_ID    reuse an existing site id (default: create a new one)
#   SITE_NAME  display name (default: "Sample Storefront Theme")
#
# Usage:  ENDPOINT=... TENANT=revenexx API_KEY=... ./deploy.sh
set -euo pipefail

: "${ENDPOINT:?set ENDPOINT, e.g. https://app.revenexx.com/v1}"
: "${TENANT:?set TENANT (X-Revenexx-Tenant, resolves the project, e.g. revenexx)}"
: "${API_KEY:?set API_KEY (sites.write key)}"
SITE_ID="${SITE_ID:-}"
SITE_NAME="${SITE_NAME:-Sample Storefront Theme}"

here="$(cd "$(dirname "$0")" && pwd)"
hdr=(-H "X-Revenexx-Tenant: ${TENANT}" -H "X-Revenexx-Key: ${API_KEY}")

say() { printf '\n\033[1;35m== %s\033[0m\n' "$*"; }

# 1) Create the Site (skip if SITE_ID provided) ------------------------------
if [ -z "$SITE_ID" ]; then
  say "Creating Site"
  resp="$(curl -sS -X POST "${ENDPOINT}/sites" "${hdr[@]}" \
    -H 'Content-Type: application/json' \
    -d "$(cat <<JSON
{
  "siteId": "unique()",
  "name": "${SITE_NAME}",
  "framework": "nuxt",
  "adapter": "ssr",
  "buildRuntime": "node-22",
  "installCommand": "npm install",
  "buildCommand": "npm run build",
  "outputDirectory": "./.output"
}
JSON
)")"
  echo "$resp"
  SITE_ID="$(echo "$resp" | sed -n 's/.*"\$id":"\([^"]*\)".*/\1/p' | head -1)"
  [ -n "$SITE_ID" ] || { echo "Failed to parse site id from response" >&2; exit 1; }
fi
say "Site id: ${SITE_ID}"

# 2) Build the source tarball (code only — platform installs + builds) -------
say "Packing source tarball"
tarball="$(mktemp -t sample-theme-XXXX).tar.gz"
tar --exclude='./node_modules' --exclude='./.output' --exclude='./.nuxt' \
    --exclude='./.git' --exclude='./.data' --exclude='*.tar.gz' \
    -czf "$tarball" -C "$here" .
ls -la "$tarball"

# 3) Upload the deployment (single request; <5MB source) + activate ----------
say "Uploading deployment (activate=true)"
dep="$(curl -sS -X POST "${ENDPOINT}/sites/${SITE_ID}/deployments" "${hdr[@]}" \
  -F "code=@${tarball};type=application/gzip" \
  -F "activate=true")"
echo "$dep"
DEP_ID="$(echo "$dep" | sed -n 's/.*"\$id":"\([^"]*\)".*/\1/p' | head -1)"
[ -n "$DEP_ID" ] || { echo "Failed to parse deployment id" >&2; exit 1; }
say "Deployment id: ${DEP_ID}"

# 4) Poll build status -------------------------------------------------------
say "Polling build status"
for i in $(seq 1 120); do
  d="$(curl -sS "${ENDPOINT}/sites/${SITE_ID}/deployments/${DEP_ID}" "${hdr[@]}")"
  status="$(echo "$d" | sed -n 's/.*"status":"\([^"]*\)".*/\1/p' | head -1)"
  printf '  [%3ds] status=%s\n' "$((i*5))" "$status"
  case "$status" in
    ready)  say "BUILD READY"; break ;;
    failed) say "BUILD FAILED — logs:"; echo "$d" | sed -n 's/.*"buildLogs":"\(.*\)","build.*/\1/p' | head -c 4000; exit 1 ;;
  esac
  sleep 5
done

# 5) Show the preview domain (auto-created rule {id}.sites.revenexx.com) ------
say "Done. Site id ${SITE_ID}, deployment ${DEP_ID}."
echo "Preview domain is the auto-created rule for this deployment (see Console / rules)."
rm -f "$tarball"
