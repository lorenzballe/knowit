# feynman — a Feynman-Technique skill for Claude Code / AI agents

Understand any concept deeply enough to **re-teach it** — the whole point of the
[Feynman Technique](https://en.wikipedia.org/wiki/Learning_by_teaching): *if you can't explain
it simply, you don't understand it well enough.*

This is a single-file **skill** (`SKILL.md`) that turns a topic — a concept, an article, your
messy notes, or a piece of code in the current repo — into a map of what to even ask, a clear
explanation, a gap check, a teaching script, a Socratic quiz, memorable analogies, a study plan,
or the one question that would break your understanding if you got it wrong.

It answers in **the user's own language** (auto-detected), and reads real source before
explaining code — it never makes things up.

## Why

A useful test before you trust yourself (or an AI agent) to decide something on its own: *if you
can't explain the logic back in plain language, it should stay a suggestion a human reviews.*
That test catches more silent failure points than most benchmarks. This skill makes running it
one command.

## The 8 modes

| Command | What it does |
|---|---|
| `/feynman map <topic>` | **Map — start here when you don't know what to ask**: the 5–8 things worth understanding, each as a question you should be able to answer, ranked, foundation first (turns *unknown unknowns* into *known unknowns*) |
| `/feynman <topic>` | **Explain like I'm 12** (default): core idea → analogy → example → one-sentence summary → a script you can repeat |
| `/feynman gaps` | You explain it → it finds the exact part you *don't* truly understand + 5 test questions |
| `/feynman script <paste notes>` | Turns messy notes into a **teaching script** you can read aloud |
| `/feynman quiz <topic>` | **Socratic quiz**, one question at a time, difficulty rising |
| `/feynman analogy <topic>` | **5 analogies** + where each one breaks + the best one as a memorable line |
| `/feynman system <topic + deadline>` | A repeatable **study plan** (explain → find gaps → correct → active-recall review) |
| `/feynman break <topic/decision>` | The **breaking question** — the hidden assumption + the edge case nobody tests |

Examples: `/feynman quiz binary search`, `/feynman analogy TCP backpressure`,
`/feynman break "let the agent auto-merge PRs"`.

## Install

The skill is one file (`SKILL.md`). Put it where your agent looks for skills.

**Quick install (symlink, so `git pull` keeps it updated):**

```bash
git clone https://github.com/haunguyendev/feynman-skill.git
cd feynman-skill
./install.sh            # → ~/.claude/skills/feynman  (all your projects)
./install.sh --project  # → ./.claude/skills/feynman  (current repo, committable)
./install.sh --uninstall
```

**Or manually:**

```bash
# Personal, all projects:
mkdir -p ~/.claude/skills/feynman && cp SKILL.md ~/.claude/skills/feynman/

# Per-project (committable to your repo):
mkdir -p .claude/skills/feynman && cp SKILL.md .claude/skills/feynman/
```

Then invoke it as `/feynman ...` in a session (restart the session if it isn't picked up
immediately). It's a plain Markdown skill — no dependencies, no build step.

## Compatibility

Any agent that discovers skills from a `SKILL.md` with YAML frontmatter (e.g. Claude Code and
compatible agent harnesses). The file uses only the standard fields: `name`, `description`,
`user-invocable`, `when_to_use`, `argument-hint`, and `$ARGUMENTS` in the body.

## Credit

The 7 mode templates are **adapted from a public collection of Feynman-technique prompts**;
the skill packaging, mode routing, and wording are original to this repo.

## License

[MIT](LICENSE) — do anything, keep the notice, no warranty.
