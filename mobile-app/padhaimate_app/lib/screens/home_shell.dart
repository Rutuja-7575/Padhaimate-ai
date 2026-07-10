import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'upload_screen.dart';
import 'chat_screen.dart';
import 'library_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 1;
  bool? _backendOk;
  int _refreshTrigger = 0;

  @override
  void initState() {
    super.initState();
    _checkBackend();
  }

  Future<void> _checkBackend() async {
    try {
      await ApiService.checkHealth();
      setState(() => _backendOk = true);
    } catch (_) {
      setState(() => _backendOk = false);
    }
  }

  void _onUploaded() {
    setState(() {
      _refreshTrigger++;
      _selectedIndex = 2;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      UploadScreen(onUploadSuccess: _onUploaded),
      const ChatScreen(),
      LibraryScreen(refreshTrigger: _refreshTrigger),
    ];

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            const Text(
              'Padhai',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: AppColors.textPrimary,
              ),
            ),
            Container(
              margin: const EdgeInsets.only(left: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.lime,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Mate AI',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(width: 10),
            if (MediaQuery.of(context).size.width > 400)
              const Text(
                'RAG-powered document Q&A',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _backendOk == null
                      ? Colors.grey
                      : (_backendOk! ? AppColors.onlineGreen : Colors.red),
                ),
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.upload_file), label: 'Upload'),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), label: 'Chat'),
          NavigationDestination(icon: Icon(Icons.folder_outlined), label: 'Library'),
        ],
      ),
    );
  }
}