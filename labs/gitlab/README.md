# Self-managed GitLab CE lab

A running GitLab instance at the current stable version, plus the matching source, for
access-control and CI/CD testing.

> Use the current stable release. A bug in an old version is usually already patched.

## 1. Pick the version

Check https://hub.docker.com/r/gitlab/gitlab-ce/tags for the newest **non-RC** tag and pin it.
Don't use `latest`.

## 2. Run it

```bash
export VER=<x.y.z>-ce.0
mkdir -p ~/gitlab/{config,logs,data}
docker run --detach \
  --hostname gitlab.local \
  --publish 8929:80 --publish 8922:22 \
  --name gitlab --restart always --shm-size 256m \
  --volume ~/gitlab/config:/etc/gitlab \
  --volume ~/gitlab/logs:/var/log/gitlab \
  --volume ~/gitlab/data:/var/opt/gitlab \
  gitlab/gitlab-ce:$VER
```

GitLab needs roughly 4 vCPU and 4–8 GB RAM. On a small VM, lower the footprint in
`/etc/gitlab/gitlab.rb`:

```ruby
puma['worker_processes'] = 2
prometheus_monitoring['enable'] = false
```

Then run `docker exec gitlab gitlab-ctl reconfigure`.

Initial root password:

```bash
docker exec gitlab cat /etc/gitlab/initial_root_password
```

## 3. Accounts and projects

Create two normal users, **attacker** and **victim**. The victim owns a private project with
CI variables, a pipeline and some files; the attacker owns a project of their own. Every test
asks: *can the attacker read or change anything in the victim's project?*

Personal access tokens for API testing can be created in the UI, or with `gitlab-rails runner`.

## 4. CI/CD testing

To test job tokens and cross-project pipeline behaviour, register a runner:

```bash
docker run -d --name gl-runner --network host \
  -v /var/run/docker.sock:/var/run/docker.sock gitlab/gitlab-runner:latest
# then register it with an instance runner token from Admin > CI/CD > Runners
```

## 5. Source at the same version

```bash
git clone --depth 1 --branch v<x.y.z>-ee https://gitlab.com/gitlab-org/gitlab.git gitlab-src
```

Authorization logic lives in `app/policies/`, `authorize :permission` calls in API/GraphQL
code, and `Ability.allowed?`.

## 6. Burp

Proxy the browser through Burp, scope it to the lab host only, and use Repeater to replay
victim-owned requests with the attacker's session or token.
