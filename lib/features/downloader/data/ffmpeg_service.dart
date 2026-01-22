import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ffmpeg_service.g.dart';

@riverpod
FfmpegService ffmpegService(Ref ref) {
  return FfmpegService();
}

class FfmpegService {
  static final _extractionCompleter = Completer<String>();
  static bool _isExtracting = false;

  (String assetName, String fileName) _getPlatformNames() {
    if (Platform.isWindows) {
      return ('assets/bin/ffmpeg.exe', 'ffmpeg.exe');
    } else if (Platform.isLinux) {
      return ('assets/bin/ffmpeg', 'ffmpeg');
    } else if (Platform.isMacOS) {
      // Caso queira suportar Mac futuramente
      return ('assets/bin/ffmpeg_mac', 'ffmpeg');
    }
    throw Exception("Sistema operacional não suportado para FFmpeg embutido.");
  }

  Future<bool> _isBinaryValid(String path) async {
    try {
      final result = await Process.run(path, ['-version']);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  /// Garante que o FFmpeg esteja extraído e pronto para uso
  Future<String> ensureFfmpegExtracted() async {
    if (_isExtracting) {
      return _extractionCompleter.future;
    }

    if (_extractionCompleter.isCompleted) {
      return _extractionCompleter.future;
    }

    final docDir = await getApplicationSupportDirectory();
    final names = _getPlatformNames();
    final ffmpegPath = '${docDir.path}${Platform.pathSeparator}${names.$2}';
    final file = File(ffmpegPath);

    bool needsExtraction = true;

    if (await file.exists()) {
      final isValid = await _isBinaryValid(ffmpegPath);

      if (isValid) {
        needsExtraction = false;
        debugPrint("Binário ffmpeg verificado e válido: $ffmpegPath");
      } else {
        debugPrint(
          "Binário ffmpeg corrompido ou inválido. Removendo para re-extraír...",
        );
        await file.delete();
        needsExtraction = true;
      }

      if (Platform.isLinux || Platform.isMacOS) {
        await Process.run('chmod', ['+x', ffmpegPath]);
      }

      if (!_extractionCompleter.isCompleted) {
        _extractionCompleter.complete(ffmpegPath);
      }
      return ffmpegPath;
    }

    _isExtracting = true;

    // Se o arquivo não existir, extrai dos assets
    if (!await file.exists()) {
      try {
        // Cria o diretório se não existir
        if (!await docDir.exists()) {
          await docDir.create(recursive: true);
        }

        debugPrint("Extraindo ffmpeg para: $ffmpegPath");

        // Carrega do asset e escreve no disco
        final byteData = await rootBundle.load(names.$1);
        final buffer = byteData.buffer;

        await file.writeAsBytes(
          buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
          flush: true,
        );

        // --- PASSO CRUCIAL PARA LINUX/MAC ---
        // Arquivos extraídos perdem a permissão de execução.
        // Precisamos restaurar o bit executável.
        if (Platform.isLinux || Platform.isMacOS) {
          await Process.run('chmod', ['+x', ffmpegPath]);
        }

        _extractionCompleter.complete(ffmpegPath);
        return ffmpegPath;
      } catch (e) {
        _isExtracting = false;

        throw Exception("Erro ao extrair FFmpeg: $e");
      }
    }
    return ffmpegPath;
  }

  /// Une Áudio e Vídeo sem re-encodar (super rápido)
  Future<void> mergeAudioVideo({
    required String videoPath,
    required String audioPath,
    required String outputPath,
  }) async {
    final ffmpegPath = await ensureFfmpegExtracted();

    // Comando: ffmpeg -i video -i audio -c copy output
    // -c copy: Copia os streams sem converter (instantâneo e sem perda de qualidade)
    // -y: Sobrescreve se existir
    final result = await Process.run(ffmpegPath, [
      '-i',
      videoPath,
      '-i',
      audioPath,
      '-c',
      'copy',
      '-y',
      outputPath,
    ]);

    if (result.exitCode != 0) {
      throw Exception("Erro no FFmpeg: ${result.stderr}");
    }
  }
}
