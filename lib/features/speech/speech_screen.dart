import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:smart_notes/features/speech/speech_service.dart';
import 'package:smart_notes/features/notes/notes_service.dart';

class SpeechScreen extends StatefulWidget {
  const SpeechScreen({super.key});

  @override
  State<SpeechScreen> createState() => _SpeechScreenState();
}

class _SpeechScreenState extends State<SpeechScreen> {
  final SpeechService _speechService = SpeechService();
  final NotesService _notesService = NotesService();

  String _text = 'Press the button and start speaking';
  String _lastSessionText = '';
  bool _isListening = false;
  bool _isSpeechInitialized = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    final status = await Permission.microphone.request();
    if (status.isGranted) {
      _isSpeechInitialized = await _speechService.initialize(
        onStatus: (status) {
          if (mounted) {
            setState(() {
              _isListening = status == 'listening';

              if (status == 'notListening' && _text.isNotEmpty) {
                _lastSessionText = _text;
              }
            });
          }
        },
        onError: (error) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Speech error: $error')));
          }
        },
      );
      setState(() {});
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission is required')),
        );
      }
    }
  }

  void _toggleListening() async {
    if (!_isSpeechInitialized) {
      await _initSpeech();
      if (!_isSpeechInitialized) return;
    }

    if (_isListening) {
      await _speechService.stopListening();
    } else {
      if (_text == 'Press the button and start speaking') {
        setState(() {
          _text = '';
          _lastSessionText = '';
        });
      } else {
        _lastSessionText = _text;
      }

      await _speechService.startListening(
        onResult: (result) {
          if (mounted) {
            setState(() {
              if (_lastSessionText.isEmpty) {
                _text = result;
              } else {
                _text = '$_lastSessionText $result'.trim();
              }
            });
          }
        },
        localeId: 'en_US',
      );
    }
  }

  void _saveNote() async {
    final trimmedText = _text.trim();
    if (trimmedText.isEmpty ||
        trimmedText == 'Press the button and start speaking' ||
        trimmedText == 'Listening...') {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Nothing to save')));
      return;
    }

    await _notesService.saveNote(trimmedText);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Note saved successfully')));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Speech to Text')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _text.isEmpty && _isListening ? 'Listening...' : _text,
                    style: TextStyle(
                      fontSize: 18,
                      color: _text == 'Press the button and start speaking'
                          ? Colors.grey
                          : Colors.white,
                      fontStyle: _text.isEmpty && _isListening
                          ? FontStyle.italic
                          : FontStyle.normal,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: () => setState(() {
                    _text = '';
                    _lastSessionText = '';
                  }),
                  icon: const Icon(Icons.clear, color: Colors.redAccent),
                  tooltip: 'Clear text',
                ),
                FloatingActionButton(
                  onPressed: _toggleListening,
                  backgroundColor: _isListening
                      ? Colors.red
                      : Colors.blueAccent,
                  child: Icon(_isListening ? Icons.stop : Icons.mic),
                ),
                IconButton(
                  onPressed: _saveNote,
                  icon: const Icon(Icons.save, color: Colors.greenAccent),
                  tooltip: 'Save note',
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              _isListening
                  ? 'Listening... Speak now'
                  : 'Tap microphone to start',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
