{
  output = [
    {
      _args = [ "eDP-1" ];
      scale = {
        _args = [ 2 ];
      };
    }
  ];
  debug = {
    # Force Niri to use the Panfrost GPU node instead of a basic display node
    # to prevent it from mistakenly fetching a non-3D node and causing
    # the screen to freeze.
    # Apple Silicon exposes multiple DRM nodes to the Linux kernel
    # (e.g., `card0`, `card1`, `card2`, `renderD128`, etc). Usually,
    # `card0` is a basic display controller and `card1` or `card2` is the
    # actual hardware-accelerated Panfrost 3D GPU.
    # Without explicitly telling Niri which card to use, it blindly grabs
    # the first one it finds.
    render-drm-device = {
      _args = [ "/dev/dri/card2" ];
    };
  };
}
