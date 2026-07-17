{ pkgs, lib, config, ... }:

{
  # -------------------------------------------------------------------------
  # Extra Nix packages available in the shell alongside the Python venv.
  # Add non-Python tooling here (linters, formatters, git plugins, etc.).
  # -------------------------------------------------------------------------
  packages = with pkgs; [
    git
  ];

  # -------------------------------------------------------------------------
  # Python — creates a venv and installs requirements.txt on shell entry.
  # `venv.requirements` is relative to the project root where devenv runs.
  # -------------------------------------------------------------------------
  languages.python = {
    enable  = true;
    version = "3.13";
    venv = {
      enable       = true;
      requirements = ./requirements.txt;
    };
  };

  # -------------------------------------------------------------------------
  # Named scripts — available as commands in the devenv shell.
  # Defined via scripts.<name>.exec + scripts.<name>.description.
  # -------------------------------------------------------------------------
  scripts = {
    docs-serve = {
      exec        = "mkdocs serve --dev-addr 0.0.0.0:8000";
      description = "Start the mkdocs live-reload server (http://localhost:8000)";
    };
    docs-build = {
      exec        = "mkdocs build --strict";
      description = "Build static site into ./site (strict = warnings as errors)";
    };
    docs-new = {
      exec        = "mkdocs new .";
      description = "Scaffold a new mkdocs project in the current directory";
    };
  };

  # -------------------------------------------------------------------------
  # Shell hook — runs every time the devenv shell is entered.
  # -------------------------------------------------------------------------
  enterShell = ''
    echo ""
    echo "mkdocs development environment"
    echo ""
    echo "  docs-serve   —  http://localhost:8000  (live reload)"
    echo "  docs-build   —  ./site                 (strict build)"
    echo "  docs-new     —  scaffold empty project"
    echo ""
    python --version
    mkdocs --version
    echo ""
  '';
}
