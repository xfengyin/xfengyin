# 架构设计 (Architecture)

本文件记录 `xfengyin/xfengyin` Profile 仓库的架构决策与扩展指南。

> **前提**:本仓**没有 CI**。GitHub Actions 默认关闭,`.github/workflows/` 与 `.gitea/` 均不存在;
> 所有"门禁"都是提交者本地的人工动作,见 `.github/PULL_REQUEST_TEMPLATE.md` 的自检清单。
> 历史背景见 [已知限制](#已知限制-known-limitations) 与「质量门禁的现状」。

## 设计原则

| 原则 | 落地方式 |
| ------ | ---------- |
| **OCP 友好** | 新增板块只新增 `data/*.yml` + README 引用,不动既有结构 |
| **最小工程化** | 不做全自动 SSG (过度工程化),人维护 README,数据文件做引用源 |
| **无自动化门禁** | 链接体检、数据与 README 的一致性都由提交者本地自查;本仓没有 workflow 可跑 |
| **可访问性** | 所有 `<img>` 必带 `alt`,装饰 emoji 用 `aria-hidden` 包裹 |
| **安全合规** | 第三方图像源在 `SECURITY.md` 中声明 |
| **无第三方依赖** | 只有 Markdown / YAML / 自托管 SVG,没有包管理器清单,因此也不需要 Dependabot |

## 目录结构

```text
xfengyin/
├── .github/
│   ├── ISSUE_TEMPLATE/                # 规范化协作流程
│   │   ├── bug_report.md
│   │   ├── feature_request.md
│   │   └── content_update.md
│   ├── PULL_REQUEST_TEMPLATE.md       # PR 自检清单(人工门禁的唯一载体)
│   ├── CODEOWNERS                     # 默认 owner
│   └── FUNDING.yml                    # Sponsor 配置
├── assets/
│   └── badges/                        # 自托管徽章 SVG
│       ├── orangepi.svg               # 本地化 OrangePi 徽章
│       └── streak-stats.svg           # 连续贡献徽章快照
├── data/                              # 单一事实源
│   ├── projects.yml                   # 精选项目
│   ├── tech_stack.yml                 # 技术栈
│   └── blog.yml                       # 最新博客文章
├── docs/
│   └── ARCHITECTURE.md                # 本文件
├── .markdownlint.json                 # 本地 markdownlint 规则(人工执行,无 CI)
├── .gitignore
├── CODE_OF_CONDUCT.md                 # Contributor Covenant v2.1
├── LICENSE                            # MIT
├── README.md                          # 门面 (人维护)
└── SECURITY.md
```

## 关键决策

### 1. 为什么不用全自动 SSG?

Profile 仓库本质是"个人品牌门面",**展示形态** > **数据完整性**。全自动生成器会带来:

- README 中 `{{ include }}` 残留风险
- CI 渲染产物 vs 提交产物的 diff 噪音
- 维护模板 / 数据 / 渲染器三件套的认知负担

采用"数据-展示分离但人维护"的折中:

- `data/*.yml` 是结构化数据,机器可读
- README.md 是给人看的渲染结果,人维护
- 二者的交叉核对是**手动**的:改完 `data/*.yml` 立刻在 README 对应区块同步
  (2026-10-26 之前这里挂着一个校验脚本 + 一份 JSON Schema,但没有任何执行者调用它们,已删除)

### 2. 外部图像源选型

| 服务 | 用途 | 部署 | 选型理由 |
| ------ | ------ | ------ | ---------- |
| `img.shields.io` | 技术栈徽章 | shields.io | 行业标准,多语言支持 |
| `github-readme-streak-stats.demolab.com` | 连续贡献 | demolab | anuraghazra 官方部署,稳定 |
| `komarev.com` | Profile 浏览量 | komarev | 轻量、活跃维护 |

> ⚠️ 已 **弃用** `github-readme-stats.vercel.app` (原审查标记的半弃用服务)。

### 3. 质量门禁的现状:没有 CI

本仓曾经有 5 个 workflow(`ci-lint` / `ci-link-check` / `ci-data-check` / `monitor-stats` /
`dependabot-auto-merge`)。2026-10-14 按"GitHub Actions 默认关闭"的口径把 `.github/workflows/` 整个删除后,
**它们都不存在了,本仓不再有任何自动化校验**。

保留下来的人工门禁只有三件事,全部写在 PR 模板里:

1. 改的是 `data/` 或 `README.md`,不手改"看起来是生成的"内容
2. 本地跑 `markdownlint README.md`(规则在 `.markdownlint.json`)
3. 链接、图片、徽章在本地预览可达

**不打算恢复 CI**:本仓一年只改几次(YAML 数据 + 手写 README),维护 5 个 workflow 的成本高于收益。
将来真要加,也只能加一条"数据/README 一致性"检查,并让它真的读 schema——而不是再存一份没人执行的契约。

## 已知限制 (Known Limitations)

> 本节明确记录"已知但故意未修复"的问题,避免读者误判项目质量。

### L1. ~~OrangePi 徽章 logo 错配~~ ✅ 已解决

- **方案**: 自托管 `assets/badges/orangepi.svg`,完全脱离 shields.io
- **优势**: 不受 simpleicons 覆盖范围限制,brand 一致

### L2. ~~`github-readme-stats.vercel.app` 依赖~~ ✅ 已解决

- **方案**: 迁移到 `github-readme-streak-stats.demolab.com`
- **方案 (2)**: 浏览量改用 `komarev.com`,与 stats 服务解耦
- **验证**: 新源 URL 已人工核验可达;原先的每日 URL 体检 workflow 已随 Actions 关闭删除,
  这类回归现在靠提交 PR 时的本地预览发现

### L3. ~~Action 版本未锁 SHA~~ ✅ 随 Actions 关闭而消失

- **方案**: 本仓已无 workflow 文件,不存在 floating tag ⇒ 无 SHA 锁定问题
- **若将来恢复 CI**: 必须重新锁定 SHA 并启用 Dependabot,别直接写 `@v4`

## 扩展指南

### 新增一个精选项目

1. 编辑 `data/projects.yml`:
   ```yaml
   - name: my-new-project
     category: ai-agent
     desc: 一句话描述
     repo: xfengyin/my-new-project
     featured: true
   ```
2. 编辑 `README.md` 对应分类区块,加一行
3. 提交 PR,在自检清单里确认"数据与 README 一致"(本仓无 CI 会替你查)

### 新增一个技术栈徽章

1. 编辑 `data/tech_stack.yml`:
   ```yaml
   - name: Rust
     category: backend
     badge: https://img.shields.io/badge/Rust-000000?style=flat-square&logo=Rust&logoColor=white
     alt: Rust
   ```
2. 编辑 `README.md` 对应分组
3. 提交 PR

### 新增板块 (例如博客聚合)

1. 新建 `data/blog.yml`
2. 在 `README.md` 中手工嵌入
3. 在 `docs/ARCHITECTURE.md` 的"目录结构"一节同步登记

> 原则: 任何"新增能力"都通过新增 `data/*.yml` + 手工 README 嵌入完成,不动既有结构。
> 不要再引入"没人执行的契约"(JSON Schema / 校验脚本 / workflow) —— 要么接上执行者,要么不写。

## 变更历史

| 日期 | 变更 |
| ------ | ------ |
| 2026-10-26 (v5) | 删除无执行者的契约层:3 个 `assets/schema/*.json`、`scripts/check_data_consistency.py`(143 行)、`.lycheecrc.json`;本文件按"本仓无 CI"重写,去掉 5 个不存在 workflow 的描述 |
| 2026-06-11 (v4.1.0) | 新增 blog.yml + schema + 校验；dependabot-auto-merge fetch-metadata 升级到 v3.1.0 (SHA 锁定) |
| 2026-06-11 (v4.0.0) | 关闭 6 个跟踪 issue: L3 SHA 锁定 + 5 个 P2/P3 |
| 2026-06-11 (v3) | 弃用 vercel.app / 迁移 streak & view / 自托管 OrangePi SVG / 加 schema 校验 / 加 auto-merge / 加 CODEOWNERS & FUNDING & CoC |
| 2026-06-11 (v2) | 补 P0/P1: monitor-stats / data-check / dependabot / aria-hidden / 个人 slogan |
| 2026-06-11 (v1) | 初版: 全量审查后建立工程化基础 (LICENSE / SECURITY / 模板 / CI) |
