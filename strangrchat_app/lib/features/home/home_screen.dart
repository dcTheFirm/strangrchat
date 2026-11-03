import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../friends/friends_list_screen.dart';
import '../random_chat/chat_provider.dart';
import '../vip/vip_provider.dart';
import 'match_filter_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const _cities = [
    nearbyCityOption,
    'Mumbai',
    'Delhi',
    'Bengaluru',
    'Hyderabad',
    'Chennai',
    'Kolkata',
    'Pune',
    'Ahmedabad',
  ];
  static const _hobbies = ['Music', 'Movies', 'Cricket', 'Gaming', 'Travel', 'Reading', 'Fitness', 'Foodie', 'Tech', 'Art'];
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final titles = ['Smart Match', 'Friends'];
    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_selectedTab]),
        backgroundColor: AppTheme.warmIvory,
        elevation: 0,
        actions: [
          if (_selectedTab == 0)
            IconButton(
              tooltip: 'Safety protection',
              icon: const Icon(Icons.security, color: AppTheme.primaryCoral),
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Zero-Storage & Safety Protection Enabled'))),
            ),
        ],
      ),
      body: IndexedStack(index: _selectedTab, children: const [_SmartMatchView(), FriendsListScreen()]),
      floatingActionButton: _selectedTab == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                final filters = ref.read(matchFilterProvider);
                unawaited(ref.read(chatProvider.notifier).joinQueue(
                      intent: filters.intent,
                      preferredGender: filters.gender,
                      city: filters.city,
                    ));
                context.push('/chat');
              },
              backgroundColor: AppTheme.primaryCoral,
              icon: const Icon(Icons.bolt_rounded, color: Colors.white),
              label: const Text('Find Partner', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: (index) => setState(() => _selectedTab = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.auto_awesome_outlined), selectedIcon: Icon(Icons.auto_awesome), label: 'Smart Match'),
          NavigationDestination(icon: Icon(Icons.people_outline_rounded), selectedIcon: Icon(Icons.people_rounded), label: 'Friends'),
        ],
      ),
    );
  }
}

class _SmartMatchView extends ConsumerWidget {
  const _SmartMatchView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(matchFilterProvider);
    final notifier = ref.read(matchFilterProvider.notifier);
    final isVip = ref.watch(vipProvider).isActive;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 112),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (!isVip) _VipNudge(onTap: () => context.push('/vip')),
        const Text('What is your intent?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            _intentChip('FRIENDS', 'Friends', filters, notifier),
            _intentChip('RELATIONSHIP', 'Relationship', filters, notifier),
            _intentChip('MARRIED', 'Married', filters, notifier),
            _intentChip('TIPS', 'Life Tips', filters, notifier),
          ],
        ),
        const SizedBox(height: 24),
        _sectionTitle('Gender preference', premium: true),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['ANY', 'MALE', 'FEMALE', 'NON_BINARY'].map((gender) {
            final selected = filters.gender == gender;
            return ChoiceChip(
              label: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(_genderLabel(gender)),
                if (gender != 'ANY' && !isVip) const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.lock_outline, size: 14)),
              ]),
              selected: selected,
              selectedColor: AppTheme.softBlush,
              onSelected: (_) {
                if (!notifier.setGender(gender)) context.push('/vip');
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        _sectionTitle('Location & distance', premium: true),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.border)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: filters.city,
              isExpanded: true,
              items: _HomeScreenState._cities.map((city) => DropdownMenuItem(
                value: city,
                child: Row(children: [
                  Expanded(child: Text(city)),
                  if (city != nearbyCityOption && !isVip) const Icon(Icons.lock_outline, size: 16, color: AppTheme.secondaryText),
                ]),
              )).toList(),
              onChanged: (city) {
                if (city != null && !notifier.setCity(city)) context.push('/vip');
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Radius: ${filters.radiusKm.toInt()} km', style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.secondaryText)),
        Slider(
          value: filters.radiusKm,
          min: 5,
          max: 500,
          divisions: 99,
          activeColor: AppTheme.primaryCoral,
          inactiveColor: AppTheme.border,
          label: '${filters.radiusKm.toInt()} km',
          onChanged: notifier.setRadius,
        ),
        const SizedBox(height: 24),
        const Text('Select hobbies & interests', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _HomeScreenState._hobbies.map((hobby) {
            final selected = filters.selectedHobbies.contains(hobby);
            return ChoiceChip(label: Text(hobby), selected: selected, selectedColor: AppTheme.softBlush, onSelected: (_) => notifier.toggleHobby(hobby));
          }).toList(),
        ),
      ]),
    );
  }

  ChoiceChip _intentChip(String value, String label, MatchFilterState state, MatchFilterNotifier notifier) {
    final selected = state.intent == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: AppTheme.primaryCoral,
      labelStyle: TextStyle(color: selected ? Colors.white : AppTheme.mainText, fontWeight: selected ? FontWeight.bold : FontWeight.normal),
      onSelected: (_) => notifier.setIntent(value),
    );
  }

  String _genderLabel(String gender) => switch (gender) {
        'ANY' => 'Anyone',
        'NON_BINARY' => 'Non-binary',
        _ => '${gender[0]}${gender.substring(1).toLowerCase()}',
      };

  Widget _sectionTitle(String title, {bool premium = false}) => Row(children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        if (premium) ...[const SizedBox(width: 7), const Icon(Icons.workspace_premium_outlined, color: AppTheme.primaryCoral, size: 19)],
      ]);
}

class _VipNudge extends StatelessWidget {
  const _VipNudge({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Material(
          color: AppTheme.softBlush,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: const Padding(
              padding: EdgeInsets.all(14),
              child: Row(children: [
                Icon(Icons.workspace_premium_rounded, color: AppTheme.primaryCoral),
                SizedBox(width: 10),
                Expanded(child: Text('Get VIP for exact matches, gender preferences, and more.', style: TextStyle(fontWeight: FontWeight.w600))),
                Icon(Icons.chevron_right_rounded),
              ]),
            ),
          ),
        ),
      );
}
