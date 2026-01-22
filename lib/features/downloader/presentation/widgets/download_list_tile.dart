import 'package:flutter/material.dart';
import 'package:sesi_downloader/core/theme/app_theme.dart';
import 'package:sesi_downloader/features/downloader/domain/download_model.dart';
import 'package:sizer/sizer.dart';
import 'package:skeletonizer/skeletonizer.dart';

class DownloadListTile extends StatelessWidget {
  final DownloadItem item;
  final VoidCallback? onCancel;
  final VoidCallback? onOpenFile;

  const DownloadListTile({
    super.key,
    required this.item,
    this.onCancel,
    this.onOpenFile,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 8.sp),
      child: Padding(
        padding: EdgeInsets.all(8.sp),
        child: Row(
          children: [
            // Thumbnail
            Skeleton.keep(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child:
                    item.thumbnailUrl.isNotEmpty
                        ? Image.network(
                          item.thumbnailUrl,
                          width: 55.sp,
                          height: 45.sp,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildPlaceholder(),
                        )
                        : _buildPlaceholder(),
              ),
            ),
            SizedBox(width: 12.sp),

            // Info Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 12.sp,
                    ),
                  ),

                  // Autor (Novo)
                  if (item.author.isNotEmpty)
                    Text(
                      item.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                        fontSize: 11.sp,
                      ),
                    ),

                  SizedBox(height: 4.h),

                  // Badges: Resolução | Tamanho | Audio (se souber)
                  Wrap(
                    spacing: 8.sp,
                    children: [
                      _buildBadge(context, Icons.hd_outlined, item.resolution),

                      // Tamanho (Novo)
                      if (item.totalSizeString != '-' &&
                          item.totalSizeString.isNotEmpty)
                        _buildBadge(
                          context,
                          Icons.sd_storage_outlined,
                          item.totalSizeString,
                        ),

                      // ETA
                      if (item.isDownloading)
                        _buildBadge(
                          context,
                          Icons.timer_outlined,
                          item.eta,
                          color: Colors.blue[700],
                        ),
                    ],
                  ),

                  SizedBox(height: 6.sp),
                  _buildStatusRow(context),
                ],
              ),
            ),

            // Actions
            if (item.status == DownloadStatus.completed)
              IconButton(
                icon: const Icon(Icons.folder_open),
                tooltip: 'Abrir arquivo',
                onPressed: onOpenFile,
              )
            else if (item.isDownloading ||
                item.status == DownloadStatus.pending ||
                item.status == DownloadStatus.fetchingMetadata)
              IconButton(
                icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                tooltip: 'Cancelar download',
                onPressed:
                    item.status == DownloadStatus.fetchingMetadata
                        ? null
                        : onCancel,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(
    BuildContext context,
    IconData icon,
    String text, {
    Color? color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10.sp, color: color ?? Colors.grey[600]),
        SizedBox(width: 2.sp),
        Text(
          text,
          style: TextStyle(
            fontSize: 10.sp,
            color: color ?? Colors.grey[800],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 55.sp,
      height: 45.sp,
      color: Colors.grey[300],
      child: const Icon(Icons.image, color: Colors.grey),
    );
  }

  Widget _buildStatusRow(BuildContext context) {
    switch (item.status) {
      case DownloadStatus.pending:
        return Text(
          "Aguardando fila...",
          style: TextStyle(color: Colors.orange[800], fontSize: 10.sp),
        );
      case DownloadStatus.processing:
        return Row(
          children: [
            SizedBox(
              width: 10.sp,
              height: 10.sp,
              child: const CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 6.sp),
            Text(
              "Unindo Áudio/Vídeo...",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        );
      case DownloadStatus.completed:
        return Text(
          "Concluído",
          style: TextStyle(
            color: Colors.green[700],
            fontSize: 10.sp,
            fontWeight: FontWeight.bold,
          ),
        );
      case DownloadStatus.error:
        return Text(
          "Erro: ${item.error}",
          style: TextStyle(color: Colors.red, fontSize: 10.sp),
          maxLines: 1,
        );
      case DownloadStatus.fetchingMetadata:
        return Text(
          "Buscando informações...",
          style: Theme.of(context).textTheme.bodyMedium,
        );
      case DownloadStatus.canceled:
        return Text(
          "Cancelado",
          style: TextStyle(color: Colors.grey, fontSize: 10.sp),
        );
      case DownloadStatus.downloading:
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(
              value: item.progress,
              borderRadius: BorderRadius.circular(2),
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation(AppTheme.primaryColor),
            ),
            SizedBox(height: 2.sp),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${(item.progress * 100).toStringAsFixed(0)}%",
                  style: TextStyle(fontSize: 10.sp),
                ),
              ],
            ),
          ],
        );
    }
  }
}
