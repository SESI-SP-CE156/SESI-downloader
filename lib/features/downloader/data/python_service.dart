import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'python_service.g.dart';

@riverpod
PythonService pythonService(Ref ref) {
  return PythonService();
}

class PythonService {
  Future<void> ensurePythonInstalled() async {
    if (!Platform.isLinux) return;

    try {
      final result = await Process.run('python3', ['--version']);
      if (result.exitCode != 0) {
        throw Exception('Python3 não encontrado.');
      }
    } catch (e) {
      throw Exception(
        'O Python 3 é necessário no Linux para executar o downloader.\n'
        'Por favor, instale-o (sudo apt install python3 ou equivalente).',
      );
    }
  }
}
