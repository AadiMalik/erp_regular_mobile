import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../services/loyalty_service.dart';
import '../../theme/theme_x.dart';
import '../legal/about_us_screen.dart';
import '../legal/contact_us_screen.dart';
import '../legal/policy_page_screen.dart';
import '../auth/login_screen.dart';
import '../orders/orders_screen.dart';
import 'account_edit_screen.dart';
import 'change_password_screen.dart';

const kAppVersion = '1.0.0 (1)';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  LoyaltyBalance? _loyalty;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && context.read<AuthProvider>().isLoggedIn) _loadLoyalty();
    });
  }

  Future<void> _loadLoyalty() async {
    final res = await LoyaltyService.fetchBalance();
    if (!mounted || !res.success) return;
    setState(() => _loyalty = res.data);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final c = context.appTheme.colors;

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (auth.isLoggedIn) ...[
            CircleAvatar(
              radius: 32,
              backgroundColor: c.primaryLight,
              backgroundImage: (auth.user?['profile_image'] is String && (auth.user!['profile_image'] as String).isNotEmpty)
                  ? NetworkImage(auth.user!['profile_image'] as String)
                  : null,
              child: (auth.user?['profile_image'] is String && (auth.user!['profile_image'] as String).isNotEmpty)
                  ? null
                  : Icon(Icons.person, color: c.primary, size: 32),
            ),
            const SizedBox(height: 12),
            Text('${auth.user?['name'] ?? 'Customer'}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            Text('${auth.user?['email'] ?? ''}', style: TextStyle(color: c.textMuted)),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: const Text('My Orders'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersScreen())),
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Edit Profile'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountEditScreen())),
            ),
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('Change Password'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordScreen())),
            ),
            if (_loyalty?.enabled == true) ...[
              const Divider(height: 32),
              const _SectionLabel('Loyalty Points'),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: c.bgAlt,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: c.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _LoyaltyStat(label: 'Available', value: _loyalty!.available ?? 0, color: c.gold),
                    ),
                    Container(width: 1, height: 32, color: c.border),
                    Expanded(
                      child: _LoyaltyStat(label: 'Reserved', value: _loyalty!.reserved ?? 0, color: c.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ] else ...[
            const SizedBox(height: 12),
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                child: const Text('Sign In'),
              ),
            ),
            const SizedBox(height: 12),
          ],
          const Divider(height: 32),
          const _SectionLabel('Company'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About Us'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutUsScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.support_agent_outlined),
            title: const Text('Contact Us'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactUsScreen())),
          ),
          const _SectionLabel('Legal'),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Terms & Conditions'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const PolicyPageScreen(title: 'Terms & Conditions', slug: 'terms-conditions'))),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const PolicyPageScreen(title: 'Privacy Policy', slug: 'privacy-policy'))),
          ),
          ListTile(
            leading: const Icon(Icons.assignment_return_outlined),
            title: const Text('Return Policy'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const PolicyPageScreen(title: 'Return Policy', slug: 'return-policy'))),
          ),
          if (auth.isLoggedIn) ...[
            const Divider(height: 32),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                context.read<AuthProvider>().logout();
                context.read<WishlistProvider>().clear();
                setState(() => _loyalty = null);
              },
            ),
          ],
          const SizedBox(height: 28),
          Center(
            child: Column(
              children: [
                Text('Powered by Dukanaz', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: c.textFaint)),
                const SizedBox(height: 4),
                Text('v$kAppVersion', style: TextStyle(fontSize: 10.5, color: c.textFaint)),
              ],
            ),
          ),
          SizedBox(height: 16 + MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final c = context.appTheme.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
      child: Text(text.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: c.textFaint)),
    );
  }
}

class _LoyaltyStat extends StatelessWidget {
  final String label;
  final num value;
  final Color color;
  const _LoyaltyStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final c = context.appTheme.colors;
    final display = value % 1 == 0 ? value.toStringAsFixed(0) : value.toString();
    return Column(
      children: [
        Text(display, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: c.textMuted)),
      ],
    );
  }
}
