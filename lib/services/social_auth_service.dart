import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Google Sign-In / Facebook Login - native SDKs, hand back the id_token /
/// access_token the backend verifies (AuthService.loginWithGoogle/loginWithFacebook).
///
/// Google's client_id is passed at runtime (this business's own OAuth
/// client, from Settings > Social Login & Security via WebsiteSettings.auth)
/// - matches the ERP being the source of truth, no per-business rebuild
/// needed. Facebook's App ID, unlike Google's, is read by the native SDK
/// during app startup before any business_id is known, so it must be baked
/// in at build time (android/app/src/main/AndroidManifest.xml +
/// ios/Runner/Info.plist) for whichever business this app build belongs to
/// - see README for the exact keys to set there.
class GoogleAuthService {
  static Future<String?> signIn(String clientId) async {
    final googleSignIn = GoogleSignIn(serverClientId: clientId, scopes: const ['email']);
    final account = await googleSignIn.signIn();
    if (account == null) return null; // user cancelled
    final auth = await account.authentication;
    return auth.idToken;
  }
}

class FacebookAuthService {
  static Future<String?> signIn() async {
    final result = await FacebookAuth.instance.login(permissions: const ['email', 'public_profile']);
    if (result.status != LoginStatus.success) return null;
    return result.accessToken?.tokenString;
  }
}
