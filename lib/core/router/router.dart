import 'dart:io';

import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sesi_downloader/features/downloader/presentation/screens/home_screen.dart';
import 'package:sesi_downloader/features/downloader/presentation/screens/login_screen.dart';
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
    initialLocation: '/',
    redirect: (context, state) async {
      if (Platform.isWindows) {
        final firstLaunch = await ref.read(isFirstLaunchProvider.future);
        if (firstLaunch) {
          // Marca como false após a primeira vez
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('is_first_launch', false);
          return '/login';
        }
      }
      return null; // Nenhuma mudança de rota
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
      GoRoute(path: '/login', builder: (context, state) => LoginScreen()),
    ],
  );
}
