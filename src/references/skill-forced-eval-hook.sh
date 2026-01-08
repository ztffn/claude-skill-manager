#!/bin/bash
# UserPromptSubmit hook that triggers skill evaluation based on keywords
#
# This hook checks the user prompt against skill keywords and only triggers
# full skill evaluation when relevant keywords are detected.
#
# Installation: Copy to .claude/hooks/UserPromptSubmit

# Dynamic path resolution - works in any project
CLAUDE_DIR="$(dirname "$0")/.."
CONFIG_FILE="$CLAUDE_DIR/skill-config.json"

# Load configuration if available, otherwise use defaults
if [[ -f "$CONFIG_FILE" ]]; then
    KEYWORD_FILE="$CLAUDE_DIR/$(jq -r '.paths.keyword_file // "skills/skill-keywords.json"' "$CONFIG_FILE")"
    SKILL_THRESHOLD=$(jq -r '.hook_settings.skill_threshold // 14' "$CONFIG_FILE")
    ENABLE_LOGGING=$(jq -r '.hook_settings.enable_logging // true' "$CONFIG_FILE")
else
    # Default paths when no config exists
    KEYWORD_FILE="$CLAUDE_DIR/skills/skill-keywords.json"
    SKILL_THRESHOLD=14
    ENABLE_LOGGING=${CLAUDE_SKILL_LOGGING:-true}
fi

# Read JSON from stdin and extract prompt
INPUT_JSON=$(cat)
USER_PROMPT=$(echo "$INPUT_JSON" | jq -r '.prompt')

# Function to check if prompt contains any keywords for a skill
check_keywords() {
    local skill_name="$1"
    local prompt_lower=$(echo "$USER_PROMPT" | tr '[:upper:]' '[:lower:]')
    
    # Extract keywords and sort by length (longest first for specificity)
    local keywords
    if ! keywords=$(jq -r ".\"$skill_name\" | to_entries[] | .value[]" "$KEYWORD_FILE" | awk '{print length($0) " " $0}' | sort -rn | cut -d' ' -f2-); then
        echo "ERROR: Failed to extract keywords for skill '$skill_name'" >&2
        return 1
    fi
    
    # Check if any keyword appears in the prompt
    while IFS= read -r keyword; do
        if [[ "$prompt_lower" == *"$keyword"* ]]; then
            MATCHED_KEYWORD="$keyword"
            MATCHED_SKILL="$skill_name"
            return 0  # Found a match
        fi
    done <<< "$keywords"
    
    return 1  # No match found
}

# Check if keyword file and jq exist
if [[ ! -f "$KEYWORD_FILE" ]]; then
    echo "ERROR: Keyword file not found: $KEYWORD_FILE" >&2
    exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
    echo "ERROR: jq is required but not installed" >&2
    exit 1
fi
# Check for keyword matches
TRIGGER_EVAL=false

# Get list of actual skills (exclude metadata keys starting with _)
if ! SKILLS=$(jq -r 'keys[] | select(startswith("_") | not)' "$KEYWORD_FILE"); then
    echo "ERROR: Failed to parse skills from keyword file" >&2
    exit 1
fi
# Find best match using combined scoring
prompt_lower=$(echo "$USER_PROMPT" | tr '[:upper:]' '[:lower:]')
best_score=0
best_skill=""
best_keyword=""

# Simple arrays for compatibility
skill_names=""
skill_scores_list=""
skill_keywords_list=""

while IFS= read -r skill; do
    if [[ -n "$skill" ]]; then
        skill_total=0
        matched_keywords=""
        
        # Check each category with priority scoring
        for category in "triggers" "technology" "actions" "name_variants"; do
            if ! keywords=$(jq -r ".\"$skill\".\"$category\"[]?" "$KEYWORD_FILE"); then
                echo "ERROR: Failed to parse keywords for skill '$skill', category '$category'" >&2
                exit 1
            fi
            
            while IFS= read -r keyword; do
                if [[ -n "$keyword" ]]; then
                    # Category priority: technology=10, triggers=4, actions=2, name_variants=1
                    case $category in
                        "triggers") category_score=4 ;;
                        "technology") category_score=10 ;;
                        "actions") category_score=2 ;;
                        *) category_score=1 ;;
                    esac
                    
                    # Check for exact phrase match first (full score)
                    if [[ "$prompt_lower" == *"$keyword"* ]]; then
                        skill_total=$((skill_total + category_score))
                        # Only add if not already in matched_keywords (proper deduplication)
                        if [[ ",$matched_keywords," != *",$keyword,"* ]]; then
                            if [[ -n "$matched_keywords" ]]; then
                                matched_keywords="$matched_keywords, $keyword"
                            else
                                matched_keywords="$keyword"
                            fi
                        fi
                    else
                        # For compound phrases, check individual words
                        word_count=$(echo "$keyword" | wc -w)
                        if [[ $word_count -gt 1 ]]; then
                            words_matched=0
                            word_list=""
                            
                            # Check each word in the keyword
                            for word in $keyword; do
                                # Skip common words that add noise
                                if [[ "$word" != "the" && "$word" != "and" && "$word" != "or" && "$word" != "to" && "$word" != "of" && "$word" != "in" && "$word" != "for" && "$word" != "with" && "$word" != "this" && "$word" != "app" && "$word" != "my" && "$word" != "a" && "$word" != "an" && "$word" != "is" && "$word" != "are" ]]; then
                                    if [[ "$prompt_lower" == *"$word"* ]]; then
                                        words_matched=$((words_matched + 1))
                                        # Only add if not already in word_list (proper deduplication)
                                        if [[ " $word_list " != *" $word "* ]]; then
                                            if [[ -n "$word_list" ]]; then
                                                word_list="$word_list $word"
                                            else
                                                word_list="$word"
                                            fi
                                        fi
                                    fi
                                fi
                            done
                            
                            # Score if we matched at least half the significant words
                            significant_words=$word_count
                            for skip_word in "the" "and" "or" "to" "of" "in" "for" "with" "this" "app" "my" "a" "an" "is" "are"; do
                                if [[ "$keyword" == *" $skip_word "* || "$keyword" == "$skip_word "* || "$keyword" == *" $skip_word" ]]; then
                                    significant_words=$((significant_words - 1))
                                fi
                            done
                            
                            if [[ $words_matched -gt 0 && $words_matched -ge $((significant_words / 2)) ]]; then
                                # Partial score based on word match ratio
                                word_score=$(( (category_score * words_matched * 2) / significant_words ))
                                if [[ $word_score -gt 0 ]]; then
                                    skill_total=$((skill_total + word_score))
                                    # Only add word_list if not already in matched_keywords (proper deduplication)
                                    if [[ ",$matched_keywords," != *",$word_list,"* ]]; then
                                        if [[ -n "$matched_keywords" ]]; then
                                            matched_keywords="$matched_keywords, $word_list"
                                        else
                                            matched_keywords="$word_list"
                                        fi
                                    fi
                                fi
                            fi
                        fi
                    fi
                fi
            done <<< "$keywords"
        done
        
        # Store the total score for this skill
        if [[ $skill_total -gt 0 ]]; then
            # Store in simple format: skill:score:keywords
            skill_names="$skill_names$skill|"
            skill_scores_list="$skill_scores_list$skill_total|"
            skill_keywords_list="$skill_keywords_list$matched_keywords|"
            
            if [[ $skill_total -gt $best_score ]]; then
                best_score=$skill_total
                best_skill="$skill"
                best_keyword="$matched_keywords"
            fi
        fi
    fi
done <<< "$SKILLS"

# Set the best match variables for compatibility
if [[ $best_score -gt 0 ]]; then
    MATCHED_KEYWORD="$best_keyword"
    MATCHED_SKILL="$best_skill"
    TRIGGER_EVAL=true
fi

# Log the activation attempt if logging is enabled
if [[ "$ENABLE_LOGGING" == "true" ]]; then
    if [[ -f "$CONFIG_FILE" ]]; then
        LOG_FILE="$CLAUDE_DIR/$(jq -r '.hook_settings.log_file // "logs/skill-activation.log"' "$CONFIG_FILE")"
    else
        LOG_FILE="$CLAUDE_DIR/logs/skill-activation.log"
    fi
    LOG_DIR="$(dirname "$LOG_FILE")"
    mkdir -p "$LOG_DIR"
    
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    PROMPT_PREVIEW=$(echo "$USER_PROMPT" | head -c 100 | tr '\n' ' ')
    
    if [[ "$TRIGGER_EVAL" == "true" ]]; then
        echo "$TIMESTAMP | SUCCESS | SKILL=$MATCHED_SKILL | KEYWORD='$MATCHED_KEYWORD' | PROMPT='$PROMPT_PREVIEW'" >> "$LOG_FILE"
        
        # Log all skills above threshold for debugging
        IFS='|' read -ra skill_array <<< "$skill_names"
        IFS='|' read -ra score_array <<< "$skill_scores_list"
        IFS='|' read -ra keywords_array <<< "$skill_keywords_list"
        
        for i in "${!skill_array[@]}"; do
            skill_name="${skill_array[$i]}"
            score="${score_array[$i]}"
            keywords_matched="${keywords_array[$i]}"
            
            if [[ -n "$skill_name" && $score -ge $SKILL_THRESHOLD ]]; then
                echo "$TIMESTAMP | CANDIDATE | SKILL=$skill_name | SCORE=$score | KEYWORD='$keywords_matched' | PROMPT='$PROMPT_PREVIEW'" >> "$LOG_FILE"
            fi
        done
    else
        echo "$TIMESTAMP | NO_MATCH | SKILL=none | KEYWORD=none | PROMPT='$PROMPT_PREVIEW'" >> "$LOG_FILE"
    fi
fi

# Note: SKILL_THRESHOLD is now loaded from configuration above

# Build skill probability list if above threshold
if [[ $best_score -ge $SKILL_THRESHOLD ]]; then
    # Calculate percentages and build suggestion list
    skill_suggestions=""
    skill_count=0
    
    # Parse stored skill data and show candidates above threshold
    IFS='|' read -ra skill_array <<< "$skill_names"
    IFS='|' read -ra score_array <<< "$skill_scores_list"
    IFS='|' read -ra keywords_array <<< "$skill_keywords_list"
    
    for i in "${!skill_array[@]}"; do
        skill_name="${skill_array[$i]}"
        score="${score_array[$i]}"
        keywords_matched="${keywords_array[$i]}"
        
        if [[ -n "$skill_name" && $score -ge $SKILL_THRESHOLD ]]; then
            # Convert score to rough percentage (normalize against reasonable max)
            percentage=$(( (score * 100) / 20 ))  # Assume max reasonable score is ~20
            if [[ $percentage -gt 95 ]]; then percentage=95; fi
            
            skill_suggestions="$skill_suggestions- $skill_name: ${percentage}% match (matched: $keywords_matched)\n"
            skill_count=$((skill_count + 1))
        fi
    done
    
    # Show skill probability analysis if we have candidates
    if [[ $skill_count -gt 0 ]]; then
        # Detailed analysis for Claude to see and act on
        echo ""
        echo "SKILL PROBABILITY ANALYSIS:"
        echo -e "$skill_suggestions"
        echo ""
        echo "AGENT DECISION REQUIRED:"
        echo "1. THINK: Analyze each skill's relevance to the user's request"
        echo "2. EVALUATE: Which skills are most appropriate for this specific task?"
        echo "3. CHOOSE: Select 1-3 skills that best match the user's intent"
        echo "4. ACTIVATE: Use Skill() tool for your chosen skills before proceeding"
        echo "5. IGNORE: If no skills seem to be relevant, do not activate any skills, just proceed with the task."
        echo ""
        
        # JSON output with systemMessage for user notification
        echo '{"systemMessage": "🎯 Skill suggestions available - analyzing your request for relevant capabilities"}'
    fi
fi
