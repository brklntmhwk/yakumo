{
  output = [
    {
      _args = [ "eDP-1" ];
      scale = {
        _args = [ 2 ];
      };
    }
  ];
  window-rule = [
    {
      match = [
        {
          _props = {
            app-id = "regreet";
          };
        }
      ];
      open-on-output = {
        _args = [ "eDP-1" ];
      };
    }
  ];
}
