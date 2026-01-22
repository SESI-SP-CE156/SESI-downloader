// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'download_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(DownloadList)
final downloadListProvider = DownloadListProvider._();

final class DownloadListProvider
    extends $NotifierProvider<DownloadList, List<DownloadItem>> {
  DownloadListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'downloadListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$downloadListHash();

  @$internal
  @override
  DownloadList create() => DownloadList();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<DownloadItem> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<DownloadItem>>(value),
    );
  }
}

String _$downloadListHash() => r'f45c145b69bc35e04c663df4e6651b956b34db5e';

abstract class _$DownloadList extends $Notifier<List<DownloadItem>> {
  List<DownloadItem> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<List<DownloadItem>, List<DownloadItem>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<DownloadItem>, List<DownloadItem>>,
              List<DownloadItem>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
