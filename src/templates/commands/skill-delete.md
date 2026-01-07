---
description: Safely delete a skill with dependency checking and backup
allowed-tools: Bash(*), Read, Write  
argument-hint: <skill-name> [--force] [--backup]
---

# Delete Skill: $1

## Safety Checks

Before deleting skill "$1", I'll perform safety validation:

### 1. Skill Exists

- **Skill directory**: !`[ -d .claude/skills/$1 ] && echo "✅ Found" || echo "❌ Not found"`
- **SKILL.md file**: !`[ -f .claude/skills/$1/SKILL.md ] && echo "✅ Found" || echo "❌ Not found"`

### 2. Skill Information

!`if [ -f .claude/skills/$1/SKILL.md ]; then
    echo "=== Skill Overview ==="
    echo "📁 Directory: .claude/skills/$1"
    echo "📄 Files:"
    find .claude/skills/$1 -type f | sed 's/^/  - /'
    echo ""
    echo "📋 Description:"
    grep -A3 "^description:" .claude/skills/$1/SKILL.md | head -3 | sed 's/^/  /'
else
    echo "❌ Skill not found: $1"
    echo ""
    echo "Available skills:"
    find .claude/skills -type d -maxdepth 1 | grep -v "^.claude/skills$" | sed 's/.*\//  - /'
    exit 1
fi`

### 3. Dependency Check

!`echo "=== Checking Dependencies ==="

# Check if other skills reference this one
if find .claude/skills -name "*.md" -not -path ".claude/skills/$1/*" | xargs grep -l "$1" 2>/dev/null; then
    echo "⚠️  This skill is referenced by other skills:"
    find .claude/skills -name "*.md" -not -path ".claude/skills/$1/*" | xargs grep -l "$1" | while read file; do
        skill_name=$(basename "$(dirname "$file")")
        echo "  - $skill_name"
        grep -n "$1" "$file" | head -2 | sed 's/^/    /'
    done
else
    echo "✅ No dependencies found"
fi

# Check if it's a core system skill
if echo "$1" | grep -E "(skill-keyword-manager|skill-creator)" >/dev/null; then
    echo "⚠️  This is a core system skill - deletion may break skill management"
else
    echo "✅ Not a core system skill"
fi`

### 4. Keyword Registry Impact

!`if [ -f .claude/skills/skill-keywords.json ]; then
    if jq -e ".[\"$1\"]" .claude/skills/skill-keywords.json >/dev/null 2>&1; then
        echo "=== Current Keywords ==="
        jq ".[\"$1\"]" .claude/skills/skill-keywords.json
        echo "✅ Will be removed from keyword registry"
    else
        echo "ℹ️  No keywords registered for this skill"
    fi
else
    echo "ℹ️  No keyword registry found"
fi`

## Deletion Process

### 5. Create Backup (if requested)

!`if [[ "$2" == "--backup" ]] || [[ "$3" == "--backup" ]]; then
    backup_dir=".claude/backups/skills"
    backup_file="$backup_dir/$1-$(date +%Y%m%d-%H%M%S).tar.gz"
    
    mkdir -p "$backup_dir"
    tar -czf "$backup_file" -C .claude/skills "$1"
    
    if [ -f "$backup_file" ]; then
        echo "✅ Backup created: $backup_file"
    else
        echo "❌ Backup failed"
        exit 1
    fi
else
    echo "ℹ️  No backup requested (use --backup to create one)"
fi`

### 6. Confirm Deletion

!`if [[ "$2" != "--force" ]] && [[ "$3" != "--force" ]]; then
    echo ""
    echo "⚠️  DELETION CONFIRMATION REQUIRED"
    echo "This will permanently delete skill '$1' and all its files."
    echo "Add --force to skip this confirmation."
    echo ""
    echo "To proceed manually:"
    echo "  1. rm -rf .claude/skills/$1"
    echo "  2. Run /skill-update to clean keywords"
    exit 0
fi`

### 7. Execute Deletion

!`if [[ "$2" == "--force" ]] || [[ "$3" == "--force" ]]; then
    echo "🗑️  Deleting skill: $1"
    
    # Remove skill directory
    if [ -d .claude/skills/$1 ]; then
        rm -rf .claude/skills/$1
        echo "✅ Skill directory removed"
    fi
    
    # Remove from keyword registry
    if [ -f .claude/skills/skill-keywords.json ]; then
        temp_file=$(mktemp)
        jq "del([\"$1\"])" .claude/skills/skill-keywords.json > "$temp_file"
        mv "$temp_file" .claude/skills/skill-keywords.json
        echo "✅ Keywords removed from registry"
    fi
    
    echo ""
    echo "✅ Skill '$1' has been deleted successfully"
fi`

## Post-Deletion

### 8. Verify Deletion

!`if [[ "$2" == "--force" ]] || [[ "$3" == "--force" ]]; then
    echo "=== Verification ==="
    
    if [ ! -d .claude/skills/$1 ]; then
        echo "✅ Skill directory removed"
    else
        echo "❌ Skill directory still exists"
    fi
    
    if [ -f .claude/skills/skill-keywords.json ]; then
        if ! jq -e ".[\"$1\"]" .claude/skills/skill-keywords.json >/dev/null 2>&1; then
            echo "✅ Keywords removed from registry"
        else
            echo "❌ Keywords still in registry"
        fi
    fi
fi`

### 9. Recommendations

After deletion:

1. **Update dependencies**: If other skills referenced this one, update them
2. **Run skill scan**: Use `/skill-scan` to check for broken references
3. **Test system**: Verify remaining skills work correctly

### Recovery

If you need to recover the deleted skill:

1. **From backup**: Extract the backup created above
2. **From git**: If using version control: `git checkout .claude/skills/$1`
3. **Recreate**: Use `/skill-create $1` to make a new version

Use `/skill-status` to verify system health after deletion.