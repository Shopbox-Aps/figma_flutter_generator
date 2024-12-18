import 'package:test/test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:svg_fetch_to_icon_font/services/figma_api_service.dart';
import 'package:svg_fetch_to_icon_font/constants/figma_constants.dart';

import 'figma_api_service_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  late MockClient mockClient;
  late FigmaApiService figmaApi;

  setUp(() {
    mockClient = MockClient.new();
    figmaApi = FigmaApiService('test_token', 'test_file_id', client: mockClient);
  });

  group('FigmaApiService', () {
    test('fetchNode returns correct data', () async {
      final nodeId = '123:456';
      final expectedUrl = 
          '${FigmaConstants.baseUrl}/files/test_file_id/nodes?ids=123:456';
      
      when(mockClient.get(
        Uri.parse(expectedUrl),
        headers: {'X-Figma-Token': 'test_token'},
      )).thenAnswer((_) async => http.Response(
        '{"nodes": {"123:456": {"document": {"test": "data"}}}}',
        200,
      ));

      final result = await figmaApi.fetchNode(nodeId);
      expect(result, {'test': 'data'});
    });

    test('exportImages returns correct URLs', () async {
      final vectorIds = ['id1', 'id2'];
      final expectedUrl = 
          '${FigmaConstants.baseUrl}/images/test_file_id?ids=id1,id2&format=svg&scale=1';
      
      when(mockClient.get(
        Uri.parse(expectedUrl),
        headers: {'X-Figma-Token': 'test_token'},
      )).thenAnswer((_) async => http.Response(
        '{"images": {"id1": "url1", "id2": "url2"}}',
        200,
      ));

      final result = await figmaApi.exportImages(vectorIds, exportAsSvg: true);
      expect(result, {'id1': 'url1', 'id2': 'url2'});
    });

    test('fetchVariables returns correct data', () async {
      final expectedUrl = 
          '${FigmaConstants.baseUrl}/files/test_file_id${FigmaConstants.variablesEndpoint}';
      
      when(mockClient.get(
        Uri.parse(expectedUrl),
        headers: {'X-Figma-Token': 'test_token'},
      )).thenAnswer((_) async => http.Response(
        '{"meta": {"variables": {"var1": {"test": "data"}}}}',
        200,
      ));

      final result = await figmaApi.fetchVariables();
      expect(result['meta']['variables']['var1'], {'test': 'data'});
    });

    test('handles API errors correctly', () async {
      final expectedUrl = 
          '${FigmaConstants.baseUrl}/files/test_file_id${FigmaConstants.variablesEndpoint}';
      
      when(mockClient.get(
        Uri.parse(expectedUrl),
        headers: {'X-Figma-Token': 'test_token'},
      )).thenAnswer((_) async => http.Response(
        '{"error": "Invalid token"}',
        401,
      ));

      expect(
        () => figmaApi.fetchVariables(),
        throwsA(isA<Exception>()),
      );
    });
  });
} 