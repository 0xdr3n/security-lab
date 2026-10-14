# Vikunja 2.7.0: zip-slip in import, and a sweep of the permission layer

**Target:** Vikunja `2.7.0` (self-hosted, Docker, my own lab) plus the source from `main`
**Result:** no exploitable vulnerability found.

## 1. Zip-slip in the Vikunja export/import

Vikunja can import its own export archive, which contains `data.json`, `filters.json`,
`VERSION` and a `files/` directory of attachments. Archive parsing is a classic place for
path traversal.

**Test:** I made a valid export, then edited the attachment metadata so a file name contained
traversal sequences (`../../...`), re-zipped it and imported it.

**Result:** the import stores attachments under the files base path with **numeric IDs the
server assigns**. The file name from the archive is never used as a write path. I confirmed
this with `docker diff` on the container: nothing was written outside the files directory. **No traversal.**

## 2. Sub-resource IDOR sweep (source review)

A common IDOR pattern: the permission check verifies access to the *parent* object in the URL,
but the handler loads the *child* object by its own ID without confirming it belongs to that parent.

I read every `pkg/models/*_permissions.go` file and checked each child type:

| Resource | How it's protected |
|---|---|
| Task attachments, comments | query scoped with `AND task_id = ?` |
| Project views | loaded by view ID **and** project ID |
| Reactions | permission derived from the actual target entity |
| Webhooks | reloaded from DB; uses the stored project ID, not the request's |
| Task relations | requires read access on **both** tasks |
| API tokens | scoped to the owner |

The whole class is covered. I also checked two recently published advisories; both are
fixed in 2.7.0, and I found no unpatched sibling.

## 3. Other dynamic tests

- Direct cross-user project access → 403
- Read-only link share trying to write/delete, plus 8 sub-resource writes → all 403
- Webhook SSRF → accepted at creation, **blocked at delivery** (loopback, link-local, private and IPv6 deny-list)

## Takeaways

- One small inconsistency turned up in the source: two branches of one permission check
  required different access levels. No route actually reaches the weaker branch, though, so it
  isn't exploitable and I didn't report it. An inconsistency in the code is only a
  vulnerability if an attacker can reach it.
- Reproduce, then check prior art. One behaviour I reproduced turned out to be an existing
  public advisory, so it was a duplicate, not a new finding.
