#!/bin/bash
# Skill System Installation Script
# Installs the skill system in any project with auto-detection and configuration

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Detect project root (look for common project indicators)
detect_project_root() {
    local current_dir="$(pwd)"
    
    # Primary case: if we're in .claude/skills directory, derive project root
    if [[ "$current_dir" == *"/.claude/skills"* ]]; then
        # Extract project root by removing /.claude/skills and everything after
        local project_root="${current_dir%/.claude/skills*}"
        if [[ -n "$project_root" ]] && [[ -d "$project_root" ]]; then
            echo "$project_root"
            return 0
        fi
    fi
    
    local search_dir="$current_dir"
    
    # Look for project indicators, but skip .claude/skills directories
    while [[ "$search_dir" != "/" ]]; do
        # Skip if we're in a .claude/skills subdirectory
        if [[ "$search_dir" == *"/.claude/skills"* ]]; then
            search_dir="$(dirname "$search_dir")"
            continue
        fi
        
        if [[ -f "$search_dir/package.json" ]] || \
           [[ -f "$search_dir/pyproject.toml" ]] || \
           [[ -f "$search_dir/Cargo.toml" ]] || \
           [[ -f "$search_dir/go.mod" ]] || \
           [[ -d "$search_dir/.git" ]]; then
            echo "$search_dir"
            return 0
        fi
        search_dir="$(dirname "$search_dir")"
    done
    
    # Fallback to current directory
    echo "$current_dir"
}

# Detect project technology stack
detect_tech_stack() {
    local project_root="$1"
    local tech_stack=""
    
    if [[ -f "$project_root/package.json" ]]; then
        tech_stack="$tech_stack nodejs"
        
        # Check for specific frameworks
        if grep -q "next" "$project_root/package.json" 2>/dev/null; then
            tech_stack="$tech_stack nextjs"
        fi
        if grep -q "react" "$project_root/package.json" 2>/dev/null; then
            tech_stack="$tech_stack react"
        fi
        if grep -q "typescript" "$project_root/package.json" 2>/dev/null; then
            tech_stack="$tech_stack typescript"
        fi
        if grep -q "tailwind" "$project_root/package.json" 2>/dev/null; then
            tech_stack="$tech_stack tailwind"
        fi
    fi
    
    if [[ -f "$project_root/pyproject.toml" ]] || [[ -f "$project_root/requirements.txt" ]]; then
        tech_stack="$tech_stack python"
    fi
    
    if [[ -f "$project_root/Cargo.toml" ]]; then
        tech_stack="$tech_stack rust"
    fi
    
    if [[ -f "$project_root/go.mod" ]]; then
        tech_stack="$tech_stack go"
    fi
    
    echo "$tech_stack" | tr ' ' '\n' | sort | uniq | tr '\n' ' ' | sed 's/ $//'
}

# Check system requirements
check_requirements() {
    log_info "Checking system requirements..."
    
    local missing=""
    for tool in bash jq python3; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            missing="$missing $tool"
        fi
    done
    
    if [[ -n "$missing" ]]; then
        log_error "Missing required tools:$missing"
        log_info "Please install the missing tools and try again."
        exit 1
    fi
    
    log_success "All required tools are available"
}

# Create directory structure
create_directories() {
    local claude_dir="$1"
    
    log_info "Creating directory structure..."
    
    mkdir -p "$claude_dir"/{skills,hooks,logs}
    
    log_success "Directory structure created"
}

# Copy skill system files
copy_skill_system() {
    local script_dir="$(dirname "$0")"
    local source_dir="$(realpath "$script_dir")"
    local claude_dir="$(realpath "$1")"
    local project_root="$(realpath "$1")"
    
    log_info "Installing skill system files..."
    
    # Guardrail 1: Prevent infinite recursion - don't copy project root into itself
    if [[ "$source_dir" == "$project_root" ]]; then
        log_error "Cannot install: Would create infinite recursion"
        log_error "Script location: $source_dir"
        log_error "Project root: $project_root"
        log_info "Solution: Run install script from skill manager directory, not project root"
        exit 1
    fi
    
    # Check if we're already in the target .claude/skills/ directory
    if [[ "$source_dir" == *"/.claude/skills/"* ]]; then
        log_info "Skill manager already in .claude/skills/ - setting up hooks and config only"
        local skill_manager_dir="$source_dir"
    else
        # Guardrail 2: Don't overwrite existing installation without confirmation
        if [[ -d "$claude_dir/skills/skill-keyword-manager" ]]; then
            log_warning "Skill manager already exists at $claude_dir/skills/skill-keyword-manager"
            log_info "Use --force flag to overwrite existing installation"
            exit 1
        fi
        
        # Copy the skill manager to .claude/skills/
        log_info "Copying skill manager to .claude/skills/"
        cp -r "$source_dir" "$claude_dir/skills/skill-keyword-manager"
        local skill_manager_dir="$claude_dir/skills/skill-keyword-manager"
    fi
    
    # Copy hook script to hooks directory
    [[ ! -d "$claude_dir/hooks" ]] && mkdir -p "$claude_dir/hooks"
    cp "$skill_manager_dir/src/references/skill-forced-eval-hook.sh" "$claude_dir/hooks/"
    
    # Copy skill management slash commands
    if [[ -d "$skill_manager_dir/src/templates/commands" ]]; then
        [[ ! -d "$claude_dir/commands" ]] && mkdir -p "$claude_dir/commands"
        cp "$skill_manager_dir/src/templates/commands/"*.md "$claude_dir/commands/"
        log_info "Installed skill management slash commands"
    fi
    
    # Create initial keyword file if it doesn't exist
    [[ ! -d "$skill_manager_dir/references" ]] && mkdir -p "$skill_manager_dir/references"
    if [[ ! -f "$skill_manager_dir/references/skill-keywords.json" ]]; then
        echo '{"_last_updated": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'", "_version": "1.0.0"}' > "$skill_manager_dir/references/skill-keywords.json"
    fi
    
    log_success "Skill system files installed"
}

# Create project-specific configuration
create_configuration() {
    local claude_dir="$1"
    local project_root="$2"
    local tech_stack="$3"
    local project_name="$(basename "$project_root")"
    
    log_info "Creating project configuration..."
    
    # Create skill-config.json from template
    local config_file="$claude_dir/skill-config.json"
    cat > "$config_file" << EOF
{
  "project_root": "$project_root",
  "paths": {
    "skills_dir": "skills",
    "logs_dir": "logs",
    "hooks_dir": "hooks", 
    "keyword_file": "skills/skill-keyword-manager/references/skill-keywords.json"
  },
  "hook_settings": {
    "enable_logging": true,
    "skill_threshold": 14,
    "log_file": "logs/skill-activation.log"
  },
  "project_info": {
    "name": "$project_name",
    "tech_stack": [$tech_stack],
    "domain": "general"
  },
  "compatibility": {
    "version": "1.0.0",
    "required_tools": ["bash", "jq", "python3"],
    "optional_tools": []
  }
}
EOF
    
    log_success "Configuration created: $config_file"
}

# Update Claude Code settings
update_claude_settings() {
    local claude_dir="$1"
    local settings_file="$claude_dir/settings.local.json"
    
    log_info "Updating Claude Code settings..."
    
    # Create or update settings file
    if [[ -f "$settings_file" ]]; then
        log_warning "Existing settings file found - backing up to settings.local.json.backup"
        cp "$settings_file" "$settings_file.backup"
    fi
    
    # Create basic settings with hook registration
    cat > "$settings_file" << 'EOF'
{
  "hooks": {
    "UserPromptSubmit": "./hooks/skill-forced-eval-hook.sh"
  },
  "permissions": {
    "allowWebSearch": true,
    "allowWebFetch": [
      "github.com",
      "docs.anthropic.com"
    ]
  }
}
EOF
    
    log_success "Claude Code settings updated"
}

# Generate initial keywords
generate_keywords() {
    local claude_dir="$1"
    local skill_manager="$claude_dir/skills/skill-keyword-manager"
    
    log_info "Generating initial skill keywords..."
    
    if [[ -f "$skill_manager/scripts/update_keywords.py" ]]; then
        cd "$claude_dir"
        python3 "$skill_manager/scripts/update_keywords.py" || {
            log_warning "Keyword generation failed - you can run it manually later"
            return 0
        }
        log_success "Initial keywords generated"
    else
        log_warning "Keyword generation script not found"
    fi
}

# Main installation function
main() {
    log_info "Starting skill system installation..."
    
    # Detect project environment
    local project_root
    project_root="$(detect_project_root)"
    log_info "Project root detected: $project_root"
    
    local tech_stack
    tech_stack="$(detect_tech_stack "$project_root")"
    log_info "Technology stack detected: ${tech_stack:-none}"
    
    local claude_dir="$project_root/.claude"
    
    # Check requirements
    check_requirements
    
    # Install system
    create_directories "$claude_dir"
    copy_skill_system "$claude_dir"
    create_configuration "$claude_dir" "$project_root" "$tech_stack"
    update_claude_settings "$claude_dir"
    generate_keywords "$claude_dir"
    
    log_success "Skill system installation completed!"
    log_info ""
    log_info "Next steps:"
    log_info "1. Restart Claude Code to load the new hook system"
    log_info "2. Test the system by asking about skills or using skill keywords"
    log_info "3. Use skill management commands:"
    log_info "   /skill-status   - Check system health"
    log_info "   /skill-list     - List available skills"
    log_info "   /skill-create   - Create new skills"
    log_info "   /skill-update   - Update keywords"
    log_info "   /skill-scan     - Audit skill quality"
    log_info "4. Check logs in $claude_dir/logs/skill-activation.log"
    log_info "5. Customize $claude_dir/skill-config.json for your project"
}

# Run main function
main "$@"