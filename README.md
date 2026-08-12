# Codex Terminal

[![Codex Plugin](https://img.shields.io/badge/Codex-plugin-101828?logo=openai&logoColor=white)](plugins/codex-terminal/.codex-plugin/plugin.json)
[![Interactive PTY](https://img.shields.io/badge/terminal-interactive%20PTY-344054)](plugins/codex-terminal/skills/control-codex-terminal/SKILL.md)
[![Validation](https://img.shields.io/badge/validation-scripted-027A48)](scripts/validate.sh)
[![License: MIT](https://img.shields.io/badge/license-MIT-175CD3)](LICENSE)
[![Last commit](https://img.shields.io/github/last-commit/felix-liuyj/codex-terminal?label=last%20commit)](https://github.com/felix-liuyj/codex-terminal/commits/main)

<p align="center"><strong>A visible, interactive Terminal surface for Codex tasks.</strong></p>
<p align="center">Create a real PTY, mount it in Codex, share control with the user, work inside nested SSH or CLI sessions, and close it safely.</p>

## Contents

- [Quick start](#quick-start)
- [Capabilities](#capabilities)
- [Repository structure](#repository-structure)
- [Validation](#validation)
- [Safety model](#safety-model)
- [Contributing](#contributing)

## Quick start

### Requirements

- A current Codex desktop or CLI installation with `codex plugin` support.
- A local Codex task; native Terminal tabs are not available to cloud-only tasks.
- `python3`, Ruby, and `xmllint` for repository validation.

From this repository root, register the non-default local marketplace and install the plugin:

```sh
codex plugin marketplace add "$PWD"
codex plugin add codex-terminal@codex-terminal-local
```

Start a new Codex task after installation so the skill is discovered. Select `@codex-terminal`, or ask Codex to create and display an interactive Codex Terminal. The plugin intentionally requires the native Codex Terminal surface when explicitly selected; it does not silently substitute a hidden one-shot shell.

## Capabilities

- Creates persistent PTYs and mounts them in a visible Codex Terminal tab.
- Sends commands, input, and intentional control keys while reporting only new output.
- Supports explicit user handoff and safe recovery before Codex resumes typing.
- Tracks nested shells, SSH, REPLs, database CLIs, and container sessions.
- Handles foreground long-running commands without unrequested background processes.
- Preserves workspace, sandbox, approval, host-key, secret-handling, and destructive-action safeguards.
- Recognizes terminal intent in Chinese, English, Japanese, Korean, Spanish, French, German, Portuguese, Russian, and Arabic.

## Repository structure

```text
.
├── .agents/plugins/marketplace.json       # Local marketplace catalog
├── plugins/codex-terminal/
│   ├── .codex-plugin/plugin.json          # Package and presentation metadata
│   ├── assets/                            # Reviewable SVG artwork
│   └── skills/control-codex-terminal/     # Terminal behavior and agent metadata
├── scripts/validate.sh                    # Repository validation gate
├── AGENTS.md                              # Contributor and agent guidance
└── LICENSE
```

The plugin has no runtime environment variables, external service credentials, package manager, build step, or deployment process. `CODEX_PYTHON` and `CODEX_SKILLS_ROOT` are optional validation-only overrides for locating a Python interpreter with PyYAML and the local official validator skills.

## Validation

Run the complete portable gate:

```sh
./scripts/validate.sh
```

The script parses both JSON manifests, the YAML agent metadata, and every SVG; checks marketplace/manifest identity and visible-label alignment; rejects placeholders, machine-specific paths, embedded base64 images, external metadata icons, and private-key material; then runs the official plugin and skill validators when those local Codex skills are available.

Behavioral changes also require a local Codex acceptance pass: create and mount a PTY, send harmless input, read the mounted Terminal, enter and exit a nested shell, interrupt a foreground command, recover after handoff, and confirm a clean exit. Record any host capability that could not be exercised.

## Safety model

The plugin guides Codex; it does not bypass Codex permissions. Users should type passwords, passphrases, MFA codes, and other secrets directly into the visible Terminal. Do not place credentials in prompts, manifests, examples, command arguments, screenshots, or committed files. A zero exit code is not proof that a remote operation or user flow is healthy; verify results at the appropriate layer.

## Contributing

Read [AGENTS.md](AGENTS.md), keep changes focused, and use `type: 中文描述` Conventional Commit titles. Synchronize user-visible metadata across `plugin.json` and `openai.yaml`. Pull requests should describe the visible behavior change, list validation performed, link related issues, and include before/after images for artwork or presentation changes.

## License and contact

Released under the [MIT License](LICENSE). Maintained by [Felix Liu](https://github.com/felix-liuyj).
