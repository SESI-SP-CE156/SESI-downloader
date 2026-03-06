// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'browser_detection_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(BrowserDetection)
final browserDetectionProvider = BrowserDetectionProvider._();

final class BrowserDetectionProvider
    extends $NotifierProvider<BrowserDetection, List<String>> {
  BrowserDetectionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'browserDetectionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$browserDetectionHash();

  @$internal
  @override
  BrowserDetection create() => BrowserDetection();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<String>>(value),
    );
  }
}

String _$browserDetectionHash() => r'e52e62628c88eaa61d6f62038fc89f54958e0f2c';

abstract class _$BrowserDetection extends $Notifier<List<String>> {
  List<String> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<List<String>, List<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<String>, List<String>>,
              List<String>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
