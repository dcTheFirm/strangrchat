import 'package:flutter_riverpod/flutter_riverpod.dart';

class MatchFilterState {
  final String intent; // 'FRIENDS', 'RELATIONSHIP', 'MARRIED', 'TIPS'
  final String city;
  final double radiusKm;
  final List<String> selectedHobbies;
  final String gender;

  MatchFilterState({
    this.intent = 'FRIENDS',
    this.city = 'Mumbai',
    this.radiusKm = 25.0,
    this.selectedHobbies = const [],
    this.gender = 'ANY',
  });

  MatchFilterState copyWith({
    String? intent,
    String? city,
    double? radiusKm,
    List<String>? selectedHobbies,
    String? gender,
  }) {
    return MatchFilterState(
      intent: intent ?? this.intent,
      city: city ?? this.city,
      radiusKm: radiusKm ?? this.radiusKm,
      selectedHobbies: selectedHobbies ?? this.selectedHobbies,
      gender: gender ?? this.gender,
    );
  }
}

class MatchFilterNotifier extends Notifier<MatchFilterState> {
  @override
  MatchFilterState build() => MatchFilterState();

  void setIntent(String intent) => state = state.copyWith(intent: intent);
  void setCity(String city) => state = state.copyWith(city: city);
  void setRadius(double radius) => state = state.copyWith(radiusKm: radius);
  void setGender(String gender) => state = state.copyWith(gender: gender);

  void toggleHobby(String hobby) {
    final currentHobbies = List<String>.from(state.selectedHobbies);
    if (currentHobbies.contains(hobby)) {
      currentHobbies.remove(hobby);
    } else {
      currentHobbies.add(hobby);
    }
    state = state.copyWith(selectedHobbies: currentHobbies);
  }
}

final matchFilterProvider = NotifierProvider<MatchFilterNotifier, MatchFilterState>(
  MatchFilterNotifier.new,
);

