import 'package:freezed_annotation/freezed_annotation.dart';

part 'part_stats.freezed.dart';
part 'part_stats.g.dart';

@freezed
class PartStats with _$PartStats {
  const factory PartStats({
    required int attack,
    required int defense,
    required int stamina,
    required int weight,
    String? type,
    @JsonKey(name: 'burst_resistance') int? burstResistance,
    @JsonKey(name: 'image_url') String? imageUrl,
  }) = _PartStats;

  factory PartStats.fromJson(Map<String, dynamic> json) =>
      _$PartStatsFromJson(json);
}
