#!/bin/bash
set -e

echo "=> 开始清理旧文件..."
rm -rf build Payload zhengqaun_unsigned.ipa

echo "=> 开始构建无签名的 iOS 实体机应用程序集 (.app)..."
# 使用无签名参数强制构建
xcodebuild clean build \
  -workspace zhengqaun.xcworkspace \
  -scheme zhengqaun \
  -configuration Release \
  -sdk iphoneos \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  SYMROOT="$(pwd)/build" \
  | xcpretty || echo "xcodebuild 结束，检查是否成功"

APP_PATH="build/Release-iphoneos/zhengqaun.app"

if [ -d "$APP_PATH" ]; then
    echo "=> .app 产物构建成功，准备清理个人信息..."
    
    # 1. 移除代码签名信息
    rm -rf "$APP_PATH/_CodeSignature"
    rm -f "$APP_PATH/embedded.mobileprovision"
    
    # 2. 移除可能包含电脑/开发者信息的文件
    rm -rf "$APP_PATH/*.dSYM"
    rm -f "$APP_PATH/PkgInfo"
    
    # 3. 从 Info.plist 中移除 Xcode/编译器/平台等构建环境信息
    # 这些字段可能包含本机 Xcode 版本、SDK 路径等
    PLIST="$APP_PATH/Info.plist"
    for key in DTCompiler DTPlatformBuild DTPlatformName DTPlatformVersion \
               DTSDKBuild DTSDKName DTXcode DTXcodeBuild \
               BuildMachineOSBuild; do
        /usr/libexec/PlistBuddy -c "Delete :$key" "$PLIST" 2>/dev/null || true
    done
    echo "   已清理 Info.plist 中的构建环境信息"
    
    # 4. Strip 调试符号（减小体积，去除可能的路径信息）
    if [ -f "$APP_PATH/zhengqaun" ]; then
        strip -x "$APP_PATH/zhengqaun" 2>/dev/null || true
        echo "   已 strip 调试符号"
    fi
    
    # 5. 移除 Frameworks 中的签名和调试符号
    if [ -d "$APP_PATH/Frameworks" ]; then
        find "$APP_PATH/Frameworks" -name "_CodeSignature" -type d -exec rm -rf {} + 2>/dev/null || true
        find "$APP_PATH/Frameworks" -name "*.dSYM" -exec rm -rf {} + 2>/dev/null || true
        echo "   已清理 Frameworks 中的签名和调试信息"
    fi
    
    echo "=> 封装 IPA..."
    mkdir Payload
    cp -r "$APP_PATH" Payload/
    zip -qr zhengqaun_unsigned.ipa Payload
    rm -rf Payload
    echo "=> 打包完毕！产生的文件：zhengqaun_unsigned.ipa"
    echo "=> 文件大小：$(du -h zhengqaun_unsigned.ipa | cut -f1)"
    echo "=> 此 IPA 不含签名、不含电脑/手机/个人信息，可直接交给企业签平台签名"
else
    echo "=> 错误: 构建失败，找不到对应的 .app 目录 ($APP_PATH)"
    exit 1
fi
