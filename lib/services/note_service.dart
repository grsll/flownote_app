import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flownote/models/note_model.dart';

/// Note service — menggunakan Firestore
/// Collection: notes/{uid}/items/{noteId}
class NoteService {
  final FirebaseFirestore _db   = FirebaseFirestore.instance;
  final FirebaseAuth      _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _notesRef =>
      _db.collection('notes').doc(_uid).collection('items');

  // ── READ ──────────────────────────────────────────────────────────────────

  Future<List<NoteModel>> getNotes({bool? isTask, String? search}) async {
    Query<Map<String, dynamic>> query = _notesRef;

    if (isTask != null) {
      query = query.where('is_task', isEqualTo: isTask);
    }

    query = query.orderBy('created_at', descending: true);
    final snapshot = await query.get();

    var notes = snapshot.docs
        .map((doc) => NoteModel.fromJson(doc.data(), docId: doc.id))
        .toList();

    // Filter pencarian di client side
    if (search != null && search.isNotEmpty) {
      final q = search.toLowerCase();
      notes = notes.where((n) =>
        n.title.toLowerCase().contains(q) ||
        (n.content?.toLowerCase().contains(q) ?? false)
      ).toList();
    }

    return notes;
  }

  // ── CREATE ────────────────────────────────────────────────────────────────

  Future<NoteModel> createNote({
    required String title,
    String? content,
    bool isTask = false,
    String color = '#FFFFFF',
  }) async {
    final now = DateTime.now();
    final data = {
      'user_id':      _uid,
      'title':        title,
      'content':      content,
      'is_task':      isTask,
      'is_completed': false,
      'color':        color,
      'created_at':   now.toIso8601String(),
      'updated_at':   now.toIso8601String(),
    };
    final docRef = await _notesRef.add(data);
    return NoteModel.fromJson(data, docId: docRef.id);
  }

  // ── UPDATE ────────────────────────────────────────────────────────────────

  Future<NoteModel> updateNote(
    String id, {
    required String title,
    String? content,
    bool isTask = false,
    bool isCompleted = false,
    String color = '#FFFFFF',
  }) async {
    final now = DateTime.now();
    final data = {
      'title':        title,
      'content':      content,
      'is_task':      isTask,
      'is_completed': isCompleted,
      'color':        color,
      'updated_at':   now.toIso8601String(),
    };
    await _notesRef.doc(id).update(data);
    // Return updated note (fetch dari cache / local state)
    final doc = await _notesRef.doc(id).get();
    return NoteModel.fromJson(doc.data()!, docId: doc.id);
  }

  // ── DELETE ────────────────────────────────────────────────────────────────

  Future<void> deleteNote(String id) async {
    await _notesRef.doc(id).delete();
  }
}
