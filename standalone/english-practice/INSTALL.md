# english-practice — Installation

A standalone skill for passive English practice. Responds in English regardless of input language, corrects up to 2 grammar mistakes per response. Not part of duperpowers plugins — install manually.

## Option 1: User-Level (Recommended)

Install globally so the skill is available in all projects:

```bash
mkdir -p ~/.claude/skills/english-practice
curl -sL https://raw.githubusercontent.com/dlomanov/duperpowers/main/standalone/english-practice/SKILL.md \
  -o ~/.claude/skills/english-practice/SKILL.md
```

## Option 2: Project-Level

Install into a specific project so the skill applies only there:

```bash
mkdir -p .claude/skills/english-practice
curl -sL https://raw.githubusercontent.com/dlomanov/duperpowers/main/standalone/english-practice/SKILL.md \
  -o .claude/skills/english-practice/SKILL.md
```

## Option 3: Tell Claude

```
Fetch and follow instructions from https://raw.githubusercontent.com/dlomanov/duperpowers/main/standalone/english-practice/INSTALL.md
```

Claude will download the skill and ask where to install it.

---

## For Claude (fetch-and-follow instructions)

You are an AI assistant helping a user install the english-practice skill. Follow these steps:

1. Ask the user: **"Install english-practice as a user-level skill (all repos, recommended) or project-level skill (current repo only)?"**

2. Check if the SKILL.md already exists at the target path. If it does, ask: **"english-practice is already installed at [path]. Overwrite with the latest version?"** Only overwrite if user confirms.

3. If user-level:
```bash
mkdir -p ~/.claude/skills/english-practice
```
Fetch SKILL.md from `https://raw.githubusercontent.com/dlomanov/duperpowers/main/standalone/english-practice/SKILL.md` and write it to `~/.claude/skills/english-practice/SKILL.md`.

4. If project-level:
```bash
mkdir -p .claude/skills/english-practice
```
Fetch same URL, write it to `.claude/skills/english-practice/SKILL.md`.

5. Tell the user: **"Skill installed. Start a new session to activate english-practice."**
