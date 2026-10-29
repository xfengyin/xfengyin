# 架构设计 (v6)

本文件记录 `xfengyin/xfengyin`（Profile 仓库）的架构决策。它只描述**当前存在的东西**。

> **前提**：本仓没有 CI，也没有生成器。`README.md` 是唯一被 GitHub 渲染的产物；
> 唯一的执行者是 `scripts/check.sh`，由提交者在本地手动运行并把输出贴进 PR。
> 任何"看起来会自动校验"的描述都是假的，本文件不再保留这类句子。

## 设计原则

| 原则 | 落地方式 |
| --- | --- |
| **单一渲染产物** | 只有 `README.md` 面向访客；不存在需要与它同步的第二份数据源 |
| **声称必须可指** | 每条能力声称指向 `repo@branch:path`；分支混用（main / master）由门禁校验 |
| **一条真跑的门禁** | `scripts/check.sh`：零第三方依赖，checked==0 ⇒ SELF-ERROR exit 2，测不出来 ⇒ ERROR exit 2 |
| **零外部图片** | 不加载 shields / 计数器 / 统计卡，README 的访客侧跨源请求数为 0 |
| **可访问性可达成** | 标题不放装饰 emoji（GitHub sanitizer 会剥掉 span 上的 `aria-hidden`） |
| **不过度工程化** | 不再引入 schema / 校验脚本 / 生成器三件套；要加就得同时有执行者 |

## 目录结构

```text
xfengyin/
├── .github/                  # ISSUE_TEMPLATE / PULL_REQUEST_TEMPLATE / CODEOWNERS / FUNDING
├── docs/
│   ├── ARCHITECTURE.md        # 本文件
│   └── THIRD_PARTY.md         # 外部依赖与网络面清单（含核验日期）
├── scripts/
│   └── check.sh               # 唯一门禁：内容一致性 + 零泄露
├── .markdownlint.json
├── CODE_OF_CONDUCT.md
├── LICENSE
├── README.md                  # 门面，也是唯一事实源
└── SECURITY.md
```

## 关键决策

### 1. 删除 `data/*.yml` 与 `assets/badges/`（2026-10-29）

- 三个 YAML 与两个 SVG 在仓库里**没有任何消费方**：README 不引用它们，也没有生成器或校验脚本读取它们。
- 这是同一反模式的第二次复发：2026-10-26 已删过一次"无执行者的数据契约层"（schema + 校验脚本 + workflow），`data/` 是它剩下的壳。
- 保留 `data/` 的唯一合理前提是同时交付"生成器 + 校验 + 真实执行点"，而本仓一年改动几次，与"不恢复 CI"的决策直接冲突。
- **推翻条件**：若站点仓库或某个生成器真的开始读取这些文件，则应恢复数据层，并把 `check.sh` 的一致性检查接上同一个执行者。

### 2. 不放徽章、统计卡与浏览量计数器

- 实测：GitHub 把 README 外链图片经 `camo.githubusercontent.com` 代理，访客 IP 并不直接暴露给第三方；**所以移除它们的理由是完整性与可用性，不是访客隐私**。
- 但 `komarev.com` 是动态、`no-store` 的单人 PHP 服务，数字既可被任意 curl 刷高，域名易主后主页就会显示攻击者可控图文；`img.shields.io` 从本机采样 6 次有 2 次 10s 超时。
- `assets/badges/streak-stats.svg` 是手绘柱状图，无数据源、无生成日期，属伪造统计，已删除。
- 结论：外部图片请求数 = 0，由 `check.sh` 第 9 项锁死。

### 3. 联系渠道不写 mailto

- `github.io` 与其子域均无 MX 记录（1.1.1.1 / 8.8.8.8 / 223.5.5.5 三家实测），Pages 节点 25 端口不通；`hi@xfengyin.github.io` 属于"点得到、必退信"的死信道，且 `github.io` 不受本账号控制，无法配置 SPF/DMARC。
- 现渠道为 GitHub issue（本仓 `has_issues=true`）。若将来换自有域名邮箱，`check.sh` 第 6 项会强制校验 MX。

### 4. 深链必须带正确分支

`kongming-agent` 与 `Protocol-algorithm` 的默认分支是 `master`，其余为 `main`。写错分支的 blob 链接会 404。
`check.sh` 第 2 项对 README 里每条 `blob/tree` 链接调用 contents API（带 `?ref=`），404 即失败。

### 5. 门禁的三条硬规则

1. 每类检查都报告 target 数量；`checked == 0` 一律 `SELF-ERROR exit 2`（站点侧 `content-drift-check.py` 曾对空目标报"无漂移 exit 0"，属假绿，不接受同款设计）。
2. 网络失败 / 限流记 **ERROR** 并 `exit 2`：测不出来不等于通过。
3. 只用 `curl / grep / sed / awk`，不引入包管理，因此不存在 lockfile 缺失与 `npx` 现拉未固定版本包的供应链面。

## 已知限制（故意记录，不等于已修复）

| # | 限制 | 现状 |
| --- | --- | --- |
| L1 | **公开 git 历史仍含私有仓名** | `README.md` 的历史版本（如 `f9db836`、`939d611`）与 PR #105 正文可被匿名读取，其中点名的 7 个仓库**至今仍为 private**（API 实测）。当前树已清理干净，历史未清理。 |
| L2 | **是否重写历史：决定不重写** | 36 commits、forks=0、network_count=0，技术上可重写；但 #104/#105/#106 仍引用旧 head，PR 正文不受重写影响，CDN 与搜索残留不可控。改走：编辑 PR 正文 + `check.sh` 泄露门禁 + GitHub Support 清除流程 + 书面风险接受。 |
| L3 | **提交作者邮箱公开** | `git log --format=%ae` 含个人邮箱与非 noreply 身份（含 agent/bot 与主机名邮箱）；主页文案不依赖署名一致性。 |
| L4 | **分支保护是名义存在** | 实测 `branches/main/protection`：不要求 approve review、无状态检查、`enforce_admins=false`，因此 CODEOWNERS 无强制力；本仓内容风险由单人自审承担。 |
| L5 | **门禁靠人跑** | 无 CI。绕过方式是可发现的：PR 必须附 `check.sh` 输出；不附输出的 PR 视为未验证。 |
| L6 | **仓库 issue 列表有历史告警** | 已关闭的 monitor 告警与 dependabot 记录仍在公开 issue 列表中，属历史痕迹，不删除。 |

## 人工门禁（PR 自检 = 命令，而不是形容词）

```bash
bash scripts/check.sh                 # 期望 PASS=n FAIL=0 ERROR=0，输出贴进 PR
npx --yes markdownlint-cli@0.42.0 README.md docs/*.md   # 期望 exit 0（可选，联网）
```

## 变更历史

| 日期 | 变更 |
| --- | --- |
| 2026-10-29 (v6) | 深度重做：README 改为"声称→可指证据"结构；删除 `data/`（无消费方的第二次复发）与 `assets/badges/`（含伪造统计卡）；新增 `scripts/check.sh` 与 `docs/THIRD_PARTY.md`；按实测修正 demolab / mailto / aria-hidden / 分支保护等失真描述；补 L1–L3 泄露限制记录 |
| 2026-10-26 (v5) | 删除无执行者的契约层（schema、校验脚本、`.lycheecrc`），按"本仓无 CI"重写 |
| 2026-06-11 (v2–v4) | 徽章源迁移、自托管 SVG、CODEOWNERS / FUNDING / CoC、blog.yml 与 schema 引入 |
