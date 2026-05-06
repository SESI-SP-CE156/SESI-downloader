import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sesi_downloader/features/downloader/data/browser_detection_service.dart';
import 'package:sesi_downloader/features/downloader/data/deno_service.dart';
import 'package:sesi_downloader/features/downloader/data/ffmpeg_service.dart';
import 'package:sesi_downloader/features/downloader/data/yt_dlp_service.dart';
import 'package:sesi_downloader/features/downloader/domain/download_model.dart';
import 'package:sesi_downloader/features/downloader/domain/video_metadata.dart';

part 'youtube_repository.g.dart';

class DownloadCancelToken {
  bool _isCancelled = false;
  Process? process;

  bool get isCancelled => _isCancelled;

  void cancel() {
    _isCancelled = true;
    process?.kill(ProcessSignal.sigterm);
  }
}

class DownloadProgressEvent {
  final double progress;
  final String eta;
  final String speed;
  final String totalSize; // Novo campo

  DownloadProgressEvent({
    required this.progress,
    this.eta = '',
    this.speed = '',
    this.totalSize = '',
  });
}

@Riverpod(keepAlive: true)
YoutubeRepository youtubeRepository(Ref ref) {
  return YoutubeRepository(
    ref,
    ref.read(ytDlpServiceProvider),
    ref.read(ffmpegServiceProvider),
    ref.read(denoServiceProvider),
  );
}

class YoutubeRepository {
  final Ref ref;
  final YtDlpService _ytDlpService;
  final FfmpegService _ffmpegService;
  final DenoService _denoService;
  String? _cachedBrowser;

  YoutubeRepository(
    this.ref,
    this._ytDlpService,
    this._ffmpegService,
    this._denoService,
  );

  Future<VideoMetadata> getVideoInfo(String url) async {
    final ytPath = await _ytDlpService.getExecutablePath();

    final result = await Process.run(ytPath, [
      '--dump-json',
      '--no-playlist',
      '--no-warnings',
      url,
    ]);

    if (result.exitCode != 0) {
      throw Exception('Falha ao buscar info: ${result.stderr}');
    }

    try {
      final jsonMap = jsonDecode(result.stdout.toString());
      return VideoMetadata.fromJson(jsonMap);
    } catch (e) {
      throw Exception('Erro ao processar JSON do yt-dlp: $e');
    }
  }

  Stream<DownloadProgressEvent> downloadVideo(
    String videoUrl, {
    required DownloadQuality quality,
    required DownloadCancelToken cancelToken,
    required Function(String filePath) onPathDetermined,
    String? browser,
    String? startTime,
    String? endTime,
  }) async* {
    final ytPath = await _ytDlpService.getExecutablePath();
    final ffmpegPath = await _ffmpegService.ensureFfmpegExtracted();

    Directory? directory = await getDownloadsDirectory();
    directory ??= await getApplicationDocumentsDirectory();

    // final url = 'https://www.youtube.com/watch?v=$videoId';
    final url = videoUrl;
    final Set<String> trackedFiles = {};

    // 1. Identifica se o usuário quer fazer um corte de minutagem
    final bool isCutting =
        (startTime != null && startTime.trim().isNotEmpty) ||
        (endTime != null && endTime.trim().isNotEmpty);

    String formatSelector;

    // 2. Lógica Dinâmica de Formato
    if (isCutting) {
      // Se tiver corte, forçamos MP4 (H.264) para evitar o Segmentation Fault (-11) do FFmpeg no Linux
      switch (quality) {
        case DownloadQuality.good: // 720p
          formatSelector =
              'bestvideo[height<=720][ext=mp4]+bestaudio[ext=m4a]/best[height<=720][ext=mp4]';
          break;
        case DownloadQuality.great: // 1080p
          formatSelector =
              'bestvideo[height<=1080][ext=mp4]+bestaudio[ext=m4a]/best[height<=1080][ext=mp4]';
          break;
        case DownloadQuality.extreme: // Max
          formatSelector =
              'bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best';
          break;
      }
    } else {
      // Comportamento normal para o vídeo inteiro (livre para pegar o WebM de altíssima qualidade)
      switch (quality) {
        case DownloadQuality.good: // 720p
          formatSelector = 'bestvideo[height<=720]+bestaudio/best[height<=720]';
          break;
        case DownloadQuality.great: // 1080p
          formatSelector =
              'bestvideo[height<=1080]+bestaudio/best[height<=1080]';
          break;
        case DownloadQuality.extreme: // Max
          formatSelector = 'bestvideo+bestaudio/best';
          break;
      }
    }

    String? denoPath;
    try {
      denoPath = await _denoService.getDenoPathOrThrow();
    } catch (_) {
      // Se não tiver Deno, o download pode falhar em vídeos novos
    }

    final outputPath = p.join(directory.path, '%(title)s.%(ext)s');

    List<String> cookieArgs = [];
    final browser = ref.read(browserDetectionProvider).firstOrNull;
    if (browser != null) {
      cookieArgs = ['--cookies-from-browser', browser];
    }

    final args = [
      url,
      '-o',
      outputPath,
      '--format',
      formatSelector,
      '--merge-output-format',
      'mkv',
      '--ffmpeg-location',
      ffmpegPath,
      ...cookieArgs,
      '--no-playlist',
      '--newline',
      '--progress',
      '--force-overwrites',
    ];

    if (isCutting) {
      final start =
          (startTime != null && startTime.trim().isNotEmpty)
              ? startTime.trim()
              : '0';
      final end =
          (endTime != null && endTime.trim().isNotEmpty)
              ? endTime.trim()
              : 'inf';

      args.addAll(['--download-sections', '*$start-$end']);
    }

    final Map<String, String> environment = Map<String, String>.from(
      Platform.environment,
    );

    if (denoPath != null) {
      final denoDir = File(denoPath).parent.path;
      final currentPath = environment['PATH'] ?? '';
      environment['PATH'] =
          '$denoDir${Platform.isWindows ? ';' : ':'}$currentPath';
    }

    print('Executando: $ytPath ${args.join(" ")}');

    Process? process;
    final errorBuffer = StringBuffer();

    try {
      process = await Process.start(
        ytPath,
        args,
        environment: environment,
        runInShell: Platform.isWindows,
      );
      cancelToken.process = process;

      process.stderr
          .transform(
            const Utf8Decoder(allowMalformed: true),
          ) // Permite caracteres inválidos
          .transform(const LineSplitter())
          .listen((line) {
            print("yt-dlp stderr: $line");
            errorBuffer.writeln(line);
          });
    } catch (e) {
      print("Erro crítico ao iniciar o processo yt-dlp: $e");
      throw Exception("Falha ao iniciar yt-dlp: $e");
    }

    final fileRegex = RegExp(
      r'\[Merger\] Merging formats into "(.*?)"|\[download\] Destination: (.*?)$|\[download\] (.*?) has already been downloaded|\[ffmpeg\] Destination: (.*?)$',
    );

    final progressRegex = RegExp(
      r'\[download\]\s+(\d+\.?\d*)%\s+of\s+([~\d\.]+\w+)\s+at\s+(\S+)\s+ETA\s+(\S+)',
    );

    try {
      final stream = process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in stream) {
        if (cancelToken.isCancelled) {
          process.kill(ProcessSignal.sigterm);
          throw Exception("Cancelado pelo usuário.");
        }

        // Detecta caminho final corrigido
        final fileMatch = fileRegex.firstMatch(line);
        if (fileMatch != null) {
          // Pega o primeiro grupo que não for nulo (resolve o bug da captura)
          final path =
              (fileMatch.group(1) ??
                      fileMatch.group(2) ??
                      fileMatch.group(3) ??
                      fileMatch.group(4))
                  ?.replaceAll('"', '')
                  .trim();

          if (path != null && path.isNotEmpty) {
            trackedFiles.add(path);
            trackedFiles.add('$path.part');
            trackedFiles.add('$path.temp');
            onPathDetermined(path);
          }
        }

        // Detecta progresso e tamanho
        if (line.startsWith('[download]')) {
          final match = progressRegex.firstMatch(line);
          if (match != null) {
            final percentStr = match.group(1);
            final sizeStr = match.group(2);
            final speed = match.group(3);
            final eta = match.group(4);

            if (percentStr != null) {
              final percent = double.tryParse(percentStr) ?? 0.0;
              yield DownloadProgressEvent(
                progress: percent / 100.0,
                totalSize: sizeStr ?? '?',
                speed: speed ?? '-',
                eta: eta ?? '-',
              );
            }
          }
        }
      }
    } finally {
      // Se foi cancelado, tentamos deletar todos os arquivos rastreados
      if (cancelToken.isCancelled) {
        process.kill(ProcessSignal.sigkill);

        // Pequeno delay para garantir que o SO liberou os arquivos após matar o processo
        await Future.delayed(const Duration(milliseconds: 500));

        for (final filePath in trackedFiles) {
          try {
            final file = File(filePath);
            if (await file.exists()) {
              await file.delete();
              print("Arquivo temporário removido: $filePath");
            }
          } catch (e) {
            print("Não foi possível remover arquivo temporário $filePath: $e");
          }
        }
        throw Exception(
          "Cancelado pelo usuário e arquivos temporários removidos.",
        );
      }
    }

    final exitCode = await process.exitCode;
    if (exitCode != 0 && !cancelToken.isCancelled) {
      final error = errorBuffer.toString();
      throw Exception("Erro no yt-dlp (Code $exitCode): $error");
    }
  }
}
