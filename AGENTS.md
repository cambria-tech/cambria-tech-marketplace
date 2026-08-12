# Repository Guidelines

## Project Structure & Module Organization

This repository is a small Codex plugin marketplace. `.agents/plugins/marketplace.json` registers locally available plugins. The plugin itself lives in `plugins/codex-terminal/`: `.codex-plugin/plugin.json` defines package metadata and UI presentation, `skills/control-codex-terminal/SKILL.md` contains the terminal-control behavior, and `skills/control-codex-terminal/agents/openai.yaml` supplies the agent-facing label and default prompt. Keep SVG artwork in `plugins/codex-terminal/assets/`; do not embed binary or base64 assets in metadata.

## Validation and Development Commands

There is no compilation step, package manager, or automated test runner. Run the complete repository gate from the root:

```sh
./scripts/validate.sh
```

The script verifies JSON, YAML, SVG, metadata alignment, placeholders, path portability, and sensitive material. When Codex's validator skills are available, it also runs the official plugin and skill validators. After changing `SKILL.md`, install or load the plugin locally and exercise the affected terminal flow in Codex.

## Coding Style & Naming Conventions

Use two-space indentation in JSON and YAML, descriptive Markdown headings, and short imperative instructions. Keep plugin and skill directories in kebab-case (`codex-terminal`, `control-codex-terminal`); preserve manifest field casing such as `displayName` and `shortDescription`. Keep user-visible metadata synchronized between `plugin.json` and `openai.yaml`. Do not use emoji, external icon URLs, base64 SVG, secrets, machine-specific paths, or undocumented tool names.

## Testing Guidelines

Treat manifest parsing as the minimum gate. For behavioral changes, manually verify the relevant lifecycle: create and display a PTY, send input, hand control to the user, recover after handoff, enter and exit nested sessions, interrupt safely, and close cleanly. Confirm that explicit Codex Terminal requests do not silently fall back to a hidden shell. Document any host capability that could not be exercised.

## Commit & Pull Request Guidelines

Use focused Conventional Commit titles in the form `type: 中文描述`, for example `docs: 完善终端接管说明`. Keep unrelated metadata, behavior, and artwork changes separate. Pull requests should explain the user-visible effect, list validation commands run, link any issue, and include before/after screenshots when icons or interface metadata change.

## Security and Agent Behavior

Never place credentials in manifests, prompts, examples, or shell arguments. Preserve sandbox, approval, user-handoff, destructive-action, and SSH host-key safeguards when editing the skill. A successful command exit is not proof that a deployment, remote operation, or user flow is healthy; verify the result at the appropriate layer.
