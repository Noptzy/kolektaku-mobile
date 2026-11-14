import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../src/rust/dto/update.dart';
import '../../platform/apk_installer.dart';
import '../settings/settings_logic.dart';
import 'update_providers.dart';
import 'update_state.dart';

class UpdateController extends Notifier<UpdateState> {
  @override
  UpdateState build() => const UpdateState();

  Future<void> checkOnLaunch() async {
    if (state.busy || state.hasOffer) return;
    await _check(manual: false);
  }

  Future<void> checkNow() => _check(manual: true);

  Future<void> _check({required bool manual}) async {
    if (state.busy) return;
    state = UpdateState(
      phase: UpdatePhase.checking,
      installed: state.installed,
    );
    var installed = '';
    UpdateOfferDto? offer;
    try {
      installed = await ref.read(appVersionProvider.future);
      final abis = await ref.read(apkInstallerProvider).abis();
      offer = await ref.read(updateGatewayProvider).check(installed, abis);
    } on Object catch (error) {
      state = manual
          ? UpdateState(
              phase: UpdatePhase.failed,
              error: '$error',
              installed: installed,
            )
          : UpdateState(installed: installed);
      return;
    }
    if (offer == null) {
      state = UpdateState(phase: UpdatePhase.upToDate, installed: installed);
      return;
    }
    state = UpdateState(
      phase: UpdatePhase.available,
      offer: offer,
      total: offer.size.toInt(),
      installed: installed,
    );
    if (ref.read(autoDownloadProvider)) await download();
  }

  Future<void> download() async {
    final offer = state.offer;
    if (offer == null || state.busy) return;
    state = UpdateState(
      phase: UpdatePhase.downloading,
      offer: offer,
      total: offer.size.toInt(),
      installed: state.installed,
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
