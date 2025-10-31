import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mt_plugin/mt_plugin.dart';

void main() {
  const MethodChannel channel = MethodChannel('mt_plugin');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('', () async {
    expect(await MtPlugin.platformVersion, '42');
  });
}
