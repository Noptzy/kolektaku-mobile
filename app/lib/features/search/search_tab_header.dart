import 'package:flutter/services.dart' show TextInputAction;
import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/kolektaku_tokens.dart';
import '../../widgets/pressable.dart';

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
        Spacing.sm,
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
            _HeaderIcon(
              key: const Key('open-filters'),
              icon: LucideIcons.slidersHorizontal,
              label: filterCount == 0 ? 'Filter' : 'Filter ($filterCount)',
              onTap: onFilter!,
              badge: filterCount,
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
    this.badge = 0,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final scheme = ShadTheme.of(context).colorScheme;
    return Pressable(
      onTap: onTap,
      label: label,
      minSize: Sizes.touchTarget,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(icon, size: 22, color: scheme.foreground),
          if (badge > 0)
            Positioned(
              top: 6,
              right: 4,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.primary,
                  shape: BoxShape.circle,
                ),
                child: SizedBox.square(
                  dimension: 16,
                  child: Center(
                    child: Text(
                      '$badge',
                      key: const Key('filter-badge'),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: scheme.primaryForeground,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
