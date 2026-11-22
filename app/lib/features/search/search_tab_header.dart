import 'package:flutter/services.dart' show TextInputAction;
import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/kolektaku_tokens.dart';
import '../../widgets/pressable.dart';
import 'search_filter_button.dart';

class SearchTabHeader extends StatelessWidget {
  const SearchTabHeader({
    super.key,
    required this.controller,
    required this.placeholder,
    required this.onChanged,
    required this.onSubmitted,
    required this.onCamera,
    this.onFilter,
    this.filterCount = 0,
  });

  final TextEditingController controller;
  final String placeholder;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onCamera;
  final VoidCallback? onFilter;
  final int filterCount;

  void _clear() {
    controller.clear();
    onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.screenGutter,
        Spacing.md,
        Spacing.screenGutter,
        Spacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: ListenableBuilder(
              listenable: controller,
              builder: (context, child) => ShadInput(
                controller: controller,
                placeholder: Text(placeholder),
                textInputAction: TextInputAction.search,
                onChanged: onChanged,
                onSubmitted: onSubmitted,
                leading: const Icon(LucideIcons.search, size: 18),
                trailing: controller.text.isEmpty
                    ? null
                    : Pressable(
                        key: const Key('clear-search'),
                        onTap: _clear,
                        label: 'Hapus pencarian',
                        child: const Icon(LucideIcons.x, size: 18),
                      ),
              ),
            ),
          ),
          _HeaderIcon(
            key: const Key('open-camera'),
            icon: LucideIcons.camera,
            label: 'Cari dari gambar',
            onTap: onCamera,
          ),
          if (onFilter != null)
            SearchFilterButton(
              key: const Key('open-filters'),
              count: filterCount,
              onTap: onFilter!,
            ),
        ],
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = ShadTheme.of(context).colorScheme;
    return Pressable(
      onTap: onTap,
      label: label,
      minSize: Sizes.touchTarget,
      child: Center(child: Icon(icon, size: 22, color: scheme.foreground)),
    );
  }
}
