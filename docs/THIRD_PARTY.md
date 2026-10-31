# 外部依赖与网络面清单

本仓的运行时外部面。**最后人工核验：2026-10-29**（本机出口，不代表所有访客网络）。

| 外部对象 | 用途 | 是否必需 | 失效后果 | 核验方式 |
| --- | --- | --- | --- | --- |
| `github.com/xfengyin/*` | 主页正文的仓库链接与 `blob/tree` 深链 | 是 | 死链即文案失效 | `check.sh` 第 1、2 项（API contents + ref） |
| `api.github.com` | `check.sh` 判定仓库存在性、语言分布、证据文件 | 否（本地无网时跳过） | 门禁报 ERROR 而非 PASS | 脚本自身 |
| `xfengyin.github.io` | 站点入口（Zola 独立仓库） | 是 | 联系渠道与文章入口失效 | 匿名 curl 200（已实测） |
| `sipeed/picoclaw` | overlay 的上游说明 | 是 | 上游叙事断裂 | API 200（已实测） |

## 已移除的外部面（不要再加回来）

| 对象 | 原用途 | 移除理由 |
| --- | --- | --- |
| `img.shields.io` | 技术栈徽章（10 个） | 静态徽章无信息增量；本机采样 6 次中 2 次 10s 超时；`badge` 端点的 `link` 参数可把任意 URL 写进返回 SVG 的 `a href`（实测可注入，当前经 camo + `<img>` 上下文不可点击） |
| `komarev.com` | 浏览量计数 | 动态、`no-store`、单人 PHP 服务；数字可被任意 curl 刷高，不可核验也不可审计；域名易主即成为投放面 |
| `github-readme-streak-stats.demolab.com` | 连续贡献 | 从未真正使用（README 中 0 命中），而 `ARCHITECTURE.md` v5 曾把它列为在用图像源 |
| `assets/badges/streak-stats.svg` | 手绘"统计卡" | 无数据源、无生成日期、无引用者，属伪造统计 |
| `mailto:hi@xfengyin.github.io` | 联系徽章 | 域名无 MX、Pages 节点 25 端口不通；`github.io` 不受本账号控制，无法配 SPF/DMARC |

## 访客侧请求

- 外部图片请求：**0**（由 `check.sh` 第 9 项锁死）。
- GitHub 对 README 外链图片会经 `camo.githubusercontent.com` 代理，因此历史上的第三方徽章并不直接暴露访客 IP；本页移除它们的理由是**内容完整性与可用性**，不是访客隐私。
- 本页不加载脚本、字体、iframe、表单；`<img>` 与 emoji 均不作为信息载体。
