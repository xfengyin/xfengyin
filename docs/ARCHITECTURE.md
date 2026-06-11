# 架构设计 (Architecture)

本文件记录 `xfengyin/xfengyin` Profile 仓库的架构决策与扩展指南。

## 设计原则

| 原则 | 落地方式 |
|------|----------|
| **OCP 友好** | 新增板块只新增 `data/*.yml` + README 引用,不动既有结构 |
| **最小工程化** | 不做全自动 SSG (过度工程化),人维护 README,数据文件做引用源 |
| **可观测** | CI 链接体检每日跑,断链 / 渲染异常自动开 issue |
| **可访问性** | 所有 `<img>` 必带 `alt`,徽章风格统一 |
| **安全合规** | 第三方图像源在 `SECURITY.md` 中声明 |

## 目录结构

```
xfengyin/
├── .github/
│   ├── ISSUE_TEMPLATE/           # 规范化协作流程
│   │   ├── bug_report.md
│   │   ├── feature_request.md
│   │   └── content_update.md
│   ├── PULL_REQUEST_TEMPLATE.md  # PR 自检清单
│   └── workflows/
│       ├── ci-lint.yml           # markdownlint
│       └── ci-link-check.yml     # lychee 链接体检 (每日 cron)
├── data/                         # 单一事实源
│   ├── projects.yml              # 精选项目
│   └── tech_stack.yml            # 技术栈
├── docs/
│   └── ARCHITECTURE.md           # 本文件
├── .markdownlint.json            # Lint 规则
├── .lycheecrc                    # 链接体检配置
├── .gitignore
├── LICENSE                       # MIT
├── README.md                     # 门面 (人维护)
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
- 二者用约定同步(新增项目=改 yml + 改 README 对应行)

### 2. 为什么保留 `github-readme-stats.vercel.app`?

短期: 上游仍可用,移除影响即时可见性
长期: 计划替换为 [github-profile-summary-cards](https://github.com/vn7n24fzkq/github-profile-summary-cards) 或自托管 Action

监控: `ci-link-check.yml` 每日 cron 检测,断链自动开 issue 提醒替换。

### 3. CI 质量门禁

| 工作流 | 工具 | 触发 | 失败动作 |
|--------|------|------|----------|
| `ci-lint.yml` | `markdownlint-cli2` | push / PR | 阻断合并 |
| `ci-link-check.yml` | `lychee` | push / PR / cron | 警告 + 自动 issue |

> 故意不引入 `dependabot.yml` 等过度配置 — Profile 仓库变更频率低,人肉管理足够。

## 扩展指南

### 新增一个精选项目

1. 编辑 `data/projects.yml`:
   ```yaml
   - name: my-new-project
     category: ai-agent
     desc: 一句话描述
     repo: xfengyin/my-new-project
   ```
2. 编辑 `README.md` 对应分类区块,加一行
3. 提交 PR,触发 CI 验证

### 新增一个技术栈徽章

1. 编辑 `data/tech_stack.yml`:
   ```yaml
   - name: Rust
     badge_url: https://img.shields.io/badge/Rust-000000?style=flat-square&logo=Rust&logoColor=white
     category: backend
   ```
2. 编辑 `README.md` 对应分组
3. 提交 PR

### 新增板块 (例如博客聚合)

1. 新建 `data/blog.yml`
2. 新建 `docs/sections/blog.md` 写好模板
3. 在 `README.md` 中 `<!-- include: blog -->` 位置手工嵌入
4. 在 `docs/ARCHITECTURE.md` 的"目录结构"一节同步登记

> 原则: 任何"新增能力"都通过新增 `data/*.yml` + 手工 README 嵌入完成,不动既有结构。

## 变更历史

| 日期 | 变更 |
|------|------|
| 2026-06-11 | 初版: 全量审查后建立工程化基础 (LICENSE / SECURITY / 模板 / CI) |
