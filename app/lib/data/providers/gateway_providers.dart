import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../gateways/bridge_catalog_gateway.dart';
import '../gateways/bridge_library_gateway.dart';
import '../gateways/catalog_gateway.dart';
import '../gateways/library_gateway.dart';
import '../gateways/scene_gateway.dart';
import '../gateways/settings_gateway.dart';
import '../gateways/source_gateway.dart';
import '../gateways/translation_gateway.dart';

final catalogGatewayProvider = Provider<CatalogGateway>(
  (ref) => const BridgeCatalogGateway(),
);

final libraryGatewayProvider = Provider<LibraryGateway>(
  (ref) => const BridgeLibraryGateway(),
);

final sourceGatewayProvider = Provider<SourceGateway>(
  (ref) => const BridgeSourceGateway(),
);

final sceneGatewayProvider = Provider<SceneGateway>(
  (ref) => const BridgeSceneGateway(),
);

final settingsGatewayProvider = Provider<SettingsGateway>(
  (ref) => const BridgeSettingsGateway(),
);

final translationGatewayProvider = Provider<TranslationGateway>(
  (ref) => const BridgeTranslationGateway(),
);
