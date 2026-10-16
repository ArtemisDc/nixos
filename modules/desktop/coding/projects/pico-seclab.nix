{ config, pkgs, ... }:
let
  openocd-rpi = pkgs.openocd.overrideAttrs (old: {
    src = pkgs.fetchFromGitHub {
      owner = "raspberrypi";
      repo = "openocd";
      rev = "sdk-2.2.0";
      sha256 = "sha256-WoGPHuOM+VcMvm+H4g7AKfladgYcPxBa9ix2uCZm29s=";
      fetchSubmodules = true;
    };
    nativeBuildInputs = old.nativeBuildInputs ++ [
      pkgs.autoreconfHook
      pkgs.libtool
      pkgs.which
    ];
    preConfigure = ''
      sed -i 's/git submodule.*//g' bootstrap
      ./bootstrap
    '';
  });
riscv32-seclab-elf = pkgs.stdenv.mkDerivation {
  name = "riscv32-seclab-elf";
  version = "v79e1e82a";

  src = pkgs.stdenv.mkDerivation {
    name = "riscv32-seclab-elf-src";
    outputHashAlgo = "sha256";
    outputHash = "sha256-ooNmNhNqE3qMT8sgSiswVpHqaMBcbrKgh6AUH797Sfo=";
    outputHashMode = "flat";

    impureEnvVars = [ "GITLAB_TOKEN" ];
    nativeBuildInputs = [ pkgs.curl pkgs.cacert ];

    buildCommand = ''
      token=$(cat /etc/secrets/gitlab-token)
      curl -fL \
        -H "PRIVATE-TOKEN: $token" \
        "https://git.tu-berlin.de/api/v4/projects/50662/packages/generic/toolchain/79e1e82a/riscv32-seclab-elf.tar.gz" \
        -o $out
    '';
  };

  nativeBuildInputs = [ pkgs.autoPatchelfHook ];
  buildInputs = [ pkgs.stdenv.cc.cc.lib pkgs.zlib ];

  dontBuild = true;
  dontConfigure = true;

  unpackPhase = ''
    tar -xzf $src
    sourceRoot=$(ls -d */ | head -1)  # whatever directory the tarball extracts to
  '';
  installPhase = ''
    mkdir -p $out
    chmod -R u+w .
    rm -f lib/bfd-plugins/liblto_plugin
    cp -r . $out/
'';
};
in {
  nix.settings.extra-sandbox-paths = [ "/etc/secrets/gitlab-token" ];
  environment.systemPackages = [ 
    riscv32-seclab-elf
    openocd-rpi
    pkgs.pico-sdk
    pkgs.python315
    pkgs.xxd
    pkgs.mklittlefs
  ];
  environment.variables.PICO_SDK_PATH = "${pkgs.pico-sdk}/lib/pico-sdk";
}
