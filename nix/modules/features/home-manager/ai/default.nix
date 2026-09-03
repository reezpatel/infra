# Aspect: ai (homeManager) — AI coding agents and tooling.
#
# opencode, pi, claude-code, codex and antigravity as home-manager modules
# (flake-packaged, with their HM integrations). On: divine.
#
# Note: luffy/ace install some of these as plain nixpkgs packages instead
# (see their environment.systemPackages) and import only `opencode`.
{self, ...}: {
  flake.modules.homeManager.ai.imports = with self.modules.homeManager; [
    opencode
    pi
    claude-code
    codex
    antigravity
    gemini
  ];
}
