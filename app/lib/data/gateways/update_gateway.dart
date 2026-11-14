import '../../src/rust/api/update.dart' as api;
import '../../src/rust/dto/update.dart';

abstract interface class UpdateGateway {
  Future<UpdateOfferDto?> check(String installed, List<String> abis);

  Stream<UpdateProgressDto> download(UpdateOfferDto offer, String folder);
}

class BridgeUpdateGateway implements UpdateGateway {
  const BridgeUpdateGateway();

  @override
  Future<UpdateOfferDto?> check(String installed, List<String> abis) =>
      api.checkUpdate(installed: installed, abis: abis);

  @override
  Stream<UpdateProgressDto> download(UpdateOfferDto offer, String folder) =>
      api.downloadUpdate(offer: offer, folder: folder);
}
