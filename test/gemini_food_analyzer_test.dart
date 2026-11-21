import 'dart:convert';
import 'dart:typed_data';

import 'package:calsnap/services/food_analyzer.dart';
import 'package:calsnap/services/gemini_food_analyzer.dart';
import 'package:calsnap/services/settings_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'fakes.dart';

void main() {
  final sampleBytes = Uint8List.fromList(<int>[1, 2, 3, 4]);

  test('throws missing_api_key when no API key is configured', () async {
    final analyzer = GeminiFoodAnalyzer(
      settingsStore: FakeSettingsStore(const AppSettings()),
      httpClient: MockClient((_) async => http.Response('{}', 200)),
    );

    expect(
      () => analyzer.analyze(imageBytes: sampleBytes, mimeType: 'image/jpeg'),
      throwsA(
        isA<FoodAnalysisException>().having(
          (e) => e.code,
          'code',
          'missing_api_key',
        ),
      ),
    );
  });

  test('sends structured request and parses Gemini JSON response', () async {
    late http.Request capturedRequest;
    final mockClient = MockClient((request) async {
      capturedRequest = request;
      final body = jsonEncode(<String, Object?>{
        'candidates': <Object?>[
          <String, Object?>{
            'content': <String, Object?>{
              'parts': <Object?>[
                <String, Object?>{
                  'text': jsonEncode(<String, Object?>{
                    'meal_title': 'Soto Ayam',
                    'items': <Object?>[
                      <String, Object?>{
                        'name': 'Soto ayam kuah bening',
                        'portion_label': '1 mangkuk',
                        'grams': 350,
                        'calories': 310,
                        'protein_g': 22,
                        'carbs_g': 18,
                        'fat_g': -2,
                      },
                    ],
                    'notes': 'Estimasi termasuk suwiran ayam.',
                  }),
                },
              ],
            },
          },
        ],
      });
      return http.Response(body, 200);
    });

    final analyzer = GeminiFoodAnalyzer(
      settingsStore: FakeSettingsStore(
        const AppSettings(
          apiKey: 'test-key-123',
          modelName: 'gemini-3.5-flash-lite',
        ),
      ),
      httpClient: mockClient,
    );

    final result = await analyzer.analyze(
      imageBytes: sampleBytes,
      mimeType: 'image/jpeg',
      userNote: 'tanpa kulit',
    );

    expect(
      capturedRequest.url.toString(),
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash-lite:generateContent',
    );
    expect(capturedRequest.headers['x-goog-api-key'], 'test-key-123');

    final decodedReq = jsonDecode(capturedRequest.body) as Map<String, dynamic>;
    final parts = (decodedReq['contents'] as List).first['parts'] as List;
    expect(parts[0]['inline_data']['mime_type'], 'image/jpeg');
    expect(parts[0]['inline_data']['data'], base64Encode(sampleBytes));
    expect(parts[1]['text'], contains('tanpa kulit'));
    expect(
      decodedReq['generationConfig']['responseMimeType'],
      'application/json',
    );
    expect(decodedReq['generationConfig']['responseJsonSchema'], isMap);

    expect(result.mealTitle, 'Soto Ayam');
    expect(result.items, hasLength(1));
    expect(result.items.first.calories, 310);
    expect(result.items.first.fatGrams, 0);
    expect(result.notes, 'Estimasi termasuk suwiran ayam.');
  });

  test('strips markdown code fences from JSON candidate text', () async {
    final analyzer = GeminiFoodAnalyzer(
      settingsStore: FakeSettingsStore(const AppSettings(apiKey: 'key')),
      httpClient: MockClient((_) async {
        final body = jsonEncode(<String, Object?>{
          'candidates': <Object?>[
            <String, Object?>{
              'content': <String, Object?>{
                'parts': <Object?>[
                  <String, Object?>{
                    'text': '```json\n{"meal_title":"Pisang","items":[{"name":"Pisang","portion_label":"1 buah","grams":110,"calories":105,"protein_g":1.3,"carbs_g":27,"fat_g":0.4}]}\n```',
                  },
                ],
              },
            },
          ],
        });
        return http.Response(body, 200);
      }),
    );

    final result = await analyzer.analyze(
      imageBytes: sampleBytes,
      mimeType: 'image/jpeg',
    );
    expect(result.mealTitle, 'Pisang');
    expect(result.items.single.calories, 105);
  });

  test('ignores thinking parts emitted before final JSON output', () async {
    final analyzer = GeminiFoodAnalyzer(
      settingsStore: FakeSettingsStore(
        const AppSettings(apiKey: 'key', modelName: 'gemini-3.8-flash'),
      ),
      httpClient: MockClient((_) async {
        final body = jsonEncode(<String, Object?>{
          'candidates': <Object?>[
            <String, Object?>{
              'content': <String, Object?>{
                'parts': <Object?>[
                  <String, Object?>{
                    'thought': true,
                    'text': 'Analyzing rice and egg portions...',
                  },
                  <String, Object?>{
                    'text': '{"meal_title":"Telur Dadar","items":[{"name":"Telur dadar","portion_label":"1 butir","grams":65,"calories":110,"protein_g":7,"carbs_g":1,"fat_g":9}]}',
                  },
                ],
              },
            },
          ],
        });
        return http.Response(body, 200);
      }),
    );

    final result = await analyzer.analyze(
      imageBytes: sampleBytes,
      mimeType: 'image/jpeg',
    );
    expect(result.mealTitle, 'Telur Dadar');
    expect(result.items.single.calories, 110);
  });

  test('maps HTTP 401, 404, 429 and empty items to clear exceptions', () async {
    Future<void> expectCode(int status, String payload, String code) async {
      final analyzer = GeminiFoodAnalyzer(
        settingsStore: FakeSettingsStore(const AppSettings(apiKey: 'key')),
        httpClient: MockClient((_) async => http.Response(payload, status)),
      );
      await expectLater(
        analyzer.analyze(imageBytes: sampleBytes, mimeType: 'image/jpeg'),
        throwsA(
          isA<FoodAnalysisException>().having((e) => e.code, 'code', code),
        ),
      );
    }

    await expectCode(401, '{}', 'invalid_api_key');
    await expectCode(404, '{}', 'model_not_found');
    await expectCode(429, '{}', 'rate_limited');
    await expectCode(
      200,
      jsonEncode(<String, Object?>{
        'candidates': <Object?>[
          <String, Object?>{
            'content': <String, Object?>{
              'parts': <Object?>[
                <String, Object?>{'text': '{"meal_title":"","items":[]}'},
              ],
            },
          },
        ],
      }),
      'no_food_detected',
    );
  });
}
