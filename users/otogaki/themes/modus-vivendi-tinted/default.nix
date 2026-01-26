# https://github.com/sioodmy/dotfiles/commit/0c2c94c828479180b34100606cc7c33e402a2375
pkgs:

let
  wallpaperPath = "maple-with-hidden-falls.jpg";
  avatorPath = "avators/otogaki.png";
  yaegaki = (pkgs.callPackage ./_sources/generated.nix { }).yaegaki;
in
{
  wallpaper = "${yaegaki.src}/${wallpaperPath}";

  avator = "${yaegaki.src}/${avatorPath}";

  fonts = {
    moralerspaceHw = {
      name = "Moralerspace Neon HWNF";
      package = pkgs.moralerspace-hw;
    };
    hackgenNf = {
      name = "HackGen Console NF";
      package = pkgs.hackgen-nf-font;
    };
    jetbrainsMono = {
      name = "JetBrains Mono";
      package = pkgs.jetbrains-mono;
    };
    notoCjkSans = {
      name = "Noto Sans CJK JP";
      package = pkgs.noto-fonts-cjk-sans;
    };
    notoCjkSerif = {
      name = "Noto Sans CJK JP";
      package = pkgs.noto-fonts-cjk-serif;
    };
    notoEmoji = {
      name = "Noto Color Emoji";
      package = pkgs.noto-fonts-emoji;
    };
  };

  cursorThemes = {
    adwaita = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
    };
    rosePine = {
      name = "BreezeX-RosePine-Linux";
      package = pkgs.rose-pine-cursor;
    };
    rosePineHyprcursor = {
      name = "rose-pine-hyprcursor";
      package = pkgs.rose-pine-hyprcursor;
    };
  };

  loginThemes = {
    adwaita = {
      name = "Adwaita";
      package = pkgs.gnome-themes-extra;
    };
  };

  # Based on modus-themes (modus-vivendi-tinted)
  # https://protesilaos.com/emacs/modus-themes-colors
  colors = {
    bg-main = "#0d0elc";
    bg-dim = "#1d2235";
    fg-main = "#ffffff";
    fg-dim = "#989898";
    fg-alt = "#c6daff";
    bg-active = "#4a4f69";
    bg-inactive = "#2b3045";
    border = "#61647a";

    red = "#ff5f59";
    red-warmer = "#ff6b55";
    red-cooler = "#ff7f86";
    red-faint = "#ef8386";
    red-intense = "#ff5f5f";

    green = "#44bc44";
    green-warmer = "#75c13e";
    green-cooler = "#11c777";
    green-faint = "#88ca9f";
    green-intense = "#44df44";

    yellow = "#d0bc00";
    yellow-warmer = "#fec43f";
    yellow-cooler = "#dfaf7a";
    yellow-faint = "#d2b580";
    yellow-intense = "#efef00";

    blue = "#2fafff";
    blue-warmer = "#79a8ff";
    blue-cooler = "#00bcff";
    blue-faint = "#82b0ec";
    blue-intense = "#338fff";

    magenta = "#feacd0";
    magenta-warmer = "#f78fe7";
    magenta-cooler = "#b6a0ff";
    magenta-faint = "#caa6df";
    magenta-intense = "#ff66ff";

    cyan = "#00d3d0";
    cyan-warmer = "#4ae2f0";
    cyan-cooler = "#6ae4b9";
    cyan-faint = "#9ac8e0";
    cyan-intense = "#00eff0";

    rust = "#db7b5f";
    gold = "#c0965b";
    olive = "#9cbd6f";
    slate = "#76afbf";
    indigo = "#9099d9";
    maroon = "#cf7fa7";
    pink = "#d09dc0";

    bg-red-intense = "#9d1f1f";
    bg-green-intense = "#2f822f";
    bg-yellow-intense = "#7a6100";
    bg-blue-intense = "#1640b0";
    bg-magenta-intense = "#7030af";
    bg-cyan-intense = "#2266ae";

    bg-red-subtle = "#620f2a";
    bg-green-subtle = "#00422a";
    bg-yellow-subtle = "#4a4000";
    bg-blue-subtle = "#242679";
    bg-magenta-subtle = "#552f5f";
    bg-cyan-subtle = "#004065";

    bg-red-nuanced = "#3a0c14";
    bg-green-nuanced = "#092f1f";
    bg-yellow-nuanced = "#381d0f";
    bg-blue-nuanced = "#12154a";
    bg-magenta-nuanced = "#2f0c3f";
    bg-cyan-nuanced = "#042837";

    bg-clay = "#49191a";
    fg-clay = "#f1b090";
    bg-ochre = "#462f20";
    fg-ochre = "#e0d09c";
    bg-lavender = "#38325c";
    fg-lavender = "#dfc0f0";
    bg-sage = "#143e32";
    fg-sage = "#c3e7d4";

    bg-graph-red-0 = "#b52c2c";
    bg-graph-red-1 = "#702020";
    bg-graph-green-0 = "#0fed00";
    bg-graph-green-1 = "#007800";
    bg-graph-yellow-0 = "#f1e00a";
    bg-graph-yellow-1 = "#b08940";
    bg-graph-blue-0 = "#2fafef";
    bg-graph-blue-1 = "#1f2f8f";
    bg-graph-magenta-0 = "#bf94fe";
    bg-graph-magenta-1 = "#5f509f";
    bg-graph-cyan-0 = "#47dfea";
    bg-graph-cyan-1 = "#00808f";

    bg-completion = "#483d8a";
    bg-hover = "#45605e";
    bg-hover-secondary = "#64404f";
    bg-hl-line = "#303a6f";
    bg-region = "#555a66";
    fg-region = "#ffffff";

    bg-tab-bar = "#2c3045";
    bg-tab-current = "#0d0e1c";
    bg-tab-other = "#4a4f6a";

    bg-added = "#003a2f";
    bg-added-faint = "#002922";
    bg-added-refine = "#035542";
    bg-added-fringe = "#23884f";
    fg-added = "#a0e0a0";
    fg-added-intense = "#80e080";

    bg-changed = "#363300";
    bg-changed-faint = "#2a1f00";
    bg-changed-refine = "#4a4a00";
    bg-changed-fringe = "#8f7a30";
    fg-changed = "#efef80";
    fg-changed-intense = "#c0b05f";

    bg-removed = "#4f1127";
    bg-removed-faint = "#380a19";
    bg-removed-refine = "#781a3a";
    bg-removed-fringe = "#b81a26";
    fg-removed = "#ffbfbf";
    fg-removed-intense = "#ff9095";

    bg-diff-context = "#1a1f30";
    bg-paren-match = "#4f7f9f";
    bg-paren-expression = "#453040";
  };
}
