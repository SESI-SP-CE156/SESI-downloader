// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cookie_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CookieService)
final cookieServiceProvider = CookieServiceProvider._();

final class CookieServiceProvider
    extends $NotifierProvider<CookieService, void> {
  CookieServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cookieServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cookieServiceHash();

  @$internal
  @override
  CookieService create() => CookieService();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$cookieServiceHash() => r'fdc22c3d310877387ae8e2d7b12583868374188e';

abstract class _$CookieService extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
