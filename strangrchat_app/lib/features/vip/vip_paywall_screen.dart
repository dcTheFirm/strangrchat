import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../app/sticker_avatar.dart';
import '../../app/tokens.dart';
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
  String? _purchaseLoadError;

  @override
  void initState() {
    super.initState();
    _initializePurchases();
  }

  Future<void> _initializePurchases() async {
    try {
      await _purchases.initialize(
        onPurchaseGranted: _grantVipAccess,
        onPurchaseValidationFailed: _showValidationFailure,
      );
    } catch (error) {
      _purchaseLoadError = 'Google Play plans could not be loaded.';
      debugPrint('VIP purchase initialization failed: $error');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _grantVipAccess(PurchaseDetails purchase) {
    if (!VipPurchaseService.productIds.contains(purchase.productID)) return;
    // The purchase service invokes this callback only after server validation.
    ref.read(vipProvider.notifier).activateVip(purchase.productID);
    if (!mounted) return;
    setState(() => _purchaseInProgress = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('VIP is active. Enjoy your premium matching tools!'),
        backgroundColor: AppTheme.primaryCoral,
      ),
    );
    context.pop();
  }

  void _showValidationFailure(String message) {
    if (!mounted) return;
    setState(() => _purchaseInProgress = false);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _buySelectedPlan() async {
    final product = _purchases.productFor(_selectedProductId);
    if (product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _purchases.storeError ?? 'This VIP plan is not available yet.',
          ),
        ),
      );
      return;
    }
    setState(() => _purchaseInProgress = true);
    final started = await _purchases.buy(product);
    if (mounted && !started) {
      setState(() => _purchaseInProgress = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Google Play could not start this purchase. Please try again.',
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _purchases.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedProduct = _purchases.productFor(_selectedProductId);
    final selectedPrice = selectedProduct?.price ?? 'Not available';
    return Scaffold(
      appBar: AppBar(
        title: const Text('StrangrChat VIP'),
        backgroundColor: AppTokens.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppTheme.mainText),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTokens.peach, AppTokens.lavender],
                    ),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: const StickerAvatar(variant: 2, size: 78),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Membership plans',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.mainText,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose a plan offered by Google Play. Access is enabled only after server validation.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.secondaryText),
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTokens.surfaceHigh,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTokens.line),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.verified_user_outlined,
                      color: AppTokens.coralDeep,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Membership access is enabled only after the server verifies a Google Play purchase. Matching features are not available until the server confirms them.',
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: AppTokens.ink),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, constraints) {
                  final passCard = _PlanCard(
                    key: const Key('vip-plan-48-hours'),
                    selected:
                        _selectedProductId == VipPurchaseService.pass48HoursId,
                    title: '48-hour pass',
                    price: _priceFor(VipPurchaseService.pass48HoursId),
                    period: 'for 48 hours',
                    onTap: () => setState(
                      () =>
                          _selectedProductId = VipPurchaseService.pass48HoursId,
                    ),
                  );
                  final monthlyCard = _PlanCard(
                    key: const Key('vip-plan-monthly'),
                    selected:
                        _selectedProductId == VipPurchaseService.monthlyId,
                    title: 'Monthly membership',
                    price: _priceFor(VipPurchaseService.monthlyId),
                    period: 'per month',
                    onTap: () => setState(
                      () => _selectedProductId = VipPurchaseService.monthlyId,
                    ),
                  );

                  if (constraints.maxWidth < 480) {
                    return Column(
                      children: [
                        passCard,
                        const SizedBox(height: 12),
                        monthlyCard,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: passCard),
                      const SizedBox(width: 12),
                      Expanded(child: monthlyCard),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryCoral,
                    ),
                  ),
                )
              else if (_purchaseLoadError != null)
                Text(
                  _purchaseLoadError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.secondaryText,
                  ),
                )
              else if (_purchases.storeError != null)
                Text(
                  _purchases.storeError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.secondaryText,
                  ),
                ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed:
                    _isLoading || _purchaseInProgress || selectedProduct == null
                    ? null
                    : _buySelectedPlan,
                child: _purchaseInProgress
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text('Continue with Google Play \u00B7 $selectedPrice'),
              ),
              const SizedBox(height: 14),
              const Text(
                'Your purchase is processed securely by Google Play. Subscription terms and renewal details are shown before payment.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppTheme.secondaryText),
              ),
              TextButton(
                onPressed: _isLoading ? null : _restorePurchases,
                child: const Text('Restore purchases'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _restorePurchases() async {
    await _purchases.restorePurchases();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Checking Google Play for previous purchases...'),
        ),
      );
    }
  }

  String _priceFor(String productId) =>
      _purchases.productFor(productId)?.price ?? 'Not available';
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    super.key,
    required this.selected,
    required this.title,
    required this.price,
    required this.period,
    required this.onTap,
  });
  final bool selected;
  final String title;
  final String price;
  final String period;
  final VoidCallback onTap;

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
          border: Border.all(
            color: selected ? AppTheme.primaryCoral : AppTheme.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 22),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.secondaryText,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              price,
              style: const TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
                color: AppTheme.mainText,
              ),
            ),
            Text(
              period,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.secondaryText,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
