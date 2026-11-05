import 'package:flutter_riverpod/flutter_riverpod.dart';

class MatchFilterState {
  const MatchFilterState({this.intent = 'FRIENDS'});

  final String intent;

  MatchFilterState copyWith({String? intent}) =>
      MatchFilterState(intent: intent ?? this.intent);
}

class MatchFilterNotifier extends Notifier<MatchFilterState> {
  @override
  MatchFilterState build() => const MatchFilterState();

  void setIntent(String intent) => state = state.copyWith(intent: intent);
}

final matchFilterProvider =
    NotifierProvider<MatchFilterNotifier, MatchFilterState>(
      MatchFilterNotifier.new,
    );
