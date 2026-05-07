// lib/core/utils/url_sanitizer.dart

class UrlSanitizer {
  static String sanitize(String inputUrl) {
    try {
      final uri = Uri.parse(inputUrl.trim());

      // 1. Sanitização para YouTube
      if (uri.host.contains('youtube.com')) {
        // Formato padrão: youtube.com/watch?v=ID
        if (uri.path == '/watch' && uri.queryParameters.containsKey('v')) {
          final videoId = uri.queryParameters['v'];
          return 'https://www.youtube.com/watch?v=$videoId';
        }
        // Formato Shorts: youtube.com/shorts/ID
        else if (uri.path.startsWith('/shorts/')) {
          return 'https://www.youtube.com${uri.path}';
        }
      }
      // Formato Encurtado: youtu.be/ID
      else if (uri.host.contains('youtu.be')) {
        return 'https://youtu.be/${uri.pathSegments.first}';
      }

      // 2. Sanitização para Instagram, TikTok, etc.
      // Remove parâmetros de rastreamento (ex: ?igsh=... ou ?is_from_webapp=1)
      if (uri.host.contains('instagram.com') ||
          uri.host.contains('tiktok.com')) {
        return '${uri.scheme}://${uri.host}${uri.path}';
      }

      // Se não for nenhum dos padrões conhecidos, retorna a URL original
      return inputUrl;
    } catch (e) {
      // Em caso de falha no parser, tenta um fallback simples cortando no '&'
      return inputUrl.split('&').first;
    }
  }
}
