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

class _UploadScreenState extends State<UploadScreen> {
  PlatformFile? _pickedFile;
  bool _uploading = false;
  String? _statusMessage;
  bool _statusIsError = false;

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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ADD A DOCUMENT',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              letterSpacing: 2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Step 01',
            style: TextStyle(color: AppColors.textMuted, fontSize: 18),
          ),
          const SizedBox(height: 4),
          const Text(
            'Upload a PDF',
            style: TextStyle(
              color: AppColors.purple,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          InkWell(
            onTap: _uploading ? null : _pickFile,
            borderRadius: BorderRadius.circular(12),
            child: DottedBorderBox(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
                child: Column(
                  children: [
                    const Icon(Icons.arrow_upward, color: AppColors.lime, size: 28),
                    const SizedBox(height: 12),
                    Text(
                      _pickedFile == null
                          ? 'Drag a PDF here, or click to browse'
                          : _pickedFile!.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Only .pdf files are supported',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.lime,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _uploading ? null : _upload,
              child: _uploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                    )
                  : const Text('Upload document', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          if (_statusMessage != null) ...[
            const SizedBox(height: 16),
            Text(
              _statusMessage!,
              style: TextStyle(color: _statusIsError ? Colors.redAccent : AppColors.onlineGreen),
            ),
          ],
        ],
      ),
    );
  }
}

/// Simple dashed-border container to mimic the web app's dropzone.
class DottedBorderBox extends StatelessWidget {
  final Widget child;
  const DottedBorderBox({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(),
      child: child,
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dashWidth = 6.0;
    const dashSpace = 4.0;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(12),
    );

    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}