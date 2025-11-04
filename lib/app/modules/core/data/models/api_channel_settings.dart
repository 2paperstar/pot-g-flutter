import 'package:pot_g/app/modules/core/domain/enums/api_channel.dart';

class ApiChannelSettings {
  final ApiChannel channel;
  final DateTime? expiredAt;

  ApiChannelSettings({
    required this.channel,
    this.expiredAt,
  });

  Map<String, dynamic> toJson() => {
        'channel': channel.name,
        'expiredAt': expiredAt?.millisecondsSinceEpoch,
      };

  factory ApiChannelSettings.fromJson(Map<String, dynamic> json) {
    final channelName = json['channel'] as String;
    final channel = ApiChannel.values.firstWhere(
      (e) => e.name == channelName,
      orElse: () => ApiChannel.byMode(),
    );
    final expiredAtMs = json['expiredAt'] as int?;
    return ApiChannelSettings(
      channel: channel,
      expiredAt: expiredAtMs != null
          ? DateTime.fromMillisecondsSinceEpoch(expiredAtMs)
          : null,
    );
  }
}
