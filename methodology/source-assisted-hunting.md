# Source-assisted vulnerability hunting

Running a scanner against a popular app rarely finds anything new, because thousands of
people have already done it. What works better is **reading the source of features that are
both historically buggy and recently changed**. New code has had the least testing.

## Hunt new and changed code

1. Read the vendor's recent security release notes. Each one names a vulnerability
   *class* and a feature area.
2. List the features added in the last two or three releases: new API endpoints, GraphQL fields,
   integrations.
3. Diff the source between recent tags and skim for new routes, resolvers and policy changes.

## Variant analysis

When a fix ships, it shows you exactly which mistake the developers made. Reproduce the
patched bug on the old version, then look for **sibling code paths with the same root cause**
that the patch didn't touch. One missing check often means there are others.

## Classes I focus on

- **Broken access control / IDOR:** a permission check missing on one route, or a check
  against the parent object while the code acts on a child loaded by ID.
- **SSRF:** webhooks, integrations, import-by-URL, mirroring. Test both when the URL is
  saved and when the request is actually made; filters often run only at save time.
- **Import/export parsing:** archives from users. Look for path traversal (zip-slip),
  XXE and unsafe deserialization.
- **CI/CD boundaries:** job tokens, cross-project triggers, runner scope.
- **Stored XSS:** markdown, filenames, rendered diagrams.

## Per-area method

1. Pick **one** area.
2. Map every endpoint or mutation in it.
3. Read the authorization code for each one.
4. Use two accounts, attacker and victim, and try to make the attacker act on the victim's
   objects.
5. Confirm real impact: cross-user data access or action, reproducible on the current
   release, with a minimal PoC.
6. Look for variants of anything you find.

## Definition of done for a report

- Reproduces on the current stable release in a clean environment
- Clear impact: who can do what to whom
- Minimal step-by-step PoC with request/response evidence and a negative control
- Root cause identified in the source
