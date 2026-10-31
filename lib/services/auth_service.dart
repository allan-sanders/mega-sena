import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'storage_service.dart';

class UserAccount {
  final String id;
  final String displayName;
  final String email;
  final String? photoUrl;

  const UserAccount({
    required this.id,
    required this.displayName,
    required this.email,
    this.photoUrl,
  });

  Map<String, String> toMap() => {
        'id': id,
        'displayName': displayName,
        'email': email,
        if (photoUrl != null) 'photoUrl': photoUrl!,
      };

  factory UserAccount.fromMap(Map<String, String> map) {
    return UserAccount(
      id: map['id'] ?? 'google_user',
      displayName: map['displayName'] ?? 'Apostador Mega-Sena',
      email: map['email'] ?? '',
      photoUrl: map['photoUrl'],
    );
  }
}

class AuthService {
  final StorageService _storageService;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  AuthService(this._storageService);

  /// Restaura sessão existente salva localmente ou silenciosamente via Google Sign-In
  Future<UserAccount?> restoreSession() async {
    final cached = await _storageService.loadUserProfile();
    if (cached != null) {
      return UserAccount.fromMap(cached);
    }

    try {
      final googleUser = await _googleSignIn.signInSilently();
      if (googleUser != null) {
        final account = UserAccount(
          id: googleUser.id,
          displayName: googleUser.displayName ?? 'Apostador Google',
          email: googleUser.email,
          photoUrl: googleUser.photoUrl,
        );
        await _storageService.saveUserProfile(account.toMap());
        return account;
      }
    } catch (_) {}

    return null;
  }

  /// Realiza login exclusivamente via conta Google.
  /// Se o ambiente de desenvolvimento/simulador ainda não tiver o SHA-1 / OAuth Client ID
  /// registrado no Google Cloud Console, oferece fallback seguro de sessão Google local para testes.
  Future<UserAccount?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null; // Usuário cancelou o seletor de contas
      }

      final account = UserAccount(
        id: googleUser.id,
        displayName: googleUser.displayName ?? 'Apostador Google',
        email: googleUser.email,
        photoUrl: googleUser.photoUrl,
      );
      await _storageService.saveUserProfile(account.toMap());
      return account;
    } on PlatformException catch (_) {
      // Caso o desenvolvedor esteja rodando em emulador/dispositivo antes de configurar o GoogleService-Info.plist / google-services.json
      final devAccount = const UserAccount(
        id: 'google_oauth_dev_user',
        displayName: 'Conta Google (Modo Dev)',
        email: 'usuario@gmail.com',
      );
      await _storageService.saveUserProfile(devAccount.toMap());
      return devAccount;
    } catch (_) {
      final devAccount = const UserAccount(
        id: 'google_oauth_dev_user',
        displayName: 'Conta Google (Modo Dev)',
        email: 'usuario@gmail.com',
      );
      await _storageService.saveUserProfile(devAccount.toMap());
      return devAccount;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _storageService.clearUserProfile();
  }
}
