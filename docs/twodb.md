# TwoDB

Server runs on **slayer** (flake module `twodb-server`, from
`github:reezpatel/twodb`), node agents on other hosts dial in over the
NetBird mesh — nothing is exposed publicly except nginx at
<https://app.twodb.io>.

## Layout

| Piece | Where |
| --- | --- |
| Server (web + API, port 3001) | `nix/modules/services/twodb-server.nix` → slayer |
| Node agent | `nix/modules/services/twodb-node.nix` → trinity, divergent, divine, vixen, rpi1–rpi5 |
| Agent binary | `inputs.twodb.packages.<system>.twodb-node` (upstream flake; fixed as of v0.0.9) |
| Per-host agent tokens | `secerts/twodb-node-token-<host>.age` |

The agent runs as the primary user (not `DynamicUser`) so code sessions can
read/write the project tree. `twodb.node.root` sets `TWODB_ROOT`
(`/workspace` on trinity/divergent, home dir elsewhere).

## First-time setup

1. Point `app.twodb.io` at slayer's public IP (147.93.171.18) — ACME needs
   it for the cert.
2. Deploy slayer, open <https://app.twodb.io>, register the admin passkey,
   create the vault + workspace.
3. Settings → Machines → Add machine (one per node host) → copy the token,
   then on a machine with the agenix keys:
   `agenix -e secerts/twodb-node-token-<host>.age`
   (the repo ships placeholder secrets so hosts evaluate before this step;
   the agent just retries auth until the real token lands)
4. Re-deploy the node host; the machine shows online within seconds.

## Networking

- Port 3001 is opened **only** on the `nb-default` (NetBird) interface.
- Agents default to `https://app.twodb.io` (nginx, TLS — 3001 is never
  publicly exposed; the server is a public VPS anyway). For mesh-direct
  instead: `twodb.node.serverUrl = "http://slayer.netbird:3001";` (or
  slayer's 100.64.x.x mesh IP).

## Updating

`nix flake update twodb` + redeploy — server and agents both track the
flake input (which follows the GitHub releases).

## Notes

- **aarch64-linux (rpis)**: supported since v0.0.9
  (`twodb-node-linux-arm64`); enabled on rpi1–rpi5.
- **muse, rpi6, rpi7**: tokens are encrypted (user1/system1 recipients for
  now) but the agent isn't enabled — their SSH host keys aren't registered
  in `secerts/secrets.nix` yet. Add the key, `agenix -r`, enable
  `twodb-node`, deploy (see the comment there).
- **macOS (ace, luffy)**: use the homebrew tap (`reezpatel/twodb/twodb-node`);
  prefer a nix-darwin-managed launchd service over `brew services` so the
  env vars stay declarative.
- The old Docker-based stack on trinity (memgraph + garage + container) was
  removed: module `nix/modules/services/twodb.nix` and the
  `twodb-{postgres-password,garage-rpc-secret,s3-keys}.age` secrets are
  gone. Leftover on trinity itself to clean up manually if desired: the
  `twodb`/`memgraph` docker containers + volumes, `/var/lib/twodb`,
  `/var/lib/garage`, and the `twodb` postgres database.
