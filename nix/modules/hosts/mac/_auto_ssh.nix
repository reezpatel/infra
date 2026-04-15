{ pkgs, ... }:

{
  launchd.daemons.autossh-saaf-dev = {
    serviceConfig = {
      Label = "autossh-saaf-dev";
      ProgramArguments = [
        "${pkgs.autossh}/bin/autossh"
        "-M" "0"
        "-o" "ServerAliveInterval 60"
        "-o" "ServerAliveCountMax 6"
        "-o" "StrictHostKeyChecking no"
        "-N"
        "-o" "GatewayPorts yes"
        "-L" "0.0.0.0:5421:dev-saaf-us-east-1-db-aurora-rds-pg.cluster-cylgsngtg19w.us-east-1.rds.amazonaws.com:5432"
        "ec2-user@dev-saaf-aurora-bh-us-east-1-lb-5289c3247da1e2dc.elb.us-east-1.amazonaws.com"
        "-i" "/etc/autossh/saaf-dev_rsa.pem"
      ];
      RunAtLoad = true;
      KeepAlive = true;
      EnvironmentVariables = {
        AUTOSSH_GATETIME = "0";
      };
    };
  };

  launchd.daemons.autossh-saaf-ppd = {
    serviceConfig = {
      Label = "autossh-saaf-ppd";
      ProgramArguments = [
        "${pkgs.autossh}/bin/autossh"
        "-M" "0"
        "-o" "ServerAliveInterval 60"
        "-o" "ServerAliveCountMax 6"
        "-o" "StrictHostKeyChecking no"
        "-N"
        "-o" "GatewayPorts yes"
        "-L" "0.0.0.0:5433:ppd-saaf-us-west-2-db-aurora-rds-pg.cluster-cncae2g4snn0.us-west-2.rds.amazonaws.com:5432"
        "ec2-user@ppd-saaf-aurora-bh-us-west-2-lb-02f29db02e2a726f.elb.us-west-2.amazonaws.com"
        "-i" "/etc/autossh/saaf-ppd_rsa.pem"
      ];
      RunAtLoad = true;
      KeepAlive = true;
      EnvironmentVariables = {
        AUTOSSH_GATETIME = "0";
      };
    };
  };
}
