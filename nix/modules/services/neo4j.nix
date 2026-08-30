{ ... }: {
  flake.modules.nixos.neo4j =
    {
      config,
      lib,
      ...
    }:
    let
      cfg = config.services.neo4j;
    in
    {
      # Default credentials: neo4j / neo4j. Neo4j forces a password change on
      # first login, via the browser (http://<host>:7474) or cypher-shell:
      #   cypher-shell -u neo4j -p neo4j
      # so no agenix secret is needed.
      services.neo4j = {
        enable = true;
        # Listens on all interfaces at the service level, but the firewall
        # only opens the ports on the NetBird mesh interface (nb-default) -
        # not reachable from the public internet or LAN.
        # CLAIM THE INSTANCE IMMEDIATELY after first deploy: whoever logs in
        # first with neo4j/neo4j gets to set the new password.
        defaultListenAddress = "0.0.0.0";
        https.enable = false;
      };

      # Mesh-only: reachable via the NetBird interface (nb-default), closed on
      # public and LAN interfaces.
      networking.firewall.interfaces."nb-default".allowedTCPPorts = [
        7474 # neo4j browser / http
        7687 # bolt
      ];

      # The BROWSER http module serves Neo4j Browser from <NEO4J_HOME>/web,
      # but the runtime home (/var/lib/neo4j) starts empty — the browser zip
      # only exists inside the read-only package. Link it so /browser/ works.
      systemd.services.neo4j.preStart = lib.mkAfter ''
        ln -sfn ${cfg.package}/share/neo4j/web ${cfg.directories.home}/web
      '';
    };
}
