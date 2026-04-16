import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../settings/presentation/settings_provider.dart';
import '../../tasks/domain/task.dart';
import '../../tasks/presentation/task_provider.dart';
import '../../chat/presentation/feedback_provider.dart';
import '../../../core/utils/service_failure.dart';

enum PomodoroPhase { work, shortBreak, longBreak }

class PomodoroState {
  final PomodoroPhase phase;
  final int secondsRemaining;
  final int sessionCount; // completed work sessions
  final bool isRunning;
  final Task? selectedTask;

  const PomodoroState({
    this.phase = PomodoroPhase.work,
    this.secondsRemaining = 25 * 60,
    this.sessionCount = 0,
    this.isRunning = false,
    this.selectedTask,
  });

  PomodoroState copyWith({
    PomodoroPhase? phase,
    int? secondsRemaining,
    int? sessionCount,
    bool? isRunning,
    Task? selectedTask,
    bool clearSelectedTask = false,
  }) {
    return PomodoroState(
      phase: phase ?? this.phase,
      secondsRemaining: secondsRemaining ?? this.secondsRemaining,
      sessionCount: sessionCount ?? this.sessionCount,
      isRunning: isRunning ?? this.isRunning,
      selectedTask: clearSelectedTask ? null : (selectedTask ?? this.selectedTask),
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
  AppLifecycleListener? _lifecycleListener;

  @override
  PomodoroState build() {
    final settings = ref.watch(appSettingsProvider);
    
    _lifecycleListener ??= AppLifecycleListener(
      onStateChange: _onAppLifecycleStateChange,
    );

    ref.onDispose(() {
      _timer?.cancel();
      _timer = null;
      _lifecycleListener?.dispose();
    });
    
    // Only reset if not currently running
    if (_timer != null) return state;
    return PomodoroState(secondsRemaining: settings.pomodoroDuration * 60);
  }

  void _onAppLifecycleStateChange(AppLifecycleState appState) {
    if (appState == AppLifecycleState.paused || appState == AppLifecycleState.hidden) {
      final settings = ref.read(appSettingsProvider);
      if (settings.zenModeEnabled && state.isRunning && state.phase == PomodoroPhase.work) {
        // Strict Mode violation: fail the Pomodoro
        reset();
        ref.read(feedbackProvider.notifier).showError(
          ServiceFailure(
            message: 'Pomodoro failed! Zen Mode requires the app to stay open.',
            type: FailureType.unknown,
          ),
        );
      }
    }
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
    state = PomodoroState(secondsRemaining: _workDuration, selectedTask: state.selectedTask);
  }

  void selectTask(Task? task) {
    state = state.copyWith(
      selectedTask: task,
      clearSelectedTask: task == null,
    );
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

      // Update linked task stats
      if (state.selectedTask != null) {
        final task = state.selectedTask!;
        final updatedTask = task.copyWith(
          focusSessions: (task.focusSessions ?? 0) + 1,
          timeSpentMinutes: (task.timeSpentMinutes ?? 0) + (_workDuration ~/ 60),
        );
        ref.read(tasksProvider.notifier).updateTask(updatedTask);
        // Also update local state so the UI reflects the new count
        state = state.copyWith(selectedTask: updatedTask);
      }

      state = PomodoroState(
        phase: nextPhase,
        secondsRemaining:
            isLongBreak ? _longBreakDuration : _shortBreakDuration,
        sessionCount: newCount,
        isRunning: false,
        selectedTask: state.selectedTask,
      );
    } else {
      // Break complete → back to work
      state = PomodoroState(
        phase: PomodoroPhase.work,
        secondsRemaining: _workDuration,
        sessionCount: state.sessionCount,
        isRunning: false,
        selectedTask: state.selectedTask,
      );
    }
  }


}

final pomodoroProvider =
    NotifierProvider<PomodoroNotifier, PomodoroState>(PomodoroNotifier.new);

final pomodoroTaskSelectorProvider = Provider<List<Task>>((ref) {
  // Use activeTasksProvider from task_provider.dart
  return ref.watch(activeTasksProvider);
});
