import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import 'match_filter_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  final List<String> _indianCities = const [
    'Mumbai', 'Delhi', 'Bengaluru', 'Hyderabad', 'Chennai', 'Kolkata', 'Pune', 'Ahmedabad'
  ];

  final List<String> _hobbiesList = const [
    'Music', 'Movies', 'Cricket', 'Gaming', 'Travel', 'Reading', 'Fitness', 'Foodie', 'Tech', 'Art'
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterState = ref.watch(matchFilterProvider);
    final filterNotifier = ref.read(matchFilterProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('StrangrChat Matchmaking'),
        backgroundColor: AppTheme.warmIvory,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.security, color: AppTheme.primaryCoral),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Zero-Storage & Safety Protection Enabled')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Intent Selector
            const Text(
              'What is your intent?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.mainText),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              children: [
                _buildIntentChip('FRIENDS', 'Friends', filterState, filterNotifier),
                _buildIntentChip('RELATIONSHIP', 'Relationship', filterState, filterNotifier),
                _buildIntentChip('MARRIED', 'Married', filterState, filterNotifier),
                _buildIntentChip('TIPS', 'Life Tips', filterState, filterNotifier),
              ],
            ),
            const SizedBox(height: 24),

            // Location Filter
            const Text(
              'Location & Distance',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.mainText),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: filterState.city,
                  isExpanded: true,
                  items: _indianCities.map((city) {
                    return DropdownMenuItem(value: city, child: Text(city));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) filterNotifier.setCity(val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Radius: ${filterState.radiusKm.toInt()} KM',
              style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.secondaryText),
            ),
            Slider(
              value: filterState.radiusKm,
              min: 5,
              max: 500,
              divisions: 99,
              activeColor: AppTheme.primaryCoral,
              inactiveColor: AppTheme.border,
              label: '${filterState.radiusKm.toInt()} KM',
              onChanged: (val) => filterNotifier.setRadius(val),
            ),
            const SizedBox(height: 24),

            // Hobbies Chip Wrap
            const Text(
              'Select Hobbies & Interests',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.mainText),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _hobbiesList.map((hobby) {
                final isSelected = filterState.selectedHobbies.contains(hobby);
                return ChoiceChip(
                  label: Text(hobby),
                  selected: isSelected,
                  selectedColor: AppTheme.softBlush,
                  backgroundColor: AppTheme.surface,
                  labelStyle: TextStyle(
                    color: isSelected ? AppTheme.primaryCoral : AppTheme.mainText,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (_) => filterNotifier.toggleHobby(hobby),
                );
              }).toList(),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/chat');
        },
        backgroundColor: AppTheme.primaryCoral,
        icon: const Icon(Icons.bolt_rounded, color: Colors.white),
        label: const Text('Find Partner', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildIntentChip(
      String value, String label, MatchFilterState state, MatchFilterNotifier notifier) {
    final isSelected = state.intent == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppTheme.primaryCoral,
      backgroundColor: AppTheme.surface,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppTheme.mainText,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (_) => notifier.setIntent(value),
    );
  }
}
