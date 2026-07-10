{
  description = "Development environment for Azure Function MCP server";

  inputs = {
    # Pin a stable nixpkgs release for reproducibility and better binary cache hits.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
  };

  outputs = { nixpkgs, ... }:
    let
      # ----------------------------------------------------------------------
      # Only developing on Linux.
      # ----------------------------------------------------------------------
      system = "x86_64-linux";

      pkgs = import nixpkgs {
        inherit system;
      };

      # ----------------------------------------------------------------------
      # Avoid duplicating packages across shells.
      # Makes maintenance much easier.
      # ----------------------------------------------------------------------

      pythonPackages = with pkgs; [
        python313
        uv
        ruff
        pyrefly
        pylint
      ];

      infraPackages = with pkgs; [
        opentofu
        tofu-ls
        tflint

        azure-cli

        azure-functions-core-tools
        dotnet-sdk_8
        dotnet-runtime_8
        stdenv.cc.cc.lib

        azurite

        podman
        oras
        trivy
      ];

      editorPackages = with pkgs; [
        marksman
        yaml-language-server
        vscode-json-languageserver
        taplo
        harper
      ];

      utilityPackages = with pkgs; [
        glow
        prek
        tokei
        nixpkgs-fmt
        commitlint
      ];

      # ----------------------------------------------------------------------
      #
      # Shared shell configuration.
      #
      # ----------------------------------------------------------------------

      commonShell = {
        UV_PYTHON_DOWNLOADS = "never";
        UV_PYTHON = "${pkgs.python313}/bin/python3.13";

        shellHook = ''
          unset PYTHONPATH
          export LD_LIBRARY_PATH=${pkgs.stdenv.cc.cc.lib}/lib:$LD_LIBRARY_PATH
        '';
      };

    in {

      devShells.${system} = {

        # ------------------------------------------------------------------
        # Main development shell.
        #
        # Includes everything needed for local development.
        # ------------------------------------------------------------------

        default = pkgs.mkShell (commonShell // {

          packages =
            pythonPackages
            ++ infraPackages
            ++ editorPackages
            ++ utilityPackages;

        });

        # ------------------------------------------------------------------
        #
        # CI shell
        #
        # ------------------------------------------------------------------

        ci = pkgs.mkShell (commonShell // {

          packages =
            pythonPackages
            ++ [
              pkgs.azure-cli
              pkgs.opentofu
              pkgs.tflint
              pkgs.trivy
              pkgs.podman
              pkgs.oras
            ];

        });
    };
};
}
