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

    double parseTime(String timeStr) {
      if (timeStr.isEmpty) return 0.0;
      final parts = timeStr.split(':').reversed.toList();
      double secs = 0;
      if (parts.isNotEmpty) secs += double.tryParse(parts[0]) ?? 0;
      if (parts.length > 1) secs += (double.tryParse(parts[1]) ?? 0) * 60;
      if (parts.length > 2) secs += (double.tryParse(parts[2]) ?? 0) * 3600;
      return secs;
    }

    // 1. Extrai o número de bytes reais para podermos fazer o cálculo de velocidade
    double parseSizeToBytes(String sizeStr) {
      if (sizeStr == '?' || sizeStr.isEmpty) return 0.0;
      final match = RegExp(r'([~\d\.]+)\s*([a-zA-Z]+)').firstMatch(sizeStr);
      if (match == null) return 0.0;

      final value = double.tryParse(match.group(1)!.replaceAll('~', '')) ?? 0.0;
      final unit = match.group(2)!.toUpperCase();

      if (unit.contains('K')) return value * 1024;
      if (unit.contains('M')) return value * 1024 * 1024;
      if (unit.contains('G')) return value * 1024 * 1024 * 1024;
      return value;
    }

    // 2. Transforma o número em um texto amigável
    String formatBytes(double bytes) {
      if (bytes >= 1024 * 1024 * 1024) {
        return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
      } else if (bytes >= 1024 * 1024) {
        return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
      } else if (bytes >= 1024) {
        return '${(bytes / 1024).toStringAsFixed(0)} KB';
      } else {
        return '${bytes.toStringAsFixed(0)} B';
      }
    }

    final bool isCutting =
        (startTime != null && startTime.trim().isNotEmpty) ||
        (endTime != null && endTime.trim().isNotEmpty);

    double targetDuration = 0.0;
    double startSecs = 0.0;

    if (isCutting) {
      startSecs =
          (startTime != null && startTime.trim().isNotEmpty)
              ? parseTime(startTime.trim())
              : 0.0;
      double endSecs =
          (endTime != null && endTime.trim().isNotEmpty)
              ? parseTime(endTime.trim())
              : 0.0;
      if (endSecs > startSecs) {
        targetDuration = endSecs - startSecs;
      }
    }

    String formatSelector;
    if (isCutting) {
      switch (quality) {
        case DownloadQuality.good:
          formatSelector =
              'bestvideo[height<=720][ext=mp4]+bestaudio[ext=m4a]/best[height<=720][ext=mp4]';
          break;
        case DownloadQuality.great:
          formatSelector =
              'bestvideo[height<=1080][ext=mp4]+bestaudio[ext=m4a]/best[height<=1080][ext=mp4]';
          break;
        case DownloadQuality.extreme:
          formatSelector =
              'bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best';
          break;
      }
    } else {
      switch (quality) {
        case DownloadQuality.good:
          formatSelector = 'bestvideo[height<=720]+bestaudio/best[height<=720]';
          break;
        case DownloadQuality.great:
          formatSelector =
              'bestvideo[height<=1080]+bestaudio/best[height<=1080]';
          break;
        case DownloadQuality.extreme:
          formatSelector = 'bestvideo+bestaudio/best';
          break;
      }
    }

    String? denoPath;
    try {
      denoPath = await _denoService.getDenoPathOrThrow();
    } catch (_) {}

    final outputPath = p.join(directory.path, '%(title)s.%(ext)s');

    List<String> cookieArgs = [];
    final browserName =
        browser ?? ref.read(browserDetectionProvider).firstOrNull;
    if (browserName != null) {
      cookieArgs = ['--cookies-from-browser', browserName];
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
    } catch (e) {
      throw Exception("Falha ao iniciar yt-dlp: $e");
    }

    // Variáveis para rastrear a velocidade em MB/s
    double lastBytes = 0.0;
    DateTime lastTime = DateTime.now();
    String currentSpeedDisplay = 'Calculando...';

    // Unifica o stdout e stderr para podermos mandar os eventos para o yield
    final controller = StreamController<DownloadProgressEvent>();
    int completedStreams = 0;
    void checkDone() {
      completedStreams++;
      if (completedStreams == 2) controller.close();
    }

    // REGEX: yt-dlp (Downloads Padrão)
    final fileRegex = RegExp(
      r'\[Merger\] Merging formats into "(.*?)"|\[download\] Destination: (.*?)$|\[download\] (.*?) has already been downloaded|\[ffmpeg\] Destination: (.*?)$',
    );
    final progressRegex = RegExp(
      r'\[download\]\s+(\d+\.?\d*)%\s+of\s+([~\d\.]+\w+)\s+at\s+(\S+)\s+ETA\s+(\S+)',
    );

    // REGEX: FFmpeg (Downloads com Minutagem / Cortes)
    final ffmpegFileRegex = RegExp(r"Output #0, .*, to '(?:file:)?(.*?)':");
    final ffmpegDurationRegex = RegExp(
      r'Duration:\s+(\d{2}):(\d{2}):(\d{2}\.\d+)',
    );
    final ffmpegProgressRegex = RegExp(
      r'size=\s*(\d+\w+)\s+time=(\d{2}):(\d{2}):(\d{2}\.\d+).*?speed=\s*([\d\.]+)x',
    );

    // LISTENER 1: Captura o FFmpeg no STDERR
    process.stderr
        .transform(const Utf8Decoder(allowMalformed: true))
        .transform(const LineSplitter())
        .listen((line) {
          errorBuffer.writeln(line);

          // Descobre onde o FFmpeg está salvando
          final fileMatch = ffmpegFileRegex.firstMatch(line);
          if (fileMatch != null) {
            String path = fileMatch.group(1)?.replaceAll('"', '').trim() ?? '';
            if (path.isNotEmpty) {
              if (path.endsWith('.part'))
                path = path.substring(0, path.length - 5);
              trackedFiles.add(path);
              trackedFiles.add('$path.part');
              onPathDetermined(path);
            }
          }

          // Se o usuário não colocou "Fim", usamos o tempo total detectado pelo próprio stream do vídeo
          if (targetDuration == 0.0) {
            final durMatch = ffmpegDurationRegex.firstMatch(line);
            if (durMatch != null) {
              final h = int.parse(durMatch.group(1)!);
              final m = int.parse(durMatch.group(2)!);
              final s = double.parse(durMatch.group(3)!);
              targetDuration = (h * 3600 + m * 60 + s) - startSecs;
            }
          }

          // Converte o tempo lido em % de progresso
          // Converte o tempo lido em % de progresso e calcula ETA e Velocidade
          final progMatch = ffmpegProgressRegex.firstMatch(line);
          if (progMatch != null) {
            final sizeStr = progMatch.group(1);
            final h = int.parse(progMatch.group(2)!);
            final m = int.parse(progMatch.group(3)!);
            final s = double.parse(progMatch.group(4)!);
            final currentTime = h * 3600 + m * 60 + s;

            final speedStr = progMatch.group(5) ?? '1.0';
            final speedDouble = double.tryParse(speedStr) ?? 1.0;

            // --- CÁLCULO DE VELOCIDADE REAL EM MB/S ---
            final currentBytes = parseSizeToBytes(sizeStr ?? '');
            final now = DateTime.now();
            final diffSecs = now.difference(lastTime).inMilliseconds / 1000.0;

            if (lastBytes == 0.0) {
              lastBytes = currentBytes;
              lastTime = now;
            } else if (diffSecs >= 1.0) {
              // Atualiza a cada 1 segundo para não piscar
              if (currentBytes > lastBytes) {
                final bytesPerSec = (currentBytes - lastBytes) / diffSecs;
                currentSpeedDisplay = '${formatBytes(bytesPerSec)}/s';
              }
              lastBytes = currentBytes;
              lastTime = now;
            }
            // ------------------------------------------

            double percent = 0.0;
            String calculatedEta = 'Calculando...';

            if (targetDuration > 0) {
              percent = (currentTime / targetDuration).clamp(0.0, 1.0);

              final remainingDuration = targetDuration - currentTime;
              if (speedDouble > 0 && remainingDuration > 0) {
                final etaInSeconds = remainingDuration / speedDouble;
                final minutes = (etaInSeconds / 60).floor();
                final seconds = (etaInSeconds % 60).floor();
                calculatedEta =
                    '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
              } else if (remainingDuration <= 0) {
                calculatedEta = '00:00';
              }
            }

            controller.add(
              DownloadProgressEvent(
                progress: percent,
                totalSize: formatBytes(currentBytes),
                speed:
                    currentSpeedDisplay, // Exibe a velocidade em MB/s ou KB/s
                eta: calculatedEta,
              ),
            );
          }
        }, onDone: checkDone);

    // LISTENER 2: Captura o YT-DLP no STDOUT
    process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
          if (cancelToken.isCancelled) return;

          final fileMatch = fileRegex.firstMatch(line);
          if (fileMatch != null) {
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

          final match = progressRegex.firstMatch(line);
          if (match != null) {
            final percentStr = match.group(1);
            final sizeStr = match.group(2);
            final speed = match.group(3);
            final eta = match.group(4);
            if (percentStr != null) {
              controller.add(
                DownloadProgressEvent(
                  progress: (double.tryParse(percentStr) ?? 0.0) / 100.0,
                  totalSize: formatBytes(parseSizeToBytes(sizeStr ?? '')),
                  speed: speed ?? '-',
                  eta: eta ?? '-',
                ),
              );
            }
          }
        }, onDone: checkDone);

    try {
      await for (final event in controller.stream) {
        if (cancelToken.isCancelled) {
          process.kill(ProcessSignal.sigterm);
          throw Exception("Cancelado pelo usuário.");
        }
        yield event;
      }
    } finally {
      if (cancelToken.isCancelled) {
        process.kill(ProcessSignal.sigkill);
        await Future.delayed(const Duration(milliseconds: 500));
        for (final filePath in trackedFiles) {
          try {
            final file = File(filePath);
            if (await file.exists()) {
              await file.delete();
            }
          } catch (_) {}
        }
        throw Exception(
          "Cancelado pelo usuário e arquivos temporários removidos.",
        );
      }
    }

    final exitCode = await process.exitCode;
    if (exitCode != 0 && !cancelToken.isCancelled) {
      throw Exception("Erro no yt-dlp (Code $exitCode): $errorBuffer");
    }
  }
}
