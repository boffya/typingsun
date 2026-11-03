#!/bin/bash
# typingsun 一键重新部署脚本
# 用法: ./deploy.sh "这次改了什么"
# 说明: 提交本地改动 -> 推送到 GitHub -> Pages 自动重新构建（约 1-2 分钟）

set -e
cd "$(dirname "$0")"

MSG="${1:-update site $(date '+%Y-%m-%d %H:%M')}"
REPO="boffya/typingsun"
BRANCH="main"

echo "==> 自动更新缓存版本号"
STAMP=$(date '+%Y%m%d%H%M')
python3 - "$STAMP" << 'PY'
import re, sys
v = sys.argv[1]
p = 'index.html'
s = open(p, encoding='utf8').read()
s = re.sub(r'(\?v=)[0-9A-Za-z]+', r'\g<1>' + v, s)
open(p, 'w', encoding='utf8').write(s)
print('  版本号 ->', v)
PY

echo "==> 检查改动"
if git diff --quiet && git diff --cached --quiet && [ -z "$(git ls-files --others --exclude-standard)" ]; then
  echo "没有文件改动，将推送一个空提交来强制重新构建"
  git commit --allow-empty -m "chore: 重新部署 ($(date '+%Y-%m-%d %H:%M'))" -q
else
  git add -A
  git commit -m "$MSG" -q
  echo "已提交: $MSG"
fi

echo "==> 需要 GitHub Token（输入时不显示）"
read -r -s -p "Token: " TOKEN
echo

if [ -z "$TOKEN" ]; then
  echo "未输入 Token，已中止（提交已保存在本地，可稍后再推）"
  exit 1
fi

echo "==> 推送到 $REPO ($BRANCH)"
git push "https://boffya:${TOKEN}@github.com/${REPO}.git" "$BRANCH"
unset TOKEN

echo ""
echo "完成！Pages 正在后台构建，1-2 分钟后访问："
echo "  https://boffya.github.io/typingsun/"
echo "部署状态: https://github.com/boffya/typingsun/deployments"
