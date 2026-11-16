import '../../src/rust/api/library.dart' as shelf;

const enabledKey = 'notify.enabled';
const hoursKey = 'notify.hours';
const askedKey = 'notify.asked';
const versionKey = 'notify.version';
const defaultHours = 2;
const hourChoices = [1, 2, 3, 6, 12];

int hoursFrom(String? text) {
  final parsed = int.tryParse(text ?? '');
  return parsed != null && hourChoices.contains(parsed) ? parsed : defaultHours;
}

bool enabledFrom(String? text) => text == '1';

abstract interface class PrefsStore {
  Future<String?> read(String name);

  Future<void> write(String name, String value);
}

class CorePrefsStore implements PrefsStore {
  const CorePrefsStore();

  @override
  Future<String?> read(String name) => shelf.libraryPreference(name: name);

  @override
  Future<void> write(String name, String value) =>
      shelf.librarySetPreference(name: name, value: value);
}

class MemoryPrefsStore implements PrefsStore {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String name) async => values[name];

  @override
  Future<void> write(String name, String value) async => values[name] = value;
}

abstract final class NotificationPrefs {
  static PrefsStore store = const CorePrefsStore();

  static Future<bool> enabled() async =>
      enabledFrom(await store.read(enabledKey));

  static Future<void> setEnabled(bool value) =>
      store.write(enabledKey, value ? '1' : '0');

  static Future<int> hours() async => hoursFrom(await store.read(hoursKey));

  static Future<void> setHours(int value) => store.write(hoursKey, '$value');

  static Future<bool> asked() async => await store.read(askedKey) == '1';

  static Future<void> markAsked() => store.write(askedKey, '1');

  static Future<String?> notifiedVersion() => store.read(versionKey);

  static Future<void> setNotifiedVersion(String version) =>
      store.write(versionKey, version);
}
