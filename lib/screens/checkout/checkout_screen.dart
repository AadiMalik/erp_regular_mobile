import 'dart:io';

import 'package:dio/dio.dart' show MultipartFile;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../models/address.dart';
import '../../providers/auth_provider.dart';
import '../../providers/branch_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/orders_service.dart';
import '../../services/website_settings_service.dart';
import '../../services/cart_service.dart';
import '../orders/orders_screen.dart';
import 'location_picker_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  late final _nameCtrl = TextEditingController(text: context.read<AuthProvider>().user?['name']);
  late final _emailCtrl = TextEditingController(text: context.read<AuthProvider>().user?['email']);
  late final _phoneCtrl = TextEditingController(text: context.read<AuthProvider>().user?['phone']);
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _paymentReferenceCtrl = TextEditingController();
  LatLng? _location;
  List<Map<String, dynamic>> _paymentMethods = [];
  String? _selectedMethodCode;
  File? _receiptImage;
  bool _useLoyaltyPoints = false;
  bool _placing = false;
  bool _loadingMethods = true;
  String? _methodsError;
  String? _error;

  // Distance-based delivery fee for the picked location - resolved against
  // the branch's Delivery Zones, separate from the (currently always-0)
  // flat `cart.totals.shipping` the cart API returns.
  bool _checkingDelivery = false;
  double? _deliveryFee; // null = not checked yet
  bool _deliveryFree = false;
  bool _deliveryOutOfArea = false;
  String? _deliveryMessage;

  bool get _isBankTransfer => _selectedMethodCode == 'bank_transfer';

  @override
  void initState() {
    super.initState();
    _prefillFromSavedAddress();
    _loadPaymentMethods();
  }

  Future<void> _loadPaymentMethods() async {
    setState(() {
      _loadingMethods = true;
      _methodsError = null;
    });
    final res = await OrdersService.fetchPaymentMethods();
    if (!mounted) return;
    if (!res.success) {
      setState(() {
        _loadingMethods = false;
        _methodsError = res.message ?? 'Could not load payment methods.';
        _paymentMethods = [];
        _selectedMethodCode = null;
      });
      return;
    }
    final list = (res.data?['methods'] as List?) ?? [];
    setState(() {
      _loadingMethods = false;
      _paymentMethods = list.cast<Map<String, dynamic>>();
      _selectedMethodCode = _paymentMethods.isNotEmpty ? '${_paymentMethods.first['code']}' : null;
      _methodsError = _paymentMethods.isEmpty ? 'No payment methods are available right now.' : null;
    });
  }

  void _prefillFromSavedAddress() {
    final raw = (context.read<AuthProvider>().user?['addresses'] as List?) ?? [];
    if (raw.isEmpty) return;
    final addresses = raw.map((e) => Address.fromJson(e as Map<String, dynamic>)).toList();
    final def = addresses.firstWhere((a) => a.isDefault, orElse: () => addresses.first);
    _addressCtrl.text = def.address;
    _cityCtrl.text = def.city ?? '';
    _countryCtrl.text = def.country ?? '';
    if (def.phone != null && def.phone!.isNotEmpty) _phoneCtrl.text = def.phone!;
  }

  Future<void> _pickLocation() async {
    final picked = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(builder: (_) => LocationPickerScreen(initial: _location)),
    );
    if (picked != null) {
      setState(() => _location = picked);
      await _verifyDelivery();
    }
  }

  Future<void> _verifyDelivery() async {
    final loc = _location;
    if (loc == null) return;
    setState(() {
      _checkingDelivery = true;
      _deliveryOutOfArea = false;
      _deliveryMessage = null;
    });
    final res = await OrdersService.verifyDeliveryAddress(
      latitude: loc.latitude,
      longitude: loc.longitude,
      branchId: context.read<BranchProvider>().selectedId,
    );
    if (!mounted) return;

    if (!res.success || res.data == null) {
      // Verification itself failing (network/branch not found) shouldn't
      // block checkout - placeOrder() re-validates server-side either way.
      setState(() {
        _checkingDelivery = false;
        _deliveryFee = null;
        _deliveryFree = false;
      });
      return;
    }

    final inArea = res.data!['in_area'] == true;
    if (!inArea) {
      setState(() {
        _checkingDelivery = false;
        _deliveryOutOfArea = true;
        _deliveryMessage = '${res.data!['message'] ?? 'Sorry, this address is out of our delivery area.'}';
        _deliveryFee = null;
        _deliveryFree = false;
      });
      return;
    }

    setState(() {
      _checkingDelivery = false;
      _deliveryFee = (res.data!['delivery_fee'] as num?)?.toDouble() ?? 0;
      _deliveryFree = res.data!['free'] == true;
    });
  }

  Future<void> _pickReceipt() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    setState(() => _receiptImage = File(picked.path));
  }

  bool get _hasOutOfStockItems => context.read<CartProvider>().items.any((i) => !i.inStock);

  Future<void> _placeOrder() async {
    if ([_nameCtrl, _emailCtrl, _phoneCtrl, _addressCtrl, _cityCtrl, _countryCtrl].any((c) => c.text.trim().isEmpty) ||
        _selectedMethodCode == null) {
      setState(() => _error = 'Please fill in all required fields and choose a payment method.');
      return;
    }
    if (_isBankTransfer && _receiptImage == null) {
      setState(() => _error = 'Please upload your payment receipt for bank transfer.');
      return;
    }
    if (_location == null) {
      setState(() => _error = 'Please pin your delivery location on the map.');
      return;
    }
    if (_deliveryOutOfArea) {
      setState(() => _error = _deliveryMessage ?? 'Sorry, this address is out of our delivery area.');
      return;
    }
    if (_hasOutOfStockItems) {
      setState(() => _error = 'One or more items in your cart are out of stock. Please remove them to continue.');
      return;
    }
    setState(() {
      _placing = true;
      _error = null;
    });
    final res = await OrdersService.placeOrder({
      'full_name': _nameCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'address': _addressCtrl.text.trim(),
      'city': _cityCtrl.text.trim(),
      'country': _countryCtrl.text.trim(),
      'latitude': _location!.latitude,
      'longitude': _location!.longitude,
      if (_notesCtrl.text.trim().isNotEmpty) 'notes': _notesCtrl.text.trim(),
      'payment_code': _selectedMethodCode!,
      if (context.read<BranchProvider>().selectedId != null) 'branch_id': context.read<BranchProvider>().selectedId!,
      if (_isBankTransfer && _paymentReferenceCtrl.text.trim().isNotEmpty) 'payment_reference': _paymentReferenceCtrl.text.trim(),
      if (_isBankTransfer && _receiptImage != null)
        'payment_receipt': await MultipartFile.fromFile(_receiptImage!.path, filename: _receiptImage!.path.split(Platform.pathSeparator).last),
      if (_useLoyaltyPoints) 'use_loyalty_points': true,
    });
    if (!mounted) return;
    setState(() => _placing = false);
    if (res.success) {
      await context.read<CartProvider>().load(branchId: context.read<BranchProvider>().selectedId);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const OrdersScreen()), (r) => r.isFirst);
    } else {
      // A rejection is very often a stock race (another order/POS sale took
      // the last unit between screen-load and submit) - refresh the cart so
      // the shopper sees corrected stock instead of resubmitting stale data.
      await context.read<CartProvider>().load(branchId: context.read<BranchProvider>().selectedId);
      if (!mounted) return;
      setState(() => _error = res.message ?? 'Failed to place order.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final money = context.watch<SettingsProvider>().money;
    final cart = context.watch<CartProvider>();
    final total = cart.totals.total + (_deliveryFee ?? 0);
    final hasOutOfStock = cart.items.any((i) => !i.inStock);
    final bank = context.watch<SettingsProvider>().settings.bankDetails;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Contact Details', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Full name')),
          const SizedBox(height: 10),
          TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email'), keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 10),
          TextField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'Phone'), keyboardType: TextInputType.phone),
          const SizedBox(height: 20),
          const Text('Delivery Address', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          TextField(controller: _addressCtrl, decoration: const InputDecoration(labelText: 'Street address'), maxLines: 2),
          const SizedBox(height: 10),
          TextField(controller: _cityCtrl, decoration: const InputDecoration(labelText: 'City')),
          const SizedBox(height: 10),
          TextField(controller: _countryCtrl, decoration: const InputDecoration(labelText: 'Country')),
          const SizedBox(height: 10),
          TextField(controller: _notesCtrl, decoration: const InputDecoration(labelText: 'Order notes (optional)'), maxLines: 2),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _pickLocation,
            icon: const Icon(Icons.location_on_outlined, size: 18),
            label: Text(
              _location == null
                  ? 'Pick Delivery Location on Map'
                  : 'Location: ${_location!.latitude.toStringAsFixed(5)}, ${_location!.longitude.toStringAsFixed(5)}',
            ),
          ),
          const SizedBox(height: 20),
          const Text('Payment Method', style: TextStyle(fontWeight: FontWeight.w700)),
          if (_loadingMethods)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_methodsError != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_methodsError!, style: const TextStyle(color: Colors.red)),
                  TextButton(onPressed: _loadPaymentMethods, child: const Text('Retry')),
                ],
              ),
            )
          else
            ..._paymentMethods.map((m) {
              final code = '${m['code']}';
              return RadioListTile<String>(
                value: code,
                groupValue: _selectedMethodCode,
                onChanged: (v) => setState(() => _selectedMethodCode = v),
                title: Text('${m['name'] ?? code}'),
                contentPadding: EdgeInsets.zero,
              );
            }),
          if (_isBankTransfer) ...[
            const SizedBox(height: 8),
            _BankDetailsCard(bank: bank),
            const SizedBox(height: 12),
            TextField(controller: _paymentReferenceCtrl, decoration: const InputDecoration(labelText: 'Transaction / Reference No. (optional)')),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickReceipt,
              icon: const Icon(Icons.upload_file_outlined, size: 18),
              label: Text(_receiptImage == null ? 'Upload Payment Receipt' : 'Receipt selected — tap to change'),
            ),
            if (_receiptImage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(_receiptImage!, height: 120)),
              ),
          ],
          const SizedBox(height: 12),
          CheckboxListTile(
            value: _useLoyaltyPoints,
            onChanged: (v) => setState(() => _useLoyaltyPoints = v ?? false),
            title: const Text('Use Loyalty Points'),
            subtitle: const Text('Automatically apply your available points as a discount on this order.'),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          if (hasOutOfStock) ...[
            const SizedBox(height: 10),
            const Text(
              'One or more items in your cart are out of stock. Go back to your cart to remove them before placing this order.',
              style: TextStyle(color: Colors.red, fontSize: 12.5),
            ),
          ],
          if (_deliveryOutOfArea) ...[
            const SizedBox(height: 10),
            Text(
              _deliveryMessage ?? 'Sorry, this address is out of our delivery area.',
              style: const TextStyle(color: Colors.red, fontSize: 12.5),
            ),
          ],
          const SizedBox(height: 20),
          _summaryRow('Subtotal', money(cart.totals.subtotal)),
          if (cart.totals.discount > 0) _summaryRow('Discount', '-${money(cart.totals.discount)}'),
          if (cart.totals.voucherDiscount > 0) _summaryRow('Voucher', '-${money(cart.totals.voucherDiscount)}'),
          _summaryRow(
            'Delivery',
            _checkingDelivery
                ? 'Checking…'
                : _deliveryOutOfArea
                    ? '—'
                    : _deliveryFee == null
                        ? 'Select a delivery location'
                        : (_deliveryFree || _deliveryFee == 0)
                            ? 'FREE'
                            : money(_deliveryFee!),
          ),
          if (cart.totals.tax > 0)
            _summaryRow(taxLineLabel(cart.totals.taxPercent, cart.totals.taxType), money(cart.totals.tax)),
          if (cart.totals.taxDiscount > 0)
            _summaryRow(taxDiscountLineLabel(cart.totals.taxDiscountPercent), money(cart.totals.taxDiscount)),
          const SizedBox(height: 4),
          Text('Order Total: ${money(total)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: (_placing || hasOutOfStock || _deliveryOutOfArea || _checkingDelivery) ? null : _placeOrder,
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            child: _placing ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Place Order'),
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
            Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

class _BankDetailsCard extends StatelessWidget {
  final BankDetails bank;
  const _BankDetailsCard({required this.bank});

  @override
  Widget build(BuildContext context) {
    if (!bank.hasDetails) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Send payment to', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            if (bank.bankName != null) _row('Bank', bank.bankName!),
            if (bank.accountTitle != null) _row('Account Title', bank.accountTitle!),
            if (bank.accountNumber != null) _row('Account No.', bank.accountNumber!),
            if (bank.iban != null) _row('IBAN', bank.iban!),
            if (bank.branch != null) _row('Branch', bank.branch!),
            if (bank.swiftCode != null) _row('SWIFT', bank.swiftCode!),
            if (bank.instructions != null) ...[
              const SizedBox(height: 6),
              Text(bank.instructions!, style: const TextStyle(fontSize: 12.5)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            SizedBox(width: 100, child: Text(label, style: const TextStyle(fontSize: 12.5, color: Colors.grey))),
            Expanded(child: Text(value, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600))),
          ],
        ),
      );
}
