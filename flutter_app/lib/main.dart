import 'dart:math';

import 'package:flutter/material.dart';

import 'dashboard_page.dart';
import 'drawing_canvas.dart';
import 'tamil_letters.dart';
import 'upload_service.dart';

void main() {
  runApp(const TamilHandwritingApp());
}

class TamilHandwritingApp extends StatelessWidget {
  const TamilHandwritingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tamil Handwriting Collector',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.deepOrange, useMaterial3: true),
      home: const CollectorPage(),
    );
  }
}

class CollectorPage extends StatefulWidget {
  const CollectorPage({super.key});

  @override
  State<CollectorPage> createState() => _CollectorPageState();
}

class _CollectorPageState extends State<CollectorPage> {
  final DrawingCanvasController _canvasController = DrawingCanvasController();
  final UploadService _uploadService = UploadService();
  final Random _random = Random();

  late List<String> _queue;
  late String _currentLetter;
  int _completedInCycle = 0;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _queue = List.of(tamilLetters)..shuffle(_random);
    _currentLetter = _queue.removeLast();
  }

  void _advanceToNextLetter() {
    if (_queue.isEmpty) {
      _queue = List.of(tamilLetters)..shuffle(_random);
      _completedInCycle = 0;
    }
    setState(() {
      _currentLetter = _queue.removeLast();
      _completedInCycle += 1;
      _canvasController.clear();
    });
  }

  Future<void> _onNextPressed() async {
    if (_canvasController.isEmpty) {
      _advanceToNextLetter();
      return;
    }

    setState(() => _isUploading = true);
    try {
      final bytes = await _canvasController.captureImage();
      if (bytes != null) {
        await _uploadService.upload(
          letterSlug: slugForLetter(_currentLetter),
          letterDisplay: _currentLetter,
          imageBytes: bytes,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saved!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }
      if (!mounted) return;
      _advanceToNextLetter();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed, try Next again: $e')),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tamil Handwriting Collector'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Collection stats',
            icon: const Icon(Icons.bar_chart),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DashboardPage()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'Letter ${_completedInCycle + 1} of ${tamilLetters.length} this cycle',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Text(
                _currentLetter,
                style: const TextStyle(fontSize: 96, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 500),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: DrawingCanvas(controller: _canvasController),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: _isUploading ? null : () => setState(_canvasController.undo),
                    icon: const Icon(Icons.undo),
                    label: const Text('Undo'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: _isUploading ? null : () => setState(_canvasController.clear),
                    icon: const Icon(Icons.clear),
                    label: const Text('Clear'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _isUploading ? null : _onNextPressed,
                    icon: _isUploading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: Text(
                      _canvasController.isEmpty ? 'Skip' : 'Submit',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
