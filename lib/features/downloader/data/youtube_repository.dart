import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
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
    ref.read(ytDlpServiceProvider),
    ref.read(ffmpegServiceProvider),
    ref.read(denoServiceProvider),
  );
}

class YoutubeRepository {
  final YtDlpService _ytDlpService;
  final FfmpegService _ffmpegService;
  final DenoService _denoService;

  YoutubeRepository(this._ytDlpService, this._ffmpegService, this._denoService);

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
    String videoId, {
    required DownloadQuality quality,
    required DownloadCancelToken cancelToken,
    required Function(String filePath) onPathDetermined,
  }) async* {
    final ytPath = await _ytDlpService.getExecutablePath();
    final ffmpegPath = await _ffmpegService.ensureFfmpegExtracted();

    Directory? directory = await getDownloadsDirectory();
    directory ??= await getApplicationDocumentsDirectory();

    final url = 'https://www.youtube.com/watch?v=$videoId';

    final Set<String> trackedFiles = {};

    String formatSelector;
    switch (quality) {
      case DownloadQuality.good: // 720p
        formatSelector = 'bestvideo[height<=720]+bestaudio/best[height<=720]';
        break;
      case DownloadQuality.great: // 1080p
        formatSelector = 'bestvideo[height<=1080]+bestaudio/best[height<=1080]';
        break;
      case DownloadQuality.extreme: // Max
        formatSelector = 'bestvideo+bestaudio/best';
        break;
    }

    String? denoPath;
    try {
      denoPath = await _denoService.getDenoPathOrThrow();
    } catch (_) {
      // Se não tiver Deno, o download pode falhar em vídeos novos
    }

    final args = [
      url,
      '-o',
      '${directory.path}/%(title)s.%(ext)s',
      '--format',
      formatSelector,
      '--merge-output-format',
      'mkv',
      '--ffmpeg-location',
      ffmpegPath,
      '--no-playlist',
      '--newline',
      '--progress',
      '--extractor-args',
      'youtube:player_client=android,ios;player_skip=webpage,configs',
      '--force-overwrites',
    ];

    print('Executando: $ytPath ${args.join(" ")}');

    final process = await Process.start(
      ytPath,
      args,
      environment:
          denoPath != null
              ? {
                'PATH':
                    '${File(denoPath).parent.path}${Platform.isWindows ? ';' : ':'}${Platform.environment['PATH']}',
              }
              : null,
    );
    cancelToken.process = process;

    // Regex atualizado para pegar Tamanho (Size)
    // Ex: [download]  45.0% of 23.45MiB at  2.00MiB/s ETA 00:05
    final progressRegex = RegExp(
      r'\[download\]\s+(\d+\.?\d*)%\s+of\s+([~\d\.]+\w+)\s+at\s+(\S+)\s+ETA\s+(\S+)',
    );
    final fileRegex = RegExp(
      r'\[Merger\] Merging formats into "(.*)"|\[download\] Destination: (.*)$',
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

        // Detecta caminho final
        if (line.contains('Merging formats into') ||
            line.contains('Destination:')) {
          final match = fileRegex.firstMatch(line);
          final path = match?.group(2)?.replaceAll('"', '').trim();
          if (path != null) {
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
            final sizeStr = match.group(2); // Tamanho (Ex: 23.45MiB)
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
      final error = await process.stderr.transform(utf8.decoder).join();
      throw Exception("Erro no yt-dlp (Code $exitCode): $error");
    }
  }
}
