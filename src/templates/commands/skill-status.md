---
description: Show skill system health, configuration, and recent activity
allowed-tools: Bash(*), Read, LS
---

# Skill System Status

## System Health

- **Skill system installed**: !`[ -d .claude/skills ] && echo "✅ Yes" || echo "❌ No - run /skill-install"`
- **Hook system active**: !`[ -f .claude/hooks/skill-forced-eval-hook.sh ] && echo "✅ Yes" || echo "❌ No"`
- **Configuration present**: !`[ -f .claude/skill-config.json ] && echo "✅ Yes" || echo "❌ No"`
- **Keywords generated**: !`[ -f .claude/skills/skill-keywords.json ] && echo "✅ Yes" || echo "❌ No"`

## Current Configuration

!`[ -f .claude/skill-config.json ] && cat .claude/skill-config.json | jq '.' || echo "No configuration file found"`

## Available Skills

- **Total skills**: !`[ -d .claude/skills ] && find .claude/skills -name "SKILL.md" | wc -l || echo "0"`
- **Skills with keywords**: !`[ -f .claude/skills/skill-keywords.json ] && jq 'keys | map(select(startswith("_") | not)) | length' .claude/skills/skill-keywords.json || echo "0"`

### Skill Directory

!`[ -d .claude/skills ] && find .claude/skills -type d -maxdepth 1 | grep -v "^.claude/skills$" | sort || echo "No skills found"`

## Recent Activity

### Skill Activation Log (Last 10 entries)

!`[ -f .claude/logs/skill-activation.log ] && tail -10 .claude/logs/skill-activation.log || echo "No activation log found"`

### Keywords Last Updated

!`[ -f .claude/skills/skill-keywords.json ] && jq -r '._last_updated // "Never"' .claude/skills/skill-keywords.json || echo "No keyword file"`

## System Requirements Check

- **bash**: !`command -v bash >/dev/null && echo "✅ Available" || echo "❌ Missing"`
- **jq**: !`command -v jq >/dev/null && echo "✅ Available" || echo "❌ Missing - required for hooks"`
- **python3**: !`command -v python3 >/dev/null && echo "✅ Available" || echo "❌ Missing - required for keyword generation"`

## Troubleshooting

If you see any ❌ issues above:

1. **Missing system**: Run `/skill-install` to set up the skill system
2. **Missing requirements**: Install missing tools (jq, python3)
3. **No recent activity**: Try using skill keywords in your prompts
4. **Hook not working**: Check `.claude/settings.local.json` for hook registration

Use `/skill-scan` to analyze skill quality and `/skill-update` to refresh keywords.