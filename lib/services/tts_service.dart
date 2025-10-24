import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

enum TtsState { playing, stopped, paused, continued }

class TtsService with ChangeNotifier {
  final FlutterTts _flutterTts = FlutterTts();
  TtsState _ttsState = TtsState.stopped;
  String _currentText = '';
  bool _isSpeaking = false;

  TtsState get ttsState => _ttsState;
  String get currentText => _currentText;
  bool get isSpeaking => _isSpeaking;

  TtsService() {
    _initializeTts();
  }

  Future<void> _initializeTts() async {
    await _flutterTts.setLanguage("en-IN");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setVolume(1.0);

    _flutterTts.setStartHandler(() {
      _ttsState = TtsState.playing;
      _isSpeaking = true;
      notifyListeners();
    });

    _flutterTts.setCompletionHandler(() {
      _ttsState = TtsState.stopped;
      _isSpeaking = false;
      _currentText = '';
      notifyListeners();
    });

    _flutterTts.setErrorHandler((msg) {
      _ttsState = TtsState.stopped;
      _isSpeaking = false;
      _currentText = '';
      notifyListeners();
    });

    _flutterTts.setCancelHandler(() {
      _ttsState = TtsState.stopped;
      _isSpeaking = false;
      _currentText = '';
      notifyListeners();
    });
  }

  Future<void> speak(String text) async {
    if (_isSpeaking) {
      await stop();
      // Add a small delay to ensure previous speech is fully stopped
      await Future.delayed(const Duration(milliseconds: 100));
    }

    _currentText = text;

    try {
      await _flutterTts.speak(text);
    } catch (e) {
      _ttsState = TtsState.stopped;
      _isSpeaking = false;
      notifyListeners();
    }
  }

  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      _ttsState = TtsState.stopped;
      _isSpeaking = false;
      _currentText = '';
      notifyListeners();
    } catch (e) {
      _ttsState = TtsState.stopped;
      _isSpeaking = false;
      _currentText = '';
      notifyListeners();
    }
  }

  Future<void> pause() async {
    try {
      await _flutterTts.pause();
      _ttsState = TtsState.paused;
      notifyListeners();
    } catch (e) {
      // If pause fails, just stop
      await stop();
    }
  }

  Future<void> resume() async {
    try {
      await _flutterTts.speak(_currentText);
      _ttsState = TtsState.continued;
      notifyListeners();
    } catch (e) {
      _ttsState = TtsState.stopped;
      _isSpeaking = false;
      notifyListeners();
    }
  }

  // Toggle play/pause
  Future<void> toggleSpeaking(String text) async {
    if (_isSpeaking) {
      await stop();
    } else {
      await speak(text);
    }
  }

  // Force stop everything
  Future<void> forceStop() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      // Ignore errors during force stop
    } finally {
      _ttsState = TtsState.stopped;
      _isSpeaking = false;
      _currentText = '';
      notifyListeners();
    }
  }

  // Dispose method to clean up
  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }
}