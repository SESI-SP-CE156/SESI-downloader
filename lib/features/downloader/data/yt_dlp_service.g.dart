// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'yt_dlp_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ytDlpService)
final ytDlpServiceProvider = YtDlpServiceProvider._();

final class YtDlpServiceProvider
    extends $FunctionalProvider<YtDlpService, YtDlpService, YtDlpService>
    with $Provider<YtDlpService> {
  YtDlpServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ytDlpServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ytDlpServiceHash();

  @$internal
  @override
  $ProviderElement<YtDlpService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  YtDlpService create(Ref ref) {
    return ytDlpService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(YtDlpService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<YtDlpService>(value),
    );
  }
}

String _$ytDlpServiceHash() => r'1cbe6025f84b9bd5c81afa018528708e8fbd350d';
