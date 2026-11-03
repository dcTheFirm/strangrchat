import 'package:flutter_riverpod/flutter_riverpod.dart';

class VipState {
  final bool isVip;
  final String? planType;
  final DateTime? expiresAt;

  VipState({
    this.isVip = false,
    this.planType,
    this.expiresAt,
  });

  VipState copyWith({
    bool? isVip,
    String? planType,
    DateTime? expiresAt,
  }) {
    return VipState(
      isVip: isVip ?? this.isVip,
      planType: planType ?? this.planType,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}

class VipNotifier extends Notifier<VipState> {
  @override
  VipState build() => VipState();

  void activateVip(String planType) {
    final now = DateTime.now();
    final expiry = planType == 'PASS_48H'
        ? now.add(const Duration(hours: 48))
        : now.add(const Duration(days: 30));
    state = VipState(isVip: true, planType: planType, expiresAt: expiry);
  }

  void revokeVip() {
    state = VipState(isVip: false);
  }
}

final vipProvider = NotifierProvider<VipNotifier, VipState>(
  VipNotifier.new,
);
