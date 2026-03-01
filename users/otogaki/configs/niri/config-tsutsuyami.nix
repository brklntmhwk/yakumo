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
      transform = {
        _args = [ "normal" ];
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
      transform = {
        _args = [ "normal" ];
      };
      position = {
        _props = {
          x = 0;
          y = 1080; # Use DP-2's logical height.
        };
      };
    }
  ];
}
