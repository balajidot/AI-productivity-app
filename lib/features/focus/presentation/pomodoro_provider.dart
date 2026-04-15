import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../settings/presentation/settings_provider.dart';

enum PomodoroPhase { work, shortBreak, longBreak }

class PomodoroState {
  final PomodoroPhase phase;
  final int secondsRemaining;
  final int sessionCount; // completed work sessions
  final bool isRunning;

  const PomodoroState({
    this.phase = PomodoroPhase.work,
    this.secondsRemaining = 25 * 60,
    this.sessionCount = 0,
    this.isRunning = false,
  });

  PomodoroState copyWith({
    PomodoroPhase? phase,
    int? secondsRemaining,
    int? sessionCount,
    bool? isRunning,
  }) {
    return PomodoroState(
      phase: phase ?? this.phase,
      secondsRemaining: secondsRemaining ?? this.secondsRemaining,
      sessionCount: sessionCount ?? this.sessionCount,
      isRunning: isRunning ?? this.isRunning,
    );
  }

  String get timeDisplay {
    final m = secondsRemaining ~/ 60;
    final s = secondsRemaining % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class PomodoroNotifier extends Notifier<PomodoroState> {
  Timer? _timer;

  @override
  PomodoroState build() {
    final settings = ref.watch(appSettingsProvider);
    ref.onDispose(() {
      _timer?.cancel();
      _timer = null;
    });
    // Only reset if not currently running
    if (_timer != null) return state;
    return PomodoroState(secondsRemaining: settings.pomodoroDuration * 60);
  }

  int get _workDuration =>
      ref.read(appSettingsProvider).pomodoroDuration * 60;
  int get _shortBreakDuration =>
      ref.read(appSettingsProvider).shortBreakDuration * 60;
  int get _longBreakDuration =>
      ref.read(appSettingsProvider).longBreakDuration * 60;

  void start() {
    if (state.isRunning) return;
    state = state.copyWith(isRunning: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void pause() {
    _timer?.cancel();
    _timer = null;
    state = state.copyWith(isRunning: false);
  }

  void reset() {
    _timer?.cancel();
    _timer = null;
    state = PomodoroState(secondsRemaining: _workDuration);
  }

  void _tick() {
    if (state.secondsRemaining <= 1) {
      _onPhaseComplete();
      return;
    }
    state = state.copyWith(secondsRemaining: state.secondsRemaining - 1);
  }

  void _onPhaseComplete() {
    _timer?.cancel();
    _timer = null;

    if (state.phase == PomodoroPhase.work) {
      final newCount = state.sessionCount + 1;
      final isLongBreak = newCount % 4 == 0;
      final nextPhase =
          isLongBreak ? PomodoroPhase.longBreak : PomodoroPhase.shortBreak;
      state = PomodoroState(
        phase: nextPhase,
        secondsRemaining:
            isLongBreak ? _longBreakDuration : _shortBreakDuration,
        sessionCount: newCount,
        isRunning: false,
      );
    } else {
      // Break complete → back to work
      state = PomodoroState(
        phase: PomodoroPhase.work,
        secondsRemaining: _workDuration,
        sessionCount: state.sessionCount,
        isRunning: false,
      );
    }
  }


}

final pomodoroProvider =
    NotifierProvider<PomodoroNotifier, PomodoroState>(PomodoroNotifier.new);
