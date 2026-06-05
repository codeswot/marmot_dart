default:
    @just --list

build-rust:
    cd rust && cargo build

generate-bridge:
    flutter_rust_bridge_codegen generate

test-rust:
    cd rust && cargo test --features test-utils

test-flutter:
    flutter test

analyze:
    flutter analyze

check: build-rust test-rust analyze
