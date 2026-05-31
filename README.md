# AI Expert Skills / AI 专家技能库

[English](#english) | [中文](#chinese)

<a name="english"></a>

## 🇬🇧 English

A curated collection of refined skill definitions that turn your AI coding assistant into a domain-specific expert. Distributed as **Claude Code plugins** through a built-in plugin marketplace, and also usable as plain skills in Open Code, Cursor, and Trae.

Each skill provides structured, high-quality context — when to engage, when not to, concrete guidance, and runnable examples — so your assistant behaves like a focused expert instead of a generalist.

### Repository Layout

```
coding-agent-skills/
├── .claude-plugin/
│   └── marketplace.json          # marketplace catalog (lists all plugins)
├── plugins/
│   ├── competitive-programming-expert/
│   │   ├── .claude-plugin/plugin.json
│   │   └── skills/competitive-programming-expert/SKILL.md
│   ├── cpp-expert/ …
│   ├── python-expert/ …
│   ├── deep-learning-expert/ …
│   ├── llm-testing-expert/ …
│   ├── software-architect/ …
│   ├── github-master/ …
│   └── threejs/                  # bundles all 10 Three.js skills
│       └── skills/threejs-*/SKILL.md
└── rules/                        # Cursor-style coding-standard rules (not a plugin)
```

Each plugin is a self-contained directory with a `.claude-plugin/plugin.json` manifest; its skills live in `skills/<slug>/SKILL.md`. The marketplace name is **`ai-expert-skills`**.

### Plugins Included

| Plugin | Skills | Description |
|--------|--------|-------------|
| **competitive-programming-expert** | 1 | Algorithmic problem solving, complexity analysis, optimization (LeetCode/Codeforces/AtCoder). |
| **cpp-expert** | 1 | Modern C++ (17/20/23), memory safety, RAII, move semantics, performance. |
| **python-expert** | 1 | Pythonic code, typing, async, standard-library usage, performance. |
| **deep-learning-expert** | 1 | Model architecture, training strategies, debugging, paper interpretation. |
| **llm-testing-expert** | 1 | Evaluation strategies, prompt engineering, red teaming, regression testing. |
| **software-architect** | 1 | System design, technology selection, trade-off analysis. |
| **github-master** | 1 | Git workflows, repo management, PRs, GitHub Actions CI/CD. |
| **threejs** | 10 | Full Three.js set: fundamentals, geometry, materials, lighting, textures, animation, loaders, shaders, post-processing, interaction. |

### Install via Claude Code (recommended)

Add the marketplace once, then install any plugin from it.

```bash
# 1. Register the marketplace (from the GitHub repo)
/plugin marketplace add Miaoge-Ge/coding-agent-skills

# 2. Install the plugins you want
/plugin install cpp-expert@ai-expert-skills
/plugin install threejs@ai-expert-skills
/plugin install software-architect@ai-expert-skills

# Or browse and install interactively
/plugin
```

Equivalent non-interactive CLI:

```bash
claude plugin marketplace add Miaoge-Ge/coding-agent-skills
claude plugin install cpp-expert@ai-expert-skills
```

Update later with `/plugin marketplace update ai-expert-skills`. Manage installs in the `/plugin` menu.

> **Local development:** from a clone of this repo you can register the marketplace by path — `claude plugin marketplace add ./` — then `claude plugin install <name>@ai-expert-skills`.

### Use without the plugin system

The skills are plain `SKILL.md` files, so you can also copy them directly:

- **Claude Code / Open Code:** copy `plugins/<plugin>/skills/<slug>/` into `.claude/skills/` (project) or `~/.claude/skills/` (global).
- **Cursor:** copy into `.cursor/skills/`.
- **Trae:** copy into `.trae/skills/`.

For the Three.js bundle, copy the individual skill folders under `plugins/threejs/skills/`.

### Coding-Standard Rules

`rules/` holds Cursor-style rules that auto-attach by file glob (they are **not** part of the Claude Code plugins):

| Rule | Scope | File |
|------|-------|------|
| **cpp-style-guide** | `*.cpp,*.hpp,*.h,*.cc,*.cxx` | [View](rules/cpp-style-guide.md) |
| **python-style-guide** | `*.py,*.pyi` | [View](rules/python-style-guide.md) |

Place them where your editor expects rule files (e.g., Cursor's `.cursor/rules/`).

### How It Works

Once a plugin is installed, Claude Code auto-discovers its skills and engages the right one based on each skill's `description`. Example triggers:

- Create a 3D scene → `threejs` (fundamentals)
- Add lighting and shadows → `threejs` (lighting)
- Load a GLTF model → `threejs` (loaders + animation)
- Solve a contest problem → `competitive-programming-expert`
- Design a distributed system → `software-architect`

### Skill File Structure

Each `SKILL.md` uses YAML frontmatter plus Markdown:

```markdown
---
name: skill-slug          # [a-z0-9-]+, matches its directory name
description: "When to engage, with trigger keywords. Quoted when it contains a colon."
---
```

The body of a **general skill** follows a consistent layout:

```markdown
# Skill Title

## Role / Description    # who the expert is
## When to Use           # concrete activation triggers
## When NOT to Use       # boundaries + which skill to defer to
## Guidelines            # the actual expertise
## Examples              # runnable code / patterns
## See Also              # cross-references to related skills
```

Workflow-heavy skills (`software-architect`, `deep-learning-expert`, `llm-testing-expert`, `competitive-programming-expert`) additionally include `Input`/`Output` contracts, step-by-step `Execution Steps`, and `Failure Handling`. The Three.js skills are example-driven, leading with a runnable quick start.

### License

MIT — see [LICENSE](LICENSE).

---

<a name="chinese"></a>

## 🇨🇳 中文

一套精心打磨的技能定义，可将你的 AI 编程助手变成特定领域的专家。以 **Claude Code 插件**形式通过内置插件市场分发，同时也能作为普通技能用于 Open Code、Cursor、Trae。

每个技能都提供结构化、高质量的上下文——何时启用、何时不启用、具体指导以及可运行示例——让助手表现得像一位聚焦的专家，而不是泛泛而谈。

### 仓库结构

```
coding-agent-skills/
├── .claude-plugin/
│   └── marketplace.json          # 市场目录（列出全部插件）
├── plugins/
│   ├── competitive-programming-expert/
│   │   ├── .claude-plugin/plugin.json
│   │   └── skills/competitive-programming-expert/SKILL.md
│   ├── cpp-expert/ …
│   ├── python-expert/ …
│   ├── deep-learning-expert/ …
│   ├── llm-testing-expert/ …
│   ├── software-architect/ …
│   ├── github-master/ …
│   └── threejs/                  # 打包全部 10 个 Three.js 技能
│       └── skills/threejs-*/SKILL.md
└── rules/                        # Cursor 风格代码规范（不属于插件）
```

每个插件都是独立目录，含 `.claude-plugin/plugin.json` 清单；其技能位于 `skills/<slug>/SKILL.md`。市场名称为 **`ai-expert-skills`**。

### 包含的插件

| 插件 | 技能数 | 描述 |
|------|--------|------|
| **competitive-programming-expert** | 1 | 算法解题、复杂度分析与优化（LeetCode/Codeforces/AtCoder）。 |
| **cpp-expert** | 1 | 现代 C++（17/20/23）、内存安全、RAII、移动语义、性能调优。 |
| **python-expert** | 1 | Pythonic 代码、类型标注、异步、标准库与性能优化。 |
| **deep-learning-expert** | 1 | 模型架构设计、训练策略、调试与论文解读。 |
| **llm-testing-expert** | 1 | 评测策略、提示词工程、红队测试与回归测试。 |
| **software-architect** | 1 | 系统设计、技术选型与架构权衡分析。 |
| **github-master** | 1 | Git 工作流、仓库管理、PR 与 GitHub Actions CI/CD。 |
| **threejs** | 10 | 完整 Three.js 套件：基础、几何体、材质、灯光、纹理、动画、加载器、着色器、后处理、交互。 |

### 通过 Claude Code 安装（推荐）

只需添加一次市场，之后即可按需安装其中的插件。

```bash
# 1. 注册市场（从 GitHub 仓库）
/plugin marketplace add Miaoge-Ge/coding-agent-skills

# 2. 安装你需要的插件
/plugin install cpp-expert@ai-expert-skills
/plugin install threejs@ai-expert-skills
/plugin install software-architect@ai-expert-skills

# 或交互式浏览安装
/plugin
```

等价的非交互式 CLI：

```bash
claude plugin marketplace add Miaoge-Ge/coding-agent-skills
claude plugin install cpp-expert@ai-expert-skills
```

之后用 `/plugin marketplace update ai-expert-skills` 更新；在 `/plugin` 菜单中管理已安装插件。

> **本地开发：** 在本仓库的克隆中可用路径注册市场——`claude plugin marketplace add ./`——再执行 `claude plugin install <name>@ai-expert-skills`。

### 不使用插件系统时

技能本质上就是 `SKILL.md` 文件，也可以直接复制使用：

- **Claude Code / Open Code：** 将 `plugins/<plugin>/skills/<slug>/` 复制到 `.claude/skills/`（项目级）或 `~/.claude/skills/`（全局）。
- **Cursor：** 复制到 `.cursor/skills/`。
- **Trae：** 复制到 `.trae/skills/`。

对于 Three.js 套件，复制 `plugins/threejs/skills/` 下的各技能文件夹即可。

### 代码规范规则

`rules/` 存放 Cursor 风格规则，按文件 glob 自动挂载（**不**属于 Claude Code 插件）：

| 规则 | 适用范围 | 文件 |
|------|----------|------|
| **cpp-style-guide** | `*.cpp,*.hpp,*.h,*.cc,*.cxx` | [查看](rules/cpp-style-guide.md) |
| **python-style-guide** | `*.py,*.pyi` | [查看](rules/python-style-guide.md) |

将其放到编辑器期望的规则目录（例如 Cursor 的 `.cursor/rules/`）。

### 工作原理

插件安装后，Claude Code 会自动发现其技能，并根据每个技能的 `description` 启用最匹配的那个。常见触发示例：

- 搭建 3D 场景 → `threejs`（基础）
- 添加灯光与阴影 → `threejs`（灯光）
- 加载 GLTF 模型 → `threejs`（加载器 + 动画）
- 解算法竞赛题 → `competitive-programming-expert`
- 设计分布式系统 → `software-architect`

### 技能文件结构

每个 `SKILL.md` 由 YAML frontmatter 加 Markdown 正文组成：

```markdown
---
name: skill-slug          # [a-z0-9-]+，与目录名一致
description: "何时启用，含触发关键词；含冒号时需加引号。"
---
```

**通用技能**正文采用统一布局：

```markdown
# 技能标题

## Role / Description    # 该专家是谁
## When to Use           # 具体触发条件
## When NOT to Use       # 边界，以及应转交哪个技能
## Guidelines            # 核心专业知识
## Examples              # 可运行代码 / 模式
## See Also              # 关联技能交叉引用
```

工作流型技能（`software-architect`、`deep-learning-expert`、`llm-testing-expert`、`competitive-programming-expert`）还包含 `Input`/`Output` 契约、分步 `Execution Steps` 与 `Failure Handling`。Three.js 系列以示例驱动，以可运行的快速上手开头。

### 许可证

MIT —— 见 [LICENSE](LICENSE)。
