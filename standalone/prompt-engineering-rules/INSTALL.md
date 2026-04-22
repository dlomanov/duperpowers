# prompt-engineering-rules -- Installation

A standalone reference for writing AI instruction files (CLAUDE.md, SKILL.md, etc). Not part of duperpowers plugins -- install manually.

## Option 1: Project-Level (Recommended)

Install into a specific project:

```bash
mkdir -p .claude/skills/prompt-engineering-rules
curl -sL https://raw.githubusercontent.com/dlomanov/duperpowers/main/standalone/prompt-engineering-rules/SKILL.md \
  -o .claude/skills/prompt-engineering-rules/SKILL.md
```

## Option 2: User-Level (Global)

Install globally so the skill is available in all projects:

```bash
mkdir -p ~/.claude/skills/prompt-engineering-rules
curl -sL https://raw.githubusercontent.com/dlomanov/duperpowers/main/standalone/prompt-engineering-rules/SKILL.md \
  -o ~/.claude/skills/prompt-engineering-rules/SKILL.md
```

## Option 3: Tell Claude

```
Fetch and follow instructions from https://raw.githubusercontent.com/dlomanov/duperpowers/main/standalone/prompt-engineering-rules/INSTALL.md
```

Claude will download the reference and ask where to install it.

---

## For Claude (fetch-and-follow instructions)

You are an AI assistant helping a user install the prompt-engineering-rules skill. Follow these steps:

1. Ask the user: **"Install prompt-engineering-rules as a project-level skill (current repo only) or user-level skill (all repos)?"**

2. Check if the SKILL.md already exists at the target path. If it does, ask: **"prompt-engineering-rules is already installed at [path]. Overwrite with the latest version?"** Only overwrite if user confirms.

3. If project-level:
```bash
mkdir -p .claude/skills/prompt-engineering-rules
```
Fetch SKILL.md from `https://raw.githubusercontent.com/dlomanov/duperpowers/main/standalone/prompt-engineering-rules/SKILL.md` and write it to `.claude/skills/prompt-engineering-rules/SKILL.md`.

4. If user-level:
```bash
mkdir -p ~/.claude/skills/prompt-engineering-rules
```
Fetch SKILL.md and write it to `~/.claude/skills/prompt-engineering-rules/SKILL.md`.

5. Tell the user: **"Reference installed. It will be available as a skill in your next session."**
