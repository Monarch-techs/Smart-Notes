import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Note {
  final String id;
  final String content;
  final DateTime createdAt;

  Note({required this.id, required this.content, required this.createdAt});

  Map<String, dynamic> toJson() => {
    'id': id,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Note.fromJson(Map<String, dynamic> json) => Note(
    id: json['id'],
    content: json['content'],
    createdAt: DateTime.parse(json['createdAt']),
  );
}

class NotesService {
  static const String _key = 'user_notes';

  Future<void> saveNote(String content) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notes = await getNotes();

      final newNote = Note(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: content,
        createdAt: DateTime.now(),
      );

      notes.insert(0, newNote);

      final notesJson = notes.map((n) => jsonEncode(n.toJson())).toList();
      await prefs.setStringList(_key, notesJson);
    } catch (e) {
      debugPrint('Error saving note: $e');
    }
  }

  Future<List<Note>> getNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notesJson = prefs.getStringList(_key);

      if (notesJson == null) return [];

      return notesJson
          .map((n) {
            try {
              return Note.fromJson(jsonDecode(n));
            } catch (e) {
              debugPrint('Error decoding note: $e');
              return null;
            }
          })
          .whereType<Note>()
          .toList();
    } catch (e) {
      debugPrint('Error getting notes: $e');
      return [];
    }
  }

  Future<void> deleteNote(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notes = await getNotes();
      notes.removeWhere((n) => n.id == id);

      final notesJson = notes.map((n) => jsonEncode(n.toJson())).toList();
      await prefs.setStringList(_key, notesJson);
    } catch (e) {
      debugPrint('Error deleting note: $e');
    }
  }

  Future<void> updateNote(String id, String newContent) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notes = await getNotes();

      final index = notes.indexWhere((n) => n.id == id);
      if (index != -1) {
        notes[index] = Note(
          id: id,
          content: newContent,
          createdAt: notes[index].createdAt,
        );

        final notesJson = notes.map((n) => jsonEncode(n.toJson())).toList();
        await prefs.setStringList(_key, notesJson);
      }
    } catch (e) {
      debugPrint('Error updating note: $e');
    }
  }
}
