#!/usr/bin/env bash
# check.sh — 主页内容门禁：单文件、零第三方依赖、脚本自身即执行者。
# 约定（docs/ARCHITECTURE.md）：
#   1) 每类检查都报告 target 数量；checked == 0 ⇒ SELF-ERROR exit 2（拒绝假绿）
#   2) 测不出来 ≠ 通过：网络/限流记 ERROR 并 exit 2，不降级为 PASS
#   3) 只用 curl / grep / sed / awk / sort，不引入包管理器
set -uo pipefail
REPO_DIR="$1"
if [ -z "$REPO_DIR" ]; then REPO_DIR=$(cd "$(dirname "$0")/.." && pwd); fi
README="$REPO_DIR/README.md"
OWNER="xfengyin"
API="https://api.github.com"
LOG=$(mktemp)
trap "rm -f $LOG" EXIT
pass=0; fail=0; err=0; selferr=0
ok()  { pass=$((pass+1)); echo "  PASS  $1" >> "$LOG"; }
bad() { fail=$((fail+1)); echo "  FAIL  $1" >> "$LOG"; }
errr(){ err=$((err+1));  echo "  ERROR $1" >> "$LOG"; }
api_body() {
  if [ -n "$GITHUB_TOKEN" ]; then
    curl -s --max-time 25 -H "Authorization: Bearer $GITHUB_TOKEN" "$1"
  else
    curl -s --max-time 25 "$1"
  fi
}
api_code() {
  if [ -n "$GITHUB_TOKEN" ]; then
    curl -s -o /dev/null -w "%{http_code}" --max-time 25 -H "Authorization: Bearer $GITHUB_TOKEN" "$1"
  else
    curl -s -o /dev/null -w "%{http_code}" --max-time 25 "$1"
  fi
}
if [ ! -f "$README" ]; then echo "SELF-ERROR: 找不到 $README"; exit 2; fi

# 私有仓名清单：**不在仓库内**。仓库是公开的，把私有仓名写进脚本本身就是一次新的泄露。
# 来源优先级：$PROFILE_DENY_FILE > ~/.config/xfengyin/private-names.txt
# 格式：每行一个名字。匹配用 PCRE 精确边界（\Q..\E + 负向前瞻），公开的 -overlay 不被同前缀私有名误伤。
DENY_FILE="${PROFILE_DENY_FILE:-$HOME/.config/xfengyin/private-names.txt}"
DENY_NAMES=""
if [ -f "$DENY_FILE" ]; then
  DENY_NAMES=$(grep -vE "^[[:space:]]*(#|$)" "$DENY_FILE" | tr -d "\r")
else
  bad "SELF-ERROR: 私有名清单未配置 ($DENY_FILE)，第 5/10 项无法执行；见 scripts/private-names.example.txt"; selferr=1
fi
# 1 仓库链接可达
REPOS=$(grep -oE "github.com/$OWNER/[A-Za-z0-9._-]+" "$README" | sed "s|github.com/$OWNER/||" | sort -u)
n=0
for r in $REPOS; do
  n=$((n+1))
  code=$(api_code "$API/repos/$OWNER/$r")
  if [ "$code" = "200" ]; then : ;
  elif [ "$code" = "404" ] || [ "$code" = "410" ]; then bad "repo $OWNER/$r = $code (DEAD)";
  else errr "repo $OWNER/$r = $code (未判定: 限流或网络)"; fi
done
if [ "$n" -eq 0 ]; then bad "SELF-ERROR: README 没有任何指向本账号仓库的链接"; selferr=1; fi
ok "1 仓库链接: 检查 $n 条"

# 2 深链 blob/tree 的分支与路径必须真实存在（main 与 master 混用是已知坑）
DEEP=$(grep -oE "github.com/$OWNER/[A-Za-z0-9._-]+/(blob|tree)/[A-Za-z0-9._-]+/[A-Za-z0-9._/%-]+" "$README" | sort -u)
d=0; dfail=0; derr=0
for u in $DEEP; do
  d=$((d+1))
  path=${u#github.com/}
  path=${path#"$OWNER"/}
  repo=${path%%/*}
  rest=${path#*/}
  rest=${rest#*/}
  ref=${rest%%/*}
  sub=${rest#*/}
  enc=$(echo "$sub" | sed "s|/|%2F|g")
  code=$(api_code "$API/repos/$OWNER/$repo/contents/$enc?ref=$ref")
  if [ "$code" = "200" ]; then : ;
  elif [ "$code" = "404" ]; then bad "深链 404: $repo @ $ref : $sub (分支或路径不存在)"; dfail=$((dfail+1));
  else errr "深链未判定: $repo @ $ref : $sub = $code"; derr=$((derr+1)); fi
done
if [ "$d" -eq 0 ]; then bad "SELF-ERROR: README 没有 blob/tree 深链, 声称无法指到代码"; selferr=1; fi
if [ "$d" -gt 0 ] && [ "$dfail" -eq 0 ] && [ "$derr" -eq 0 ]; then ok "2 深链: 检查 $d 条, 路径与分支均存在"; fi

# 3 技术声称 → 公开证据（语言分布 ∪ 指定文件）
LANGS=""
for r in $REPOS; do
  one=$(api_body "$API/repos/$OWNER/$r/languages" | grep -oE "\"[A-Za-z0-9+#]+\"" | tr -d "\"")
  LANGS="$LANGS $one"
done
MAP="React $OWNER/daq-insight/contents/package.json
Electron $OWNER/daq-insight/contents/package.json
Docker $OWNER/kongming-agent/contents/Dockerfile
MCP $OWNER/kongming-agent/contents/pkg/tools/mcp.go"
cfail=0; cchecked=0
for w in Go Python TypeScript Rust React Electron Docker MCP; do
  grep -qw -- "$w" "$README" || continue
  cchecked=$((cchecked+1))
  if echo "$LANGS" | tr " " "\n" | grep -qx -- "$w"; then continue; fi
  hit=$(echo "$MAP" | grep "^$w " | cut -d" " -f2)
  if [ -n "$hit" ] && [ "$(api_code "$API/repos/$hit")" = "200" ]; then continue; fi
  bad "无证据声称: $w (不在公开仓语言分布, 映射证据也不可达)"; cfail=$((cfail+1))
done
if [ "$cchecked" -eq 0 ]; then bad "SELF-ERROR: 未识别到任何技术声称, 检查表失效"; selferr=1; fi
if [ "$cfail" -eq 0 ]; then ok "3 声称→证据: 检查 $cchecked 个技术名, 全部有公开证据"; fi

# 4 禁止形态（对应历史事故：外部徽章服务、计数器、假统计、无效的 a11y 手段）
FB="img.shields.io komarev.com streak-stats demolab aria-hidden github-readme-stats"
f=0
for p in $FB; do
  if grep -qF -- "$p" "$README"; then bad "禁止形态复现: $p"; f=$((f+1)); fi
done
[ "$f" -eq 0 ] && ok "4 禁止形态: 0 命中"

# 5 私有仓名泄露（精确边界匹配，公开的 -overlay 不误报）
DENY="$DENY_NAMES"
leak=0
for p in $DENY; do
  if grep -qP -- "\Q$p\E(?![A-Za-z0-9._-])" "$README"; then bad "私有仓名泄露: 清单第 $((leak+1)) 条命中 README（不打印名字）"; leak=$((leak+1)); fi
done
[ "$leak" -eq 0 ] && [ -n "$DENY_NAMES" ] && ok "5 私有名: 0 命中 (边界匹配)"

# 6 联系信道：出现 mailto 就必须有 MX（github.io 子域无 MX，已复现静默丢信）
MAILRAW=$(grep -oE "mailto:[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+" "$README" | sed "s|^mailto:||" | sort -u)
if [ -z "$MAILRAW" ]; then
  ok "6 联系信道: README 不含 mailto"
else
  for a in $MAILRAW; do
    dom=$(echo "$a" | cut -d @ -f2)
    if command -v dig >/dev/null 2>&1; then
      mx=$(dig +short MX "$dom" 2>/dev/null)
      if [ -z "$mx" ]; then bad "邮箱域 $dom 无 MX 记录 ($a 不可投递)"; else ok "邮箱域 $dom 有 MX"; fi
    else errr "缺 dig, 无法验证邮箱域 $dom"; fi
  done
fi

# 7 本仓相对链接（门禁与文档必须挂在 README 上）
REL=$(grep -oE "\]\((docs|scripts|assets)/[^) ]+" "$README" | sed "s/^](//" | sort -u)
if [ -z "$REL" ]; then
  errr "7 README 未引用本仓 docs/scripts/assets, 文档挂载点丢失"
else
  rn=0; rfail=0
  for p in $REL; do rn=$((rn+1)); if [ ! -f "$REPO_DIR/$p" ]; then bad "相对链接缺失: $p"; rfail=$((rfail+1)); fi; done
  [ "$rfail" -eq 0 ] && ok "7 本仓引用: $rn 个文件均存在"
fi

# 8 结构与可访问性
h1=$(grep -cE "^# " "$README")
if [ "$h1" -eq 1 ]; then ok "8 结构: h1 = 1"; else bad "h1 数量 = $h1 (应为 1)"; fi
emoji=$(grep -cP "^#{1,4} .*[\x{1F000}-\x{1FAFF}\x{2600}-\x{27BF}]" "$README" 2>/dev/null || echo 0)
if [ "$emoji" -gt 0 ]; then
  bad "标题含装饰 emoji $emoji 处 (GitHub sanitizer 会剥掉 span 上的 aria-hidden, 读屏必然念出)"
else
  ok "8 无障碍: 标题不含装饰 emoji"
fi
last=$(tail -c 1 "$README" | od -An -c | tr -d " ")
if echo "$last" | grep -q n; then ok "8 结尾单个换行 (MD047)"; else bad "文件末尾缺换行 (MD047)"; fi
orph=0
for a in "$REPO_DIR"/assets/badges/*; do
  [ -e "$a" ] || continue
  b=$(basename "$a")
  if ! grep -qF -- "assets/badges/$b" "$README"; then bad "孤儿资产: assets/badges/$b"; orph=$((orph+1)); fi
done
[ "$orph" -eq 0 ] && ok "8 资产: assets/badges 无孤儿文件"

# 9 外部图片请求数（目标 0）
imgs=$(grep -oE "!\[[^]]*\]\(https?://" "$README" | wc -l | tr -d " ")
if [ "$imgs" -eq 0 ]; then ok "9 外部图片请求 = 0"; else bad "外部图片请求 $imgs 个 (应为 0)"; fi


# 10 零泄露门禁（内容面 + 暂存区新增行）：私有仓名 / 内网形态 / 个人邮箱 / 凭据形态
# 注：本脚本自身携带 denylist 模式，因此扫描范围排除 scripts/（否则必然自命中）。
CONTENT=$(ls "$README" 2>/dev/null; ls "$REPO_DIR"/docs/*.md 2>/dev/null; ls "$REPO_DIR"/.github/*.md "$REPO_DIR"/.github/*.yml 2>/dev/null; ls "$REPO_DIR"/.github/ISSUE_TEMPLATE/*.md 2>/dev/null)
PAT_INTERNAL="192[.]168[.]|10[.][0-9]+[.][0-9]+[.]|172[.](1[6-9]|2[0-9]|3[0-1])[.]|:(3100|3101)|gitea[.][A-Za-z0-9.-]*[:/]"
PAT_PERSONAL="[0-9]{8,}@(qq|163|126|foxmail)[.]com"
PAT_CRED="gh""p_[A-Za-z0-9]{20,}|github_""pat_[A-Za-z0-9_]{20,}|BEGIN (RSA |OPENSSH |EC |)PRIVATE KEY"
lc=0; lfail=0
STAGED=""
if git -C "$REPO_DIR" rev-parse --git-dir > /dev/null 2>&1; then
  if git -C "$REPO_DIR" diff --cached -U0 -- . ":(exclude)scripts/" 2>/dev/null | grep -E "^\+" | grep -v "^\+\+\+" > /tmp/.staged_profile_lines; then STAGED=$(cat /tmp/.staged_profile_lines); fi
fi
for f in $CONTENT; do
  [ -f "$f" ] || continue
  case "$f" in *check.sh) continue ;; esac
  lc=$((lc+1))
  for pat in "$PAT_INTERNAL" "$PAT_PERSONAL" "$PAT_CRED"; do
    if grep -qE -- "$pat" "$f"; then bad "泄露门禁命中: $f <- $(echo "$pat" | cut -c1-22)..."; lfail=$((lfail+1)); fi
  done
  for n in $DENY_NAMES; do
    if grep -qP -- "\Q$n\E(?![A-Za-z0-9._-])" "$f"; then bad "泄露门禁命中: $f <- 私有名清单条目（不打印名字）"; lfail=$((lfail+1)); fi
  done
done
if [ -n "$STAGED" ]; then
  lc=$((lc+1))
  for pat in "$PAT_INTERNAL" "$PAT_PERSONAL" "$PAT_CRED"; do
    if echo "$STAGED" | grep -qE -- "$pat"; then bad "泄露门禁命中: 暂存区新增行 <- $(echo "$pat" | cut -c1-22)..."; lfail=$((lfail+1)); fi
  done
  for n in $DENY_NAMES; do
    if echo "$STAGED" | grep -qP -- "\Q$n\E(?![A-Za-z0-9._-])"; then bad "泄露门禁命中: 暂存区新增行 <- 私有名清单条目（不打印名字）"; lfail=$((lfail+1)); fi
  done
fi
if [ "$lc" -eq 0 ]; then bad "SELF-ERROR: 泄露门禁没有可扫描文件"; selferr=1; fi
if [ "$lfail" -eq 0 ] && [ -n "$DENY_NAMES" ]; then ok "10 泄露门禁: 扫描 $lc 个内容面(含暂存区), 0 命中"; fi

echo "── check.sh ── $README"
cat "$LOG"
echo "PASS=$pass FAIL=$fail ERROR=$err"
if [ "$selferr" -gt 0 ]; then echo "结论: SELF-ERROR —— 有检查项没有可测对象，拒绝出具通过结论"; exit 2; fi
if [ "$err" -gt 0 ]; then echo "结论: 未完成验证 ($err 项测不出来), 不算通过"; exit 2; fi
if [ "$fail" -gt 0 ]; then echo "结论: FAIL ($fail 项不通过)"; exit 1; fi
echo "结论: OK"
exit 0


