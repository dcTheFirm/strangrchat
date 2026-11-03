import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import 'vip_provider.dart';

class VipPaywallScreen extends ConsumerStatefulWidget {
  const VipPaywallScreen({super.key});

  @override
  ConsumerState<VipPaywallScreen> createState() => _VipPaywallScreenState();
}

class _VipPaywallScreenState extends ConsumerState<VipPaywallScreen> {
  String _selectedPlan = 'MONTHLY'; // '48H' or 'MONTHLY'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('StrangrChat VIP'),
        backgroundColor: AppTheme.warmIvory,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppTheme.mainText),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Banner / Crown
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.softBlush,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.primaryCoral, width: 2),
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    size: 44,
                    color: AppTheme.primaryCoral,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Unlock Ultimate Matching & Freedom',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.mainText,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Get exact matches, gender filter, unlimited images & priority queue.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.secondaryText,
                ),
              ),
              const SizedBox(height: 32),

              // Perks List
              _buildPerkItem(Icons.wc_rounded, 'Specific Gender Filter', 'Choose exactly who you want to talk to.'),
              _buildPerkItem(Icons.location_on_rounded, 'Exact City Matching', 'Connect with verified users in your city.'),
              _buildPerkItem(Icons.image_rounded, 'Unlimited Image Sharing', 'Share high-quality photos safely.'),
              _buildPerkItem(Icons.bolt_rounded, 'Priority Matchmaking & Ad-free', 'Skip waiting queues instantly.'),
              const SizedBox(height: 32),

              // Plan Selection Cards
              Row(
                children: [
                  Expanded(
                    child: _buildPlanCard(
                      title: '48-Hour Pass',
                      price: '₹49',
                      period: '48 hours',
                      planKey: '48H',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildPlanCard(
                      title: 'Monthly VIP',
                      price: '₹199',
                      period: 'per month',
                      planKey: 'MONTHLY',
                      badge: 'BEST VALUE',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Subscribe Button
              ElevatedButton(
                onPressed: () {
                  ref.read(vipProvider.notifier).activateVip(_selectedPlan);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('VIP Unlocked Successfully! Enjoy premium perks.'),
                      backgroundColor: AppTheme.primaryCoral,
                    ),
                  );
                  context.pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryCoral,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  _selectedPlan == 'MONTHLY' ? 'Unlock Monthly VIP - ₹199' : 'Unlock 48-Hour Pass - ₹49',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Recurring billing. Cancel anytime from Google Play Store settings.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppTheme.secondaryText),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPerkItem(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.softBlush,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.primaryCoral, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.mainText),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 13, color: AppTheme.secondaryText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String price,
    required String period,
    required String planKey,
    String? badge,
  }) {
    final isSelected = _selectedPlan == planKey;
    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = planKey),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryCoral : AppTheme.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppTheme.primaryCoral.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (badge != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryCoral,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              const SizedBox(height: 8),
            ] else
              const SizedBox(height: 22),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.secondaryText),
            ),
            const SizedBox(height: 4),
            Text(
              price,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: AppTheme.mainText),
            ),
            const SizedBox(height: 2),
            Text(
              period,
              style: const TextStyle(fontSize: 12, color: AppTheme.secondaryText),
            ),
          ],
        ),
      ),
    );
  }
}
