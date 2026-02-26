{
  output = [
    {
      _args = [ "DP-2" ];
      mode = {
        _args = [ "3840x2160" ];
      };
      scale = {
        _args = [ 2 ];
      };
      position = {
        _props = {
          x = 0;
          y = 0;
        };
      };
    }
    {
      _args = [ "HDMI-A-1" ];
      mode = {
        _args = [ "2560x1440" ];
      };
      scale = {
        _args = [ 1 ];
      };
      position = {
        _props = {
          x = 0;
          y = 1080;
        };
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
        _args = [ "DP-2" ];
      };
    }
  ];
}
