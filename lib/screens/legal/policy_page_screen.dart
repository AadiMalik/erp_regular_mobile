import 'package:flutter/material.dart';

import '../../services/pages_service.dart';

/// Renders a CMS-managed static page (Terms & Conditions, Privacy Policy,
/// Return Policy, ...) by slug. Falls back to a short static notice if the
/// admin hasn't configured that page yet (per CLAUDE.md #13).
class PolicyPageScreen extends StatefulWidget {
  final String title;
  final String slug;
  const PolicyPageScreen({super.key, required this.title, required this.slug});

  @override
  State<PolicyPageScreen> createState() => _PolicyPageScreenState();
}

class _PolicyPageScreenState extends State<PolicyPageScreen> {
  CmsPage? _page;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    PagesService.fetchPage(widget.slug).then((p) {
      if (!mounted) return;
      setState(() {
        _page = p;
        _loading = false;
      });
    });
  }

  // Content comes from a CMS rich-text editor; strip tags to plain text
  // rather than pulling in a full HTML-rendering dependency for a page
  // that's mostly paragraphs and bullet points.
  static String _plainText(String html) {
    var text = html
        .replaceAll(RegExp(r'<\s*(br|/p|/li|/div|/h[1-6])[^>]*>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<li[^>]*>', caseSensitive: false), '• ')
        .replaceAll(RegExp(r'<[^>]+>'), '');
    return text.replaceAll(RegExp(r'\n{3,}'), '\n\n').replaceAll('&nbsp;', ' ').trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Text(
                _page != null ? _plainText(_page!.content) : 'This page has not been set up yet. Please check back later.',
                style: const TextStyle(height: 1.6, fontSize: 14),
              ),
            ),
    );
  }
}
