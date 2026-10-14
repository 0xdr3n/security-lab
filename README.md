# security-lab

My setup and notes for hands-on vulnerability research on self-hostable web applications.

Everything here runs **locally against my own instances**. Nothing in this repo targets
third-party systems.

## Contents

| Path | What it is |
|---|---|
| [`labs/wordpress/`](labs/wordpress/) | Dockerised WordPress + MariaDB lab for plugin auditing |
| [`labs/gitlab/`](labs/gitlab/) | Self-managed GitLab CE lab (Docker) with attacker/victim accounts |
| [`methodology/wordpress-plugin-authz.md`](methodology/wordpress-plugin-authz.md) | How I hunt missing-authorization bugs in WordPress plugins |
| [`methodology/source-assisted-hunting.md`](methodology/source-assisted-hunting.md) | General approach: hunt new code in historically buggy areas |
| [`tools/wp-surface.sh`](tools/wp-surface.sh) | Lists a plugin's unauthenticated AJAX hooks and open REST routes |
| [`writeups/`](writeups/) | Tests I ran and what I found, including the ones where the control held |

## Lab layout

```
Windows host (notes, source review, static analysis)
   │  SSH
   ▼
Kali Linux VM (VMware, bridged)
   └── Docker
        ├── wordpress + mariadb       (plugin auditing)
        ├── gitlab-ce + gitlab-runner (access control, CI/CD, webhooks)
        ├── nextcloud                 (file/share permissions)
        └── vikunja                   (sharing permissions, import parsing)
```

Each target gets at least two non-admin accounts, an **attacker** and a **victim**, so
access-control tests are always a cross-user test rather than "can admin do admin things".

## Rules I follow

- Test only instances I run myself, or programs that explicitly allow it, within their scope.
- No DoS, no mass scanning.
- Verify before reporting: reproduce on the current release, include a negative control, and
  compare against the right baseline (is this behaviour intended elsewhere in the same app?).
- Coordinated disclosure: vulnerability details are published here only after a fix is out.
