# WordPress plugin lab

A disposable WordPress install for auditing plugins: install a plugin, read its source,
then test its handlers as different roles.

## Start

```bash
cp .env.example .env        # set real passwords
docker compose up -d
```

Open `http://<host>:8082` and finish the installer.

## wp-cli

The official `wordpress:cli` image needs the DB settings and the site's volume:

```bash
wp() {
  docker run --rm --network wordpress_default --volumes-from wordpress-wp-1 \
    -e WORDPRESS_DB_HOST=wp-db -e WORDPRESS_DB_USER=wp \
    -e WORDPRESS_DB_PASSWORD="$WP_DB_PASSWORD" -e WORDPRESS_DB_NAME=wp \
    wordpress:cli "$@"
}
```

Network and container names depend on your compose project name; check them with
`docker network ls` and `docker ps`.

If plugin installs fail with a permissions error, make `wp-content/upgrade` writable
inside the `wp` container.

## Test accounts

```bash
wp user create attacker attacker@lab.test --role=subscriber --user_pass="$ATTACKER_PASS"
wp user create victim   victim@lab.test   --role=author     --user_pass="$VICTIM_PASS"
```

Then install the target plugin at a pinned version:

```bash
wp plugin install <slug> --version=<x.y.z> --activate
```

## Getting the source

Read the exact code you're running:

```bash
curl -LO https://downloads.wordpress.org/plugin/<slug>.<x.y.z>.zip
unzip <slug>.<x.y.z>.zip -d src/
```

Then run [`tools/wp-surface.sh`](../../tools/wp-surface.sh) on it to list the entry points.
