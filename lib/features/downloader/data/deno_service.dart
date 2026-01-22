import 'dart:io';

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
  /// Verifica se o Deno está instalado e retorna o caminho do executável.
  /// Se não estiver, lança uma exceção orientando o usuário.
  Future<String> getDenoPathOrThrow() async {
    // 1. Tenta encontrar no PATH global (comando 'deno')
    if (await _checkDenoVersion('deno')) {
      return 'deno';
    }

    // 2. Tenta encontrar no caminho padrão (~/.deno/bin/deno)
    final standardPath = _getStandardDenoPath();
    if (await _checkDenoVersion(standardPath)) {
      return standardPath;
    }

    // 3. Se não encontrar, lança erro para a UI tratar
    throw DenoMissingException(
      "O Deno (ambiente JS) é necessário para baixar vídeos protegidos.\n"
      "Por favor, instale-o em https://deno.com/deploy ou via terminal:\n"
      "${Platform.isWindows ? 'irm https://deno.land/install.ps1 | iex' : 'curl -fsSL https://deno.land/install.sh | sh'}",
    );
  }

  String _getStandardDenoPath() {
    final home =
        Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (home == null) return 'deno';

    final exe = Platform.isWindows ? 'deno.exe' : 'deno';
    return '$home/.deno/bin/$exe';
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
