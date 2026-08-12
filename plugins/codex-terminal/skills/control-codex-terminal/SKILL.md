---
name: control-codex-terminal
description: "Create, show, inspect, and jointly control an interactive Codex Terminal or SSH PTY, including persistent sessions, command input, control keys, output polling, handoff, reconnect guidance, and clean shutdown. Use for explicit @codex-terminal or Codex Terminal requests and multilingual terminal intent: terminal, shell, console, command line, SSH; 终端, 控制台, 命令行, 远程终端; ターミナル, 端末; 터미널, 콘솔; consola; ligne de commande; Konsole; linha de comando; терминал, консоль; طرفية, وحدة التحكم."
---

# Codex Terminal

## Select the Terminal surface

Treat an explicit `Codex Terminal`, `@codex-terminal`, or plugin selection as a hard surface requirement. Use the Codex native PTY and Terminal panel. Do not substitute Computer Use, macOS `open`, a hidden one-shot command, or a separate terminal app unless the user requests that fallback.

Prefer purpose-built APIs for semantic external-service operations unless the user explicitly wants a terminal workflow. Continue using the terminal for shell, build, test, log, process, REPL, database CLI, container CLI, and SSH work.

Use these host tools, discovering deferred tools when necessary:

- `exec_command`: start commands and interactive PTYs.
- `write_stdin`: send input or poll a PTY by `session_id`.
- `codex_app__open_in_codex`: display a PTY as a Codex Terminal tab.
- `codex_app__read_thread_terminal`: read the current task Terminal when no writable session handle is available.

If a required native tool is unavailable, report the exact missing capability. Do not claim a visible or controllable terminal was created.

## Session model

Track one primary shared Terminal per task unless the user requests multiple sessions. Preserve its `session_id`, working directory, shell, nesting state, and whether the user or Codex currently owns input. Reuse it across turns while it remains alive.

Use these states:

1. `none`: no known writable PTY.
2. `starting`: PTY creation has not returned a `session_id` yet.
3. `ready`: shell prompt is available.
4. `running`: a foreground command is executing.
5. `waiting`: the program is requesting input.
6. `user-control`: the visible Terminal is handed to the user; do not type until asked.
7. `nested`: inside SSH, REPL, database CLI, container shell, or another subshell.
8. `exited`: the PTY returned an exit code and must not receive more input.

Do not invent session discovery. `codex_app__read_thread_terminal` can read a visible Terminal but does not provide a writable `session_id`. If the current task lost the session handle, read its state and explain that Codex can inspect it but must create a new shared PTY to regain write control.

## Create and show a shared Terminal

For a clean local shell, start a PTY with `exec_command` using:

- `cmd`: `exec /bin/zsh -f`
- `tty`: `true`
- `login`: `false`
- `workdir`: the current workspace or the user's requested directory
- `yield_time_ms`: about `1000`

Use the user's requested shell when specified. Avoid interactive login startup files by default because they can mutate user caches, print secrets, block on prompts, or fail inside the sandbox.

When `exec_command` returns a live `session_id`, immediately show it with `codex_app__open_in_codex`:

```json
{
  "target": { "type": "terminal", "sessionId": "<session-id>" },
  "placement": "bottom"
}
```

Use the requested placement. Default to `bottom` for terminal ergonomics; use `right` when the user asks or the bottom panel is unsuitable.

If opening returns `queued`, keep the same session. Tell the user it will appear when the local task is visible. Do not create a duplicate PTY.

After mounting, send one harmless marker and `pwd` only when useful to verify the binding. Never print environment variables, tokens, SSH keys, command history, or credential files as a connectivity test.

Terminals require a local task. If the current task is cloud-only or remote and the native panel rejects the request, explain the boundary and offer a one-shot command or user-owned local Terminal only with user approval.

## Read, write, and poll

Use `write_stdin` with the primary `session_id`:

- Send a command with a trailing newline.
- Poll without input by omitting `chars` or passing an empty string.
- Use a short yield after ordinary input and a longer yield for builds, tests, or remote commands.
- Report only new output returned by the tool; do not imply old output is new.

Use control characters only when their meaning is clear:

| Action | Input |
| --- | --- |
| Interrupt foreground process | `\u0003` (`Control-C`) |
| End input / exit many shells | `\u0004` (`Control-D`) |
| Suspend foreground process | `\u001a` (`Control-Z`) |
| Escape | `\u001b` |

Do not send control keys speculatively. Inspect output first. If a command may be doing a consequential write, do not interrupt it unless the user asks or interruption is necessary to avoid greater harm.

## User and Codex co-control

When the user asks to take over, set the session to `user-control`, keep it open, and stop sending input. Continue only after an explicit request such as “继续操作当前 Terminal” or “接管终端”.

Avoid simultaneous typing. Before sending input after a user handoff, read the current Terminal state or poll the PTY so the command is not inserted into partially typed user text.

Ask the user to type passwords, passphrases, MFA codes, recovery codes, private keys, and other secrets directly into the visible Terminal. Never request those values in chat, echo them, save them in plugin files, or pass them through command arguments when a safer prompt is available.

## SSH and nested sessions

Prefer a configured SSH alias, for example `ssh host-alias`, instead of expanding key paths or credentials into commands. Use `-o IdentitiesOnly=yes` only when needed and already supported by the user's config.

Before persistent SSH monitoring, state the connection target, purpose, resource use, and stop method. Do not enable `ForwardAgent`, copy private keys, weaken host-key checking, or accept a changed host key without explicit verification.

Track nesting. One `exit` from an SSH session normally returns to the local shell; a second `exit` closes the local PTY. Verify the prompt or exit result after each step rather than sending repeated exits blindly.

## Long-running commands

Use the foreground PTY by default. Do not add `&`, `nohup`, detached containers, background agents, or persistent watchers unless the user requests them or they are genuinely required.

For authorized long-running work:

1. State the command, purpose, expected resource usage, port or external target, and stop method.
2. Start it in the shared PTY.
3. Poll at useful intervals without busy waiting.
4. Keep the user updated at least once per minute.
5. Stop with the application's normal shutdown path or `Control-C` before stronger termination.

## Safety and compliance

The plugin does not bypass Codex approvals, sandboxing, workspace boundaries, or Computer Use confirmation policy. Apply the user's current instruction, repository rules, and the host's destructive-action policy to every command.

Before commands that delete or overwrite material data, change credentials, expand persistent access, alter security or network settings, deploy, migrate, restart production, or perform irreversible external actions:

1. Resolve the exact target with read-only checks.
2. Confirm the action is within the user's request.
3. Obtain any confirmation required at action time.
4. Prefer reversible and scoped operations.
5. Verify the result and disclose remaining risk.

Never use unresolved broad targets such as `$HOME`, `~`, `/`, workspace roots, wildcards, or unvalidated variables in destructive commands. Never expose secrets through `set -x`, `env`, shell history, process arguments, logs, screenshots, or chat output.

Do not treat a successful shell exit code as proof that a service, deployment, migration, upload, or user flow is healthy. Verify at the appropriate layer.

## Close and recover

Close cleanly:

1. Inspect whether the PTY is nested.
2. Exit the nested program first.
3. Exit the local shell with `exit` or `Control-D`.
4. Confirm `write_stdin` returns an exit code.
5. Report that the PTY ended and distinguish it from any server-side process left running.

Use `Control-C` before terminating a foreground process. Use forced termination only when graceful shutdown repeatedly fails and the user authorized the impact.

If a session is already closed, do not write to its stale ID. Create a new PTY only when the user still wants a Terminal.

## Multilingual trigger behavior

Respond in the user's language. Interpret common terminal requests across supported languages, including:

- Chinese: `终端`, `控制台`, `命令行`, `远程终端`, `打开 SSH`.
- English: `terminal`, `shell`, `console`, `command line`, `open SSH`.
- Japanese: `ターミナル`, `端末`, `コマンドライン`, `SSH を開く`.
- Korean: `터미널`, `콘솔`, `명령줄`, `SSH 열기`.
- Spanish: `terminal`, `consola`, `línea de comandos`, `abrir SSH`.
- French: `terminal`, `console`, `ligne de commande`, `ouvrir SSH`.
- German: `Terminal`, `Konsole`, `Befehlszeile`, `SSH öffnen`.
- Portuguese: `terminal`, `console`, `linha de comando`, `abrir SSH`.
- Russian: `терминал`, `консоль`, `командная строка`, `открыть SSH`.
- Arabic: `طرفية`, `وحدة التحكم`, `سطر الأوامر`, `فتح SSH`.

Explicit plugin selection always wins regardless of language. Do not require the user to repeat the request in English.
