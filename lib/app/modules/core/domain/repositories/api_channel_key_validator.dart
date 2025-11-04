import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:injectable/injectable.dart';
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
/// - signature: HMAC-SHA256 서명 (hex 인코딩)
/// 
/// 서명 계산: HMAC-SHA256(secret, "channel:timestamp")
@injectable
class ApiChannelKeyValidator {
  /// 키 만료 시간 (초) - 기본 7일
  static const int _expirationSeconds = 7 * 24 * 60 * 60;

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
      final signature = parts[2];

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
      if (timestamp < now - _expirationSeconds) {
        return const ApiChannelKeyValidationResult.invalid(
          'Key has expired',
        );
      }

      // 서명 검증
      final message = '$channelName:$timestampStr';
      final expectedSignature = _computeSignature(message);
      
      if (signature != expectedSignature) {
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

  /// HMAC-SHA256 서명 계산
  String _computeSignature(String message) {
    final secret = _getSecret();
    final key = utf8.encode(secret);
    final bytes = utf8.encode(message);
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(bytes);
    return digest.toString();
  }

  /// 시크릿 키 가져오기
  /// 
  /// envied를 통해 환경 변수에서 가져옴
  String _getSecret() {
    return Config.apiChannelKeySecret;
  }
}
