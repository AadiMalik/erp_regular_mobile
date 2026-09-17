import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/settings_provider.dart';
import '../../services/cms_service.dart';

class ContactUsScreen extends StatefulWidget {
  const ContactUsScreen({super.key});

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  bool _sending = false;

  Future<void> _send() async {
    if (_nameCtrl.text.trim().isEmpty || _emailCtrl.text.trim().isEmpty || _messageCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in your name, email and message.')));
      return;
    }
    setState(() => _sending = true);
    final ok = await CmsService.submitContactMessage(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      message: _messageCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _sending = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Message sent — we will get back to you soon.' : 'Failed to send. Please try again.')),
    );
    if (ok) _messageCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final business = context.watch<SettingsProvider>().settings;

    return Scaffold(
      appBar: AppBar(title: const Text('Contact Us')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (business.phone != null) _ContactRow(icon: Icons.call_outlined, text: business.phone!),
          if (business.email != null) _ContactRow(icon: Icons.email_outlined, text: business.email!),
          if (business.address != null) _ContactRow(icon: Icons.location_on_outlined, text: business.address!),
          const SizedBox(height: 20),
          const Text('Send us a message', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 12),
          TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Full name')),
          const SizedBox(height: 10),
          TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email'), keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 10),
          TextField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'Phone (optional)'), keyboardType: TextInputType.phone),
          const SizedBox(height: 10),
          TextField(controller: _messageCtrl, decoration: const InputDecoration(labelText: 'Message'), maxLines: 4),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _sending ? null : _send,
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            child: _sending ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Send Message'),
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _ContactRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
