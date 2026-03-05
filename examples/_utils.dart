import 'dart:io';

import 'package:openai_dart/openai_dart.dart';

String? readDotEnvValue(String key) {
  final file = File('.env');
  if (!file.existsSync()) {
    return null;
  }

  for (final raw in file.readAsLinesSync()) {
    final line = raw.trim();
    if (line.isEmpty || line.startsWith('#')) {
      continue;
    }

    final eq = line.indexOf('=');
    if (eq <= 0) {
      continue;
    }

    final k = line.substring(0, eq).trim();
    if (k != key) {
      continue;
    }

    var v = line.substring(eq + 1).trim();
    if (v.startsWith('"') && v.endsWith('"') && v.length >= 2) {
      v = v.substring(1, v.length - 1);
    } else if (v.startsWith("'") && v.endsWith("'") && v.length >= 2) {
      v = v.substring(1, v.length - 1);
    }

    return v;
  }

  return null;
}

String loadApiKey() {
  final key =
      Platform.environment['DEEPSEEK_API_KEY'] ??
      readDotEnvValue('DEEPSEEK_API_KEY');
  if (key == null || key.isEmpty) {
    throw StateError(
      'Missing DEEPSEEK_API_KEY. Set env var or put it in .env file.',
    );
  }
  return key;
}

OpenAI createClient({bool beta = false}) {
  return OpenAI(
    apiKey: loadApiKey(),
    baseUrl: beta
        ? 'https://api.deepseek.com/beta'
        : 'https://api.deepseek.com',
  );
}
