import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SpeechService {
  final SpeechToText _speech = SpeechToText();

  Future<bool> initialize({
    required Function(String) onStatus,
    required Function(String) onError,
  }) async {
    try {
      return await _speech.initialize(
        onError: (error) => onError(error.errorMsg),
        onStatus: (status) => onStatus(status),
      );
    } catch (e) {
      debugPrint('Speech Initialization Error: $e');
      return false;
    }
  }

  Future<void> startListening({
    required Function(String) onResult,
    required String localeId,
  }) async {
    try {
      await _speech.listen(
        onResult: (result) => onResult(result.recognizedWords),
        listenFor: const Duration(minutes: 1),
        pauseFor: const Duration(seconds: 10),
        localeId: localeId,
        listenOptions: SpeechListenOptions(
          partialResults: true,
          cancelOnError: false,
          listenMode: ListenMode.dictation,
        ),
      );
    } catch (e) {
      debugPrint('Speech Listen Error: $e');
    }
  }

  Future<void> stopListening() async {
    try {
      await _speech.stop();
    } catch (e) {
      debugPrint('Speech Stop Error: $e');
    }
  }

  Future<void> cancelListening() async {
    try {
      await _speech.cancel();
    } catch (e) {
      debugPrint('Speech Cancel Error: $e');
    }
  }

  bool get isListening => _speech.isListening;
  bool get isAvailable => _speech.isAvailable;
}
