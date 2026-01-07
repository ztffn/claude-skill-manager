---
description: Install the skill system in current project with auto-detection
allowed-tools: Bash(*), Read, Write, LS
argument-hint: [--force]
---

# Install Skill System

## Current Project Analysis

- **Project root**: !`pwd`
- **Existing .claude directory**: !`ls -la .claude 2>/dev/null || echo "Not found"`
- **Technology stack detected**: !`[ -f package.json ] && echo "Node.js project" || echo "Non-Node.js project"`
- **Git repository**: !`[ -d .git ] && echo "Git repository detected" || echo "No git repository"`

## Installation Process

I'll install the skill system in your current project. This will:

1. ✅ Create `.claude/` directory structure
2. ✅ Copy skill system files and hook scripts  
3. ✅ Generate project-specific configuration
4. ✅ Set up Claude Code settings integration
5. ✅ Initialize skill keyword registry

### Running Installation

!`./.claude/skills/skill-keyword-manager/scripts/install-skill-system.sh $ARGUMENTS`

## Post-Installation

After installation:

1. **Restart Claude Code** to load the new hook system
2. **Test the system** by asking about skills or using keywords  
3. **Check logs** in `.claude/logs/skill-activation.log`
4. **Customize** `.claude/skill-config.json` for your project needs

Use `/skill-status` to verify the installation was successful.