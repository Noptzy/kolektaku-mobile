import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class ThemePreviewScreen extends StatefulWidget {
  const ThemePreviewScreen({super.key});

  @override
  State<ThemePreviewScreen> createState() => _ThemePreviewScreenState();
}

class _ThemePreviewScreenState extends State<ThemePreviewScreen> {
  final _inputController = TextEditingController();
  String _selectedTab = 'anime';

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return FScaffold(
      child: DecoratedBox(
        decoration: BoxDecoration(color: theme.colorScheme.background),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pratinjau tema Kolektaku', style: theme.textTheme.h2),
                const SizedBox(height: 24),
                ShadInput(
                  controller: _inputController,
                  placeholder: const Text('Cari anime atau manga'),
                ),
                const SizedBox(height: 16),
                ShadTabs<String>(
                  value: _selectedTab,
                  onChanged: (value) => setState(() => _selectedTab = value),
                  tabs: [
                    ShadTab(value: 'anime', child: const Text('Anime')),
                    ShadTab(value: 'manga', child: const Text('Manga')),
                  ],
                ),
                const SizedBox(height: 24),
                ShadButton(
                  onPressed: () {},
                  child: const Text('Tonton sekarang'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
