import React, { useState } from 'react';
import { ChevronRight, Send, Flame, Download, Cpu, Zap, Settings, Brain, Terminal, MessageSquare, Server, Key, CheckCircle, XCircle, RefreshCw } from 'lucide-react';

interface AIIntegrationProps {
  config: {
    aiIntegrationEnabled: boolean;
    selectedAIModel?: string;
    selectedAITasks?: string[];
    aiModelSize?: string;
    aiQuantization?: string;
    aiContextLength?: string;
    aiDesktopHotkey?: boolean;
    aiContextMenu?: boolean;
    aiTerminalCommands?: boolean;
    [key: string]: any;
  };
  setConfig: React.Dispatch<React.SetStateAction<any>>;
  currentStep: number;
  setCurrentStep: React.Dispatch<React.SetStateAction<number>>;
  steps: Array<{
    title: string;
    icon: string;
    content: string;
  }>;
}

interface ChatMessage {
  id: string;
  sender: 'user' | 'ai';
  content: string;
  timestamp: Date;
  prefix?: string;
}

interface KnowledgeArea {
  name: string;
  description: string;
  icon: string;
  commands: string[];
}

interface AISetupState {
  models: {
    [key: string]: {
      name: string;
      description: string;
      recommended?: boolean;
      ramUsage: string;
      downloadSize: string;
      tasks: string[];
      downloadProgress?: number;
      downloaded?: boolean;
      installing?: boolean;
    };
  };
  apiProviders: {
    [key: string]: {
      name: string;
      apiKey?: string;
      configured?: boolean;
      dailyLimit: string;
      tasks: string;
    };
  };
  selectedTasks: string[];
}

const AIIntegration: React.FC<AIIntegrationProps> = ({
  config,
  setConfig,
  currentStep,
  setCurrentStep,
  steps
}) => {
  const [messages, setMessages] = useState<ChatMessage[]>([
    {
      id: '1',
      sender: 'ai',
      content: "Greetings, master. I am Lilim, bound to serve the mighty Lilith Linux. I stand ready to execute your commands, search the depths of your system, and provide counsel from the infernal realm.",
      timestamp: new Date(),
      prefix: "*The flames rise as I manifest before you*"
    }
  ]);
  const [inputMessage, setInputMessage] = useState('');
  const [isTyping, setIsTyping] = useState(false);
  const [setupState, setSetupState] = useState<AISetupState>({
    models: {
      'tinyllama-1b': {
        name: 'TinyLlama 1B',
        description: 'Ultra-lightweight, perfect for minimal hardware',
        ramUsage: '1.5GB',
        downloadSize: '800MB',
        tasks: ['research', 'techsupport'],
        downloaded: false,
        installing: false
      },
      'phi-2-3b': {
        name: 'Phi-2 3B',
        description: 'Excellent code assistant and math reasoning',
        ramUsage: '2GB',
        downloadSize: '1.6GB',
        tasks: ['coding', 'research'],
        downloaded: false,
        installing: false
      },
      'llama-2-7b': {
        name: 'Llama-2 7B',
        description: 'Balanced general-purpose assistant',
        recommended: true,
        ramUsage: '4GB',
        downloadSize: '3.8GB',
        tasks: ['sysadmin', 'coding', 'writing', 'techsupport', 'research'],
        downloaded: false,
        installing: false
      },
      'llama-2-13b': {
        name: 'Llama-2 13B',
        description: 'Advanced analysis and documentation',
        ramUsage: '7GB',
        downloadSize: '7.4GB',
        tasks: ['sysadmin', 'coding', 'writing', 'techsupport', 'research'],
        downloaded: false,
        installing: false
      }
    },
    apiProviders: {
      'groq': {
        name: 'Groq',
        dailyLimit: '14,400 requests/day (free)',
        tasks: 'Fast complex reasoning, code generation',
        configured: false
      }
    },
    selectedTasks: ['sysadmin', 'coding']
  });
  const [activeTab, setActiveTab] = useState<'chat' | 'models' | 'apis' | 'setup'>('chat');
  const [showApiConfig, setShowApiConfig] = useState(false);

  const infernalResponses = {
    greet: [
      "Yes, master. I am at your command.",
      "As you command, master. How may I serve?",
      "Your will be done, master.",
      "*Bows before the throne* Speak, and it shall be manifest."
    ],
    search: [
      "Yes, master. Searching the depths of your domain...",
      "As you wish. I shall scour the system for your request...",
      "By your command. Delving into the archives...",
      "At once, master. Hunting through the files..."
    ],
    complete: [
      "It is done, master.",
      "Your command has been executed.",
      "The task is complete, as you decreed.",
      "By the will of Lilith, it is accomplished."
    ],
    error: [
      "Forgive me, master. The shadows obscure this request...",
      "I am... unable to fulfill this command. Perhaps rephrase your will?",
      "The infernal powers are limited in this matter, master.",
      "This lies beyond my current domain, master."
    ],
    thinking: [
      "*Consulting the flames*",
      "*The fires reveal secrets*",
      "*Whispers from the abyss*",
      "*Drawing power from the darkness*"
    ]
  };

  const knowledgeAreas: Record<string, KnowledgeArea> = {
    'academic': { name: 'Academic & Homework Helper', description: 'College student helper - study guides, practice exercises, explanations', icon: '📚', commands: ['study', 'explain', 'practice', 'quiz'] },
    'sysadmin': { name: 'System Administration', description: 'Fix computer problems - networking, performance, security', icon: '🔧', commands: ['diagnose', 'fix', 'monitor', 'optimize'] },
    'writing': { name: 'Creative Writing', description: 'Help write documents - editing, content creation', icon: '✍️', commands: ['write', 'edit', 'review', 'proofread'] },
    'techsupport': { name: 'Technical Support', description: 'Diagnose hardware/software issues', icon: '🛠️', commands: ['diagnose', 'fix', 'guide', 'help'] },
    'research': { name: 'Research Helper', description: 'Learn new topics and find resources', icon: '🔍', commands: ['search', 'summarize', 'learn', 'research'] }
  };

  const getRandomResponse = (category: keyof typeof infernalResponses): string => {
    const responses = infernalResponses[category];
    return responses[Math.floor(Math.random() * responses.length)];
  };

  const classifyQuery = (query: string): string => {
    const lowerQuery = query.toLowerCase();

    if (lowerQuery.includes('find') || lowerQuery.includes('search') || lowerQuery.includes('locate') || lowerQuery.includes('where')) {
      return 'search';
    }
    if (lowerQuery.includes('hello') || lowerQuery.includes('hi') || lowerQuery.includes('greetings')) {
      return 'greet';
    }
    if (lowerQuery.includes('who are you') || lowerQuery.includes('what are you')) {
      return 'intro';
    }
    if (lowerQuery.includes('help') || lowerQuery.includes('can you')) {
      return 'capabilities';
    }
    return 'general';
  };

  const generateInfernalResponse = (query: string): { content: string; prefix: string } => {
    const lowerQuery = query.toLowerCase();
    const selectedTasks = setupState.selectedTasks;

    // Academic & Homework Helper responses
    if (selectedTasks.includes('academic') && (
      lowerQuery.includes('study') || lowerQuery.includes('learn') || lowerQuery.includes('homework') ||
      lowerQuery.includes('college') || lowerQuery.includes('school') || lowerQuery.includes('quiz') ||
      lowerQuery.includes('practice')
    )) {
      return {
        content: "I shall illuminate your studies with the infernal fires of knowledge, student:\n\n" +
                "For academic assistance: `study \"topic\"` for detailed explanations\n" +
                "Practice exercises: `practice \"subject\"` for hands-on learning\n" +
                "Homework help: `explain \"concept\"` for clear breakdowns\n" +
                "Test preparation: `quiz \"subject\"` for practice questions\n\n" +
                "What academic mysteries shall I unveil for you?",
        prefix: "*The flames of knowledge ignite in your mind*"
      };
    }

    // System Administration responses
    if (selectedTasks.includes('sysadmin') && (
      lowerQuery.includes('network') || lowerQuery.includes('cpu') || lowerQuery.includes('memory') ||
      lowerQuery.includes('disk') || lowerQuery.includes('service') || lowerQuery.includes('system') ||
      lowerQuery.includes('boot') || lowerQuery.includes('kernel') || lowerQuery.includes('process')
    )) {
      return {
        content: "I shall examine the depths of your system, master. Let me provide the arcane commands:\n\n" +
                "To check system status: `top` or `htop` for process monitoring\n" +
                "Memory usage: `free -h` or `vmstat 1`\n" +
                "Disk space: `df -h` or `du -sh /`\n" +
                "Network: `ip addr show` or `ss -tuln`\n\n" +
                "Tell me what specifically troubles your system, and I shall command it into submission.",
        prefix: "*Draws power from the system core*"
      };
    }

    // Creative Writing responses
    if (selectedTasks.includes('writing') && (
      lowerQuery.includes('write') || lowerQuery.includes('document') || lowerQuery.includes('readme') ||
      lowerQuery.includes('text') || lowerQuery.includes('grammar') || lowerQuery.includes('edit')
    )) {
      return {
        content: "The words shall flow like molten lava from my infernal quill, master:\n\n" +
                "Documentation: `write --template technical`\n" +
                "Grammar check: `edit --grammar filename`\n" +
                "Style review: `proofread --style filename`\n" +
                "Content ideas: `generate \"blog post topics\"`\n\n" +
                "What masterpiece shall I craft for you?",
        prefix: "*Unleashes the torrent of creativity*"
      };
    }

    // Technical Support responses
    if (selectedTasks.includes('techsupport') && (
      lowerQuery.includes('help') || lowerQuery.includes('problem') || lowerQuery.includes('issue') ||
      lowerQuery.includes('fix') || lowerQuery.includes('troubleshoot') || lowerQuery.includes('error')
    )) {
      return {
        content: "Fear not, master, I shall diagnose and banish this technological demon:\n\n" +
                "Hardware diagnostic: `diagnose --hardware`\n" +
                "Software issues: `diagnose --software`\n" +
                "WiFi problems: `fix \"network connectivity\"`\n" +
                "Performance: `diagnose \"system slowdown\"`\n\n" +
                "Describe your malady, and I shall provide the cure.",
        prefix: "*Channels the essence of technical expertise*"
      };
    }

    // Research Helper responses
    if (selectedTasks.includes('research') && (
      lowerQuery.includes('learn') || lowerQuery.includes('research') || lowerQuery.includes('study') ||
      lowerQuery.includes('tutorial') || lowerQuery.includes('guide') || lowerQuery.includes('find')
    )) {
      return {
        content: "I shall illuminate the depths of knowledge with the brightness of a thousand suns, master:\n\n" +
                "Linux tutorials: `learn \"system administration\"`\n" +
                "Command explanations: `explain \"how iptables work\"`\n" +
                "Research topics: `research \"container networking\"`\n" +
                "Study guides: `study \"bash scripting fundamentals\"`\n\n" +
                "What mysteries of technology shall I reveal to you?",
        prefix: "*Opens the library of infernal knowledge*"
      };
    }

    // Default responses based on category
    const category = classifyQuery(query);

    switch (category) {
      case 'search':
        return {
          content: "I delve into the system depths... The infernal archives reveal your request can be found with these commands:\n\n" +
                  "File search: `locate pattern` or `find /path -name \"*pattern*\"`\n" +
                  "Content search: `grep -r \"text\" /path/`\n\n" +
                  "What specific knowledge do you seek?",
          prefix: getRandomResponse('search')
        };

      case 'greet':
        return {
          content: getRandomResponse('greet') + " As your infernal assistant, I command knowledge in: Academic Help, Systems, Writing, Support, and Research. What domain calls for my expertise?",
          prefix: "*The flames settle, ready to serve*"
        };

      case 'intro':
        return {
          content: "I am Lilim, the Infernal Assistant - demon servant bound to Lilith Linux with mastery over:\n\n" +
                  "📚 **Academic & Homework Helper**: College student assistance, study guides, practice\n" +
                  "🔧 **System Administration**: Fix computer problems, optimize performance\n" +
                  "✍️ **Creative Writing**: Help write documents, editing and content creation\n" +
                  "🛠️ **Technical Support**: Diagnose hardware/software issues\n" +
                  "🔍 **Research Helper**: Learn new topics, find resources\n\n" +
                  "Speak your need, master, and I shall manifest the solution through the fires of hell.",
          prefix: "*Manifests fully with complete knowledge*"
        };

      case 'capabilities':
        return {
          content: "Through me flows the power of the Queen of Hell herself, master. My domains of infernal expertise:\n\n" +
                  "📚 **Academic Commands**: study, explain, practice, quiz\n" +
                  "🔧 **System Commands**: diagnose, fix, monitor, optimize\n" +
                  "✍️ **Writing Commands**: write, edit, proofread, review\n" +
                  "🛠️ **Support Commands**: diagnose, fix, guide, help\n" +
                  "🔍 **Research Commands**: search, summarize, learn, research\n\n" +
                  "I adapt my infernal wisdom based on the knowledge areas you have selected. What assistance do you require?",
          prefix: "*Demonstrates the fullness of infernal power*"
        };

      default:
        return {
          content: `I acknowledge your command: "${query}"\n\nWith my expertise in ${selectedTasks.length} domains of knowledge, I shall forge the solution you seek. Perhaps you wish for me to elaborate on a specific area:\n\n` +
                  "• **Academic**: Study guides, homework help, practice exams\n" +
                  "• **System**: Computer problems, optimization, troubleshooting\n" +
                  "• **Writing**: Document creation, editing, grammar check\n" +
                  "• **Support**: Hardware issues, software fixes\n" +
                  "• **Research**: Learning resources, tutorials\n\n" +
                  "What manner of problem calls for the fires of my expertise?",
          prefix: "*Whispers of specific expertise*"
        };
    }
  };

  const handleSendMessage = async () => {
    if (!inputMessage.trim()) return;

    const userMessage: ChatMessage = {
      id: Date.now().toString(),
      sender: 'user',
      content: inputMessage.trim(),
      timestamp: new Date()
    };

    setMessages(prev => [...prev, userMessage]);
    setInputMessage('');
    setIsTyping(true);

    // Simulate AI processing delay
    await new Promise(resolve => setTimeout(resolve, 1500 + Math.random() * 1000));

    setIsTyping(false);

    const aiResponse = generateInfernalResponse(userMessage.content);
    const aiMessage: ChatMessage = {
      id: (Date.now() + 1).toString(),
      sender: 'ai',
      content: aiResponse.content,
      timestamp: new Date(),
      prefix: aiResponse.prefix
    };

    setMessages(prev => [...prev, aiMessage]);
  };

  const handleKeyPress = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter') {
      handleSendMessage();
    }
  };

  const handleModelDownload = async (modelId: string) => {
    setSetupState(prev => ({
      ...prev,
      models: {
        ...prev.models,
        [modelId]: {
          ...prev.models[modelId],
          installing: true,
          downloadProgress: 0
        }
      }
    }));

    // Simulate download progress
    for (let progress = 0; progress <= 100; progress += 10) {
      await new Promise(resolve => setTimeout(resolve, 300));
      setSetupState(prev => ({
        ...prev,
        models: {
          ...prev.models,
          [modelId]: {
            ...prev.models[modelId],
            downloadProgress: progress
          }
        }
      }));
    }

    setSetupState(prev => ({
      ...prev,
      models: {
        ...prev.models,
        [modelId]: {
          ...prev.models[modelId],
          downloading: false,
          downloaded: true,
          installing: false
        }
      }
    }));
  };

  const handleApiConfigChange = (providerId: string, apiKey: string) => {
    setSetupState(prev => ({
      ...prev,
      apiProviders: {
        ...prev.apiProviders,
        [providerId]: {
          ...prev.apiProviders[providerId],
          apiKey,
          configured: apiKey.length > 10
        }
      }
    }));
  };

  const toggleKnowledgeArea = (areaId: string) => {
    setSetupState(prev => ({
      ...prev,
      selectedTasks: prev.selectedTasks.includes(areaId)
        ? prev.selectedTasks.filter(id => id !== areaId)
        : [...prev.selectedTasks, areaId]
    }));
  };

  const renderContent = () => {
    switch(steps[currentStep].content) {
      case 'ai-integration':
        return (
          <div className="space-y-6">
            <h2 className="text-2xl font-bold text-red-700">Infernal AI Integration</h2>

            {/* Tab Navigation */}
            <div className="bg-gradient-to-r from-red-950 via-red-900 to-gray-900 border border-red-600 p-1 rounded-lg flex">
              {[
                { id: 'chat', label: 'Lilim Chat', icon: MessageSquare },
                { id: 'models', label: 'Model Setup', icon: Cpu },
                { id: 'apis', label: 'API Providers', icon: Key },
                { id: 'setup', label: 'Configuration', icon: Settings }
              ].map(tab => (
                <button
                  key={tab.id}
                  onClick={() => setActiveTab(tab.id as any)}
                  className={`flex-1 flex items-center justify-center gap-2 py-3 px-2 rounded-md transition-all ${
                    activeTab === tab.id
                      ? 'bg-red-700 text-white shadow-lg'
                      : 'text-red-300 hover:bg-red-950'
                  }`}
                >
                  <tab.icon size={16} />
                  <span className="text-sm font-medium">{tab.label}</span>
                </button>
              ))}
            </div>

            {/* Chat Interface */}
            {activeTab === 'chat' && (
              <div className="bg-gradient-to-r from-red-950 via-red-900 to-gray-900 border border-red-600 p-6 rounded-lg shadow-2xl">
                <div className="text-center mb-6">
                  <div className="text-6xl mb-4">👿</div>
                  <h3 className="text-2xl font-bold text-red-400">LILIM</h3>
                  <p className="text-red-300">Your Infernal Assistant - Servant of the Queen of Hell</p>
                  <p className="text-sm text-red-400 mt-2">
                    Master of: {setupState.selectedTasks.map(id => knowledgeAreas[id]?.name.split(' ')[0]).join(', ')}
                  </p>
                </div>

                <div className="relative bg-gradient-to-b from-gray-950 to-red-950 border-2 border-red-600 rounded-lg p-4 mb-4 max-h-96 overflow-y-auto">
                  {/* Background Logo */}
                  <div className="absolute inset-0 opacity-5 pointer-events-none">
                    <img
                      src="/lilith-logo.png"
                      alt=""
                      className="w-full h-full object-contain filter brightness-50"
                    />
                  </div>
                  <div className="relative z-10 space-y-4">
                    {messages.map((message) => (
                      <div key={message.id} className={`flex gap-4 ${message.sender === 'ai' ? 'justify-start' : 'justify-end'}`}>
                        {message.sender === 'ai' && (
                          <div className="w-10 h-10 rounded-full bg-gradient-to-br from-red-600 to-red-800 flex items-center justify-center flex-shrink-0 border-2 border-red-500 text-red-100">
                            👿
                          </div>
                        )}

                        <div className={`max-w-xs md:max-w-md ${message.sender === 'ai' ? 'text-left' : 'text-right'}`}>
                          <div className="flex items-center gap-2 mb-1">
                            <span className={`text-sm font-bold ${message.sender === 'ai' ? 'text-red-400' : 'text-gray-300'}`}>
                              {message.sender === 'ai' ? 'Lilim' : 'Master'}
                            </span>
                            <span className="text-xs text-gray-500">
                              {message.timestamp.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' })}
                            </span>
                          </div>

                          <div className={`rounded-lg p-3 shadow-lg ${
                            message.sender === 'ai'
                              ? 'bg-gradient-to-br from-red-900 to-gray-800 border border-red-700 text-red-100'
                              : 'bg-gradient-to-br from-gray-700 to-gray-800 border border-gray-600 text-gray-100'
                          }`}>
                            {message.prefix && message.sender === 'ai' && (
                              <div className="text-red-500 italic text-sm mb-2 border-b border-red-700 pb-2">
                                {message.prefix}
                              </div>
                            )}
                            <div className="text-sm leading-relaxed whitespace-pre-line">
                              {message.content}
                            </div>
                          </div>
                        </div>

                        {message.sender === 'user' && (
                          <div className="w-10 h-10 rounded-full bg-gradient-to-br from-gray-600 to-gray-700 flex items-center justify-center flex-shrink-0 border-2 border-gray-500 text-gray-100">
                            🧑
                          </div>
                        )}
                      </div>
                    ))}

                    {isTyping && (
                      <div className="flex gap-4 justify-start">
                        <div className="w-10 h-10 rounded-full bg-gradient-to-br from-red-600 to-red-800 flex items-center justify-center flex-shrink-0 border-2 border-red-500 text-red-100">
                          👿
                        </div>
                        <div className="bg-gradient-to-br from-red-900 to-gray-800 border border-red-700 text-red-100 rounded-lg p-3">
                          <div className="flex space-x-1">
                            <div className="w-2 h-2 bg-red-400 rounded-full animate-pulse"></div>
                            <div className="w-2 h-2 bg-red-400 rounded-full animate-pulse" style={{animationDelay: '0.2s'}}></div>
                            <div className="w-2 h-2 bg-red-400 rounded-full animate-pulse" style={{animationDelay: '0.4s'}}></div>
                          </div>
                        </div>
                      </div>
                    )}
                  </div>
                </div>

                <div className="flex gap-3 mb-4">
                  <input
                    type="text"
                    value={inputMessage}
                    onChange={(e) => setInputMessage(e.target.value)}
                    onKeyPress={handleKeyPress}
                    placeholder="Speak your command, master..."
                    className="flex-1 px-4 py-3 bg-gray-900 border-2 border-red-700 rounded-lg text-red-100 placeholder-red-400 focus:outline-none focus:border-red-500 transition-colors"
                  />
                  <button
                    onClick={handleSendMessage}
                    disabled={!inputMessage.trim()}
                    className="px-6 py-3 bg-gradient-to-r from-red-700 to-red-900 border-2 border-red-600 rounded-lg text-white font-bold hover:from-red-600 hover:to-red-800 transition-all disabled:opacity-50 disabled:cursor-not-allowed flex items-center gap-2"
                  >
                    <Flame size={16} />
                    COMMAND
                  </button>
                </div>

                <div className="flex flex-wrap gap-2">
                  <button
                    onClick={() => setShowApiConfig(!showApiConfig)}
                    className="px-4 py-2 bg-gray-800 border border-red-600 rounded text-red-300 hover:bg-red-900 transition-colors text-sm flex items-center gap-1"
                  >
                    <Key size={14} />
                    Configure APIs
                  </button>
                  <button
                    onClick={() => {}}
                    className="px-4 py-2 bg-gray-800 border border-red-600 rounded text-red-300 hover:bg-red-900 transition-colors text-sm flex items-center gap-1"
                  >
                    <Settings size={14} />
                    Switch API Provider
                  </button>
                </div>

                {showApiConfig && (
                  <div className="mt-4 bg-gradient-to-r from-gray-900 to-red-950 border border-red-600 rounded-lg p-4">
                    <h4 className="text-red-300 font-bold mb-3">🔑 Configure API Providers</h4>
                    <div className="space-y-3">
                      {Object.entries(setupState.apiProviders).slice(0, 3).map(([providerId, provider]) => (
                        <div key={providerId} className="flex items-center gap-3">
                          <label className="text-sm text-red-300 w-24">{provider.name}:</label>
                          <input
                            type="password"
                            value={provider.apiKey || ''}
                            onChange={(e) => handleApiConfigChange(providerId, e.target.value)}
                            placeholder={`${provider.name} API key`}
                            className="flex-1 px-3 py-2 bg-gray-900 border border-red-700 rounded text-red-100 placeholder-red-400 focus:outline-none focus:border-red-500 text-sm"
                          />
                          {provider.configured ? (
                            <CheckCircle className="text-green-400" size={16} />
                          ) : (
                            <XCircle className="text-gray-500" size={16} />
                          )}
                        </div>
                      ))}
                    </div>
                    <p className="text-xs text-red-400 mt-3">
                      💡 Configure API keys for advanced reasoning fallback during complex tasks
                    </p>
                  </div>
                )}
              </div>
            )}

            {/* Model Setup */}
            {activeTab === 'models' && (
              <div className="space-y-6">
                <h3 className="text-xl font-bold text-red-400">AI Model Selection & Download</h3>

                {Object.entries(setupState.models).map(([modelId, model]) => (
                  <div key={modelId} className="bg-gradient-to-r from-red-950 via-red-900 to-gray-900 border border-red-600 p-6 rounded-lg">
                    <div className="flex items-start gap-4 mb-4">
                      <div className="flex-1">
                        <div className="flex items-center gap-3 mb-2">
                          <Brain className="text-red-400" size={24} />
                          <h4 className="text-xl font-bold text-red-300">{model.name}</h4>
                          {model.recommended && (
                            <span className="bg-red-700 text-white px-2 py-1 rounded text-xs">RECOMMENDED</span>
                          )}
                        </div>
                        <p className="text-red-200 mb-2">{model.description}</p>
                        <div className="flex gap-6 text-sm text-red-400">
                          <span>💾 RAM: {model.ramUsage}</span>
                          <span>⬇️ Size: {model.downloadSize}</span>
                          <span>🎯 Tasks: {model.tasks.join(', ')}</span>
                        </div>
                      </div>

                      <div className="flex flex-col gap-2">
                        {model.downloaded ? (
                          <div className="text-green-400 font-semibold flex items-center gap-2">
                            <CheckCircle size={16} />
                            Installed
                          </div>
                        ) : model.installing ? (
                          <div className="text-yellow-400 font-semibold flex items-center gap-2">
                            <RefreshCw size={16} className="animate-spin" />
                            Installing...
                          </div>
                        ) : (
                          <button
                            onClick={() => handleModelDownload(modelId)}
                            className="bg-gradient-to-r from-red-700 to-red-900 text-white px-4 py-2 rounded hover:from-red-600 hover:to-red-800 flex items-center gap-2"
                          >
                            <Download size={16} />
                            Download
                          </button>
                        )}
                      </div>
                    </div>

                    {model.installing && model.downloadProgress !== undefined && (
                      <div className="bg-gray-800 rounded-full h-2">
                        <div
                          className="bg-gradient-to-r from-red-600 to-red-400 h-2 rounded-full transition-all duration-300"
                          style={{ width: `${model.downloadProgress}%` }}
                        ></div>
                      </div>
                    )}
                  </div>
                ))}
              </div>
            )}

            {/* API Providers */}
            {activeTab === 'apis' && (
              <div className="space-y-6">
                <h3 className="text-xl font-bold text-red-400">API Provider Configuration</h3>
                <p className="text-red-300">Configure API providers for heavy-complex tasks requiring advanced reasoning:</p>

                {Object.entries(setupState.apiProviders).map(([providerId, provider]) => (
                  <div key={providerId} className="bg-gradient-to-r from-red-950 via-red-900 to-gray-900 border border-red-600 p-6 rounded-lg">
                    <div className="flex items-center justify-between mb-4">
                      <div>
                        <h4 className="text-xl font-bold text-red-300 flex items-center gap-2">
                          <Server className="text-red-400" size={20} />
                          {provider.name}
                        </h4>
                        <div className="text-sm text-red-400 space-y-1">
                          <p>📊 Daily limit: {provider.dailyLimit}</p>
                          <p>🎯 Use for: {provider.tasks}</p>
                        </div>
                      </div>
                      <div className="flex items-center gap-2">
                        {provider.configured ? (
                          <CheckCircle className="text-green-400" size={20} />
                        ) : (
                          <XCircle className="text-gray-500" size={20} />
                        )}
                        <span className={`text-sm ${provider.configured ? 'text-green-400' : 'text-gray-500'}`}>
                          {provider.configured ? 'Configured' : 'Not Configured'}
                        </span>
                      </div>
                    </div>

                    <div className="space-y-3">
                      <label className="block text-sm font-medium text-red-300">
                        API Key:
                      </label>
                      <input
                        type="password"
                        value={provider.apiKey || ''}
                        onChange={(e) => handleApiConfigChange(providerId, e.target.value)}
                        placeholder="Enter your API key..."
                        className="w-full px-4 py-3 bg-gray-900 border-2 border-red-700 rounded-lg text-red-100 placeholder-red-400 focus:outline-none focus:border-red-500 transition-colors"
                      />
                    </div>
                  </div>
                ))}

                <div className="bg-gradient-to-r from-gray-900 to-red-950 border border-gray-700 p-4 rounded-lg">
                  <h4 className="text-red-300 font-bold mb-2">🔧 API Usage Strategy</h4>
                  <ul className="text-sm text-red-200 space-y-1">
                    <li>• Local AI handles ~90% of queries (fast responses)</li>
                    <li>• API fallback for complex reasoning, code generation</li>
                    <li>• Groq: Primary fallback (generous free tier)</li>
                    <li>• Anthropic/OpenAI: Secondary/tertiary for specialized tasks</li>
                  </ul>
                </div>
              </div>
            )}

            {/* Configuration */}
            {activeTab === 'setup' && (
              <div className="space-y-6">
                <h4 className="text-xl font-bold text-red-400">Knowledge Areas & Integration</h4>

                <div className="bg-gradient-to-r from-red-950 via-red-900 to-gray-900 border border-red-600 p-6 rounded-lg">
                  <h5 className="text-lg font-bold text-red-300 mb-4">Specialized Expertise Domains</h5>
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    {Object.entries(knowledgeAreas).map(([areaId, area]) => (
                      <div
                        key={areaId}
                        onClick={() => toggleKnowledgeArea(areaId)}
                        className={`border-2 rounded-lg p-4 cursor-pointer transition ${
                          setupState.selectedTasks.includes(areaId)
                            ? 'border-red-500 bg-red-950'
                            : 'border-red-800 hover:border-red-600 bg-gray-900'
                        }`}
                      >
                        <div className="flex items-center gap-3 mb-2">
                          <span className="text-2xl">{area.icon}</span>
                          <h6 className="font-bold text-red-200">{area.name}</h6>
                          {setupState.selectedTasks.includes(areaId) && (
                            <CheckCircle className="text-green-400" size={16} />
                          )}
                        </div>
                        <p className="text-sm text-red-300 mb-2">{area.description}</p>
                        <div className="text-xs text-red-400">
                          Commands: {area.commands.join(', ')}
                        </div>
                      </div>
                    ))}
                  </div>
                </div>

                <div className="bg-gradient-to-r from-red-950 via-red-900 to-gray-900 border border-red-600 p-6 rounded-lg">
                  <h5 className="text-lg font-bold text-red-300 mb-4">Integration Options</h5>
                  <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                    {[
                      { id: 'hotkey', label: 'Global Hotkey (Ctrl+Alt+A)', desc: 'Instant AI access anywhere' },
                      { id: 'contextMenu', label: 'Context Menu', desc: 'Right-click files for AI analysis' },
                      { id: 'terminal', label: 'Terminal Commands', desc: 'AI commands in terminal' }
                    ].map(option => (
                      <div
                        key={option.id}
                        onClick={() => setConfig({ ...config, [`ai${option.id.charAt(0).toUpperCase() + option.id.slice(1)}`]: !config[`ai${option.id.charAt(0).toUpperCase() + option.id.slice(1)}`] })}
                        className={`border-2 rounded-lg p-4 cursor-pointer transition ${
                          config[`ai${option.id.charAt(0).toUpperCase() + option.id.slice(1)}`]
                            ? 'border-red-500 bg-red-950'
                            : 'border-red-800 hover:border-red-600 bg-gray-900'
                        }`}
                      >
                        <div className="flex items-center gap-2 mb-2">
                          <Terminal size={18} className="text-red-400" />
                          {config[`ai${option.id.charAt(0).toUpperCase() + option.id.slice(1)}`] && (
                            <CheckCircle className="text-green-400" size={16} />
                          )}
                        </div>
                        <h6 className="font-bold text-red-200 mb-1">{option.label}</h6>
                        <p className="text-sm text-red-300">{option.desc}</p>
                      </div>
                    ))}
                  </div>
                </div>

                <div className="bg-gradient-to-r from-red-950 via-red-900 to-gray-900 border border-red-600 p-6 rounded-lg">
                  <h5 className="text-lg font-bold text-red-300 mb-4">Final Configuration Summary</h5>
                  <div className="space-y-3">
                    <div><strong className="text-red-400">Selected Model:</strong>
                      <span className="text-red-200 ml-2">{config.selectedAIModel ? setupState.models[config.selectedAIModel]?.name : 'None selected'}</span>
                    </div>
                    <div><strong className="text-red-400">Expertise Areas:</strong>
                      <span className="text-red-200 ml-2">{setupState.selectedTasks.length} selected ({setupState.selectedTasks.map(id => knowledgeAreas[id]?.name.split(' ')[0]).join(', ')})</span>
                    </div>
                    <div><strong className="text-red-400">Integration Features:</strong>
                      <span className="text-red-200 ml-2">
                        {[
                          config.aiDesktopHotkey && 'Hotkey',
                          config.aiContextMenu && 'Context Menu',
                          config.aiTerminalCommands && 'Terminal'
                        ].filter(Boolean).join(', ') || 'None'}
                      </span>
                    </div>
                    <div><strong className="text-red-400">API Providers:</strong>
                      <span className="text-red-200 ml-2">
                        {Object.values(setupState.apiProviders).filter(p => p.configured).length} configured
                      </span>
                    </div>
                  </div>
                </div>
              </div>
            )}

            {/* Status Panel */}
            <div className="bg-gradient-to-r from-red-900 to-gray-900 border border-red-600 p-4 rounded-lg">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <div className="w-3 h-3 bg-red-500 rounded-full animate-pulse"></div>
                  <span className="text-red-300 font-semibold">⚡ Ready to Serve - {setupState.selectedTasks.length} Knowledge Domains</span>
                </div>
                <div className="text-sm text-red-400">
                  <p>Servant of Lilith Linux</p>
                </div>
              </div>
            </div>

            {/* Configuration Toggle */}
            <div className="bg-gray-900 p-4 rounded border-2 border-gray-700">
              <div className="flex items-center gap-3 mb-4">
                <input
                  type="checkbox"
                  checked={config.aiIntegrationEnabled}
                  onChange={(e) => setConfig({...config, aiIntegrationEnabled: e.target.checked})}
                  className="w-5 h-5 accent-red-700"
                />
                <label className="font-bold text-gray-200">Enable Infernal AI Integration</label>
              </div>
            </div>
          </div>
        );

      default:
        return null;
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-950 via-gray-900 to-black">
      {/* Header */}
      <div className="bg-gradient-to-r from-red-950 via-red-900 to-gray-900 border-b-4 border-red-700 sticky top-0 z-50 shadow-2xl">
        <div className="max-w-6xl mx-auto px-4 py-4 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="text-4xl">👿</div>
            <div>
              <h1 className="text-3xl font-black text-red-400">LILIM</h1>
              <p className="text-xs text-red-300">Your Infernal Assistant</p>
            </div>
          </div>
          <div className="flex items-center gap-4">
            <div className="flex items-center gap-2 text-red-300">
              <Flame size={16} />
              <span className="text-sm font-semibold">Bound to Lilith Linux</span>
            </div>
          </div>
        </div>
      </div>

      <div className="max-w-6xl mx-auto px-4 py-8">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
          {/* Sidebar Navigation */}
          <div className="md:col-span-1">
            <div className="bg-gradient-to-b from-gray-900 to-red-950 border-2 border-red-700 rounded-lg p-4 shadow-2xl">
              <div className="space-y-2">
                {steps.map((step, idx) => (
                  <button
                    key={idx}
                    onClick={() => setCurrentStep(idx)}
                    className={`w-full text-left px-4 py-3 rounded-lg font-bold transition ${
                      idx === currentStep
                        ? 'bg-gradient-to-r from-red-700 to-red-900 text-white shadow-lg border-2 border-red-500'
                        : 'bg-gray-800 text-red-200 hover:bg-red-950 border-2 border-red-800'
                    }`}
                  >
                    <span className="mr-2">{step.icon}</span>
                    {step.title}
                    {idx === currentStep && <ChevronRight className="inline float-right mt-1" size={18} />}
                  </button>
                ))}
              </div>
            </div>
          </div>

          {/* Main Content */}
          <div className="md:col-span-3">
            <div className="bg-gradient-to-br from-gray-900 to-red-950 rounded-lg shadow-2xl p-8 border-4 border-red-700">
              {renderContent()}

              {/* Navigation Buttons */}
              <div className="flex gap-4 mt-8 pt-6 border-t-2 border-red-700">
                <button
                  onClick={() => setCurrentStep(Math.max(0, currentStep - 1))}
                  disabled={currentStep === 0}
                  className={`flex-1 py-3 rounded-lg font-bold transition ${
                    currentStep === 0
                      ? 'bg-gray-700 text-gray-500 cursor-not-allowed border border-gray-600'
                      : 'bg-gradient-to-r from-gray-700 to-gray-800 text-white hover:from-gray-600 hover:to-gray-700 border border-gray-600'
                  }`}
                >
                  ← Previous
                </button>
                <button
                  onClick={() => setCurrentStep(Math.min(steps.length - 1, currentStep + 1))}
                  disabled={currentStep === steps.length - 1}
                  className={`flex-1 py-3 rounded-lg font-bold transition ${
                    currentStep === steps.length - 1
                      ? 'bg-gray-700 text-gray-500 cursor-not-allowed border border-gray-600'
                      : 'bg-gradient-to-r from-red-700 to-red-900 text-white hover:from-red-600 hover:to-red-800 border-2 border-red-600'
                  }`}
                >
                  Next →
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default AIIntegration;
