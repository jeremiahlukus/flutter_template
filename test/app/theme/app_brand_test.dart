import 'package:flutter_template/src/app/theme/app_brand.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every brand has a label and a seed', () {
    for (final brand in AppBrand.values) {
      expect(brand.label, isNotEmpty);
      expect(brand.seed.a, 1.0, reason: '${brand.name} seed must be opaque');
    }
  });

  test('labels are unique', () {
    final labels = AppBrand.values.map((b) => b.label).toList();
    expect(labels.toSet(), hasLength(labels.length));
  });

  test('seeds are unique', () {
    final seeds = AppBrand.values.map((b) => b.seed).toList();
    expect(seeds.toSet(), hasLength(seeds.length));
  });

  test('the fallback is one of the values', () {
    expect(AppBrand.values, contains(AppBrand.fallback));
  });

  group('decode', () {
    test('round-trips every brand', () {
      for (final brand in AppBrand.values) {
        expect(AppBrand.decode(brand.encode()), brand);
      }
    });

    test('falls back for null', () {
      expect(AppBrand.decode(null), AppBrand.fallback);
    });

    test('falls back for an empty string', () {
      expect(AppBrand.decode(''), AppBrand.fallback);
    });

    test('falls back for an unknown name', () {
      // A corrupt preference must not brick the app.
      expect(AppBrand.decode('chartreuse'), AppBrand.fallback);
    });
  });
}
