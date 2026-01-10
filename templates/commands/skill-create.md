---
description: Create a new skill with guided setup, templates, and validation
allowed-tools: Bash(*), Read, Write, Edit
argument-hint: <skill-name> [--template=type] [--interactive]
---

# Create New Skill: $1

## Skill Creation System Detection

!`# Check for Anthropic skill-creator (preferred)
ANTHROPIC_SKILL_CREATOR=".claude/skills/skill-creator"
INIT_SCRIPT="$ANTHROPIC_SKILL_CREATOR/scripts/init_skill.py"

if [ -f "$INIT_SCRIPT" ]; then
    echo "Found Anthropic skill-creator system"
    echo "Using professional skill creation tools"
    CREATION_METHOD="anthropic"
else
    echo "Anthropic skill-creator not found"
    echo "Using fallback system"
    CREATION_METHOD="fallback"
fi`

## Skill Name Validation

!`# Validate skill name
skill_name="$1"
if [ -z "$skill_name" ]; then
    echo "Error: Skill name is required"
    echo "Usage: /skill-create <skill-name>"
    echo "Example: /skill-create react-optimizer"
    exit 1
fi

# Check if name is valid (lowercase, hyphens, no spaces)
if echo "$skill_name" | grep -E "^[a-z][a-z0-9-]*$" >/dev/null; then
    echo "Valid skill name: $skill_name"
else
    echo "Invalid skill name: $skill_name"
    echo "Requirements:"
    echo "  - Lowercase letters only"
    echo "  - Start with letter"
    echo "  - Use hyphens for spaces"
    echo "  - No special characters"
    echo "Example: 'react-optimizer', 'database-helper'"
    exit 1
fi

# Check if skill already exists
if [ -d ".claude/skills/$skill_name" ]; then
    echo "Error: Skill already exists: $skill_name"
    echo "Use /skill-delete $skill_name first, or choose a different name"
    exit 1
else
    echo "Skill name available: $skill_name"
fi`

## Skill Template Selection

!`echo "=== Available Templates ==="

# Determine template type
template_type=""
for arg in "$@"; do
    if [[ "$arg" == --template=* ]]; then
        template_type="${arg#--template=}"
        break
    fi
done

if [ -z "$template_type" ]; then
    echo "Available templates:"
    echo "  - basic: Simple skill with standard structure"
    echo "  - workflow: Multi-step workflow skill with guides"
    echo "  - technical: Technology-specific skill with scripts"
    echo "  - analysis: Code analysis and review skill"
    echo ""
    echo "Using 'basic' template (specify --template=type for others)"
    template_type="basic"
else
    echo "Using template: $template_type"
fi

# Validate template type
case "$template_type" in
    basic|workflow|technical|analysis)
        echo "Valid template: $template_type"
        ;;
    *)
        echo "Error: Invalid template: $template_type"
        echo "Available: basic, workflow, technical, analysis"
        exit 1
        ;;
esac`

## Creating Skill Structure

!`if [ "$CREATION_METHOD" = "anthropic" ]; then
    echo "Using Anthropic skill-creator system"
    
    # Use the professional init_skill.py script
    python3 "$INIT_SCRIPT" "$skill_name" --path ".claude/skills"
    
    # Check if creation succeeded
    if [ -d ".claude/skills/$skill_name" ]; then
        echo "Skill created successfully using Anthropic system"
        echo "Created directory: .claude/skills/$skill_name"
        
        # Update keywords using the Anthropic system's script
        if [ -f "$ANTHROPIC_SKILL_CREATOR/scripts/update_keywords.py" ]; then
            echo "Updating skill keywords"
            cd .claude
            python3 "$ANTHROPIC_SKILL_CREATOR/scripts/update_keywords.py"
        fi
    else
        echo "Error: Anthropic skill creation failed"
        exit 1
    fi
else
    echo "Using fallback skill creation system"
    
    skill_dir=".claude/skills/$skill_name"
    mkdir -p "$skill_dir"
    echo "Created directory: $skill_dir"

    # Create subdirectories based on template
    case "$template_type" in
        basic)
            # Just the skill file
            ;;
        workflow)
            mkdir -p "$skill_dir/guides"
            echo "Created guides/ directory"
            ;;
        technical)
            mkdir -p "$skill_dir/scripts" "$skill_dir/references"
            echo "Created scripts/ and references/ directories"
            ;;
        analysis)
            mkdir -p "$skill_dir/references" "$skill_dir/templates"
            echo "Created references/ and templates/ directories"
            ;;
    esac
fi`

## Generating Skill Content

!`if [ "$CREATION_METHOD" = "fallback" ]; then
    echo "Generating SKILL.md for fallback system"
    
    # Create the main skill file based on template
    cat > "$skill_dir/SKILL.md" << EOF
---
name: $skill_name
description: [REPLACE: Brief description of what this skill does]
allowed-tools: [Read, Write, Edit, Bash, Grep, Glob]
---

# ${skill_name^} Skill

## Overview

[REPLACE: Describe the purpose and capabilities of this skill]

This skill helps with [REPLACE: specific use case]. It provides [REPLACE: key benefits].

## When to Use This Skill

Use this skill when:
- [REPLACE: Scenario 1]
- [REPLACE: Scenario 2]  
- [REPLACE: Scenario 3]

## How It Works

### Step 1: [REPLACE: First step]
[REPLACE: Detailed explanation]

### Step 2: [REPLACE: Second step]
[REPLACE: Detailed explanation]

### Step 3: [REPLACE: Third step]
[REPLACE: Detailed explanation]

## Examples

### Example 1: [REPLACE: Example name]
\`\`\`
[REPLACE: Example code or commands]
\`\`\`

### Example 2: [REPLACE: Example name]
\`\`\`
[REPLACE: Example code or commands]
\`\`\`

## Best Practices

- [REPLACE: Best practice 1]
- [REPLACE: Best practice 2]
- [REPLACE: Best practice 3]

## Common Issues

- **Issue**: [REPLACE: Common problem]
  **Solution**: [REPLACE: How to solve it]

- **Issue**: [REPLACE: Another problem]
  **Solution**: [REPLACE: How to solve it]

## Related Skills

- [REPLACE: Related skill name]: [REPLACE: How it relates]
- [REPLACE: Another related skill]: [REPLACE: How it relates]

EOF

echo "Created $skill_dir/SKILL.md"
else
    echo "Skill content generated by Anthropic system"
fi`

## Adding Template-Specific Content

!`if [ "$CREATION_METHOD" = "fallback" ]; then
    case "$template_type" in
    workflow)
        echo "=== Creating Workflow Guide ==="
        cat > "$skill_dir/guides/workflow.md" << 'EOF'
# Workflow Guide

## Overview
[REPLACE: Describe the workflow]

## Prerequisites
- [REPLACE: Requirement 1]
- [REPLACE: Requirement 2]

## Steps
1. [REPLACE: Step 1 with details]
2. [REPLACE: Step 2 with details]
3. [REPLACE: Step 3 with details]

## Validation
- [ ] [REPLACE: Check 1]
- [ ] [REPLACE: Check 2]
- [ ] [REPLACE: Check 3]
EOF
        echo "Created workflow guide"
        ;;
    
    technical)
        echo "Creating technical resources"
        cat > "$skill_dir/scripts/example.sh" << 'EOF'
#!/bin/bash
# Example script for $skill_name skill

echo "Replace this with actual script content"
# Add your technical implementation here
EOF
        chmod +x "$skill_dir/scripts/example.sh"
        
        cat > "$skill_dir/references/README.md" << 'EOF'
# Technical References

## Documentation Links
- [REPLACE: Link 1](url)
- [REPLACE: Link 2](url)

## Configuration Examples
\`\`\`
[REPLACE: Configuration examples]
\`\`\`
EOF
        echo "Created technical resources"
        ;;
    
    analysis)
        echo "Creating analysis templates"
        cat > "$skill_dir/templates/checklist.md" << 'EOF'
# Analysis Checklist

## Code Quality
- [ ] [REPLACE: Check 1]
- [ ] [REPLACE: Check 2]
- [ ] [REPLACE: Check 3]

## Performance
- [ ] [REPLACE: Performance check 1]
- [ ] [REPLACE: Performance check 2]

## Security
- [ ] [REPLACE: Security check 1]
- [ ] [REPLACE: Security check 2]
EOF
        
        cat > "$skill_dir/references/criteria.md" << 'EOF'
# Analysis Criteria

## Quality Metrics
[REPLACE: Define quality standards]

## Common Patterns
[REPLACE: Good and bad patterns to look for]

## Recommendations
[REPLACE: Standard recommendations to provide]
EOF
        echo "Created analysis templates"
        ;;
esac`

## Skill Validation

!`echo "=== Validating Created Skill ==="

# Check file structure
echo "File structure:"
find "$skill_dir" -type f | sed "s|$skill_dir/||" | sed 's/^/  /'

# Check file sizes
skill_file="$skill_dir/SKILL.md"
if [ -f "$skill_file" ]; then
    size=$(wc -c < "$skill_file")
    echo "SKILL.md: $size characters"
    if [ "$size" -gt 500 ]; then
        echo "Adequate content size"
    else
        echo "Warning: Content may be too brief"
    fi
else
    echo "Error: SKILL.md not created"
fi`

## Next Steps

Your new skill "$1" has been created! Here's what to do next:

### 1. Customize the Content

!`echo "Edit the skill file:"
echo "  $skill_dir/SKILL.md"
echo ""
echo "Replace all [REPLACE: ...] placeholders with actual content"`

### 2. Generate Keywords

!`echo "Generate keywords for discovery:"
echo "  /skill-update --skill-name $skill_name"`

### 3. Test the Skill

!`echo "Test skill activation:"
echo "  - Use skill-related keywords in prompts"
echo "  - Check /skill-status for activation logs"
echo "  - Refine keywords based on testing"`

### 4. Validate Quality

!`echo "Run quality checks:"
echo "  /skill-scan --verbose"`

## Skill Template Structure

!`echo "Your skill uses the '$template_type' template with:"
case "$template_type" in
    basic)
        echo "  - SKILL.md with standard structure"
        echo "  - Ready for basic skill functionality"
        ;;
    workflow)
        echo "  - SKILL.md with workflow focus"
        echo "  - guides/workflow.md for detailed steps"
        echo "  - Structured for multi-step processes"
        ;;
    technical)
        echo "  - SKILL.md with technical focus"
        echo "  - scripts/ for executable code"
        echo "  - references/ for documentation"
        echo "  - Ready for automation and tools"
        ;;
    analysis)
        echo "  - SKILL.md with analysis focus"
        echo "  - templates/checklist.md for systematic reviews"
        echo "  - references/criteria.md for standards"
        echo "  - Structured for code review and analysis"
        ;;
esac`

## Quick Reference

- **Edit skill**: Open `$skill_dir/SKILL.md` in your editor
- **Add keywords**: `/skill-update` after editing
- **Test activation**: Use skill keywords in prompts  
- **View all skills**: `/skill-list`
- **Delete if needed**: `/skill-delete $1`

Your skill is ready for customization! Replace the placeholder content with your specific requirements.