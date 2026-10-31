import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'services/game_generator_service.dart';
import 'services/lottery_sync_service.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const MegaSenaApp());
}

class MegaSenaApp extends StatefulWidget {
  const MegaSenaApp({super.key});

  @override
  State<MegaSenaApp> createState() => _MegaSenaAppState();
}

class _MegaSenaAppState extends State<MegaSenaApp> {
  late final StorageService _storageService;
  late final AuthService _authService;
  late final LotterySyncService _syncService;
  late final GameGeneratorService _generatorService;

  UserAccount? _currentUser;
  bool _checkingSession = true;

  @override
  void initState() {
    super.initState();
    _storageService = StorageService();
    _authService = AuthService(_storageService);
    _syncService = LotterySyncService(_storageService);
    _generatorService = GameGeneratorService();
    _restoreUserSession();
  }

  Future<void> _restoreUserSession() async {
    final user = await _authService.restoreSession();
    if (mounted) {
      setState(() {
        _currentUser = user;
        _checkingSession = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    await _authService.signOut();
    if (mounted) {
      setState(() {
        _currentUser = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mega-Sena Smart',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: _checkingSession
          ? const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: AppTheme.neonEmerald),
              ),
            )
          : _currentUser == null
              ? LoginScreen(
                  authService: _authService,
                  onSignedIn: (account) {
                    setState(() {
                      _currentUser = account;
                    });
                  },
                )
              : HomeScreen(
                  user: _currentUser!,
                  storageService: _storageService,
                  syncService: _syncService,
                  generatorService: _generatorService,
                  onLogout: _handleLogout,
                ),
    );
  }
}
