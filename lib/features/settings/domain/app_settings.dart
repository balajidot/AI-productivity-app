class AppSettings {
  final bool smartAnalysis;
  final bool notificationsEnabled;
  final String aiTone;
  final String themeMode; // 'Light', 'Dark', 'System'
  final String aiModelId;
  final bool enableCelebration;
  final bool enableSound;
  final int pomodoroDuration;   // minutes, default 25
  final int shortBreakDuration; // minutes, default 5
  final int longBreakDuration;  // minutes, default 15
  final bool zenModeEnabled;
  final bool hideCompletedTasks;

  const AppSettings({
    this.smartAnalysis = true,
    this.notificationsEnabled = true,
    this.aiTone = 'Professional',
    this.themeMode = 'System',
    this.aiModelId = 'auto-intelligence',
    this.enableCelebration = true,
    this.enableSound = true,
    this.pomodoroDuration = 25,
    this.shortBreakDuration = 5,
    this.longBreakDuration = 15,
    this.zenModeEnabled = false,
    this.hideCompletedTasks = false,
  });

  AppSettings copyWith({
    bool? smartAnalysis,
    bool? notificationsEnabled,
    String? aiTone,
    String? themeMode,
    String? aiModelId,
    bool? enableCelebration,
    bool? enableSound,
    int? pomodoroDuration,
    int? shortBreakDuration,
    int? longBreakDuration,
    bool? zenModeEnabled,
    bool? hideCompletedTasks,
  }) {
    return AppSettings(
      smartAnalysis: smartAnalysis ?? this.smartAnalysis,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      aiTone: aiTone ?? this.aiTone,
      themeMode: themeMode ?? this.themeMode,
      aiModelId: aiModelId ?? this.aiModelId,
      enableCelebration: enableCelebration ?? this.enableCelebration,
      enableSound: enableSound ?? this.enableSound,
      pomodoroDuration: pomodoroDuration ?? this.pomodoroDuration,
      shortBreakDuration: shortBreakDuration ?? this.shortBreakDuration,
      longBreakDuration: longBreakDuration ?? this.longBreakDuration,
      zenModeEnabled: zenModeEnabled ?? this.zenModeEnabled,
      hideCompletedTasks: hideCompletedTasks ?? this.hideCompletedTasks,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'smartAnalysis': smartAnalysis,
      'notificationsEnabled': notificationsEnabled,
      'aiTone': aiTone,
      'themeMode': themeMode,
      'aiModelId': aiModelId,
      'enableCelebration': enableCelebration,
      'enableSound': enableSound,
      'pomodoroDuration': pomodoroDuration,
      'shortBreakDuration': shortBreakDuration,
      'longBreakDuration': longBreakDuration,
      'zenModeEnabled': zenModeEnabled,
      'hideCompletedTasks': hideCompletedTasks,
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      smartAnalysis: map['smartAnalysis'] as bool? ?? true,
      notificationsEnabled: map['notificationsEnabled'] as bool? ?? true,
      aiTone: map['aiTone'] as String? ?? 'Professional',
      themeMode: map['themeMode'] as String? ?? 'System',
      aiModelId: map['aiModelId'] as String? ?? 'auto-intelligence',
      enableCelebration: map['enableCelebration'] as bool? ?? true,
      enableSound: map['enableSound'] as bool? ?? true,
      pomodoroDuration: (map['pomodoroDuration'] as num?)?.toInt() ?? 25,
      shortBreakDuration: (map['shortBreakDuration'] as num?)?.toInt() ?? 5,
      longBreakDuration: (map['longBreakDuration'] as num?)?.toInt() ?? 15,
      zenModeEnabled: map['zenModeEnabled'] as bool? ?? false,
      hideCompletedTasks: map['hideCompletedTasks'] as bool? ?? false,
    );
  }
}
