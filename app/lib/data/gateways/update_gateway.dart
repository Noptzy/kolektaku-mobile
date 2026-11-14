import '../../src/rust/api/update.dart' as api;
import '../../src/rust/dto/update.dart';

abstract interface class UpdateGateway {
  Future<UpdateOfferDto?> check(String installed, List<String> abis);

  Stream<UpdateProgressDto> download(UpdateOfferDto offer, String folder);

  bool due(int? lastCheckedSecs, int nowSecs, {required bool manual});
}

class BridgeUpdateGateway implements UpdateGateway {
  const BridgeUpdateGateway();

  @override
  Future<UpdateOfferDto?> check(String installed, List<String> abis) =>
      api.checkUpdate(installed: installed, abis: abis);

  @override
  Stream<UpdateProgressDto> download(UpdateOfferDto offer, String folder) =>
      api.downloadUpdate(offer: offer, folder: folder);

  @override
  bool due(int? lastCheckedSecs, int nowSecs, {required bool manual}) {
    return api.updateDue(
      lastCheckedSecs: lastCheckedSecs == null
          ? null
          : BigInt.from(lastCheckedSecs),
      nowSecs: BigInt.from(nowSecs),
      manual: manual,
    );
  }
}
