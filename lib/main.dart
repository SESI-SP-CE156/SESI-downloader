import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:sesi_downloader/core/router/router.dart';
import 'package:sesi_downloader/core/theme/app_theme.dart';
import 'package:sesi_downloader/features/downloader/data/browser_detection_service.dart';
import 'package:sesi_downloader/features/downloader/data/deno_service.dart';
import 'package:sesi_downloader/features/downloader/data/ffmpeg_service.dart';
import 'package:sesi_downloader/features/downloader/data/yt_dlp_service.dart';
import 'package:sizer/sizer.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(1024, 768),
    minimumSize: Size(800, 600),
    maximumSize: Size(1280, 1024),
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

  await _ensureDependencies(container);

  runApp(UncontrolledProviderScope(container: container, child: MainApp()));
}

Future<void> _ensureDependencies(ProviderContainer container) async {
  final ytDlpService = container.read(ytDlpServiceProvider);
  final denoService = container.read(denoServiceProvider);
  final ffmpegService = container.read(ffmpegServiceProvider);

  // 1. Verificar/Atualizar yt-dlp
  try {
    await Future.wait([
      ytDlpService.updateBinary().catchError(
        (e) => debugPrint("Falha no yt-dlp: $e"),
      ),
      ffmpegService.updateBinary().catchError(
        (e) => debugPrint("Falha no ffmpeg: $e"),
      ),
    ]);
  } catch (e) {
    debugPrint("Erro durante atualizações simultâneas: $e");
  }

  // 2. Verificar/Instalar Deno
  try {
    debugPrint("Verificando instalação do Deno...");
    await denoService.getDenoPathOrThrow();
    debugPrint("Deno já está instalado.");
  } catch (e) {
    debugPrint("Deno não encontrado. Iniciando instalação automática...");
    try {
      await denoService.installDeno();
      debugPrint("Deno instalado com sucesso.");
    } catch (installError) {
      debugPrint("Erro crítico ao instalar Deno: $installError");
    }
  }

  // 3. Detectar navegadores automaticamente
  try {
    debugPrint("Detectando navegadores instalados...");
    await container.read(browserDetectionProvider.notifier).detect();
  } catch (e) {
    debugPrint("Erro ao detectar navegadores: $e");
  }
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
