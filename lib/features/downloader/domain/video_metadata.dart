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
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Sem título',
      uploader: json['uploader'] as String? ?? 'Desconhecido',
      thumbnailUrl: json['thumbnail'] as String? ?? '',
      durationSeconds: json['duration'] as int? ?? 0,
      width: json['width'] as int? ?? 0,
      height: json['height'] as int? ?? 0,
    );
  }
}
