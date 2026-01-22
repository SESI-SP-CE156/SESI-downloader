// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ffmpeg_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ffmpegService)
final ffmpegServiceProvider = FfmpegServiceProvider._();

final class FfmpegServiceProvider
    extends $FunctionalProvider<FfmpegService, FfmpegService, FfmpegService>
    with $Provider<FfmpegService> {
  FfmpegServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ffmpegServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ffmpegServiceHash();

  @$internal
  @override
  $ProviderElement<FfmpegService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FfmpegService create(Ref ref) {
    return ffmpegService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FfmpegService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FfmpegService>(value),
    );
  }
}

String _$ffmpegServiceHash() => r'99ce36b399d54d9c28e5838773ad567b882f5b38';
