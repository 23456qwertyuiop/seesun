import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seesun/main.dart';
import 'package:seesun/widgets/liquid_glass/liquid_glass_dock.dart';

void main() {
  testWidgets('SeesunApp renders brand title, default city, and bottom dock at bottom',
      (WidgetTester tester) async {
    await tester.pumpWidget(const SeesunApp());
    expect(find.text('seesun'), findsOneWidget);
    expect(find.text('上海 今天日落'), findsOneWidget);

    final dockBox = tester.renderObject<RenderBox>(find.byType(LiquidGlassDock));
    final offset = dockBox.localToGlobal(Offset.zero);
    expect(offset.dy, greaterThan(450));
  });
}
