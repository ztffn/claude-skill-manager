---
description: Update skill keywords, metadata, and maintenance tasks
allowed-tools: Bash(*), Read, Write
argument-hint: [--force] [--skill-name]
---

# Update Skill System

## Current Keyword Status

- **Keyword file exists**: !`[ -f .claude/skills/skill-keywords.json ] && echo "✅ Yes" || echo "❌ No"`
- **Last updated**: !`[ -f .claude/skills/skill-keywords.json ] && jq -r '._last_updated // "Never"' .claude/skills/skill-keywords.json || echo "Never"`
- **Skills with keywords**: !`[ -f .claude/skills/skill-keywords.json ] && jq 'keys | map(select(startswith("_") | not)) | length' .claude/skills/skill-keywords.json || echo "0"`
- **Total skills**: !`find .claude/skills -name "SKILL.md" 2>/dev/null | wc -l || echo "0"`

## Skills Needing Updates

!`if [ -f .claude/skills/skill-keywords.json ]; then
    echo "=== Skills Missing Keywords ==="
    find .claude/skills -name "SKILL.md" | while read skill; do
        name=$(basename "$(dirname "$skill")")
        if ! jq -e ".[\"$name\"]" .claude/skills/skill-keywords.json >/dev/null 2>&1; then
            echo "❌ $name - No keywords"
        fi
    done
    
    echo -e "\n=== Skills with Outdated Content ==="
    # Check modification times vs keyword generation time
    keyword_time=$(jq -r '._last_updated // "1970-01-01T00:00:00Z"' .claude/skills/skill-keywords.json)
    find .claude/skills -name "SKILL.md" | while read skill; do
        name=$(basename "$(dirname "$skill")")
        if [ "$skill" -nt .claude/skills/skill-keywords.json ]; then
            echo "⚠️  $name - Modified since last keyword update"
        fi
    done
else
    echo "❌ No keyword file found - will generate from scratch"
fi`

## Running Keyword Update

### Pre-Update Backup

!`if [ -f .claude/skills/skill-keywords.json ]; then
    cp .claude/skills/skill-keywords.json .claude/skills/skill-keywords.json.backup
    echo "✅ Backup created: skill-keywords.json.backup"
else
    echo "ℹ️  No existing keywords to backup"
fi`

### Executing Update

I'll now run the keyword update process. This will:

1. 🔍 Analyze all skill descriptions for relevant keywords
2. 🎯 Generate technology, trigger, and action keywords  
3. 🔄 Update the skill registry with new keywords
4. 📊 Validate keyword quality and coverage

!`cd .claude && python3 skills/skill-keyword-manager/scripts/update_keywords.py $ARGUMENTS`

### Post-Update Verification

!`if [ -f .claude/skills/skill-keywords.json ]; then
    echo "=== Update Results ==="
    echo "✅ Keywords updated: $(date)"
    echo "📊 Total skills: $(jq 'keys | map(select(startswith("_") | not)) | length' .claude/skills/skill-keywords.json)"
    echo "🆕 Last updated: $(jq -r '._last_updated' .claude/skills/skill-keywords.json)"
    
    echo -e "\n=== Keyword Categories per Skill ==="
    jq -r 'to_entries[] | select(.key | startswith("_") | not) | "\(.key): triggers=\(.value.triggers | length), technology=\(.value.technology | length), actions=\(.value.actions | length)"' .claude/skills/skill-keywords.json | head -10
else
    echo "❌ Update failed - keyword file not found"
fi`

## Validation

### Keyword Quality Check

!`if [ -f .claude/skills/skill-keywords.json ]; then
    echo "=== Quality Metrics ==="
    
    # Count empty categories
    empty_triggers=$(jq '[.[] | select(type == "object") | select(.triggers | length == 0)] | length' .claude/skills/skill-keywords.json)
    empty_tech=$(jq '[.[] | select(type == "object") | select(.technology | length == 0)] | length' .claude/skills/skill-keywords.json)
    
    echo "⚠️  Skills with no triggers: $empty_triggers"
    echo "⚠️  Skills with no technology: $empty_tech"
    
    # Sample some keywords
    echo -e "\n=== Sample Keywords ==="
    jq -r 'to_entries[] | select(.key | startswith("_") | not) | "\(.key):" | head -3' .claude/skills/skill-keywords.json
    jq -r 'to_entries[] | select(.key | startswith("_") | not) | "  triggers: \(.value.triggers | join(", "))" | head -3' .claude/skills/skill-keywords.json
fi`

## Next Steps

After updating keywords:

1. **Test activation**: Use skill keywords in prompts to verify triggering
2. **Check logs**: Monitor `.claude/logs/skill-activation.log` for activation patterns
3. **Adjust thresholds**: Modify `.claude/skill-config.json` if needed
4. **Restart Claude Code**: If hook behavior seems inconsistent

### Specific Skill Update

If you specified a skill name with `--skill-name`, only that skill's keywords were updated.

Use `/skill-status` to verify the system health after updates.