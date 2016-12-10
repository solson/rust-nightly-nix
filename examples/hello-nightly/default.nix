#
# File ${RUST_NIGHTLY_NIX_HOME}/examples/hello-nightly/default.nix
#
# A hello-world rust project using rust-nightly-nix to manage
# rust and cargo.
#
# note that in this file `/path/to/rust-nightly.nix` is
# `../../default.nix`

with import <nixpkgs> {};

let rustNightlyFuns = pkgs.callPackage ../../default.nix {};
    rust = rustNightlyFuns.rust {};
    deps = [ rust ];
    packageName = "hello-nightly";
in {
  helloNightlyEnv = stdenv.mkDerivation {
      name = packageName;
      buildInputs = [ stdenv ] ++ deps;
  };
}
 
