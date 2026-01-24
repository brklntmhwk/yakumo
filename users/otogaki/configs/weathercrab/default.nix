{ pkgs, lib, ... }:

{
  xdg.configFile = {
    "weathercrab/wthrr.ron".source = ./wthrr.ron;
  };

  home.packages = with pkgs; [
    wthrr
  ];
}
