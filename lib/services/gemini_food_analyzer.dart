import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:calsnap/models/meal_entry.dart';
import 'package:calsnap/services/food_analyzer.dart';
import 'package:calsnap/services/settings_store.dart';
import 'package:http/http.dart' as http;

class GeminiFoodAnalyzer implements FoodAnalyzer {
  GeminiFoodAnalyzer({
    required SettingsStore settingsStore,
    http.Client? httpClient,
    Duration timeout = const Duration(seconds: 45),
  })  : _settingsStore = settingsStore,
        _httpClient = httpClient,
        _timeout = timeout;

  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  static const Map<String, Object?> _responseSchema = <String, Object?>{
    'type': 'object',
    'properties': <String, Object?>{
      'meal_title': <String, Object?>{'type': 'string'},
      'items': <String, Object?>{
        'type': 'array',
        'items': <String, Object?>{
          'type': 'object',
          'properties': <String, Object?>{
            'name': <String, Object?>{'type': 'string'},
            'portion_label': <String, Object?>{'type': 'string'},
            'grams': <String, Object?>{'type': 'number'},
            'calories': <String, Object?>{'type': 'number'},
            'protein_g': <String, Object?>{'type': 'number'},
            'carbs_g': <String, Object?>{'type': 'number'},
            'fat_g': <String, Object?>{'type': 'number'},
          },
          'required': <String>[
            'name',
            'portion_label',
            'grams',
            'calories',
            'protein_g',
            'carbs_g',
            'fat_g',
          ],
        },
      },
      'notes': <String, Object?>{'type': 'string'},
    },
    'required': <String>['meal_title', 'items'],
  };

  final SettingsStore _settingsStore;
  final http.Client? _httpClient;
  final Duration _timeout;

  @override
  Future<FoodAnalysisResult> analyze({
    required Uint8List imageBytes,
    required String mimeType,
    String? userNote,
  }) async {
    final settings = await _settingsStore.load();
    final apiKey = settings.apiKey?.trim();
    if (apiKey == null || apiKey.isEmpty) {
      throw const FoodAnalysisException(
        'API key Gemini belum diisi. Buka Pengaturan untuk menambahkannya.',
        code: 'missing_api_key',
      );
    }

    final model = settings.modelName.trim().isEmpty
        ? defaultGeminiModel
        : settings.modelName.trim();
    final uri = Uri.parse(
      '$_baseUrl/${Uri.encodeComponent(model)}:generateContent',
    );

    final requestBody = jsonEncode(<String, Object?>{
      'contents': <Object?>[
        <String, Object?>{
          'role': 'user',
          'parts': <Object?>[
            <String, Object?>{
              'inline_data': <String, Object?>{
                'mime_type': mimeType,
                'data': base64Encode(imageBytes),
              },
            },
            <String, Object?>{
              'text': _buildPrompt(userNote),
            },
          ],
        },
      ],
      'generationConfig': <String, Object?>{
        'temperature': 0.2,
        'responseMimeType': 'application/json',
        'responseJsonSchema': _responseSchema,
      },
    });

    final client = _httpClient ?? http.Client();
    final ownsClient = _httpClient == null;
    try {
      final response = await client
          .post(
            uri,
            headers: <String, String>{
              'Content-Type': 'application/json',
              'x-goog-api-key': apiKey,
            },
            body: requestBody,
          )
          .timeout(_timeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw _mapHttpError(response.statusCode, response.body, model);
      }

      return _parseResponse(response.body);
    } on FoodAnalysisException {
      rethrow;
    } on TimeoutException {
      throw const FoodAnalysisException(
        'Permintaan ke Gemini melewati batas waktu. Coba lagi.',
        code: 'timeout',
      );
    } on SocketException {
      throw const FoodAnalysisException(
        'Tidak ada koneksi internet. Periksa jaringan lalu coba lagi.',
        code: 'network_error',
      );
    } on http.ClientException {
      throw const FoodAnalysisException(
        'Gagal menghubungi server Gemini. Periksa koneksi internet Anda.',
        code: 'network_error',
      );
    } finally {
      if (ownsClient) {
        client.close();
      }
    }
  }

  String _buildPrompt(String? userNote) {
    final buffer = StringBuffer()
      ..writeln(
        'Analisis foto makanan atau minuman ini dan perkirakan kandungan gizinya.',
      )
      ..writeln(
        'Gunakan bahasa Indonesia untuk meal_title, name, portion_label, dan notes.',
      )
      ..writeln(
        'Pecah hidangan campur menjadi beberapa item bila terlihat (misalnya nasi putih, ayam goreng, sayur, sambal).',
      )
      ..writeln(
        'Berikan estimasi realistis untuk grams, calories (kkal), protein_g, carbs_g, dan fat_g (semua angka >= 0).',
      )
      ..writeln(
        'Jika foto tidak menampilkan makanan, minuman, atau label nutrisi sama sekali, kembalikan items sebagai array kosong.',
      );

    final trimmedNote = userNote?.trim();
    if (trimmedNote != null && trimmedNote.isNotEmpty) {
      buffer.writeln('Catatan tambahan dari pengguna: "$trimmedNote".');
    }
    return buffer.toString().trim();
  }

  FoodAnalysisException _mapHttpError(
    int statusCode,
    String responseBody,
    String model,
  ) {
    if (statusCode == 401 || statusCode == 403) {
      return FoodAnalysisException(
        'API key Gemini ditolak ($statusCode). Periksa ulang key Anda di Pengaturan.',
        code: 'invalid_api_key',
      );
    }
    if (statusCode == 404) {
      return FoodAnalysisException(
        'Model "$model" tidak ditemukan atau belum tersedia. Ganti nama model di Pengaturan.',
        code: 'model_not_found',
      );
    }
    if (statusCode == 429) {
      return const FoodAnalysisException(
        'Kuota permintaan Gemini sedang penuh. Tunggu sebentar lalu coba lagi.',
        code: 'rate_limited',
      );
    }

    final detail = _extractApiErrorMessage(responseBody);
    return FoodAnalysisException(
      detail == null
          ? 'Gagal menganalisis foto (HTTP $statusCode).'
          : 'Gagal menganalisis foto (HTTP $statusCode): $detail',
      code: 'http_$statusCode',
    );
  }

  String? _extractApiErrorMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['error'] is Map) {
        final message = (decoded['error'] as Map)['message'];
        if (message is String && message.trim().isNotEmpty) {
          return message.trim();
        }
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  FoodAnalysisResult _parseResponse(String body) {
    final Object? decoded;
    try {
      decoded = jsonDecode(body);
    } catch (_) {
      throw const FoodAnalysisException(
        'Respons server Gemini tidak valid.',
        code: 'invalid_response',
      );
    }

    if (decoded is! Map) {
      throw const FoodAnalysisException(
        'Format respons Gemini tidak dikenali.',
        code: 'invalid_response',
      );
    }

    final candidates = decoded['candidates'];
    if (candidates is! List || candidates.isEmpty) {
      throw const FoodAnalysisException(
        'Gemini tidak mengembalikan hasil analisis untuk foto ini.',
        code: 'empty_response',
      );
    }

    final firstCandidate = candidates.first;
    final content =
        firstCandidate is Map ? firstCandidate['content'] as Map? : null;
    final parts = content?['parts'];
    if (parts is! List || parts.isEmpty) {
      throw const FoodAnalysisException(
        'Hasil analisis Gemini kosong. Coba foto ulang.',
        code: 'empty_response',
      );
    }

    final textBuffer = StringBuffer();
    for (final part in parts) {
      // Thinking models emit thought: true parts before the final JSON payload.
      if (part is Map &&
          part['thought'] != true &&
          part['text'] is String) {
        textBuffer.write(part['text'] as String);
      }
    }

    final cleanedText = _stripCodeFences(textBuffer.toString());
    if (cleanedText.isEmpty) {
      throw const FoodAnalysisException(
        'Hasil analisis Gemini kosong. Coba foto ulang.',
        code: 'empty_response',
      );
    }

    final Object? parsedResult;
    try {
      parsedResult = jsonDecode(cleanedText);
    } catch (_) {
      throw const FoodAnalysisException(
        'Output Gemini tidak berformat JSON yang valid. Coba analisis ulang.',
        code: 'malformed_json',
      );
    }

    if (parsedResult is! Map) {
      throw const FoodAnalysisException(
        'Format hasil analisis tidak sesuai.',
        code: 'malformed_json',
      );
    }

    final rawItems = parsedResult['items'];
    final items = <FoodItem>[];
    if (rawItems is List) {
      for (final rawItem in rawItems) {
        if (rawItem is Map<String, dynamic>) {
          items.add(FoodItem.fromJson(rawItem));
        } else if (rawItem is Map) {
          items.add(FoodItem.fromJson(Map<String, dynamic>.from(rawItem)));
        }
      }
    }

    if (items.isEmpty) {
      throw const FoodAnalysisException(
        'Tidak ada makanan yang terdeteksi di foto ini. Coba ambil ulang atau isi manual.',
        code: 'no_food_detected',
      );
    }

    final rawTitle = (parsedResult['meal_title'] ?? '').toString().trim();
    final mealTitle = rawTitle.isEmpty ? items.first.name : rawTitle;
    final rawNotes = parsedResult['notes']?.toString().trim();

    return FoodAnalysisResult(
      mealTitle: mealTitle,
      items: items,
      notes: (rawNotes == null || rawNotes.isEmpty) ? null : rawNotes,
    );
  }

  String _stripCodeFences(String raw) {
    var trimmed = raw.trim();
    if (trimmed.startsWith('```')) {
      final firstNewline = trimmed.indexOf('\n');
      if (firstNewline != -1) {
        trimmed = trimmed.substring(firstNewline + 1);
      }
      if (trimmed.endsWith('```')) {
        trimmed = trimmed.substring(0, trimmed.length - 3);
      }
    }
    return trimmed.trim();
  }
}
