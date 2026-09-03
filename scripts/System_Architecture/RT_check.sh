#!/usr/bin/env bash
# 薄包装脚本：对应产出文档 output/System_Architecture/RT/RT.md 的范围校验入口。
#
# 规则7"范围交叉一致性"天然是跨文档检查(A的排除要在B的覆盖里对上号)，
# 物理上没法真正拆成34个互相独立、各管一篇的脚本；这里只是调用全局脚本
# scripts/check_scope_links.sh，把输出过滤到本主题相关的行，方便按主题排查。
# 背景见 ../../Scope_Section_Design.md。
#
# 用法: scripts/System_Architecture/RT_check.sh

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TOPIC_FILE="RT.md"

out="$("$REPO_ROOT/scripts/check_scope_links.sh" 2>&1 || true)"
filtered="$(printf '%s\n' "$out" | grep -F "$TOPIC_FILE" || true)"

if [ -z "$filtered" ]; then
  echo "[output/System_Architecture/RT/RT.md] 未在全局校验输出中被提及(可能已合规，也可能是本主题目前还没有《对比范围》节——不能替代人工确认)"
  exit 0
fi

printf '%s\n' "$filtered"

if printf '%s\n' "$filtered" | grep -qE '^\[(缺节|悬空引用)\]'; then
  exit 1
fi
exit 0
