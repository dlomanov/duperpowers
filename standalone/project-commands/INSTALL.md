# project-commands — Installation

A standalone skill template for project-specific make targets, test commands, and verification protocols. Not part of duperpowers plugins — install manually per project.

## Option 1: Project-Level (Recommended)

Install into a specific project so the skill applies only there:

```bash
mkdir -p .claude/skills/project-commands
curl -sL https://raw.githubusercontent.com/dlomanov/duperpowers/main/standalone/project-commands/SKILL.md \
  -o .claude/skills/project-commands/SKILL.md
```

Then edit `.claude/skills/project-commands/SKILL.md` to match your project's actual Makefile targets.

## Option 2: User-Level (Global)

Install globally so the skill is available in all projects:

```bash
mkdir -p ~/.claude/skills/project-commands
curl -sL https://raw.githubusercontent.com/dlomanov/duperpowers/main/standalone/project-commands/SKILL.md \
  -o ~/.claude/skills/project-commands/SKILL.md
```

Then edit `~/.claude/skills/project-commands/SKILL.md` to match your workflow.

## Option 3: Tell Claude

```
Fetch and follow instructions from https://raw.githubusercontent.com/dlomanov/duperpowers/main/standalone/project-commands/INSTALL.md
```

Claude will download the template and ask where to install it.

---

## For Claude (fetch-and-follow instructions)

You are an AI assistant helping a user install the project-commands skill. Follow these steps:

1. Ask the user: **"Install project-commands as a project-level skill (current repo only) or user-level skill (all repos)?"**

2. If project-level:
```bash
mkdir -p .claude/skills/project-commands
```
Fetch SKILL.md from `https://raw.githubusercontent.com/dlomanov/duperpowers/main/standalone/project-commands/SKILL.md` and write it to `.claude/skills/project-commands/SKILL.md`.

3. If user-level:
```bash
mkdir -p ~/.claude/skills/project-commands
```
Fetch SKILL.md and write it to `~/.claude/skills/project-commands/SKILL.md`.

4. Tell the user: **"Template installed. Edit the SKILL.md to match your project's actual Makefile targets. The current content is a template with common examples."**
