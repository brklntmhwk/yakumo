{ theme }:

let inherit (theme) colors fonts;
in ''
  /* See wofi(5) for the CSS selectors  */
  * {
      font-family: ${fonts.moralerspaceHw.name}, ${fonts.jetbrainsMono.name}, Roboto, Helvetica, Ariel, sans-serif;
      font-size: 25px;
  }

  #window {
      margin: 0 auto;
      background-color: ${colors.bg-active};
      border-radius: 6px;
  }

  #input {
      color: ${colors.fg-alt};
      background-color: ${colors.bg-active};
      border: none;
      margin: 10px;
      padding: 10px 12px;
  }

  #inner-box {
      border: none;
  }

  #text {
      color: ${colors.fg-alt};
  }

  .entry {
      margin: 8px 12px;
  }

  #entry:selected {
      background: ${colors.magenta-cooler};
      border: none;
  }
''
