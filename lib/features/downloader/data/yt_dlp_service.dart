import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sesi_downloader/features/downloader/data/python_service.dart';

part 'yt_dlp_service.g.dart';

@riverpod
YtDlpService ytDlpService(Ref ref) {
  return YtDlpService(ref.read(pythonServiceProvider));
}

class YtDlpService {
  final PythonService _pythonService;
  static final _extractionCompleter = Completer<String>();
  static bool _isExtracting = false;

  YtDlpService(this._pythonService);

  (String assetName, String fileName) _getPlatformNames() {
    if (Platform.isWindows) {
      return ('assets/bin/yt-dlp.exe', 'yt-dlp.exe');
    } else if (Platform.isLinux) {
      return ('assets/bin/yt-dlp', 'yt-dlp');
    }
    throw Exception("Sistema operacional não suportado.");
  }

  Future<bool> _isBinaryValid(String path) async {
    try {
      final result = await Process.run(path, ['--version']);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  Future<String> getExecutablePath() async {
    // 1. Garantir Python APENAS no Linux
    if (Platform.isLinux) {
      await _pythonService.ensurePythonInstalled();
    }

    if (_isExtracting) return _extractionCompleter.future;
    if (_extractionCompleter.isCompleted) return _extractionCompleter.future;

    _isExtracting = true;

    try {
      final docDir = await getApplicationSupportDirectory();
      final names = _getPlatformNames();
      final exePath = '${docDir.path}${Platform.pathSeparator}${names.$2}';
      final file = File(exePath);

      // Lógica robusta: Verificar existência e validade
      bool needsExtraction = true;

      if (await file.exists()) {
        // Se o arquivo existe, verificamos se ele realmente funciona
        final isValid = await _isBinaryValid(exePath);
        if (isValid) {
          needsExtraction = false;
          debugPrint("Binário yt-dlp verificado e válido: $exePath");
        } else {
          debugPrint("Binário corrompido. Removendo para re-extrair...");
          await file.delete();
        }
      }

      if (needsExtraction) {
        if (!await docDir.exists()) await docDir.create(recursive: true);

        debugPrint("Extraindo yt-dlp para: $exePath");
        final byteData = await rootBundle.load(names.$1);

        // Escrita direta e segura
        await file.writeAsBytes(
          byteData.buffer.asUint8List(
            byteData.offsetInBytes,
            byteData.lengthInBytes,
          ),
          flush: true,
        );

        if (Platform.isLinux || Platform.isMacOS) {
          await Process.run('chmod', ['+x', exePath]);
        }
      }

      if (!_extractionCompleter.isCompleted) {
        _extractionCompleter.complete(exePath);
      }
      return exePath;
    } catch (e) {
      _isExtracting = false;
      // Se houver erro, resetamos o completer para permitir nova tentativa
      throw Exception("Erro ao preparar yt-dlp: $e");
    } finally {
      _isExtracting = false;
    }
  }
}
