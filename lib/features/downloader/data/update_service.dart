// lib/features/downloader/data/update_service.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:url_launcher/url_launcher.dart';

part 'update_service.g.dart';

@riverpod
UpdateService updateService(Ref ref) {
  return UpdateService();
}

class UpdateService {
  final Dio _dio = Dio();
  final String repo = "SESI-SP-CE156/SESI-downloader";

  Future<void> checkForUpdates(BuildContext context) async {
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;
    debugPrint(currentVersion);

    try {
      final response = await _dio.get(
        'https://api.github.com/repos/$repo/releases/latest',
      );

      if (response.statusCode == 200) {
        final json = response.data;
        // Assume que a tag no GitHub está como 'v1.0.0'
        final latestVersion = json['tag_name'].toString().replaceAll('v', '');

        if (latestVersion != currentVersion) {
          if (context.mounted) {
            _showUpdateDialog(context, json['html_url']);
          }
        }
      }
    } catch (e) {
      debugPrint("Erro ao verificar atualizações: $e");
    }
  }

  void _showUpdateDialog(BuildContext context, String url) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text("Atualização disponível!"),
            content: const Text(
              "Uma nova versão está disponível. Deseja baixar?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Agora não"),
              ),
              ElevatedButton(
                onPressed: () => launchUrl(Uri.parse(url)),
                child: const Text("Baixar"),
              ),
            ],
          ),
    );
  }
}
