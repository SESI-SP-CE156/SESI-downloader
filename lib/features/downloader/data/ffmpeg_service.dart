import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'ffmpeg_service.g.dart';

@riverpod
FfmpegService ffmpegService(Ref ref) {
  return FfmpegService();
}

class FfmpegService {
  final Dio _dio = Dio();
  static const String _prefsKey = 'ffmpeg_version_tag';
  static const String _repoUrl =
      'https://api.github.com/repos/yt-dlp/FFmpeg-Builds/releases/latest';

  /// Retorna o caminho final do executável no sistema
  Future<String> ensureFfmpegExtracted() async {
    final docDir = await getApplicationSupportDirectory();
    final ext = Platform.isWindows ? '.exe' : '';
    return '${docDir.path}${Platform.pathSeparator}ffmpeg$ext';
  }

  /// Verifica e atualiza o FFmpeg automaticamente
  Future<void> updateBinary() async {
    debugPrint("Verificando atualizações do FFmpeg...");
    try {
      final response = await _dio.get(_repoUrl);
      if (response.statusCode == 200) {
        final data = response.data;
        final latestTag = data['tag_name'] as String;

        final prefs = await SharedPreferences.getInstance();
        final currentTag = prefs.getString(_prefsKey);

        // Se a versão atual já for a mais recente, e o arquivo existir, encerra.
        final exePath = await ensureFfmpegExtracted();
        if (latestTag == currentTag && await File(exePath).exists()) {
          debugPrint("FFmpeg já está na versão mais recente ($latestTag).");
          return;
        }

        debugPrint(
          "Nova versão do FFmpeg encontrada: $latestTag. Iniciando download...",
        );
        await _downloadAndExtractFfmpeg(data['assets'] as List<dynamic>);

        // Atualiza a tag salva e dá permissão no Linux
        await prefs.setString(_prefsKey, latestTag);
        if (Platform.isLinux) {
          await Process.run('chmod', ['+x', exePath]);
        }

        debugPrint("FFmpeg atualizado com sucesso!");
      }
    } catch (e) {
      debugPrint("Falha ao atualizar FFmpeg: $e");
      // Se falhar (ex: sem internet), tentamos garantir que pelo menos exista um binário
      final exePath = await ensureFfmpegExtracted();
      if (!await File(exePath).exists()) {
        throw Exception("FFmpeg não encontrado e não foi possível baixar.");
      }
    }
  }

  Future<void> _downloadAndExtractFfmpeg(List<dynamic> assets) async {
    final docDir = await getApplicationSupportDirectory();
    final tempDir = Directory(
      '${docDir.path}${Platform.pathSeparator}ffmpeg_temp',
    );
    if (!await tempDir.exists()) await tempDir.create();

    String downloadUrl = '';
    String archiveName = '';

    // Seleciona o asset correto dependendo do SO
    for (var asset in assets) {
      final name = asset['name'] as String;
      if (Platform.isWindows && name.contains('win64-gpl.zip')) {
        downloadUrl = asset['browser_download_url'];
        archiveName = 'ffmpeg.zip';
        break;
      } else if (Platform.isLinux && name.contains('linux64-gpl.tar.xz')) {
        downloadUrl = asset['browser_download_url'];
        archiveName = 'ffmpeg.tar.xz';
        break;
      }
    }

    if (downloadUrl.isEmpty)
      throw Exception("Build do FFmpeg não encontrada para este SO.");

    final archivePath = '${tempDir.path}${Platform.pathSeparator}$archiveName';

    // Faz o download do arquivo comprimido
    await _dio.download(downloadUrl, archivePath);

    // Usa ferramentas nativas do SO para extrair (evita dependências pesadas no Dart)
    if (Platform.isWindows) {
      final result = await Process.run('powershell', [
        '-command',
        'Expand-Archive -Path "$archivePath" -DestinationPath "${tempDir.path}" -Force',
      ]);
      if (result.exitCode != 0)
        throw Exception("Erro ao extrair zip: ${result.stderr}");
    } else if (Platform.isLinux) {
      final result = await Process.run('tar', [
        '-xf',
        archivePath,
        '-C',
        tempDir.path,
      ]);
      if (result.exitCode != 0)
        throw Exception("Erro ao extrair tar.xz: ${result.stderr}");
    }

    // Procura o binário extraído nas subpastas e move para o local definitivo
    final exeName = Platform.isWindows ? 'ffmpeg.exe' : 'ffmpeg';
    final files = tempDir.listSync(recursive: true);
    File? extractedFfmpeg;

    for (var entity in files) {
      // Usamos .path.endsWith para garantir que não vamos pegar outro arquivo com 'ffmpeg' no nome
      if (entity is File &&
          entity.path.endsWith(Platform.pathSeparator + exeName)) {
        extractedFfmpeg = entity;
        break;
      }
    }

    if (extractedFfmpeg != null) {
      final finalPath = await ensureFfmpegExtracted();
      // Em alguns SOs não é possível dar rename entre partições diferentes, então fazemos cópia e delete
      await extractedFfmpeg.copy(finalPath);
    } else {
      throw Exception(
        "Binário $exeName não encontrado dentro do arquivo baixado.",
      );
    }

    // Limpeza da pasta temporária
    await tempDir.delete(recursive: true);
  }
}
