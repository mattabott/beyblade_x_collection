class AppConstants {
  AppConstants._();

  static const String remoteDbUrl =
      'https://raw.githubusercontent.com/mattabott/beyblade-x-collection/main/assets/data/beyblade_parts_db.json';

  static const String dbFileName = 'beyblade_parts_db.json';
  static const String collectionFileName = 'beyblade_collection.json';

  static const int maxDeckSlots = 3;
  static const int maxStatValue = 10;

  static const Map<String, Map<String, double>> comboWeights = {
    'attack': {'attack': 0.6, 'stamina': 0.2, 'weight': 0.2},
    'defense': {'defense': 0.6, 'burst_resistance': 0.2, 'stamina': 0.2},
    'stamina': {'stamina': 0.6, 'defense': 0.2, 'weight': 0.2},
    'balance': {'attack': 0.33, 'defense': 0.33, 'stamina': 0.34},
  };
}
