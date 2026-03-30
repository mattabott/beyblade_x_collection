import 'package:beyblade_x_collection/data/models/user_collection.dart';

abstract class CollectionRepository {
  Future<UserCollection> getCollection();
  Future<void> saveCollection(UserCollection collection);
  Future<String> exportCollection(UserCollection collection);
  Future<UserCollection?> importCollection(String jsonString);
}
