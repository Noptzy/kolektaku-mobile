import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers/gateway_providers.dart';
import '../../data/providers/home_providers.dart';
import '../../data/providers/library_providers.dart';
import '../../data/providers/toast_providers.dart';
import '../../src/rust/dto/highlight.dart';
import '../../src/rust/dto/library.dart';
import '../../src/rust/dto/media.dart';
import 'collection_logic.dart';
import 'confirm_sheet.dart';

class CollectionActions {
  const CollectionActions({
    required this.context,
    required this.ref,
    required this.kind,
  });

  final BuildContext context;
  final WidgetRef ref;
  final MediaKindDto kind;

  void _refresh() {
    ref.invalidate(historyProvider(kind));
    ref.invalidate(continueProvider(kind));
    ref.invalidate(favoritesProvider(kind));
  }

  void _offerUndo(String message, Future<void> Function() undo) {
    if (!context.mounted) return;
    ref
        .read(swipeToastProvider.notifier)
        .show(
          message: message,
          actionLabel: 'Urungkan',
          onAction: () async {
            await undo();
            _refresh();
          },
        );
  }

  Future<void> removeHistory(ProgressDto progress) async {
    final library = ref.read(libraryGatewayProvider);
    await library.removeProgress(
      progress.kind,
      progress.reference,
      progress.unitNumber,
    );
    _refresh();
    _offerUndo('Dihapus dari riwayat.', () => library.saveProgress(progress));
  }

  Future<void> removeFavorite(FavoriteDto favorite) async {
    final library = ref.read(libraryGatewayProvider);
    await library.toggleFavorite(favorite);
    _refresh();
    _offerUndo('Dihapus dari favorit.', () async {
      final still = await library.isFavorite(favorite.kind, favorite.reference);
      if (!still) await library.toggleFavorite(favorite);
    });
  }

  Future<void> removeHighlight(HighlightDto item) async {
    final agreed = await confirmSheet(
      context,
      title: 'Hapus sorotan?',
      message: 'Sorotan ini akan dihapus dari Koleksi dan dari novelnya.',
      confirmLabel: 'Hapus',
    );
    if (!agreed) return;
    await ref.read(highlightGatewayProvider).remove(item.id);
    ref.invalidate(highlightsProvider);
  }

  Future<void> clearHistory() async {
    final agreed = await confirmSheet(
      context,
      title: 'Hapus semua riwayat?',
      message:
          'Seluruh riwayat ${collectionTitle(kind).toLowerCase()} akan dihapus dan tidak bisa dikembalikan.',
      confirmLabel: 'Hapus semua',
    );
    if (!agreed) return;
    await ref.read(libraryGatewayProvider).clearHistory(kind);
    _refresh();
  }
}
