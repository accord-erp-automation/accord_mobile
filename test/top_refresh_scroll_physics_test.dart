import 'package:erpnext_stock_mobile/src/core/widgets/top_refresh_scroll_physics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const physics = TopRefreshScrollPhysics();

  TestWidgetsFlutterBinding.ensureInitialized();

  test('allows top pull-to-refresh underscroll on short content', () {
    final metrics = FixedScrollMetrics(
      minScrollExtent: 0,
      maxScrollExtent: 0,
      pixels: 0,
      viewportDimension: 600,
      axisDirection: AxisDirection.down,
      devicePixelRatio: 1,
    );

    expect(physics.shouldAcceptUserOffset(metrics), isTrue);
    expect(physics.applyBoundaryConditions(metrics, -40), 0.0);
  });

  test('blocks bottom overscroll on short content', () {
    final metrics = FixedScrollMetrics(
      minScrollExtent: 0,
      maxScrollExtent: 0,
      pixels: 0,
      viewportDimension: 600,
      axisDirection: AxisDirection.down,
      devicePixelRatio: 1,
    );

    expect(physics.applyBoundaryConditions(metrics, 40), 40);
  });

  test('caps top pull-to-refresh overscroll distance', () {
    final metrics = FixedScrollMetrics(
      minScrollExtent: 0,
      maxScrollExtent: 0,
      pixels: 0,
      viewportDimension: 600,
      axisDirection: AxisDirection.down,
      devicePixelRatio: 1,
    );

    expect(physics.applyBoundaryConditions(metrics, -88), 0.0);
    expect(physics.applyBoundaryConditions(metrics, -140), -52.0);
  });
}
