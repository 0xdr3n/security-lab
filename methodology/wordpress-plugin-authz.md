# Hunting missing authorization in WordPress plugins

WordPress core is well hardened. Plugins usually aren't: many are written by small teams
with no security review, and every AJAX or REST handler is a public entry point that has to
do its own checks. Missing checks here are the most common plugin vulnerability class.

## Where the entry points are

| Registration | Who can call it |
|---|---|
| `add_action('wp_ajax_nopriv_<x>', ...)` | **Anyone**, logged out |
| `add_action('wp_ajax_<x>', ...)` | **Any logged-in user**, including Subscriber |
| `register_rest_route(..., ['permission_callback' => '__return_true'])` | **Anyone** |
| `register_rest_route(...)` with a real `permission_callback` | Whatever that callback allows |
| `admin_init` / `admin_post_*` hooks | Any logged-in user (`admin_init` also fires on `admin-ajax.php`) |

Key point: `wp_ajax_` does **not** mean admin-only. A Subscriber can call every one of them.

## The three checks a sensitive handler needs

1. **Nonce:** `check_ajax_referer()` / `wp_verify_nonce()`. This protects against CSRF only.
   It is **not** authorization: if the nonce is printed on a public page or to every logged-in
   user, anyone can get it.
2. **Capability:** `current_user_can('<cap>')`, appropriate for the action.
3. **Ownership:** for an object loaded by ID (post, listing, attachment, order), does the
   current user actually own it or have rights over *that specific object*?

A handler can pass 1 and 2 and still fail 3. That's an IDOR.

## Process

1. **Pick targets.** Plugins with roughly 1k–50k installs, active development, and features
   that touch other users' data (bookings, CRMs, forms, LMS, membership, quizzes).
2. **List the surface.** Run [`tools/wp-surface.sh`](../tools/wp-surface.sh) on the source.
3. **Triage by impact.** Look first at handlers that delete, upload, update, or return personal data.
4. **Read each handler fully.** Follow every ID that comes from the request: where is it
   validated, and against whom?
5. **Check the right baseline.** If an unauthenticated read looks like a leak, check whether
   the plugin's *designed* public read paths expose the same data. If they do, it's
   intended behaviour, not a bug.
6. **Reproduce in the lab** as the lowest role that should be able to reach it, with a second
   user as the victim. Run a **negative control**: show that core WordPress blocks the same
   action through its own API (for example, a Subscriber editing another user's post through `/wp/v2/posts/<id>` gets 403).
7. **Check prior art.** Search WPScan, Patchstack, Wordfence and the CVE database for the
   plugin before writing anything up.
8. **Check the disclosure program's current scope** for that bug class *before* investing time.
   Rules change, and some classes only count for certain plugins.

## Patterns worth grepping for

```bash
rg -n "wp_ajax_nopriv_|permission_callback\s*=>\s*'__return_true'" src/
rg -n "\\\$_(POST|GET|REQUEST)\[['\"][a-z_]*id" src/          # IDs taken straight from the request
rg -n "wp_delete_(post|attachment)|wp_update_post|update_post_meta|unlink\(" src/
rg -n "check_ajax_referer|wp_verify_nonce|current_user_can" src/
```

A delete, update or meta write that is reachable from a request ID and has no nearby
`current_user_can` or ownership check is the first place to read.
