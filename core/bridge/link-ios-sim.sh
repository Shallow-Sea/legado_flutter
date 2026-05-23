#!/bin/sh
# Rust cargo linker wrapper for iOS Simulator targets
# Links against iOS Simulator SDK with proper flags
exec /usr/bin/xcrun --sdk iphonesimulator clang \
    "$@"
