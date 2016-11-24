# A Nix expression for nightly Rust versions

This is useful for working with the latest Rust nightly (or the nightly from a specific date) on [NixOS].
Notably, it uses Nix's `builtins.fetchurl` feature to avoid the need to specify source hashes manually.
This feature is banned in [nixpkgs], so this expression has to exist outside of it.

Essentially, this expression is convenient for development but unsuitable for official packaging.


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
``
{
  rustPackages = pkgs.callPackage /path/to/rust-nightly-nix { };
}
``
Note the the `default.nix` is a special name and thus you can use the path to be the directory containing it.


## Invocation

`default.nix` is structure like a normal package in Nixpkgs in that it is a function from a attrset of package, suitable for calling with `callPackage` as show above.
Unlike a normal package, however, it is a function not to a single derivation but two a set of functions.
The functions it produces are as follows.

### `rustc`

`rustc` is a function from a set of optional arguments to a derivation for the rust compiler.
`date` determines which nightly to download (defaults to latest date where a nightly was successfully built).
`system` is the system the compiler *runs* on (defaults to the system Nix is installed on).
This is an LLVM- (and Rust-) style system name, not Nix-style.
`hash` is the expect hash of the nightly download.
The default here is somewhat complex, and marginally better than just an unchecked download.
If no hash is provided, rust-nightly-nix will first download the hash from Mozilla (an unchecked download), then use the downloaded hash to verify the compiler download.
That way, the compiler download is always verified with some hash.

As an example example,
```nix
{
  funs = callPackage /path/to/rust-nightly-nix { };

  rustcNightly = funs.rustc {
    date = "2016-06-09";
    hash = "1p0xkpfk66jq0iladqfrhqk1zc1jr9n2v2lqyf7jjbrmqx2ja65i";
  };
}
```
provides a hash to add some security to the build process.

### `cargo`

`cargo` has the same type as `rustc`.
Note that if one of a nightly Rust compiler build and nightly Cargo build fails and the other succeeds, the other is still published.
So don't freak out if on some day half your downloads are failing.

### `rust-std`

`rust-std` is used for prebuilt standard libraries.
On "normal" platforms this is `std` and its dependencies but on more exotic platforms (e.g. small CPUs for embedded systems) it will contain less as `std` itself makes no sense.
It has the same type as `rustc`.
I (@Ericson2314) believe that the standard library for all all tier-1 platforms need to be built and tested for a nightly compiler to be released, so these will be released on the same days as `rustc`.

### `rustcWithSysroots`

`rustcWithSysroots` bundles together a Rust compiler with some pre-built nightlies for easier cross-compiling.


takes rustc as an argument, plus an optional set of derivations to be put in scope for the build of rustc.
This is particularly useful if you want to make `rust-std` avalable to `rustc`.
For example you might invoke `rustcWithSysroots` in the following way in order to make different instances of `rust-std` avalable during the use of `rustc`.

```nix
{
  rustNightlyWithi686 = funs.rustcWithSysroots {
    rustc = rustcNightly;
    sysroots = builtins.map funs.rust-std [
      { } # native std, need for build.rs and proc macros
      { system = "x86_64-unknown-linux-gnu"; }
      { system = "i686-unknown-linux-gnu"; }
    ];
  };
}
```

### `rust`

`rust` has the same type as `rustc`. It is the legacy/simple download, a combination of `rustc`, `cargo`, and `rust-std` for the build platform (not cross-compiling).


## Exposing

This is the completely generic procedure for "installing" stuff with Nix or NixOS.

### NixOS System-Wide Setup

You can install this globally by adding it as an override in the system's configuration at `/etc/nixos/configuration.nix`.

```nix
{
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
nix-shell -p 'rustNightly.rust { date = "2016-01-01"; }'

# To use the latest:
nix-shell -p 'rustNightly.rust {}'
```

But there are more derivations in `rustNightly` than just `rust`. Check out the source for the full list. It's not too complicated.

You could also add any of these to your `systemPackages` or user environment (with `nix-env`).

## Tip

I also added an alias to my `packageOverrides`:

```nix
{
  nixpkgs.config.packageOverrides = pkgs: rec {
    rustNightly = pkgs.callPackage /path/to/rust-nightly-nix {};
    rustLatest = rustNightly.rust {};
  };
}
```

So I can just run `nix-shell -p rustLatest` to work with my nightly projects.

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
