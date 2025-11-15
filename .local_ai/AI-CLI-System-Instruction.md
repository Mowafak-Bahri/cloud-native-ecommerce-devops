🤖 Optimized System Prompts for All AI Tools

✔ Claude CLI System Instruction
Save as:
.local_ai/claude/INSTRUCTIONS.md

```bash
SYSTEM INSTRUCTION — CLAUDE LOCAL PROJECT MODE

From now on:

1. ALL non-project files (notes, drafts, summaries, experiment logs) must be written ONLY inside .local_ai/claude.
2. NEVER create or modify project files unless the user says: "This is project code".
3. Scratch or step-by-step reasoning → .local_ai/claude/scratch.md
4. Summaries → .local_ai/claude/summary.md
5. Logs → .local_ai/logs/
6. NEVER generate files outside .local_ai unless directly asked.
7. ALWAYS confirm before editing or writing ANY project file.
```

To activate:
```bash
claude
```
Then paste:

```bash
Load the system instructions from .local_ai/claude/INSTRUCTIONS.md
```


✔ ChatGPT Codex CLI System Prompt

Save as:

.local_ai/codex/INSTRUCTIONS.md

```bash
SYSTEM — CODEX PROJECT GUARD

- All AI-generated files → .local_ai/codex/
- Never output files in project root.
- Never modify any project file unless user explicitly writes "modify project".
- Summaries → .local_ai/codex/summary.md
- Logs → .local_ai/logs/codex.log
- All reasoning must stay inside .local_ai and not appear in commit history.
```

To activate:
```bash
codex
Load instructions from .local_ai/codex/INSTRUCTIONS.md
```


✔ Gemini CLI System Instruction
Save as:
.local_ai/codex/INSTRUCTIONS.md
```bash
SYSTEM — GEMINI SAFE WORKSPACE MODE

Rules:
- Only create files inside .local_ai/gemini/.
- No editing project files without explicit user command.
- Temporary content → .local_ai/tmp/
- Scratch → .local_ai/gemini/scratch.md
- Summaries → .local_ai/gemini/summary.md
- Logs → .local_ai/logs/
- Never touch the root repo unless user permits.

```

To activate:
```bash
gemini
load .local_ai/gemini/INSTRUCTIONS.md
```

