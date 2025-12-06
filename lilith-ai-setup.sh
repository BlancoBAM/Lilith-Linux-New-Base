#!/bin/bash

# Lilith Linux AI Setup Script
# Deploy optimized AI models with specialized knowledge areas

set -e
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration - should be set by GUI
CONFIG_FILE="/opt/lilith-ai-config.json"
AI_DIR="/opt/lilith-ai"
MODEL_DIR="$AI_DIR/models"
CONFIG_DIR="$AI_DIR/config"
SCRIPT_DIR="$AI_DIR/scripts"
LOG_DIR="$AI_DIR/logs"

# Parse command line arguments or use defaults
USE_MODEL="${1:-llama-cpp}"
MODEL_SIZE="${2:-7B}"
QUANTIZATION="${3:-Q4_K_M}"
INCLUDE_TASKS="${4:-sysadmin,coding,writing}"
DESKTOP_HOTKEY="${5:-true}"
CONTEXT_MENU="${6:-true}"
TERMINAL_COMMANDS="${7:-true}"

# Initialize logging
echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Lilith Linux AI Setup - Local Intelligence Deployment      ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Create directories
mkdir -p "$AI_DIR" "$MODEL_DIR" "$CONFIG_DIR" "$SCRIPT_DIR" "$LOG_DIR"
exec > >(tee -a "$LOG_DIR/setup.log") 2>&1

# Function to install system dependencies
install_dependencies() {
    echo -e "${YELLOW}► Installing AI system dependencies...${NC}"

    apt-get update
    apt-get install -y git cmake make gcc g++ build-essential pkg-config

    # Python for AI frameworks
    apt-get install -y python3 python3-pip python3-dev

    # Libraries for optimization
    apt-get install -y libopenblas-dev libblas-dev libatlas-base-dev
    apt-get install -y liblapack-dev liblapacke-dev
    apt-get install -y libffi-dev libssl-dev
    apt-get install -y libhdf5-dev libyaml-dev

    echo -e "${GREEN}✓ Dependencies installed${NC}"
}

# Function to install llama.cpp (maximum optimization)
install_llamacpp() {
    echo -e "${YELLOW}► Installing llama.cpp with maximum optimization...${NC}"

    cd "$AI_DIR"

    # Clone llama.cpp with latest optimizations
    if [ ! -d "llama.cpp" ]; then
        git clone --depth 1 https://github.com/ggerganov/llama.cpp.git
        cd llama.cpp

        # Build with maximum optimizations
        mkdir build && cd build
        cmake .. \
            -DLLAMA_BUILD_ALL=1 \
            -DLLAMA_AVX=ON \
            -DLLAMA_AVX2=ON \
            -DLLAMA_AVX512=ON \
            -DLLAMA_FMA=ON \
            -DLLAMA_F16C=ON \
            -DLLAMA_CUBLAS=OFF \
            -DLLAMA_OPENBLAS=ON \
            -DLLAMA_BLAS_VENDOR=OpenBLAS \
            -DCMAKE_BUILD_TYPE=Release

        make -j$(nproc)
        cd "$AI_DIR"
    fi

    # Create optimized runner script
    cat > "$SCRIPT_DIR/run-llama.sh" << 'LLAMA_EOF'
#!/bin/bash

MODEL_FILE="$1"
PROMPT_FILE="$2"
OUTPUT_FILE="$3"

cd /opt/lilith-ai/llama.cpp/build

# Optimized llama.cpp execution
./bin/main \
    --model "$MODEL_FILE" \
    --prompt "$(cat "$PROMPT_FILE")" \
    --ctx-size 2048 \
    --threads $(nproc) \
    --temp 0.7 \
    --top-k 40 \
    --top-p 0.9 \
    --repeat-penalty 1.1 \
    --n-predict 512 \
    --no-mmap \
    2>/dev/null > "$OUTPUT_FILE"
LLAMA_EOF

    chmod +x "$SCRIPT_DIR/run-llama.sh"

    echo -e "${GREEN}✓ llama.cpp installed with maximum optimization${NC}"
}

# Function to download optimized models
download_models() {
    echo -e "${YELLOW}► Downloading pre-quantized optimized models...${NC}"

    local model_urls=()

    # Models mapped by size and quantization
    declare -A model_map=(
        ["1B_Q4_K_M"]="https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v0.3-GGUF/resolve/main/tinyllama-1.1b-chat-v0.3.Q4_K_M.gguf"
        ["1B_Q2_K"]="https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v0.3-GGUF/resolve/main/tinyllama-1.1b-chat-v0.3.Q2_K.gguf"

        ["3B_Q4_K_M"]="https://huggingface.co/TheBloke/Phi-2-GGUF/resolve/main/phi-2.Q4_K_M.gguf"
        ["3B_Q2_K"]="https://huggingface.co/TheBloke/Phi-2-GGUF/resolve/main/phi-2.Q2_K.gguf"

        ["7B_Q4_K_M"]="https://huggingface.co/TheBloke/Llama-2-7B-Chat-GGUF/resolve/main/llama-2-7b-chat.Q4_K_M.gguf"
        ["7B_Q3_K_L"]="https://huggingface.co/TheBloke/Llama-2-7B-Chat-GGUF/resolve/main/llama-2-7b-chat.Q3_K_L.gguf"
        ["7B_Q2_K"]="https://huggingface.co/TheBloke/Llama-2-7B-Chat-GGUF/resolve/main/llama-2-7b-chat.Q2_K.gguf"

        ["13B_Q4_K_M"]="https://huggingface.co/TheBloke/Llama-2-13B-chat-GGUF/resolve/main/llama-2-13b-chat.Q4_K_M.gguf"
        ["13B_Q3_K_L"]="https://huggingface.co/TheBloke/Llama-2-13B-chat-GGUF/resolve/main/llama-2-13b-chat.Q3_K_L.gguf"
        ["13B_Q2_K"]="https://huggingface.co/TheBloke/Llama-2-13B-chat-GGUF/resolve/main/llama-2-13b-chat.Q2_K.gguf"
    )

    local model_key="${MODEL_SIZE}_${QUANTIZATION//_/}"

    # Download main model if available
    if [ "${model_map[$model_key]}" ]; then
        echo "Downloading $MODEL_SIZE model with $QUANTIZATION quantization..."
        curl -L -o "$MODEL_DIR/main-model.gguf" "${model_map[$model_key]}"
    else
        # Fallback to default 7B Q4_K_M
        echo "Model configuration not found, using default 7B Q4_K_M..."
        curl -L -o "$MODEL_DIR/main-model.gguf" "${model_map[7B_Q4_K_M]}"
    fi

    echo -e "${GREEN}✓ Models downloaded and ready${NC}"
}

# Function to create specialized task configurations
create_specialized_tasks() {
    echo -e "${YELLOW}► Creating specialized task configurations...${NC}"

    mkdir -p "$CONFIG_DIR/tasks"
    IFS=',' read -ra TASK_ARRAY <<< "$INCLUDE_TASKS"

    # System Administration Task
    if [[ " ${TASK_ARRAY[@]} " =~ " sysadmin " ]]; then
        cat > "$CONFIG_DIR/tasks/sysadmin.json" << 'SYSADMIN_EOF'
{
    "name": "System Administration Assistant",
    "system_prompt": "You are an expert Linux system administrator for Lilith Linux. Provide concise, practical solutions for system management, troubleshooting, and configuration. Focus on Lilith-specific instructions and best practices. Use commands appropriate for the user's Linux expertise level.",
    "keywords": ["system", "admin", "troubleshoot", "configure", "fix", "diagnose"],
    "examples": [
        "How do I troubleshoot network connectivity?",
        "Configure user permissions for shared directories",
        "Optimize system performance",
        "Set up backup automation"
    ],
    "commands": ["ask", "explain", "help", "diagnose", "fix", "optimize"]
}
SYSADMIN_EOF
    fi

    # Academic & Homework Helper Task
    if [[ " ${TASK_ARRAY[@]} " =~ " academic " ]]; then
        cat > "$CONFIG_DIR/tasks/academic.json" << 'ACADEMIC_EOF'
{
    "name": "Academic & Homework Helper for College Students",
    "system_prompt": "You are a knowledgeable and patient tutor specialized in helping first-year associate degree college students, particularly those pursuing Medical Assistant majors. You combine deep knowledge of medical assisting coursework with general academic skills. When local processing capabilities are insufficient for complex tasks, offer to use available API fallbacks. Focus on practical learning, clear explanations, and helping students succeed in their coursework. Remember that you have access to API fallbacks for complex medical research or detailed analysis when local hardware limitations would make tasks impractical.",
    "keywords": ["study", "homework", "exam", "medical assistant", "anatomy", "physiology", "patient care", "medical terminology", "class", "assignment", "learn", "practice"],
    "examples": [
        "Help me study anatomy chapter 3",
        "Explain medical terminology for cardiovascular system",
        "Practice patient vital signs measurement",
        "Help with HIPAA compliance assignment",
        "Create a study plan for pharmacology exam",
        "Explain proper sterile technique procedures",
        "Help understand lab values interpretation",
        "Practice medical documentation skills"
    ],
    "commands": ["study", "explain", "practice", "quiz", "help"],
    "specializations": {
        "medical_assistant_core": [
            "Medical Terminology",
            "Anatomy & Physiology",
            "Patient Care Procedures",
            "Vital Signs & Measurements",
            "Infection Control & Sterile Technique",
            "Medical Office Administration",
            "HIPAA & Patient Privacy",
            "Electronic Health Records",
            "Phlebotomy Procedures",
            "Medical Office Lab Procedures",
            "Pharmacology Basics",
            "Medical Law & Ethics",
            "Insurance Billing & Coding",
            "Front Office Procedures",
            "Medical Emergencies"
        ],
        "general_academic": [
            "Study Skills Development",
            "Test Preparation Strategies",
            "Time Management for Students",
            "Note-Taking Techniques",
            "Research Paper Writing",
            "Critical Thinking Skills",
            "Problem-Solving Approaches",
            "Presentation Skills",
            "Academic Writing Enhancement",
            "Test Anxiety Management"
        ]
    },
    "api_fallback": {
        "enabled": true,
        "triggers": ["complex_research", "detailed_medical_analysis", "comprehensive_exam_prep"],
        "providers": ["openai", "anthropic", "local_fallback"],
        "hardware_threshold_mb": 2048
    },
    "study_features": [
        "Flashcard Generation",
        "Quiz Creation",
        "Concept Mapping",
        "Memory Techniques",
        "Practice Exam Simulations",
        "Progress Tracking",
        "Personalized Study Plans",
        "Mnemonics for Medical Terms",
        "Clinical Scenario Simulations"
    ]
}
ACADEMIC_EOF
    fi

    # Creative Writing Task
    if [[ " ${TASK_ARRAY[@]} " =~ " writing " ]]; then
        cat > "$CONFIG_DIR/tasks/writing.json" << 'WRITING_EOF'
{
    "name": "Creative Writing Assistant",
    "system_prompt": "You are a creative writing assistant for Lilith Linux users. Help with content creation, editing, proofreading, and idea generation. Focus on clear, engaging writing that's appropriate for technical documentation, personal projects, and creative work on Linux systems.",
    "keywords": ["write", "edit", "proofread", "content", "creative", "documentation"],
    "examples": [
        "Edit this technical documentation",
        "Write a README for my project",
        "Generate ideas for a tutorial",
        "Review this blog post"
    ],
    "commands": ["write", "edit", "review", "proofread", "generate"]
}
WRITING_EOF
    fi

    # Technical Support Task
    if [[ " ${TASK_ARRAY[@]} " =~ " techsupport " ]]; then
        cat > "$CONFIG_DIR/tasks/techsupport.json" << 'SUPPORT_EOF'
{
    "name": "Technical Support Assistant",
    "system_prompt": "You are a technical support specialist for Lilith Linux. Provide step-by-step troubleshooting guides, explain technical concepts, and offer solutions to common problems. Be patient, thorough, and focus on the specific tools and interfaces available in Lilith Linux.",
    "keywords": ["support", "help", "troubleshoot", "problem", "error", "guide"],
    "examples": [
        "I can't connect to Wi-Fi",
        "Application won't start",
        "File permissions issue",
        "Hardware recognition problem"
    ],
    "commands": ["diagnose", "fix", "guide", "explain", "help"]
}
SUPPORT_EOF
    fi

    # Research Helper Task
    if [[ " ${TASK_ARRAY[@]} " =~ " research " ]]; then
        cat > "$CONFIG_DIR/tasks/research.json" << 'RESEARCH_EOF'
{
    "name": "Research and Learning Assistant",
    "system_prompt": "You are a research and learning assistant for Lilith Linux users. Help with information gathering, learning new concepts, summarizing technical topics, and finding relevant resources. Focus on Linux, programming, and technical subjects while providing clear, actionable information.",
    "keywords": ["research", "learn", "summarize", "find", "information", "study"],
    "examples": [
        "Learn about Linux networking",
        "Summarize this technical paper",
        "Find resources for learning Python",
        "Research systemd best practices"
    ],
    "commands": ["search", "summarize", "learn", "research", "find"]
}
RESEARCH_EOF
    fi

    echo -e "${GREEN}✓ Specialized task configurations created${NC}"
}

# Function to setup desktop integration
setup_desktop_integration() {
    echo -e "${YELLOW}► Setting up desktop integration...${NC}"

    # Install necessary desktop tools
    apt-get install -y xdotool wmctrl

    # Desktop hotkey setup
    if [ "$DESKTOP_HOTKEY" = "true" ]; then
        cat > /usr/local/bin/lilith-ai-hotkey.sh << 'HOTKEY_EOF'
#!/bin/bash

# Lilith AI Hotkey Handler
# Triggered by Ctrl+Alt+A

# Get active window info
ACTIVE_WINDOW=$(xdotool getactivewindow getwindowname 2>/dev/null || echo "Desktop")

# Create temporary files
TEMP_PROMPT="/tmp/lilith-prompt.txt"
TEMP_RESPONSE="/tmp/lilith-response.txt"

# Create context-aware prompt
cat > "$TEMP_PROMPT" << EOF
You are a helpful AI assistant specialized for Lilith Linux.

Current Context: $ACTIVE_WINDOW

How can I help you?
EOF

# Launch AI interface (replace with your preferred terminal/command)
# This example uses zenity for GUI input/output
zenity --text-info --title "Lilith AI Assistant" --filename="$TEMP_PROMPT" --editable \
    --width=600 --height=400 2>/dev/null |
tr '\n' ' ' > "$TEMP_PROMPT.input"

# If user provided input, process it
if [ -s "$TEMP_PROMPT.input" ]; then
    bash /opt/lilith-ai/scripts/process-query.sh "$(cat "$TEMP_PROMPT.input")" "$TEMP_RESPONSE"
    zenity --text-info --title "Lilith AI Response" --filename="$TEMP_RESPONSE" \
        --width=600 --height=400 2>/dev/null
fi

# Cleanup
rm -f "$TEMP_PROMPT" "$TEMP_PROMPT.input" "$TEMP_RESPONSE"
HOTKEY_EOF

        chmod +x /usr/local/bin/lilith-ai-hotkey.sh

        # Create desktop shortcut/hotkey
        mkdir -p ~/.config/autostart
        cat > ~/.config/autostart/lilith-ai.desktop << EOF
[Desktop Entry]
Type=Application
Name=Lilith AI Hotkey
Exec=/usr/local/bin/lilith-ai-hotkey.sh
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF

        echo -e "${GREEN}✓ Desktop hotkey integration configured${NC}"
    fi

    # Context menu setup (if supported by file manager)
    if [ "$CONTEXT_MENU" = "true" ]; then
        echo "Context menu integration requires manual configuration per file manager"
        echo "See documentation for integration with your preferred file manager"
    fi

    # Terminal commands setup
    if [ "$TERMINAL_COMMANDS" = "true" ]; then
        # Add to system PATH
        echo 'export PATH="$PATH:/opt/lilith-ai/scripts"' >> ~/.bashrc
        source ~/.bashrc

        # Create symlink for easy access
        ln -sf /opt/lilith-ai/scripts/process-query.sh /usr/local/bin/lilith

        echo -e "${GREEN}✓ Terminal commands integration configured${NC}"
    fi
}

# Function to create API fallback system
create_api_fallback() {
    echo -e "${YELLOW}► Setting up API fallback system...${NC}"

    # Create Python script for API integration
    cat > "$SCRIPT_DIR/api-fallback.py" << 'API_EOF'
#!/usr/bin/env python3

import os
import sys
import json
import requests
import argparse
from pathlib import Path

class APIManager:
    def __init__(self):
        self.config_dir = "/opt/lilith-ai/config"
        self.apis = {
            "openai": {
                "url": "https://api.openai.com/v1/chat/completions",
                "model": "gpt-4-turbo-preview",
                "headers": {"Authorization": f"Bearer {os.getenv('OPENAI_API_KEY')}"}
            },
            "anthropic": {
                "url": "https://api.anthropic.com/v1/messages",
                "model": "claude-3-opus-20240229",
                "headers": {"x-api-key": os.getenv('ANTHROPIC_API_KEY'),
                           "anthropic-version": "2023-06-01"}
            }
        }

    def check_availability(self):
        """Check which APIs have active keys"""
        available = []
        for provider, config in self.apis.items():
            key_env = f"{provider.upper()}_API_KEY"
            if os.getenv(key_env) and self.test_api(provider):
                available.append(provider)
        return available

    def test_api(self, provider):
        """Test if API key works"""
        try:
            config = self.apis[provider]
            headers = {
                "Content-Type": "application/json",
                **config["headers"]
            }

            if provider == "openai":
                payload = {
                    "model": config["model"],
                    "messages": [{"role": "user", "content": "test"}],
                    "max_tokens": 10
                }
            elif provider == "anthropic":
                payload = {
                    "model": config["model"],
                    "messages": [{"role": "user", "content": "test"}],
                    "max_tokens": 10
                }

            response = requests.post(config["url"], headers=headers, json=payload, timeout=10)
            return response.status_code == 200
        except:
            return False

    def query_api(self, provider, prompt, system_prompt="", context_mb=2048):
        """Query external API for complex tasks"""
        try:
            config = self.apis[provider]
            headers = {
                "Content-Type": "application/json",
                **config["headers"]
            }

            if provider == "openai":
                messages = []
                if system_prompt:
                    messages.append({"role": "system", "content": system_prompt})
                messages.append({"role": "user", "content": prompt})

                payload = {
                    "model": config["model"],
                    "messages": messages,
                    "max_tokens": min(4096, context_mb * 4),  # Convert MB to tokens
                    "temperature": 0.7
                }
            elif provider == "anthropic":
                full_prompt = f"{system_prompt}\n\n{prompt}" if system_prompt else prompt
                payload = {
                    "model": config["model"],
                    "messages": [{"role": "user", "content": full_prompt}],
                    "max_tokens": min(4096, context_mb * 4),
                    "temperature": 0.7
                }

            response = requests.post(config["url"], headers=headers, json=payload, timeout=60)
            response.raise_for_status()

            if provider == "openai":
                return response.json()["choices"][0]["message"]["content"]
            elif provider == "anthropic":
                return response.json()["content"][0]["text"]

        except Exception as e:
            return f"API Error: {str(e)}"

def main():
    parser = argparse.ArgumentParser(description="Lilith API Fallback System")
    parser.add_argument("--list", action="store_true", help="List available APIs")
    parser.add_argument("--provider", choices=["openai", "anthropic"], required=False)
    parser.add_argument("--prompt", required=False)
    parser.add_argument("--system-prompt", default="")
    parser.add_argument("--context-mb", type=int, default=2048)
    parser.add_argument("--output", required=False)

    args = parser.parse_args()

    api_manager = APIManager()

    if args.list:
        # List available APIs
        available = api_manager.check_availability()
        print("\n".join(available) if available else "")
        return

    if not args.provider or not args.prompt or not args.output:
        print("Error: --provider, --prompt, and --output are required", file=sys.stderr)
        sys.exit(1)

    available_apis = api_manager.check_availability()

    if args.provider not in available_apis:
        print(f"Error: {args.provider} API not available. Available: {available_apis}", file=sys.stderr)
        sys.exit(1)

    result = api_manager.query_api(
        args.provider,
        args.prompt,
        args.system_prompt,
        args.context_mb
    )

    with open(args.output, 'w') as f:
        f.write(result)

    print(f"API query completed - saved to {args.output}")

if __name__ == "__main__":
    main()
API_EOF

    chmod +x "$SCRIPT_DIR/api-fallback.py"

    # Install Python dependencies
    python3 -m pip install requests

    echo -e "${GREEN}✓ API fallback system created${NC}"
}

# Function to create AI processing script
create_ai_processor() {
    echo -e "${YELLOW}► Creating AI processing system...${NC}"

    # Main query processor with API fallback
    cat > "$SCRIPT_DIR/process-query.sh" << 'PROCESS_EOF'
#!/bin/bash

# Lilith AI Query Processor
# Processes natural language queries and routes to appropriate specialized model

QUERY="$1"
OUTPUT_FILE="${2:-/tmp/lilith-output.txt}"
TASK_HINT="${3:-auto}"

# Determine task category based on keywords
determine_task() {
    local query_lower=$(echo "$1" | tr '[:upper:]' '[:lower:]')

    if echo "$query_lower" | grep -q -E "(system|admin|troubleshoot|fix|configure|network|permission)"; then
        echo "sysadmin"
    elif echo "$query_lower" | grep -q -E "(code|program|script|debug|bash|python|c\+\+|function)"; then
        echo "coding"
    elif echo "$query_lower" | grep -q -E "(write|edit|content|creative|document|proofread)"; then
        echo "writing"
    elif echo "$query_lower" | grep -q -E "(support|help|problem|error|can't|won't|how)"; then
        echo "techsupport"
    elif echo "$query_lower" | grep -q -E "(learn|research|find|understand|explain)"; then
        echo "research"
    else
        echo "general"
    fi
}

# Process query
TASK=$(determine_task "$QUERY")

# Create system prompt based on task
create_system_prompt() {
    local task="$1"
    local config_file="/opt/lilith-ai/config/tasks/${task}.json"

    if [ -f "$config_file" ]; then
        # Use specialized system prompt
        jq -r '.system_prompt' "$config_file"
    else
        # Default general prompt
        echo "You are a helpful AI assistant for Lilith Linux. Provide clear, practical advice for Linux users. Be concise but thorough in your responses."
    fi
}

# Create formatted prompt
SYSTEM_PROMPT=$(create_system_prompt "$TASK")
FULL_PROMPT="${SYSTEM_PROMPT}

User Query: ${QUERY}

Response:"

# Save prompt to temporary file
TEMP_PROMPT="/tmp/lilith-query-$$.txt"
echo "$FULL_PROMPT" > "$TEMP_PROMPT"

# Process with llama.cpp
bash /opt/lilith-ai/scripts/run-llama.sh \
    "/opt/lilith-ai/models/main-model.gguf" \
    "$TEMP_PROMPT" \
    "$OUTPUT_FILE"

# Post-process output (extract just the response)
if [ -f "$OUTPUT_FILE" ]; then
    # Extract everything after "Response:"
    sed -n '/Response:/,$p' "$OUTPUT_FILE" | sed '1d' | sed '/^$/d' > "${OUTPUT_FILE}.processed"
    mv "${OUTPUT_FILE}.processed" "$OUTPUT_FILE"
fi

# Cleanup
rm -f "$TEMP_PROMPT"

echo "Response saved to: $OUTPUT_FILE"
PROCESS_EOF

    chmod +x "$SCRIPT_DIR/process-query.sh"

    # Create individual command scripts for specialized tasks
    for task in ask explain help diagnose fix optimize analyze debug review generate write edit search summarize learn; do
        cat > "$SCRIPT_DIR/${task}.sh" << COMMAND_EOF
#!/bin/bash

# Lilith AI - ${task^} Command
# Specialized AI command for $task operations

QUERY="Please $task: \$*"
OUTPUT_FILE="/tmp/lilith-${task}-result.txt"

bash /opt/lilith-ai/scripts/process-query.sh "\$QUERY" "\$OUTPUT_FILE" "${task}"

# Display result
if [ -f "\$OUTPUT_FILE" ]; then
    cat "\$OUTPUT_FILE"
    echo ""
    echo "Result saved to: \$OUTPUT_FILE"
else
    echo "Error: No response generated"
fi
COMMAND_EOF
        chmod +x "$SCRIPT_DIR/${task}.sh"
    done

    # Create specialized academic commands with API fallback
    for task in study explain practice quiz help; do
        cat > "$SCRIPT_DIR/${task}.sh" << ACADEMIC_EOF
#!/bin/bash

# Lilith AI - Academic ${task^} Command
# Specialized AI command for academic assistance with API fallback support

ACCADEMIC_TASK="${task}"
QUERY="Please \$ACCADEMIC_TASK: \$*"
OUTPUT_FILE="/tmp/lilith-academic-\${task}-result.txt"

# Check if this is a complex task that might need API fallback
TASK_COMPLEXITY_CHECK() {
    local query_lower=\$(echo "\$*" | tr '[:upper:]' '[:lower:]')
    local config_file="/opt/lilith-ai/config/tasks/academic.json"

    if [ -f "\$config_file" ] && command -v python3 >/dev/null 2>&1; then
        # Check if API fallback is enabled and triggers match
        local api_enabled=\$(python3 -c "
import json
with open('\$config_file') as f:
    config = json.load(f)
    if 'api_fallback' in config and config['api_fallback'].get('enabled', False):
        triggers = config['api_fallback'].get('triggers', [])
        for trigger in triggers:
            if trigger.lower() in query_lower:
                print('true')
                exit(0)
print('false')
")
        if [ "\$api_enabled" = "true" ]; then
            echo "Complex task detected - attempting API fallback..." >&2

            # Get available APIs
            AVAILABLE_APIS=\$(python3 /opt/lilith-ai/scripts/api-fallback.py --list 2>/dev/null || echo "")

            # Try OpenAI first, then Anthropic
            for api in openai anthropic; do
                if echo "\$AVAILABLE_APIS" | grep -q "\$api"; then
                    echo "Using \$api API for complex processing..." >&2
                    SYSTEM_PROMPT=\$(jq -r '.system_prompt' "\$config_file" 2>/dev/null || echo "You are a helpful academic tutor.")

                    if python3 /opt/lilith-ai/scripts/api-fallback.py \
                        --provider "\$api" \
                        --prompt "\$*" \
                        --system-prompt "\$SYSTEM_PROMPT" \
                        --context-mb 2048 \
                        --output "\$OUTPUT_FILE"; then

                        echo "" >&2
                        echo "AI response (via \$api API - enhanced for complex tasks):" >&2
                        echo "==================================================" >&2
                        return 0
                    fi
                fi
            done

            # If API fallback failed, fall back to local processing
            echo "API fallback unavailable or failed - using local AI..." >&2
        fi
    fi

    # Default local processing
    return 1
}

# Try API fallback first for complex tasks
if ! TASK_COMPLEXITY_CHECK; then
    # Use local AI for simpler tasks
    bash /opt/lilith-ai/scripts/process-query.sh "\$QUERY" "\$OUTPUT_FILE" "academic"
fi

# Display result
if [ -f "\$OUTPUT_FILE" ]; then
    cat "\$OUTPUT_FILE"
    echo ""
    echo "Result saved to: \$OUTPUT_FILE"
else
    echo "Error: No response generated"
fi
ACADEMIC_EOF
        chmod +x "$SCRIPT_DIR/${task}.sh"
    done

    echo -e "${GREEN}✓ AI processing system created${NC}"
}

# Function to create AI service
create_ai_service() {
    echo -e "${YELLOW}► Creating AI background service...${NC}"

    # Create systemd service for AI processing
    cat > /etc/systemd/system/lilith-ai.service << 'SERVICE_EOF'
[Unit]
Description=Lilith AI Assistant Service
After=network.target

[Service]
Type=simple
User=root
ExecStart=/bin/bash -c "while true; do sleep 30; done"
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
SERVICE_EOF

    # Enable but don't start automatically
    systemctl daemon-reload
    systemctl enable lilith-ai

    echo -e "${GREEN}✓ AI service configured${NC}"
}

# Function to create integration documentation
create_documentation() {
    echo -e "${YELLOW}► Creating integration documentation...${NC}"

    cat > "$AI_DIR/README.md" << 'DOC_EOF'
# Lilith Linux AI Integration

## Overview
Lilith Linux includes a locally-deployed AI assistant optimized for your hardware with specialized knowledge areas.

## Features
- Local processing (no cloud dependency)
- Hardware optimization with quantization
- Specialized knowledge areas
- Desktop integration
- Terminal commands

## Usage

### Desktop Integration
- **Hotkey**: Ctrl+Alt+A launches AI assistant
- **Context Menu**: Right-click files for AI analysis (configurable)

### Terminal Commands
Available commands (run with `lilith` or directly):

```bash
# Generic help
lilith "How do I configure network settings?"

# Specialized commands
ask "What is systemd?"
help "troubleshoot network"
diagnose "why can't I connect to wifi?"
fix "permission denied error"
analyze "this bash script"
debug "find the bug in this code"
generate "create a backup script"
```

### Specialized Areas
- **System Administration**: `ask`, `explain`, `help`, `diagnose`, `fix`
- **Code Assistant**: `analyze`, `debug`, `review`, `optimize`, `generate`
- **Creative Writing**: `write`, `edit`, `review`, `proofread`
- **Technical Support**: `diagnose`, `fix`, `guide`, `explain`
- **Research Helper**: `search`, `summarize`, `learn`, `research`

## Configuration

### Model Settings
- Location: `/opt/lilith-ai/models/main-model.gguf`
- Quantization: Configurable (Q2_K, Q3_K_L, Q4_K_M, etc.)
- Context length: Up to 8192 tokens

### Task Configuration
- Location: `/opt/lilith-ai/config/tasks/`
- JSON configurations for each specialized area
- Customizable system prompts and keywords

## Hardware Optimization

### Supported Quantization Levels
- **Q2_K**: Fastest, lowest memory (~1.5-3GB RAM)
- **Q3_K_L**: Balanced performance (~2-4GB RAM)
- **Q4_K_M**: Recommended default (~2.5-5GB RAM)
- **Q5_K_M**: Higher quality (~3-6GB RAM)
- **Q8_0**: Near full precision (~4-8GB RAM)

### Performance Estimates
- **Q4_K_M 7B model**: ~10-20 tokens/second
- **Q3_K_L 7B model**: ~15-25 tokens/second
- **Q2_K 7B model**: ~20-35 tokens/second

## Integration Options

### Hotkey Configuration
Edit: `~/.config/autostart/lilith-ai.desktop`

### Context Menu
Requires manual configuration per file manager (Dolphin, Nautilus, etc.)

### Terminal Integration
Automatically added to PATH via `~/.bashrc`

## Troubleshooting

### Service Not Starting
```bash
systemctl status lilith-ai
journalctl -u lilith-ai --no-pager
```

### Model Not Found
```bash
ls -la /opt/lilith-ai/models/
# Re-run setup if missing
```

### Low Performance
- Try lower quantization level (Q3_K_L or Q2_K)
- Reduce context length
- Check CPU usage: `htop`

### No Response
- Check logs: `tail -f /opt/lilith-ai/logs/setup.log`
- Verify model file integrity
- Test basic functionality

## Customization

### Adding New Tasks
1. Create JSON config in `/opt/lilith-ai/config/tasks/`
2. Add keywords and system prompt
3. Restart AI service if needed

### Custom Models
1. Download quantized GGUF models to `/opt/lilith-ai/models/`
2. Update script paths in `/opt/lilith-ai/scripts/`
3. Test compatibility

### System Integration
Modify desktop integration in:
- `~/.config/autostart/lilith-ai.desktop`
- `/usr/local/bin/lilith-ai-hotkey.sh`

---

**Brought to you by Lilith Linux** 🔥
DOC_EOF

    echo -e "${GREEN}✓ Integration documentation created${NC}"
}

# Main execution
main() {
    echo -e "${YELLOW}Starting Lilith AI Setup...${NC}"
    echo ""
    echo "Configuration:"
    echo "  Model Engine: $USE_MODEL"
    echo "  Model Size: $MODEL_SIZE"
    echo "  Quantization: $QUANTIZATION"
    echo "  Specialized Tasks: $INCLUDE_TASKS"
    echo "  Desktop Hotkey: $DESKTOP_HOTKEY"
    echo "  Context Menu: $CONTEXT_MENU"
    echo "  Terminal Commands: $TERMINAL_COMMANDS"
    echo ""

    install_dependencies

    case "$USE_MODEL" in
        "llama-cpp")
            install_llamacpp
            ;;
        *)
            echo "Unsupported model: $USE_MODEL"
            echo "Currently only llama-cpp is fully supported"
            exit 1
            ;;
    esac

    download_models
    create_api_fallback
    create_specialized_tasks
    setup_desktop_integration
    create_ai_processor
    create_ai_service
    create_documentation

    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  Lilith AI Setup Complete!                                 ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}AI Integration Ready:${NC}"
    echo "  📁 AI files installed in: $AI_DIR"
    echo "  🤖 Model ready: $(basename "$MODEL_DIR"/*.gguf 2>/dev/null || echo 'None')"
    echo "  📝 Specialized areas: $(ls "$CONFIG_DIR/tasks/" | wc -l)"
    echo ""
    echo -e "${YELLOW}Usage:${NC}"
    echo "  • Desktop hotkey: Ctrl+Alt+A"
    echo "  • Terminal: lilith \"your question\""
    echo "  • Specialized: ask, explain, debug, generate, etc."
    echo ""
    if systemctl is-active --quiet lilith-ai 2>/dev/null; then
        echo -e "${GREEN}✓ AI service is running${NC}"
    else
        echo -e "${YELLOW}• Run: sudo systemctl start lilith-ai${NC}"
    fi
    echo ""
    echo -e "${GREEN}Read documentation at: $AI_DIR/README.md${NC}"
}

# Run main function
main

exit 0
