import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'deno_service.g.dart';

class DenoMissingException implements Exception {
  final String message;
  DenoMissingException(this.message);
  @override
  String toString() => message;
}

@riverpod
DenoService denoService(Ref ref) {
  return DenoService();
}

class DenoService {
  final Dio _dio = Dio();

  Future<String> _getLocalDenoPath() async {
    final dir = await getApplicationSupportDirectory();
    return '${dir.path}${Platform.pathSeparator}deno${Platform.isWindows ? '.exe' : ''}';
  }

  /// Verifica se o Deno está instalado e retorna o caminho do executável.
  /// Se não estiver, lança uma exceção orientando o usuário.
  Future<String> getDenoPathOrThrow() async {
    final localPath = await _getLocalDenoPath();
    if (await File(localPath).exists()) {
      return localPath;
    }
    // 1. Tenta encontrar no PATH global (comando 'deno')
    if (await _checkDenoVersion('deno')) {
      return 'deno';
    }

    throw Exception("Deno não encontrado.");
  }

  Future<void> installDeno() async {
    ProcessResult result;

    if (Platform.isLinux) {
      debugPrint("Instalando Deno no Linux...");
      // Executa via shell para suportar o pipe (|)
      result = await Process.run('sh', [
        '-c',
        'curl -fsSL https://deno.land/install.sh | sh',
      ]);
    } else if (Platform.isWindows) {
      debugPrint("Instalando Deno no Windows...");
      // Executa via PowerShell para suportar o pipe (|)
      result = await Process.run('powershell', [
        '-Command',
        'irm https://deno.land/install.ps1 | iex',
      ]);
    } else {
      throw UnsupportedError("Instalação automática não suportada neste SO.");
    }

    if (result.exitCode != 0) {
      throw Exception("Falha na instalação do Deno: ${result.stderr}");
    }

    debugPrint("Deno instalado com sucesso.");
  }

  Future<bool> _checkDenoVersion(String executable) async {
    try {
      final result = await Process.run(executable, ['--version']);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }
}
