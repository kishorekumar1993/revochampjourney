import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revojourneytryone/core/component_engine/models/component_node.dart';
import 'package:revojourneytryone/core/component_engine/renderer/component_renderer.dart';

void main() {
  setUpAll(() {
    HttpOverrides.global = MockHttpOverrides();
  });
  testWidgets('ComponentRenderer renders Container child slot correctly', (WidgetTester tester) async {
    final childNode = ComponentNode(
      id: 'text-child',
      type: 'Text',
      properties: {'text': 'Hello Slot'},
      children: [],
      actions: [],
    );

    final containerNode = ComponentNode(
      id: 'container',
      type: 'Container',
      properties: {},
      children: [],
      slots: {'child': childNode},
      actions: [],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: ComponentRenderer.render(
              containerNode,
              isDesignMode: false,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Hello Slot'), findsOneWidget);
  });

  testWidgets('ComponentRenderer renders legacy Container direct child fallback correctly', (WidgetTester tester) async {
    final childNode = ComponentNode(
      id: 'text-child-legacy',
      type: 'Text',
      properties: {'text': 'Legacy Slot'},
      children: [],
      actions: [],
    );

    final containerNode = ComponentNode(
      id: 'container-legacy',
      type: 'Container',
      properties: {},
      children: [childNode],
      slots: {'child': null},
      actions: [],
    );

    expect(containerNode.getSlotChild('child')?.id, 'text-child-legacy');
    expect(containerNode.hasSlotChild('child'), isTrue);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: ComponentRenderer.render(
              containerNode,
              isDesignMode: false,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Legacy Slot'), findsOneWidget);
  });

  testWidgets('ComponentRenderer renders complex nested tree perfectly and supports CRUD + Serialization', (WidgetTester tester) async {
    // 1. Build the nested widget definition:
    // Scaffold -> body slot: Column -> [Container -> Text, Row -> [Image, Button]]
    final textNode = ComponentNode(
      id: 'text-1',
      type: 'Text',
      properties: {'label': 'Nested Text Content'},
      children: [],
      actions: [],
    );

    final containerNode = ComponentNode(
      id: 'container-1',
      type: 'Container',
      properties: {},
      children: [],
      slots: {'child': textNode},
      actions: [],
    );

    final imageNode = ComponentNode(
      id: 'image-1',
      type: 'Image',
      properties: {
        'src': 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=500',
        'width': 100.0,
        'height': 100.0,
      },
      children: [],
      actions: [],
    );

    final buttonNode = ComponentNode(
      id: 'button-1',
      type: 'Button',
      properties: {'label': 'Click Me'},
      children: [],
      actions: [],
    );

    final rowNode = ComponentNode(
      id: 'row-1',
      type: 'Row',
      properties: {},
      children: [imageNode, buttonNode],
      actions: [],
    );

    final columnNode = ComponentNode(
      id: 'column-1',
      type: 'Column',
      properties: {},
      children: [containerNode, rowNode],
      actions: [],
    );

    final scaffoldNode = ComponentNode(
      id: 'scaffold-1',
      type: 'Scaffold',
      properties: {},
      children: [],
      slots: {'body': columnNode},
      actions: [],
    );

    // 2. Render & Mount
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: ComponentRenderer.render(
              scaffoldNode,
              isDesignMode: false,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify all components render correctly
    expect(find.text('Nested Text Content'), findsOneWidget);
    expect(find.text('Click Me'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);

    // 3. Save (Serialization)
    final jsonMap = scaffoldNode.toJson();
    expect(jsonMap['type'], 'Scaffold');
    expect(jsonMap['slots']['body']['type'], 'Column');
    expect(jsonMap['slots']['body']['children'][0]['type'], 'Container');
    expect(jsonMap['slots']['body']['children'][0]['slots']['child']['type'], 'Text');

    // 4. Load (Deserialization)
    final reconstructedNode = ComponentNode.fromJson(jsonMap);
    expect(reconstructedNode.type, 'Scaffold');
    expect(reconstructedNode.slots['body']?.type, 'Column');
    expect(reconstructedNode.slots['body']?.children[0].type, 'Container');
    expect(reconstructedNode.slots['body']?.children[0].getSlotChild('child')?.type, 'Text');
    expect(reconstructedNode.slots['body']?.children[1].children[0].type, 'Image');
    expect(reconstructedNode.slots['body']?.children[1].children[1].type, 'Button');
  });
}

// ── MOCK HTTP OVERRIDES FOR IMAGES IN UNIT TESTS ─────────────────────────────

class MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _MockHttpClient();
  }
}

class _MockHttpClient implements HttpClient {
  @override
  bool autoUncompress = true;

  @override
  Duration? connectionTimeout;

  @override
  Duration idleTimeout = const Duration(seconds: 15);

  @override
  int? maxConnectionsPerHost = 10;

  @override
  String? userAgent = 'Dart';

  @override
  Future<HttpClientRequest> get(String host, int port, String path) {
    return Future.value(_MockHttpClientRequest());
  }

  @override
  Future<HttpClientRequest> getUrl(Uri url) {
    return Future.value(_MockHttpClientRequest());
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _MockHttpClientRequest implements HttpClientRequest {
  @override
  Future<HttpClientResponse> close() {
    return Future.value(_MockHttpClientResponse());
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _MockHttpClientResponse implements HttpClientResponse {
  @override
  int get statusCode => 200;

  @override
  int get contentLength => _transparentImage.length;

  @override
  HttpClientResponseCompressionState get compressionState => HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable([_transparentImage]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

final List<int> _transparentImage = [
  0x47, 0x49, 0x46, 0x38, 0x39, 0x61, 0x01, 0x00, 0x01, 0x00, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00,
  0xff, 0xff, 0xff, 0x21, 0xf9, 0x04, 0x01, 0x00, 0x00, 0x00, 0x00, 0x2c, 0x00, 0x00, 0x00, 0x00,
  0x01, 0x00, 0x01, 0x00, 0x00, 0x02, 0x02, 0x44, 0x01, 0x00, 0x3b
];
