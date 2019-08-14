{ stdenv, lib, buildEnv, makeWrapper, runCommand, fetchurl, zlib, rsync, autoPatchelfHook }:

# rustc and cargo nightly binaries

let
  convertPlatform = system:
    if      system == "i686-linux"    then "i686-unknown-linux-gnu"
    else if system == "x86_64-linux"  then "x86_64-unknown-linux-gnu"
    else if system == "i686-darwin"   then "i686-apple-darwin"
    else if system == "x86_64-darwin" then "x86_64-apple-darwin"
    else abort "no snapshot to bootstrap for this platform (missing target triple)";

  thisSys = convertPlatform stdenv.system;

  defaultDateFile = builtins.fetchurl
    "https://static.rust-lang.org/dist/channel-rust-nightly-date.txt";
  defaultDate = lib.removeSuffix "\n" (builtins.readFile defaultDateFile);

  mkUrl = { pname, archive, date, system }:
    "${archive}/${date}/${pname}-nightly-${system}.tar.gz";

  fetch = args: let
      url = mkUrl { inherit (args) pname archive date system; };
      download = builtins.fetchurl (url + ".sha256");
      contents = builtins.readFile download;
      sha256 = args.hash or (lib.head (lib.strings.splitString " " contents));
    in fetchurl { inherit url sha256; };

  generic = { pname, archive }:
      { date ? defaultDate, system ? thisSys, ... } @ args:
      stdenv.mkDerivation rec {
    name = "${pname}-${version}";
    version = "nightly-${date}";
    preferLocalBuild = true;
    # TODO meta;
    outputs = [ "out" "doc" ];
    src = fetch (args // { inherit pname archive system date; });
    nativeBuildInputs = [ rsync autoPatchelfHook ];
    dontStrip = true;
    installPhase = ''
      rsync --chmod=u+w -r ./*/ $out/
    '';
  };

in rec {
  rustcWithSysroots = { rustc, sysroots ? [] }: buildEnv {
    name = "combined-sysroots";
    paths = [ rustc ] ++ sysroots;
    pathsToLink = [ "/lib" "/share" ];
    #buildInputs = [ makeWrapper ];
    # Can't use wrapper script because of https://github.com/rust-lang/rust/issues/31943
    postBuild = ''
      mkdir -p $out/bin/
      cp ${rustc}/bin/* $out/bin/
    '';
  };

  rust-std = { date ? defaultDate, system ? thisSys, ... } @ args:
      stdenv.mkDerivation rec {
    # Strip install.sh, etc
    pname = "rust-std";
    version = "nightly-${date}";
    name = "${pname}-${version}-${system}";
    src = fetch (args // {
      inherit pname date system;
      archive = "https://static.rust-lang.org/dist";
    });
    installPhase = ''
      mkdir -p $out
      mv ./*/* $out/
      rm $out/manifest.in
    '';
  };

  rust = generic {
    pname = "rust";
    archive = "https://static.rust-lang.org/dist";
  };
}
