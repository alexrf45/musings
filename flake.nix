
{
  description = "Go development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, utils }:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
       color = "31"; # Red color text helper for shell prompt
      in
      {
        devShells.default = pkgs.mkShell {
          # Tools available in the environment
          buildInputs = with pkgs; [
            go                 # The Go compiler and toolchain
            gopls              # Go language server for IDEs
            gotools            # Go tools like goimports
            golangci-lint      # Go linter
            hugo
            gimp
          ];

          # Environments variables to inject
          shellHook = ''
            echo -e "\e[${color}mWelcome to your Go development shell!\e[0m"
            export GOPATH="$HOME/go"
          '';
        };
      });
}
