"""校验 data/*.yml 与 README.md 的一致性。

校验规则 (双向):
  1. data/projects.yml 中 featured=true 的项目, README.md 中必须出现对应 GitHub 链接
  2. README.md "精选项目" 区块中列出的 GitHub 链接, 必须在 data/projects.yml 中存在
  3. data/tech_stack.yml 中所有技术, README.md 徽章 URL 中必须出现对应 badge

设计为 CI 友好: 失败时非零退出, 输出可读报告。
"""
import re
import sys
from pathlib import Path
from typing import Iterable

import yaml

ROOT = Path(__file__).resolve().parent.parent
README = ROOT / "README.md"
DATA_DIR = ROOT / "data"


def load_yaml(name: str) -> dict:
    with (DATA_DIR / name).open(encoding="utf-8") as f:
        return yaml.safe_load(f)


def extract_readme_projects() -> set[str]:
    """从 README 精选项目区块提取 owner/repo 形式的项目标识。"""
    text = README.read_text(encoding="utf-8")
    # 仅在 "精选项目" 区块内查找 (兼容 aria-hidden 包裹的标题)
    match = re.search(
        r"##\s+(?:<span[^>]*>[^<]*</span>\s*)?精选项目(.*?)(?=^##\s|\Z)",
        text,
        re.S | re.M,
    )
    if not match:
        return set()
    section = match.group(1)
    return set(re.findall(r"https://github\.com/([\w.-]+/[\w.-]+)", section))


def extract_readme_tech_badges() -> set[str]:
    """从 README 提取所有技术徽章的"特征名"。

    支持两种来源:
    - shields.io 徽章: 从 URL 段提取 (如 OrangePi-F9A602 -> OrangePi)
    - 本地自托管 SVG: 从 <img alt="..."> 第一段提取
    """
    text = README.read_text(encoding="utf-8")
    names: set[str] = set()

    # 1) shields.io: badge/<Name>-<color>
    for token in re.findall(r"https://img\.shields\.io/badge/([A-Za-z0-9.+_]+)-[0-9A-Fa-f]+", text):
        names.add(token)

    # 2) 本地 SVG: alt="Name: ..." 或 alt="Name"
    for alt in re.findall(r'alt="([^"]+)"', text):
        # 取冒号前的首段作为特征名
        first = alt.split(":")[0].strip()
        if first and not first.lower().startswith(("xfengyin", "profile", "github", "website")):
            names.add(first)

    return names


def main() -> int:
    errors: list[str] = []

    # ---------- projects.yml ----------
    projects = load_yaml("projects.yml")["projects"]
    featured_repos = {p["repo"] for p in projects if p.get("featured", True)}
    readme_repos = extract_readme_projects()

    missing_in_readme = featured_repos - readme_repos
    missing_in_yml = readme_repos - featured_repos

    if missing_in_readme:
        errors.append(
            "[projects] data/projects.yml 中以下项目在 README 缺失:\n  - "
            + "\n  - ".join(sorted(missing_in_readme))
        )
    if missing_in_yml:
        errors.append(
            "[projects] README 中以下项目未在 data/projects.yml 登记:\n  - "
            + "\n  - ".join(sorted(missing_in_yml))
        )

    # ---------- tech_stack.yml ----------
    techs = load_yaml("tech_stack.yml")["tech_stack"]
    tech_names = {t["name"] for t in techs}
    readme_badges = extract_readme_tech_badges()

    missing_badges = tech_names - readme_badges
    if missing_badges:
        errors.append(
            "[tech_stack] data/tech_stack.yml 中以下技术未在 README 徽章出现:\n  - "
            + "\n  - ".join(sorted(missing_badges))
        )

    # ---------- blog.yml ----------
    posts = load_yaml("blog.yml")["posts"]
    blog_urls = {p["url"] for p in posts}
    blog_text = README.read_text(encoding="utf-8")
    # 仅在"最新博客文章"区块内查找
    blog_section_match = re.search(
        r"##\s+(?:<span[^>]*>[^<]*</span>\s*)?最新博客文章(.*?)(?=^##\s|\Z)",
        blog_text,
        re.S | re.M,
    )
    if blog_section_match:
        readme_blog_urls = set(
            re.findall(r"\((https?://[^)]+)\)", blog_section_match.group(1))
        )
    else:
        readme_blog_urls = set()

    missing_blog_in_readme = blog_urls - readme_blog_urls
    if missing_blog_in_readme:
        errors.append(
            "[blog] data/blog.yml 中以下文章未在 README 最新博客文章区块出现:\n  - "
            + "\n  - ".join(sorted(missing_blog_in_readme))
        )

    # 输出结果
    print(f"已加载 {len(projects)} 个项目 (featured={len(featured_repos)}), "
          f"{len(techs)} 项技术栈")
    print(f"README 中识别 {len(readme_repos)} 个项目链接, "
          f"{len(readme_badges)} 个 shields.io 徽章")

    if errors:
        print("\n❌ 一致性校验失败:\n")
        for e in errors:
            print(e)
        print(f"\n修复建议: 同步编辑 data/ 与 README.md, 或运行 "
              f"`python scripts/check_data_consistency.py` 复测")
        return 1

    print("\n✅ data/* 与 README.md 一致性校验通过")
    return 0


if __name__ == "__main__":
    sys.exit(main())
