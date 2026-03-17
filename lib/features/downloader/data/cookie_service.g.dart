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
    extends $NotifierProvider<CookieService, bool> {
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
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$cookieServiceHash() => r'9001338c65d681a8385390ff9c01e4b807fefb67';

abstract class _$CookieService extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
