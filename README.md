# A Nix expression for nightly Rust versions

This is useful for working with the latest Rust nightly (or the nightly from a
specific date) on [NixOS]. Notably, it uses Nix's `builtins.fetchurl` feature to
avoid the need to specify source hashes manually. This feature is banned in
[nixpkgs], so this expression has to exist outside of it.

Essentially, this expression is convenient for development but unsuitable for
official packaging.

## Usage

### Setup

The way I use the expression is to have something like the following in my NixOS
system config:

```nix
{
  nixpkgs.config.packageOverrides = pkgs: {
    rustNightly = pkgs.callPackage ./rust-nightly.nix {};
  };
}
```

In reality, my package overrides are split across multiple files, since I have
more than just this one, but the idea is the same. It should also be possible to
set this up with a user-local nixpkgs config.

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
    rustNightly = pkgs.callPackage ./rust-nightly.nix {};
    rustLatest = rustNightly.rust {};
  };
}
```

So I can just run `nix-shell -p rustLatest` to work with my nightly projects.


[NixOS]: http://nixos.org/
[nixpkgs]: https://github.com/NixOS/nixpkgs
