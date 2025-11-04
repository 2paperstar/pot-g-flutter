#!/usr/bin/env dart
/// API 채널 키 생성 유틸리티
/// 
/// 사용법:
///   dart run tools/generate_api_channel_key.dart <channel> [secret]
/// 
/// 예시:
///   dart run tools/generate_api_channel_key.dart qa
///   dart run tools/generate_api_channel_key.dart dev my-secret-key
/// 
/// 출력 형식:
///   channel:timestamp:signature
/// 
/// 이 값을 URL에 사용:
///   https://pot-g.gistory.me/test#key=channel:timestamp:signature

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

void main(List<String> args) {
  if (args.isEmpty || args.length > 2) {
    print('Usage: dart run tools/generate_api_channel_key.dart <channel> [secret]');
    print('');
    print('Channels: dev, qa, prod');
    print('');
    print('Examples:');
    print('  dart run tools/generate_api_channel_key.dart qa');
    print('  dart run tools/generate_api_channel_key.dart dev my-secret-key');
    exit(1);
  }

  final channel = args[0].toLowerCase();
  if (!['dev', 'qa', 'prod'].contains(channel)) {
    print('Error: Invalid channel. Must be one of: dev, qa, prod');
    exit(1);
  }

  // 시크릿 키 가져오기
  String secret;
  if (args.length == 2) {
    secret = args[1];
  } else {
    // 환경 변수에서 가져오기
    secret = Platform.environment['API_CHANNEL_KEY_SECRET'] ?? '';
    if (secret.isEmpty) {
      print('Error: Secret key not provided.');
      print('');
      print('Please provide secret key either as:');
      print('  1. Second argument: dart run tools/generate_api_channel_key.dart qa my-secret');
      print('  2. Environment variable: API_CHANNEL_KEY_SECRET=my-secret dart run ...');
      exit(1);
    }
  }

  // 타임스탬프 생성 (현재 시간, 초 단위)
  final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

  // 서명 생성
  final message = '$channel:$timestamp';
  final key = utf8.encode(secret);
  final bytes = utf8.encode(message);
  final hmac = Hmac(sha256, key);
  final digest = hmac.convert(bytes);
  final signature = digest.toString();

  // 키 생성
  final apiKey = '$channel:$timestamp:$signature';

  print('');
  print('Generated API Channel Key:');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print(apiKey);
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('');
  print('URL:');
  print('https://pot-g.gistory.me/test#key=$apiKey');
  print('');
  print('Channel: $channel');
  print('Timestamp: $timestamp (${DateTime.fromMillisecondsSinceEpoch(timestamp * 1000)})');
  print('Expires: ${DateTime.fromMillisecondsSinceEpoch((timestamp + 7 * 24 * 60 * 60) * 1000)} (7 days)');
  print('');
}
