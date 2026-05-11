import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sesi_downloader/features/downloader/presentation/screens/home_screen.dart';
import 'package:sesi_downloader/features/downloader/presentation/screens/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'router.g.dart';

@riverpod
Future<bool> isFirstLaunch(Ref ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('is_first_launch') ?? true;
}

@riverpod
GoRouter goRouter(Ref ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    ],
  );
}
