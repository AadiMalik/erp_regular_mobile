import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/address.dart';
import '../../providers/auth_provider.dart';
import '../../services/address_service.dart';
import '../../services/auth_service.dart';
import '../../theme/theme_x.dart';

class AccountEditScreen extends StatefulWidget {
  const AccountEditScreen({super.key});

  @override
  State<AccountEditScreen> createState() => _AccountEditScreenState();
}

class _AccountEditScreenState extends State<AccountEditScreen> {
  late final _nameCtrl = TextEditingController(text: context.read<AuthProvider>().user?['name']);
  bool _busy = false;
  String? _error;
  File? _imageFile;

  static const _allowedExtensions = ['.jpg', '.jpeg', '.png', '.webp'];

  String? get _currentImageUrl => context.read<AuthProvider>().user?['profile_image'] as String?;

  bool _isAllowedImagePath(String path) {
    final lower = path.toLowerCase();
    return _allowedExtensions.any(lower.endsWith);
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    final mime = (picked.mimeType ?? '').toLowerCase();
    final hasImageMime = mime.startsWith('image/') &&
        (mime.contains('jpeg') || mime.contains('jpg') || mime.contains('png') || mime.contains('webp'));
    final hasPath = _isAllowedImagePath(picked.path);
    if (mime.isNotEmpty && !hasImageMime && !hasPath) {
      setState(() => _error = 'Please upload a valid image file (JPG, PNG or WEBP).');
      return;
    }
    if (mime.isEmpty && picked.path.contains('.') && !hasPath) {
      setState(() => _error = 'Please upload a valid image file (JPG, PNG or WEBP).');
      return;
    }
    setState(() {
      _imageFile = File(picked.path);
      _error = null;
    });
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final res = await AuthService.updateProfile(name: _nameCtrl.text.trim(), profileImage: _imageFile);
    if (!mounted) return;
    setState(() => _busy = false);
    if (!res.success) {
      setState(() => _error = res.message);
      return;
    }
    await context.read<AuthProvider>().refreshProfile();
    if (!mounted) return;
    setState(() => _imageFile = null);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated.')));
  }

  Future<void> _openAddressForm({Address? existing}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddressFormSheet(existing: existing),
    );
    if (!mounted) return;
    context.read<AuthProvider>().refreshProfile();
  }

  Future<void> _deleteAddress(String id) async {
    await AddressService.deleteAddress(id);
    if (!mounted) return;
    context.read<AuthProvider>().refreshProfile();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final email = auth.user?['email'] ?? '';
    final addresses = ((auth.user?['addresses'] as List?) ?? []).map((e) => Address.fromJson(e as Map<String, dynamic>)).toList();
    final c = context.appTheme.colors;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: CircleAvatar(
              radius: 40,
              backgroundColor: c.primaryLight,
              backgroundImage: _imageFile != null
                  ? FileImage(_imageFile!) as ImageProvider
                  : (_currentImageUrl != null && _currentImageUrl!.isNotEmpty
                      ? NetworkImage(_currentImageUrl!)
                      : null),
              child: (_imageFile == null && (_currentImageUrl == null || _currentImageUrl!.isEmpty))
                  ? Icon(Icons.camera_alt_outlined, color: c.primary, size: 28)
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: _pickImage, child: const Text('Change photo')),
          const SizedBox(height: 14),
          TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Full name')),
          const SizedBox(height: 14),
          TextField(enabled: false, decoration: InputDecoration(labelText: 'Email', hintText: email)),
          const SizedBox(height: 14),
          TextField(
            enabled: false,
            decoration: InputDecoration(labelText: 'Phone', hintText: auth.user?['phone'] ?? ''),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: _busy ? null : _save,
            child: _busy ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save'),
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Saved Addresses', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              TextButton.icon(onPressed: () => _openAddressForm(), icon: const Icon(Icons.add, size: 18), label: const Text('Add')),
            ],
          ),
          if (addresses.isEmpty) Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text('No addresses saved yet.', style: TextStyle(color: c.textMuted))),
          ...addresses.map((a) => Card(
                margin: const EdgeInsets.only(top: 10),
                child: ListTile(
                  title: Text(a.fullName, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(a.summary),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (a.isDefault) Padding(padding: const EdgeInsets.only(right: 6), child: Icon(Icons.star, size: 16, color: c.primary)),
                      IconButton(icon: const Icon(Icons.edit_outlined, size: 18), onPressed: () => _openAddressForm(existing: a)),
                      IconButton(icon: const Icon(Icons.delete_outline, size: 18), onPressed: () => _deleteAddress(a.id)),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

class _AddressFormSheet extends StatefulWidget {
  final Address? existing;
  const _AddressFormSheet({this.existing});

  @override
  State<_AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends State<_AddressFormSheet> {
  late final _fullNameCtrl = TextEditingController(text: widget.existing?.fullName);
  late final _phoneCtrl = TextEditingController(text: widget.existing?.phone);
  late final _addressCtrl = TextEditingController(text: widget.existing?.address);
  late final _cityCtrl = TextEditingController(text: widget.existing?.city);
  late final _countryCtrl = TextEditingController(text: widget.existing?.country);
  bool _busy = false;
  String? _error;

  Future<void> _save() async {
    if (_fullNameCtrl.text.trim().isEmpty || _addressCtrl.text.trim().isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final res = await AddressService.saveAddress(
      id: widget.existing?.id,
      fullName: _fullNameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      city: _cityCtrl.text.trim(),
      country: _countryCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (!res.success) {
      setState(() => _error = res.message ?? 'Could not save address.');
      return;
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.existing == null ? 'Add Address' : 'Edit Address', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 14),
            TextField(controller: _fullNameCtrl, decoration: const InputDecoration(labelText: 'Full name')),
            const SizedBox(height: 10),
            TextField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'Phone'), keyboardType: TextInputType.phone),
            const SizedBox(height: 10),
            TextField(controller: _addressCtrl, decoration: const InputDecoration(labelText: 'Street address'), maxLines: 2),
            const SizedBox(height: 10),
            TextField(controller: _cityCtrl, decoration: const InputDecoration(labelText: 'City')),
            const SizedBox(height: 10),
            TextField(controller: _countryCtrl, decoration: const InputDecoration(labelText: 'Country')),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _busy ? null : _save,
              child: _busy ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save Address'),
            ),
          ],
        ),
      ),
    );
  }
}
