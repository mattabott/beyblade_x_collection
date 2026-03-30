import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:beyblade_x_collection/data/datasources/local_datasource.dart';
import 'package:beyblade_x_collection/data/models/user_collection.dart';
import 'package:beyblade_x_collection/data/models/collected_part.dart';
import 'package:beyblade_x_collection/data/repositories/collection_repository_impl.dart';

class MockLocalDatasource extends Mock implements LocalDatasource {}

void main() {
  late MockLocalDatasource mockLocal;
  late CollectionRepositoryImpl repository;

  final testCollection = UserCollection(
    parts: [CollectedPart(name: 'Sword Dran', category: PartCategory.blade, quantity: 1)],
  );

  setUp(() {
    mockLocal = MockLocalDatasource();
    repository = CollectionRepositoryImpl(local: mockLocal);
  });

  test('getCollection delegates to local datasource', () async {
    when(() => mockLocal.loadCollection()).thenAnswer((_) async => testCollection);
    final result = await repository.getCollection();
    expect(result.parts.length, 1);
  });

  test('saveCollection delegates to local datasource', () async {
    when(() => mockLocal.saveCollection(testCollection)).thenAnswer((_) async {});
    await repository.saveCollection(testCollection);
    verify(() => mockLocal.saveCollection(testCollection)).called(1);
  });

  test('exportCollection returns JSON string', () async {
    when(() => mockLocal.exportCollectionToString(testCollection)).thenAnswer((_) async => '{"parts":[]}');
    final result = await repository.exportCollection(testCollection);
    expect(result, isA<String>());
  });

  test('importCollection parses valid JSON', () async {
    const jsonStr = '{"parts":[],"decks":[],"wishlist":[]}';
    when(() => mockLocal.importCollectionFromString(jsonStr)).thenAnswer((_) async => const UserCollection());
    final result = await repository.importCollection(jsonStr);
    expect(result, isNotNull);
  });
}
