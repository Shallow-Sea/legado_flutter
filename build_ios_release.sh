#!/usr/bin/env bash
# legado_flutter iOS Release 构建脚本
# 用法: bash build_ios_release.sh
# 前置条件:
#   - Git 工作区干净
#   - 有效的 Apple Developer 证书和 Provisioning Profile
# 输出: dist/legado-arm64-release-v{VERSION}-{COMMIT}.ipa

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=== iOS Release Build ==="

# 检查 Git 状态
if ! git diff --quiet HEAD 2>/dev/null; then
    echo "Error: Git working tree is not clean. Commit or stash changes first."
    exit 1
fi

# 获取版本信息
VERSION=$(grep 'version:' flutter_app/pubspec.yaml | head -1 | awk '{print $2}' | tr -d " '")
COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "nogit")
echo "Version: $VERSION (commit $COMMIT)"

# 检测 Rust 工具链
if ! command -v cargo &>/dev/null; then
    if [ -f "$HOME/.cargo/env" ]; then
        source "$HOME/.cargo/env"
    else
        echo "Error: cargo not found"
        exit 1
    fi
fi

# 运行 Flutter 分析
echo ""
echo ">>> Running Flutter analyze..."
cd flutter_app
flutter analyze --no-fatal-infos --no-fatal-warnings
cd "$SCRIPT_DIR"

# 运行测试
echo ""
echo ">>> Running tests..."
cd flutter_app
flutter test
cd "$SCRIPT_DIR"

# 编译 Rust 桥接库（设备目标）
echo ""
echo ">>> Compiling Rust bridge library for aarch64-apple-ios..."
cd core
cargo build -p bridge --target aarch64-apple-ios --release
cd ..

# 复制库
echo ""
echo ">>> Copying Rust library..."
mkdir -p flutter_app/ios/Frameworks
cp core/target/aarch64-apple-ios/release/libbridge.a \
   flutter_app/ios/Frameworks/libbridge.a

# 安装 Pod 依赖
echo ""
echo ">>> Installing CocoaPods dependencies..."
cd flutter_app/ios
pod install
cd "$SCRIPT_DIR"

# 构建 Flutter IPA
echo ""
echo ">>> Building Flutter IPA..."
cd flutter_app
flutter build ipa --release \
    --export-options-plist ios/export_options_release.plist
cd "$SCRIPT_DIR"

# 复制 IPA 到 dist/
echo ""
echo ">>> Copying IPA to dist/..."
mkdir -p dist
IPA_PATH="flutter_app/build/ios/ipa/Legado_Flutter.ipa"
if [ -f "$IPA_PATH" ]; then
    DIST_NAME="legado-arm64-release-v${VERSION}-${COMMIT}.ipa"
    cp "$IPA_PATH" "dist/$DIST_NAME"
    echo "Copied: dist/$DIST_NAME"

    # 生成 SHA256
    shasum -a 256 "dist/$DIST_NAME" > "dist/$DIST_NAME.sha256"
    echo "SHA256: $(cat dist/$DIST_NAME.sha256)"
fi

echo ""
echo "=== iOS Release Build Complete ==="
ls -lh dist/ 2>/dev/null || true
