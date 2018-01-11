# A Nix expression for nightly Rust versions

This project is used for using Rust nightlies on [NixOS].
You can use this to download Rust nightlies, either the latest or any specified date, easily.
This is the closest to Rustup as we can get right now, while still using Nix's features.

## Obtaining

You can fetch the whole repo and use it with something like:
```nix
{
  rustNightlyNixRepo = pkgs.fetchFromGitHub {
    owner = "solson";
    repo = "rust-nightly-nix";
    rev = "9e09d579431940367c1f6de9463944eef66de1d4";
    sha256 = "03zkjnzd13142yla52aqmgbbnmws7q8kn1l5nqaly22j31f125xy";
  };

  rustPackages = pkgs.callPackage rustNightlyNixRepo { };
}
```

Or you can just download `default.nix` file onto your system somewhere, and do:
```nix
{
  rustPackages = pkgs.callPackage /path/to/rust-nightly-nix { };
}
```
Note the the `default.nix` is a special name and thus you can use the path to be the directory containing it.


## Invocation

`rust-nightly-nix/default.nix` is structured like a normal package in [nixpkgs] in that it is a function from a attrset of package, suitable for calling with `callPackage` as show above.
Unlike most Nixpkgs packages, however, `rust-nightly-nix/default.nix` is a function to a set of functions, not just a single derivation.
The functions it produces are as follows.

### `rustc`

`rustc` is a function from a set of optional arguments to a derivation for the rust compiler.

* `date` determines which nightly to download; defaults to latest date where a nightly was successfully built.
* `system` is the system the compiler *runs* on; defaults to the system Nix is installed on.
  This is an LLVM- (and Rust-) style system name, not Nix-style.
* `hash` is the expect hash of the nightly download.
   If no hash is provided, rust-nightly-nix will first download the hash from Mozilla, which is an unchecked download, and then use the downloaded hash to verify the compiler download.
   This way, the compiler download is always verified with some hash.

#### Example Usage

Build a nightly for June 9th, 2016.

```nix
{
  rustPackages = callPackage /path/to/rust-nightly-nix { };

  rustcNightly2016-06-09 = rustPackages.rustc {
    date = "2016-06-09";
    hash = "1p0xkpfk66jq0iladqfrhqk1zc1jr9n2v2lqyf7jjbrmqx2ja65i";
  };
}
```

### `cargo`

`cargo` has the same imput as `rustc`, but returns a derivation for Cargo.

Note that if either the Rust or Cargo nightly build fails, the other is still published.
Don't freak out if on some days half of your downloads are failing.

### `rust-std`

`rust-std` is used for pre-built standard libraries.

`rust-std` has the same imput as `rustc`.

On "normal" platforms this is `std` and its dependencies, but on more exotic platforms (e.g. small CPUs for embedded systems) it will contain less as `std` itself makes no sense.

I (@Ericson2314) believe that the standard library for all all tier-1 platforms need to be built and tested for a nightly compiler to be released, so these will be released on the same days as `rustc`.

### `rustcWithSysroots`

`rustcWithSysroots` is a function that takes a set and returns a derivation.

* rustc - A rustc derivation
* sysroots - An optional set of derivations to be put in scope for the rustc build; defaults to an empty set.

It bundles together a Rust compiler with some pre-built nightlies for easier cross-compiling.
This bundling is particularly useful if you want to make multiple `rust-std` avalable to `rustc`.

#### Example

For example you might invoke `rustcWithSysroots` in the following way in order to make different instances of `rust-std` avalable during the use of `rustc`.

```nix
{
  rustNightlyWithi686 = rustPackages.rustcWithSysroots {
    rustc = rustPackages.rustc {};
    sysroots = map rustPackages.rust-std [
      { } # native std, need for build.rs and procedural macros
      { system = "x86_64-unknown-linux-gnu"; }
      { system = "i686-unknown-linux-gnu"; }
    ];
  };
}
```

### `rust`

`rust` has the same type as `rustc`.

It is the legacy/simple download, a combination of `rustc`, `cargo`, and `rust-std` for the build platform (not cross-compiling).

## Exposing

This is the completely generic procedure for "installing" stuff with Nix or NixOS.

### NixOS System-Wide Setup

You can install this globally by adding it as an override in the system's configuration at `/etc/nixos/configuration.nix`.

```nix
{
  # Rest of your configuration file here.

  nixpkgs.config.packageOverrides = pkgs: {
    rustNightly = pkgs.callPackage /path/to/rust-nightly-nix {};
  };
}
```

### Nix User-Specific Setup

You can also set this up specifically for a single user by adding it to that user's nix configuration, located at `$HOME/.nixpkgs/config.nix`.

```nix
{
  packageOverrides = pkgs: {
    rustNightly = pkgs.callPackage /path/to/rust-nightly-nix {};
  };
}
```

### Examples

Once you're set up, you should be able to run something like:

```sh
# To use a specific date:
nix-shell -p 'rustNightly.rust { date = "2016-06-09"; }'

# To use the latest:
nix-shell -p 'rustNightly.rust {}'
```

You could also add any of these to your `systemPackages` or user environment (with `nix-env`).

## Aliasing Tip

You can also add an alias to your `packageOverrides`:

```nix
{
  nixpkgs.config.packageOverrides = pkgs: rec {
    rustNightly = pkgs.callPackage /path/to/rust-nightly-nix {};
    rustLatest = rustNightly.rust {};
  };
}
```

Then, you can run `nix-shell -p rustLatest` to work on nightly projects.

## Compile with musl

```nix
{
  rustPackages = pkgs.callPackage rustNightlyNixRepo { };

  cargoNightly = rustPackages.cargo { date = "2016-11-09"; };
  rustcNightly = rustPackages.rustc {};

  rustNightly = rustPackages.rustcWithSysroots {
    rustc = rustcNightly;
    sysroots = [
      (rustPackages.rust-std { })
      (rustPackages.rust-std { system = "x86_64-unknown-linux-musl"; })
    ];
  };
}
```

Now you can build `cargo build --target x86_64-unknown-linux-musl` :)
Note: of course the `musl` package needs to be installed too ;-)

## Why not in Nixpkgs

Rust Nightly Nix uses Nix's `builtins.fetchurl` feature to avoid the need to specify source hashes manually.
This feature is banned in [nixpkgs], so this expression has to exist outside of it.
That means that this expression is convenient for development but unsuitable for official packaging.

## License

Licensed under either of
  * Apache License, Version 2.0 ([LICENSE-APACHE](LICENSE-APACHE) or
    http://www.apache.org/licenses/LICENSE-2.0)
  * MIT license ([LICENSE-MIT](LICENSE-MIT) or
    http://opensource.org/licenses/MIT) at your option.

### Contribution

Unless you explicitly state otherwise, any contribution intentionally submitted for inclusion in the work by you shall be dual licensed as above, without any additional terms or conditions.


[NixOS]: http://nixos.org/
[nixpkgs]: https://github.com/NixOS/nixpkgs
