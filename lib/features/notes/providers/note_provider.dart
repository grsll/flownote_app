import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flownote/models/note_model.dart';
import 'package:flownote/services/note_service.dart';

class NoteState {
  final List<NoteModel> notes;
  final List<NoteModel> tasks;
  final bool isLoading;
  final String? error;
  final String searchQuery;

  const NoteState({
    this.notes       = const [],
    this.tasks       = const [],
    this.isLoading   = false,
    this.error,
    this.searchQuery = '',
  });

  NoteState copyWith({
    List<NoteModel>? notes,
    List<NoteModel>? tasks,
    bool? isLoading,
    String? error,
    String? searchQuery,
  }) {
    return NoteState(
      notes:       notes       ?? this.notes,
      tasks:       tasks       ?? this.tasks,
      isLoading:   isLoading   ?? this.isLoading,
      error:       error,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class NoteNotifier extends StateNotifier<NoteState> {
  final NoteService _service;
  NoteNotifier(this._service) : super(const NoteState());

  Future<void> loadAll({bool refresh = false}) async {
    if (state.isLoading && !refresh) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final results = await Future.wait([
        _service.getNotes(isTask: false, search: state.searchQuery.isEmpty ? null : state.searchQuery),
        _service.getNotes(isTask: true,  search: state.searchQuery.isEmpty ? null : state.searchQuery),
      ]);
      state = state.copyWith(
        isLoading: false,
        notes: results[0],
        tasks: results[1],
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> createNote({
    required String title,
    String? content,
    bool isTask = false,
    String color = '#FFFFFF',
  }) async {
    try {
      final note = await _service.createNote(
        title: title, content: content, isTask: isTask, color: color,
      );
      if (isTask) {
        state = state.copyWith(tasks: [note, ...state.tasks]);
      } else {
        state = state.copyWith(notes: [note, ...state.notes]);
      }
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> toggleTask(NoteModel note) async {
    try {
      final updated = await _service.updateNote(
        note.id,
        title: note.title,
        content: note.content,
        isTask: note.isTask,
        isCompleted: !note.isCompleted,
        color: note.color,
      );
      state = state.copyWith(
        tasks: state.tasks.map((t) => t.id == note.id ? updated : t).toList(),
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteNote(String id, {required bool isTask}) async {
    try {
      await _service.deleteNote(id);
      if (isTask) {
        state = state.copyWith(tasks: state.tasks.where((t) => t.id != id).toList());
      } else {
        state = state.copyWith(notes: state.notes.where((n) => n.id != id).toList());
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  void search(String query) {
    state = state.copyWith(searchQuery: query);
    loadAll(refresh: true);
  }
}

final noteServiceProvider = Provider<NoteService>((ref) => NoteService());

final noteProvider = StateNotifierProvider<NoteNotifier, NoteState>((ref) {
  return NoteNotifier(ref.read(noteServiceProvider));
});
