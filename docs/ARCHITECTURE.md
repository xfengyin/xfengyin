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

> dependabot.yml 已配置为周轮询 (见下方 L3)，仍不引入 npm/pip/docker 等生态 (无运行时依赖)。

## 已知限制 (Known Limitations)

> 本节明确记录"已知但故意未修复"的问题，避免读者误判项目质量。

### L1. OrangePi 徽章 logo 与 alt 错配

- **位置**: `README.md` Tools & Platforms 分组中 OrangePi 徽章
- **现状**: `logo=Linux` (因为 shields.io simpleicons 无 OrangePi 官方 logo), `alt=OrangePi`
- **取舍**: shields.io 简图库覆盖硬件品牌有限，OrangePi 等小众硬件无对应 logo
- **备选方案**:
  - 自托管 SVG 徽章 (复杂度 ↑)
  - 使用通用 `chip` / `hardware` 类 icon (语义 ↓)
  - 维持现状 (推荐) — alt 已准确表达品牌，logo 仅为视觉装饰

### L2. `github-readme-stats.vercel.app` 单点依赖

- **现状**: 继续使用上游服务，未替换
- **风险**: 审查曾标记"半弃用"
- **缓解**:
  - `ci-link-check.yml` 每次 PR 检测
  - `monitor-stats.yml` 每日 cron + 失败自动开 issue
  - ARCHITECTURE.md 留有"自托管迁移"路径
- **触发替换条件**: monitor-stats 连续 3 天开 issue 后评估

### L3. Action 版本未锁 SHA

- **现状**: 全部使用浮动 tag (`@v4`, `@v19`, `@v2`)
- **风险**: 上游可被供应链攻击
- **缓解**: `.github/dependabot.yml` 周一自动检测 + 提 PR；人工 review 合入
- **进一步加固路径**: dependabot 启用后，批量 PR 将 action 锁到 SHA

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
