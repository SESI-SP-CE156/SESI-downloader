// lib/features/downloader/data/browser_detection_service.dart
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'browser_detection_service.g.dart';

@Riverpod(keepAlive: true)
class BrowserDetection extends _$BrowserDetection {
  @override
  List<String> build() => [];

  /// Detecta navegadores instalados e atualiza o estado
  Future<void> detect() async {
    final foundBrowsers = <String>[];

    // Lista de nomes de executáveis comuns que o yt-dlp reconhece
    final browserNames = [
      'firefox',
      'chrome',
      'brave',
      'opera',
      'vivaldi',
      'edge',
      'zen',
    ];

    if (Platform.isLinux) {
      // No Linux, verificamos se o comando está no PATH (resolve snap, deb, rpm)
      for (final browser in browserNames) {
        final result = await Process.run('which', [browser]);
        if (result.exitCode == 0) {
          foundBrowsers.add(browser);
        }
      }

      final flatpakMap = {
        'zen': 'firefox', // Zen é baseado em Firefox
        'firefox': 'firefox',
        'chrome': 'chrome',
        'brave': 'brave',
        'opera': 'opera',
        'vivaldi': 'vivaldi',
      };

      final flatpakDirs = [
        '/var/lib/flatpak/exports/bin',
        '${Platform.environment['HOME']}/.local/share/flatpak/exports/bin',
      ];

      for (final dirPath in flatpakDirs) {
        final dir = Directory(dirPath);
        if (await dir.exists()) {
          final List<FileSystemEntity> files = dir.listSync();
          for (final file in files) {
            final fileName = file.uri.pathSegments.last.toLowerCase();

            for (final entry in flatpakMap.entries) {
              if (fileName.contains(entry.key)) {
                foundBrowsers.add(entry.value);
              }
            }
          }
        }
      }
    } else if (Platform.isWindows) {
      // No Windows, verificamos caminhos padrão
      final programFiles =
          Platform.environment['ProgramFiles'] ?? 'C:\\Program Files';
      final programFilesX86 =
          Platform.environment['ProgramFiles(x86)'] ??
          'C:\\Program Files (x86)';

      final commonPaths = [
        '$programFiles\\Google\\Chrome\\Application\\chrome.exe',
        '$programFiles\\Mozilla Firefox\\firefox.exe',
        '$programFiles\\Microsoft\\Edge\\Application\\msedge.exe',
        '$programFilesX86\\Google\\Chrome\\Application\\chrome.exe',
      ];

      for (final path in commonPaths) {
        if (await File(path).exists()) {
          // Mapeia caminho para o nome que o yt-dlp aceita
          if (path.contains('chrome')) foundBrowsers.add('chrome');
          if (path.contains('firefox')) foundBrowsers.add('firefox');
          if (path.contains('msedge')) foundBrowsers.add('edge');
        }
      }
    }

    state = foundBrowsers;
    debugPrint("Navegadores detectados: $state");
  }
}
