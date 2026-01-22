// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deno_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(denoService)
final denoServiceProvider = DenoServiceProvider._();

final class DenoServiceProvider
    extends $FunctionalProvider<DenoService, DenoService, DenoService>
    with $Provider<DenoService> {
  DenoServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'denoServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$denoServiceHash();

  @$internal
  @override
  $ProviderElement<DenoService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DenoService create(Ref ref) {
    return denoService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DenoService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DenoService>(value),
    );
  }
}

String _$denoServiceHash() => r'd673e92e6bebc82a4f48b4126bfb5502de28e9bf';
