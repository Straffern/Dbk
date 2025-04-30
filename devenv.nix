{ pkgs, lib, config, inputs, ... }:
let
  pkgs-unstable =
    import inputs.nixpkgs-unstable { system = pkgs.stdenv.system; };
  # elixir = pkgs-unstable.beam.packages.erlang_27.elixir_1_17;
  elixir = pkgs-unstable.beamMinimal27Packages.elixir;
in {
  # https://devenv.sh/basics/
  env.GREET = "devenv";
  env.ELIXIR_ERL_OPTIONS = "-kernel shell_history enabled";

  # https://devenv.sh/packages/
  packages = [ pkgs.git elixir pkgs.inotify-tools ];

  # https://devenv.sh/languages/
  # languages.rust.enable = true;

  # https://devenv.sh/processes/
  # processes.cargo-watch.exec = "cargo-watch";

  # https://devenv.sh/services/
  # services.postgres.enable = true;

  # https://devenv.sh/scripts/
  scripts.cleanup.exec = ''
    echo "Cleaning up development artifacts..."
    # Remove migration files (contents only)
    rm -rf priv/repo/migrations/*
    # Remove resource snapshots directory
    rm -rf priv/resource_snapshots
    # Remove development database files
    rm -f numeri_dev.db numeri_dev.db-shm numeri_dev.db-wal
    echo "Cleanup complete."
  '';

  # scripts.hello.exec = ''
  #   echo hello from $GREET
  # '';

  # enterShell = ''
  #   hello
  #   echo "Run 'devenv cleanup' to remove migrations, snapshots, and the dev database."
  #   git --version
  # '';

  # https://devenv.sh/tasks/
  # tasks = {
  #   "myproj:setup".exec = "mytool build";
  #   "devenv:enterShell".after = [ "myproj:setup" ];
  # };

  # https://devenv.sh/tests/
  # enterTest = ''
  #   echo "Running tests"
  #   git --version | grep --color=auto "${pkgs.git.version}"
  # '';

  # https://devenv.sh/git-hooks/
  # git-hooks.hooks.shellcheck.enable = true;

  # See full reference at https://devenv.sh/reference/options/

  git-hooks.hooks = {
    mix-format = {
      enable = true;
      entry = "${elixir}/bin/mix format";
      stages = [ "pre-commit" ];
    };
    credo = {
      enable = true;
      entry = "${elixir}/bin/mix credo --strict";
      stages = [ "pre-push" ];
    };
  };
}
