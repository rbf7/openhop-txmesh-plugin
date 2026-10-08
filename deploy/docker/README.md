# Running openhop-txmesh in Docker

The plugin is a client. It connects to a companion on an openHop Repeater and
to `collector.txme.sh:443`. It needs no inbound ports and no hardware.

```
radio --- openhop-repeater --(companion TCP :5001)-- openhop-txmesh --> collector.txme.sh
```

## Before you start

1. A running openHop Repeater with a companion created for this plugin
   (Rooms, Companions in its web UI). One client per companion, so give this
   one its own port, and set its TCP timeout to 0 so an idle link is not dropped.
2. `OPENHOP_TXMESH_NODE_NAME` in `txmesh.env` must match the companion's node name exactly.
3. Your txme.sh username and password. They go in `txmesh.env`, never in git.

## Deploy

One command, run on the NAS (clones your fork, builds the image, starts it):

```bash
curl -fsSL https://raw.githubusercontent.com/rbf7/openhop-txmesh-plugin/main/deploy/docker/deploy.sh -o deploy.sh
chmod +x deploy.sh && ./deploy.sh   # first run creates templates; edit them, then run again
```

Override with `BASE=`, `REPO_URL=` or `BRANCH=` in the environment. The manual steps follow.

On the Docker host (paths below match a Synology-style layout; change as needed):

```bash
mkdir -p /volume1/docker/openhop-txmesh/{config,data}
cp config.json /volume1/docker/openhop-txmesh/config/       # optional: edit channels
cp env.example /volume1/docker/openhop-txmesh/txmesh.env    # edit login, node name, IPs, network
chmod 600 /volume1/docker/openhop-txmesh/txmesh.env
chown 15889 /volume1/docker/openhop-txmesh/data             # the container user

docker compose --env-file /volume1/docker/openhop-txmesh/txmesh.env \
  -f docker-compose.txmesh.yml up -d --build
docker logs -f openhop-txmesh 2>&1
```

Networking is configured in `txmesh.env`, not in the compose file:
`TXMESH_NETWORK` is the name of an existing Docker network (macvlan, bridge,
...) and `TXMESH_IP` is a free address on it for this container. The compose
file reads them through `docker compose --env-file`, which `deploy.sh` passes
for you. If you run `docker compose` by hand, pass `--env-file` too.

## Check it works

- Repeater log: `docker logs openhop-repeater 2>&1 | grep "client connected"`
  shows a connection on the companion's port.
- txmesh log: no connection errors, then `status online` publishes.
- Your node publishes under `meshcore/<username>/<node_name>/`
  (see [../../docs/OPERATIONS.md](../../docs/OPERATIONS.md)).

## Upgrade

The plugin is not on PyPI; the image installs the GitHub release wheel and
checks its SHA-256. For a new release, set `VERSION` and `WHEEL_SHA256`
(from the `.sha256` file next to the wheel on the releases page) in the compose
file, update the `image:` tag, and run
`deploy.sh` again (or `docker compose --env-file ... -f docker-compose.txmesh.yml up -d --build`).
The `/data` volume keeps the restart counter.

## Troubleshooting

- **Connection refused / timeout to the companion:** wrong host or port, the
  companion bound to 127.0.0.1, or a firewall between the networks.
- **Companion already in use:** another client (a phone app, another bot) holds
  that companion. Use a different companion.
- **Disconnects every ~2 minutes:** the companion's idle timeout is 120 s;
  set it to 0.
- **Auth failure to the collector:** check the username and password in
  `txmesh.env`.
