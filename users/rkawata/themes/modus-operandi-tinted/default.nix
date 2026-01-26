# https://github.com/sioodmy/dotfiles/commit/0c2c94c828479180b34100606cc7c33e402a2375
pkgs:

let
  wallpaperPath = "stone-stacking.jpg";
  avatorPath = "avators/rkawata.png";
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

  # Based on modus-themes (modus-operandi-tinted)
  # https://protesilaos.com/emacs/modus-themes-colors
  colors = {
    bg-main = "#fbf7f0";
    bg-dim = "#efe9dd";
    fg-main = "#000000";
    fg-dim = "#595959";
    fg-alt = "#193668";
    bg-active = "#c9b9b0";
    bg-inactive = "#dfd5cf";
    border = "#9f9690";

    red = "#a60000";
    red-warmer = "#972500";
    red-cooler = "#a0132f";
    red-faint = "#7f0000";
    red-intense = "#d00000";

    green = "#006300";
    green-warmer = "#306010";
    green-cooler = "#00603f";
    green-faint = "#2a5045";
    green-intense = "#008900";

    yellow = "#6d5000";
    yellow-warmer = "#894000";
    yellow-cooler = "#602938";
    yellow-faint = "#574316";
    yellow-intense = "#808000";

    blue = "#0031a9";
    blue-warmer = "#3546c2";
    blue-cooler = "#0000b0";
    blue-faint = "#003497";
    blue-intense = "#0000ff";

    magenta = "#721045";
    magenta-warmer = "#8f0075";
    magenta-cooler = "#531ab6";
    magenta-faint = "#7c318f";
    magenta-intense = "#dd22dd";

    cyan = "#00598b";
    cyan-warmer = "#32548f";
    cyan-cooler = "#005f5f";
    cyan-faint = "#304463";
    cyan-intense = "#008899";

    rust = "#8a290f";
    gold = "#80601f";
    olive = "#56692d";
    slate = "#2f3f83";
    indigo = "#4a3a8a";
    maroon = "#731c52";
    pink = "#7b435c";

    bg-red-intense = "#ff8f88";
    bg-green-intense = "#8adf80";
    bg-yellow-intense = "#f3d000";
    bg-blue-intense = "#bfc9ff";
    bg-magenta-intense = "#dfa0f0";
    bg-cyan-intense = "#a4d5f9";

    bg-red-subtle = "#ffcfbf";
    bg-green-subtle = "#b3fabf";
    bg-yellow-subtle = "#fff576";
    bg-blue-subtle = "#ccdfff";
    bg-magenta-subtle = "#ffddff";
    bg-cyan-subtle = "#bfefff";

    bg-red-nuanced = "#ffe8e8";
    bg-green-nuanced = "#e0f6e0";
    bg-yellow-nuanced = "#f8f0d0";
    bg-blue-nuanced = "#ecedff";
    bg-magenta-nuanced = "#f8e6f5";
    bg-cyan-nuanced = "#e0f2fa";

    bg-clay = "#f1c8b5";
    fg-clay = "#63192a";
    bg-ochre = "#f0e3c0";
    fg-ochre = "#573a30";
    bg-lavender = "#dfcdfa";
    fg-lavender = "#443379";
    bg-sage = "#c0e7d4";
    fg-sage = "#124b41";

    bg-graph-red-0 = "#ef7969";
    bg-graph-red-1 = "#ffaab4";
    bg-graph-green-0 = "#45c050";
    bg-graph-green-1 = "#75ef30";
    bg-graph-yellow-0 = "#ffcf00";
    bg-graph-yellow-1 = "#f9ff00";
    bg-graph-blue-0 = "#7f90ff";
    bg-graph-blue-1 = "#a6c0ff";
    bg-graph-magenta-0 = "#e07fff";
    bg-graph-magenta-1 = "#fad0ff";
    bg-graph-cyan-0 = "#70d3f0";
    bg-graph-cyan-1 = "#afefff";

    bg-completion = "#f0c1cf";
    bg-hover = "#b2e4dc";
    bg-hover-secondary = "#dfe09f";
    bg-hl-line = "#f1d5d0";
    bg-region = "#c2bcb5";
    fg-region = "#000000";

    bg-tab-bar = "#e0d4ce";
    bg-tab-current = "#fbf7f0";
    bg-tab-other = "#c8b8b2";

    bg-added = "#c3ebc1";
    bg-added-faint = "#dcf8d1";
    bg-added-refine = "#acd6a5";
    bg-added-fringe = "#6cc06c";
    fg-added = "#005000";
    fg-added-intense = "#006700";

    bg-changed = "#ffdfa9";
    bg-changed-faint = "#ffefbf";
    bg-changed-refine = "#fac090";
    bg-changed-fringe = "#c0b200";
    fg-changed = "#553d00";
    fg-changed-intense = "#655000";

    bg-removed = "#f4d0cf";
    bg-removed-faint = "#ffe9e5";
    bg-removed-refine = "#f3b5a7";
    bg-removed-fringe = "#d84a4f";
    fg-removed = "#8f1313";
    fg-removed-intense = "#aa2222";

    bg-diff-context = "#efe9df";
    bg-paren-match = "#7fdfcf";
    bg-paren-expression = "#efd3f5";
  };
}
