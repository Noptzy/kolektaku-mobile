import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers/gateway_providers.dart';
import '../../platform/apk_installer.dart';
import '../settings/settings_logic.dart';
import 'update_providers.dart';
import 'update_state.dart';

const lastCheckKey = 'update.last_checked';

class UpdateController extends Notifier<UpdateState> {
  @override
  UpdateState build() => const UpdateState();

  Future<void> checkOnLaunch() async {
    if (state.busy || state.hasOffer) return;
    try {
      final stored = await ref
          .read(libraryGatewayProvider)
          .preference(lastCheckKey);
      final now = ref.read(nowSecondsProvider)();
      final due = ref
          .read(updateGatewayProvider)
          .due(int.tryParse(stored ?? ''), now, manual: false);
      if (due) await _check(manual: false);
    } on Object {
      return;
    }
  }

  Future<void> checkNow() => _check(manual: true);

  Future<void> _check({required bool manual}) async {
    if (state.busy) return;
    state = const UpdateState(phase: UpdatePhase.checking);
    try {
      final installed = await ref.read(appVersionProvider.future);
      final abis = await ref.read(apkInstallerProvider).abis();
      final offer = await ref
          .read(updateGatewayProvider)
          .check(installed, abis);
      await _remember();
      state = offer == null
          ? const UpdateState(phase: UpdatePhase.upToDate)
          : UpdateState(
              phase: UpdatePhase.available,
              offer: offer,
              total: offer.size.toInt(),
            );
    } on Object catch (error) {
      state = manual
          ? UpdateState(phase: UpdatePhase.failed, error: '$error')
          : const UpdateState();
    }
  }

  Future<void> _remember() async {
    try {
      final now = ref.read(nowSecondsProvider)();
      await ref
          .read(libraryGatewayProvider)
          .setPreference(lastCheckKey, '$now');
    } on Object {
      return;
    }
  }

  Future<void> download() async {
    final offer = state.offer;
    if (offer == null || state.busy) return;
    state = UpdateState(
      phase: UpdatePhase.downloading,
      offer: offer,
      total: offer.size.toInt(),
    );
    try {
      final folder = await ref.read(updateFolderProvider)();
      await for (final event
          in ref.read(updateGatewayProvider).download(offer, folder)) {
        final path = event.path;
        state = path == null
            ? state.copyWith(
                received: event.received.toInt(),
                total: event.total.toInt(),
              )
            : state.copyWith(
                phase: UpdatePhase.ready,
                received: event.total.toInt(),
                total: event.total.toInt(),
                path: path,
              );
      }
      if (state.phase != UpdatePhase.ready) {
        throw const InstallFailure('unduhan tidak selesai');
      }
    } on Object catch (error) {
      state = state.copyWith(phase: UpdatePhase.failed, error: '$error');
    }
  }

  Future<void> install() async {
    final path = state.path;
    if (path == null || state.busy) return;
    state = state.copyWith(phase: UpdatePhase.installing);
    try {
      await ref.read(apkInstallerProvider).install(path);
      state = state.copyWith(phase: UpdatePhase.ready);
    } on Object catch (error) {
      state = state.copyWith(phase: UpdatePhase.failed, error: '$error');
    }
  }
}

final updateControllerProvider =
    NotifierProvider<UpdateController, UpdateState>(UpdateController.new);
