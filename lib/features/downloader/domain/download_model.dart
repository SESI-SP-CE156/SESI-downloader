enum DownloadStatus {
  fetchingMetadata,
  pending,
  downloading,
  processing,
  completed,
  error,
  canceled,
}

enum DownloadQuality {
  extreme("Extrema (4K/Max)"),
  great("Ótima (1080p)"),
  good("Boa (720p)");

  final String label;
  const DownloadQuality(this.label);
}

class DownloadItem {
  final String id;
  final String title;
  final String author; // Novo: Nome do canal
  final String thumbnailUrl;
  final double progress;
  final DownloadStatus status;
  final String? error;
  final String filePath;

  final DownloadQuality quality;
  final String resolution;
  final String audioBitrate;
  final String eta;
  final String totalSizeString; // Novo: Ex: "45.2 MiB"

  DownloadItem({
    required this.id,
    required this.title,
    this.author = '',
    required this.thumbnailUrl,
    this.progress = 0.0,
    this.status = DownloadStatus.pending,
    this.error,
    this.filePath = '',
    this.quality = DownloadQuality.extreme,
    this.resolution = '-',
    this.audioBitrate = '-',
    this.eta = '-',
    this.totalSizeString = '-',
  });

  bool get isDownloading => status == DownloadStatus.downloading;
  bool get isProcessing => status == DownloadStatus.processing;
  bool get isCompleted => status == DownloadStatus.completed;
  bool get isPending => status == DownloadStatus.pending;

  DownloadItem copyWith({
    String? id,
    String? title,
    String? author,
    String? thumbnailUrl,
    double? progress,
    DownloadStatus? status,
    String? error,
    String? filePath,
    DownloadQuality? quality,
    String? resolution,
    String? audioBitrate,
    String? eta,
    String? totalSizeString,
  }) {
    return DownloadItem(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      error: error ?? this.error,
      filePath: filePath ?? this.filePath,
      quality: quality ?? this.quality,
      resolution: resolution ?? this.resolution,
      audioBitrate: audioBitrate ?? this.audioBitrate,
      eta: eta ?? this.eta,
      totalSizeString: totalSizeString ?? this.totalSizeString,
    );
  }
}
