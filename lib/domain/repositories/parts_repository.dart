import 'package:beyblade_x_collection/data/models/parts_database.dart';

abstract class PartsRepository {
  Future<PartsDatabase> getDatabase();
  Future<PartsDatabase?> checkForUpdate();
  Future<void> updateDatabase(PartsDatabase db);
}
