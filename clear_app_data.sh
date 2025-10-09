#!/bin/bash

echo "正在清除 Device Player 应用数据..."

# 应用包名
APP_ID="com.strong.devicePlayer"

# 清除应用支持目录
APP_SUPPORT_PATH="$HOME/Library/Application Support/$APP_ID"
if [ -d "$APP_SUPPORT_PATH" ]; then
    echo "删除应用支持目录: $APP_SUPPORT_PATH"
    rm -rf "$APP_SUPPORT_PATH"
fi

# 清除用户偏好设置
PREFERENCES_PATH="$HOME/Library/Preferences/$APP_ID.plist"
if [ -f "$PREFERENCES_PATH" ]; then
    echo "删除用户偏好设置: $PREFERENCES_PATH"
    rm -f "$PREFERENCES_PATH"
fi

# 清除缓存
CACHE_PATH="$HOME/Library/Caches/$APP_ID"
if [ -d "$CACHE_PATH" ]; then
    echo "删除缓存目录: $CACHE_PATH"
    rm -rf "$CACHE_PATH"
fi

# 清除临时文件
TEMP_SCRCPY="/tmp/scrcpy"
if [ -d "$TEMP_SCRCPY" ]; then
    echo "删除临时 scrcpy 目录: $TEMP_SCRCPY"
    rm -rf "$TEMP_SCRCPY"
fi

TEMP_PLATFORM_TOOLS="/tmp/platform-tools"
if [ -d "$TEMP_PLATFORM_TOOLS" ]; then
    echo "删除临时 platform-tools 目录: $TEMP_PLATFORM_TOOLS"
    rm -rf "$TEMP_PLATFORM_TOOLS"
fi

echo "应用数据清除完成！"
echo ""
echo "已清除的目录："
echo "- 应用支持目录"
echo "- 用户偏好设置"
echo "- 缓存目录"
echo "- 临时文件"
echo ""
echo "现在可以重新运行应用了。"

