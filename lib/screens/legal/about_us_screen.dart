import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/settings_provider.dart';
import '../../services/cms_service.dart';

class AboutUsScreen extends StatefulWidget {
  const AboutUsScreen({super.key});

  @override
  State<AboutUsScreen> createState() => _AboutUsScreenState();
}

class _AboutUsScreenState extends State<AboutUsScreen> {
  CmsSection? _section;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    CmsService.fetchSection('about-us').then((s) {
      if (!mounted) return;
      setState(() {
        _section = s;
        _loading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final businessName = context.watch<SettingsProvider>().settings.businessName;
    final s = _section;

    return Scaffold(
      appBar: AppBar(title: const Text('About Us')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (s?.image != null)
                    AspectRatio(aspectRatio: 16 / 9, child: CachedNetworkImage(imageUrl: s!.image!, fit: BoxFit.cover)),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s?.title ?? 'About $businessName', style: Theme.of(context).textTheme.titleLarge),
                        if (s?.subtitle != null) ...[
                          const SizedBox(height: 6),
                          Text(s!.subtitle!, style: const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                        const SizedBox(height: 12),
                        Text(
                          s?.content ?? "We're setting up our story — check back soon to learn more about $businessName.",
                          style: const TextStyle(height: 1.6, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
