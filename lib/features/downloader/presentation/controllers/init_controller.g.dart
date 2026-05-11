// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'init_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AppInitialization)
final appInitializationProvider = AppInitializationProvider._();

final class AppInitializationProvider
    extends $NotifierProvider<AppInitialization, InitState> {
  AppInitializationProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appInitializationProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appInitializationHash();

  @$internal
  @override
  AppInitialization create() => AppInitialization();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InitState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InitState>(value),
    );
  }
}

String _$appInitializationHash() => r'0af28575f98af5c9b4cd234e67998dae0c5f29ca';

abstract class _$AppInitialization extends $Notifier<InitState> {
  InitState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<InitState, InitState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<InitState, InitState>,
              InitState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
