import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_provider.g.dart';

/// Indices of the home screen's tabs, in `HomeScreen`'s order.
abstract final class HomeTab {
  static const documentation = 0;
  static const discrete = 1;
  static const continuous = 2;
  static const qualitative = 3;
  static const backups = 4;
  static const tutorial = 5;
}

@riverpod
class Home extends _$Home {
  @override
  int build() => 0;

  // A getter here would violate riverpod_lint's avoid_public_notifier_properties
  // (reads should go through `ref.watch(homeProvider)`/`state` instead).
  // ignore: avoid_setters_without_getters
  set tabIndex(int index) => state = index;
}
