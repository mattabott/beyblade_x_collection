import 'package:freezed_annotation/freezed_annotation.dart';
import 'part_stats.dart';

part 'parts_database.freezed.dart';
part 'parts_database.g.dart';

@freezed
class PartsDatabase with _$PartsDatabase {
  const factory PartsDatabase({
    required Map<String, PartStats> blades,
    required Map<String, PartStats> ratchets,
    required Map<String, PartStats> bits,
    @Default(0) int version,
  }) = _PartsDatabase;

  factory PartsDatabase.fromJson(Map<String, dynamic> json) =>
      _$PartsDatabaseFromJson(json);
}
