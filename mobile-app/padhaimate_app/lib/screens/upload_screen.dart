import 'dart:ui';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class UploadScreen extends StatefulWidget {
  final VoidCallback? onUploadSuccess;
  const UploadScreen({super.key, this.onUploadSuccess});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> with SingleTickerProviderStateMixin {
  PlatformFile? _pickedFile;
  bool _uploading = false;
  String? _statusMessage;
  bool _statusIsError = false;
  bool _hovering = false;

  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _pickedFile = result.files.first;
        _statusMessage = null;
      });
    }
  }

  Future<void> _upload() async {
    if (_pickedFile == null) {
      setState(() {
        _statusMessage = 'Pick a PDF first.';
        _statusIsError = true;
      });
      return;
    }
    setState(() {
      _uploading = true;
      _statusMessage = null;
    });
    try {
      final res = await ApiService.uploadDocument(_pickedFile!);
      setState(() {
        _statusMessage = '${res['message']} — ${res['chunks_stored']} chunks stored';
        _statusIsError = false;
        _pickedFile = null;
      });
      widget.onUploadSuccess?.call();
    } catch (e) {
      setState(() {
        _statusMessage = e.toString().replaceFirst('Exception: ', '');
        _statusIsError = true;
      });
    } finally {
      setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasFile = _pickedFile != null;

    return Stack(
      children: [
        // Decorative background blobs
        Positioned(
          top: -60,
          right: -40,
          child: _blob(AppColors.purple.withOpacity(0.25), 180),
        ),
        Positioned(
          top: 180,
          left: -50,
          child: _blob(AppColors.lime.withOpacity(0.15), 140),
        ),
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Turn your notes into answers',
                style: TextStyle(color: AppColors.textMuted, fontSize: 14),
              ),
              const SizedBox(height: 4),
              const Text(
                'Upload a PDF',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: _uploading ? null : _pickFile,
                child: MouseRegion(
                  onEnter: (_) => setState(() => _hovering = true),
                  onExit: (_) => setState(() => _hovering = false),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: AppColors.cardDark,
                      border: Border.all(
                        color: hasFile
                            ? AppColors.lime
                            : (_hovering ? AppColors.purple : AppColors.border),
                        width: hasFile || _hovering ? 1.5 : 1,
                      ),
                      boxShadow: hasFile ? AppShadows.glow(AppColors.lime) : [],
                    ),
                    child: Column(
                      children: [
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            final scale = hasFile ? 1.0 : 1.0 + (_pulseController.value * 0.08);
                            return Transform.scale(scale: scale, child: child);
                          },
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: hasFile ? AppGradients.limeGlow : AppGradients.purpleGlow,
                              boxShadow: AppShadows.glow(hasFile ? AppColors.lime : AppColors.purple),
                            ),
                            child: Icon(
                              hasFile ? Icons.picture_as_pdf_rounded : Icons.cloud_upload_rounded,
                              color: hasFile ? Colors.black : Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          hasFile ? _pickedFile!.name : 'Tap to choose a PDF',
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          hasFile
                              ? '${(_pickedFile!.size / 1024).toStringAsFixed(0)} KB • ready to upload'
                              : 'PDF files only • max a few MB',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                        ),
                        if (hasFile) ...[
                          const SizedBox(height: 14),
                          TextButton.icon(
                            onPressed: () => setState(() => _pickedFile = null),
                            icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.textMuted),
                            label: const Text('Remove', style: TextStyle(color: AppColors.textMuted)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: hasFile ? AppColors.lime : AppColors.border,
                    foregroundColor: Colors.black,
                    elevation: hasFile ? 6 : 0,
                    shadowColor: AppColors.lime.withOpacity(0.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: (_uploading || !hasFile) ? (hasFile ? _upload : null) : _upload,
                  child: _uploading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.black),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.bolt_rounded, color: hasFile ? Colors.black : AppColors.textMuted),
                            const SizedBox(width: 8),
                            Text(
                              'Upload & analyze',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: hasFile ? Colors.black : AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              if (_statusMessage != null) ...[
                const SizedBox(height: 18),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: (_statusIsError ? Colors.redAccent : AppColors.onlineGreen).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (_statusIsError ? Colors.redAccent : AppColors.onlineGreen).withOpacity(0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _statusIsError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
                        color: _statusIsError ? Colors.redAccent : AppColors.onlineGreen,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _statusMessage!,
                          style: TextStyle(color: _statusIsError ? Colors.redAccent : AppColors.onlineGreen),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
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