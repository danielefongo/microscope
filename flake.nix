{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        inherit (pkgs.luajitPackages)
          argparse
          buildLuarocksPackage
          luacov
          luafilesystem
          penlight
          ;
        pkgs = import nixpkgs { inherit system; };

        classic = buildLuarocksPackage {
          pname = "classic";
          version = "0.1.0-1";
          knownRockspec =
            (pkgs.fetchurl {
              url = "https://luarocks.org/manifests/emartech/classic-0.1.0-1.rockspec";
              hash = "sha256-jhsG+pAs1GbHKjpSV+eZP5l/2TMophOpng+jHMFpCbc=";
            }).outPath;
          src = pkgs.fetchFromGitHub {
            owner = "emartech";
            repo = "classic";
            rev = "e5610756c98ac2f8facd7ab90c94e1a097ecd2c6";
            hash = "sha256-c+DE/X1DZz3Sao9kcF7g4huTpQP39Y5k8RIoRkIw7+M=";
          };
        };

        lua-resty-template = buildLuarocksPackage {
          pname = "lua-resty-template";
          version = "2.0-1";
          knownRockspec =
            (pkgs.fetchurl {
              url = "https://luarocks.org/manifests/bungle/lua-resty-template-2.0-1.rockspec";
              hash = "sha256-LgH2r5txtsqNXf+SVlmu9MwldlgvoQuPaHB3ZLUNi0k=";
            }).outPath;
          src = pkgs.fetchFromGitHub {
            owner = "bungle";
            repo = "lua-resty-template";
            rev = "v2.0";
            hash = "sha256-YW3h9exkAC0WKnlK38L9qbso2Uk/TfNjRysWXQeW/r4=";
          };
        };

        luacov-console = buildLuarocksPackage {
          pname = "luacov-console";
          version = "1.1.0-1";
          knownRockspec =
            (pkgs.fetchurl {
              url = "https://luarocks.org/manifests/spacewander/luacov-console-1.1.0-1.rockspec";
              hash = "sha256-MaFCmat/p9gt1aRyd5hYvno2QMll0yX0wW0mmjPnOww=";
            }).outPath;
          src = pkgs.fetchFromGitHub {
            owner = "spacewander";
            repo = "luacov-console";
            rev = "1.1";
            hash = "sha256-Ka1Ff6ccLYKDZQYsVEYYREtdCrlZ4PAcGcYRPJX0BTg=";
          };
          propagatedBuildInputs = [
            luacov
            luafilesystem
            argparse
          ];
        };

        luacov-html = buildLuarocksPackage {
          pname = "luacov-html";
          version = "1.0.0-1";
          knownRockspec =
            (pkgs.fetchurl {
              url = "https://luarocks.org/manifests/wesen1/luacov-html-1.0.0-1.rockspec";
              hash = "sha256-PLXtsnK23CNEVjwpiwHpDYONw0nVyIzw/u/IgK6q0UI=";
            }).outPath;
          src = pkgs.fetchFromGitHub {
            owner = "wesen1";
            repo = "luacov-html";
            rev = "v1.0.0";
            hash = "sha256-8VP6V7vSryW6azvmXQYobQnDw4Mh8ujmj7yfwxitvjY=";
          };
          propagatedBuildInputs = [
            classic
            penlight
            luacov
            lua-resty-template
          ];
        };

        luacov-html-wrapper = pkgs.writeShellScriptBin "luacov-html" ''
          #!/usr/bin/env bash
          ${pkgs.luajit}/bin/luajit -e "require('luacov.html')()"
        '';
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = [
            pkgs.luajit
            luacov
            luacov-console
            luacov-html
            luacov-html-wrapper
          ];
        };
      }
    );
}
