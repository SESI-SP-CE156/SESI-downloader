import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:open_file/open_file.dart';
import 'package:sesi_downloader/core/theme/app_theme.dart';
import 'package:sesi_downloader/features/downloader/domain/download_model.dart';
import 'package:sesi_downloader/features/downloader/presentation/controllers/download_controller.dart';
import 'package:sesi_downloader/features/downloader/presentation/widgets/download_list_tile.dart';
import 'package:sizer/sizer.dart';
import 'package:skeletonizer/skeletonizer.dart';

class HomeScreen extends HookConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final urlController = useTextEditingController();
    final downloadList = ref.watch(downloadListProvider);

    ref.listen<List<DownloadItem>>(downloadListProvider, (previous, next) {
      for (final newItem in next) {
        final oldItem = previous?.firstWhere(
          (e) => e.id == newItem.id,
          orElse: () => newItem,
        );
        if (newItem.isCompleted && (oldItem != null && !oldItem.isCompleted)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Download concluído: ${newItem.title}'),
              backgroundColor: Colors.green[700],
              action: SnackBarAction(
                label: 'ABRIR',
                textColor: Colors.white,
                onPressed: () {
                  if (newItem.filePath.isNotEmpty)
                    OpenFile.open(newItem.filePath);
                },
              ),
            ),
          );
        }
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.download_rounded, color: AppTheme.primaryColor),
            SizedBox(width: 8.sp),
            const Text('SESI Downloader'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
          ),
          SizedBox(width: 8.sp),
        ],
      ),
      body: Row(
        children: [
          // Navigation Rail
          NavigationRail(
            selectedIndex: 0,
            onDestinationSelected: (val) {},
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: Text('Início'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.folder_outlined),
                selectedIcon: Icon(Icons.folder),
                label: Text('Arquivos'),
              ),
            ],
          ),
          const VerticalDivider(
            width: 1,
            thickness: 1,
            color: AppTheme.borderColor,
          ),

          // Main Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(16.sp),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Input Area
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(12.sp),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Adicionar Novo Vídeo",
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          SizedBox(height: 12.sp),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: urlController,
                                  decoration: const InputDecoration(
                                    labelText: 'Cole o link do YouTube aqui...',
                                    prefixIcon: Icon(Icons.link),
                                  ),
                                  onSubmitted: (value) {
                                    if (value.isNotEmpty) {
                                      ref
                                          .read(downloadListProvider.notifier)
                                          .addDownload(
                                            value,
                                            DownloadQuality.extreme,
                                          );
                                      urlController.clear();
                                    }
                                  },
                                ),
                              ),
                              SizedBox(width: 8.sp),

                              ElevatedButton.icon(
                                onPressed: () {
                                  if (urlController.text.isNotEmpty) {
                                    // SEMPRE usa DownloadQuality.extreme
                                    ref
                                        .read(downloadListProvider.notifier)
                                        .addDownload(
                                          urlController.text,
                                          DownloadQuality.extreme,
                                        );
                                    urlController.clear();
                                  }
                                },
                                icon: const Icon(Icons.add),
                                label: const Text("Baixar"),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 16.sp),
                  Text(
                    "Downloads Recentes",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 8.sp),

                  // Lista
                  Expanded(
                    child:
                        downloadList.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.cloud_download_outlined,
                                    size: 40.sp,
                                    color: Colors.grey[400],
                                  ),
                                  SizedBox(height: 8.sp),
                                  Text(
                                    "Nenhum download ativo",
                                    style:
                                        Theme.of(context).textTheme.bodyLarge,
                                  ),
                                ],
                              ),
                            )
                            : ListView.builder(
                              itemCount: downloadList.length,
                              itemBuilder: (context, index) {
                                final item = downloadList[index];
                                final isSkeleton =
                                    item.status ==
                                    DownloadStatus.fetchingMetadata;

                                final itemForDisplay =
                                    isSkeleton
                                        ? DownloadItem(
                                          id: 'skeleton',
                                          title: 'Carregando informações...',
                                          thumbnailUrl: '',
                                          status:
                                              DownloadStatus.fetchingMetadata,
                                          resolution: "4K",
                                          audioBitrate: "Kbps",
                                        )
                                        : item;

                                return Skeletonizer(
                                  enabled: isSkeleton,
                                  child: DownloadListTile(
                                    item: itemForDisplay,
                                    onOpenFile: () {
                                      if (item.filePath.isNotEmpty)
                                        OpenFile.open(item.filePath);
                                    },
                                    onCancel: () {
                                      ref
                                          .read(downloadListProvider.notifier)
                                          .cancelDownload(item.id);
                                    },
                                  ),
                                );
                              },
                            ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
