# Contributing to Claude Skill Manager

Thank you for your interest in contributing to Claude Skill Manager! This document provides guidelines for contributing to the project.

## Ways to Contribute

### 1. Bug Reports
- Use the [Bug Report template](.github/ISSUE_TEMPLATE/bug_report.md)
- Include system information (OS, Claude Code version, etc.)
- Provide steps to reproduce the issue
- Include relevant log files from `.claude/logs/skill-activation.log`

### 2. Feature Requests
- Use the [Feature Request template](.github/ISSUE_TEMPLATE/feature_request.md)
- Describe the use case and expected behavior
- Explain how it would benefit the community

### 3. Skill Contributions
- Submit new skills to the `community-skills/` directory
- Use the [Skill Submission template](.github/ISSUE_TEMPLATE/skill_submission.md)
- Ensure skills follow the [skill creation guidelines](docs/creating-skills.md)

### 4. Code Improvements
- Core system enhancements
- Platform compatibility improvements
- Performance optimizations
- Documentation updates

## Development Setup

### Prerequisites
- bash (shell scripting)
- jq (JSON processing)
- python3 (keyword generation)
- git (version control)

### Local Development

1. **Fork and Clone**
   ```bash
   git clone https://github.com/your-username/claude-skill-manager.git
   cd claude-skill-manager
   ```

2. **Test Installation**
   ```bash
   # Create a test project
   mkdir test-project
   cd test-project
   
   # Run installation
   ../install.sh .
   
   # Verify functionality
   ./.claude/skills/skill-keyword-manager/templates/commands/skill-status.md
   ```

3. **Run Tests**
   ```bash
   # Run the test suite
   ./scripts/run-tests.sh
   
   # Validate specific components
   ./scripts/validate-contribution.sh
   ```

## Contribution Guidelines

### Code Style

**Bash Scripts:**
- Use `set -e` for error handling
- Include descriptive comments
- Use consistent indentation (2 spaces)
- Quote variable expansions: `"$variable"`

**Python Scripts:**
- Follow PEP 8 style guidelines
- Include docstrings for functions
- Use type hints where appropriate
- Handle errors gracefully

**Markdown Documentation:**
- Use consistent heading levels
- Include code examples with syntax highlighting
- Keep lines under 100 characters where practical

### Skill Contributions

**Quality Standards:**
- Generic, reusable content (no project-specific references)
- Complete SKILL.md with proper frontmatter
- Tested functionality
- Clear documentation

**Submission Process:**
1. Create skill in `community-skills/your-skill-name/`
2. Include SKILL.md and any supporting files
3. Add entry to `community-skills/README.md`
4. Submit pull request with skill description

### Pull Request Process

1. **Branch Naming**
   ```bash
   git checkout -b feature/skill-name
   git checkout -b fix/issue-description
   git checkout -b docs/update-section
   ```

2. **Commit Messages**
   - Use clear, descriptive commit messages
   - Reference issue numbers when applicable
   - Use conventional commit format when possible

3. **Pull Request Requirements**
   - Fill out the pull request template
   - Include tests for new functionality
   - Update documentation as needed
   - Ensure all CI checks pass

4. **Review Process**
   - Maintainers will review within 1-2 weeks
   - Address feedback promptly
   - Squash commits before merge

### Testing Requirements

**For Core System Changes:**
- Test installation on multiple platforms (macOS, Linux)
- Test with different project types (Node.js, Python, etc.)
- Verify hook functionality
- Check slash command integration

**For Skill Contributions:**
- Validate skill structure
- Test keyword generation
- Verify skill activation
- Check for security issues

### Security Considerations

**Script Security:**
- No arbitrary code execution
- Validate all user inputs
- Use secure temporary file handling
- Avoid exposing sensitive information in logs

**Skill Security:**
- No network requests to external services
- No file system access outside project directory
- No credential storage or transmission

## Community Guidelines

### Code of Conduct
- Be respectful and inclusive
- Help newcomers learn the system
- Provide constructive feedback
- Focus on technical merit

### Communication
- Use GitHub Issues for bug reports and feature requests
- Use GitHub Discussions for questions and ideas
- Be patient with response times (this is community-maintained)

### Skill Sharing Ethics
- Only contribute skills you have permission to share
- Respect intellectual property
- Give credit to original creators
- Don't submit proprietary or confidential content

## Release Process

### Version Numbering
- Use semantic versioning (MAJOR.MINOR.PATCH)
- MAJOR: Breaking changes to installation/API
- MINOR: New features, additional functionality
- PATCH: Bug fixes, documentation updates

### Release Checklist
- [ ] Update CHANGELOG.md
- [ ] Tag release with `git tag v1.2.3`
- [ ] Create GitHub release with binaries
- [ ] Update documentation links
- [ ] Announce in GitHub Discussions

## Getting Help

### Documentation
- [Installation Guide](docs/installation.md)
- [Usage Guide](docs/usage.md)
- [API Reference](docs/api-reference.md)
- [Troubleshooting](docs/troubleshooting.md)

### Support Channels
- [GitHub Issues](https://github.com/your-username/claude-skill-manager/issues) - Bug reports and feature requests
- [GitHub Discussions](https://github.com/your-username/claude-skill-manager/discussions) - Questions and community discussion

### Maintainer Response Time
- Bug reports: 1-2 weeks
- Feature requests: 2-4 weeks  
- Pull requests: 1-2 weeks
- Security issues: 1-3 days

Thank you for contributing to Claude Skill Manager!