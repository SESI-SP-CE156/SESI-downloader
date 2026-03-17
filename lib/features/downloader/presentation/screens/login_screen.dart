// lib/features/downloader/presentation/screens/login_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:sesi_downloader/features/downloader/data/cookie_service.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!Platform.isWindows)
      return const Scaffold(body: Text("Apenas Windows"));

    return Scaffold(
      appBar: AppBar(title: const Text("Login YouTube")),
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: InAppWebView(
          initialSettings: InAppWebViewSettings(
            transparentBackground: true, // Evita o flash branco
          ),
          initialUrlRequest: URLRequest(url: WebUri("https://www.youtube.com")),
          onLoadStop: (controller, url) async {
            // Verifica se carregou o YouTube
            if (url?.host.contains("youtube.com") ?? false) {
              CookieManager cookieManager = CookieManager.instance();
              List<Cookie> cookies = await cookieManager.getCookies(
                url: WebUri("https://www.youtube.com"),
              );

              // Converte para o formato que o service espera
              final cookieList = cookies.map((c) => c.toJson()).toList();
              await ref
                  .read(cookieServiceProvider.notifier)
                  .saveCookies(cookieList);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Login capturado com sucesso!")),
                );
              }
            }
          },
        ),
      ),
    );
  }
}
