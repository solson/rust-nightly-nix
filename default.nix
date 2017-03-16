{ stdenv, lib, buildEnv, makeWrapper, runCommand, fetchurl, zlib, rsync, curl }:

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

  dispatchUrl = { pname, archive, channel, system }: channelArgs: ({ # Switch
    nightly = { date ? defaultDate }: {
      url = "${archive}/${date}/${pname}-nightly-${system}.tar.gz";
      version = "nightly-${date}";
    };
    stable = { version }: {
      url = "${archive}/${pname}-${version}-${system}.tar.gz";
      version = "stable-${version}";
    };
  }.${channel}) channelArgs;

  dispatchFetch = { pname, archive }: args: rec {
    inherit (args) channel;
    system = args.system or thisSys;
    inherit (dispatchUrl
        { inherit pname archive channel system; }
        (builtins.removeAttrs args [ "channel" "system" "sha256" ]))
      url version;
    sha256 = let
        download = builtins.fetchurl (url + ".sha256");
        contents = builtins.readFile download;
      in args.sha256 or (lib.head (lib.strings.splitString " " contents));
    src = fetchurl { inherit url sha256; };
  };

  generic = { pname, archive, exes }: args: patchBin {
    inherit pname exes;
    inherit (dispatchFetch { inherit pname archive; } args) version src;
  };

  patchBin = { pname, version, src, exes }: stdenv.mkDerivation rec {
    name = "${pname}-${version}";
    inherit version src;
    # TODO meta;
    outputs = [ "out" "doc" ];
    nativeBuildInputs = [ rsync ];
    dontStrip = true;
    installPhase = ''
      rsync --chmod=u+w -r ./*/ $out/
    '';
    preFixup = if stdenv.isLinux then let
      # it's overkill, but fixup will prune
      rpath = "$out/lib:" + lib.makeLibraryPath [ zlib stdenv.cc.cc.lib curl ];
    in ''
      for executable in ${lib.concatStringsSep " " exes}; do
        patchelf \
          --interpreter "$(< $NIX_CC/nix-support/dynamic-linker)" \
          --set-rpath "${rpath}" \
          "$out/bin/$executable"
      done
      for library in $out/lib/*.so; do
        patchelf --set-rpath "${rpath}" "$library"
      done
    '' else "";
  };

in rec {
  rustc = generic {
    pname = "rustc";
    archive = "https://static.rust-lang.org/dist";
    exes = [ "rustc" "rustdoc" ];
  };

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

  rust-std = args: let
      pname = "rust-std";
      inherit (dispatchFetch {
        inherit pname;
        archive = "https://static.rust-lang.org/dist";
      } args) url system version src;
    in stdenv.mkDerivation rec {
      # Strip install.sh, etc
      inherit pname version src;
      name = "${pname}-${version}-${system}";
      installPhase = ''
        mkdir -p $out
        mv ./*/* $out/
        rm $out/manifest.in
      '';
    };

  cargo = generic {
    pname = "cargo";
    archive = "https://static.rust-lang.org/dist";
    exes = [ "cargo" ];
  };

  rust = generic {
    pname = "rust";
    archive = "https://static.rust-lang.org/dist";
    exes = [ "rustc" "rustdoc" "cargo" ];
  };
}
