# Claude Code Skill System

A skill management system for Claude Code that provides skill activation through keyword analysis of prompts. Inspired by https://scottspence.com/posts/how-to-make-claude-code-skills-activate-reliably designed to work programmatically to save tokens.

## Overview

This package sets up a skill system in Claude Code projects. The system detects when users need specific skills based on their prompts and suggests relevant skills to Claude.

## Features

- **Skill Detection**: AI-powered keyword matching with context awareness
- **Portable**: Works in any project with automatic path resolution
- **Auto-Configuration**: Detects project type and configures appropriate settings
- **Analytics**: Skill usage logging and probability scoring
- **Installation**: Single script setup with project detection
- **Self-Maintaining**: Automatic keyword generation and updates

## Quick Start

### 1. Installation

Navigate to your project's `.claude/skills` directory and clone the repository:

```bash
# Navigate to your project's skills directory (create if needed)
cd /path/to/your/project/.claude/skills
mkdir -p .  # Create directory if it doesn't exist

# Clone the skill manager
git clone https://github.com/ztffn/claude-skill-manager.git skill-keyword-manager

# Run installation from its installed location  
./skill-keyword-manager/install.sh
```

Alternative method (external clone):

```bash
# Clone outside your project
git clone https://github.com/ztffn/claude-skill-manager.git
cd claude-skill-manager

# Install to your project
./install.sh /path/to/your/project
```

### 2. Restart Claude Code

Restart Claude Code to load the new hook system.

### 3. Test the System

Try asking Claude about skills or using skill keywords - the system will automatically suggest relevant skills.

### 4. Use Management Commands

The system includes slash commands for skill management:

```bash
/skill-status    # Check system health and configuration
/skill-list      # List all available skills with statistics
/skill-create    # Create new skills with guided templates
/skill-update    # Update keywords and maintenance
/skill-scan      # Audit skill quality and detect issues
/skill-delete    # Safely remove skills with validation
```

## Directory Structure

```
skill-keyword-manager/
├── README.md                          # This documentation
├── install.sh                        # Installation script
├── SKILL.md                          # Skill definition for Claude
├── scripts/                          # Automation and maintenance
│   └── update_keywords.py            # Keyword generation and maintenance
├── references/                       # System components
│   ├── skill-forced-eval-hook.sh     # Main hook script
│   └── skill-config.template.json    # Configuration template
└── templates/                        # Project templates
    └── commands/                      # Slash command definitions
```

## System Components

### 1. Hook System (`references/skill-forced-eval-hook.sh`)

The core component that:
- Intercepts user prompts
- Analyzes keywords with priority scoring
- Triggers skill suggestions when thresholds are met
- Provides detailed logging and analytics

### 2. Configuration System (`skill-config.json`)

Project-specific configuration that controls:
- File paths and directory structure
- Skill activation thresholds
- Logging settings
- Technology stack detection

### 3. Keyword Management (`scripts/update_keywords.py`)

AI-powered keyword generation that:
- Analyzes skill descriptions
- Generates domain-specific keywords
- Maintains keyword quality and relevance
- Tracks changes and updates incrementally

### 4. Installation Automation (`scripts/install-skill-system.sh`)

Setup automation that:
- Detects project type and structure
- Creates necessary directories
- Configures paths dynamically
- Sets up Claude Code integration

## Configuration

After installation, customize your setup in `.claude/skill-config.json`:

```json
{
  "project_root": "/path/to/your/project",
  "paths": {
    "skills_dir": "skills",
    "logs_dir": "logs",
    "hooks_dir": "hooks",
    "keyword_file": "skills/skill-keywords.json"
  },
  "hook_settings": {
    "enable_logging": true,
    "skill_threshold": 14,
    "log_file": "logs/skill-activation.log"
  },
  "project_info": {
    "name": "your-project",
    "tech_stack": ["nextjs", "typescript", "tailwind"],
    "domain": "web-development"
  }
}
```

### Key Settings

- **skill_threshold**: Minimum score for skill suggestions (recommended: 14)
- **enable_logging**: Track skill activation for debugging and optimization
- **tech_stack**: Helps prioritize relevant skills for your project type

## Keyword System

The system uses a sophisticated keyword matching algorithm with priority scoring:

### Keyword Categories

1. **Technology** (priority: 10): Specific tools, frameworks, APIs
2. **Triggers** (priority: 4): Natural language phrases indicating skill usage
3. **Actions** (priority: 2): Domain-specific verbs and operations
4. **Name Variants** (priority: 1): Different ways to reference the skill

### Matching Algorithm

- **Exact Phrase Matching**: Full priority score for exact phrase matches
- **Compound Word Analysis**: Partial scoring for multi-word phrases
- **Context Awareness**: Filters common words to reduce false positives
- **Specificity Priority**: Longer, more specific phrases score higher

## Creating Portable Skills

When creating skills for this system, follow these guidelines:

### 1. Generic Content
```markdown
# Good: Generic, reusable
This skill helps optimize React components for performance.

# Bad: Project-specific  
This skill optimizes the MyCompany e-commerce app components.
```

### 2. Configurable Paths
```markdown
# Good: Relative references
Check the `src/components/` directory for existing patterns.

# Bad: Absolute paths
Look at `/Users/username/Projects/MyApp/components/`
```

### 3. Technology Agnostic
```markdown
# Good: Framework-agnostic
This skill works with any modern JavaScript framework.

# Bad: Technology-specific assumptions
This skill requires Next.js 15+ with App Router.
```

## Monitoring and Debugging

### Skill Activation Logs

Monitor skill activation in `.claude/logs/skill-activation.log`:

```
2024-01-07 10:30:45 | SUCCESS | SKILL=skill-creator | KEYWORD='create skill' | PROMPT='Help me create a new skill for...'
2024-01-07 10:31:20 | CANDIDATE | SKILL=react-optimizer | SCORE=16 | KEYWORD='react, performance' | PROMPT='Optimize my React components...'
```

### Log Analysis

- **SUCCESS**: Skill was suggested and likely activated
- **CANDIDATE**: Skill met threshold but wasn't the top choice
- **NO_MATCH**: No skills matched the user's prompt

### Common Issues

1. **No Skills Triggered**: Check keyword quality and threshold settings
2. **Wrong Skills Suggested**: Review keyword categories and priorities
3. **Performance Issues**: Monitor log file size and consider log rotation

## Skill Management Commands

The system includes slash commands for managing skills without leaving Claude Code:

### `/skill-install [--force]`

Install the skill system in the current project with automatic detection of technology stack and project structure.

```bash
/skill-install          # Standard installation
/skill-install --force  # Force reinstall over existing system
```

**Features:**
- Auto-detects project type (Node.js, Python, etc.)
- Creates optimal directory structure
- Configures paths dynamically
- Sets up Claude Code integration

### `/skill-status`

Display system health, configuration, and recent activity.

```bash
/skill-status   # Show system status
```

**Information shown:**
- System health checks (✅/❌ indicators)
- Current configuration settings
- Available skills count and status
- Recent activation logs
- System requirements verification

### `/skill-list [--detailed] [--active-only]`

List all available skills with usage statistics and metadata.

```bash
/skill-list              # Quick overview of all skills
/skill-list --detailed   # Full information including file structures
/skill-list --active-only # Only skills with recent usage
```

**Features:**
- Skill descriptions and file counts
- Keyword coverage analysis
- Usage statistics and last activation times
- Skills needing maintenance identification

### `/skill-create <name> [--template=type]`

Create new skills with guided templates and validation.

```bash
/skill-create react-optimizer              # Basic skill template
/skill-create code-reviewer --template=analysis # Analysis skill template
/skill-create deployment --template=workflow    # Workflow skill template
/skill-create api-helper --template=technical   # Technical skill template
```

**Templates available:**
- **basic**: Standard skill structure for general use
- **workflow**: Multi-step process skills with guides
- **technical**: Skills with scripts and automation
- **analysis**: Code review and analysis skills with checklists

**Features:**
- Name validation and conflict checking
- Template-based content generation
- Placeholder replacement system
- Automatic directory structure creation

### `/skill-update [--force] [--skill-name=name]`

Update skill keywords, metadata, and perform maintenance tasks.

```bash
/skill-update                    # Update all skills
/skill-update --skill-name=react # Update specific skill only
/skill-update --force           # Force update ignoring timestamps
```

**Operations performed:**
- AI-powered keyword generation from skill descriptions
- Skill registry updates with change detection
- Quality validation and metrics reporting
- Backup creation for safety

### `/skill-scan [--fix] [--verbose]`

Audit of skill quality, duplicates, and issues.

```bash
/skill-scan             # Standard quality audit
/skill-scan --fix       # Automatically fix detected issues
/skill-scan --verbose   # Detailed analysis with file contents
```

**Analysis includes:**
- Skill structure validation
- Duplicate detection
- Keyword coverage analysis
- Project-specific content identification
- Broken reference detection
- Content quality assessment

### `/skill-delete <name> [--force] [--backup]`

Safely remove skills with dependency checking and backup options.

```bash
/skill-delete old-skill          # Interactive deletion with confirmations
/skill-delete old-skill --force  # Skip confirmations
/skill-delete old-skill --backup # Create backup before deletion
```

**Safety features:**
- Dependency analysis before deletion
- Core system skill protection
- Automatic backup creation
- Keyword registry cleanup
- Post-deletion verification

## Advanced Features

### Custom Skill Thresholds

Adjust thresholds per skill type:

```bash
# High-precision skills (avoid false positives)
export CLAUDE_SKILL_THRESHOLD_HIGH=18

# General-purpose skills (more permissive)
export CLAUDE_SKILL_THRESHOLD_LOW=10
```

### Technology Stack Detection

The system automatically detects your project's technology stack:

- **Node.js Projects**: Analyzes `package.json` for frameworks
- **Python Projects**: Checks `requirements.txt` and `pyproject.toml`
- **Other Languages**: Supports Rust, Go, and more

### Skill Dependencies

Skills can declare dependencies on other skills:

```yaml
# In SKILL.md frontmatter
dependencies:
  skills: ["skill-creator", "documentation-tools"]
  system: ["bash", "python3", "git"]
```

## Migration and Sharing

### Exporting Skills

Share skills between projects:

```bash
# Export a skill for sharing
./.claude/skills/skill-keyword-manager/scripts/export-skill.sh skill-name

# Import a skill from another project
./.claude/skills/skill-keyword-manager/scripts/import-skill.sh /path/to/exported-skill.json
```

### Bulk Migration

Move all skills to a new project:

```bash
# Copy entire skill system
cp -r /old/project/.claude/skills /new/project/.claude/

# Reconfigure for new project
cd /new/project
./.claude/skills/skill-keyword-manager/scripts/install-skill-system.sh --reconfigure
```

## Troubleshooting

### System Requirements

- **bash**: Shell scripting support
- **jq**: JSON processing (install via package manager)
- **python3**: Keyword generation and AI analysis
- **Claude Code**: Version 1.0+ with hook support

### Common Solutions

**Keywords not generating**: Run manual update
```bash
cd .claude
python3 skills/skill-keyword-manager/scripts/update_keywords.py
```

**Hook not working**: Check Claude Code settings
```bash
# Verify hook is registered
cat .claude/settings.local.json | jq '.hooks'
```

**Permissions issues**: Fix script permissions
```bash
chmod +x .claude/skills/skill-keyword-manager/scripts/*.sh
```

## Contributing

This system is designed to be community-driven. Contributions welcome:

1. **Skill Templates**: Generic, reusable skill patterns
2. **Keyword Quality**: Improvements to keyword generation
3. **Project Detection**: Support for new technology stacks
4. **Documentation**: Usage examples and best practices

## License

This skill system is designed to be shared and adapted. Use it in any project, commercial or open source.

---

Check the skill activation logs and adjust your configuration for troubleshooting.
