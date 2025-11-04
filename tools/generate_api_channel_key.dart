#!/usr/bin/env dart
/// API 채널 키 생성 유틸리티
/// 
/// 사용법:
///   dart run tools/generate_api_channel_key.dart <channel> <private_key_path>
/// 
/// 예시:
///   dart run tools/generate_api_channel_key.dart qa keys/private_key.pem
///   dart run tools/generate_api_channel_key.dart dev keys/private_key.pem
/// 
/// 출력 형식:
///   channel:timestamp:signature
/// 
/// 이 값을 URL에 사용:
///   https://pot-g.gistory.me/test#key=channel:timestamp:signature
/// 
/// RSA 키 쌍 생성:
///   openssl genrsa -out private_key.pem 2048
///   openssl rsa -in private_key.pem -pubout -out public_key.pem

import 'dart:convert';
import 'dart:io';

import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/asymmetric/rsa.dart';
import 'package:pointycastle/digests/sha256.dart';
import 'package:pointycastle/formats/der_public_key_parser.dart';
import 'package:pointycastle/formats/pkcs1_private_key_parser.dart';
import 'package:pointycastle/pointycastle.dart';

void main(List<String> args) {
  if (args.length != 2) {
    print('Usage: dart run tools/generate_api_channel_key.dart <channel> <private_key_path>');
    print('');
    print('Channels: dev, qa, prod');
    print('');
    print('Examples:');
    print('  dart run tools/generate_api_channel_key.dart qa keys/private_key.pem');
    print('  dart run tools/generate_api_channel_key.dart dev keys/private_key.pem');
    print('');
    print('RSA Key Pair Generation:');
    print('  openssl genrsa -out private_key.pem 2048');
    print('  openssl rsa -in private_key.pem -pubout -out public_key.pem');
    exit(1);
  }

  final channel = args[0].toLowerCase();
  if (!['dev', 'qa', 'prod'].contains(channel)) {
    print('Error: Invalid channel. Must be one of: dev, qa, prod');
    exit(1);
  }

  final privateKeyPath = args[1];
  final privateKeyFile = File(privateKeyPath);
  
  if (!privateKeyFile.existsSync()) {
    print('Error: Private key file not found: $privateKeyPath');
    print('');
    print('Please generate RSA key pair first:');
    print('  openssl genrsa -out private_key.pem 2048');
    print('  openssl rsa -in private_key.pem -pubout -out public_key.pem');
    exit(1);
  }

  try {
    // 개인키 로드
    final privateKeyPem = privateKeyFile.readAsStringSync();
    final privateKey = _parsePrivateKey(privateKeyPem);

    // 타임스탬프 생성 (현재 시간, 초 단위)
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // 서명 생성
    final message = '$channel:$timestamp';
    final messageBytes = utf8.encode(message);
    
    // SHA-256 해시
    final digest = SHA256Digest();
    final hash = digest.process(messageBytes);
    
    // RSA-PSS 서명
    final signer = RSASigner(SHA256Digest(), 'SHA-256/PSS');
    signer.init(true, PrivateKeyParameter<RSAPrivateKey>(privateKey));
    final signature = signer.generateSignature(messageBytes);
    
    // Base64 인코딩
    final signatureBase64 = base64Encode(signature.bytes);

    // 키 생성
    final apiKey = '$channel:$timestamp:$signatureBase64';

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
  } catch (e) {
    print('Error: Failed to generate key: $e');
    exit(1);
  }
}

/// PEM 형식의 개인키 파싱
RSAPrivateKey _parsePrivateKey(String privateKeyPem) {
  // PEM 헤더/푸터 제거
  final pemLines = privateKeyPem
      .split('\n')
      .where((line) => 
          !line.startsWith('-----BEGIN') && 
          !line.startsWith('-----END') &&
          line.trim().isNotEmpty)
      .join('');
  
  // Base64 디코딩
  final keyBytes = base64Decode(pemLines);
  
  // PKCS#1 형식으로 파싱
  final parser = PKCS1PrivateKeyParser();
  final privateKey = parser.parsePrivateKey(keyBytes);
  
  return privateKey as RSAPrivateKey;
}
