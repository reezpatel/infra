# Komodo

One web UI over every containerised host in the fleet. **Core** runs on
**slayer**, a **Periphery** agent runs on every NixOS host, and the agents
dial Core over the NetBird mesh — nothing is published to the internet.

## Layout

| Piece | Where |
| --- | --- |
| Core (UI + API, port 9120) | `nix/modules/services/komodo-core.nix` → slayer |
| Mongo (Core's database) | same module, `komodo-mongo` podman container, loopback-only |
| Periphery agent | `nix/modules/services/komodo-periphery.nix` → imported by `base`, so **all** NixOS hosts |
| Agent binary | `pkgs.komodo` (nixpkgs 2.3.3), native systemd unit |
| Onboarding key | `secerts/komodo-onboarding-key.age` (one shared key) |

macOS hosts (`ace`, `luffy`) have no agent — Komodo Periphery is Linux-only.

## Why Core is a container but Periphery is not

`pkgs.komodo` builds the Rust binaries only. Core additionally serves the web
UI from `ui_path` (`/app/ui`) and shells out to a bundled `deno` for Actions —
both are assembled in upstream's Dockerfile and are **not** in the nixpkgs
derivation. So Core runs from `ghcr.io/moghtech/komodo-core:2` under rootful
podman (same pattern as `memgraph` / `waha`), while the agent, which needs
neither, runs natively from the nixpkgs binary via the upstream NixOS module.

Core speaks the MongoDB wire protocol only — it cannot reuse the Postgres
already on slayer, hence the small `mongo:8` container next to it.

## Connection direction

**Outbound (Periphery → Core).** Each agent opens a websocket to
`http://slayer.netbird:9120`, so:

- no inbound port is opened on any host — no `:8120`, no self-signed TLS
- Core's public key is trust-on-first-use pinned into
  `/var/lib/komodo-periphery/keys/core.pub` on the first handshake
- NAT'd and netbooted nodes need zero extra plumbing

The payload is Noise-encrypted end to end and rides WireGuard underneath, so
plain `http://` to Core is fine. Port 9120 is opened **only** on the
`nb-default` interface.

Override per host if ever needed:

```nix
komodo.periphery.coreAddress = "http://100.64.0.x:9120";
```

## Container runtime: podman, not docker

The agent is pointed at `unix:///run/podman/podman.sock` (podman's
Docker-compatible API). Komodo talks the Docker API with bollard and shells
out to the `docker` CLI; both honour `DOCKER_HOST`, so Komodo sees and manages
the podman containers this repo already runs — memgraph, waha, and Komodo's
own Core/mongo.

Consequences baked into the module:

- the agent user joins the `podman` group (upstream only grants `docker`)
- `legacyComposeCli = true` — `docker compose` is a CLI plugin nixpkgs'
  docker package doesn't ship; `pkgs.docker-compose` (standalone binary) is
  put on the unit's `PATH` instead
- on hosts that don't already run dockerd, `virtualisation.docker.package` is
  narrowed to `pkgs.docker-client` so the daemon never lands in the closure —
  this matters most on the netbooted Pis
- hosts carrying the `server` aspect (trinity, vixen, muse, divine,
  divergent) still run their own dockerd; those containers are simply
  invisible to Komodo. Move them to podman, or add a second Server in the UI
  pointed at a periphery instance with `dockerHost` set to the docker socket.

## First-time setup

1. Deploy slayer. From any mesh peer open <http://slayer.netbird:9120>.
2. Click **Sign Up** — `disable_user_registration` is on, so the first
   account created becomes the admin and every later signup is rejected.
   Minimum password length is 12.
3. **Settings → Server Onboarding Keys** → create a key, then:
   ```
   agenix -e secerts/komodo-onboarding-key.age   # raw key, no KEY= prefix
   ```
4. Set `komodo.periphery.onboarding.enable = true` (in `features/default.nix`
   or per host) and redeploy the fleet. Each host registers itself as a Server
   named after its `hostname` on first connect.

Without the key, create each Server by hand in the UI: name it after the
host's `hostname`, leave the address blank (that selects Periphery → Core
mode) — `connect_as` on the agent does the rest.

## Notes

- `jwt_secret` is generated once into `/var/lib/komodo/keys/jwt_secret` by an
  `ExecStartPre`. Without it Core mints a random secret per start and drops
  every session on redeploy.
- Core state lives in `/var/lib/komodo/{keys,syncs,repo-cache,backups}`; the
  database is in the podman volume `komodo-mongo-data`.
- **muse and rpi7** have no host key in `secerts/secrets.nix`, so they cannot
  decrypt the onboarding key. Add their keys and `agenix -r`, or leave
  onboarding off there and create those two Servers by hand.
- `km` (upstream CLI) is in slayer's system packages.
- Updating: `nix flake update` moves `pkgs.komodo` (agents); Core follows the
  `:2` image tag and updates on `podman pull` / container restart.
