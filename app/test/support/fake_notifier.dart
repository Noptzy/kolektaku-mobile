import 'package:kolektaku/platform/notifier.dart';
import 'package:kolektaku/src/rust/dto/follow.dart';

class FakeNotifier implements Notifier {
  FakeNotifier({this.permitted = true, this.grants = true});

  bool permitted;
  bool grants;
  bool ready = false;
  int permissionAsks = 0;
  final List<List<UpdateEventDto>> shown = [];
  final List<({String title, String body})> notices = [];
  int tests = 0;
  String? launch;

  @override
  Future<void> init({void Function(String? payload)? onTap}) async =>
      ready = true;

  @override
  Future<bool> requestPermission() async {
    permissionAsks++;
    permitted = grants;
    return grants;
  }

  @override
  Future<bool> isPermitted() async => permitted;

  @override
  Future<void> showEvents(
    List<UpdateEventDto> events, {
    bool sound = true,
  }) async => shown.add(events);

  @override
  Future<void> showNotice({
    required String title,
    required String body,
  }) async => notices.add((title: title, body: body));

  @override
  Future<void> showTest() async => tests++;

  @override
  Future<String?> launchPayload() async => launch;
}
