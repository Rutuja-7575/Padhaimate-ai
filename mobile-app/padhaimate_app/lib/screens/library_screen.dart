import 'dart:ui';
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

  Future<void> _confirmDelete(String filename) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove document?', style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          '$filename will be removed from your library and can no longer be searched.',
          style: const TextStyle(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed == true) _delete(filename);
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

  static const _cardColors = [AppColors.purple, AppColors.lime];

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -60,
          left: -40,
          child: _blob(AppColors.lime.withOpacity(0.12), 170),
        ),
        RefreshIndicator(
          onRefresh: _fetchDocs,
          color: AppColors.lime,
          backgroundColor: AppColors.cardDark,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Your Library',
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.cardDark,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      '${_docs.length} ${_docs.length == 1 ? 'doc' : 'docs'}',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Everything you\'ve uploaded, ready to search.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 24),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(child: CircularProgressIndicator(color: AppColors.lime)),
                )
              else if (_docs.isEmpty)
                _buildEmptyState()
              else
                ..._docs.asMap().entries.map((entry) {
                  final i = entry.key;
                  final doc = entry.value;
                  final filename = doc['filename'] as String;
                  final chunks = doc['chunks'];
                  final accent = _cardColors[i % _cardColors.length];
                  final isLime = accent == AppColors.lime;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.cardDark,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                      boxShadow: AppShadows.card,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            gradient: isLime ? AppGradients.limeGlow : AppGradients.purpleGlow,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.picture_as_pdf_rounded,
                            color: isLime ? Colors.black : Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                filename,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.layers_rounded, size: 12, color: AppColors.textMuted),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$chunks chunks indexed',
                                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        _deletingFile == filename
                            ? const Padding(
                                padding: EdgeInsets.all(10),
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.lime),
                                ),
                              )
                            : IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.textMuted),
                                onPressed: () => _confirmDelete(filename),
                              ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppGradients.purpleGlow,
              boxShadow: AppShadows.glow(AppColors.purple),
            ),
            child: const Icon(Icons.folder_off_rounded, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 18),
          const Text(
            'No documents yet',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Upload a PDF from the Upload tab to get started.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _blob(Color color, double size) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
      ),
    );
  }
}