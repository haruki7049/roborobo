{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default";
    crane.url = "github:ipetkov/crane";
    flake-compat.url = "github:edolstra/flake-compat";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import inputs.systems;

      imports = [
        inputs.treefmt-nix.flakeModule
      ];

      perSystem =
        {
          pkgs,
          lib,
          system,
          ...
        }:
        let
          overlays = [ inputs.rust-overlay.overlays.default ];
          rust = pkgs.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml;
          craneLib = (inputs.crane.mkLib pkgs).overrideToolchain rust;
          src = craneLib.cleanCargoSource ./.;
          cargoArtifacts = craneLib.buildDepsOnly {
            inherit src;
            buildInputs = bevyengine-dependencies;
            nativeBuildInputs = [ pkgs.pkg-config ];
          };
          roborobo = craneLib.buildPackage {
            inherit src cargoArtifacts;
            strictDeps = true;
            buildInputs = bevyengine-dependencies;
            nativeBuildInputs = [ pkgs.pkg-config ];

            doCheck = true;
          };
          cargo-clippy = craneLib.cargoClippy {
            inherit src cargoArtifacts;
            buildInputs = bevyengine-dependencies;
            nativeBuildInputs = [ pkgs.pkg-config ];

            cargoClippyExtraArgs = "--verbose -- --deny warning";
          };
          cargo-doc = craneLib.cargoDoc {
            inherit src cargoArtifacts;
            buildInputs = bevyengine-dependencies;
            nativeBuildInputs = [ pkgs.pkg-config ];
          };

          bevyengine-dependencies = lib.optional pkgs.stdenv.isLinux [
            pkgs.udev
            pkgs.alsa-lib
            pkgs.vulkan-loader

            # To use the x11 feature
            pkgs.xorg.libX11
            pkgs.xorg.libXcursor
            pkgs.xorg.libXi
            pkgs.xorg.libXrandr

            # To use the wayland feature
            pkgs.libxkbcommon
            pkgs.wayland
          ];
        in
        {
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system overlays;
          };

          packages = {
            inherit
              roborobo
              ;
            default = roborobo;
            doc = cargo-doc;
          };

          checks = {
            inherit
              roborobo
              cargo-clippy
              cargo-doc
              ;
          };

          treefmt = {
            projectRootFile = "rust-toolchain.toml";
            programs.nixfmt.enable = true;
            programs.rustfmt.enable = true;
            programs.taplo.enable = true;
            programs.actionlint.enable = true;
            programs.mdformat.enable = true;

            settings.formatter = {
              mdformat.excludes = [
                "CODE_OF_CONDUCT.md"
                "SUPPORT.md"
              ];
            };
          };

          devShells.default = pkgs.mkShell rec {
            buildInputs = bevyengine-dependencies ++ [
              rust
              pkgs.nil
            ];

            nativeBuildInputs = [
              pkgs.pkg-config
            ];

            LD_LIBRARY_PATH = lib.makeLibraryPath buildInputs;

            shellHook = ''
              export PS1="\n[nix-shell:\w]$ "
            '';
          };
        };
    };
}
