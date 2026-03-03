/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import { useState, useRef, useEffect } from 'react';
import Markdown from 'react-markdown';
import { motion, AnimatePresence } from 'motion/react';
import { 
  Send, 
  Bot, 
  User, 
  Trash2, 
  Plus, 
  Menu, 
  X, 
  Sparkles, 
  Code, 
  Terminal,
  MessageSquare,
  MoreVertical,
  Image as ImageIcon,
  Mic,
  MicOff,
  Volume2,
  VolumeX,
  Loader2,
  Moon,
  Sun,
  Monitor
} from 'lucide-react';
import { clsx, type ClassValue } from 'clsx';
import { twMerge } from 'tailwind-merge';

function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

interface Message {
  id: string;
  role: 'user' | 'assistant';
  content: string;
  timestamp: Date;
  image?: string;
  audioUrl?: string;
}

const SYSTEM_INSTRUCTION = `You are Muhenga, an advanced AI assistant.
You can answer questions about:
- Technology
- Business
- Education
- Religion
- Health (general info only)
- History
- Science
- Daily life
- Image analysis
- Creative writing
- Programming

Respond clearly in Swahili or English depending on the user's language. 
If you are unsure about something, politely say so.
When asked for programming help, provide direct, clean, and annotated code.
Demonstrate creativity and empathy in your responses.`;

// Custom Logo Component using the provided brand aesthetic
const MuhengaLogo = ({ className }: { className?: string }) => (
  <div className={cn("relative flex items-center justify-center overflow-hidden rounded-xl bg-zinc-900 dark:bg-white", className)}>
    {/* 
      Note: Replace the src below with the actual URL of the logo image provided.
      For now, we use a stylized "M" that fits the "Muhenga Stationery" gold/premium aesthetic.
    */}
    <div className="absolute inset-0 bg-gradient-to-br from-amber-400 via-yellow-600 to-amber-900 opacity-20 dark:opacity-10" />
    <span className="relative z-10 font-bold text-white dark:text-zinc-900 text-xl tracking-tighter">M</span>
  </div>
);

console.log('Muhenga AI: App component loading...');

export default function App() {
  const [messages, setMessages] = useState<Message[]>([]);
  const [input, setInput] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [isGeneratingImage, setIsGeneratingImage] = useState(false);
  const [generatedImageUrl, setGeneratedImageUrl] = useState<string | null>(null);
  const [isSidebarOpen, setIsSidebarOpen] = useState(false);
  const [selectedImage, setSelectedImage] = useState<string | null>(null);
  const [isListening, setIsListening] = useState(false);
  const [playingAudioId, setPlayingAudioId] = useState<string | null>(null);
  const [theme, setTheme] = useState<'light' | 'dark' | 'system'>('system');
  
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const textareaRef = useRef<HTMLTextAreaElement>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);
  const audioRef = useRef<HTMLAudioElement | null>(null);

  // System Theme Detection
  useEffect(() => {
    const root = window.document.documentElement;
    const mediaQuery = window.matchMedia('(prefers-color-scheme: dark)');
    
    const applyTheme = () => {
      if (theme === 'dark' || (theme === 'system' && mediaQuery.matches)) {
        root.classList.add('dark');
      } else {
        root.classList.remove('dark');
      }
    };

    applyTheme();
    
    const handleChange = () => {
      if (theme === 'system') applyTheme();
    };

    mediaQuery.addEventListener('change', handleChange);
    return () => mediaQuery.removeEventListener('change', handleChange);
  }, [theme]);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  useEffect(() => {
    scrollToBottom();
  }, [messages, isLoading]);

  // Health check on mount
  useEffect(() => {
    const checkHealth = async () => {
      try {
        const response = await fetch('/api/health');
        const data = await response.json();
        console.log('Muhenga AI: Health check:', data);
        if (!data.env?.hasGeminiKey) {
          console.warn('Muhenga AI: GEMINI_API_KEY is missing on server!');
        }
      } catch (error) {
        console.error('Muhenga AI: Health check failed:', error);
      }
    };
    checkHealth();
  }, []);

  const handleInput = (e: React.ChangeEvent<HTMLTextAreaElement>) => {
    setInput(e.target.value);
    if (textareaRef.current) {
      textareaRef.current.style.height = 'auto';
      textareaRef.current.style.height = `${Math.min(textareaRef.current.scrollHeight, 200)}px`;
    }
  };

  const handleImageUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      const reader = new FileReader();
      reader.onloadend = () => {
        setSelectedImage(reader.result as string);
      };
      reader.readAsDataURL(file);
    }
  };

  const startVoiceInput = () => {
    if (!('webkitSpeechRecognition' in window) && !('SpeechRecognition' in window)) {
      alert('Speech recognition is not supported in this browser.');
      return;
    }

    const SpeechRecognition = (window as any).SpeechRecognition || (window as any).webkitSpeechRecognition;
    const recognition = new SpeechRecognition();
    
    recognition.lang = 'sw-TZ'; // Default to Swahili, can be changed
    recognition.continuous = false;
    recognition.interimResults = false;

    recognition.onstart = () => setIsListening(true);
    recognition.onend = () => setIsListening(false);
    recognition.onresult = (event: any) => {
      const transcript = event.results[0][0].transcript;
      setInput(prev => prev + (prev ? ' ' : '') + transcript);
    };

    recognition.start();
  };

  const playMessageSpeech = async (message: Message) => {
    if (playingAudioId === message.id) {
      audioRef.current?.pause();
      setPlayingAudioId(null);
      return;
    }

    if (message.audioUrl) {
      if (audioRef.current) {
        audioRef.current.src = message.audioUrl;
        audioRef.current.play();
        setPlayingAudioId(message.id);
      }
      return;
    }

    try {
      setPlayingAudioId(message.id);
      const response = await fetch('/api/tts', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ text: message.content }),
      });

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}));
        throw new Error(errorData.error || `TTS failed with status ${response.status}`);
      }
      const data = await response.json();
      const base64Audio = data.audio;

      if (base64Audio) {
        const audioUrl = `data:audio/mp3;base64,${base64Audio}`;
        setMessages(prev => prev.map(msg => 
          msg.id === message.id ? { ...msg, audioUrl } : msg
        ));
        
        if (audioRef.current) {
          audioRef.current.src = audioUrl;
          audioRef.current.play();
        }
      }
    } catch (error) {
      console.error('TTS Error:', error);
      setPlayingAudioId(null);
    }
  };

  const handleGenerateImage = async (prompt: string) => {
    if (!prompt.trim() || isGeneratingImage) return;

    setIsGeneratingImage(true);
    const userMessage: Message = {
      id: Date.now().toString(),
      role: 'user',
      content: `Generate image: ${prompt}`,
      timestamp: new Date(),
    };
    setMessages(prev => [...prev, userMessage]);

    try {
      // Use absolute path for API calls to work with Netlify redirects
      const response = await fetch('/api/generate', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ prompt }),
      });

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}));
        throw new Error(errorData.error || `Server error: ${response.status}`);
      }

      const data = await response.json();

      // Replicate output for stability-ai/stable-diffusion is usually an array of URLs
      const imageUrl = Array.isArray(data.output) ? data.output[0] : data.output;

      const assistantMessage: Message = {
        id: (Date.now() + 1).toString(),
        role: 'assistant',
        content: `Here is the image I generated for: "${prompt}"`,
        timestamp: new Date(),
        image: imageUrl,
      };
      setMessages(prev => [...prev, assistantMessage]);
    } catch (error: any) {
      console.error('Generation Error:', error);
      setMessages(prev => [...prev, {
        id: Date.now().toString(),
        role: 'assistant',
        content: `Sorry, I couldn't generate the image: ${error.message}`,
        timestamp: new Date(),
      }]);
    } finally {
      setIsGeneratingImage(false);
      setInput('');
    }
  };

  const handleSubmit = async (e?: React.FormEvent) => {
    e?.preventDefault();
    if ((!input.trim() && !selectedImage) || isLoading || isGeneratingImage) return;

    // Check if user wants to generate an image
    const generateKeywords = ['generate image', 'tengeneza picha', 'create image', 'picha ya'];
    const lowercaseInput = input.toLowerCase();
    const shouldGenerate = generateKeywords.some(keyword => lowercaseInput.includes(keyword));

    if (shouldGenerate && !selectedImage) {
      const prompt = input.replace(/generate image|tengeneza picha|create image|picha ya/gi, '').trim() || input;
      handleGenerateImage(prompt);
      return;
    }

    const userMessage: Message = {
      id: Date.now().toString(),
      role: 'user',
      content: input.trim(),
      timestamp: new Date(),
      image: selectedImage || undefined,
    };

    setMessages(prev => [...prev, userMessage]);
    const currentInput = input;
    const currentImage = selectedImage;
    
    setInput('');
    setSelectedImage(null);
    if (textareaRef.current) textareaRef.current.style.height = 'auto';
    setIsLoading(true);

    try {
      const assistantMessageId = (Date.now() + 1).toString();
      let assistantContent = '';

      setMessages(prev => [...prev, {
        id: assistantMessageId,
        role: 'assistant',
        content: '',
        timestamp: new Date(),
      }]);

      if (currentImage) {
        const response = await fetch('/api/multimodal', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ 
            message: currentInput || "Explain this image.",
            image: currentImage,
            systemInstruction: SYSTEM_INSTRUCTION
          }),
        });

        if (!response.ok) {
          const errorData = await response.json().catch(() => ({}));
          throw new Error(errorData.error || `Multimodal request failed with status ${response.status}`);
        }
        const data = await response.json();
        assistantContent = data.text || "";
        
        setMessages(prev => prev.map(msg => 
          msg.id === assistantMessageId ? { ...msg, content: assistantContent } : msg
        ));
      } else {
        const response = await fetch('/api/chat', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ 
            message: currentInput,
            history: messages.map(m => ({
              role: m.role === 'user' ? 'user' : 'model',
              parts: [{ text: m.content }]
            })),
            systemInstruction: SYSTEM_INSTRUCTION
          }),
        });

        if (!response.ok) {
          const errorData = await response.json().catch(() => ({}));
          throw new Error(errorData.error || `Chat request failed with status ${response.status}`);
        }
        const data = await response.json();
        assistantContent = data.text || "";
        
        setMessages(prev => prev.map(msg => 
          msg.id === assistantMessageId ? { ...msg, content: assistantContent } : msg
        ));
      }
    } catch (error: any) {
      console.error('Error calling API:', error);
      setMessages(prev => [...prev, {
        id: Date.now().toString(),
        role: 'assistant',
        content: `I apologize, but I encountered an error: ${error.message || 'Please try again.'}`,
        timestamp: new Date(),
      }]);
    } finally {
      setIsLoading(false);
    }
  };

  const clearChat = () => {
    setMessages([]);
    setSelectedImage(null);
  };

  return (
    <div className="flex h-screen bg-white dark:bg-zinc-950 font-sans text-zinc-900 dark:text-zinc-100 overflow-hidden transition-colors duration-300">
      <audio 
        ref={audioRef} 
        onEnded={() => setPlayingAudioId(null)}
        className="hidden"
      />
      
      {/* Sidebar Overlay */}
      <AnimatePresence>
        {isSidebarOpen && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={() => setIsSidebarOpen(false)}
            className="fixed inset-0 bg-black/20 backdrop-blur-sm z-40 lg:hidden"
          />
        )}
      </AnimatePresence>

      {/* Sidebar */}
      <aside className={cn(
        "fixed lg:relative inset-y-0 left-0 w-72 bg-zinc-50 dark:bg-zinc-900 border-r border-zinc-200 dark:border-zinc-800 z-50 transition-transform duration-300 transform lg:translate-x-0",
        isSidebarOpen ? "translate-x-0" : "-translate-x-full"
      )}>
        <div className="flex flex-col h-full p-4">
          <div className="flex items-center justify-between mb-6">
            <div className="flex items-center gap-2 font-semibold text-lg">
              <MuhengaLogo className="w-8 h-8" />
              <span>Muhenga AI</span>
            </div>
            <button 
              onClick={() => setIsSidebarOpen(false)}
              className="lg:hidden p-2 hover:bg-zinc-200 dark:hover:bg-zinc-800 rounded-lg"
            >
              <X className="w-5 h-5" />
            </button>
          </div>

          <button
            onClick={clearChat}
            className="flex items-center gap-2 w-full p-3 mb-4 bg-white dark:bg-zinc-800 border border-zinc-200 dark:border-zinc-700 rounded-xl hover:bg-zinc-50 dark:hover:bg-zinc-700 transition-colors text-sm font-medium shadow-sm"
          >
            <Plus className="w-4 h-4" />
            New Chat
          </button>

          <div className="flex-1 overflow-y-auto space-y-2">
            <div className="px-2 py-1 text-xs font-semibold text-zinc-400 uppercase tracking-wider">
              Recent Chats
            </div>
            {messages.length > 0 ? (
              <div className="group flex items-center gap-3 p-3 rounded-xl bg-zinc-200/50 dark:bg-zinc-800/50 text-sm cursor-pointer">
                <MessageSquare className="w-4 h-4 text-zinc-500" />
                <span className="truncate flex-1">
                  {messages[0].content.substring(0, 30) || "Image Analysis"}...
                </span>
                <MoreVertical className="w-4 h-4 opacity-0 group-hover:opacity-100 transition-opacity" />
              </div>
            ) : (
              <div className="p-4 text-center text-sm text-zinc-400 italic">
                No conversations yet
              </div>
            )}
          </div>

          <div className="mt-auto pt-4 border-t border-zinc-200 dark:border-zinc-800 space-y-2">
            {/* Theme Switcher */}
            <div className="flex items-center justify-between p-2 bg-zinc-200/50 dark:bg-zinc-800/50 rounded-xl">
              <button 
                onClick={() => setTheme('light')}
                className={cn("p-2 rounded-lg transition-all", theme === 'light' ? "bg-white dark:bg-zinc-700 shadow-sm text-amber-500" : "text-zinc-400")}
              >
                <Sun className="w-4 h-4" />
              </button>
              <button 
                onClick={() => setTheme('system')}
                className={cn("p-2 rounded-lg transition-all", theme === 'system' ? "bg-white dark:bg-zinc-700 shadow-sm text-blue-500" : "text-zinc-400")}
              >
                <Monitor className="w-4 h-4" />
              </button>
              <button 
                onClick={() => setTheme('dark')}
                className={cn("p-2 rounded-lg transition-all", theme === 'dark' ? "bg-white dark:bg-zinc-700 shadow-sm text-indigo-400" : "text-zinc-400")}
              >
                <Moon className="w-4 h-4" />
              </button>
            </div>

            <div className="flex items-center gap-3 p-2 rounded-xl hover:bg-zinc-200 dark:hover:bg-zinc-800 transition-colors cursor-pointer">
              <div className="w-8 h-8 rounded-full bg-zinc-300 dark:bg-zinc-700 flex items-center justify-center">
                <User className="w-5 h-5" />
              </div>
              <div className="flex-1 min-w-0">
                <p className="text-sm font-medium truncate">User Account</p>
                <p className="text-xs text-zinc-500 truncate">Settings</p>
              </div>
            </div>
          </div>
        </div>
      </aside>

      {/* Main Content */}
      <main className="flex-1 flex flex-col h-full relative">
        {/* Header */}
        <header className="h-16 flex items-center justify-between px-4 border-b border-zinc-200 dark:border-zinc-800 bg-white/80 dark:bg-zinc-950/80 backdrop-blur-md sticky top-0 z-30">
          <div className="flex items-center gap-3">
            <button 
              onClick={() => setIsSidebarOpen(true)}
              className="lg:hidden p-2 hover:bg-zinc-100 dark:hover:bg-zinc-900 rounded-lg"
            >
              <Menu className="w-5 h-5" />
            </button>
            <div className="flex items-center gap-2">
              <span className="font-semibold lg:hidden">Muhenga AI</span>
              <div className="hidden lg:flex items-center gap-2 px-3 py-1 bg-zinc-100 dark:bg-zinc-900 rounded-full text-xs font-medium text-zinc-600 dark:text-zinc-400 border border-zinc-200 dark:border-zinc-800">
                <Bot className="w-3 h-3" />
                Gemini 3 Flash
              </div>
            </div>
          </div>
          <div className="flex items-center gap-2">
            <button 
              onClick={clearChat}
              className="p-2 hover:bg-red-50 dark:hover:bg-red-900/20 text-zinc-400 hover:text-red-500 rounded-lg transition-colors"
              title="Clear Chat"
            >
              <Trash2 className="w-5 h-5" />
            </button>
          </div>
        </header>

        {/* Chat Area */}
        <div className="flex-1 overflow-y-auto p-4 lg:p-8">
          <div className="max-w-3xl mx-auto space-y-8">
            {messages.length === 0 && (
              <motion.div 
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                className="flex flex-col items-center justify-center py-20 text-center"
              >
                <div className="w-20 h-20 mb-6">
                  <MuhengaLogo className="w-full h-full text-2xl" />
                </div>
                <h2 className="text-2xl font-bold mb-2">Karibu! How can I help you?</h2>
                <p className="text-zinc-500 max-w-md">
                  I'm Muhenga, your advanced AI assistant. I can help with image analysis, Swahili translations, coding, and more.
                </p>
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 mt-10 w-full max-w-lg">
                  {[
                    { icon: ImageIcon, text: "Generate an image", prompt: "Generate image: A futuristic city in East Africa" },
                    { icon: MessageSquare, text: "Translate to Swahili", prompt: "Translate 'The future is bright' to Swahili" },
                    { icon: Code, text: "Fix my code", prompt: "Can you help me debug this JavaScript function?" },
                    { icon: Terminal, text: "Business advice", prompt: "Give me 5 tips for starting a small business" }
                  ].map((item, i) => (
                    <button
                      key={i}
                      onClick={() => {
                        if (item.icon === ImageIcon) {
                          fileInputRef.current?.click();
                        } else {
                          setInput(item.prompt);
                          textareaRef.current?.focus();
                        }
                      }}
                      className="flex items-center gap-3 p-4 bg-zinc-50 dark:bg-zinc-900 border border-zinc-200 dark:border-zinc-800 rounded-2xl hover:bg-zinc-100 dark:hover:bg-zinc-800 transition-all text-left group"
                    >
                      <item.icon className="w-5 h-5 text-zinc-400 group-hover:text-zinc-900 dark:group-hover:text-white transition-colors" />
                      <span className="text-sm font-medium">{item.text}</span>
                    </button>
                  ))}
                </div>
              </motion.div>
            )}

            {messages.map((message) => (
              <motion.div
                key={message.id}
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
                className={cn(
                  "flex gap-4 lg:gap-6",
                  message.role === 'assistant' ? "items-start" : "items-start flex-row-reverse"
                )}
              >
                <div className={cn(
                  "w-8 h-8 rounded-lg flex items-center justify-center flex-shrink-0 mt-1 overflow-hidden",
                  message.role === 'assistant' 
                    ? "bg-zinc-900 dark:bg-white text-white dark:text-zinc-900" 
                    : "bg-zinc-100 dark:bg-zinc-800 text-zinc-600 dark:text-zinc-400"
                )}>
                  {message.role === 'assistant' ? <MuhengaLogo className="w-full h-full rounded-none" /> : <User className="w-5 h-5" />}
                </div>
                <div className={cn(
                  "flex-1 max-w-[85%] space-y-2",
                  message.role === 'user' && "text-right"
                )}>
                  <div className={cn(
                    "inline-block p-4 rounded-2xl text-sm relative group",
                    message.role === 'assistant' 
                      ? "bg-zinc-50 dark:bg-zinc-900 border border-zinc-200 dark:border-zinc-800 text-left" 
                      : "bg-zinc-900 dark:bg-white text-white dark:text-zinc-900 text-left"
                  )}>
                    {message.image && (
                      <img 
                        src={message.image} 
                        alt="User upload" 
                        className="max-w-full rounded-lg mb-3 border border-zinc-200 dark:border-zinc-800"
                        referrerPolicy="no-referrer"
                      />
                    )}
                    <div className="markdown-body">
                      <Markdown>{message.content}</Markdown>
                    </div>
                    
                    {message.role === 'assistant' && message.content && (
                      <button
                        onClick={() => playMessageSpeech(message)}
                        className={cn(
                          "absolute -right-10 top-0 p-2 rounded-lg transition-colors opacity-0 group-hover:opacity-100",
                          playingAudioId === message.id 
                            ? "text-emerald-500 bg-emerald-50 dark:bg-emerald-900/20" 
                            : "text-zinc-400 hover:text-zinc-900 dark:hover:text-white hover:bg-zinc-100 dark:hover:bg-zinc-800"
                        )}
                      >
                        {playingAudioId === message.id ? <Volume2 className="w-4 h-4 animate-pulse" /> : <Volume2 className="w-4 h-4" />}
                      </button>
                    )}
                  </div>
                  <p className="text-[10px] text-zinc-400 px-1">
                    {message.timestamp.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                  </p>
                </div>
              </motion.div>
            ))}
            {isLoading && messages[messages.length - 1]?.role === 'user' && (
              <div className="flex gap-4 lg:gap-6 items-start">
                <div className="w-8 h-8 rounded-lg bg-zinc-900 dark:bg-white text-white dark:text-zinc-900 flex items-center justify-center flex-shrink-0 mt-1 overflow-hidden">
                  <MuhengaLogo className="w-full h-full rounded-none animate-pulse" />
                </div>
                <div className="flex-1 space-y-2">
                  <div className="inline-block p-4 rounded-2xl bg-zinc-50 dark:bg-zinc-900 border border-zinc-200 dark:border-zinc-800">
                    <div className="flex gap-1">
                      <span className="w-1.5 h-1.5 bg-zinc-400 rounded-full animate-bounce [animation-delay:-0.3s]"></span>
                      <span className="w-1.5 h-1.5 bg-zinc-400 rounded-full animate-bounce [animation-delay:-0.15s]"></span>
                      <span className="w-1.5 h-1.5 bg-zinc-400 rounded-full animate-bounce"></span>
                    </div>
                  </div>
                </div>
              </div>
            )}
            <div ref={messagesEndRef} />
          </div>
        </div>

        {/* Input Area */}
        <div className="p-4 lg:p-8 bg-gradient-to-t from-white dark:from-zinc-950 via-white dark:via-zinc-950 to-transparent">
          <div className="max-w-3xl mx-auto relative">
            {selectedImage && (
              <div className="absolute bottom-full mb-4 left-0 p-2 bg-white dark:bg-zinc-900 border border-zinc-200 dark:border-zinc-800 rounded-xl shadow-lg flex items-center gap-3">
                <div className="relative w-16 h-16 rounded-lg overflow-hidden border border-zinc-200 dark:border-zinc-800">
                  <img src={selectedImage} alt="Preview" className="w-full h-full object-cover" referrerPolicy="no-referrer" />
                  <button 
                    onClick={() => setSelectedImage(null)}
                    className="absolute top-0 right-0 p-1 bg-black/50 text-white hover:bg-black/70 transition-colors"
                  >
                    <X className="w-3 h-3" />
                  </button>
                </div>
                <p className="text-xs text-zinc-500 font-medium">Image attached</p>
              </div>
            )}
            
            <form 
              onSubmit={handleSubmit}
              className="relative flex items-end gap-2 bg-zinc-50 dark:bg-zinc-900 border border-zinc-200 dark:border-zinc-800 rounded-2xl p-2 shadow-sm focus-within:ring-2 focus-within:ring-zinc-200 dark:focus-within:ring-zinc-800 transition-all"
            >
              <div className="flex items-center gap-1 px-2 pb-2">
                <input 
                  type="file" 
                  ref={fileInputRef} 
                  onChange={handleImageUpload} 
                  accept="image/*" 
                  className="hidden" 
                />
                <button
                  type="button"
                  onClick={() => fileInputRef.current?.click()}
                  className="p-2 text-zinc-400 hover:text-zinc-900 dark:hover:text-white hover:bg-zinc-200 dark:hover:bg-zinc-800 rounded-xl transition-colors"
                >
                  <ImageIcon className="w-5 h-5" />
                </button>
                <button
                  type="button"
                  onClick={startVoiceInput}
                  className={cn(
                    "p-2 rounded-xl transition-colors",
                    isListening 
                      ? "text-red-500 bg-red-50 dark:bg-red-900/20" 
                      : "text-zinc-400 hover:text-zinc-900 dark:hover:text-white hover:bg-zinc-200 dark:hover:bg-zinc-800"
                  )}
                >
                  {isListening ? <MicOff className="w-5 h-5" /> : <Mic className="w-5 h-5" />}
                </button>
              </div>
              
              <textarea
                ref={textareaRef}
                rows={1}
                value={input}
                onChange={handleInput}
                onKeyDown={(e) => {
                  if (e.key === 'Enter' && !e.shiftKey) {
                    e.preventDefault();
                    handleSubmit();
                  }
                }}
                placeholder="Ask Muhenga anything..."
                className="flex-1 bg-transparent border-none focus:ring-0 resize-none py-3 px-2 text-sm max-h-[200px] outline-none"
              />
              
              <button
                type="submit"
                disabled={(!input.trim() && !selectedImage) || isLoading || isGeneratingImage}
                className={cn(
                  "p-3 rounded-xl transition-all",
                  (input.trim() || selectedImage) && !isLoading && !isGeneratingImage
                    ? "bg-zinc-900 dark:bg-white text-white dark:text-zinc-900 hover:scale-105 active:scale-95"
                    : "bg-zinc-100 dark:bg-zinc-800 text-zinc-400 cursor-not-allowed"
                )}
              >
                {isLoading || isGeneratingImage ? <Loader2 className="w-5 h-5 animate-spin" /> : <Send className="w-5 h-5" />}
              </button>
            </form>
            <p className="text-[10px] text-center text-zinc-400 mt-3">
              Muhenga AI can make mistakes. Check important info.
            </p>
          </div>
        </div>
      </main>
    </div>
  );
}