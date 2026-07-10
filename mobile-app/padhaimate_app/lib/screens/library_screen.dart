import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class LibraryScreen extends StatefulWidget {
  final int refreshTrigger;
  const LibraryScreen({super.key, this.refreshTrigger = 0});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  List<dynamic> _docs = [];
  bool _loading = true;
  String? _deletingFile;

  @override
  void initState() {
    super.initState();
    _fetchDocs();
  }

  @override
  void didUpdateWidget(covariant LibraryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshTrigger != widget.refreshTrigger) {
      _fetchDocs();
    }
  }

  Future<void> _fetchDocs() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.getDocuments();
      setState(() => _docs = res['documents'] ?? []);
    } catch (_) {
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _delete(String filename) async {
    setState(() => _deletingFile = filename);
    try {
      await ApiService.deleteDocument(filename);
      await _fetchDocs();
    } finally {
      setState(() => _deletingFile = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _fetchDocs,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'LIBRARY',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              letterSpacing: 2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          const Text('Step 02', style: TextStyle(color: AppColors.textMuted, fontSize: 18)),
          const SizedBox(height: 4),
          const Text(
            'Your Library',
            style: TextStyle(color: AppColors.purple, fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator(color: AppColors.lime)),
            )
          else if (_docs.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  'Nothing here yet — upload a PDF to get started.',
                  style: TextStyle(color: AppColors.textMuted),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            ..._docs.map((doc) {
              final filename = doc['filename'] as String;
              final chunks = doc['chunks'];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.purple),
                  title: Text(filename, style: const TextStyle(color: AppColors.textPrimary)),
                  subtitle: Text('$chunks chunks', style: const TextStyle(color: AppColors.textMuted)),
                  trailing: _deletingFile == filename
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.lime),
                        )
                      : IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppColors.textMuted),
                          onPressed: () => _delete(filename),
                        ),
                ),
              );
            }),
        ],
      ),
    );
  }
}