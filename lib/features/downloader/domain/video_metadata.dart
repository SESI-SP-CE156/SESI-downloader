class VideoMetadata {
  final String id;
  final String title;
  final String uploader; // Novo: Autor/Canal
  final String thumbnailUrl;
  final int durationSeconds;
  final int width; // Novo: Largura
  final int height; // Novo: Altura

  VideoMetadata({
    required this.id,
    required this.title,
    required this.uploader,
    required this.thumbnailUrl,
    required this.durationSeconds,
    required this.width,
    required this.height,
  });

  factory VideoMetadata.fromJson(Map<String, dynamic> json) {
    return VideoMetadata(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? json['id'] ?? 'Sem título').toString(),
      uploader:
          (json['uploader'] ??
                  json['channel'] ??
                  json['creator'] ??
                  'Desconhecido')
              .toString(),
      thumbnailUrl: (json['thumbnail'] ?? '').toString(),
      durationSeconds: (json['duration'] as num?)?.toInt() ?? 0,
      width: (json['width'] as num?)?.toInt() ?? 0,
      height: (json['height'] as num?)?.toInt() ?? 0,
    );
  }
}
