#!/usr/bin/env bash
# legado_flutter iOS Debug 构建脚本
# 用法: bash build_ios_debug.sh [simulator]
#   - 不带参数: 构建真机 Debug 版本并尝试启动到连接的 iOS 设备
#   - simulator: 构建模拟器 Debug 版本

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=== iOS Debug Build ==="

# 检测 Rust 工具链
if ! command -v cargo &>/dev/null; then
    if [ -f "$HOME/.cargo/env" ]; then
        source "$HOME/.cargo/env"
    else
        echo "Error: cargo not found. Install Rust via: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
        exit 1
    fi
fi

# 选择目标架构
BUILD_TARGET=""
BUILD_MODE=""

if [ "${1:-}" = "simulator" ]; then
    BUILD_TARGET="x86_64-apple-ios"
    BUILD_MODE="simulator"
    echo "Target: $BUILD_TARGET (simulator)"
else
    BUILD_TARGET="aarch64-apple-ios"
    BUILD_MODE="device"
    echo "Target: $BUILD_TARGET (device)"
fi

# 编译 Rust 桥接库
echo ""
echo ">>> Compiling Rust bridge library for $BUILD_TARGET..."
cd core
IPHONEOS_DEPLOYMENT_TARGET=13.0 cargo build -p bridge --target "$BUILD_TARGET" --release
cd ..

# 复制库到 iOS 框架目录（统一命名为 libbridge.a）
echo ""
echo ">>> Copying Rust library to iOS framework..."
mkdir -p flutter_app/ios/Frameworks
cp "core/target/$BUILD_TARGET/release/libbridge.a" \
   flutter_app/ios/Frameworks/libbridge.a
echo "Copied: flutter_app/ios/Frameworks/libbridge.a ($(du -h flutter_app/ios/Frameworks/libbridge.a | cut -f1))"

# 安装 Pod 依赖
echo ""
echo ">>> Installing CocoaPods dependencies..."
cd flutter_app/ios
pod install
cd "$SCRIPT_DIR"

# 构建 Flutter iOS
echo ""
echo ">>> Building Flutter for iOS ($BUILD_MODE)..."
cd flutter_app

if [ "$BUILD_MODE" = "simulator" ]; then
    flutter build ios --debug --simulator
else
    flutter build ios --debug --no-codesign
fi

cd "$SCRIPT_DIR"

echo ""
echo "=== iOS Debug Build Complete ==="
echo "Output: flutter_app/build/ios/"
