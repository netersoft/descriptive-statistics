import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_provider.g.dart';

@riverpod
class Home extends _$Home {
  @override
  int build() => 0;

  // A getter here would violate riverpod_lint's avoid_public_notifier_properties
  // (reads should go through `ref.watch(homeProvider)`/`state` instead).
  // ignore: avoid_setters_without_getters
  set tabIndex(int index) => state = index;
}
