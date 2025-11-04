import 'package:hive_ce/hive.dart';
import 'package:pot_g/app/modules/core/domain/enums/api_channel.dart';

@HiveType(typeId: 1)
class ApiChannelSettings extends HiveObject {
  @HiveField(0)
  final ApiChannel channel;

  @HiveField(1)
  final DateTime? expiredAt;

  ApiChannelSettings({
    required this.channel,
    this.expiredAt,
  });

  const ApiChannelSettings.const({
    required this.channel,
    this.expiredAt,
  });
}
