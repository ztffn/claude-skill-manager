---
name: skill-keyword-manager
description: Automates maintenance of the skill keywords registry using AI-powered analysis. This skill should be used when updating skill keywords, maintaining the registry, generating keywords for new skills, improving skill triggering, running keyword analysis, or when the update script prompts for keyword generation. Essential for ensuring skills are discoverable and properly triggered.
---

# Skill Keyword Manager

## Overview

Automates the maintenance of the skill keywords registry using AI-powered keyword generation. This skill manages the `skill-keywords.json` file that enables selective skill evaluation hooks, ensuring skills are properly triggered while reducing noise.

## Core Capabilities

### 1. AI-Powered Keyword Generation
When triggered by this skill, Claude performs intelligent analysis of skill descriptions to generate comprehensive keywords including:

**Action Keywords:** Specific verbs that are NOT overly generic
- AVOID: "create", "build", "setup", "implement", "make", "add", "handle", "use", "work", "run"
- PREFER: Domain-specific actions like "deploy", "migrate", "geocode", "authenticate", "optimize", "refactor"
- Context-aware extraction based on skill purpose, favoring specificity over breadth

**Technology Keywords:** Domain-specific terms and technologies
- AVOID: "react", "component", "database", "api", "app", "user", "system", "code", "file", "data"
- PREFER: Specific technologies like "useEffect", "drizzle", "vipps", "geonorge", "vercel", "nextjs"
- Programming languages, frameworks, tools, services with version specificity when relevant
- Project-specific terminology (company names, domain-specific terms, etc.)

**Natural Language Triggers:** COMPOUND PHRASES that uniquely identify the skill intent
- PRIORITY: Multi-word phrases like "explain how this works", "deploy to production", "fix useEffect abuse"
- Question patterns: "how does this work", "what does this do", "show me how", "walk me through"  
- Intent expressions: "help me understand", "explain this to me", "deploy my app"
- Problem statements with context: "useEffect not working", "authentication broken", "deployment failed"
- AVOID single generic words - always use 2+ word phrases for triggers

**Technical Phrases:** Specific domain language
- "server actions", "route handlers", "form handling", "cookies from client"
- "address validation", "Norwegian municipality", "delivery area"
- "schema migration", "database connection", "authentication setup"

**Name Variants:** All ways users might reference the skill
- Hyphenated, underscore, and space variations
- Abbreviations and common shortenings
- Alternative terminology for the same concept

### 2. Change Detection and Incremental Updates
Use content hashing to detect new, modified, or deleted skills and only process changed skills, making the update process efficient for large skill collections.

### 3. Registry Maintenance
Maintain the `skill-keywords.json` file with proper structure including:
- Keyword categories (actions, technology, triggers, name_variants)
- Metadata tracking (skill hashes, update timestamps)
- Automatic cleanup of deleted skills

## Agentic Keyword Generation Workflow

When this skill is triggered for keyword generation:

### Step 1: Skill Analysis
For each skill requiring keyword updates, analyze:
1. **Read the full skill description** - Understand the skill's purpose and scope
2. **Identify the target domain** - What technology, workflow, or problem area
3. **Extract "when" conditions** - How the skill describes its trigger conditions
4. **Note specific terminology** - Technical terms, tool names, domain language

### Step 2: Intelligent Keyword Extraction
Generate keywords by reasoning about how users would naturally express needs for this skill:

**User Intent Analysis:**
- What problems would lead someone to need this skill?
- How would they naturally describe those problems?
- What questions would they ask?

**Context-Aware Generation:**
- Extract domain-specific terminology from the description
- Focus on UNIQUE identifiers that differentiate this skill from others
- Avoid keywords that would reasonably apply to multiple skills
- Prioritize compound phrases over single words
- Consider context: "explain auth" vs "setup auth" should trigger different skills
- Test keywords mentally against other skills to avoid conflicts

**Natural Language Patterns:**
- "I want to [action] [object]"
- "How do I [accomplish task]"
- "Help me [solve problem]"
- "[Technology] is [not working/broken/confusing]"

### Step 3: Quality Validation & Conflict Resolution
Ensure generated keywords are:
- **Specific Over Comprehensive**: Favor precision over recall - it's better to miss edge cases than create false positives
- **Compound Phrases**: Use 2+ word combinations instead of single generic terms
- **Context-Aware**: "auth" with "explain" should trigger explaining-code, not neon-auth
- **Conflict-Free**: Check if keywords would falsely trigger other skills
- **Scalable**: Keywords should work for any project, not just this specific codebase
- **80%+ Target**: Aim for 80%+ success rate in skill activation accuracy

## Quick Start

To update the skill keywords registry using AI analysis:

```bash
# Trigger this skill, then use the update script
python3 scripts/update_keywords.py
```

The script detects which skills need keyword updates, then this skill provides intelligent keyword analysis for each one.

## Usage Scenarios

### Standard Workflow
Run the keyword update script after:
- Creating new skills
- Modifying skill descriptions
- Reorganizing the skills directory
- When skill triggering seems inconsistent

### Script Options

**Regenerate all keywords:**
```bash
python3 scripts/update_keywords.py --force
```
Useful when keyword generation logic is improved or when starting fresh.

**Preview changes without updating:**
```bash
python3 scripts/update_keywords.py --dry-run
```
See what would be updated before making actual changes.

**Combine options:**
```bash
python3 scripts/update_keywords.py --force --dry-run
```
Preview what a full regeneration would do.

## Maintenance Guidelines

### When to Run Updates

**Automatic triggers:**
- After skill creation via skill-creator
- When skill descriptions are significantly modified
- When adding new technology domains to skills

**Manual triggers:**
- When skills aren't being triggered appropriately
- After skill reorganization or cleanup
- When expanding into new technology domains

### Registry Structure

The generated `skill-keywords.json` follows this structure:
```json
{
  "skill-name": {
    "actions": ["create", "build", "configure"],
    "technology": ["nextjs", "typescript", "api"],
    "triggers": ["user requests", "when building"],
    "name_variants": ["skill", "name", "skill-name"]
  },
  "_skill_hashes": {
    "skill-name": "abc123def456"
  },
  "_last_updated": "project-directory"
}
```

### Best Practices

**Keyword Quality:**
- AVOID generic single words that appear in multiple domains
- PRIORITIZE compound phrases and domain-specific terminology
- Focus on unique skill identifiers, not broad category terms
- Generate keywords that distinguish this skill from others
- Target 80%+ accuracy with minimal false positives
- Use contextual phrases rather than isolated technical terms

**Registry Maintenance:**
- Run updates regularly as part of skill development workflow
- Use `--dry-run` first when making significant changes
- Monitor keyword effectiveness by observing skill triggering behavior

## Script Resources

### scripts/update_keywords.py

The core Python script that automates keyword generation and registry maintenance:

**Key Features:**
- Scans all skill directories in the parent skills folder
- Extracts YAML frontmatter from SKILL.md files  
- Detects new/changed skills using content hashing
- Identifies which skills need keyword generation
- Triggers this skill for AI-powered keyword analysis
- Updates the registry with generated keywords
- Maintains proper JSON structure with metadata

**Dependencies:**
- Python 3.6+
- Standard library modules: `pathlib`, `json`, `re`, `hashlib`, `argparse`
- This skill for intelligent keyword generation

**Usage Examples:**
```bash
# Standard update (only changed skills)
python3 scripts/update_keywords.py

# Force regeneration of all keywords
python3 scripts/update_keywords.py --force

# Preview changes without updating files
python3 scripts/update_keywords.py --dry-run
```

The script is self-contained and requires no external API keys or services.
