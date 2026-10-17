#!/usr/bin/env bash
# 网页版一键构建: 导出 + 注入居中样式
#   bash tools/build_web.sh
set -e
cd "$(dirname "$0")/.."
GODOT=/Applications/Godot.app/Contents/MacOS/Godot

mkdir -p export/web
"$GODOT" --headless --path . --export-release "Web" export/web/index.html

python3 - <<'EOF'
html_path = "export/web/index.html"
style = open("tools/web_head.html").read()
s = open(html_path).read()
if "weixi-shell" not in s:  # 幂等: 已注入则跳过
    s = s.replace("</head>", style + "\n</head>", 1)
    open(html_path, "w").write(s)
print("居中样式已注入")
EOF
echo "网页版构建完成: export/web/"
