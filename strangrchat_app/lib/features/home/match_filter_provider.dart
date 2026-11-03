import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../vip/vip_provider.dart';

/// The free matching mode stays broad; precise locations are a VIP benefit.
const String nearbyCityOption = 'Nearby (any city)';

class MatchFilterState {
  final String intent; // 'FRIENDS', 'RELATIONSHIP', 'MARRIED', 'TIPS'
  final String city;
  final double radiusKm;
  final List<String> selectedHobbies;
  final String gender;

  MatchFilterState({
    this.intent = 'FRIENDS',
    this.city = nearbyCityOption,
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

  /// Returns false when selecting an exact city requires VIP.
  bool setCity(String city) {
    if (city != nearbyCityOption && !ref.read(vipProvider).isActive) return false;
    state = state.copyWith(city: city);
    return true;
  }
  void setRadius(double radius) => state = state.copyWith(radiusKm: radius);
  /// Returns false when selecting a specific gender requires VIP.
  bool setGender(String gender) {
    if (gender != 'ANY' && !ref.read(vipProvider).isActive) return false;
    state = state.copyWith(gender: gender);
    return true;
  }

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

