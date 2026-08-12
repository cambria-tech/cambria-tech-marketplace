# Codex Terminal

简体中文 | [English](README.en.md)

[![Codex Plugin](https://img.shields.io/badge/Codex-plugin-101828?logo=openai&logoColor=white)](plugins/codex-terminal/.codex-plugin/plugin.json)
[![Interactive PTY](https://img.shields.io/badge/terminal-interactive%20PTY-344054)](plugins/codex-terminal/skills/control-codex-terminal/SKILL.md)
[![Validation](https://img.shields.io/badge/validation-scripted-027A48)](scripts/validate.sh)
[![License: MIT](https://img.shields.io/badge/license-MIT-175CD3)](LICENSE)
[![Last commit](https://img.shields.io/github/last-commit/cambria-tech/cambria-tech-marketplace?label=last%20commit)](https://github.com/cambria-tech/cambria-tech-marketplace/commits/main)

<p align="center">
  <img src="plugins/codex-terminal/assets/codex-terminal.svg" width="128" height="128" alt="Codex Terminal 标志">
</p>

<p align="center"><strong>面向 Codex 任务的可见、可交互 Terminal。</strong></p>
<p align="center">创建真实 PTY，在 Codex 内显示终端，与用户共享控制权，在嵌套 SSH 或 CLI 会话中持续工作，并安全关闭会话。</p>
<p align="center">由 <a href="https://www.cambria-tech.com">Cambria Tech</a> 通过 Cambria Tech Marketplace 发布。</p>

## 目录

- [为什么使用 Codex Terminal](#为什么使用-codex-terminal)
- [从 GitHub 安装](#从-github-安装)
- [使用插件](#使用插件)
- [更新或卸载](#更新或卸载)
- [能力与边界](#能力与边界)
- [仓库结构](#仓库结构)
- [开发与验证](#开发与验证)
- [参与贡献](#参与贡献)
- [许可证与联系方式](#许可证与联系方式)

## 为什么使用 Codex Terminal

Codex Terminal 为显式选择终端的任务创建真实的交互式 PTY，并将其显示为 Codex 原生 Terminal 标签。与隐藏的一次性 shell 命令不同，会话会保持可见和可写，因此用户与 Codex 可以共同查看输出、轮流输入、响应交互提示、中断前台任务，并在不丢失会话上下文的情况下进入或退出嵌套 shell。

本插件为 Codex 提供行为指导，不构成权限边界。宿主环境的工作区、沙箱、审批、敏感信息处理、SSH 主机密钥校验和破坏性操作保护仍然有效。

## 从 GitHub 安装

### 环境要求

- 当前版本的 Codex 桌面端或 CLI，并支持 `codex plugin`。
- 本地 Codex 任务。仅云端运行的任务无法使用原生 Terminal 标签。

注册已发布的 Marketplace、安装插件并验证发现状态：

```sh
codex plugin marketplace add cambria-tech/cambria-tech-marketplace
codex plugin add codex-terminal@cambria-tech-marketplace
codex plugin list --marketplace cambria-tech-marketplace
```

安装完成后请新建一个 Codex 任务，让 Codex 加载该技能。已经打开的任务不会自动获得新安装的插件能力。

## 使用插件

在新建的本地任务中选择 `@codex-terminal`，或在请求中明确要求使用 Codex Terminal。例如：

```text
使用 @codex-terminal 创建并显示一个我可以接管的交互式终端。
使用 @codex-terminal 通过我已配置的主机别名打开 SSH。
Use @codex-terminal to create and show an interactive Terminal for this task.
```

显式选择插件后，Codex 必须使用原生 Codex Terminal。如果宿主无法创建或显示可控制的 PTY，Codex 应说明缺失的能力，不得静默替换为隐藏式 shell。

输入密码、口令、MFA 验证码、恢复码及其它敏感信息时，请接管可见 Terminal 并直接在其中输入。不要通过聊天发送敏感信息。

## 更新或卸载

刷新 GitHub Marketplace 快照、重新安装当前插件版本，然后新建一个任务：

```sh
codex plugin marketplace upgrade cambria-tech-marketplace
codex plugin add codex-terminal@cambria-tech-marketplace
```

不再需要插件时，可以执行：

```sh
codex plugin remove codex-terminal@cambria-tech-marketplace
```

## 能力与边界

| 范围 | 支持的行为 |
| --- | --- |
| PTY 生命周期 | 创建、显示、复用、检查、中断和关闭持久化交互会话 |
| 共享控制 | 将输入权交给用户，并在 Codex 恢复输入前安全接管 |
| 嵌套会话 | 跟踪本地 shell、SSH、REPL、数据库 CLI 和容器 shell |
| 长时间任务 | 在前台保持命令可见并轮询结果，不擅自创建后台进程 |
| 控制输入 | 仅在检查会话状态后，有目的地发送 `Control-C`、`Control-D`、`Control-Z` 或 Escape |
| 多语言 | 识别中文、英语、日语、韩语、西班牙语、法语、德语、葡萄牙语、俄语和阿拉伯语终端意图 |
| 安全 | 保留 Codex 权限、沙箱、审批、主机密钥校验和破坏性操作保护 |

命令成功退出并不能证明部署、迁移、上传或远程服务处于健康状态。对有实际影响的结果，必须在相应的应用或基础设施层继续验证。

## 仓库结构

```text
.
├── .agents/plugins/marketplace.json       # 已发布的 Marketplace 目录
├── plugins/codex-terminal/
│   ├── .codex-plugin/plugin.json          # 插件包与展示元数据
│   ├── assets/                            # 可审查的 SVG 资源
│   └── skills/control-codex-terminal/     # Terminal 行为与 Agent 元数据
├── scripts/validate.sh                    # 完整仓库验证入口
├── AGENTS.md                              # 贡献者与 Agent 协作规范
├── README.md                              # 中文文档
├── README.en.md                           # 英文文档
└── LICENSE                                # MIT 许可证
```

本插件没有运行时环境变量、外部服务凭据、包管理器、编译步骤或部署流程。

## 开发与验证

克隆仓库并执行完整的可移植验证入口：

```sh
git clone https://github.com/cambria-tech/cambria-tech-marketplace.git
cd cambria-tech-marketplace
./scripts/validate.sh
```

该脚本会解析 Marketplace 与插件 manifest、Agent YAML 和所有 SVG；检查元数据一致性与 Marketplace 策略；拒绝占位符、机器专属路径、内嵌 base64 图片、外链元数据图标和常见私钥或 token 内容；如果本机存在 Codex 官方验证技能，还会运行官方插件与技能 validator。

`CODEX_PYTHON` 和 `CODEX_SKILLS_ROOT` 是仅用于验证的可选覆盖项，用来定位带有 PyYAML 的 Python 解释器和本地官方 validator 技能。可移植验证需要 `python3`、Ruby、`xmllint` 和 `rg`。

如果修改了插件行为，还需要完成一次本地 Codex 验收：创建并显示 PTY、发送无害输入、读取已挂载的 Terminal、进入和退出嵌套 shell、中断前台命令、在用户接管后恢复控制，并确认会话干净退出。任何无法在宿主中实际执行的能力都应如实记录。

## 参与贡献

请先阅读 [AGENTS.md](AGENTS.md)，保持变更范围集中，并使用 `type: 中文描述` 格式的 Conventional Commit 标题。用户可见的元数据需要在 `plugin.json` 与 `openai.yaml` 之间保持同步。Pull Request 应说明用户可见变化、列出已执行的验证、关联相关 Issue；涉及图标或界面元数据变化时，还应附上修改前后的图片。

## 许可证与联系方式

本项目依据 [MIT License](LICENSE) 发布，由 [Cambria Tech](https://www.cambria-tech.com) 发布和维护。联系邮箱：[cloud@cambria-tech.com](mailto:cloud@cambria-tech.com)。
