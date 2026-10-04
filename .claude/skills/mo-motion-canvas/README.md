# Motion Canvas Skill for Claude Code

A Claude Code skill for creating programmatic vector animations with TypeScript using the [Motion Canvas](https://motioncanvas.io/) library. Build animated explainer videos, tutorials, data visualizations, and presentations with synchronized audio.

## What are Skills?

Skills are markdown files that give AI agents specialized knowledge and workflows for specific tasks. When you add this skill to your project, Claude Code can recognize when you're working on animation tasks and apply the right frameworks and best practices.

## Available Skills

| Skill | Description | Triggers |
|-------|-------------|----------|
| [motion-canvas](SKILL.md) | Create programmatic animations with TypeScript | "motion canvas," "animate," "explainer video," "code animation" |

## Installation

### Option 1: CLI Install (Recommended)

Use [add-skill](https://github.com/vercel-labs/add-skill) to install skills directly:

```bash
# Install the skill
npx add-skill apoorvlathey/motion-canvas-skills
```

This automatically installs to your `.claude/skills/` directory.

### Option 2: Claude Code Plugin

Install via Claude Code's built-in plugin system:

```bash
# Add the marketplace
/plugin marketplace add apoorvlathey/motion-canvas-skills

# Install the skill
/plugin install motion-canvas
```

### Option 3: Clone and Copy

Clone the entire repo and copy the skill:

```bash
git clone https://github.com/apoorvlathey/motion-canvas-skills.git
cp -r motion-canvas-skills/SKILL.md .claude/skills/motion-canvas/
cp -r motion-canvas-skills/references .claude/skills/motion-canvas/
```

### Option 4: Git Submodule

Add as a submodule for easy updates:

```bash
git submodule add https://github.com/apoorvlathey/motion-canvas-skills.git .claude/motion-canvas-skills
```

Then reference skills from `.claude/motion-canvas-skills/`.

### Option 5: Fork and Customize

1. Fork this repository
2. Customize the skill for your specific needs
3. Clone your fork into your projects

## Usage

Once installed, just ask Claude Code to help with animation tasks:

```
"Create an animated explainer video showing how binary search works"
→ Uses motion-canvas skill

"Help me animate a logo reveal"
→ Uses motion-canvas skill

"Build a scene with code syntax highlighting transitions"
→ Uses motion-canvas skill

"Create a data visualization animation"
→ Uses motion-canvas skill
```

You can also invoke the skill directly:

```
/motion-canvas
```

## Skill Structure

```
motion-canvas-skills/
├── SKILL.md                 # Main skill instructions
└── references/
    ├── api-reference.md     # Comprehensive API documentation
    └── patterns.md          # Common animation patterns and examples
```

The `SKILL.md` file follows this format:

```markdown
---
name: motion-canvas
description: One-line description for skill selection
---

# Motion Canvas

[Full instructions for the AI agent]
```

## Resources

- [Motion Canvas Documentation](https://motioncanvas.io/docs/)
- [Motion Canvas GitHub](https://github.com/motion-canvas/motion-canvas)
- [Motion Canvas Examples](https://motioncanvas.io/examples/)

## License

MIT - Use this however you want.
