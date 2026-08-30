import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_provider.g.dart';

@riverpod
class Home extends _$Home {
  @override
  int build() => 0;

  int get tabIndex => state;

  set tabIndex(int index) => state = index;
}
