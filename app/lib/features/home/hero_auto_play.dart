import 'package:flutter_riverpod/flutter_riverpod.dart';

const heroAutoPlayInterval = Duration(seconds: 6);

final heroAutoPlayProvider = Provider<Duration?>((ref) => heroAutoPlayInterval);
