# Security Policy

## Supported Versions

本仓库为个人 Profile 仓库，只渲染 `README.md`，仅 `main` 分支受支持。

| Branch  | Supported          |
| ------- | ------------------ |
| `main`  | :white_check_mark: |
| 其他    | :x: |

## Reporting a Vulnerability

如发现本仓内容存在安全问题（README 被植入恶意链接、伪造指标、文案泄露私有信息、
若将来引入 workflow 后的注入风险等），请私密披露，勿在公开 Issue 描述未修复细节：

1. **GitHub Private Vulnerability Reporting**（首选）：<https://github.com/xfengyin/xfengyin/security/advisories/new>
2. 兜底渠道：在 <https://github.com/xfengyin/kongming-agent/issues> 开一个标题写 "private" 的 Issue，我收到后转私密沟通。
   注意：**不要**使用 `hi@xfengyin.github.io` —— 实测 `github.io` 与其子域均无 MX 记录，该地址必然退信。

**响应 SLA**：7 个工作日内确认收到；修复计划随首次回复给出。

## Scope

- `README.md` — 面向访客的唯一渲染产物
- `docs/*.md` — 架构决策与外部依赖清单
- `.github/**` — Issue / PR 模板、CODEOWNERS、FUNDING
- 文案中的**第三方引用面**（链接目标、域名、若出现的徽章服务）：其存在与选取在范围内

## Out of Scope

- 第三方服务自身的可用性与事故（GitHub Pages、camo 代理等）
- `xfengyin.github.io` 站点仓库的安全策略（见该仓库 SECURITY.md）
- `.github/workflows/*` —— **本仓当前没有 workflow 文件**；若将来恢复 CI 才纳入范围

## 已知残余风险（诚实声明）

- 本仓**公开 git 历史**中的早期 README 版本与 PR 正文点名了至今仍为 private 的仓库名。
  当前工作树已清理干净，并由 `scripts/check.sh` 第 10 项（泄露门禁）锁死新增内容；
  历史经决定**不重写**，理由与残余风险记录在 `docs/ARCHITECTURE.md` 的 L1 / L2。
- 本仓外部图片数为 0，因此不存在经第三方图像源投放攻击者可控内容的路径。
- 内容完整性依赖单人自审 + 一个需人工执行的门禁脚本（无 CI），保障强度有限，见 L4 / L5。
