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

  final _destinations = const [
    (icon: Icons.upload_file_rounded, label: 'Upload'),
    (icon: Icons.chat_bubble_rounded, label: 'Chat'),
    (icon: Icons.folder_rounded, label: 'Library'),
  ];

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
      extendBody: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          decoration: const BoxDecoration(gradient: AppGradients.header),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            titleSpacing: 16,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: AppGradients.limeGlow,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: AppShadows.glow(AppColors.lime),
                  ),
                  child: const Icon(Icons.auto_stories_rounded, color: Colors.black, size: 20),
                ),
                const SizedBox(width: 10),
                const Text(
                  'PadhaiMate',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19, color: AppColors.textPrimary),
                ),
                
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _backendOk == null ? Colors.grey : (_backendOk! ? AppColors.onlineGreen : Colors.red),
                      boxShadow: _backendOk == true ? AppShadows.glow(AppColors.onlineGreen) : [],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: IndexedStack(key: ValueKey(_selectedIndex), index: _selectedIndex, children: screens),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Container(
          height: 68,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: AppColors.panelDark,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.card,
          ),
          child: Row(
            children: List.generate(_destinations.length, (i) {
              final selected = i == _selectedIndex;
              final dest = _destinations[i];
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedIndex = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                    decoration: BoxDecoration(
                      gradient: selected ? AppGradients.limeGlow : null,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(dest.icon, size: 20, color: selected ? Colors.black : AppColors.textMuted),
                        const SizedBox(height: 2),
                        Text(
                          dest.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: selected ? Colors.black : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}