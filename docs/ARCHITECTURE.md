# 架构设计 (Architecture)

本文件记录 `xfengyin/xfengyin` Profile 仓库的架构决策与扩展指南。

## 设计原则

| 原则 | 落地方式 |
|------|----------|
| **OCP 友好** | 新增板块只新增 `data/*.yml` + README 引用,不动既有结构 |
| **最小工程化** | 不做全自动 SSG (过度工程化),人维护 README,数据文件做引用源 |
| **可观测** | CI 链接体检每日跑,断链 / 渲染异常自动开 issue |
| **可访问性** | 所有 `<img>` 必带 `alt`,装饰 emoji 用 `aria-hidden` 包裹 |
| **安全合规** | 第三方图像源在 `SECURITY.md` 中声明 |
| **供应链安全** | Dependabot 周轮询 + auto-merge patch/minor |

## 目录结构

```
xfengyin/
├── .github/
│   ├── ISSUE_TEMPLATE/                # 规范化协作流程
│   │   ├── bug_report.md
│   │   ├── feature_request.md
│   │   └── content_update.md
│   ├── PULL_REQUEST_TEMPLATE.md       # PR 自检清单
│   ├── CODEOWNERS                     # 默认 owner
│   ├── FUNDING.yml                    # Sponsor 配置
│   ├── dependabot.yml                 # 周轮询 GitHub Actions
│   └── workflows/
│       ├── ci-lint.yml                # markdownlint
│       ├── ci-link-check.yml          # lychee 链接体检
│       ├── ci-data-check.yml          # schema + data/README 双向校验
│       ├── monitor-stats.yml          # 每日 cron 监测外部图像源
│       └── dependabot-auto-merge.yml  # dependabot patch/minior 自动合入
├── assets/
│   ├── badges/                        # 自托管徽章 SVG
│   │   └── orangepi.svg               # 本地化 OrangePi 徽章
│   └── schema/                        # JSON Schema 契约
│       ├── projects.schema.json
│       └── tech_stack.schema.json
├── data/                              # 单一事实源
│   ├── projects.yml                   # 精选项目
│   └── tech_stack.yml                 # 技术栈
├── docs/
│   └── ARCHITECTURE.md                # 本文件
├── scripts/
│   └── check_data_consistency.py      # data/README 双向校验
├── .markdownlint.json                 # Lint 规则
├── .lycheecrc                         # 链接体检配置
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
- 二者用 `scripts/check_data_consistency.py` + `ci-data-check.yml` 自动交叉校验
- `assets/schema/*.json` 约束 yml 字段,避免脏数据

### 2. 外部图像源选型

| 服务 | 用途 | 部署 | 选型理由 |
|------|------|------|----------|
| `img.shields.io` | 技术栈徽章 | shields.io | 行业标准,多语言支持 |
| `github-readme-streak-stats.demolab.com` | 连续贡献 | demolab | anuraghazra 官方部署,稳定 |
| `komarev.com` | Profile 浏览量 | komarev | 轻量、活跃维护 |

> ⚠️ 已 **弃用** `github-readme-stats.vercel.app` (原审查标记的半弃用服务)。

### 3. CI 质量门禁

| 工作流 | 工具 | 触发 | 失败动作 |
|--------|------|------|----------|
| `ci-lint.yml` | `markdownlint-cli2` | push / PR | 阻断合并 |
| `ci-link-check.yml` | `lychee` | push / PR / cron | 警告 + 自动 issue |
| `ci-data-check.yml` | `pyyaml` + `jsonschema` | push / PR | 阻断合并 |
| `monitor-stats.yml` | `curl` + `github-script` | 每日 cron + 手动 | 失败自动开 issue |
| `dependabot-auto-merge.yml` | `dependabot/fetch-metadata` | dependabot PR | 自动 squash 合并 |

## 已知限制 (Known Limitations)

> 本节明确记录"已知但故意未修复"的问题,避免读者误判项目质量。

### L1. ~~OrangePi 徽章 logo 错配~~ ✅ 已解决

- **方案**: 自托管 `assets/badges/orangepi.svg`,完全脱离 shields.io
- **优势**: 不受 simpleicons 覆盖范围限制,brand 一致

### L2. ~~`github-readme-stats.vercel.app` 依赖~~ ✅ 已解决

- **方案**: 迁移到 `github-readme-streak-stats.demolab.com`
- **方案 (2)**: 浏览量改用 `komarev.com`,与 stats 服务解耦
- **验证**: `monitor-stats.yml` 已更新 URL 列表,每日体检新源

### L3. Action 版本未锁 SHA ⚠️ 仍存在

- **现状**: 使用浮动 major tag (`@v6`, `@v23`, `@v9`, `@v2`)
- **缓解**:
  - `dependabot.yml` 周一自动检测
  - `dependabot-auto-merge.yml` patch / minor 自动合入
  - 人工 review major 升级 (目前 4 PR 等待 review)
- **彻底加固路径**: 待 dependabot 跑稳后,批量将 floating tag 替换为 commit SHA

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
3. 提交 PR,触发 CI 验证 (data-check 自动校验双向一致)

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
2. 新建 `assets/schema/blog.schema.json` 约束字段
3. 在 `scripts/check_data_consistency.py` 中加一段校验
4. 在 `README.md` 中手工嵌入
5. 在 `docs/ARCHITECTURE.md` 的"目录结构"一节同步登记

> 原则: 任何"新增能力"都通过新增 `data/*.yml` + 手工 README 嵌入完成,不动既有结构。

## 变更历史

| 日期 | 变更 |
|------|------|
| 2026-06-11 (v3) | 弃用 vercel.app / 迁移 streak & view / 自托管 OrangePi SVG / 加 schema 校验 / 加 auto-merge / 加 CODEOWNERS & FUNDING & CoC |
| 2026-06-11 (v2) | 补 P0/P1: monitor-stats / data-check / dependabot / aria-hidden / 个人 slogan |
| 2026-06-11 (v1) | 初版: 全量审查后建立工程化基础 (LICENSE / SECURITY / 模板 / CI) |
