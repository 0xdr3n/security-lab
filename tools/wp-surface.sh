#!/usr/bin/env bash
# wp-surface.sh - list a WordPress plugin's request entry points for manual review.
#
# Usage: ./wp-surface.sh <plugin-source-dir>
#
# Prints:
#   1. unauthenticated AJAX actions   (wp_ajax_nopriv_*)
#   2. logged-in AJAX actions         (wp_ajax_*  - reachable by Subscriber)
#   3. REST routes and their permission_callback
#   4. which files call nonce / capability checks at all
# Vendored libraries (vendor/, node_modules/) are skipped.

set -euo pipefail

dir="${1:?usage: $0 <plugin-source-dir>}"
excl=(--exclude-dir=vendor --exclude-dir=node_modules --exclude-dir=.git)

section() { printf '\n=== %s ===\n' "$1"; }

section "Unauthenticated AJAX (wp_ajax_nopriv_)"
grep -rnoE "${excl[@]}" --include='*.php' \
  "wp_ajax_nopriv_[A-Za-z0-9_\-]+" "$dir" | sort -u || echo "(none)"

section "Logged-in AJAX (wp_ajax_) - any role incl. Subscriber"
grep -rnoE "${excl[@]}" --include='*.php' \
  "['\"]wp_ajax_[A-Za-z0-9_\-]+" "$dir" | grep -v nopriv | sort -u || echo "(none)"

section "REST routes"
grep -rnE "${excl[@]}" --include='*.php' "register_rest_route" "$dir" || echo "(none)"

section "REST permission_callback => __return_true (public)"
grep -rnE "${excl[@]}" --include='*.php' \
  "permission_callback['\"]?\s*=>\s*['\"]__return_true" "$dir" || echo "(none)"

section "admin_post_ / admin_init hooks"
grep -rnoE "${excl[@]}" --include='*.php' \
  "admin_post_(nopriv_)?[A-Za-z0-9_\-]+|['\"]admin_init['\"]" "$dir" | sort -u || echo "(none)"

section "Files with nonce checks"
grep -rlE "${excl[@]}" --include='*.php' \
  "check_ajax_referer|wp_verify_nonce|check_admin_referer" "$dir" | sort || echo "(none)"

section "Files with capability checks"
grep -rlE "${excl[@]}" --include='*.php' "current_user_can" "$dir" | sort || echo "(none)"
