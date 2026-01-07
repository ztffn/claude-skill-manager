---
description: Scan and audit existing skills for quality, duplicates, and issues
allowed-tools: Bash(*), Read, Grep, Glob
argument-hint: [--fix] [--verbose]
---

# Skill System Audit

## Scanning All Skills

I'm analyzing your skill system for quality, duplicates, and potential issues.

### Discovery Phase

- **Skills found**: !`find .claude/skills -name "SKILL.md" 2>/dev/null | wc -l`
- **Skill directories**: !`find .claude/skills -type d -maxdepth 1 | grep -v "^.claude/skills$" | sort`

## Quality Analysis

### 1. Skill Structure Validation

!`find .claude/skills -name "SKILL.md" | while read skill; do
    dir=$(dirname "$skill")
    name=$(basename "$dir")
    echo "=== $name ==="
    
    # Check for required frontmatter
    if head -10 "$skill" | grep -q "^---$"; then
        echo "✅ Has frontmatter"
    else
        echo "⚠️  Missing frontmatter"
    fi
    
    # Check file size (empty skills)
    size=$(wc -c < "$skill")
    if [ "$size" -gt 100 ]; then
        echo "✅ Adequate content ($size chars)"
    else
        echo "⚠️  Very short content ($size chars)"
    fi
    
    # Check for obvious placeholders
    if grep -qi "TODO\|PLACEHOLDER\|REPLACE THIS" "$skill"; then
        echo "❌ Contains placeholder text"
    else
        echo "✅ No placeholders found"
    fi
    
    echo ""
done`

### 2. Duplicate Detection

!`# Find skills with similar names
find .claude/skills -name "SKILL.md" | while read skill; do
    basename "$(dirname "$skill")"
done | sort | uniq -d | while read dup; do
    echo "⚠️  Potential duplicate name: $dup"
done

# Find skills with similar descriptions
echo "=== Similar Descriptions ==="
find .claude/skills -name "SKILL.md" | while read skill; do
    name=$(basename "$(dirname "$skill")")
    desc=$(grep -A5 "^description:" "$skill" | head -1 | cut -d: -f2- | tr -d '"' | xargs)
    echo "$name: $desc"
done | sort -k2`

### 3. Keyword Coverage

!`# Check which skills have keywords
if [ -f .claude/skills/skill-keywords.json ]; then
    echo "=== Skills with Keywords ==="
    jq -r 'keys[] | select(startswith("_") | not)' .claude/skills/skill-keywords.json
    
    echo -e "\n=== Skills WITHOUT Keywords ==="
    find .claude/skills -name "SKILL.md" | while read skill; do
        name=$(basename "$(dirname "$skill")")
        if ! jq -e ".[\"$name\"]" .claude/skills/skill-keywords.json >/dev/null 2>&1; then
            echo "❌ $name"
        fi
    done
else
    echo "❌ No keyword file found - run /skill-update"
fi`

## Content Quality Issues

### 4. Project-Specific Content

!`echo "=== Scanning for Project-Specific References ==="
find .claude/skills -name "*.md" | xargs grep -l -i "lions\|relivator\|steffen" | while read file; do
    skill=$(basename "$(dirname "$file")")
    echo "⚠️  $skill contains project-specific content:"
    grep -n -i "lions\|relivator\|steffen" "$file" | head -3
    echo ""
done`

### 5. Broken References

!`echo "=== Checking File References ==="
find .claude/skills -name "*.md" | xargs grep -H "@\|scripts/" | while IFS: read file ref; do
    skill=$(basename "$(dirname "$file")")
    echo "📁 $skill references: $(echo "$ref" | head -c 60)..."
done`

## Recommendations

Based on the scan above, here are improvement suggestions:

### High Priority Issues
- Skills with ❌ markers need immediate attention
- Skills without keywords won't be auto-discovered
- Project-specific content reduces portability

### Medium Priority Issues  
- Skills with ⚠️ warnings should be reviewed
- Similar descriptions may indicate duplicates
- Very short skills may need more content

### Actions You Can Take

1. **Fix keywords**: Run `/skill-update` to generate missing keywords
2. **Remove duplicates**: Use `/skill-delete [name]` for redundant skills  
3. **Generalize content**: Edit skills to remove project-specific references
4. **Add structure**: Improve skills with missing frontmatter or short content

### Automatic Fixes

If you passed `--fix` argument, I can automatically:
- Generate missing keywords
- Add basic frontmatter to skills missing it
- Create skill templates for very short skills

Would you like me to run these fixes?