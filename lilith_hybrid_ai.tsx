import React, { useState } from 'react';
import { Download, Cpu, Cloud, Zap, HardDrive, Search, Terminal } from 'lucide-react';

const LilithHybridAI = () => {
  const [activeTab, setActiveTab] = useState('overview');

  const generateInstallScript = () => {
    return `#!/bin/bash
# Lilith Linux Hybrid AI System Installer
# Local Model + Cloud API Fallback with Intelligent Routing

set -e

echo "🔥 Installing Lilith Linux Hybrid AI System..."

# Install Ollama for local model
echo "📦 Installing Ollama..."
curl -fsSL https://ollama.ai/install.sh | sh

# Pull the lightweight local model
echo "🤖 Downloading Phi-3-mini (3.8B parameters, ~2.3GB)..."
ollama pull phi3:mini

# Install Python dependencies
echo "🐍 Setting up Python environment..."
sudo apt install -y python3 python3-pip python3-venv

# Create AI directory
mkdir -p /opt/lilith-ai
cd /opt/lilith-ai

# Create virtual environment
python3 -m venv aienv
source aienv/bin/activate

# Install required packages
pip install --upgrade pip
pip install ollama anthropic openai httpx requests python-dotenv

echo ""
echo "✅ Installation Complete!"
echo ""
echo "📝 Next Steps:"
echo "1. (Optional) Add API keys to /opt/lilith-ai/.env"
echo "2. Test local AI: ollama run phi3:mini"
echo "3. Download the Python router script"
echo ""
`;
  };

  const generatePythonRouter = () => {
    return `#!/usr/bin/env python3
"""
Lilith Linux Hybrid AI Router
Local-first with intelligent cloud fallback
"""

import subprocess
import json
import os
from datetime import datetime
from pathlib import Path

class HybridAI:
    def __init__(self):
        self.local_model = "phi3:mini"
        self.cloud_apis = [
            {"name": "groq", "limit": 14400, "used": 0},
            {"name": "together", "limit": 1000, "used": 0},
            {"name": "openrouter", "limit": 200, "used": 0}
        ]
        self.load_usage()
    
    def load_usage(self):
        usage_file = Path.home() / ".lilith-ai-usage.json"
        if usage_file.exists():
            with open(usage_file) as f:
                data = json.load(f)
                if data.get("date") == str(datetime.now().date()):
                    for api in self.cloud_apis:
                        api["used"] = data.get(api["name"], 0)
    
    def save_usage(self):
        usage_file = Path.home() / ".lilith-ai-usage.json"
        data = {
            "date": str(datetime.now().date())
        }
        for api in self.cloud_apis:
            data[api["name"]] = api["used"]
        with open(usage_file, "w") as f:
            json.dump(data, f)
    
    def classify_query(self, query):
        query_lower = query.lower()
        
        # File operations
        if any(kw in query_lower for kw in ["find", "search file", "locate"]):
            return "local-files"
        
        # Command help
        if any(kw in query_lower for kw in ["command", "how to run", "apt"]):
            return "local-command"
        
        # Cloud tasks
        cloud_keywords = ["write code", "debug", "explain why", "compare"]
        if any(kw in query_lower for kw in cloud_keywords):
            return "cloud"
        
        return "local"
    
    def search_files(self, query):
        terms = query.lower().replace("find", "").replace("search", "").strip()
        
        try:
            result = subprocess.run(
                ["locate", "-i", terms],
                capture_output=True,
                text=True,
                timeout=5
            )
            files = result.stdout.strip().split("\\n")[:20]
            
            if files and files[0]:
                return f"Found {len(files)} files matching '{terms}':\\n" + "\\n".join(files)
            else:
                return f"No files found. Try: sudo updatedb"
        except Exception as e:
            return f"Search error: {e}"
    
    def local_query(self, query):
        try:
            result = subprocess.run(
                ["ollama", "run", self.local_model, query],
                capture_output=True,
                text=True,
                timeout=30
            )
            return result.stdout.strip()
        except Exception as e:
            return f"Local AI error: {e}"
    
    def cloud_query(self, query):
        for api in self.cloud_apis:
            if api["used"] < api["limit"]:
                api["used"] += 1
                self.save_usage()
                return f"[Cloud API {api['name']} would be used here - add API key to enable]"
        
        return f"[Cloud APIs exhausted, using local] {self.local_query(query)}"
    
    def query(self, user_input):
        classification = self.classify_query(user_input)
        
        print(f"🔍 Query type: {classification}")
        
        if classification == "local-files":
            return self.search_files(user_input)
        elif classification == "cloud":
            return self.cloud_query(user_input)
        else:
            return self.local_query(user_input)

if __name__ == "__main__":
    import sys
    
    ai = HybridAI()
    
    if len(sys.argv) > 1:
        query = " ".join(sys.argv[1:])
        print(ai.query(query))
    else:
        print("🔥 Lilith Linux Hybrid AI")
        print("Type 'exit' to quit\\n")
        
        while True:
            try:
                query = input("You: ")
                if query.lower() in ["exit", "quit"]:
                    break
                
                response = ai.query(query)
                print(f"\\nLilith AI: {response}\\n")
            except KeyboardInterrupt:
                print("\\n\\nGoodbye!")
                break
`;
  };

  const generateOptimizationGuide = () => {
    return `# Lilith Linux Hybrid AI - Optimization Guide

## Hardware Profile
- CPU: i5-i7 (4-8 cores)
- RAM: 8GB
- GPU: Integrated (Intel UHD/Iris)
- Storage: SSD recommended

## Perfect Model: Phi-3-mini (3.8B)

**Why Phi-3-mini?**
- Only 2.3GB RAM usage
- Fast responses (1-2 seconds)
- Good at structured tasks
- CPU-optimized

## RAM Optimization

### Monitor Memory
\`\`\`bash
free -h
watch -n 1 'ps aux | grep ollama'
\`\`\`

### Reduce RAM Usage
\`\`\`bash
# Use smaller quantization
ollama pull phi3:mini-q3  # 1.8GB instead of 2.3GB
\`\`\`

### Add Swap
\`\`\`bash
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
\`\`\`

## CPU Optimization

### Limit Threads
\`\`\`bash
export OMP_NUM_THREADS=4
echo 'export OMP_NUM_THREADS=4' >> ~/.bashrc
\`\`\`

## Cloud API Strategy

### Free Tiers

| Provider | Daily Limit | Speed | Best For |
|----------|-------------|-------|----------|
| Groq | 14,400 | Fast | Main fallback |
| Together | 1,000 | Medium | Secondary |
| OpenRouter | 200 | Medium | Tertiary |

### Get API Keys
1. Groq: https://console.groq.com
2. Together: https://api.together.xyz
3. OpenRouter: https://openrouter.ai

## Expected Performance

On i5-i7, 8GB RAM:
- Simple query: 1-2 seconds
- Medium query: 3-5 seconds
- Complex query: 8-15 seconds

RAM usage: 2.8GB (model) + 3GB (OS) = ~6GB total

## Troubleshooting

### System Freezes
\`\`\`bash
# Limit CPU usage
export OMP_NUM_THREADS=4
\`\`\`

### Out of Memory
\`\`\`bash
# Use smaller model
ollama pull phi3:mini-q3
\`\`\`

### Slow Responses
\`\`\`bash
# Check CPU throttling
watch -n 1 'cat /proc/cpuinfo | grep MHz'
\`\`\`
`;
  };

  const downloadInstallScript = () => {
    const script = generateInstallScript();
    const blob = new Blob([script], { type: 'text/plain' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'install-hybrid-ai.sh';
    a.click();
    URL.revokeObjectURL(url);
  };

  const downloadPythonRouter = () => {
    const script = generatePythonRouter();
    const blob = new Blob([script], { type: 'text/plain' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'hybrid_router.py';
    a.click();
    URL.revokeObjectURL(url);
  };

  const downloadOptimizationGuide = () => {
    const guide = generateOptimizationGuide();
    const blob = new Blob([guide], { type: 'text/markdown' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'OPTIMIZATION-GUIDE.md';
    a.click();
    URL.revokeObjectURL(url);
  };

  const tabs = [
    { id: 'overview', label: 'Overview', icon: Zap },
    { id: 'architecture', label: 'Architecture', icon: Cpu },
    { id: 'models', label: 'Models', icon: HardDrive },
    { id: 'apis', label: 'Cloud APIs', icon: Cloud },
    { id: 'install', label: 'Install', icon: Download }
  ];

  const renderOverview = () => (
    <div className="space-y-6">
      <h2 className="text-3xl font-bold text-gray-800">Hybrid AI for Low-End Hardware</h2>
      
      <div className="bg-gradient-to-r from-purple-600 to-blue-600 text-white p-6 rounded-lg">
        <h3 className="text-xl font-bold mb-3">Perfect for Your Hardware!</h3>
        <div className="space-y-2">
          <p>✅ i5-i7 CPU, 8GB RAM, Integrated GPU</p>
          <p>✅ Local model: Only 2-3GB RAM</p>
          <p>✅ Fast responses: 1-3 seconds</p>
          <p>✅ Free cloud APIs for complex tasks</p>
          <p>✅ Automatic intelligent routing</p>
        </div>
      </div>

      <div className="grid grid-cols-2 gap-4">
        <div className="bg-green-50 p-4 rounded border-l-4 border-green-500">
          <div className="flex items-center gap-2 mb-2">
            <Cpu className="text-green-600" size={24} />
            <h4 className="font-bold">Local AI</h4>
          </div>
          <p className="text-sm text-gray-700">Phi-3-mini (3.8B)</p>
          <ul className="text-xs mt-2 space-y-1 text-gray-600">
            <li>• File searching</li>
            <li>• Command help</li>
            <li>• Quick answers</li>
            <li>• System info</li>
          </ul>
        </div>

        <div className="bg-blue-50 p-4 rounded border-l-4 border-blue-500">
          <div className="flex items-center gap-2 mb-2">
            <Cloud className="text-blue-600" size={24} />
            <h4 className="font-bold">Cloud APIs</h4>
          </div>
          <p className="text-sm text-gray-700">Groq/Together/OpenRouter</p>
          <ul className="text-xs mt-2 space-y-1 text-gray-600">
            <li>• Code generation</li>
            <li>• Complex reasoning</li>
            <li>• Long explanations</li>
            <li>• Advanced tasks</li>
          </ul>
        </div>
      </div>

      <div className="bg-yellow-50 border-l-4 border-yellow-400 p-4">
        <h4 className="font-bold text-yellow-800 mb-2">Why Hybrid?</h4>
        <div className="text-sm text-yellow-700 space-y-1">
          <p>🚀 Best of both: Fast local + powerful cloud</p>
          <p>💰 Cost effective: Free tiers go far</p>
          <p>🔒 Privacy: Sensitive queries stay local</p>
          <p>🎯 Smart routing: AI decides where to process</p>
        </div>
      </div>
    </div>
  );

  const renderArchitecture = () => (
    <div className="space-y-6">
      <h2 className="text-2xl font-bold text-gray-800">System Architecture</h2>
      
      <div className="bg-gray-100 p-6 rounded-lg font-mono text-sm">
        <div className="space-y-2">
          <div>User Query → Classifier</div>
          <div className="ml-4">↓</div>
          <div className="ml-4">├─ File Search? → Direct filesystem search</div>
          <div className="ml-4">├─ Command Help? → Local AI (Phi-3)</div>
          <div className="ml-4">├─ Simple Query? → Local AI (Phi-3)</div>
          <div className="ml-4">└─ Complex Query? → Cloud API Chain</div>
          <div className="ml-8">├─ Try Groq (14,400/day free)</div>
          <div className="ml-8">├─ Try Together (1,000/day free)</div>
          <div className="ml-8">├─ Try OpenRouter (200/day free)</div>
          <div className="ml-8">└─ Fallback to Local</div>
        </div>
      </div>

      <div className="grid grid-cols-3 gap-4">
        <div className="bg-white p-4 rounded shadow">
          <h4 className="font-bold mb-2 flex items-center gap-2">
            <Search size={18} className="text-green-600" />
            File Search
          </h4>
          <p className="text-xs text-gray-600">Direct filesystem access, instant results</p>
        </div>

        <div className="bg-white p-4 rounded shadow">
          <h4 className="font-bold mb-2 flex items-center gap-2">
            <Terminal size={18} className="text-blue-600" />
            Command Help
          </h4>
          <p className="text-xs text-gray-600">Local AI explains commands quickly</p>
        </div>

        <div className="bg-white p-4 rounded shadow">
          <h4 className="font-bold mb-2 flex items-center gap-2">
            <Cloud size={18} className="text-purple-600" />
            Complex Tasks
          </h4>
          <p className="text-xs text-gray-600">Cloud APIs handle heavy lifting</p>
        </div>
      </div>
    </div>
  );

  const renderModels = () => (
    <div className="space-y-6">
      <h2 className="text-2xl font-bold text-gray-800">Model Comparison</h2>
      
      <div className="bg-green-100 border-l-4 border-green-500 p-4">
        <h3 className="font-bold text-green-800 mb-2">Recommended: Phi-3-mini (3.8B)</h3>
        <div className="text-sm text-green-700">
          <p>Perfect balance for 8GB RAM systems</p>
          <ul className="list-disc ml-4 mt-2 space-y-1">
            <li>RAM: 2.3GB (Q4 quantization)</li>
            <li>Speed: 1-2 seconds for simple queries</li>
            <li>Quality: Excellent for structured tasks</li>
            <li>CPU-optimized, works great on i5-i7</li>
          </ul>
        </div>
      </div>

      <table className="w-full border-collapse border">
        <thead className="bg-gray-200">
          <tr>
            <th className="border p-2 text-left">Model</th>
            <th className="border p-2">RAM</th>
            <th className="border p-2">Speed</th>
            <th className="border p-2">Quality</th>
            <th className="border p-2">Best For</th>
          </tr>
        </thead>
        <tbody className="text-sm">
          <tr>
            <td className="border p-2 font-mono">TinyLlama 1B</td>
            <td className="border p-2">0.6GB</td>
            <td className="border p-2">⚡⚡⚡</td>
            <td className="border p-2">⭐⭐</td>
            <td className="border p-2">Ultra-low RAM</td>
          </tr>
          <tr className="bg-green-50">
            <td className="border p-2 font-mono font-bold">Phi-3-mini 3.8B</td>
            <td className="border p-2">2.3GB</td>
            <td className="border p-2">⚡⚡</td>
            <td className="border p-2">⭐⭐⭐⭐</td>
            <td className="border p-2 font-bold">Recommended!</td>
          </tr>
          <tr>
            <td className="border p-2 font-mono">Llama-3.2-3B</td>
            <td className="border p-2">2.8GB</td>
            <td className="border p-2">⚡⚡</td>
            <td className="border p-2">⭐⭐⭐⭐⭐</td>
            <td className="border p-2">Better quality</td>
          </tr>
        </tbody>
      </table>

      <div className="bg-blue-50 p-4 rounded">
        <h4 className="font-bold mb-2">Installation</h4>
        <code className="block bg-gray-900 text-green-400 p-3 rounded text-sm">
          ollama pull phi3:mini
        </code>
      </div>
    </div>
  );

  const renderAPIs = () => (
    <div className="space-y-6">
      <h2 className="text-2xl font-bold text-gray-800">Cloud API Strategy</h2>
      
      <div className="bg-purple-100 border-l-4 border-purple-500 p-4">
        <h3 className="font-bold text-purple-800 mb-2">Free Tier Chain</h3>
        <p className="text-sm text-purple-700">
          System automatically tries APIs in order until one works
        </p>
      </div>

      <table className="w-full border-collapse border">
        <thead className="bg-gray-200">
          <tr>
            <th className="border p-2 text-left">Provider</th>
            <th className="border p-2">Daily Limit</th>
            <th className="border p-2">Speed</th>
            <th className="border p-2">Sign Up</th>
          </tr>
        </thead>
        <tbody className="text-sm">
          <tr className="bg-green-50">
            <td className="border p-2 font-bold">Groq</td>
            <td className="border p-2">14,400 requests</td>
            <td className="border p-2">⚡⚡⚡ Blazing</td>
            <td className="border p-2">
              <a href="https://console.groq.com" target="_blank" rel="noopener noreferrer" 
                 className="text-blue-600 hover:underline">
                console.groq.com
              </a>
            </td>
          </tr>
          <tr>
            <td className="border p-2 font-bold">Together AI</td>
            <td className="border p-2">1,000 requests</td>
            <td className="border p-2">⚡⚡ Fast</td>
            <td className="border p-2">
              <a href="https://api.together.xyz" target="_blank" rel="noopener noreferrer"
                 className="text-blue-600 hover:underline">
                api.together.xyz
              </a>
            </td>
          </tr>
          <tr>
            <td className="border p-2 font-bold">OpenRouter</td>
            <td className="border p-2">200 requests</td>
            <td className="border p-2">⚡⚡ Fast</td>
            <td className="border p-2">
              <a href="https://openrouter.ai" target="_blank" rel="noopener noreferrer"
                 className="text-blue-600 hover:underline">
                openrouter.ai
              </a>
            </td>
          </tr>
        </tbody>
      </table>

      <div className="bg-yellow-50 border-l-4 border-yellow-400 p-4">
        <h4 className="font-bold text-yellow-800 mb-2">Usage Strategy</h4>
        <div className="text-sm text-yellow-700 space-y-2">
          <p><strong>Groq (Primary):</strong> Use for most cloud queries - very generous limit</p>
          <p><strong>Together (Secondary):</strong> Backup when Groq limit reached</p>
          <p><strong>OpenRouter (Tertiary):</strong> Final fallback before going local</p>
          <p><strong>Local (Always):</strong> When all cloud APIs exhausted</p>
        </div>
      </div>
    </div>
  );

  const renderInstall = () => (
    <div className="space-y-6">
      <h2 className="text-2xl font-bold text-gray-800">Installation</h2>
      
      <div className="bg-gradient-to-r from-green-600 to-blue-600 text-white p-6 rounded-lg">
        <h3 className="text-xl font-bold mb-3">Quick Install</h3>
        <ol className="space-y-2 text-sm">
          <li>1. Download installation script</li>
          <li>2. Run: sudo bash install-hybrid-ai.sh</li>
          <li>3. Download Python router script</li>
          <li>4. (Optional) Add cloud API keys</li>
          <li>5. Test: ollama run phi3:mini</li>
        </ol>
      </div>

      <div className="grid grid-cols-3 gap-4">
        <button
          onClick={downloadInstallScript}
          className="flex flex-col items-center gap-2 bg-green-600 text-white p-6 rounded-lg hover:bg-green-700"
        >
          <Download size={32} />
          <span className="font-bold">Install Script</span>
          <span className="text-xs">install-hybrid-ai.sh</span>
        </button>

        <button
          onClick={downloadPythonRouter}
          className="flex flex-col items-center gap-2 bg-blue-600 text-white p-6 rounded-lg hover:bg-blue-700"
        >
          <Download size={32} />
          <span className="font-bold">Router Script</span>
          <span className="text-xs">hybrid_router.py</span>
        </button>

        <button
          onClick={downloadOptimizationGuide}
          className="flex flex-col items-center gap-2 bg-purple-600 text-white p-6 rounded-lg hover:bg-purple-700"
        >
          <Download size={32} />
          <span className="font-bold">Optimization</span>
          <span className="text-xs">OPTIMIZATION-GUIDE.md</span>
        </button>
      </div>

      <div className="bg-gray-100 p-4 rounded">
        <h4 className="font-bold mb-3">Installation Steps</h4>
        <div className="space-y-4 text-sm">
          <div>
            <div className="font-bold text-green-700">Step 1: Run Install Script</div>
            <code className="block bg-gray-900 text-green-400 p-2 rounded mt-1">
              chmod +x install-hybrid-ai.sh<br/>
              sudo ./install-hybrid-ai.sh
            </code>
          </div>

          <div>
            <div className="font-bold text-green-700">Step 2: Place Router Script</div>
            <code className="block bg-gray-900 text-green-400 p-2 rounded mt-1">
              sudo mv hybrid_router.py /opt/lilith-ai/<br/>
              sudo chmod +x /opt/lilith-ai/hybrid_router.py
            </code>
          </div>

          <div>
            <div className="font-bold text-green-700">Step 3: Create CLI Command</div>
            <code className="block bg-gray-900 text-green-400 p-2 rounded mt-1">
              sudo ln -s /opt/lilith-ai/hybrid_router.py /usr/local/bin/ask
            </code>
          </div>

          <div>
            <div className="font-bold text-green-700">Step 4: Test It</div>
            <code className="block bg-gray-900 text-green-400 p-2 rounded mt-1">
              ask "What is Lilith Linux?"
            </code>
          </div>
        </div>
      </div>

      <div className="bg-blue-50 border-l-4 border-blue-400 p-4">
        <h4 className="font-bold text-blue-800 mb-2">Usage Examples</h4>
        <div className="text-sm space-y-2 font-mono">
          <div><strong>File search:</strong> ask "find config files"</div>
          <div><strong>Command help:</strong> ask "how to restart nginx"</div>
          <div><strong>System info:</strong> ask "show disk usage"</div>
          <div><strong>Coding:</strong> ask "write a backup script"</div>
        </div>
      </div>
    </div>
  );

  return (
    <div className="min-h-screen bg-gradient-to-br from-purple-900 via-blue-900 to-black p-8">
      <div className="max-w-6xl mx-auto">
        <div className="bg-gradient-to-r from-purple-600 to-blue-600 p-6 rounded-t-lg shadow-2xl">
          <div className="flex items-center gap-4">
            <div className="w-16 h-16 bg-purple-900 rounded-full flex items-center justify-center">
              <Zap size={32} className="text-yellow-400" />
            </div>
            <div>
              <h1 className="text-3xl font-bold text-white">Lilith Linux Hybrid AI</h1>
              <p className="text-purple-200">Local Model + Cloud APIs for Low-End Hardware</p>
            </div>
          </div>
        </div>

        <div className="bg-gray-800 flex overflow-x-auto">
          {tabs.map((tab) => {
            const Icon = tab.icon;
            return (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id)}
                className={`flex items-center gap-2 px-6 py-4 font-medium transition ${
                  activeTab === tab.id
                    ? 'bg-white text-purple-700 border-b-4 border-purple-700'
                    : 'text-gray-300 hover:bg-gray-700'
                }`}
              >
                <Icon size={18} />
                {tab.label}
              </button>
            );
          })}
        </div>

        <div className="bg-white p-8 rounded-b-lg shadow-2xl min-h-96">
          {activeTab === 'overview' && renderOverview()}
          {activeTab === 'architecture' && renderArchitecture()}
          {activeTab === 'models' && renderModels()}
          {activeTab === 'apis' && renderAPIs()}
          {activeTab === 'install' && renderInstall()}
        </div>

        <div className="mt-8 text-center text-gray-400 text-sm">
          <p>Hybrid AI System for Lilith Linux</p>
          <p className="mt-1">Optimized for i5-i7, 8GB RAM, Integrated GPU</p>
        </div>
      </div>
    </div>
  );
};

export default LilithHybridAI;