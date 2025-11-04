import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/asymmetric/rsa.dart';
import 'package:pointycastle/digests/sha256.dart';
import 'package:pointycastle/formats/pkcs1_public_key_parser.dart';
import 'package:pointycastle/pointycastle.dart';
import 'package:pot_g/app/modules/core/domain/enums/api_channel.dart';
import 'package:pot_g/app/values/config.dart';

/// API 채널 키 검증 결과
class ApiChannelKeyValidationResult {
  final bool isValid;
  final ApiChannel? channel;
  final String? error;

  const ApiChannelKeyValidationResult({
    required this.isValid,
    this.channel,
    this.error,
  });

  const ApiChannelKeyValidationResult.valid(this.channel)
      : isValid = true,
        error = null;

  const ApiChannelKeyValidationResult.invalid(this.error)
      : isValid = false,
        channel = null;
}

/// API 채널 키 검증 서비스
/// 
/// 키 형식: `channel:timestamp:signature`
/// - channel: 채널 이름 (dev, qa, prod)
/// - timestamp: Unix timestamp (초 단위)
/// - signature: RSA-PSS-SHA256 서명 (base64 인코딩)
/// 
/// 서명 검증: RSA 공개키로 서명 검증
@injectable
class ApiChannelKeyValidator {
  /// 키 만료 시간 (초) - 기본 7일
  static const int _expirationSeconds = 7 * 24 * 60 * 60;

  /// RSA 공개키 파서 (캐시)
  RSAPublicKey? _cachedPublicKey;

  /// 키 검증
  /// 
  /// [key] 형식: `channel:timestamp:signature`
  /// 
  /// Returns 검증 결과와 유효한 경우 채널 정보
  ApiChannelKeyValidationResult validate(String key) {
    try {
      final parts = key.split(':');
      if (parts.length != 3) {
        return const ApiChannelKeyValidationResult.invalid(
          'Invalid key format. Expected: channel:timestamp:signature',
        );
      }

      final channelName = parts[0].toLowerCase();
      final timestampStr = parts[1];
      final signatureBase64 = parts[2];

      // 채널 이름 검증
      ApiChannel? channel;
      for (final ch in ApiChannel.values) {
        if (ch.name.toLowerCase() == channelName) {
          channel = ch;
          break;
        }
      }

      if (channel == null) {
        return ApiChannelKeyValidationResult.invalid(
          'Invalid channel name: $channelName',
        );
      }

      // 타임스탬프 검증
      final timestamp = int.tryParse(timestampStr);
      if (timestamp == null) {
        return const ApiChannelKeyValidationResult.invalid(
          'Invalid timestamp format',
        );
      }

      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      // 미래 타임스탬프 거부 (클럭 스큐 허용: 5분)
      const clockSkewSeconds = 5 * 60;
      if (timestamp > now + clockSkewSeconds) {
        return const ApiChannelKeyValidationResult.invalid(
          'Key timestamp is in the future',
        );
      }
      
      // 만료 시간 검증
      if (timestamp < now - _expirationSeconds) {
        return const ApiChannelKeyValidationResult.invalid(
          'Key has expired',
        );
      }

      // RSA 서명 검증
      final message = '$channelName:$timestampStr';
      final messageBytes = utf8.encode(message);
      final signatureBytes = base64Decode(signatureBase64);
      
      if (!_verifySignature(messageBytes, signatureBytes)) {
        return const ApiChannelKeyValidationResult.invalid(
          'Invalid signature',
        );
      }

      return ApiChannelKeyValidationResult.valid(channel);
    } catch (e) {
      return ApiChannelKeyValidationResult.invalid(
        'Validation error: $e',
      );
    }
  }

  /// RSA 서명 검증
  /// 
  /// [messageBytes]: 원본 메시지 바이트
  /// [signatureBytes]: 서명 바이트
  /// 
  /// Returns 서명이 유효한지 여부
  bool _verifySignature(List<int> messageBytes, List<int> signatureBytes) {
    try {
      final publicKey = _getPublicKey();
      
      // RSA-PSS 서명 검증
      final signer = RSASigner(SHA256Digest(), 'SHA-256/PSS');
      signer.init(false, PublicKeyParameter<RSAPublicKey>(publicKey));
      
      return signer.verifySignature(messageBytes, Signature(signatureBytes));
    } catch (e) {
      return false;
    }
  }

  /// 공개키 가져오기 (캐시)
  RSAPublicKey _getPublicKey() {
    if (_cachedPublicKey != null) {
      return _cachedPublicKey!;
    }
    
    final publicKeyPem = Config.apiChannelKeyPublicKey;
    _cachedPublicKey = _parsePublicKey(publicKeyPem);
    return _cachedPublicKey!;
  }

  /// PEM 형식의 공개키 파싱
  RSAPublicKey _parsePublicKey(String publicKeyPem) {
    // PEM 헤더/푸터 제거
    final pemLines = publicKeyPem
        .split('\n')
        .where((line) => 
            !line.startsWith('-----BEGIN') && 
            !line.startsWith('-----END') &&
            line.trim().isNotEmpty)
        .join('');
    
    // Base64 디코딩
    final keyBytes = base64Decode(pemLines);
    
    // PKCS#1 형식으로 파싱
    final parser = PKCS1PublicKeyParser();
    final publicKey = parser.parsePublicKey(keyBytes);
    
    return publicKey as RSAPublicKey;
  }
}
