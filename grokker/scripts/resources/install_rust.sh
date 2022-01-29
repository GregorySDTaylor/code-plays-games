#!/bin/ash
set -eux

CARGO_DIR=/home/coderunner/.cargo/bin

wget "https://static.rust-lang.org/rustup/archive/1.24.3/x86_64-unknown-linux-musl/rustup-init"
chmod +x rustup-init
./rustup-init -y --no-modify-path --profile minimal --default-toolchain 1.58.1 --default-host "x86_64-unknown-linux-musl"
rm rustup-init
$CARGO_DIR/rustup --version
$CARGO_DIR/cargo --version
$CARGO_DIR/rustc --version