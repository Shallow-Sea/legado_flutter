#!/bin/sh
# Rust cargo linker wrapper for iOS device targets (arm64)
exec /usr/bin/xcrun --sdk iphoneos clang -arch arm64 -miphoneos-version-min=13.0 "$@"
