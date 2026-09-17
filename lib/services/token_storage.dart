import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Auth bearer token storage — Keychain/Keystore via flutter_secure_storage.
/// Migrates any legacy plain SharedPreferences `sm_token` on first read.
class TokenStorage {
  TokenStorage._();
  static final TokenStorage instance = TokenStorage._();

  static const _key = 'sm_token';
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<String?> read() async {
    final secure = await _storage.read(key: _key);
    if (secure != null && secure.isNotEmpty) return secure;

    // One-time migration from the old plain SharedPreferences slot.
    final prefs = await SharedPreferences.getInstance();
    final legacy = prefs.getString(_key);
    if (legacy == null || legacy.isEmpty) return null;
    await _storage.write(key: _key, value: legacy);
    await prefs.remove(_key);
    return legacy;
  }

  Future<void> write(String token) async {
    await _storage.write(key: _key, value: token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  Future<void> clear() async {
    await _storage.delete(key: _key);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
