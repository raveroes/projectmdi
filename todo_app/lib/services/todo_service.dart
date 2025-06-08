import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class Todo {
  final String id;
  final String title;
  final String description;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  Todo({
    required this.id,
    required this.title,
    required this.description,
    required this.isCompleted,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Todo.fromMap(Map<String, dynamic> map) {
    return Todo(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      isCompleted: map['isCompleted'] as bool,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  Todo copyWith({
    String? id,
    String? title,
    String? description,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class TodoService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _uuid = const Uuid();
  List<Todo> _todos = [];
  bool _isLoading = false;
  String? _error;

  List<Todo> get todos => _todos;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadTodos() async {
    if (_auth.currentUser == null) return;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final snapshot = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('todos')
          .orderBy('createdAt', descending: true)
          .get();

      _todos = snapshot.docs
          .map((doc) => Todo.fromMap(doc.data()))
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTodo(String title, String description) async {
    if (_auth.currentUser == null) return;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final now = DateTime.now();
      final todo = Todo(
        id: _uuid.v4(),
        title: title,
        description: description,
        isCompleted: false,
        createdAt: now,
        updatedAt: now,
      );

      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('todos')
          .doc(todo.id)
          .set(todo.toMap());

      _todos.insert(0, todo);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateTodo(Todo todo) async {
    if (_auth.currentUser == null) return;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final updatedTodo = todo.copyWith(
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('todos')
          .doc(todo.id)
          .update(updatedTodo.toMap());

      final index = _todos.indexWhere((t) => t.id == todo.id);
      if (index != -1) {
        _todos[index] = updatedTodo;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteTodo(String id) async {
    if (_auth.currentUser == null) return;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('todos')
          .doc(id)
          .delete();

      _todos.removeWhere((todo) => todo.id == id);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleTodoStatus(String id) async {
    if (_auth.currentUser == null) return;

    try {
      final todo = _todos.firstWhere((t) => t.id == id);
      final updatedTodo = todo.copyWith(
        isCompleted: !todo.isCompleted,
        updatedAt: DateTime.now(),
      );

      await updateTodo(updatedTodo);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}