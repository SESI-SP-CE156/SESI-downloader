// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'python_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(pythonService)
final pythonServiceProvider = PythonServiceProvider._();

final class PythonServiceProvider
    extends $FunctionalProvider<PythonService, PythonService, PythonService>
    with $Provider<PythonService> {
  PythonServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pythonServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pythonServiceHash();

  @$internal
  @override
  $ProviderElement<PythonService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PythonService create(Ref ref) {
    return pythonService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PythonService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PythonService>(value),
    );
  }
}

String _$pythonServiceHash() => r'c29ff145b58f33cf127172c007c7ddba0e8a9780';
