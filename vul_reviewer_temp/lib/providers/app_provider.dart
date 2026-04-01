import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/question.dart';
import '../models/mistake_entry.dart';
import '../data/set_a_data.dart';
import '../data/set_b_data.dart';

enum QuizSet { a, b }

class AppProvider extends ChangeNotifier {
  // --- Active Set ---
  QuizSet _activeSet = QuizSet.a;
  QuizSet get activeSet => _activeSet;

  // --- Persistent State (per set) ---
  Map<QuizSet, int> _unlockedLevels = {QuizSet.a: 1, QuizSet.b: 1};
  Map<QuizSet, Map<int, int>> _levelScores = {QuizSet.a: {}, QuizSet.b: {}};
  Map<QuizSet, List<MistakeEntry>> _mistakes = {QuizSet.a: [], QuizSet.b: []};

  // --- Quiz Session State ---
  int _currentLevel = 1;
  List<Question> _sessionQuestions = [];
  int _currentQuestionIndex = 0;
  int _score = 0;
  int? _selectedAnswerIndex;
  bool _answered = false;
  List<MistakeEntry> _sessionMistakes = [];

  // --- Review Mode ---
  bool _isReviewMode = false;
  bool _isRetryMistakes = false;

  // Getters
  int unlockedLevelsFor(QuizSet set) => _unlockedLevels[set]!;
  int get unlockedLevels => _unlockedLevels[_activeSet]!;
  Map<int, int> get levelScores => _levelScores[_activeSet]!;
  List<MistakeEntry> get mistakes => _mistakes[_activeSet]!;
  int get currentLevel => _currentLevel;
  List<Question> get sessionQuestions => _sessionQuestions;
  int get currentQuestionIndex => _currentQuestionIndex;
  int get score => _score;
  int? get selectedAnswerIndex => _selectedAnswerIndex;
  bool get answered => _answered;
  bool get isReviewMode => _isReviewMode;
  bool get isRetryMistakes => _isRetryMistakes;
  List<MistakeEntry> get sessionMistakes => _sessionMistakes;

  Question get currentQuestion => _sessionQuestions[_currentQuestionIndex];
  bool get isLastQuestion => _currentQuestionIndex >= _sessionQuestions.length - 1;
  int get totalQuestions => _sessionQuestions.length;

  int get totalLevels => _activeSet == QuizSet.a ? setATotalLevels : setBTotalLevels;
  int get passingScore => _activeSet == QuizSet.a ? setAPassingScore : setBPassingScore;

  List<Question> get allActiveQuestions =>
      _activeSet == QuizSet.a ? setAQuestions : setBQuestions;

  double get totalAccuracy {
    final scores = _levelScores[_activeSet]!;
    if (scores.isEmpty) return 0;
    final total = scores.values.fold(0, (a, b) => a + b);
    final maxPossible = scores.length * 10;
    return maxPossible == 0 ? 0 : total / maxPossible;
  }

  AppProvider() {
    _loadProgress();
  }

  void setActiveSet(QuizSet set) {
    _activeSet = set;
    notifyListeners();
  }

  List<Question> _getQuestionsForLevel(int level) {
    return _activeSet == QuizSet.a
        ? getSetAQuestionsForLevel(level)
        : getSetBQuestionsForLevel(level);
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();

    for (final set in QuizSet.values) {
      final key = set == QuizSet.a ? 'a' : 'b';
      _unlockedLevels[set] = prefs.getInt('unlockedLevels_$key') ?? 1;

      final scoresJson = prefs.getString('levelScores_$key');
      if (scoresJson != null) {
        final decoded = jsonDecode(scoresJson) as Map<String, dynamic>;
        _levelScores[set] = decoded.map((k, v) => MapEntry(int.parse(k), v as int));
      }

      final mistakesJson = prefs.getString('mistakes_$key');
      if (mistakesJson != null) {
        final list = jsonDecode(mistakesJson) as List;
        final questions = set == QuizSet.a ? setAQuestions : setBQuestions;
        _mistakes[set] = list.map((e) {
          final q = questions.firstWhere((q) => q.id == e['questionId'],
              orElse: () => questions.first);
          return MistakeEntry(question: q, selectedIndex: e['selectedIndex']);
        }).toList();
      }
    }
    notifyListeners();
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final key = _activeSet == QuizSet.a ? 'a' : 'b';

    await prefs.setInt('unlockedLevels_$key', _unlockedLevels[_activeSet]!);
    final scoresJson = jsonEncode(_levelScores[_activeSet]!.map((k, v) => MapEntry(k.toString(), v)));
    await prefs.setString('levelScores_$key', scoresJson);
    final mistakesJson = jsonEncode(_mistakes[_activeSet]!.map((m) => {
      'questionId': m.question.id,
      'selectedIndex': m.selectedIndex,
    }).toList());
    await prefs.setString('mistakes_$key', mistakesJson);
  }

  void startLevel(int level) {
    _currentLevel = level;
    _sessionQuestions = _getQuestionsForLevel(level);
    _isReviewMode = false;
    _isRetryMistakes = false;
    _resetSession();
  }

  void startReviewMode() {
    _isReviewMode = true;
    _isRetryMistakes = false;
    _sessionQuestions = List.from(allActiveQuestions)..shuffle();
    _resetSession();
  }

  void startRetryMistakes() {
    _isRetryMistakes = true;
    _isReviewMode = false;
    _sessionQuestions = _mistakes[_activeSet]!.map((m) => m.question).toList();
    _resetSession();
  }

  void _resetSession() {
    _currentQuestionIndex = 0;
    _score = 0;
    _selectedAnswerIndex = null;
    _answered = false;
    _sessionMistakes = [];
    notifyListeners();
  }

  void selectAnswer(int index) {
    if (_answered) return;
    _selectedAnswerIndex = index;
    _answered = true;

    final q = currentQuestion;
    if (index == q.correctIndex) {
      _score++;
    } else {
      final entry = MistakeEntry(question: q, selectedIndex: index);
      _sessionMistakes.add(entry);
      _mistakes[_activeSet]!.removeWhere((m) => m.question.id == q.id);
      _mistakes[_activeSet]!.add(entry);
    }
    notifyListeners();
  }

  void nextQuestion() {
    if (!isLastQuestion) {
      _currentQuestionIndex++;
      _selectedAnswerIndex = null;
      _answered = false;
      notifyListeners();
    }
  }

  Future<void> finishLevel() async {
    if (!_isReviewMode && !_isRetryMistakes) {
      final prev = _levelScores[_activeSet]![_currentLevel] ?? 0;
      if (_score > prev) _levelScores[_activeSet]![_currentLevel] = _score;

      if (_score >= passingScore &&
          _currentLevel >= _unlockedLevels[_activeSet]! &&
          _currentLevel < totalLevels) {
        _unlockedLevels[_activeSet] = _currentLevel + 1;
      }
      await _saveProgress();
    }
    notifyListeners();
  }

  int starsForScore(int score, int total) {
    final ratio = score / total;
    if (ratio >= 0.9) return 3;
    if (ratio >= 0.7) return 2;
    return 1;
  }

  Future<void> clearMistakes() async {
    _mistakes[_activeSet]!.clear();
    await _saveProgress();
    notifyListeners();
  }

  Future<void> resetAllProgress() async {
    _unlockedLevels[_activeSet] = 1;
    _levelScores[_activeSet] = {};
    _mistakes[_activeSet] = [];
    final prefs = await SharedPreferences.getInstance();
    final key = _activeSet == QuizSet.a ? 'a' : 'b';
    await prefs.remove('unlockedLevels_$key');
    await prefs.remove('levelScores_$key');
    await prefs.remove('mistakes_$key');
    notifyListeners();
  }
}
