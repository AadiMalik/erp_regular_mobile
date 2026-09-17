import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'theme_provider.dart';
import 'theme_tokens.dart';

/// Shorthand so widgets can read `context.appTheme.colors.primary` instead
/// of the full `Provider.of<ThemeProvider>(context).theme` boilerplate.
extension ThemeX on BuildContext {
  AppThemeData get appTheme => watch<ThemeProvider>().theme;
}
