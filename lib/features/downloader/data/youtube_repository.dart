import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
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
  );
}

class YoutubeRepository {
  final YtDlpService _ytDlpService;
  final FfmpegService _ffmpegService;

  YoutubeRepository(this._ytDlpService, this._ffmpegService);

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
    ];

    print('Executando: $ytPath ${args.join(" ")}');

    final process = await Process.start(ytPath, args);
    cancelToken.process = process;

    // Regex atualizado para pegar Tamanho (Size)
    // Ex: [download]  45.0% of 23.45MiB at  2.00MiB/s ETA 00:05
    final progressRegex = RegExp(
      r'\[download\]\s+(\d+\.?\d*)%\s+of\s+([~\d\.]+\w+)\s+at\s+(\S+)\s+ETA\s+(\S+)',
    );
    final fileRegex = RegExp(
      r'\[Merger\] Merging formats into "(.*)"|\[download\] Destination: (.*)$',
    );

    final stream = process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    await for (final line in stream) {
      if (cancelToken.isCancelled) {
        process.kill();
        throw Exception("Cancelado pelo usuário.");
      }

      // Detecta caminho final
      if (line.contains('Merging formats into') ||
          line.contains('Destination:')) {
        final match = fileRegex.firstMatch(line);
        if (match != null) {
          String? path = match.group(1) ?? match.group(2);
          if (path != null) {
            path = path.replaceAll('"', '');
            onPathDetermined(path);
          }
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

    final exitCode = await process.exitCode;
    if (exitCode != 0 && !cancelToken.isCancelled) {
      final error = await process.stderr.transform(utf8.decoder).join();
      throw Exception("Erro no yt-dlp (Code $exitCode): $error");
    }
  }
}
