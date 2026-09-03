#!/usr/bin/env bash
# Methodology.md 规则7"范围交叉一致性"的辅助校验脚本。
#
# 检查每篇主题文档《对比范围》节里"明确排除"指向的目标文档：
#   1. 目标文档是否存在（悬空引用 —— 硬性错误，导致脚本以非0退出）
#   2. 目标文档的"覆盖"字段里是否能找到排除项的关键字（字符串级别粗检查，
#      不匹配只打印警告，不算硬性错误——不能替代人工判断措辞是否准确）
#
# 用法: scripts/check_scope_links.sh

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

fail=0
warn=0

mapfile -t docs < <(
  find output/System_Architecture output/Boot_Architecture output/Build_Architecture output/Code_Composition output/Platform_Features -mindepth 1 -maxdepth 2 -name '*.md' -print | \
  awk -F/ '
    NF == 3 { print; next }                                   # output/<分类>/<主题>.md
    NF == 4 {                                                  # output/<分类>/<主题目录>/<file>.md
      parentdir = $3; fname = $4; sub(/\.md$/, "", fname)
      if (fname == parentdir) print                            # 只认basename与父目录同名的文件为主题文档,docs/等子目录下的文件不算
    }
  ' | sort
)

declare -A doc_by_basename
for d in "${docs[@]}"; do
  doc_by_basename["$(basename "$d")"]="$d"
done

# 提取指定文件里 "## $2" 到下一个 "## " 之间的内容
extract_section() {
  local file="$1" heading="$2"
  awk -v start="^## ${heading}" '
    $0 ~ start {flag=1; next}
    /^## / && flag {exit}
    flag {print}
  ' "$file" 2>/dev/null
}

# 提取范围节里指定子字段(如"覆盖"/"明确排除")的内容——字段值可能跟在
# "**字段名**："同一行,也可能作为下面的子bullet列出到下一个"- **"字段为止
extract_field() {
  local text="$1" field="$2"
  printf '%s\n' "$text" | awk -v f="\\*\\*${field}\\*\\*" -v pat="^.*${field}\\*\\*[：:]?[[:space:]]*" '
    $0 ~ f {
      flag=1
      line=$0
      sub(pat, "", line)
      if (line != "") print line
      next
    }
    /^- \*\*/ && flag {exit}
    flag {print}
  ' 2>/dev/null
}

for d in "${docs[@]}"; do
  scope="$(extract_section "$d" "对比范围")"
  if [ -z "$scope" ]; then
    echo "[缺节] $d 没有《对比范围》节（回填前的存量文档会正常触发，回填完成后不应再出现）"
    fail=1
    continue
  fi

  excl="$(extract_field "$scope" "明确排除")"
  [ -z "$excl" ] && continue

  while IFS= read -r line; do
    [ -z "$line" ] && continue

    target=""
    link_re='\]\(([^)]+\.md)\)'
    book_re='《([A-Za-z0-9_.]+\.md)》'
    if [[ "$line" =~ $link_re ]]; then
      target="$(basename "${BASH_REMATCH[1]}")"
    elif [[ "$line" =~ $book_re ]]; then
      target="${BASH_REMATCH[1]}"
    fi
    [ -z "$target" ] && continue

    target_path="${doc_by_basename[$target]:-}"
    if [ -z "$target_path" ]; then
      echo "[悬空引用] $d 的明确排除指向不存在的文档: $target"
      fail=1
      continue
    fi

    target_scope="$(extract_section "$target_path" "对比范围")"
    target_cover="$(extract_field "$target_scope" "覆盖")"

    keyword="$(printf '%s\n' "$line" | sed -E 's/^[-*[:space:]]*//; s/——见.*$//; s/[[:space:]]+$//' | python3 -c "import sys; print(sys.stdin.read().strip()[:24], end='')")"
    if [ -n "$keyword" ] && [ -n "$target_cover" ] && ! printf '%s' "$target_cover" | grep -qF "$keyword"; then
      echo "[疑似不匹配-人工核对] $d 排除\"$keyword\" -> $target，但其覆盖字段未见对应关键字"
      warn=1
    fi
  done <<< "$excl"
done

echo "---"
if [ "$fail" -ne 0 ]; then
  echo "结果: 发现悬空引用或缺失《对比范围》节，见上方 [缺节]/[悬空引用]"
elif [ "$warn" -ne 0 ]; then
  echo "结果: 无悬空引用，但有疑似不匹配项需人工核对，见上方 [疑似不匹配-人工核对]"
else
  echo "结果: 全部通过"
fi
exit "$fail"
