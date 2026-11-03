import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../app/theme.dart';
import 'vip_provider.dart';
import 'vip_purchase_service.dart';

class VipPaywallScreen extends ConsumerStatefulWidget {
  const VipPaywallScreen({super.key});

  @override
  ConsumerState<VipPaywallScreen> createState() => _VipPaywallScreenState();
}

class _VipPaywallScreenState extends ConsumerState<VipPaywallScreen> {
  final VipPurchaseService _purchases = VipPurchaseService();
  String _selectedProductId = VipPurchaseService.monthlyId;
  bool _isLoading = true;
  bool _purchaseInProgress = false;

  @override
  void initState() {
    super.initState();
    _initializePurchases();
  }

  Future<void> _initializePurchases() async {
    await _purchases.initialize(
      onPurchaseGranted: _grantVipAccess,
      onPurchaseValidationFailed: _showValidationFailure,
    );
    if (mounted) setState(() => _isLoading = false);
  }

  void _grantVipAccess(PurchaseDetails purchase) {
    if (!VipPurchaseService.productIds.contains(purchase.productID)) return;
    // Receipt validation belongs on the backend before this local entitlement.
    ref.read(vipProvider.notifier).activateVip(purchase.productID);
    if (!mounted) return;
    setState(() => _purchaseInProgress = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('VIP is active. Enjoy your premium matching tools!'), backgroundColor: AppTheme.primaryCoral),
    );
    context.pop();
  }

  void _showValidationFailure(String message) {
    if (!mounted) return;
    setState(() => _purchaseInProgress = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _buySelectedPlan() async {
    final product = _purchases.productFor(_selectedProductId);
    if (product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_purchases.storeError ?? 'This VIP plan is not available yet.')),
      );
      return;
    }
    setState(() => _purchaseInProgress = true);
    final started = await _purchases.buy(product);
    if (mounted && !started) {
      setState(() => _purchaseInProgress = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Google Play could not start this purchase. Please try again.')));
    }
  }

  @override
  void dispose() {
    _purchases.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedPrice = _priceFor(_selectedProductId);
    return Scaffold(
      appBar: AppBar(
        title: const Text('StrangrChat VIP'),
        backgroundColor: AppTheme.warmIvory,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.close, color: AppTheme.mainText), onPressed: () => context.pop()),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(color: AppTheme.softBlush, shape: BoxShape.circle, border: Border.all(color: AppTheme.primaryCoral, width: 2)),
                child: const Icon(Icons.workspace_premium_rounded, size: 44, color: AppTheme.primaryCoral),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Find the match you want', textAlign: TextAlign.center, style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: AppTheme.mainText)),
            const SizedBox(height: 8),
            const Text('More control, fewer interruptions, and a better way to connect.', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.secondaryText)),
            const SizedBox(height: 28),
            const _Perk(icon: Icons.wc_rounded, title: 'Unlock gender filter', subtitle: 'Choose the people you want to meet.'),
            const _Perk(icon: Icons.location_on_rounded, title: 'Exact city matching', subtitle: 'Match with people in the city you select.'),
            const _Perk(icon: Icons.image_rounded, title: 'Unlimited images', subtitle: 'Share more of your conversation, without limits.'),
            const _Perk(icon: Icons.block_flipped, title: 'Ad-free usage', subtitle: 'Stay focused on the people, not interruptions.'),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(child: _PlanCard(
                selected: _selectedProductId == VipPurchaseService.pass48HoursId,
                title: '48-hour pass',
                price: _priceFor(VipPurchaseService.pass48HoursId),
                period: 'for 48 hours',
                onTap: () => setState(() => _selectedProductId = VipPurchaseService.pass48HoursId),
              )),
              const SizedBox(width: 12),
              Expanded(child: _PlanCard(
                selected: _selectedProductId == VipPurchaseService.monthlyId,
                title: 'Monthly VIP',
                price: _priceFor(VipPurchaseService.monthlyId),
                period: 'per month',
                badge: 'BEST VALUE',
                onTap: () => setState(() => _selectedProductId = VipPurchaseService.monthlyId),
              )),
            ]),
            const SizedBox(height: 16),
            if (_isLoading) const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator(color: AppTheme.primaryCoral)))
            else if (_purchases.storeError != null)
              Text(_purchases.storeError!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: AppTheme.secondaryText)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading || _purchaseInProgress ? null : _buySelectedPlan,
              child: _purchaseInProgress
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text('Continue with Google Play \u00B7 $selectedPrice'),
            ),
            const SizedBox(height: 14),
            const Text('Your purchase is processed securely by Google Play. Subscription terms and renewal details are shown before payment.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppTheme.secondaryText)),
            TextButton(onPressed: _isLoading ? null : _restorePurchases, child: const Text('Restore purchases')),
          ]),
        ),
      ),
    );
  }

  Future<void> _restorePurchases() async {
    await _purchases.restorePurchases();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Checking Google Play for previous purchases...')));
  }

  String _priceFor(String productId) => _purchases.productFor(productId)?.price ?? (productId == VipPurchaseService.pass48HoursId ? '\u20B949' : '\u20B9199');
}

class _Perk extends StatelessWidget {
  const _Perk({required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 15),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppTheme.softBlush, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: AppTheme.primaryCoral)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.mainText)),
            Text(subtitle, style: const TextStyle(fontSize: 13, color: AppTheme.secondaryText)),
          ])),
        ]),
      );
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.selected, required this.title, required this.price, required this.period, required this.onTap, this.badge});
  final bool selected;
  final String title;
  final String price;
  final String period;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        label: '$title, $price, $period',
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: selected ? AppTheme.primaryCoral : AppTheme.border, width: selected ? 2 : 1),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (badge != null) ...[
                Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: AppTheme.primaryCoral, borderRadius: BorderRadius.circular(5)), child: Text(badge!, style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold))),
                const SizedBox(height: 8),
              ] else
                const SizedBox(height: 22),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.secondaryText)),
              const SizedBox(height: 4),
              Text(price, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold, color: AppTheme.mainText)),
              Text(period, style: const TextStyle(fontSize: 12, color: AppTheme.secondaryText)),
            ]),
          ),
        ),
      );
}
