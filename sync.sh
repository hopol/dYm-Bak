#!/usr/bin/env bash
# 手动镜像 Everless321/dYm 的 main 分支。
set -euo pipefail

UPSTREAM_URL="https://github.com/Everless321/dYm.git"
UPSTREAM_WEB_URL="https://github.com/Everless321/dYm"
UPSTREAM_BRANCH="main"
MIRROR_REPO="https://github.com/hopol/dYm-Bak"

command -v git >/dev/null 2>&1 || { echo "错误：未找到 git，请先安装 Git。" >&2; exit 1; }
if ! git remote get-url origin >/dev/null 2>&1; then
  echo "错误：当前目录不是已配置 origin 的 Git 仓库。" >&2
  exit 1
fi
if ! git remote get-url upstream >/dev/null 2>&1; then
  git remote add upstream "$UPSTREAM_URL"
fi

git fetch upstream "$UPSTREAM_BRANCH" --tags
UPSTREAM_COMMIT="$(git rev-parse "upstream/$UPSTREAM_BRANCH")"
OLD_COMMIT="$(git show HEAD:upstream/.sync-info 2>/dev/null | sed -n 's/^commit=//p' | head -n 1 || true)"
if [[ "$UPSTREAM_COMMIT" == "$OLD_COMMIT" ]]; then
  echo "上游 $UPSTREAM_BRANCH 分支没有新提交，无需同步。"
  exit 0
fi

rm -rf upstream
mkdir -p upstream
git archive --format=tar "upstream/$UPSTREAM_BRANCH" | tar -x -C upstream
VERSION="$(sed -n 's/.*\"version\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p' upstream/package.json | head -n 1)"
SOURCE_VALUE="${VERSION:-unknown}"
SOURCE_FIELD="version"
SYNC_TIME="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
SHORT_COMMIT="${UPSTREAM_COMMIT:0:7}"

cat > upstream/.sync-info <<EOF
commit=$UPSTREAM_COMMIT
timestamp=$SYNC_TIME
upstream_url=$UPSTREAM_WEB_URL
upstream_branch=$UPSTREAM_BRANCH
version=$SOURCE_VALUE
EOF

git add upstream
git commit -m "chore: mirror dYm-Bak source $SOURCE_VALUE ($SHORT_COMMIT)"
git tag -a "mirror-source-v$SOURCE_VALUE-$SHORT_COMMIT" -m "Mirror dYm-Bak source $SOURCE_VALUE ($SHORT_COMMIT)"
git push origin HEAD
git push origin "mirror-source-v$SOURCE_VALUE-$SHORT_COMMIT"
echo "已同步 dYm-Bak $UPSTREAM_BRANCH：$UPSTREAM_COMMIT"
