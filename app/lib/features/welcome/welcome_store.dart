import 'dart:io';

const _markerName = 'welcome_seen';

abstract interface class WelcomeStore {
  Future<bool> seen();

  Future<void> markSeen();
}

class FileWelcomeStore implements WelcomeStore {
  const FileWelcomeStore(this._folder);

  final Future<Directory> Function() _folder;

  Future<File> _marker() async {
    final folder = await _folder();
    return File('${folder.path}${Platform.pathSeparator}$_markerName');
  }

  @override
  Future<bool> seen() async {
    try {
      return await (await _marker()).exists();
    } on Object {
      return true;
    }
  }

  @override
  Future<void> markSeen() async {
    try {
      await (await _marker()).writeAsString('1');
    } on Object {
      return;
    }
  }
}
