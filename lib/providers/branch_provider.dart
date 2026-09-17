import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/branch.dart';
import '../services/branch_service.dart';

/// Which store location cart/checkout is scoped to. Mirrors the site's
/// branch store: persisted locally (not a server session), resent on every
/// relevant call by whoever reads [selectedId].
class BranchProvider extends ChangeNotifier {
  static const _prefsKey = 'sm_branch';

  List<Branch> _branches = [];
  String? _selectedId;
  bool _loading = false;

  List<Branch> get branches => _branches;
  String? get selectedId => _selectedId;
  bool get loading => _loading;
  bool get hasSelection => _selectedId != null;
  Branch? get selectedBranch => _branches.where((b) => b.id == _selectedId).firstOrNull;

  Future<void> load() async {
    // Called from splash's initState via Future.wait — notifying before the
    // first await would fire mid-build (provider throws "setState during
    // build"), so _loading flips silently and the first real notify is
    // after data lands, same convention as ThemeProvider/AuthProvider.
    _loading = true;
    final prefs = await SharedPreferences.getInstance();
    _selectedId = prefs.getString(_prefsKey);
    _branches = await BranchService.fetchBranches();
    if (_selectedId != null && _branches.every((b) => b.id != _selectedId)) {
      _selectedId = null;
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> selectBranch(String id) async {
    _selectedId = id;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, id);
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
