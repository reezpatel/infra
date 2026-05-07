1. Linux Hosts are present in `scripts/deploy_remote.sh`
2. In addition there are two host `ace` and `luffy` which are darvin (macos)
3. The script runs on darvin and deployed to linux host, so local exploration may no always work.
4. `Justfile` stores all command related to deploy
5. We use nix-flake and `dendritic` pattern.
6. All static files are strored in `dotfiles`
7. All secrets are `age` encrpted and stored in `secrets`
8. Services always run on linux hosts this configuration doesn't need to adapt for darvin.
9. Programs (cli) may run on macos and need to consider darvin too.
10. Each host has its own `.nix` file at `nix/modules/hosts`
