// lib/features/downloader/data/cookie_service.dart
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'cookie_service.g.dart';

@Riverpod(keepAlive: true)
class CookieService extends _$CookieService {
  @override
  void build() {}

  Future<File> getCookieFile() async {
    final appDir = await getApplicationSupportDirectory();
    return File('${appDir.path}/cookies.txt');
  }

  // Converte cookies do WebView para o formato Netscape (yt-dlp)
  Future<void> saveCookies(List<Map<String, dynamic>> cookies) async {
    final file = await getCookieFile();
    final buffer = StringBuffer();

    buffer.writeln("# Netscape HTTP Cookie File");

    for (var cookie in cookies) {
      final domain = (cookie['domain'] ?? '.youtube.com').toString();
      final path = (cookie['path'] ?? '/').toString();
      final name = (cookie['name'] ?? '').toString().replaceAll(
        RegExp(r'[\r\n\t]'),
        '',
      );
      final value = (cookie['value'] ?? '').toString().replaceAll(
        RegExp(r'[\r\n\t]'),
        '',
      );

      final includeSubdomains = 'TRUE';
      final secure = cookie['isSecure'] == true ? 'TRUE' : 'FALSE';
      final expiry =
          cookie['expiresDate'] != null
              ? (cookie['expiresDate'] as num).toInt().toString()
              : '0';

      // Escreve garantindo que não há caracteres de controle que quebrem o parser
      buffer.writeln(
        '$domain\t$includeSubdomains\t$path\t$secure\t$expiry\t$name\t$value',
      );
    }

    await file.writeAsString(buffer.toString(), flush: true);
  }
}
