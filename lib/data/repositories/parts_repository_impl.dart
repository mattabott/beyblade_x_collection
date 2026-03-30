import 'package:beyblade_x_collection/data/datasources/local_datasource.dart';
import 'package:beyblade_x_collection/data/datasources/remote_datasource.dart';
import 'package:beyblade_x_collection/data/models/parts_database.dart';
import 'package:beyblade_x_collection/domain/repositories/parts_repository.dart';

class PartsRepositoryImpl implements PartsRepository {
  final LocalDatasource _local;
  final RemoteDatasource _remote;

  PartsRepositoryImpl({required LocalDatasource local, required RemoteDatasource remote})
      : _local = local, _remote = remote;

  @override
  Future<PartsDatabase> getDatabase() async {
    final localDb = await _local.loadLocalDatabase();
    if (localDb != null) return localDb;
    return _local.loadBundledDatabase();
  }

  @override
  Future<PartsDatabase?> checkForUpdate() async {
    final currentDb = await getDatabase();
    final remoteDb = await _remote.fetchDatabase();
    if (remoteDb != null && remoteDb.version > currentDb.version) return remoteDb;
    return null;
  }

  @override
  Future<void> updateDatabase(PartsDatabase db) async {
    await _local.saveDatabase(db);
  }
}
