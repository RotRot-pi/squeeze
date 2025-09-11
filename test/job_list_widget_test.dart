import 'dart:io';
import 'dart:ui' show Size;
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:squeeze/app/app.dart';
import 'package:squeeze/features/home/presentation/pages/home_page.dart';

Future<File> _writeTempJpg(String name) async {
  final tmp = await Directory.systemTemp.createTemp('squeeze_w1_');
  final image = img.Image(width: 100, height: 80);
  final bytes = img.encodeJpg(image, quality: 90);
  final file = File(p.join(tmp.path, name));
  await file.writeAsBytes(bytes);
  return file;
}

void main() {
  testWidgets('Selecting/adding a file shows it in the job list', (
    tester,
  ) async {
    // Ensure enough surface area to avoid tight-layout overflows in tests
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const SqueezeApp());

    final file = await _writeTempJpg('queued.jpg');

    // Access the HomePage State and enqueue one file (simulates drop or picker)
    final stateObj = tester.state(find.byType(HomePage)) as dynamic;
    await stateObj.addDroppedItems([file.path]);

    await tester.pumpAndSettle();

    expect(find.text('queued.jpg'), findsOneWidget);
  });
}