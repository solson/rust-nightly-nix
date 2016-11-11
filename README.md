# A Nix expression for nightly Rust versions

This is useful for working with the latest Rust nightly (or the nightly from a
specific date) on [NixOS]. Notably, it uses Nix's `builtins.fetchurl` feature to
avoid the need to specify source hashes manually. This feature is banned in
[nixpkgs], so this expression has to exist outside of it.

Essentially, this expression is convenient for development but unsuitable for
official packaging.

## Usage

### Setup

Download `default.nix` file onto your system somewhere. The location of that
file is your `/path/to/rust-nightly-nix`. It doesn't have to be called
`default.nix` unless you want the path to be the directory containing it.

#### NixOS System Setup

You can install this globally by adding it as an override in the system's
configuration at `/etc/nixos/configuration.nix`.

```nix
{
  nixpkgs.config.packageOverrides = pkgs: {
    rustNightly = pkgs.callPackage /path/to/rust-nightly-nix {};
  };
}
```

Alternatively you can define this repo directy within your `configuration.nix`:

```nix
rustNightlyNixRepo = pkgs.fetchFromGitHub {
   owner = "solson";
   repo = "rust-nightly-nix";
   rev = "9e09d579431940367c1f6de9463944eef66de1d4";
   sha256 = "03zkjnzd13142yla52aqmgbbnmws7q8kn1l5nqaly22j31f125xy";
};

rustPackages = pkgs.callPackage rustNightlyNixRepo { };
```

#### Local User Setup

You can also set this up specifically for a single user by adding it to that
user's nix configuration, located at `$HOME/.nixpkgs/config.nix`.

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

But there are more derivations in `rustNightly` than just `rust`. Check out the
source for the full list. It's not too complicated.

You could also add any of these to your `systemPackages` or user environment
(with `nix-env`).

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

Unless you explicitly state otherwise, any contribution intentionally submitted
for inclusion in the work by you shall be dual licensed as above, without any
additional terms or conditions.


[NixOS]: http://nixos.org/
[nixpkgs]: https://github.com/NixOS/nixpkgs
