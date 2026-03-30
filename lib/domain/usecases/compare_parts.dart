import 'package:beyblade_x_collection/data/models/part_stats.dart';

class ComparedPart {
  final String name;
  final PartStats stats;
  const ComparedPart({required this.name, required this.stats});
}

class CompareParts {
  List<ComparedPart> execute({required Map<String, PartStats> parts}) {
    return parts.entries.map((e) => ComparedPart(name: e.key, stats: e.value)).toList();
  }
}
