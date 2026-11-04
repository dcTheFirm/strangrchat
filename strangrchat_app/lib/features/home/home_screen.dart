import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/tokens.dart';
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

  int _selectedTab = 0;
  bool _showVipNudge = true;

  void _startMatching() {
    HapticFeedback.mediumImpact();
    final filters = ref.read(matchFilterProvider);
    unawaited(
      ref
          .read(chatProvider.notifier)
          .joinQueue(
            intent: filters.intent,
            preferredGender: filters.gender,
            city: filters.city,
          ),
    );
    context.push('/chat');
  }

  void _showSafetyInfo() {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: AppTokens.surface.withValues(alpha: 0),
      builder: (context) => const _SafetySheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTokens.space24,
                AppTokens.space8,
                AppTokens.space24,
                AppTokens.space8,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'strangrchat',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                              ),
                        ),
                        const SizedBox(height: AppTokens.space4),
                        Text(
                          _selectedTab == 0
                              ? 'MEET SOMEONE NEW'
                              : 'YOUR CONNECTIONS',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: AppTokens.textMuted,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.8,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: 'Safety information',
                    child: Material(
                      color: AppTokens.surface,
                      shape: const StadiumBorder(
                        side: BorderSide(color: AppTokens.outlineStrong),
                      ),
                      child: InkWell(
                        customBorder: const StadiumBorder(),
                        onTap: _showSafetyInfo,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTokens.space12,
                            vertical: AppTokens.space8,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.shield_outlined,
                                size: 18,
                                color: AppTokens.forest,
                              ),
                              const SizedBox(width: AppTokens.space8),
                              Text(
                                'Safety',
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(
                                      color: AppTokens.forest,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: IndexedStack(
                index: _selectedTab,
                children: [
                  _SmartMatchView(
                    onStart: _startMatching,
                    showVipNudge: _showVipNudge,
                    onDismissVipNudge: () =>
                        setState(() => _showVipNudge = false),
                  ),
                  const FriendsListScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _HomeDock(
        selectedTab: _selectedTab,
        onTabSelected: (index) {
          HapticFeedback.selectionClick();
          setState(() => _selectedTab = index);
        },
        onStart: _startMatching,
      ),
    );
  }
}

class _HomeDock extends StatelessWidget {
  const _HomeDock({
    required this.selectedTab,
    required this.onTabSelected,
    required this.onStart,
  });

  final int selectedTab;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppTokens.space24,
          AppTokens.space8,
          AppTokens.space24,
          AppTokens.space8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSize(
              duration: reduceMotion ? Duration.zero : AppTokens.base,
              curve: AppTokens.enter,
              child: selectedTab == 0
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: AppTokens.space12),
                      child: _FindSomeoneButton(onPressed: onStart),
                    )
                  : const SizedBox(width: double.infinity),
            ),
            _PillNavigation(
              selectedTab: selectedTab,
              onTabSelected: onTabSelected,
            ),
          ],
        ),
      ),
    );
  }
}

class _FindSomeoneButton extends StatefulWidget {
  const _FindSomeoneButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_FindSomeoneButton> createState() => _FindSomeoneButtonState();
}

class _FindSomeoneButtonState extends State<_FindSomeoneButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      button: true,
      label: 'Find someone to chat with',
      child: AnimatedScale(
        scale: _pressed && !reduceMotion ? 0.98 : 1,
        duration: AppTokens.fast,
        child: Material(
          color: AppTokens.forest,
          shape: const StadiumBorder(),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTapDown: (_) => setState(() => _pressed = true),
            onTapCancel: () => setState(() => _pressed = false),
            onTap: () {
              setState(() => _pressed = false);
              widget.onPressed();
            },
            child: LayoutBuilder(
              builder: (context, _) {
                final largeText =
                    MediaQuery.textScalerOf(context).scale(1) >= 1.5;
                final label = Text(
                  'Find someone',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTokens.onForest,
                    fontWeight: FontWeight.w700,
                  ),
                );
                final icon = const Icon(
                  Icons.north_east_rounded,
                  color: AppTokens.onForest,
                  size: AppTokens.iconMedium,
                );

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.space24,
                    vertical: AppTokens.space16,
                  ),
                  child: largeText
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            icon,
                            const SizedBox(height: AppTokens.space8),
                            label,
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            icon,
                            const SizedBox(width: AppTokens.space8),
                            label,
                          ],
                        ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _PillNavigation extends StatelessWidget {
  const _PillNavigation({
    required this.selectedTab,
    required this.onTabSelected,
  });

  final int selectedTab;
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = constraints.maxWidth / 2;
        final reduceMotion = MediaQuery.disableAnimationsOf(context);
        return Container(
          padding: const EdgeInsets.all(AppTokens.space4),
          decoration: BoxDecoration(
            color: AppTokens.surface,
            borderRadius: BorderRadius.circular(AppTokens.radius28),
            border: Border.all(color: AppTokens.outline),
          ),
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: reduceMotion ? Duration.zero : AppTokens.base,
                curve: AppTokens.move,
                left: itemWidth * selectedTab,
                top: 0,
                bottom: 0,
                width: itemWidth,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppTokens.sageSoft,
                    borderRadius: BorderRadius.circular(AppTokens.radius28),
                  ),
                ),
              ),
              Row(
                children: [
                  _NavigationItem(
                    label: 'Match',
                    icon: Icons.radio_button_checked_rounded,
                    selected: selectedTab == 0,
                    onTap: () => onTabSelected(0),
                  ),
                  _NavigationItem(
                    label: 'Friends',
                    icon: Icons.people_outline_rounded,
                    selected: selectedTab == 1,
                    onTap: () => onTabSelected(1),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppTokens.forest : AppTokens.textMuted;
    final largeText = MediaQuery.textScalerOf(context).scale(1) >= 1.5;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: Material(
          color: AppTokens.surface.withValues(alpha: 0),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppTokens.radius28),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppTokens.space8),
              child: largeText
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon, size: AppTokens.iconSmall, color: color),
                        const SizedBox(height: AppTokens.space4),
                        _NavigationLabel(label: label, color: color),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon, size: AppTokens.iconSmall, color: color),
                        const SizedBox(width: AppTokens.space8),
                        _NavigationLabel(label: label, color: color),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavigationLabel extends StatelessWidget {
  const _NavigationLabel({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedDefaultTextStyle(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : AppTokens.base,
      style: Theme.of(context).textTheme.labelLarge!
          .copyWith(color: color, fontWeight: FontWeight.w600),
      child: Text(label),
    );
  }
}

class _SmartMatchView extends ConsumerWidget {
  const _SmartMatchView({
    required this.onStart,
    required this.showVipNudge,
    required this.onDismissVipNudge,
  });

  final VoidCallback onStart;
  final bool showVipNudge;
  final VoidCallback onDismissVipNudge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(matchFilterProvider);
    final notifier = ref.read(matchFilterProvider.notifier);
    final isVip = ref.watch(vipProvider).isActive;

    return LayoutBuilder(
      builder: (context, constraints) {
        final orbSize = math.min(
          248.0,
          math.max(176.0, constraints.maxHeight * 0.38),
        );
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppTokens.space24,
            AppTokens.space8,
            AppTokens.space24,
            AppTokens.space16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Ready when you are',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: AppTokens.space8),
              Text(
                'Meet someone new, on your terms.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              SizedBox(height: orbSize * 0.04),
              Center(
                child: _Orb(size: orbSize, onTap: onStart),
              ),
              const SizedBox(height: AppTokens.space8),
              _FilterSummary(
                label: _filterSummary(filters),
                onTap: () => _openFilters(context),
              ),
              const SizedBox(height: AppTokens.space16),
              Text(
                'What sounds right today?',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppTokens.space8),
              _IntentSelector(
                selectedIntent: filters.intent,
                onChanged: notifier.setIntent,
              ),
              if (!isVip && showVipNudge) ...[
                const SizedBox(height: AppTokens.space12),
                _VipNudge(
                  onTap: () => context.push('/vip'),
                  onDismiss: onDismissVipNudge,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _openFilters(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: AppTokens.surface.withValues(alpha: 0),
      builder: (context) =>
          _MatchSettingsSheet(onVipRequired: () => context.push('/vip')),
    );
  }

  String _filterSummary(MatchFilterState filters) {
    final intent = switch (filters.intent) {
      'RELATIONSHIP' => 'Relationship',
      'MARRIED' => 'Married',
      'TIPS' => 'Life tips',
      _ => 'Friends',
    };
    final gender = switch (filters.gender) {
      'NON_BINARY' => 'Non-binary',
      'MALE' => 'Men',
      'FEMALE' => 'Women',
      _ => 'Anyone',
    };
    final location = filters.city == nearbyCityOption ? 'Nearby' : filters.city;
    final city = '$location · ${filters.radiusKm.toInt()} km';
    final interests = filters.selectedHobbies.isEmpty
        ? ''
        : ' · ${filters.selectedHobbies.length} ${filters.selectedHobbies.length == 1 ? 'interest' : 'interests'}';
    return '$intent · $gender · $city$interests';
  }
}

class _FilterSummary extends StatelessWidget {
  const _FilterSummary({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Match settings: $label',
      child: Material(
        color: AppTokens.surface,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppTokens.outline),
          borderRadius: BorderRadius.circular(AppTokens.radius20),
        ),
        child: InkWell(
          key: const Key('match-filter-summary'),
          borderRadius: BorderRadius.circular(AppTokens.radius20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.space16,
              vertical: AppTokens.space12,
            ),
            child: Row(
              children: [
                const Icon(Icons.tune_rounded, color: AppTokens.sage, size: 20),
                const SizedBox(width: AppTokens.space12),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTokens.text,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: AppTokens.space8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppTokens.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IntentSelector extends StatelessWidget {
  const _IntentSelector({
    required this.selectedIntent,
    required this.onChanged,
  });

  static const _intents = [
    ('FRIENDS', 'Friends'),
    ('RELATIONSHIP', 'Relationship'),
    ('MARRIED', 'Married'),
    ('TIPS', 'Life tips'),
  ];

  final String selectedIntent;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _intents.indexWhere(
      (intent) => intent.$1 == selectedIntent,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = constraints.maxWidth / _intents.length;
        final reduceMotion = MediaQuery.disableAnimationsOf(context);
        return Container(
          padding: const EdgeInsets.all(AppTokens.space4),
          decoration: BoxDecoration(
            color: AppTokens.surface,
            border: Border.all(color: AppTokens.outline),
            borderRadius: BorderRadius.circular(AppTokens.radius20),
          ),
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: reduceMotion ? Duration.zero : AppTokens.base,
                curve: AppTokens.move,
                left: itemWidth * selectedIndex,
                top: 0,
                bottom: 0,
                width: itemWidth,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppTokens.sageSoft,
                    borderRadius: BorderRadius.circular(AppTokens.radius12),
                  ),
                ),
              ),
              Row(
                children: [
                  for (final (value, label) in _intents)
                    Expanded(
                      child: Semantics(
                        button: true,
                        selected: selectedIntent == value,
                        label: label,
                        child: Material(
                          color: AppTokens.surface.withValues(alpha: 0),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(
                              AppTokens.radius12,
                            ),
                            onTap: () {
                              if (selectedIntent != value) {
                                HapticFeedback.selectionClick();
                                onChanged(value);
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTokens.space4,
                                vertical: AppTokens.space8,
                              ),
                              child: Center(
                                child: AnimatedDefaultTextStyle(
                                  duration: reduceMotion
                                      ? Duration.zero
                                      : AppTokens.base,
                                  style: Theme.of(context).textTheme.labelSmall!
                                      .copyWith(
                                        color: selectedIntent == value
                                            ? AppTokens.forest
                                            : AppTokens.textMuted,
                                        fontWeight: FontWeight.w600,
                                      ),
                                  child: Text(
                                    label,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Orb extends StatefulWidget {
  const _Orb({required this.size, required this.onTap});

  final double size;
  final VoidCallback onTap;

  @override
  State<_Orb> createState() => _OrbState();
}

class _OrbState extends State<_Orb> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _pressed = false;
  bool? _reducedMotion;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppTokens.orbBreath,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reducedMotion == reduceMotion) return;
    _reducedMotion = reduceMotion;
    if (reduceMotion) {
      _controller.stop();
    } else {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      button: true,
      label: 'Start matching with your selected filters',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: () {
          setState(() => _pressed = false);
          widget.onTap();
        },
        child: AnimatedScale(
          scale: _pressed && !reduceMotion ? 0.94 : 1,
          duration: reduceMotion ? Duration.zero : AppTokens.fast,
          child: RepaintBoundary(
            child: CustomPaint(
              size: Size.square(widget.size),
              painter: _OrbPainter(
                progress: _controller,
                sage: AppTokens.sage,
                sageLight: AppTokens.sageLight,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrbPainter extends CustomPainter {
  _OrbPainter({
    required this.progress,
    required this.sage,
    required this.sageLight,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final Color sage;
  final Color sageLight;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * 0.3;
    final breathe =
        1 + 0.04 * (0.5 - 0.5 * math.cos(progress.value * 2 * math.pi));
    final orbRadius = radius * breathe;
    final haloRadius = radius * 1.9;

    canvas.drawCircle(
      center,
      haloRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [sage.withValues(alpha: 0.13), sage.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: center, radius: haloRadius)),
    );
    canvas.drawCircle(
      center,
      orbRadius,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [sageLight, sage],
        ).createShader(Rect.fromCircle(center: center, radius: orbRadius)),
    );
    canvas.drawCircle(
      center.translate(-orbRadius * 0.2, -orbRadius * 0.28),
      orbRadius * 0.12,
      Paint()..color = AppTokens.surface.withValues(alpha: 0.28),
    );
  }

  @override
  bool shouldRepaint(_OrbPainter oldDelegate) =>
      oldDelegate.sage != sage || oldDelegate.sageLight != sageLight;
}

class _MatchSettingsSheet extends ConsumerWidget {
  const _MatchSettingsSheet({required this.onVipRequired});

  final VoidCallback onVipRequired;

  static const _genders = ['ANY', 'MALE', 'FEMALE', 'NON_BINARY'];
  static const _hobbies = [
    'Music',
    'Movies',
    'Cricket',
    'Gaming',
    'Travel',
    'Reading',
    'Fitness',
    'Foodie',
    'Tech',
    'Art',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(matchFilterProvider);
    final notifier = ref.read(matchFilterProvider.notifier);
    final isVip = ref.watch(vipProvider).isActive;

    return Container(
      decoration: BoxDecoration(
        color: AppTokens.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTokens.radius28),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppTokens.space24,
          AppTokens.space12,
          AppTokens.space24,
          AppTokens.space32,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: AppTokens.sheetHandleWidth,
                height: AppTokens.space4,
                decoration: BoxDecoration(
                  color: AppTokens.outline,
                  borderRadius: BorderRadius.circular(AppTokens.radius12),
                ),
              ),
            ),
            const SizedBox(height: AppTokens.space24),
            Text(
              'Match settings',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppTokens.space4),
            Text(
              'Choose what feels right for this conversation.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppTokens.space24),
            _FilterSectionTitle(
              title: 'Gender',
              accessory: isVip ? null : 'VIP',
            ),
            const SizedBox(height: AppTokens.space12),
            Wrap(
              spacing: AppTokens.space8,
              runSpacing: AppTokens.space8,
              children: [
                for (final gender in _genders)
                  _FilterChip(
                    label: _genderLabel(gender),
                    selected: filters.gender == gender,
                    locked: gender != 'ANY' && !isVip,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      if (!notifier.setGender(gender)) onVipRequired();
                    },
                  ),
              ],
            ),
            const SizedBox(height: AppTokens.space24),
            _FilterSectionTitle(title: 'City', accessory: isVip ? null : 'VIP'),
            const SizedBox(height: AppTokens.space12),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.space16,
              ),
              decoration: BoxDecoration(
                color: AppTokens.surface,
                borderRadius: BorderRadius.circular(AppTokens.radius20),
                border: Border.all(color: AppTokens.outlineStrong),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: filters.city,
                  isExpanded: true,
                  borderRadius: BorderRadius.circular(AppTokens.radius20),
                  icon: const Icon(
                    Icons.expand_more_rounded,
                    color: AppTokens.forest,
                  ),
                  items: _HomeScreenState._cities
                      .map(
                        (city) => DropdownMenuItem(
                          value: city,
                          child: Row(
                            children: [
                              Expanded(child: Text(city)),
                              if (city != nearbyCityOption && !isVip)
                                const Icon(
                                  Icons.lock_outline_rounded,
                                  size: 16,
                                  color: AppTokens.sage,
                                ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (city) {
                    if (city != null && !notifier.setCity(city)) {
                      onVipRequired();
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: AppTokens.space24),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Distance',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  '${filters.radiusKm.toInt()} km',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppTokens.forest,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppTokens.forest,
                inactiveTrackColor: AppTokens.sageSoft,
                thumbColor: AppTokens.forest,
                overlayColor: AppTokens.sage.withValues(alpha: 0.12),
                trackHeight: 4,
              ),
              child: Slider(
                value: filters.radiusKm,
                min: 5,
                max: 500,
                divisions: 99,
                onChanged: notifier.setRadius,
                onChangeEnd: (_) => HapticFeedback.selectionClick(),
              ),
            ),
            const SizedBox(height: AppTokens.space16),
            Text('Interests', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppTokens.space4),
            Text(
              'Pick a few things you enjoy.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppTokens.space12),
            Wrap(
              spacing: AppTokens.space8,
              runSpacing: AppTokens.space8,
              children: [
                for (final hobby in _hobbies)
                  _FilterChip(
                    label: hobby,
                    selected: filters.selectedHobbies.contains(hobby),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      notifier.toggleHobby(hobby);
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _genderLabel(String gender) => switch (gender) {
    'ANY' => 'Anyone',
    'NON_BINARY' => 'Non-binary',
    _ => '${gender[0]}${gender.substring(1).toLowerCase()}',
  };
}

class _FilterSectionTitle extends StatelessWidget {
  const _FilterSectionTitle({required this.title, this.accessory});

  final String title;
  final String? accessory;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        if (accessory != null) ...[
          const SizedBox(width: AppTokens.space8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.space8,
              vertical: AppTokens.space4,
            ),
            decoration: BoxDecoration(
              color: AppTokens.sageSoft,
              borderRadius: BorderRadius.circular(AppTokens.radius12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_outline_rounded,
                  size: 12,
                  color: AppTokens.forest,
                ),
                const SizedBox(width: AppTokens.space4),
                Text(
                  accessory!,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTokens.forest,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.locked = false,
  });

  final String label;
  final bool selected;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      button: true,
      selected: selected,
      label: locked ? '$label, VIP option' : label,
      child: AnimatedScale(
        scale: selected ? 1 : 0.98,
        duration: reduceMotion ? Duration.zero : AppTokens.base,
        curve: AppTokens.enter,
        child: Material(
          color: selected ? AppTokens.sageSoft : AppTokens.surface,
          shape: RoundedRectangleBorder(
            side: BorderSide(
              color: selected ? AppTokens.outlineStrong : AppTokens.outline,
            ),
            borderRadius: BorderRadius.circular(AppTokens.radius12),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppTokens.radius12),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.space12,
                vertical: AppTokens.space8,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: selected ? AppTokens.forest : AppTokens.text,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (locked) ...[
                    const SizedBox(width: AppTokens.space4),
                    const Icon(
                      Icons.lock_outline_rounded,
                      size: 14,
                      color: AppTokens.sage,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VipNudge extends StatelessWidget {
  const _VipNudge({required this.onTap, required this.onDismiss});

  final VoidCallback onTap;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Material(
      color: AppTokens.surfaceHigh,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppTokens.outline),
        borderRadius: BorderRadius.circular(AppTokens.radius20),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTokens.radius20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTokens.space12,
            AppTokens.space8,
            AppTokens.space8,
            AppTokens.space8,
          ),
          child: Row(
            children: [
              _VipNudgeIcon(reduceMotion: reduceMotion),
              const SizedBox(width: AppTokens.space8),
              Expanded(
                child: Text(
                  'More ways to find your kind of conversation',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTokens.text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Dismiss VIP offer',
                visualDensity: VisualDensity.compact,
                onPressed: onDismiss,
                icon: const Icon(Icons.close_rounded, size: 18),
                color: AppTokens.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VipNudgeIcon extends StatelessWidget {
  const _VipNudgeIcon({required this.reduceMotion});

  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    const icon = Icon(
      Icons.tune_rounded,
      color: AppTokens.sage,
      size: AppTokens.iconMedium,
    );
    if (reduceMotion) return icon;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppTokens.slow,
      child: icon,
      builder: (context, progress, child) {
        final shift = -1.5 + 3 * progress;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment(shift - 0.5, 0),
            end: Alignment(shift + 0.5, 0),
            colors: [AppTokens.sage, AppTokens.surface, AppTokens.sage],
          ).createShader(bounds),
          child: child,
        );
      },
    );
  }
}

class _SafetySheet extends StatelessWidget {
  const _SafetySheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.space24,
        AppTokens.space12,
        AppTokens.space24,
        AppTokens.space32,
      ),
      decoration: const BoxDecoration(
        color: AppTokens.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTokens.radius28),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: AppTokens.sheetHandleWidth,
              height: AppTokens.space4,
              decoration: BoxDecoration(
                color: AppTokens.outline,
                borderRadius: BorderRadius.circular(AppTokens.radius12),
              ),
            ),
          ),
          const SizedBox(height: AppTokens.space24),
          Row(
            children: [
              const Icon(
                Icons.shield_outlined,
                color: AppTokens.forest,
                size: 24,
              ),
              const SizedBox(width: AppTokens.space12),
              Text(
                'Your comfort comes first',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space12),
          Text(
            'Keep personal details private. You can leave a conversation at any time if it does not feel right.',
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: AppTokens.text),
          ),
          const SizedBox(height: AppTokens.space24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: AppTokens.forest,
                foregroundColor: AppTokens.onForest,
                padding: const EdgeInsets.symmetric(
                  vertical: AppTokens.space16,
                ),
              ),
              child: const Text('Got it'),
            ),
          ),
        ],
      ),
    );
  }
}
