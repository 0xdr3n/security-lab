# GitLab CE 19.4.2: cross-user access control, CI job tokens, webhook SSRF

**Target:** self-managed GitLab CE `19.4.2-ce.0` (Docker, my own lab)
**Result:** no vulnerability found. Every control I tested held.
**Why publish it:** these are negative results, but they show what I tested and how.

## Background

GitLab 19.4.2 was a security release that fixed *improper authorization in downstream
pipeline creation*. My aim was variant analysis: look for other ways to create or trigger
pipelines, or read CI data, in a project the attacker has no access to.

## Setup

- `attacker` owns a private project `attacker-proj`
- `victim` owns a private project `victim-secret` with CI variables, pipelines and files
- A docker-executor runner registered at instance level, so real jobs could run
- First check: attacker cannot see victim's project at all ✔

## Tests

### REST API, attacker → victim project

Projects, pipelines, CI variables, jobs, triggers, pipeline schedules, members, repository
files, container registry, job-token scope: **all returned 404**. That's the correct
behaviour, because GitLab doesn't confirm the project exists to someone without access.

### GraphQL

Querying the victim project, its nested CI variables, pipelines and repository returned
`null` (denied) every time.

### Cross-project CI `include:`

A pipeline config in the attacker's project with `include: project: victim/victim-secret`,
checked through the CI lint API, returned *"Project not found or access denied"*. A canary
string in the victim's file did not leak.

### CI job token scope

I ran a real job in the attacker's project and used its `CI_JOB_TOKEN` against the victim's project:

- API read → **403** *"Authentication by CI/CD job token not allowed from attacker-proj to project"*
- repository file → **403**
- pipeline creation → **401**

Job-token scoping is enforced.

### Webhook SSRF

| Payload | At creation | At delivery |
|---|---|---|
| `127.0.0.1`, `localhost` | blocked | – |
| private ranges (`10.x`, `192.168.x`) | blocked | – |
| decimal / octal IP encodings | blocked | – |
| IPv6 loopback / mapped | blocked | – |
| `*.nip.io` names resolving to internal IPs | blocked | – |
| `metadata.google.internal` | **accepted** | blocked: *"Host cannot be resolved or invalid"* |

The one accepted hostname looked interesting at first. But GitLab resolves the host again
when it sends the webhook and blocks it then, so no request ever goes out. **Not SSRF.**

## Takeaways

- On a hardened, current release, the obvious cross-user paths are well covered. A real bug
  is more likely in new feature code or in edge cases between checks.
- Always test SSRF filters at **both** creation and delivery time. Treating "accepted at
  creation" as a finding would have been a false positive.
