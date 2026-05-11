import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sesi_downloader/features/downloader/data/browser_detection_service.dart';
import 'package:sesi_downloader/features/downloader/data/deno_service.dart';
import 'package:sesi_downloader/features/downloader/data/ffmpeg_service.dart';
import 'package:sesi_downloader/features/downloader/data/yt_dlp_service.dart';

part 'init_controller.g.dart';

class InitState {
  final double progress;
  final String message;
  final bool isComplete;

  InitState({
    required this.progress,
    required this.message,
    this.isComplete = false,
  });
}

@riverpod
class AppInitialization extends _$AppInitialization {
  @override
  InitState build() => InitState(progress: 0.0, message: "Iniciando...");

  Future<void> initialize() async {
    final steps = 5;
    double currentStep = 0;

    void update(String msg) {
      currentStep++;
      state = InitState(progress: currentStep / steps, message: msg);
    }

    // 1. YT-DLP
    update("Verificando yt-dlp...");
    await ref.read(ytDlpServiceProvider).updateBinary().catchError((e) => null);

    // 2. FFmpeg
    update("Verificando FFmpeg...");
    await ref
        .read(ffmpegServiceProvider)
        .updateBinary()
        .catchError((e) => null);

    // 3. Deno
    update("Verificando ambiente Deno...");
    final denoService = ref.read(denoServiceProvider);
    try {
      await denoService.getDenoPathOrThrow();
    } catch (_) {
      state = InitState(
        progress: currentStep / steps,
        message: "Instalando Deno...",
      );
      await denoService.installDeno().catchError((e) => null);
    }

    // 4. Navegadores
    update("Detectando navegadores...");
    await ref.read(browserDetectionProvider.notifier).detect();

    // 5. Finalizando
    update("Tudo pronto!");
    await Future.delayed(const Duration(milliseconds: 500));

    state = InitState(progress: 1.0, message: "Concluído", isComplete: true);
  }
}
