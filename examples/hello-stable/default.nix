#
# File ${RUST_NIGHTLY_NIX_HOME}/examples/hello-stable/default.nix
#
# A hello-world rust project using rust-nightly-nix to manage
# rust and cargo.
#
# note that in this file `/path/to/rust-nightly.nix` is
# `../../default.nix`

with import <nixpkgs> {};

let rustStableFuns = pkgs.callPackage ../../default.nix {
        stableVersion = "1.13.0";
    };
    rust = rustStableFuns.rust {};
    deps = [ rust ];
    packageName = "hello-stable";
in {
  helloStableEnv = stdenv.mkDerivation {
      name = packageName;
      buildInputs = [ stdenv ] ++ deps;
  };
}
 
