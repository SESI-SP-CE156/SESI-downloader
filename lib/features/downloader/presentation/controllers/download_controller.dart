import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sesi_downloader/features/downloader/data/youtube_repository.dart';
import 'package:sesi_downloader/features/downloader/domain/download_model.dart';
import 'package:sesi_downloader/features/downloader/domain/video_metadata.dart';

part 'download_controller.g.dart';

@riverpod
class DownloadList extends _$DownloadList {
  static const int _maxSimultaneousDownloads = 1;
  final Map<String, DownloadCancelToken> _cancelTokens = {};

  @override
  List<DownloadItem> build() => [];

  Future<void> addDownload(String url, DownloadQuality quality) async {
    final repository = ref.read(youtubeRepositoryProvider);
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';

    state = [
      ...state,
      DownloadItem(
        id: tempId,
        title: 'Buscando metadados...',
        thumbnailUrl: '',
        status: DownloadStatus.fetchingMetadata,
        quality: quality,
      ),
    ];

    try {
      final VideoMetadata video = await repository.getVideoInfo(url);

      if (state.any((item) => item.id == video.id)) {
        state = state.where((item) => item.id != tempId).toList();
        return;
      }

      final realItem = DownloadItem(
        id: video.id,
        title: video.title,
        author: video.uploader, // Preenche autor
        thumbnailUrl: video.thumbnailUrl,
        status: DownloadStatus.pending,
        quality: quality,
        // Preenche resolução baseada no metadata
        resolution: video.height > 0 ? "${video.height}p" : "HD",
      );

      state = [
        for (final item in state)
          if (item.id == tempId) realItem else item,
      ];

      _checkQueue();
    } catch (e) {
      state = state.where((item) => item.id != tempId).toList();
      print("Erro ao adicionar: $e");
    }
  }

  void cancelDownload(String id) {
    _cancelTokens[id]?.cancel();
    _cancelTokens.remove(id);
    _updateItem(
      id,
      (item) => item.copyWith(
        status: DownloadStatus.canceled,
        error: "Cancelado pelo usuário",
        eta: "-",
        progress: 0.0,
      ),
    );
    Future.delayed(const Duration(milliseconds: 1000), () {
      _checkQueue();
    });
  }

  void _checkQueue() {
    final activeDownloads =
        state.where((i) => i.isDownloading || i.isProcessing).length;
    if (activeDownloads >= _maxSimultaneousDownloads) return;

    final nextItem =
        state.where((i) => i.status == DownloadStatus.pending).firstOrNull;
    if (nextItem == null) return;

    _updateItem(
      nextItem.id,
      (item) =>
          item.copyWith(status: DownloadStatus.downloading, progress: 0.0),
    );

    _startDownloadProcess(nextItem.id, nextItem.quality);
  }

  Future<void> _startDownloadProcess(
    String videoId,
    DownloadQuality quality,
  ) async {
    final repository = ref.read(youtubeRepositoryProvider);
    final cancelToken = DownloadCancelToken();
    _cancelTokens[videoId] = cancelToken;

    bool shouldProcessQueue = true;

    try {
      final stream = repository.downloadVideo(
        videoId,
        quality: quality,
        cancelToken: cancelToken,
        onPathDetermined: (fullPath) {
          _updateItem(videoId, (item) => item.copyWith(filePath: fullPath));
        },
      );

      await for (final event in stream) {
        _updateItem(
          videoId,
          (item) => item.copyWith(
            progress: event.progress,
            totalSizeString: event.totalSize, // Preenche tamanho
            eta: "${event.eta} (${event.speed})",
            status:
                event.progress >= 0.99
                    ? DownloadStatus.processing
                    : DownloadStatus.downloading,
          ),
        );
      }

      _updateItem(
        videoId,
        (item) => item.copyWith(
          status: DownloadStatus.completed,
          progress: 1.0,
          eta: "Completo",
        ),
      );
    } catch (e) {
      if (cancelToken.isCancelled) {
        _updateItem(
          videoId,
          (item) => item.copyWith(
            status: DownloadStatus.canceled,
            error: "Cancelado",
            eta: "-",
          ),
        );
        shouldProcessQueue = true;
        return;
      }
      _updateItem(
        videoId,
        (item) =>
            item.copyWith(status: DownloadStatus.error, error: e.toString()),
      );
    } finally {
      _cancelTokens.remove(videoId);
      if (shouldProcessQueue) {
        Future.delayed(const Duration(seconds: 1), _checkQueue);
      }
    }
  }

  void _updateItem(String id, DownloadItem Function(DownloadItem) update) {
    state = state.map((item) => item.id == id ? update(item) : item).toList();
  }
}
