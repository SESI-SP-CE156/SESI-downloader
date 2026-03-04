import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:sesi_downloader/core/router/router.dart';
import 'package:sesi_downloader/core/theme/app_theme.dart';
import 'package:sesi_downloader/features/downloader/data/yt_dlp_service.dart';
import 'package:sizer/sizer.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(1024, 768),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
    title: "SESI Youtube Downloader",
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  // --- INICIALIZAÇÃO ANTECIPADA ---
  // Cria um container para inicializar o repositório do YouTube (e o Deno)
  // assim que o app abrir, reduzindo o comportamento de "bot" nas requisições.
  final container = ProviderContainer();

  final ytDlpService = container.read(ytDlpServiceProvider);

  try {
    debugPrint("Iniciando verificação de atualização do yt-dlp...");
    ytDlpService.updateBinary().catchError(
      (e) => debugPrint("Erro silencioso: $e"),
    );
  } catch (e, stack) {
    // Não paramos o app se a atualização falhar (ex: sem internet)
    debugPrint("Erro ao atualizar o yt-dlp na inicialização: $e");
  }

  runApp(UncontrolledProviderScope(container: container, child: MainApp()));
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);

    return Sizer(
      builder: (context, orientation, deviceType) {
        return MaterialApp.router(
          title: 'SESI Downloader',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme, // Now safe to use .sp
          routerConfig: router,
        );
      },
    );
  }
}
