#!/bin/bash

# Lilith AI Query Processor
# Processes natural language queries and routes to appropriate specialized model

set -e

# Configuration
CONFIG_DIR="/opt/lilith-ai/config"
MODEL_DIR="/opt/lilith-ai/models"
SCRIPT_DIR="/opt/lilith-ai/scripts"
LOG_DIR="/opt/lilith-ai/logs"

# Input parameters
QUERY="$1"
OUTPUT_FILE="${2:-/tmp/lilith-output.txt}"
TASK_HINT="${3:-auto}"

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $*" >> "$LOG_DIR/query.log"
}

# Function to determine task category based on keywords
determine_task() {
    local query_lower=$(echo "$1" | tr '[:upper:]' '[:lower:]')

    # Academic keywords (highest priority for Lilith's educational focus)
    if echo "$query_lower" | grep -q -E "(study|homework|exam|learn|practice|quiz|test|grade|coursework|medical assistant|anatomy|physiology|patient care)"; then
        echo "academic"
    # System administration
    elif echo "$query_lower" | grep -q -E "(system|admin|troubleshoot|fix|configure|network|permission|service|process|disk|memory|cpu)"; then
        echo "sysadmin"
    # Code/programming
    elif echo "$query_lower" | grep -q -E "(code|program|script|debug|function|class|variable|algorithm|syntax|error|bug|bash|python|javascript|php)"; then
        echo "coding"
    # Writing/creative
    elif echo "$query_lower" | grep -q -E "(write|edit|content|creative|documentation|article|blog|proofread|grammar|style)"; then
        echo "writing"
    # Technical support
    elif echo "$query_lower" | grep -q -E "(support|help|troubleshoot|problem|error|can't|won't|how|issue|broken|not working|failed|crash|slow)"; then
        echo "techsupport"
    # Research/learning
    elif echo "$query_lower" | grep -q -E "(research|learn|summarize|find|information|study|understand|explain|tutorial|guide)"; then
        echo "research"
    else
        echo "general"
    fi
}

# Function to create system prompt based on task
create_system_prompt() {
    local task="$1"
    local config_file="$CONFIG_DIR/tasks/${task}.json"

    if [ -f "$config_file" ]; then
        # Use specialized system prompt from JSON config
        jq -r '.system_prompt' "$config_file" 2>/dev/null || echo "You are a helpful AI assistant for Lilith Linux. Provide clear, practical advice."
    else
        # Default general prompt
        echo "You are a helpful AI assistant for Lilith Linux. Provide clear, practical advice for Linux users. Be concise but thorough in your responses."
    fi
}

# Function to check if API fallback should be used
should_use_api_fallback() {
    local query="$1"
    local task="$2"
    local config_file="$CONFIG_DIR/tasks/${task}.json"

    # Check if API fallback is enabled for this task
    if [ -f "$config_file" ] && jq -e '.api_fallback.enabled' "$config_file" >/dev/null 2>&1; then
        local query_lower=$(echo "$query" | tr '[:upper:]' '[:lower:]')
        local triggers=$(jq -r '.api_fallback.triggers[]' "$config_file" 2>/dev/null)

        # Check if query matches any triggers
        for trigger in $triggers; do
            if echo "$query_lower" | grep -q "$trigger"; then
                return 0  # Use API fallback
            fi
        done
    fi

    return 1  # Use local AI
}

# Function to process with API fallback
process_with_api_fallback() {
    local query="$1"
    local task="$2"
    local output_file="$3"
    local config_file="$CONFIG_DIR/tasks/${task}.json"

    log "Attempting API fallback for task: $task"

    # Get API providers from config
    local providers=$(jq -r '.api_fallback.providers[]' "$config_file" 2>/dev/null)

    for provider in $providers; do
        case $provider in
            "openai")
                if [ -n "$OPENAI_API_KEY" ]; then
                    log "Trying OpenAI API"
                    if python3 "$SCRIPT_DIR/api-fallback.py" \
                        --provider openai \
                        --prompt "$query" \
                        --system-prompt "$(create_system_prompt "$task")" \
                        --output "$output_file" 2>/dev/null; then
                        echo "Response generated using OpenAI API" >> "$output_file"
                        return 0
                    fi
                fi
                ;;
            "anthropic")
                if [ -n "$ANTHROPIC_API_KEY" ]; then
                    log "Trying Anthropic API"
                    if python3 "$SCRIPT_DIR/api-fallback.py" \
                        --provider anthropic \
                        --prompt "$query" \
                        --system-prompt "$(create_system_prompt "$task")" \
                        --output "$output_file" 2>/dev/null; then
                        echo "Response generated using Anthropic API" >> "$output_file"
                        return 0
                    fi
                fi
                ;;
        esac
    done

    log "API fallback failed, falling back to local AI"
    return 1  # Fallback to local processing
}

# Main processing logic
main() {
    log "Processing query: $QUERY"

    # Determine task if not specified
    if [ "$TASK_HINT" = "auto" ]; then
        TASK=$(determine_task "$QUERY")
    else
        TASK="$TASK_HINT"
    fi

    log "Determined task: $TASK"

    # Create system prompt
    SYSTEM_PROMPT=$(create_system_prompt "$TASK")

    # Check for API fallback
    if should_use_api_fallback "$QUERY" "$TASK"; then
        log "Using API fallback for complex query"
        if process_with_api_fallback "$QUERY" "$TASK" "$OUTPUT_FILE"; then
            log "API fallback successful"
            return 0
        fi
    fi

    # Local AI processing
    log "Using local AI processing"

    # Create formatted prompt
    FULL_PROMPT="${SYSTEM_PROMPT}

User Query: ${QUERY}

Response:"

    # Save prompt to temporary file
    TEMP_PROMPT="/tmp/lilith-query-$$.txt"
    echo "$FULL_PROMPT" > "$TEMP_PROMPT"

    # Process with llama.cpp (if available)
    if [ -f "$SCRIPT_DIR/run-llama.sh" ] && [ -f "$MODEL_DIR/main-model.gguf" ]; then
        log "Running llama.cpp inference"
        bash "$SCRIPT_DIR/run-llama.sh" \
            "$MODEL_DIR/main-model.gguf" \
            "$TEMP_PROMPT" \
            "$OUTPUT_FILE"
    else
        # Fallback response
        log "No AI model available, providing basic response"
        cat > "$OUTPUT_FILE" << EOF
Lilith AI Assistant - Basic Response

I'm sorry, but the AI model is not currently available. Here's some general guidance for your query:

Query: $QUERY

For Lilith Linux support, please check:
- Documentation: /opt/lilith-ai/README.md
- Community forums: [coming soon]
- GitHub issues: https://github.com/BlancoBAM/Lilith-Linux/issues

In the meantime, here are some general Linux resources:
- man pages: man <command>
- Ubuntu documentation: https://ubuntu.com/desktop
- Ask Ubuntu: https://askubuntu.com
EOF
    fi

    # Post-process output (extract just the response)
    if [ -f "$OUTPUT_FILE" ]; then
        # Extract everything after "Response:" if it exists
        if grep -q "Response:" "$OUTPUT_FILE"; then
            sed -n '/Response:/,$p' "$OUTPUT_FILE" | sed '1d' | sed '/^$/d' > "${OUTPUT_FILE}.processed"
            mv "${OUTPUT_FILE}.processed" "$OUTPUT_FILE"
        fi
    fi

    # Cleanup
    rm -f "$TEMP_PROMPT"

    log "Query processing completed: $OUTPUT_FILE"
    echo "Response saved to: $OUTPUT_FILE"
}

# Run main function
main "$@"
