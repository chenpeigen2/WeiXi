#!/usr/bin/env bash
# deb 安装包构建: bash tools/build_deb.sh
# 前置: 先导出 Linux 版(bash 里 godot --export-release "Linux")
set -e
cd "$(dirname "$0")/.."

VERSION="0.1.0"
PKG="weixi_${VERSION}_amd64"
STAGING="export/linux/deb-staging/${PKG}"

rm -rf "$STAGING"
mkdir -p "$STAGING/DEBIAN" \
         "$STAGING/usr/games" \
         "$STAGING/usr/bin" \
         "$STAGING/usr/share/applications" \
         "$STAGING/usr/share/icons/hicolor/256x256/apps"

# 游戏本体
cp export/linux/weixi.x86_64 "$STAGING/usr/games/"
cp export/linux/weixi.pck "$STAGING/usr/games/"
chmod 755 "$STAGING/usr/games/weixi.x86_64"

# 启动器
cat > "$STAGING/usr/bin/weixi" <<'EOF'
#!/bin/sh
exec /usr/games/weixi.x86_64 "$@"
EOF
chmod 755 "$STAGING/usr/bin/weixi"

# control 元数据
cat > "$STAGING/DEBIAN/control" <<EOF
Package: weixi
Version: ${VERSION}
Section: games
Priority: optional
Architecture: amd64
Maintainer: chenpeigen <chenpeigen@xiaomi.com>
Description: 玩不死的泡泡龙 (WeiXi) - bubble shooter + match3 fusion
 永不失败的糖果泡泡龙: 射击消除 + 三消互换 + 自由换色, 打满自动掉落。
EOF

# 桌面快捷方式
cat > "$STAGING/usr/share/applications/weixi.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=WeiXi
Name[zh_CN]=玩不死的泡泡龙
Comment=玩不死的糖果泡泡龙
Exec=/usr/games/weixi.x86_64
Icon=weixi
Terminal=false
Categories=Game;
EOF

# 图标 256x256
sips -s format png --resampleWidth 256 icon.png --out "$STAGING/usr/share/icons/hicolor/256x256/apps/weixi.png" >/dev/null

dpkg-deb --build --root-owner-group "$STAGING"
mv "${STAGING}.deb" "export/${PKG}.deb"
echo "deb 构建完成: export/${PKG}.deb"
