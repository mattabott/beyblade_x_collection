import 'package:beyblade_x_collection/data/datasources/local_datasource.dart';
import 'package:beyblade_x_collection/data/models/user_collection.dart';
import 'package:beyblade_x_collection/domain/repositories/collection_repository.dart';

class CollectionRepositoryImpl implements CollectionRepository {
  final LocalDatasource _local;

  CollectionRepositoryImpl({required LocalDatasource local}) : _local = local;

  @override
  Future<UserCollection> getCollection() => _local.loadCollection();

  @override
  Future<void> saveCollection(UserCollection collection) => _local.saveCollection(collection);

  @override
  Future<String> exportCollection(UserCollection collection) => _local.exportCollectionToString(collection);

  @override
  Future<UserCollection?> importCollection(String jsonString) => _local.importCollectionFromString(jsonString);
}
