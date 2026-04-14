# FindLie — Multi-Agent Configuration Guide

FindLie works with any AI coding agent that supports the SKILL.md standard.

## Claude Code

### Installation
```bash
git clone https://github.com/stronghuni/FindLie.git ~/.claude/skills/FindLie
cd ~/.claude/skills/FindLie && chmod +x setup && ./setup
```

### Add to CLAUDE.md
Add this to your project's `CLAUDE.md`:

```markdown
## FindLie
Available skills for detecting lie code:
- /find-lie — Standard analysis (6 phases, ~2-5 min)
- /lie-scan — Quick pattern scan (~30 seconds)
- /lie-deep — Deep forensic analysis (~10-30 min)

Skill routing:
- "find lies", "check code", "audit code", "is this real" → invoke find-lie
- "quick scan", "fast check", "pre-commit" → invoke lie-scan
- "deep scan", "full audit", "forensic" → invoke lie-deep
```

### Usage
```
You: /find-lie
You: /lie-scan
You: /lie-deep
```

---

## OpenAI Codex CLI

### Installation
```bash
git clone https://github.com/stronghuni/FindLie.git ~/.codex/skills/FindLie
cd ~/.codex/skills/FindLie && chmod +x setup && ./setup --host codex
```

### Usage
```
codex> /find-lie
```

Codex reads SKILL.md frontmatter for skill discovery. The `name` and `description`
fields trigger automatic invocation when relevant.

---

## OpenClaw

OpenClaw spawns Claude Code sessions via ACP. FindLie works automatically when
Claude Code has it installed.

### Setup
Paste this to your OpenClaw agent:

> Install FindLie: run `git clone https://github.com/stronghuni/FindLie.git ~/.claude/skills/FindLie && cd ~/.claude/skills/FindLie && chmod +x setup && ./setup` to install FindLie for Claude Code. Then add a "FindLie" section to AGENTS.md that says: when spawning Claude Code sessions for code auditing, tell the session to use FindLie skills. Include these examples — quick audit: "Run /lie-scan", full audit: "Run /find-lie", deep forensic: "Run /lie-deep".

### Usage
Talk to your OpenClaw agent:
```
You: Run a lie check on this codebase
→ Spawns Claude Code with: Run /find-lie

You: Quick scan for fake code
→ Spawns Claude Code with: Run /lie-scan
```

---

## Cursor

### Installation
```bash
git clone https://github.com/stronghuni/FindLie.git ~/.cursor/skills/FindLie
cd ~/.cursor/skills/FindLie && chmod +x setup && ./setup --host cursor
```

---

## Factory Droid

### Installation
```bash
git clone https://github.com/stronghuni/FindLie.git ~/.factory/skills/FindLie
cd ~/.factory/skills/FindLie && chmod +x setup && ./setup --host factory
```

---

## Gemini / Antigravity

### Project-level installation
```bash
git clone https://github.com/stronghuni/FindLie.git
cd FindLie && chmod +x setup && ./setup
```

Or add to your project:
```bash
mkdir -p .agents/skills
ln -sfn ~/FindLie/find-lie .agents/skills/find-lie
ln -sfn ~/FindLie/lie-scan .agents/skills/lie-scan
ln -sfn ~/FindLie/lie-deep .agents/skills/lie-deep
```

---

## Adding support for a new agent

FindLie uses the SKILL.md open standard. To add support for any new agent:

1. Find the agent's skills directory (usually `~/.agent-name/skills/`)
2. Symlink FindLie skills into it:
   ```bash
   ln -sfn ~/FindLie/find-lie ~/.new-agent/skills/find-lie
   ln -sfn ~/FindLie/lie-scan ~/.new-agent/skills/lie-scan
   ln -sfn ~/FindLie/lie-deep ~/.new-agent/skills/lie-deep
   ```
3. The agent reads `SKILL.md` frontmatter (`name`, `description`) for discovery
4. The Markdown body contains the execution instructions

If the agent doesn't support `SKILL.md`, the instructions in the Markdown body
can be copied into whatever prompt/instruction format the agent uses.

---

## Uninstall

```bash
# Remove all symlinks
for agent_dir in ~/.claude/skills ~/.codex/skills ~/.cursor/skills ~/.factory/skills ~/.slate/skills ~/.kiro/skills; do
  rm -f "$agent_dir/find-lie" "$agent_dir/lie-scan" "$agent_dir/lie-deep" "$agent_dir/findlie-references" 2>/dev/null
done

# Remove the repo
rm -rf ~/FindLie  # or wherever you cloned it
```
