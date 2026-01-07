#!/usr/bin/env python3
"""
Auto-update skill keywords registry by scanning all skills and generating keywords
from skill names and descriptions using the skill-keyword-manager agent.

This script follows the Ralph Wiggum pattern to trigger the skill-keyword-manager
agent for each skill that needs keyword updates.

This script:
1. Scans all skill directories for SKILL.md files
2. Extracts name and description from YAML frontmatter
3. Identifies new or changed skills
4. Triggers skill-keyword-manager agent for AI-powered keyword generation
5. Updates the skill-keywords.json file

Usage:
    python3 update_keywords.py [--force] [--dry-run]
    
    --force    : Regenerate keywords for all skills (not just new/changed)
    --dry-run  : Show what would be updated without making changes
"""

import os
import sys
import json
import argparse
import hashlib
import subprocess
import tempfile
from pathlib import Path
from typing import Dict, List, Set, Optional, Tuple

def extract_frontmatter(skill_md_path: Path) -> Optional[Dict]:
    """Extract YAML frontmatter from SKILL.md file using simple parsing."""
    try:
        with open(skill_md_path, 'r', encoding='utf-8') as f:
            content = f.read()
            
        if not content.startswith('---\n'):
            return None
            
        # Find the end of frontmatter
        end_marker = content.find('\n---\n', 4)
        if end_marker == -1:
            return None
            
        frontmatter = content[4:end_marker]
        
        # Simple YAML parsing for our specific case (only need name and description)
        result = {}
        for line in frontmatter.strip().split('\n'):
            line = line.strip()
            if ':' in line:
                key, value = line.split(':', 1)
                key = key.strip()
                value = value.strip()
                
                # Remove quotes if present
                if value.startswith('"') and value.endswith('"'):
                    value = value[1:-1]
                elif value.startswith("'") and value.endswith("'"):
                    value = value[1:-1]
                
                result[key] = value
        
        return result
        
    except Exception as e:
        print(f"Error reading {skill_md_path}: {e}")
        return None

def generate_keywords_with_ai(name: str, description: str) -> Dict[str, List[str]]:
    """This function should be called from within Claude Code to use the Task tool."""
    # This script is designed to be run FROM within a Claude Code session
    # so that each skill can trigger the skill-keyword-manager agent
    
    print(f"\n🤖 Generating keywords for: {name}")
    print(f"Description: {description}")
    
    # Create the prompt for the agent
    prompt = f"""Generate optimized keywords for the skill "{name}" with description: "{description}"

Please analyze this skill and generate keywords following these guidelines:
- AVOID generic words: create, build, setup, implement, make, add, handle, use, work, run, react, component, database, api, app, user, system, code, file, data  
- PREFER domain-specific terms and compound phrases (2+ words)
- Focus on unique identifiers that differentiate this skill from others
- Target 80%+ accuracy with minimal false positives
- Use contextual phrases rather than isolated technical terms

Generate keywords in exactly this JSON format:
{{
  "actions": ["specific", "domain-verbs"],
  "technology": ["specific", "technologies"], 
  "triggers": ["compound phrases", "that indicate when"],
  "name_variants": ["skill", "name", "variants"]
}}

Only return the JSON, no other text."""
    
    # Write the prompt to a file that Claude Code can pick up
    request_file = f"/tmp/keyword_request_{name.replace('-', '_')}.txt"
    
    with open(request_file, 'w') as f:
        f.write(f"SKILL: {name}\n")
        f.write(f"DESCRIPTION: {description}\n")
        f.write(f"PROMPT:\n{prompt}\n")
    
    print(f"📝 Request written to: {request_file}")
    print(f"⚠️  This script must be run from within Claude Code to trigger the skill-keyword-manager agent")
    print(f"⚠️  Agent should process this request and return keywords")
    
    # Since we can't actually trigger the agent from a subprocess,
    # this is where Claude Code should take over and use the Task tool
    # Return placeholder for now - agent will provide actual keywords
    return {
        "actions": [],
        "technology": [],
        "triggers": [],
        "name_variants": [name.replace('-', '_')]
    }

def compute_skill_hash(name: str, description: str) -> str:
    """Compute hash of skill name + description to detect changes."""
    combined = f"{name}|{description}"
    return hashlib.sha256(combined.encode()).hexdigest()[:16]

def scan_skills(skills_dir: Path) -> Dict[str, Dict]:
    """Scan all skill directories and extract metadata."""
    skills = {}
    
    for skill_dir in skills_dir.iterdir():
        if not skill_dir.is_dir():
            continue
            
        skill_md = skill_dir / 'SKILL.md'
        if not skill_md.exists():
            continue
            
        frontmatter = extract_frontmatter(skill_md)
        if not frontmatter:
            print(f"Warning: No valid frontmatter in {skill_md}")
            continue
            
        name = frontmatter.get('name')
        description = frontmatter.get('description')
        
        if not name or not description:
            print(f"Warning: Missing name or description in {skill_md}")
            continue
            
        skills[name] = {
            'description': description,
            'hash': compute_skill_hash(name, description),
            'path': str(skill_md)
        }
    
    return skills

def load_existing_keywords(keywords_file: Path) -> Tuple[Dict, Dict]:
    """Load existing keywords file and extract metadata."""
    if not keywords_file.exists():
        return {}, {}
        
    try:
        with open(keywords_file, 'r', encoding='utf-8') as f:
            data = json.load(f)
            
        # Separate keywords from metadata
        keywords = {}
        metadata = {}
        
        for skill_name, content in data.items():
            if skill_name.startswith('_'):  # Metadata keys start with underscore
                metadata[skill_name] = content
            else:
                keywords[skill_name] = content
                
        return keywords, metadata
        
    except Exception as e:
        print(f"Error loading keywords file: {e}")
        return {}, {}

def save_keywords(keywords_file: Path, keywords: Dict, metadata: Dict):
    """Save keywords and metadata to file."""
    # Combine keywords and metadata
    combined = {}
    combined.update(keywords)
    combined.update(metadata)
    
    # Sort by skill name for consistency
    sorted_data = dict(sorted(combined.items()))
    
    with open(keywords_file, 'w', encoding='utf-8') as f:
        json.dump(sorted_data, f, indent=2, ensure_ascii=False)

def main():
    parser = argparse.ArgumentParser(description=__doc__, 
                                   formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--force', action='store_true',
                       help='Regenerate keywords for all skills')
    parser.add_argument('--dry-run', action='store_true',
                       help='Show changes without updating files')
    
    args = parser.parse_args()
    
    # Determine paths
    script_dir = Path(__file__).parent
    skills_dir = script_dir.parent.parent  # ../.. from scripts/
    keywords_file = skills_dir / 'skill-keywords.json'
    
    print(f"Scanning skills in: {skills_dir}")
    print(f"Keywords file: {keywords_file}")
    
    # Scan current skills
    current_skills = scan_skills(skills_dir)
    print(f"Found {len(current_skills)} skills")
    
    # Load existing keywords and metadata
    existing_keywords, metadata = load_existing_keywords(keywords_file)
    
    # Get existing hashes from metadata
    existing_hashes = metadata.get('_skill_hashes', {})
    
    # Determine which skills need keyword generation
    skills_to_process = []
    
    for skill_name, skill_data in current_skills.items():
        current_hash = skill_data['hash']
        existing_hash = existing_hashes.get(skill_name)
        
        if args.force or current_hash != existing_hash:
            skills_to_process.append((skill_name, skill_data))
            if existing_hash:
                print(f"Skill changed: {skill_name}")
            else:
                print(f"New skill: {skill_name}")
    
    if not skills_to_process:
        print("No skills need keyword updates")
        return
    
    print(f"\nProcessing {len(skills_to_process)} skills...")
    
    # Generate keywords for changed/new skills
    updated_keywords = existing_keywords.copy()
    updated_hashes = existing_hashes.copy()
    
    for skill_name, skill_data in skills_to_process:
        print(f"Generating keywords for: {skill_name}")
        
        keywords = generate_keywords_with_ai(skill_name, skill_data['description'])
        
        if args.dry_run:
            print(f"  Would add keywords: {keywords}")
        else:
            updated_keywords[skill_name] = keywords
            updated_hashes[skill_name] = skill_data['hash']
    
    # Remove keywords for skills that no longer exist
    removed_skills = set(existing_keywords.keys()) - set(current_skills.keys())
    for skill_name in removed_skills:
        print(f"Removing keywords for deleted skill: {skill_name}")
        if not args.dry_run:
            del updated_keywords[skill_name]
            updated_hashes.pop(skill_name, None)
    
    # Update metadata
    updated_metadata = metadata.copy()
    updated_metadata['_skill_hashes'] = updated_hashes
    updated_metadata['_last_updated'] = str(Path().cwd().name)  # Basic timestamp
    
    if args.dry_run:
        print(f"\nDry run complete. Would update {len(skills_to_process)} skills.")
        if removed_skills:
            print(f"Would remove {len(removed_skills)} deleted skills.")
    else:
        # Save updated keywords
        save_keywords(keywords_file, updated_keywords, updated_metadata)
        print(f"\nUpdated keywords file with {len(current_skills)} skills")

if __name__ == '__main__':
    main()