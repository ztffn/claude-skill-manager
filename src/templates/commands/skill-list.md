---
description: List all available skills with status, keywords, and usage statistics
allowed-tools: Bash(*), Read
argument-hint: [--detailed] [--active-only] [--sort-by-usage]
---

# Skill System Overview

## Quick Summary

- **Total skills**: !`find .claude/skills -name "SKILL.md" 2>/dev/null | wc -l`
- **Skills with keywords**: !`[ -f .claude/skills/skill-keywords.json ] && jq 'keys | map(select(startswith("_") | not)) | length' .claude/skills/skill-keywords.json || echo "0"`
- **Last activation**: !`[ -f .claude/logs/skill-activation.log ] && tail -1 .claude/logs/skill-activation.log | cut -d'|' -f1 || echo "No activity logged"`

## All Skills

!`find .claude/skills -name "SKILL.md" | while read skill_file; do
    skill_dir=$(dirname "$skill_file")
    skill_name=$(basename "$skill_dir")
    
    # Skip if it's the skill manager itself and not detailed mode
    if [[ "$skill_name" == "skill-keyword-manager" ]] && [[ "$1" != "--detailed" ]]; then
        continue
    fi
    
    echo "=== $skill_name ==="
    
    # Get description from frontmatter or first line
    if description=$(grep -A1 "^description:" "$skill_file" | tail -1 | sed 's/description: *//; s/^[" ]*//' 2>/dev/null); then
        echo "📝 $description"
    else
        # Fallback to first meaningful line
        echo "📝 $(head -10 "$skill_file" | grep -v "^#" | grep -v "^-" | grep -v "^$" | head -1)"
    fi
    
    # Directory info
    file_count=$(find "$skill_dir" -type f | wc -l)
    dir_size=$(du -sh "$skill_dir" 2>/dev/null | cut -f1 || echo "?")
    echo "📁 Files: $file_count, Size: $dir_size"
    
    # Keyword status
    if [ -f .claude/skills/skill-keywords.json ]; then
        if keywords=$(jq -r ".[\"$skill_name\"] // empty" .claude/skills/skill-keywords.json 2>/dev/null) && [ -n "$keywords" ]; then
            trigger_count=$(echo "$keywords" | jq '.triggers // [] | length' 2>/dev/null || echo "0")
            tech_count=$(echo "$keywords" | jq '.technology // [] | length' 2>/dev/null || echo "0")
            action_count=$(echo "$keywords" | jq '.actions // [] | length' 2>/dev/null || echo "0")
            echo "🎯 Keywords: $trigger_count triggers, $tech_count tech, $action_count actions"
            
            # Show sample keywords if detailed
            if [[ "$1" == "--detailed" ]]; then
                echo "   Triggers: $(echo "$keywords" | jq -r '.triggers // [] | join(", ")' | head -c 60)..."
                echo "   Technology: $(echo "$keywords" | jq -r '.technology // [] | join(", ")' | head -c 60)..."
            fi
        else
            echo "❌ No keywords registered"
        fi
    else
        echo "❌ No keyword system"
    fi
    
    # Usage statistics
    if [ -f .claude/logs/skill-activation.log ]; then
        activations=$(grep "$skill_name" .claude/logs/skill-activation.log | wc -l)
        last_used=$(grep "$skill_name" .claude/logs/skill-activation.log | tail -1 | cut -d'|' -f1 || echo "Never")
        echo "📊 Activations: $activations, Last used: $(echo "$last_used" | cut -d' ' -f1)"
    else
        echo "📊 No usage data"
    fi
    
    # File structure (if detailed)
    if [[ "$1" == "--detailed" ]]; then
        echo "📂 Structure:"
        find "$skill_dir" -type f | sed "s|$skill_dir/||" | head -10 | sed 's/^/   /'
        file_count_all=$(find "$skill_dir" -type f | wc -l)
        if [ "$file_count_all" -gt 10 ]; then
            echo "   ... and $((file_count_all - 10)) more files"
        fi
    fi
    
    echo ""
done`

## Most Active Skills

!`if [ -f .claude/logs/skill-activation.log ]; then
    echo "=== Top 5 Most Used Skills ==="
    grep "SUCCESS" .claude/logs/skill-activation.log | cut -d'|' -f3 | cut -d'=' -f2 | sort | uniq -c | sort -nr | head -5 | while read count skill; do
        echo "🏆 $skill: $count activations"
    done
else
    echo "=== No Usage Statistics Available ==="
    echo "ℹ️  Start using skills to see activation statistics here"
fi`

## Skills Needing Attention

!`echo "=== Skills Requiring Maintenance ==="

# Skills without keywords
echo "🔧 Skills missing keywords:"
find .claude/skills -name "SKILL.md" | while read skill; do
    name=$(basename "$(dirname "$skill")")
    if ! jq -e ".[\"$name\"]" .claude/skills/skill-keywords.json >/dev/null 2>&1; then
        echo "   ❌ $name"
    fi
done

# Skills with very few files (potentially incomplete)
echo -e "\n🔧 Skills with minimal content:"
find .claude/skills -type d -maxdepth 1 | grep -v "^.claude/skills$" | while read dir; do
    name=$(basename "$dir")
    file_count=$(find "$dir" -type f | wc -l)
    if [ "$file_count" -le 2 ]; then
        echo "   ⚠️  $name ($file_count files)"
    fi
done

# Recently modified skills (may need keyword updates)
if [ -f .claude/skills/skill-keywords.json ]; then
    echo -e "\n🔧 Skills modified since last keyword update:"
    find .claude/skills -name "SKILL.md" | while read skill; do
        name=$(basename "$(dirname "$skill")")
        if [ "$skill" -nt .claude/skills/skill-keywords.json ]; then
            echo "   🔄 $name"
        fi
    done
fi`

## Quick Actions

Based on the analysis above, you can:

1. **Update keywords**: `/skill-update` to refresh all keywords
2. **Scan for issues**: `/skill-scan` for detailed quality analysis  
3. **Create new skills**: `/skill-create [name]` to add capabilities
4. **Delete unused**: `/skill-delete [name]` for skills you don't need
5. **Check system health**: `/skill-status` for overall system status

### Filtering Options

- Use `--detailed` to see full skill information and file structures
- Use `--active-only` to show only skills with recent usage
- Use `--sort-by-usage` to order by activation frequency

Example: `/skill-list --detailed` for comprehensive overview.