import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:sesi_downloader/core/theme/app_theme.dart';
import 'package:sesi_downloader/features/downloader/presentation/controllers/init_controller.dart';
import 'package:sizer/sizer.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Inicia o processo assim que a tela monta
    Future.microtask(
      () => ref.read(appInitializationProvider.notifier).initialize(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initState = ref.watch(appInitializationProvider);

    // Navega para a Home quando terminar
    ref.listen(appInitializationProvider, (prev, next) {
      if (next.isComplete) {
        context.go('/');
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        // Envolvemos o Container em um SingleChildScrollView para evitar o overflow
        child: SingleChildScrollView(
          child: Container(
            width: 400,
            padding: EdgeInsets.all(24.sp),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.download_for_offline,
                  size: 60.sp,
                  color: AppTheme.primaryColor,
                ),
                SizedBox(height: 20.sp),
                Text(
                  "SESI Downloader",
                  style: Theme.of(
                    context,
                  ).textTheme.displayLarge?.copyWith(fontSize: 20.sp),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 32.sp),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: initState.progress,
                    minHeight: 8,
                    backgroundColor: Colors.grey[300],
                    valueColor: const AlwaysStoppedAnimation(
                      AppTheme.primaryColor,
                    ),
                  ),
                ),
                SizedBox(height: 12.sp),
                Text(
                  initState.message,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
