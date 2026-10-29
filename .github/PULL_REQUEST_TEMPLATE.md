## 变更说明

<!-- 简述本次变更解决什么问题、动了哪些文件 -->

## 变更类型

- [ ] 内容（README / docs）
- [ ] 门禁或脚本（`scripts/`）
- [ ] 协作面（`.github/`）
- [ ] 文档

## 自检 = 命令输出，不是形容词

本仓没有 CI。以下两条**必须由人真实执行**并把输出贴在下面；没有输出 = 未验证，不予合并。

```text
$ bash scripts/check.sh
<完整输出；要求 FAIL=0 ERROR=0；出现 SELF-ERROR 说明检查对象为空，属脚本设计错误>

$ npx --yes markdownlint-cli@0.42.0 README.md docs/*.md
<输出与 exit code>
```

- [ ] 新增的每条能力声称都指向 `repo@branch:path`，且分支写对（`kongming-agent` 与 `Protocol-algorithm` 是 `master`，其余是 `main`）
- [ ] 没有新增外部图片 / 徽章 / 计数器（门禁第 9 项）
- [ ] 没有新增无人引用的数据文件或资产（孤儿文件由第 8 项拦截）
- [ ] 泄露门禁（第 10 项）0 命中：无私有仓名、无内网地址与端口、无个人邮箱、无凭据形态
- [ ] 如新增第三方引用面，已在 `docs/THIRD_PARTY.md` 登记并写明核验日期
- [ ] 如改变了设计决策，已同步 `docs/ARCHITECTURE.md`（不允许留下与现实不符的描述）

## 关联 Issue

<!-- Closes #1 / Refs #2 -->

## 回滚

- [ ] 每个 commit 只包含一个关切，`git revert <sha>` 单个 commit 即可回到上一稳定文案

  禁止在同一 commit 里混改 README 与门禁脚本，否则回滚会连带撤销事实修正。
  注意：**内容回滚不会撤销历史泄露**（见 ARCHITECTURE.md L1）。
