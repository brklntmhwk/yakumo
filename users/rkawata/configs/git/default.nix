{ config, ... }:

{
  user = {
    name = "Reiji Kawata";
    # TODO: Change this to an individual email.
    email = "contact@younagi.dev";
    signingKey = config.sops.secrets.git_signing_key.path;
  };
  help = {
    # Auto-correct typos immediately. (e.g., `git stats` -> `git status`)
    autocorrect = "prompt";
  };
  init = {
    defaultBranch = "main";
  };
  gpg = {
    format = "ssh";
  };
  commit = {
    gpgSign = true;
  };
  push = {
    # Automatically set upstream on push if it doesn't exist. (Git 2.37+)
    autoSetupRemote = true;
    # Prevent accidental pushes to creating new branches you didn't intend.
    # Possible values: 'current', 'simple',
    default = "simple";
  };
  rebase = {
    # Automatically stash dirty changes before rebase and pop after.
    autoStash = true;
    # Update refs of stacked branches when rebasing. (Git 2.38+)
    updateRefs = true;
  };
  # "Reuse Recorded Resolution": Remembers how you fixed conflicts.
  # and automatically applies it if you encounter the same conflict again later.
  rerere = {
    enabled = true;
    autoupdate = true;
  };
  # URL shorthands. (e.g., `git clone gh:nixos/nixpkgs`)
  url = {
    "git@github.com:".insteadOf = [
      "gh:"
      "github:"
    ];
    "git@gitlab.com:".insteadOf = [
      "gl:"
      "gitlab:"
    ];
  };
}
