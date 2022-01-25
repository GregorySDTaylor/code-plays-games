#!/bin/ash
set -eux

export RUSTUP_HOME=/usr/local/rustup \
export CARGO_HOME=/usr/local/cargo \
export PATH=/usr/local/cargo/bin:$PATH \
export RUST_VERSION=1.58.1

apk add --no-cache gcc
wget "https://static.rust-lang.org/rustup/archive/1.24.3/x86_64-unknown-linux-musl/rustup-init"
chmod +x rustup-init
./rustup-init -y --no-modify-path --profile minimal --default-toolchain $RUST_VERSION --default-host "x86_64-unknown-linux-musl"
rm rustup-init
chmod -R a+w $RUSTUP_HOME $CARGO_HOME
rustup --version
cargo --version
rustc --version