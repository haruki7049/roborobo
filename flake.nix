{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default-linux";
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
          kosu = craneLib.buildPackage {
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
          llvm-cov-text = craneLib.cargoLlvmCov {
            inherit cargoArtifacts src;
            buildInputs = bevyengine-dependencies;
            nativeBuildInputs = [ pkgs.pkg-config ];
            cargoExtraArgs = "--locked";
            cargoLlvmCovCommand = "test";
            cargoLlvmCovExtraArgs = "--text --output-dir $out";
          };
          llvm-cov = craneLib.cargoLlvmCov {
            inherit cargoArtifacts src;
            buildInputs = bevyengine-dependencies;
            nativeBuildInputs = [ pkgs.pkg-config ];
            cargoExtraArgs = "--locked";
            cargoLlvmCovCommand = "test";
            cargoLlvmCovExtraArgs = "--html --output-dir $out";
          };

          bevyengine-dependencies = with pkgs; [
            udev
            alsa-lib
            vulkan-loader

            # To use the x11 feature
            xorg.libX11
            xorg.libXcursor
            xorg.libXi
            xorg.libXrandr

            # To use the wayland feature
            libxkbcommon
            wayland
          ];
        in
        {
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system overlays;
          };

          packages = {
            inherit
              kosu
              llvm-cov
              llvm-cov-text
              ;
            default = kosu;
            doc = cargo-doc;
          };

          checks = {
            inherit
              kosu
              cargo-clippy
              cargo-doc
              llvm-cov
              llvm-cov-text
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
