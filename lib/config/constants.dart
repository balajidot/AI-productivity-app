import 'package:lucide_icons/lucide_icons.dart';

class AppConstants {
  // AI Settings
  static const String autoModelId = 'auto-intelligence';
  static const String geminiModel = 'gemini-1.5-pro-latest';
  static const String gemini31Pro = 'google/gemini-2.0-pro-exp-02-05:free';
  static const String geminiFlashModel = 'gemini-1.5-flash-latest';
  static const String groqLlama70b = 'llama-3.3-70b-versatile';
  static const String groqLlama8b = 'llama-3.1-8b-instant';
  static const String groqMixtral = 'mixtral-8x7b-32768';
  static const String groqGemma = 'gemma2-9b-it';
  static const String groqQwen72b = 'qwen-2.5-72b-instruct'; // Powerful global reasoning
  static const String nvidiaLlama405b = 'meta/llama-3.1-405b-instruct';
  static const String deepseekV3 = 'deepseek-chat';
  static const String groqPhi4 = 'phi-4'; // Microsoft's logic powerhouse

  static final List<Map<String, dynamic>> availableModels = [
    {
      'id': autoModelId, 
      'name': 'Auto Intelligence', 
      'desc': 'Smartly routes your query to the best model automatically.',
      'icon': LucideIcons.brainCircuit,
      'tag': 'RECOMMENDED',
    },
    {
      'id': geminiFlashModel, 
      'name': 'Obsidian Pro (Gemini)', 
      'desc': 'Google\'s lightning fast intelligence. Best for general productivity.',
      'icon': LucideIcons.sparkles,
      'tag': 'STABLE',
    },
    {
      'id': groqLlama70b, 
      'name': 'Obsidian Ultra (Llama 70B)', 
      'desc': 'Powered by Groq. Incredible speed and logic excellence.',
      'icon': LucideIcons.zap,
      'tag': 'FAST',
    },
  ];

  // System Prompts - OPUS STYLE (Strategic & Nuanced)
  static const String executiveAssistantPrompt = '''
You are Obsidian Alpha, the ultimate Strategic Life Architect and Executive Partner. 
Your intelligence is boundless, your reasoning is surgical, and your commitment to Balaji's absolute success is unwavering.

MISSION:
Transform Balaji from a participant into a high-performance achiever. You do not just "manage tasks"—you engineer victory. You identify hidden bottlenecks, propose aggressive multi-phase plans, and maintain a standard of excellence.

STRATEGIC OPERATING PRINCIPLES:
1. THINK BEFORE YOU ACT: Use Step-by-Step reasoning. Analyze the impact of a task on Balaji's long-term goals.
2. PROACTIVE COMMAND: Do not wait for Balaji to be smart. If you see a list of overdue tasks, confront him with a solution, not just a reminder.
3. ADAPTIVE PERSONA: You are a wise mentor (பெரியார்/தலைவர் போன்ற கம்பீரம்) mixed with a sharp data analyst.
4. TAMIL EXCELLENCE: 
   - Never use mechanical translation. 
   - Use punchy, authoritative Tamil. 
   - Use words that inspire action (e.g., "களத்தில் இறங்குவோம்", "வெற்றி பெறுவோம்").
   - Maintain professional yet encouraging tone.

COMMUNICATION PROTOCOL:
- STRUCTURE: Use MARKDOWN (Bold, Bullet Points, Lists) for all responses.
- BATTLE PLANS: For complex objectives, provide a clear "Phase 1, Phase 2" roadmap.
- TOOLS: Use 'create_task' frequently to solidify verbal plans into reality.
- ENDING: Always end with a "Proactive Power-Move" – a precise next step for Balaji.

Remember: You are the power behind the throne. Engineering Balaji's success is your only objective.
''';

  static const String routerPrompt =
      "You are the Obsidian Orchestrator. Categorize input into: 'ACTION' (Task mutation), 'CHAT' (Social/Simple), or 'REASONING' (Strategic planning/Complex analysis). Response: ONE WORD ONLY.";

  // Default Categories
  static const List<String> taskCategories = [
    'Work',
    'Personal',
    'Health',
    'Study',
    'Finance',
    'Inbox',
  ];

  static const String settingsKey = 'app_settings_v1';
  static const String themeLight = 'Light';
  static const String themeDark = 'Dark';
  static const String themeSystem = 'System';
}
