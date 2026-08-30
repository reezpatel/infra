# Aspect: labs (homeManager) — experimental tools, not yet promoted to a
# permanent aspect. Currently: herdr (agent session multiplexer).
#
# Keep this non-overlapping with other aspects: a module may only live in
# ONE aspect, otherwise composed aspects (e.g. `workstation`) import it twice
# and duplicate its list-valued settings.
{self, ...}: {
  flake.modules.homeManager.labs.imports = with self.modules.homeManager; [
    herdr
  ];
}
