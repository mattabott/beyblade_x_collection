# Beyblade X Collection Manager — Flutter Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Migrate the Android Kotlin/Jetpack Compose app to a cross-platform Flutter app (Android + iOS) with improved collection management, wishlist, remote DB updates, export/import, and a Beyblade-themed dark UI.

**Architecture:** Clean Architecture with 3 layers (data → domain → presentation). Riverpod for state management, GoRouter for navigation, Freezed for immutable models. Local JSON storage with remote DB version check.

**Tech Stack:** Flutter 3.41+, Dart 3.11+, Riverpod, GoRouter, Freezed, Dio, fl_chart, cached_network_image, flutter_animate, share_plus, file_picker

---

## File Structure

```
lib/
├── main.dart                                    # Entry point, ProviderScope, app init
├── app.dart                                     # MaterialApp.router, theme, GoRouter
├── core/
│   ├── theme/
│   │   └── beyblade_theme.dart                  # ThemeData, colors, typography
│   ├── constants/
│   │   └── app_constants.dart                   # Remote DB URL, storage keys, stat weights
│   └── utils/
│       └── stat_utils.dart                      # Stat color getter, stat value extraction
├── data/
│   ├── models/
│   │   ├── part_stats.dart                      # PartStats freezed model
│   │   ├── parts_database.dart                  # PartsDatabase freezed model
│   │   ├── collected_part.dart                  # CollectedPart freezed model
│   │   ├── beyblade_slot.dart                   # BeybladeSlot freezed model
│   │   ├── deck.dart                            # Deck freezed model
│   │   └── user_collection.dart                 # UserCollection freezed model
│   ├── datasources/
│   │   ├── local_datasource.dart                # Read/write JSON files + bundled assets
│   │   └── remote_datasource.dart               # Fetch DB from GitHub raw URL
│   └── repositories/
│       ├── parts_repository_impl.dart           # PartsRepository implementation
│       └── collection_repository_impl.dart      # CollectionRepository implementation
├── domain/
│   ├── repositories/
│   │   ├── parts_repository.dart                # Abstract PartsRepository
│   │   └── collection_repository.dart           # Abstract CollectionRepository
│   └── usecases/
│       ├── suggest_combo.dart                   # SuggestCombo use case
│       ├── rank_parts.dart                      # RankParts use case
│       └── compare_parts.dart                   # CompareParts use case
├── presentation/
│   ├── providers/
│   │   ├── parts_provider.dart                  # PartsDatabase provider + update logic
│   │   ├── collection_provider.dart             # UserCollection provider + CRUD
│   │   └── analysis_provider.dart               # Analysis providers (suggest, rank, compare)
│   ├── screens/
│   │   ├── home/
│   │   │   └── home_screen.dart                 # Main menu with 5 cards
│   │   ├── collection/
│   │   │   ├── collection_screen.dart           # Tab view + search/filter + part list
│   │   │   └── add_part_screen.dart             # Browse DB + add to collection
│   │   ├── deck/
│   │   │   ├── deck_list_screen.dart            # List decks with preview
│   │   │   └── deck_edit_screen.dart            # Create/edit deck with 3 slots
│   │   ├── analysis/
│   │   │   ├── analysis_menu_screen.dart        # 3 analysis options
│   │   │   ├── compare_parts_screen.dart        # Compare 2+ parts radar chart
│   │   │   ├── rank_parts_screen.dart           # Rank by stat
│   │   │   └── suggest_combo_screen.dart        # Top 3 combos
│   │   ├── wishlist/
│   │   │   └── wishlist_screen.dart             # Wishlist + move to collection
│   │   └── settings/
│   │       └── settings_screen.dart             # Export/import + DB update
│   └── widgets/
│       ├── part_card.dart                       # Card with image, name, stats
│       ├── stat_bar.dart                        # Animated horizontal stat bar
│       ├── stat_radar.dart                      # Radar chart for comparison
│       └── deck_preview.dart                    # Mini deck summary card
└── assets/
    └── data/
        ├── beyblade_parts_db.json               # Bundled parts database (copied from existing)
        └── beyblade_collection.json             # Default empty collection
```

**Tests:**

```
test/
├── data/
│   ├── models/
│   │   ├── part_stats_test.dart
│   │   ├── parts_database_test.dart
│   │   └── user_collection_test.dart
│   └── repositories/
│       ├── parts_repository_test.dart
│       └── collection_repository_test.dart
├── domain/
│   └── usecases/
│       ├── suggest_combo_test.dart
│       ├── rank_parts_test.dart
│       └── compare_parts_test.dart
└── presentation/
    └── widgets/
        ├── stat_bar_test.dart
        └── part_card_test.dart
```

---

### Task 1: Project Scaffolding

**Files:**
- Create: `pubspec.yaml` (Flutter-managed, we edit dependencies)
- Create: `assets/data/beyblade_parts_db.json` (copy from existing)
- Create: `assets/data/beyblade_collection.json` (new empty format)
- Modify: `.gitignore` (Flutter-specific)

- [ ] **Step 1: Clean old Android project files**

Remove old Kotlin/Android files that will be replaced by Flutter's own android/ directory:

```bash
cd /home/mattabott/Documents/flutter_apps/beyblade_x_collection
# Move legacy code to a backup branch reference, then remove
rm -rf app/ gradle/ build.gradle.kts settings.gradle.kts gradle.properties
```

- [ ] **Step 2: Create Flutter project**

```bash
cd /home/mattabott/Documents/flutter_apps/beyblade_x_collection
flutter create --project-name beyblade_x_collection --org org.jules.beyblade --platforms android,ios .
```

Expected: Flutter project created with android/, ios/, lib/, test/ directories.

- [ ] **Step 3: Set up pubspec.yaml dependencies**

Replace the generated `pubspec.yaml` with:

```yaml
name: beyblade_x_collection
description: Beyblade X Collection Manager
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: ^3.11.0

dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.5.0
  riverpod_annotation: ^2.3.0
  go_router: ^14.0.0
  freezed_annotation: ^2.4.0
  json_annotation: ^4.9.0
  path_provider: ^2.1.0
  dio: ^5.4.0
  cached_network_image: ^3.3.0
  fl_chart: ^0.68.0
  share_plus: ^9.0.0
  file_picker: ^8.0.0
  flutter_animate: ^4.5.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.0
  freezed: ^2.5.0
  json_serializable: ^6.8.0
  riverpod_generator: ^2.4.0
  flutter_lints: ^3.0.0
  mocktail: ^1.0.0

flutter:
  uses-material-design: true
  assets:
    - assets/data/
```

- [ ] **Step 4: Copy and prepare asset files**

```bash
mkdir -p assets/data
```

Copy the existing `beyblade_parts_db.json` to `assets/data/beyblade_parts_db.json`. Add a `"version": 1` field at the root level of the JSON.

Create `assets/data/beyblade_collection.json` with the new format:

```json
{
  "parts": [],
  "decks": [],
  "wishlist": []
}
```

- [ ] **Step 5: Install dependencies**

```bash
flutter pub get
```

Expected: All dependencies resolve successfully.

- [ ] **Step 6: Update .gitignore for Flutter**

Replace `.gitignore` with Flutter-appropriate ignores:

```
# Flutter
.dart_tool/
.packages
build/
*.iml
.idea/
.vscode/
*.lock
.flutter-plugins
.flutter-plugins-dependencies

# Android
android/.gradle/
android/local.properties
android/app/build/

# iOS
ios/Pods/
ios/.symlinks/
ios/Flutter/Flutter.framework
ios/Flutter/Flutter.podspec

# Generated
*.g.dart
*.freezed.dart

# OS
.DS_Store
```

- [ ] **Step 7: Verify project builds**

```bash
flutter analyze
```

Expected: No errors (warnings from generated template are ok).

- [ ] **Step 8: Commit**

```bash
git add -A
git commit -m "feat: scaffold Flutter project with dependencies and assets"
```

---

### Task 2: Data Models (Freezed)

**Files:**
- Create: `lib/data/models/part_stats.dart`
- Create: `lib/data/models/parts_database.dart`
- Create: `lib/data/models/collected_part.dart`
- Create: `lib/data/models/beyblade_slot.dart`
- Create: `lib/data/models/deck.dart`
- Create: `lib/data/models/user_collection.dart`
- Test: `test/data/models/part_stats_test.dart`
- Test: `test/data/models/parts_database_test.dart`
- Test: `test/data/models/user_collection_test.dart`

- [ ] **Step 1: Write PartStats model test**

Create `test/data/models/part_stats_test.dart`:

```dart
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:beyblade_x_collection/data/models/part_stats.dart';

void main() {
  group('PartStats', () {
    test('deserializes from blade JSON (with type, image_url)', () {
      final json = {
        'attack': 8,
        'defense': 4,
        'stamina': 5,
        'weight': 7,
        'type': 'Attack',
        'image_url': 'https://example.com/image.png',
      };
      final stats = PartStats.fromJson(json);
      expect(stats.attack, 8);
      expect(stats.defense, 4);
      expect(stats.stamina, 5);
      expect(stats.weight, 7);
      expect(stats.type, 'Attack');
      expect(stats.imageUrl, 'https://example.com/image.png');
      expect(stats.burstResistance, isNull);
    });

    test('deserializes from ratchet JSON (with burst_resistance, no type)', () {
      final json = {
        'attack': 5,
        'defense': 6,
        'stamina': 7,
        'weight': 4,
        'burst_resistance': 8,
        'image_url': null,
      };
      final stats = PartStats.fromJson(json);
      expect(stats.burstResistance, 8);
      expect(stats.type, isNull);
      expect(stats.imageUrl, isNull);
    });

    test('serializes to JSON', () {
      final stats = PartStats(
        attack: 9,
        defense: 3,
        stamina: 4,
        weight: 4,
        type: 'Attack',
        burstResistance: 7,
        imageUrl: null,
      );
      final json = stats.toJson();
      expect(json['attack'], 9);
      expect(json['burst_resistance'], 7);
      expect(json['image_url'], isNull);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/data/models/part_stats_test.dart
```

Expected: FAIL — `part_stats.dart` does not exist.

- [ ] **Step 3: Write PartStats model**

Create `lib/data/models/part_stats.dart`:

```dart
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
```

- [ ] **Step 4: Write remaining models**

Create `lib/data/models/collected_part.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'collected_part.freezed.dart';
part 'collected_part.g.dart';

enum PartCategory {
  blade,
  ratchet,
  bit;
}

@freezed
class CollectedPart with _$CollectedPart {
  const factory CollectedPart({
    required String name,
    required PartCategory category,
    @Default(1) int quantity,
  }) = _CollectedPart;

  factory CollectedPart.fromJson(Map<String, dynamic> json) =>
      _$CollectedPartFromJson(json);
}
```

Create `lib/data/models/beyblade_slot.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'beyblade_slot.freezed.dart';
part 'beyblade_slot.g.dart';

@freezed
class BeybladeSlot with _$BeybladeSlot {
  const factory BeybladeSlot({
    String? blade,
    String? ratchet,
    String? bit,
  }) = _BeybladeSlot;

  factory BeybladeSlot.fromJson(Map<String, dynamic> json) =>
      _$BeybladeSlotFromJson(json);
}
```

Create `lib/data/models/deck.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'beyblade_slot.dart';

part 'deck.freezed.dart';
part 'deck.g.dart';

@freezed
class Deck with _$Deck {
  const factory Deck({
    required String name,
    required List<BeybladeSlot> slots,
  }) = _Deck;

  factory Deck.fromJson(Map<String, dynamic> json) => _$DeckFromJson(json);
}
```

Create `lib/data/models/parts_database.dart`:

```dart
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
```

Create `lib/data/models/user_collection.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'collected_part.dart';
import 'deck.dart';

part 'user_collection.freezed.dart';
part 'user_collection.g.dart';

@freezed
class UserCollection with _$UserCollection {
  const factory UserCollection({
    @Default([]) List<CollectedPart> parts,
    @Default([]) List<Deck> decks,
    @Default([]) List<String> wishlist,
  }) = _UserCollection;

  factory UserCollection.fromJson(Map<String, dynamic> json) =>
      _$UserCollectionFromJson(json);
}
```

- [ ] **Step 5: Run code generation**

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: Generated `.freezed.dart` and `.g.dart` files for all models.

- [ ] **Step 6: Write PartsDatabase test**

Create `test/data/models/parts_database_test.dart`:

```dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:beyblade_x_collection/data/models/parts_database.dart';
import 'package:beyblade_x_collection/data/models/part_stats.dart';

void main() {
  group('PartsDatabase', () {
    test('deserializes from actual DB JSON file', () {
      final file = File('assets/data/beyblade_parts_db.json');
      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final db = PartsDatabase.fromJson(json);

      expect(db.blades.length, greaterThanOrEqualTo(60));
      expect(db.ratchets.length, greaterThanOrEqualTo(20));
      expect(db.bits.length, greaterThanOrEqualTo(30));
      expect(db.version, 1);

      // Check a known blade
      final swordDran = db.blades['Sword Dran']!;
      expect(swordDran.attack, 8);
      expect(swordDran.type, 'Attack');

      // Check a known ratchet (no type field)
      final r160 = db.ratchets['1-60']!;
      expect(r160.burstResistance, 8);

      // Check a known bit
      final flatF = db.bits['Flat (F)']!;
      expect(flatF.type, 'Attack');
      expect(flatF.attack, 9);
    });

    test('serializes back to JSON', () {
      final db = PartsDatabase(
        blades: {'TestBlade': PartStats(attack: 5, defense: 5, stamina: 5, weight: 5)},
        ratchets: {},
        bits: {},
        version: 1,
      );
      final json = db.toJson();
      expect(json['version'], 1);
      expect((json['blades'] as Map).containsKey('TestBlade'), isTrue);
    });
  });
}
```

- [ ] **Step 7: Write UserCollection test**

Create `test/data/models/user_collection_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:beyblade_x_collection/data/models/user_collection.dart';
import 'package:beyblade_x_collection/data/models/collected_part.dart';
import 'package:beyblade_x_collection/data/models/deck.dart';
import 'package:beyblade_x_collection/data/models/beyblade_slot.dart';

void main() {
  group('UserCollection', () {
    test('deserializes from JSON', () {
      final json = {
        'parts': [
          {'name': 'Sword Dran', 'category': 'blade', 'quantity': 2},
          {'name': '1-60', 'category': 'ratchet', 'quantity': 1},
        ],
        'decks': [
          {
            'name': 'Deck 1',
            'slots': [
              {'blade': 'Sword Dran', 'ratchet': '1-60', 'bit': 'Flat (F)'},
            ],
          },
        ],
        'wishlist': ['Phoenix Wing'],
      };
      final collection = UserCollection.fromJson(json);
      expect(collection.parts.length, 2);
      expect(collection.parts[0].name, 'Sword Dran');
      expect(collection.parts[0].category, PartCategory.blade);
      expect(collection.parts[0].quantity, 2);
      expect(collection.decks.length, 1);
      expect(collection.decks[0].name, 'Deck 1');
      expect(collection.wishlist, ['Phoenix Wing']);
    });

    test('serializes to JSON', () {
      final collection = UserCollection(
        parts: [
          CollectedPart(name: 'Sword Dran', category: PartCategory.blade, quantity: 1),
        ],
        decks: [],
        wishlist: ['Rush (R)'],
      );
      final json = collection.toJson();
      expect((json['parts'] as List).length, 1);
      expect((json['wishlist'] as List).first, 'Rush (R)');
    });

    test('defaults to empty lists', () {
      final collection = UserCollection();
      expect(collection.parts, isEmpty);
      expect(collection.decks, isEmpty);
      expect(collection.wishlist, isEmpty);
    });
  });
}
```

- [ ] **Step 8: Run all model tests**

```bash
flutter test test/data/models/
```

Expected: All tests PASS.

- [ ] **Step 9: Commit**

```bash
git add lib/data/models/ test/data/models/ assets/data/
git commit -m "feat: add Freezed data models with serialization and tests"
```

---

### Task 3: Core Theme and Constants

**Files:**
- Create: `lib/core/theme/beyblade_theme.dart`
- Create: `lib/core/constants/app_constants.dart`
- Create: `lib/core/utils/stat_utils.dart`

- [ ] **Step 1: Create app constants**

Create `lib/core/constants/app_constants.dart`:

```dart
class AppConstants {
  AppConstants._();

  static const String remoteDbUrl =
      'https://raw.githubusercontent.com/mattabott/beyblade-x-collection/main/assets/data/beyblade_parts_db.json';

  static const String dbFileName = 'beyblade_parts_db.json';
  static const String collectionFileName = 'beyblade_collection.json';

  static const int maxDeckSlots = 3;
  static const int maxStatValue = 10;

  // Suggest combo weights per strategy
  static const Map<String, Map<String, double>> comboWeights = {
    'attack': {'attack': 0.6, 'stamina': 0.2, 'weight': 0.2},
    'defense': {'defense': 0.6, 'burst_resistance': 0.2, 'stamina': 0.2},
    'stamina': {'stamina': 0.6, 'defense': 0.2, 'weight': 0.2},
    'balance': {'attack': 0.33, 'defense': 0.33, 'stamina': 0.34},
  };
}
```

- [ ] **Step 2: Create stat utilities**

Create `lib/core/utils/stat_utils.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:beyblade_x_collection/data/models/part_stats.dart';

class StatUtils {
  StatUtils._();

  static const Color attackColor = Color(0xFFE63946);
  static const Color defenseColor = Color(0xFF4A90D9);
  static const Color staminaColor = Color(0xFF2ECC71);
  static const Color weightColor = Color(0xFFF39C12);
  static const Color burstResistanceColor = Color(0xFF9B59B6);

  static Color colorForStat(String stat) {
    return switch (stat) {
      'attack' => attackColor,
      'defense' => defenseColor,
      'stamina' => staminaColor,
      'weight' => weightColor,
      'burst_resistance' => burstResistanceColor,
      _ => Colors.grey,
    };
  }

  static String labelForStat(String stat) {
    return switch (stat) {
      'attack' => 'ATK',
      'defense' => 'DEF',
      'stamina' => 'STA',
      'weight' => 'WGT',
      'burst_resistance' => 'BRS',
      _ => stat.toUpperCase(),
    };
  }

  static int getStatValue(PartStats stats, String stat) {
    return switch (stat) {
      'attack' => stats.attack,
      'defense' => stats.defense,
      'stamina' => stats.stamina,
      'weight' => stats.weight,
      'burst_resistance' => stats.burstResistance ?? 0,
      _ => 0,
    };
  }

  static Color colorForType(String? type) {
    return switch (type) {
      'Attack' => attackColor,
      'Defense' => defenseColor,
      'Stamina' => staminaColor,
      'Balance' => const Color(0xFFFFB703),
      _ => Colors.grey,
    };
  }

  static const List<String> allStats = [
    'attack',
    'defense',
    'stamina',
    'weight',
    'burst_resistance',
  ];
}
```

- [ ] **Step 3: Create Beyblade theme**

Create `lib/core/theme/beyblade_theme.dart`:

```dart
import 'package:flutter/material.dart';

class BeybladeTheme {
  BeybladeTheme._();

  // Colors
  static const Color primary = Color(0xFF1A3A7D);
  static const Color secondary = Color(0xFFE63946);
  static const Color accent = Color(0xFFFFB703);
  static const Color background = Color(0xFF1C1C2E);
  static const Color surface = Color(0xFF2A2A3D);
  static const Color textPrimary = Color(0xFFF0F0F0);
  static const Color textSecondary = Color(0xFFA0A0B0);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        tertiary: accent,
        surface: surface,
        onPrimary: textPrimary,
        onSecondary: textPrimary,
        onSurface: textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: Color(0xFF1C1C2E),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: textPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accent, width: 2),
        ),
        hintStyle: const TextStyle(color: textSecondary),
        labelStyle: const TextStyle(color: textSecondary),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: textPrimary,
          fontSize: 32,
          fontWeight: FontWeight.w900,
          letterSpacing: -1,
        ),
        titleLarge: TextStyle(
          color: textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: textPrimary,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: textSecondary,
          fontSize: 14,
        ),
        labelLarge: TextStyle(
          color: textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          fontFamily: 'monospace',
        ),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: accent,
        unselectedLabelColor: textSecondary,
        indicatorColor: accent,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: primary,
        labelStyle: const TextStyle(color: textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
```

- [ ] **Step 4: Commit**

```bash
git add lib/core/
git commit -m "feat: add Beyblade theme, constants, and stat utilities"
```

---

### Task 4: Data Layer (Datasources + Repositories)

**Files:**
- Create: `lib/data/datasources/local_datasource.dart`
- Create: `lib/data/datasources/remote_datasource.dart`
- Create: `lib/domain/repositories/parts_repository.dart`
- Create: `lib/domain/repositories/collection_repository.dart`
- Create: `lib/data/repositories/parts_repository_impl.dart`
- Create: `lib/data/repositories/collection_repository_impl.dart`
- Test: `test/data/repositories/parts_repository_test.dart`
- Test: `test/data/repositories/collection_repository_test.dart`

- [ ] **Step 1: Create local datasource**

Create `lib/data/datasources/local_datasource.dart`:

```dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:beyblade_x_collection/core/constants/app_constants.dart';
import 'package:beyblade_x_collection/data/models/parts_database.dart';
import 'package:beyblade_x_collection/data/models/user_collection.dart';

class LocalDatasource {
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  // --- Parts Database ---

  Future<PartsDatabase> loadBundledDatabase() async {
    final jsonString =
        await rootBundle.loadString('assets/data/beyblade_parts_db.json');
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return PartsDatabase.fromJson(json);
  }

  Future<PartsDatabase?> loadLocalDatabase() async {
    try {
      final path = await _localPath;
      final file = File('$path/${AppConstants.dbFileName}');
      if (!await file.exists()) return null;
      final jsonString = await file.readAsString();
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return PartsDatabase.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveDatabase(PartsDatabase db) async {
    final path = await _localPath;
    final file = File('$path/${AppConstants.dbFileName}');
    final jsonString = jsonEncode(db.toJson());
    await file.writeAsString(jsonString);
  }

  // --- User Collection ---

  Future<UserCollection> loadCollection() async {
    try {
      final path = await _localPath;
      final file = File('$path/${AppConstants.collectionFileName}');
      if (!await file.exists()) {
        return const UserCollection();
      }
      final jsonString = await file.readAsString();
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return UserCollection.fromJson(json);
    } catch (_) {
      return const UserCollection();
    }
  }

  Future<void> saveCollection(UserCollection collection) async {
    final path = await _localPath;
    final file = File('$path/${AppConstants.collectionFileName}');
    final jsonString = jsonEncode(collection.toJson());
    await file.writeAsString(jsonString);
  }

  Future<String> exportCollectionToString(UserCollection collection) async {
    return const JsonEncoder.withIndent('  ').convert(collection.toJson());
  }

  Future<UserCollection?> importCollectionFromString(String jsonString) async {
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return UserCollection.fromJson(json);
    } catch (_) {
      return null;
    }
  }
}
```

- [ ] **Step 2: Create remote datasource**

Create `lib/data/datasources/remote_datasource.dart`:

```dart
import 'package:dio/dio.dart';
import 'package:beyblade_x_collection/core/constants/app_constants.dart';
import 'package:beyblade_x_collection/data/models/parts_database.dart';

class RemoteDatasource {
  final Dio _dio;

  RemoteDatasource({Dio? dio}) : _dio = dio ?? Dio();

  Future<PartsDatabase?> fetchDatabase() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        AppConstants.remoteDbUrl,
        options: Options(
          responseType: ResponseType.json,
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      if (response.data != null) {
        return PartsDatabase.fromJson(response.data!);
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
```

- [ ] **Step 3: Create abstract repositories**

Create `lib/domain/repositories/parts_repository.dart`:

```dart
import 'package:beyblade_x_collection/data/models/parts_database.dart';

abstract class PartsRepository {
  Future<PartsDatabase> getDatabase();
  Future<PartsDatabase?> checkForUpdate();
  Future<void> updateDatabase(PartsDatabase db);
}
```

Create `lib/domain/repositories/collection_repository.dart`:

```dart
import 'package:beyblade_x_collection/data/models/user_collection.dart';

abstract class CollectionRepository {
  Future<UserCollection> getCollection();
  Future<void> saveCollection(UserCollection collection);
  Future<String> exportCollection(UserCollection collection);
  Future<UserCollection?> importCollection(String jsonString);
}
```

- [ ] **Step 4: Implement repositories**

Create `lib/data/repositories/parts_repository_impl.dart`:

```dart
import 'package:beyblade_x_collection/data/datasources/local_datasource.dart';
import 'package:beyblade_x_collection/data/datasources/remote_datasource.dart';
import 'package:beyblade_x_collection/data/models/parts_database.dart';
import 'package:beyblade_x_collection/domain/repositories/parts_repository.dart';

class PartsRepositoryImpl implements PartsRepository {
  final LocalDatasource _local;
  final RemoteDatasource _remote;

  PartsRepositoryImpl({
    required LocalDatasource local,
    required RemoteDatasource remote,
  })  : _local = local,
        _remote = remote;

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
    if (remoteDb != null && remoteDb.version > currentDb.version) {
      return remoteDb;
    }
    return null;
  }

  @override
  Future<void> updateDatabase(PartsDatabase db) async {
    await _local.saveDatabase(db);
  }
}
```

Create `lib/data/repositories/collection_repository_impl.dart`:

```dart
import 'package:beyblade_x_collection/data/datasources/local_datasource.dart';
import 'package:beyblade_x_collection/data/models/user_collection.dart';
import 'package:beyblade_x_collection/domain/repositories/collection_repository.dart';

class CollectionRepositoryImpl implements CollectionRepository {
  final LocalDatasource _local;

  CollectionRepositoryImpl({required LocalDatasource local}) : _local = local;

  @override
  Future<UserCollection> getCollection() => _local.loadCollection();

  @override
  Future<void> saveCollection(UserCollection collection) =>
      _local.saveCollection(collection);

  @override
  Future<String> exportCollection(UserCollection collection) =>
      _local.exportCollectionToString(collection);

  @override
  Future<UserCollection?> importCollection(String jsonString) =>
      _local.importCollectionFromString(jsonString);
}
```

- [ ] **Step 5: Write repository tests**

Create `test/data/repositories/parts_repository_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:beyblade_x_collection/data/datasources/local_datasource.dart';
import 'package:beyblade_x_collection/data/datasources/remote_datasource.dart';
import 'package:beyblade_x_collection/data/models/parts_database.dart';
import 'package:beyblade_x_collection/data/models/part_stats.dart';
import 'package:beyblade_x_collection/data/repositories/parts_repository_impl.dart';

class MockLocalDatasource extends Mock implements LocalDatasource {}

class MockRemoteDatasource extends Mock implements RemoteDatasource {}

void main() {
  late MockLocalDatasource mockLocal;
  late MockRemoteDatasource mockRemote;
  late PartsRepositoryImpl repository;

  final testDb = PartsDatabase(
    blades: {
      'Test': PartStats(attack: 5, defense: 5, stamina: 5, weight: 5),
    },
    ratchets: {},
    bits: {},
    version: 1,
  );

  final updatedDb = testDb.copyWith(version: 2);

  setUp(() {
    mockLocal = MockLocalDatasource();
    mockRemote = MockRemoteDatasource();
    repository = PartsRepositoryImpl(local: mockLocal, remote: mockRemote);
  });

  group('getDatabase', () {
    test('returns local DB when available', () async {
      when(() => mockLocal.loadLocalDatabase()).thenAnswer((_) async => testDb);
      final result = await repository.getDatabase();
      expect(result.version, 1);
      verifyNever(() => mockLocal.loadBundledDatabase());
    });

    test('falls back to bundled DB when local is null', () async {
      when(() => mockLocal.loadLocalDatabase()).thenAnswer((_) async => null);
      when(() => mockLocal.loadBundledDatabase())
          .thenAnswer((_) async => testDb);
      final result = await repository.getDatabase();
      expect(result.version, 1);
    });
  });

  group('checkForUpdate', () {
    test('returns remote DB when version is higher', () async {
      when(() => mockLocal.loadLocalDatabase()).thenAnswer((_) async => testDb);
      when(() => mockRemote.fetchDatabase())
          .thenAnswer((_) async => updatedDb);
      final result = await repository.checkForUpdate();
      expect(result, isNotNull);
      expect(result!.version, 2);
    });

    test('returns null when remote version is same or lower', () async {
      when(() => mockLocal.loadLocalDatabase()).thenAnswer((_) async => testDb);
      when(() => mockRemote.fetchDatabase()).thenAnswer((_) async => testDb);
      final result = await repository.checkForUpdate();
      expect(result, isNull);
    });

    test('returns null when remote fetch fails', () async {
      when(() => mockLocal.loadLocalDatabase()).thenAnswer((_) async => testDb);
      when(() => mockRemote.fetchDatabase()).thenAnswer((_) async => null);
      final result = await repository.checkForUpdate();
      expect(result, isNull);
    });
  });
}
```

Create `test/data/repositories/collection_repository_test.dart`:

```dart
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
    parts: [
      CollectedPart(name: 'Sword Dran', category: PartCategory.blade, quantity: 1),
    ],
  );

  setUp(() {
    mockLocal = MockLocalDatasource();
    repository = CollectionRepositoryImpl(local: mockLocal);
  });

  test('getCollection delegates to local datasource', () async {
    when(() => mockLocal.loadCollection())
        .thenAnswer((_) async => testCollection);
    final result = await repository.getCollection();
    expect(result.parts.length, 1);
  });

  test('saveCollection delegates to local datasource', () async {
    when(() => mockLocal.saveCollection(testCollection))
        .thenAnswer((_) async {});
    await repository.saveCollection(testCollection);
    verify(() => mockLocal.saveCollection(testCollection)).called(1);
  });

  test('exportCollection returns JSON string', () async {
    when(() => mockLocal.exportCollectionToString(testCollection))
        .thenAnswer((_) async => '{"parts":[]}');
    final result = await repository.exportCollection(testCollection);
    expect(result, isA<String>());
  });

  test('importCollection parses valid JSON', () async {
    const jsonStr = '{"parts":[],"decks":[],"wishlist":[]}';
    when(() => mockLocal.importCollectionFromString(jsonStr))
        .thenAnswer((_) async => const UserCollection());
    final result = await repository.importCollection(jsonStr);
    expect(result, isNotNull);
  });
}
```

- [ ] **Step 6: Run repository tests**

```bash
flutter test test/data/repositories/
```

Expected: All tests PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/data/datasources/ lib/data/repositories/ lib/domain/ test/data/repositories/
git commit -m "feat: add data layer with local/remote datasources and repositories"
```

---

### Task 5: Use Cases (Business Logic)

**Files:**
- Create: `lib/domain/usecases/suggest_combo.dart`
- Create: `lib/domain/usecases/rank_parts.dart`
- Create: `lib/domain/usecases/compare_parts.dart`
- Test: `test/domain/usecases/suggest_combo_test.dart`
- Test: `test/domain/usecases/rank_parts_test.dart`
- Test: `test/domain/usecases/compare_parts_test.dart`

- [ ] **Step 1: Write SuggestCombo test**

Create `test/domain/usecases/suggest_combo_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:beyblade_x_collection/data/models/part_stats.dart';
import 'package:beyblade_x_collection/data/models/parts_database.dart';
import 'package:beyblade_x_collection/domain/usecases/suggest_combo.dart';

void main() {
  late SuggestCombo suggestCombo;

  final db = PartsDatabase(
    blades: {
      'Attacker': PartStats(attack: 9, defense: 2, stamina: 3, weight: 7, type: 'Attack'),
      'Defender': PartStats(attack: 3, defense: 9, stamina: 6, weight: 8, type: 'Defense'),
      'Spinner': PartStats(attack: 4, defense: 6, stamina: 9, weight: 5, type: 'Stamina'),
    },
    ratchets: {
      '3-60': PartStats(attack: 7, defense: 6, stamina: 6, weight: 5, burstResistance: 7),
      '9-60': PartStats(attack: 5, defense: 6, stamina: 8, weight: 6, burstResistance: 8),
    },
    bits: {
      'Flat (F)': PartStats(attack: 9, defense: 3, stamina: 4, weight: 4, type: 'Attack'),
      'Ball (B)': PartStats(attack: 2, defense: 7, stamina: 9, weight: 5, type: 'Stamina'),
    },
    version: 1,
  );

  setUp(() {
    suggestCombo = SuggestCombo();
  });

  group('SuggestCombo', () {
    test('attack strategy picks highest attack parts', () {
      final results = suggestCombo.execute(
        db: db,
        strategy: 'attack',
        availableBlades: ['Attacker', 'Defender', 'Spinner'],
        availableRatchets: ['3-60', '9-60'],
        availableBits: ['Flat (F)', 'Ball (B)'],
      );

      expect(results.length, lessThanOrEqualTo(3));
      expect(results.isNotEmpty, isTrue);
      // Best attack combo should be Attacker + 3-60 + Flat (F)
      expect(results.first.blade, 'Attacker');
      expect(results.first.ratchet, '3-60');
      expect(results.first.bit, 'Flat (F)');
    });

    test('defense strategy picks highest defense parts', () {
      final results = suggestCombo.execute(
        db: db,
        strategy: 'defense',
        availableBlades: ['Attacker', 'Defender'],
        availableRatchets: ['3-60', '9-60'],
        availableBits: ['Flat (F)', 'Ball (B)'],
      );

      expect(results.first.blade, 'Defender');
    });

    test('returns empty list when no parts available', () {
      final results = suggestCombo.execute(
        db: db,
        strategy: 'attack',
        availableBlades: [],
        availableRatchets: [],
        availableBits: [],
      );
      expect(results, isEmpty);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/domain/usecases/suggest_combo_test.dart
```

Expected: FAIL — `suggest_combo.dart` does not exist.

- [ ] **Step 3: Write SuggestCombo use case**

Create `lib/domain/usecases/suggest_combo.dart`:

```dart
import 'package:beyblade_x_collection/core/constants/app_constants.dart';
import 'package:beyblade_x_collection/core/utils/stat_utils.dart';
import 'package:beyblade_x_collection/data/models/parts_database.dart';

class ComboResult {
  final String blade;
  final String ratchet;
  final String bit;
  final double score;

  const ComboResult({
    required this.blade,
    required this.ratchet,
    required this.bit,
    required this.score,
  });
}

class SuggestCombo {
  List<ComboResult> execute({
    required PartsDatabase db,
    required String strategy,
    required List<String> availableBlades,
    required List<String> availableRatchets,
    required List<String> availableBits,
  }) {
    if (availableBlades.isEmpty ||
        availableRatchets.isEmpty ||
        availableBits.isEmpty) {
      return [];
    }

    final weights = AppConstants.comboWeights[strategy];
    if (weights == null) return [];

    final combos = <ComboResult>[];

    for (final bladeName in availableBlades) {
      final bladeStats = db.blades[bladeName];
      if (bladeStats == null) continue;

      for (final ratchetName in availableRatchets) {
        final ratchetStats = db.ratchets[ratchetName];
        if (ratchetStats == null) continue;

        for (final bitName in availableBits) {
          final bitStats = db.bits[bitName];
          if (bitStats == null) continue;

          double score = 0;
          for (final entry in weights.entries) {
            final stat = entry.key;
            final weight = entry.value;
            final avg = (StatUtils.getStatValue(bladeStats, stat) +
                    StatUtils.getStatValue(ratchetStats, stat) +
                    StatUtils.getStatValue(bitStats, stat)) /
                3.0;
            score += avg * weight;
          }

          combos.add(ComboResult(
            blade: bladeName,
            ratchet: ratchetName,
            bit: bitName,
            score: score,
          ));
        }
      }
    }

    combos.sort((a, b) => b.score.compareTo(a.score));
    return combos.take(3).toList();
  }
}
```

- [ ] **Step 4: Run SuggestCombo test**

```bash
flutter test test/domain/usecases/suggest_combo_test.dart
```

Expected: All tests PASS.

- [ ] **Step 5: Write RankParts test and implementation**

Create `test/domain/usecases/rank_parts_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:beyblade_x_collection/data/models/part_stats.dart';
import 'package:beyblade_x_collection/domain/usecases/rank_parts.dart';

void main() {
  late RankParts rankParts;

  setUp(() {
    rankParts = RankParts();
  });

  test('ranks parts by attack descending', () {
    final parts = {
      'Low': PartStats(attack: 3, defense: 5, stamina: 5, weight: 5),
      'High': PartStats(attack: 9, defense: 5, stamina: 5, weight: 5),
      'Mid': PartStats(attack: 6, defense: 5, stamina: 5, weight: 5),
    };

    final result = rankParts.execute(parts: parts, stat: 'attack');
    expect(result.length, 3);
    expect(result[0].name, 'High');
    expect(result[0].value, 9);
    expect(result[1].name, 'Mid');
    expect(result[2].name, 'Low');
  });

  test('ranks by burst_resistance with null values as 0', () {
    final parts = {
      'NoBR': PartStats(attack: 5, defense: 5, stamina: 5, weight: 5),
      'HasBR': PartStats(
          attack: 5, defense: 5, stamina: 5, weight: 5, burstResistance: 8),
    };

    final result = rankParts.execute(parts: parts, stat: 'burst_resistance');
    expect(result[0].name, 'HasBR');
    expect(result[0].value, 8);
    expect(result[1].value, 0);
  });
}
```

Create `lib/domain/usecases/rank_parts.dart`:

```dart
import 'package:beyblade_x_collection/core/utils/stat_utils.dart';
import 'package:beyblade_x_collection/data/models/part_stats.dart';

class RankedPart {
  final String name;
  final int value;
  final PartStats stats;

  const RankedPart({
    required this.name,
    required this.value,
    required this.stats,
  });
}

class RankParts {
  List<RankedPart> execute({
    required Map<String, PartStats> parts,
    required String stat,
  }) {
    final ranked = parts.entries.map((entry) {
      return RankedPart(
        name: entry.key,
        value: StatUtils.getStatValue(entry.value, stat),
        stats: entry.value,
      );
    }).toList();

    ranked.sort((a, b) => b.value.compareTo(a.value));
    return ranked;
  }
}
```

- [ ] **Step 6: Write CompareParts test and implementation**

Create `test/domain/usecases/compare_parts_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:beyblade_x_collection/data/models/part_stats.dart';
import 'package:beyblade_x_collection/domain/usecases/compare_parts.dart';

void main() {
  late CompareParts compareParts;

  setUp(() {
    compareParts = CompareParts();
  });

  test('compares two parts and returns stat diffs', () {
    final parts = {
      'PartA': PartStats(attack: 9, defense: 3, stamina: 4, weight: 7),
      'PartB': PartStats(attack: 4, defense: 8, stamina: 7, weight: 5),
    };

    final result = compareParts.execute(parts: parts);
    expect(result.length, 2);
    expect(result[0].name, 'PartA');
    expect(result[0].stats.attack, 9);
    expect(result[1].name, 'PartB');
    expect(result[1].stats.attack, 4);
  });

  test('returns empty for empty input', () {
    final result = compareParts.execute(parts: {});
    expect(result, isEmpty);
  });
}
```

Create `lib/domain/usecases/compare_parts.dart`:

```dart
import 'package:beyblade_x_collection/data/models/part_stats.dart';

class ComparedPart {
  final String name;
  final PartStats stats;

  const ComparedPart({required this.name, required this.stats});
}

class CompareParts {
  List<ComparedPart> execute({required Map<String, PartStats> parts}) {
    return parts.entries
        .map((e) => ComparedPart(name: e.key, stats: e.value))
        .toList();
  }
}
```

- [ ] **Step 7: Run all use case tests**

```bash
flutter test test/domain/usecases/
```

Expected: All tests PASS.

- [ ] **Step 8: Commit**

```bash
git add lib/domain/usecases/ test/domain/usecases/
git commit -m "feat: add business logic use cases with tests (suggest, rank, compare)"
```

---

### Task 6: Riverpod Providers

**Files:**
- Create: `lib/presentation/providers/parts_provider.dart`
- Create: `lib/presentation/providers/collection_provider.dart`
- Create: `lib/presentation/providers/analysis_provider.dart`

- [ ] **Step 1: Create parts provider**

Create `lib/presentation/providers/parts_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:beyblade_x_collection/data/datasources/local_datasource.dart';
import 'package:beyblade_x_collection/data/datasources/remote_datasource.dart';
import 'package:beyblade_x_collection/data/models/parts_database.dart';
import 'package:beyblade_x_collection/data/repositories/parts_repository_impl.dart';
import 'package:beyblade_x_collection/domain/repositories/parts_repository.dart';

final localDatasourceProvider = Provider<LocalDatasource>((ref) {
  return LocalDatasource();
});

final remoteDatasourceProvider = Provider<RemoteDatasource>((ref) {
  return RemoteDatasource();
});

final partsRepositoryProvider = Provider<PartsRepository>((ref) {
  return PartsRepositoryImpl(
    local: ref.watch(localDatasourceProvider),
    remote: ref.watch(remoteDatasourceProvider),
  );
});

final partsDatabaseProvider =
    AsyncNotifierProvider<PartsDatabaseNotifier, PartsDatabase>(
  PartsDatabaseNotifier.new,
);

class PartsDatabaseNotifier extends AsyncNotifier<PartsDatabase> {
  @override
  Future<PartsDatabase> build() async {
    final repo = ref.watch(partsRepositoryProvider);
    final db = await repo.getDatabase();
    // Check for update in background, don't block
    _checkForUpdate(repo);
    return db;
  }

  Future<void> _checkForUpdate(PartsRepository repo) async {
    final update = await repo.checkForUpdate();
    if (update != null) {
      await repo.updateDatabase(update);
      state = AsyncData(update);
    }
  }

  Future<void> forceUpdate() async {
    state = const AsyncLoading();
    final repo = ref.read(partsRepositoryProvider);
    final update = await repo.checkForUpdate();
    if (update != null) {
      await repo.updateDatabase(update);
      state = AsyncData(update);
    } else {
      state = AsyncData(await repo.getDatabase());
    }
  }
}
```

- [ ] **Step 2: Create collection provider**

Create `lib/presentation/providers/collection_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:beyblade_x_collection/data/models/collected_part.dart';
import 'package:beyblade_x_collection/data/models/deck.dart';
import 'package:beyblade_x_collection/data/models/beyblade_slot.dart';
import 'package:beyblade_x_collection/data/models/user_collection.dart';
import 'package:beyblade_x_collection/data/repositories/collection_repository_impl.dart';
import 'package:beyblade_x_collection/domain/repositories/collection_repository.dart';
import 'package:beyblade_x_collection/presentation/providers/parts_provider.dart';

final collectionRepositoryProvider = Provider<CollectionRepository>((ref) {
  return CollectionRepositoryImpl(local: ref.watch(localDatasourceProvider));
});

final collectionProvider =
    AsyncNotifierProvider<CollectionNotifier, UserCollection>(
  CollectionNotifier.new,
);

class CollectionNotifier extends AsyncNotifier<UserCollection> {
  @override
  Future<UserCollection> build() async {
    final repo = ref.watch(collectionRepositoryProvider);
    return repo.getCollection();
  }

  Future<void> _save(UserCollection collection) async {
    final repo = ref.read(collectionRepositoryProvider);
    await repo.saveCollection(collection);
    state = AsyncData(collection);
  }

  // --- Parts ---

  Future<void> addPart(String name, PartCategory category,
      {int quantity = 1}) async {
    final current = state.value;
    if (current == null) return;

    final parts = List<CollectedPart>.from(current.parts);
    final index = parts.indexWhere(
      (p) => p.name == name && p.category == category,
    );

    if (index >= 0) {
      parts[index] = parts[index].copyWith(
        quantity: parts[index].quantity + quantity,
      );
    } else {
      parts.add(CollectedPart(
        name: name,
        category: category,
        quantity: quantity,
      ));
    }

    await _save(current.copyWith(parts: parts));
  }

  Future<void> removePart(String name, PartCategory category) async {
    final current = state.value;
    if (current == null) return;

    final parts = List<CollectedPart>.from(current.parts);
    final index = parts.indexWhere(
      (p) => p.name == name && p.category == category,
    );

    if (index >= 0) {
      if (parts[index].quantity > 1) {
        parts[index] = parts[index].copyWith(
          quantity: parts[index].quantity - 1,
        );
      } else {
        parts.removeAt(index);
      }
    }

    await _save(current.copyWith(parts: parts));
  }

  // --- Wishlist ---

  Future<void> addToWishlist(String partName) async {
    final current = state.value;
    if (current == null) return;
    if (current.wishlist.contains(partName)) return;

    final wishlist = [...current.wishlist, partName];
    await _save(current.copyWith(wishlist: wishlist));
  }

  Future<void> removeFromWishlist(String partName) async {
    final current = state.value;
    if (current == null) return;

    final wishlist = current.wishlist.where((n) => n != partName).toList();
    await _save(current.copyWith(wishlist: wishlist));
  }

  Future<void> moveWishlistToCollection(
      String partName, PartCategory category) async {
    final current = state.value;
    if (current == null) return;

    final wishlist = current.wishlist.where((n) => n != partName).toList();
    final parts = List<CollectedPart>.from(current.parts);
    final index = parts.indexWhere(
      (p) => p.name == partName && p.category == category,
    );

    if (index >= 0) {
      parts[index] = parts[index].copyWith(quantity: parts[index].quantity + 1);
    } else {
      parts.add(CollectedPart(name: partName, category: category, quantity: 1));
    }

    await _save(current.copyWith(parts: parts, wishlist: wishlist));
  }

  // --- Decks ---

  Future<void> createDeck(String name) async {
    final current = state.value;
    if (current == null) return;

    final decks = [
      ...current.decks,
      Deck(name: name, slots: [
        const BeybladeSlot(),
        const BeybladeSlot(),
        const BeybladeSlot(),
      ]),
    ];
    await _save(current.copyWith(decks: decks));
  }

  Future<void> updateDeck(int index, Deck deck) async {
    final current = state.value;
    if (current == null) return;

    final decks = List<Deck>.from(current.decks);
    decks[index] = deck;
    await _save(current.copyWith(decks: decks));
  }

  Future<void> deleteDeck(int index) async {
    final current = state.value;
    if (current == null) return;

    final decks = List<Deck>.from(current.decks);
    decks.removeAt(index);
    await _save(current.copyWith(decks: decks));
  }

  // --- Export/Import ---

  Future<String> exportCollection() async {
    final current = state.value;
    if (current == null) return '';
    final repo = ref.read(collectionRepositoryProvider);
    return repo.exportCollection(current);
  }

  Future<bool> importCollection(String jsonString) async {
    final repo = ref.read(collectionRepositoryProvider);
    final imported = await repo.importCollection(jsonString);
    if (imported != null) {
      await _save(imported);
      return true;
    }
    return false;
  }
}
```

- [ ] **Step 3: Create analysis provider**

Create `lib/presentation/providers/analysis_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:beyblade_x_collection/domain/usecases/suggest_combo.dart';
import 'package:beyblade_x_collection/domain/usecases/rank_parts.dart';
import 'package:beyblade_x_collection/domain/usecases/compare_parts.dart';

final suggestComboProvider = Provider<SuggestCombo>((ref) {
  return SuggestCombo();
});

final rankPartsProvider = Provider<RankParts>((ref) {
  return RankParts();
});

final comparePartsProvider = Provider<CompareParts>((ref) {
  return CompareParts();
});
```

- [ ] **Step 4: Commit**

```bash
git add lib/presentation/providers/
git commit -m "feat: add Riverpod providers for parts, collection, and analysis"
```

---

### Task 7: Shared Widgets

**Files:**
- Create: `lib/presentation/widgets/stat_bar.dart`
- Create: `lib/presentation/widgets/part_card.dart`
- Create: `lib/presentation/widgets/stat_radar.dart`
- Create: `lib/presentation/widgets/deck_preview.dart`
- Test: `test/presentation/widgets/stat_bar_test.dart`
- Test: `test/presentation/widgets/part_card_test.dart`

- [ ] **Step 1: Write StatBar widget test**

Create `test/presentation/widgets/stat_bar_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:beyblade_x_collection/presentation/widgets/stat_bar.dart';

void main() {
  group('StatBar', () {
    testWidgets('renders label and value', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatBar(label: 'ATK', value: 8, maxValue: 10, color: Colors.red),
          ),
        ),
      );

      expect(find.text('ATK'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/presentation/widgets/stat_bar_test.dart
```

Expected: FAIL — `stat_bar.dart` does not exist.

- [ ] **Step 3: Write StatBar widget**

Create `lib/presentation/widgets/stat_bar.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class StatBar extends StatelessWidget {
  final String label;
  final int value;
  final int maxValue;
  final Color color;

  const StatBar({
    super.key,
    required this.label,
    required this.value,
    this.maxValue = 10,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: value / maxValue,
                minHeight: 8,
                backgroundColor: color.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          )
              .animate()
              .scaleX(begin: 0, end: 1, alignment: Alignment.centerLeft)
              .fadeIn(duration: 400.ms),
          const SizedBox(width: 6),
          SizedBox(
            width: 18,
            child: Text(
              '$value',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run StatBar test**

```bash
flutter test test/presentation/widgets/stat_bar_test.dart
```

Expected: PASS.

- [ ] **Step 5: Write PartCard widget**

Create `lib/presentation/widgets/part_card.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:beyblade_x_collection/core/utils/stat_utils.dart';
import 'package:beyblade_x_collection/data/models/part_stats.dart';
import 'stat_bar.dart';

class PartCard extends StatelessWidget {
  final String name;
  final PartStats stats;
  final int? quantity;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const PartCard({
    super.key,
    required this.name,
    required this.stats,
    this.quantity,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final typeColor = StatUtils.colorForType(stats.type);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: typeColor, width: 4),
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Image
              if (stats.imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: stats.imageUrl!,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      width: 56,
                      height: 56,
                      color: typeColor.withValues(alpha: 0.2),
                      child: Icon(Icons.catching_pokemon, color: typeColor, size: 28),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      width: 56,
                      height: 56,
                      color: typeColor.withValues(alpha: 0.2),
                      child: Icon(Icons.catching_pokemon, color: typeColor, size: 28),
                    ),
                  ),
                )
              else
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.catching_pokemon, color: typeColor, size: 28),
                ),

              const SizedBox(width: 12),

              // Name + Stats
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (quantity != null && quantity! > 1)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: typeColor.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'x$quantity',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: typeColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (stats.type != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2, bottom: 4),
                        child: Text(
                          stats.type!,
                          style: TextStyle(
                            fontSize: 12,
                            color: typeColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    StatBar(
                      label: 'ATK',
                      value: stats.attack,
                      color: StatUtils.attackColor,
                    ),
                    StatBar(
                      label: 'DEF',
                      value: stats.defense,
                      color: StatUtils.defenseColor,
                    ),
                    StatBar(
                      label: 'STA',
                      value: stats.stamina,
                      color: StatUtils.staminaColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 6: Write StatRadar widget**

Create `lib/presentation/widgets/stat_radar.dart`:

```dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:beyblade_x_collection/core/utils/stat_utils.dart';
import 'package:beyblade_x_collection/data/models/part_stats.dart';

class StatRadar extends StatelessWidget {
  final Map<String, PartStats> parts;

  const StatRadar({super.key, required this.parts});

  static const _stats = ['attack', 'defense', 'stamina', 'weight'];
  static const _colors = [
    Color(0xFFE63946),
    Color(0xFF4A90D9),
    Color(0xFF2ECC71),
    Color(0xFFFFB703),
    Color(0xFF9B59B6),
  ];

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: RadarChart(
        RadarChartData(
          dataSets: parts.entries.toList().asMap().entries.map((entry) {
            final colorIndex = entry.key % _colors.length;
            final stats = entry.value.value;
            return RadarDataSet(
              dataEntries: _stats
                  .map((s) => RadarEntry(
                      value: StatUtils.getStatValue(stats, s).toDouble()))
                  .toList(),
              fillColor: _colors[colorIndex].withValues(alpha: 0.2),
              borderColor: _colors[colorIndex],
              borderWidth: 2,
            );
          }).toList(),
          radarShape: RadarShape.polygon,
          radarBorderData: const BorderSide(color: Colors.white24),
          gridBorderData: const BorderSide(color: Colors.white12),
          tickBorderData: const BorderSide(color: Colors.transparent),
          tickCount: 5,
          ticksTextStyle: const TextStyle(fontSize: 0),
          titlePositionPercentageOffset: 0.15,
          getTitle: (index, angle) {
            return RadarChartTitle(
              text: StatUtils.labelForStat(_stats[index]),
              angle: 0,
            );
          },
          titleTextStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 7: Write DeckPreview widget**

Create `lib/presentation/widgets/deck_preview.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:beyblade_x_collection/core/theme/beyblade_theme.dart';
import 'package:beyblade_x_collection/data/models/deck.dart';

class DeckPreview extends StatelessWidget {
  final Deck deck;
  final VoidCallback? onTap;

  const DeckPreview({super.key, required this.deck, this.onTap});

  @override
  Widget build(BuildContext context) {
    final filledSlots =
        deck.slots.where((s) => s.blade != null || s.ratchet != null || s.bit != null).length;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.style, color: BeybladeTheme.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      deck.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '$filledSlots/${deck.slots.length}',
                    style: TextStyle(
                      color: BeybladeTheme.textSecondary,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...deck.slots.asMap().entries.map((entry) {
                final i = entry.key;
                final slot = entry.value;
                final label = slot.blade ?? 'Vuoto';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: BeybladeTheme.primary.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            '${i + 1}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        slot.blade != null
                            ? '${slot.blade} / ${slot.ratchet ?? "?"} / ${slot.bit ?? "?"}'
                            : 'Slot vuoto',
                        style: TextStyle(
                          fontSize: 14,
                          color: slot.blade != null
                              ? BeybladeTheme.textPrimary
                              : BeybladeTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 8: Write PartCard widget test**

Create `test/presentation/widgets/part_card_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:beyblade_x_collection/data/models/part_stats.dart';
import 'package:beyblade_x_collection/presentation/widgets/part_card.dart';

void main() {
  group('PartCard', () {
    testWidgets('renders name and type', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PartCard(
              name: 'Sword Dran',
              stats: PartStats(
                attack: 8,
                defense: 4,
                stamina: 5,
                weight: 7,
                type: 'Attack',
              ),
              quantity: 2,
            ),
          ),
        ),
      );

      expect(find.text('Sword Dran'), findsOneWidget);
      expect(find.text('Attack'), findsOneWidget);
      expect(find.text('x2'), findsOneWidget);
    });

    testWidgets('does not show quantity badge when quantity is 1', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PartCard(
              name: 'Test',
              stats: PartStats(attack: 5, defense: 5, stamina: 5, weight: 5),
              quantity: 1,
            ),
          ),
        ),
      );

      expect(find.text('x1'), findsNothing);
    });
  });
}
```

- [ ] **Step 9: Run widget tests**

```bash
flutter test test/presentation/widgets/
```

Expected: All tests PASS.

- [ ] **Step 10: Commit**

```bash
git add lib/presentation/widgets/ test/presentation/widgets/
git commit -m "feat: add shared widgets (StatBar, PartCard, StatRadar, DeckPreview)"
```

---

### Task 8: Home Screen

**Files:**
- Create: `lib/presentation/screens/home/home_screen.dart`

- [ ] **Step 1: Write HomeScreen**

Create `lib/presentation/screens/home/home_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:beyblade_x_collection/core/theme/beyblade_theme.dart';
import 'package:beyblade_x_collection/presentation/providers/collection_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collectionAsync = ref.watch(collectionProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Title
              Text(
                'BEYBLADE X',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: BeybladeTheme.accent,
                      letterSpacing: 4,
                    ),
              ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.3),
              Text(
                'MANAGER',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: BeybladeTheme.textSecondary,
                      letterSpacing: 8,
                    ),
              ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
              const SizedBox(height: 40),

              // Menu cards
              Expanded(
                child: collectionAsync.when(
                  data: (collection) {
                    final totalParts = collection.parts.fold<int>(
                        0, (sum, p) => sum + p.quantity);
                    final deckCount = collection.decks.length;
                    final wishlistCount = collection.wishlist.length;

                    return GridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 1.1,
                      children: [
                        _MenuCard(
                          icon: Icons.collections_bookmark,
                          label: 'Collezione',
                          badge: '$totalParts parti',
                          color: BeybladeTheme.secondary,
                          onTap: () => context.go('/collection'),
                        ),
                        _MenuCard(
                          icon: Icons.style,
                          label: 'Deck',
                          badge: '$deckCount deck',
                          color: BeybladeTheme.primary,
                          onTap: () => context.go('/deck'),
                        ),
                        _MenuCard(
                          icon: Icons.analytics,
                          label: 'Analisi',
                          badge: null,
                          color: const Color(0xFF2ECC71),
                          onTap: () => context.go('/analysis'),
                        ),
                        _MenuCard(
                          icon: Icons.favorite,
                          label: 'Wishlist',
                          badge: wishlistCount > 0
                              ? '$wishlistCount'
                              : null,
                          color: const Color(0xFFE63946),
                          onTap: () => context.go('/wishlist'),
                        ),
                        _MenuCard(
                          icon: Icons.settings,
                          label: 'Impostazioni',
                          badge: null,
                          color: BeybladeTheme.textSecondary,
                          onTap: () => context.go('/settings'),
                        ),
                      ]
                          .animate(interval: 100.ms)
                          .fadeIn(duration: 300.ms)
                          .slideY(begin: 0.2),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const Center(
                    child: Text('Errore nel caricamento'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? badge;
  final Color color;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.label,
    this.badge,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              if (badge != null) ...[
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badge!,
                    style: TextStyle(
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/presentation/screens/home/
git commit -m "feat: add HomeScreen with animated menu cards and badge counts"
```

---

### Task 9: Collection Screens

**Files:**
- Create: `lib/presentation/screens/collection/collection_screen.dart`
- Create: `lib/presentation/screens/collection/add_part_screen.dart`

- [ ] **Step 1: Write CollectionScreen**

Create `lib/presentation/screens/collection/collection_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:beyblade_x_collection/core/theme/beyblade_theme.dart';
import 'package:beyblade_x_collection/data/models/collected_part.dart';
import 'package:beyblade_x_collection/presentation/providers/collection_provider.dart';
import 'package:beyblade_x_collection/presentation/providers/parts_provider.dart';
import 'package:beyblade_x_collection/presentation/widgets/part_card.dart';

class CollectionScreen extends ConsumerStatefulWidget {
  const CollectionScreen({super.key});

  @override
  ConsumerState<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends ConsumerState<CollectionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String? _typeFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final collectionAsync = ref.watch(collectionProvider);
    final dbAsync = ref.watch(partsDatabaseProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('La Mia Collezione'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Blade'),
            Tab(text: 'Ratchet'),
            Tab(text: 'Bit'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/collection/add'),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Cerca parti...',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String?>(
                  icon: Icon(
                    Icons.filter_list,
                    color: _typeFilter != null
                        ? BeybladeTheme.accent
                        : BeybladeTheme.textSecondary,
                  ),
                  onSelected: (v) => setState(() => _typeFilter = v),
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: null, child: Text('Tutti')),
                    const PopupMenuItem(value: 'Attack', child: Text('Attack')),
                    const PopupMenuItem(
                        value: 'Defense', child: Text('Defense')),
                    const PopupMenuItem(
                        value: 'Stamina', child: Text('Stamina')),
                    const PopupMenuItem(
                        value: 'Balance', child: Text('Balance')),
                  ],
                ),
              ],
            ),
          ),

          // Parts list
          Expanded(
            child: collectionAsync.when(
              data: (collection) => dbAsync.when(
                data: (db) {
                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPartsList(collection, db, PartCategory.blade),
                      _buildPartsList(collection, db, PartCategory.ratchet),
                      _buildPartsList(collection, db, PartCategory.bit),
                    ],
                  );
                },
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (_, __) =>
                    const Center(child: Text('Errore caricamento DB')),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) =>
                  const Center(child: Text('Errore caricamento collezione')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartsList(
    dynamic collection,
    dynamic db,
    PartCategory category,
  ) {
    final parts = collection.parts
        .where((CollectedPart p) => p.category == category)
        .toList();

    // Get stats map for this category
    final Map<String, dynamic> statsMap = switch (category) {
      PartCategory.blade => db.blades,
      PartCategory.ratchet => db.ratchets,
      PartCategory.bit => db.bits,
    };

    // Apply search filter
    var filtered = parts.where((CollectedPart p) {
      if (_searchQuery.isNotEmpty &&
          !p.name.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      if (_typeFilter != null) {
        final stats = statsMap[p.name];
        if (stats != null && stats.type != _typeFilter) return false;
      }
      return true;
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 64, color: BeybladeTheme.textSecondary),
            const SizedBox(height: 12),
            Text(
              'Nessuna parte',
              style: TextStyle(color: BeybladeTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final part = filtered[index];
        final stats = statsMap[part.name];
        if (stats == null) return const SizedBox.shrink();

        return Dismissible(
          key: Key('${part.name}_${part.category.name}'),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            color: BeybladeTheme.secondary,
            child: const Icon(Icons.remove_circle, color: Colors.white),
          ),
          onDismissed: (_) {
            ref.read(collectionProvider.notifier).removePart(
                  part.name,
                  part.category,
                );
          },
          child: PartCard(
            name: part.name,
            stats: stats,
            quantity: part.quantity,
          ),
        );
      },
    );
  }
}
```

- [ ] **Step 2: Write AddPartScreen**

Create `lib/presentation/screens/collection/add_part_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:beyblade_x_collection/core/theme/beyblade_theme.dart';
import 'package:beyblade_x_collection/core/utils/stat_utils.dart';
import 'package:beyblade_x_collection/data/models/collected_part.dart';
import 'package:beyblade_x_collection/data/models/part_stats.dart';
import 'package:beyblade_x_collection/presentation/providers/collection_provider.dart';
import 'package:beyblade_x_collection/presentation/providers/parts_provider.dart';
import 'package:beyblade_x_collection/presentation/widgets/part_card.dart';

class AddPartScreen extends ConsumerStatefulWidget {
  const AddPartScreen({super.key});

  @override
  ConsumerState<AddPartScreen> createState() => _AddPartScreenState();
}

class _AddPartScreenState extends ConsumerState<AddPartScreen> {
  PartCategory _selectedCategory = PartCategory.blade;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final dbAsync = ref.watch(partsDatabaseProvider);
    final collectionAsync = ref.watch(collectionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aggiungi Parti'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/collection'),
        ),
      ),
      body: Column(
        children: [
          // Category selector
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: PartCategory.values.map((cat) {
                final isSelected = cat == _selectedCategory;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(cat.name[0].toUpperCase() + cat.name.substring(1)),
                      selected: isSelected,
                      onSelected: (_) =>
                          setState(() => _selectedCategory = cat),
                      selectedColor: BeybladeTheme.primary,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Cerca...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          const SizedBox(height: 8),

          // Parts list from DB
          Expanded(
            child: dbAsync.when(
              data: (db) {
                final Map<String, PartStats> partsMap = switch (_selectedCategory) {
                  PartCategory.blade => db.blades,
                  PartCategory.ratchet => db.ratchets,
                  PartCategory.bit => db.bits,
                };

                var entries = partsMap.entries.where((e) {
                  if (_searchQuery.isEmpty) return true;
                  return e.key
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase());
                }).toList();

                entries.sort((a, b) => a.key.compareTo(b.key));

                return collectionAsync.when(
                  data: (collection) {
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: entries.length,
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        final owned = collection.parts
                            .where((p) =>
                                p.name == entry.key &&
                                p.category == _selectedCategory)
                            .fold<int>(0, (sum, p) => sum + p.quantity);

                        return PartCard(
                          name: entry.key,
                          stats: entry.value,
                          quantity: owned > 0 ? owned : null,
                          onTap: () {
                            ref
                                .read(collectionProvider.notifier)
                                .addPart(entry.key, _selectedCategory);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${entry.key} aggiunto!'),
                                duration: const Duration(seconds: 1),
                                backgroundColor: BeybladeTheme.primary,
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const SizedBox.shrink(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) =>
                  const Center(child: Text('Errore caricamento DB')),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/screens/collection/
git commit -m "feat: add CollectionScreen with search/filter and AddPartScreen"
```

---

### Task 10: Deck Screens

**Files:**
- Create: `lib/presentation/screens/deck/deck_list_screen.dart`
- Create: `lib/presentation/screens/deck/deck_edit_screen.dart`

- [ ] **Step 1: Write DeckListScreen**

Create `lib/presentation/screens/deck/deck_list_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:beyblade_x_collection/core/theme/beyblade_theme.dart';
import 'package:beyblade_x_collection/presentation/providers/collection_provider.dart';
import 'package:beyblade_x_collection/presentation/widgets/deck_preview.dart';

class DeckListScreen extends ConsumerWidget {
  const DeckListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collectionAsync = ref.watch(collectionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestione Deck'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDeckDialog(context, ref),
        child: const Icon(Icons.add),
      ),
      body: collectionAsync.when(
        data: (collection) {
          if (collection.decks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.style_outlined,
                      size: 64, color: BeybladeTheme.textSecondary),
                  const SizedBox(height: 12),
                  Text(
                    'Nessun deck creato',
                    style: TextStyle(color: BeybladeTheme.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tocca + per creare un deck',
                    style: TextStyle(
                      color: BeybladeTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: collection.decks.length,
            itemBuilder: (context, index) {
              final deck = collection.decks[index];
              return DeckPreview(
                deck: deck,
                onTap: () => context.go('/deck/edit/$index'),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Errore')),
      ),
    );
  }

  void _showCreateDeckDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nuovo Deck'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Nome del deck'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                ref.read(collectionProvider.notifier).createDeck(name);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Crea'),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Write DeckEditScreen**

Create `lib/presentation/screens/deck/deck_edit_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:beyblade_x_collection/core/theme/beyblade_theme.dart';
import 'package:beyblade_x_collection/core/utils/stat_utils.dart';
import 'package:beyblade_x_collection/data/models/beyblade_slot.dart';
import 'package:beyblade_x_collection/data/models/collected_part.dart';
import 'package:beyblade_x_collection/data/models/deck.dart';
import 'package:beyblade_x_collection/presentation/providers/collection_provider.dart';
import 'package:beyblade_x_collection/presentation/providers/parts_provider.dart';
import 'package:beyblade_x_collection/presentation/widgets/stat_bar.dart';

class DeckEditScreen extends ConsumerStatefulWidget {
  final int deckIndex;

  const DeckEditScreen({super.key, required this.deckIndex});

  @override
  ConsumerState<DeckEditScreen> createState() => _DeckEditScreenState();
}

class _DeckEditScreenState extends ConsumerState<DeckEditScreen> {
  late List<BeybladeSlot> _slots;
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    final collectionAsync = ref.watch(collectionProvider);
    final dbAsync = ref.watch(partsDatabaseProvider);

    return Scaffold(
      appBar: AppBar(
        title: collectionAsync.when(
          data: (c) => Text(c.decks[widget.deckIndex].name),
          loading: () => const Text('...'),
          error: (_, __) => const Text('Errore'),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/deck'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: BeybladeTheme.secondary),
            onPressed: () => _deleteDeck(context, ref),
          ),
        ],
      ),
      body: collectionAsync.when(
        data: (collection) => dbAsync.when(
          data: (db) {
            if (!_initialized) {
              _slots =
                  List.from(collection.decks[widget.deckIndex].slots);
              _initialized = true;
            }

            final ownedBlades = collection.parts
                .where((p) => p.category == PartCategory.blade)
                .map((p) => p.name)
                .toList();
            final ownedRatchets = collection.parts
                .where((p) => p.category == PartCategory.ratchet)
                .map((p) => p.name)
                .toList();
            final ownedBits = collection.parts
                .where((p) => p.category == PartCategory.bit)
                .map((p) => p.name)
                .toList();

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ..._slots.asMap().entries.map((entry) {
                  final i = entry.key;
                  final slot = entry.value;
                  return _buildSlotEditor(
                    context,
                    slotIndex: i,
                    slot: slot,
                    ownedBlades: ownedBlades,
                    ownedRatchets: ownedRatchets,
                    ownedBits: ownedBits,
                    db: db,
                  );
                }),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _saveDeck(ref, collection),
                  icon: const Icon(Icons.save),
                  label: const Text('Salva Deck'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BeybladeTheme.accent,
                    foregroundColor: BeybladeTheme.background,
                    minimumSize: const Size.fromHeight(50),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(child: Text('Errore')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Errore')),
      ),
    );
  }

  Widget _buildSlotEditor(
    BuildContext context, {
    required int slotIndex,
    required BeybladeSlot slot,
    required List<String> ownedBlades,
    required List<String> ownedRatchets,
    required List<String> ownedBits,
    required dynamic db,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Beyblade ${slotIndex + 1}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: BeybladeTheme.accent,
              ),
            ),
            const SizedBox(height: 12),
            _buildDropdown(
              label: 'Blade',
              value: slot.blade,
              items: ownedBlades,
              onChanged: (v) {
                setState(() {
                  _slots[slotIndex] = slot.copyWith(blade: v);
                });
              },
            ),
            const SizedBox(height: 8),
            _buildDropdown(
              label: 'Ratchet',
              value: slot.ratchet,
              items: ownedRatchets,
              onChanged: (v) {
                setState(() {
                  _slots[slotIndex] = slot.copyWith(ratchet: v);
                });
              },
            ),
            const SizedBox(height: 8),
            _buildDropdown(
              label: 'Bit',
              value: slot.bit,
              items: ownedBits,
              onChanged: (v) {
                setState(() {
                  _slots[slotIndex] = slot.copyWith(bit: v);
                });
              },
            ),
            // Show combined stats if all parts selected
            if (slot.blade != null &&
                slot.ratchet != null &&
                slot.bit != null) ...[
              const Divider(height: 24),
              _buildComboStats(slot, db),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: items.contains(value) ? value : null,
      decoration: InputDecoration(labelText: label),
      items: [
        const DropdownMenuItem(value: null, child: Text('-- Seleziona --')),
        ...items.map((item) =>
            DropdownMenuItem(value: item, child: Text(item))),
      ],
      onChanged: onChanged,
    );
  }

  Widget _buildComboStats(BeybladeSlot slot, dynamic db) {
    final bladeStats = db.blades[slot.blade];
    final ratchetStats = db.ratchets[slot.ratchet];
    final bitStats = db.bits[slot.bit];
    if (bladeStats == null || ratchetStats == null || bitStats == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Stats Combo',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        for (final stat in ['attack', 'defense', 'stamina'])
          StatBar(
            label: StatUtils.labelForStat(stat),
            value: ((StatUtils.getStatValue(bladeStats, stat) +
                        StatUtils.getStatValue(ratchetStats, stat) +
                        StatUtils.getStatValue(bitStats, stat)) /
                    3)
                .round(),
            color: StatUtils.colorForStat(stat),
          ),
      ],
    );
  }

  void _saveDeck(WidgetRef ref, dynamic collection) {
    final deck = collection.decks[widget.deckIndex] as Deck;
    ref.read(collectionProvider.notifier).updateDeck(
          widget.deckIndex,
          deck.copyWith(slots: _slots),
        );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Deck salvato!'),
        backgroundColor: BeybladeTheme.primary,
      ),
    );
  }

  void _deleteDeck(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Elimina Deck'),
        content: const Text('Sei sicuro di voler eliminare questo deck?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: BeybladeTheme.secondary,
            ),
            onPressed: () {
              ref
                  .read(collectionProvider.notifier)
                  .deleteDeck(widget.deckIndex);
              Navigator.pop(ctx);
              context.go('/deck');
            },
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/screens/deck/
git commit -m "feat: add DeckListScreen and DeckEditScreen with slot editor"
```

---

### Task 11: Analysis Screens

**Files:**
- Create: `lib/presentation/screens/analysis/analysis_menu_screen.dart`
- Create: `lib/presentation/screens/analysis/compare_parts_screen.dart`
- Create: `lib/presentation/screens/analysis/rank_parts_screen.dart`
- Create: `lib/presentation/screens/analysis/suggest_combo_screen.dart`

- [ ] **Step 1: Write AnalysisMenuScreen**

Create `lib/presentation/screens/analysis/analysis_menu_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:beyblade_x_collection/core/theme/beyblade_theme.dart';

class AnalysisMenuScreen extends StatelessWidget {
  const AnalysisMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analisi'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _AnalysisTile(
              icon: Icons.compare_arrows,
              title: 'Confronta Parti',
              subtitle: 'Confronta stats di 2 o piu parti con radar chart',
              color: BeybladeTheme.secondary,
              onTap: () => context.go('/analysis/compare'),
            ),
            const SizedBox(height: 12),
            _AnalysisTile(
              icon: Icons.leaderboard,
              title: 'Classifica Parti',
              subtitle: 'Ordina le parti per statistica',
              color: const Color(0xFF2ECC71),
              onTap: () => context.go('/analysis/rank'),
            ),
            const SizedBox(height: 12),
            _AnalysisTile(
              icon: Icons.auto_awesome,
              title: 'Suggerisci Combo',
              subtitle: 'Trova le migliori combinazioni per strategia',
              color: BeybladeTheme.accent,
              onTap: () => context.go('/analysis/suggest'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalysisTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _AnalysisTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
        subtitle: Text(subtitle,
            style: TextStyle(color: BeybladeTheme.textSecondary, fontSize: 13)),
        trailing: Icon(Icons.chevron_right, color: color),
      ),
    );
  }
}
```

- [ ] **Step 2: Write ComparePartsScreen**

Create `lib/presentation/screens/analysis/compare_parts_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:beyblade_x_collection/core/theme/beyblade_theme.dart';
import 'package:beyblade_x_collection/core/utils/stat_utils.dart';
import 'package:beyblade_x_collection/data/models/collected_part.dart';
import 'package:beyblade_x_collection/data/models/part_stats.dart';
import 'package:beyblade_x_collection/presentation/providers/parts_provider.dart';
import 'package:beyblade_x_collection/presentation/widgets/stat_radar.dart';
import 'package:beyblade_x_collection/presentation/widgets/stat_bar.dart';

class ComparePartsScreen extends ConsumerStatefulWidget {
  const ComparePartsScreen({super.key});

  @override
  ConsumerState<ComparePartsScreen> createState() =>
      _ComparePartsScreenState();
}

class _ComparePartsScreenState extends ConsumerState<ComparePartsScreen> {
  PartCategory _category = PartCategory.blade;
  final List<String> _selectedParts = [];

  @override
  Widget build(BuildContext context) {
    final dbAsync = ref.watch(partsDatabaseProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confronta Parti'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/analysis'),
        ),
      ),
      body: dbAsync.when(
        data: (db) {
          final Map<String, PartStats> partsMap = switch (_category) {
            PartCategory.blade => db.blades,
            PartCategory.ratchet => db.ratchets,
            PartCategory.bit => db.bits,
          };

          final sortedNames = partsMap.keys.toList()..sort();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Category selector
              Row(
                children: PartCategory.values.map((cat) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(cat.name[0].toUpperCase() + cat.name.substring(1)),
                        selected: cat == _category,
                        onSelected: (_) => setState(() {
                          _category = cat;
                          _selectedParts.clear();
                        }),
                        selectedColor: BeybladeTheme.primary,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Part selectors
              for (int i = 0; i < 2; i++) ...[
                DropdownButtonFormField<String>(
                  value: i < _selectedParts.length
                      ? _selectedParts[i]
                      : null,
                  decoration:
                      InputDecoration(labelText: 'Parte ${i + 1}'),
                  items: sortedNames
                      .map((n) =>
                          DropdownMenuItem(value: n, child: Text(n)))
                      .toList(),
                  onChanged: (v) {
                    setState(() {
                      if (i < _selectedParts.length) {
                        if (v != null) {
                          _selectedParts[i] = v;
                        }
                      } else if (v != null) {
                        _selectedParts.add(v);
                      }
                    });
                  },
                ),
                const SizedBox(height: 8),
              ],

              // Radar chart
              if (_selectedParts.length >= 2) ...[
                const SizedBox(height: 24),
                SizedBox(
                  height: 280,
                  child: StatRadar(
                    parts: {
                      for (final name in _selectedParts)
                        if (partsMap.containsKey(name))
                          name: partsMap[name]!,
                    },
                  ),
                ),
                const SizedBox(height: 12),
                // Legend
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _selectedParts.asMap().entries.map((entry) {
                    final colors = [
                      const Color(0xFFE63946),
                      const Color(0xFF4A90D9),
                    ];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: colors[entry.key % colors.length],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(entry.value,
                              style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                // Detailed comparison
                for (final stat in StatUtils.allStats) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      StatUtils.labelForStat(stat),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: StatUtils.colorForStat(stat),
                      ),
                    ),
                  ),
                  for (final name in _selectedParts)
                    if (partsMap.containsKey(name))
                      Padding(
                        padding: const EdgeInsets.only(left: 8, bottom: 2),
                        child: StatBar(
                          label: name.length > 6
                              ? '${name.substring(0, 6)}.'
                              : name,
                          value: StatUtils.getStatValue(
                              partsMap[name]!, stat),
                          color: StatUtils.colorForStat(stat),
                        ),
                      ),
                  const SizedBox(height: 8),
                ],
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Errore')),
      ),
    );
  }
}
```

- [ ] **Step 3: Write RankPartsScreen**

Create `lib/presentation/screens/analysis/rank_parts_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:beyblade_x_collection/core/theme/beyblade_theme.dart';
import 'package:beyblade_x_collection/core/utils/stat_utils.dart';
import 'package:beyblade_x_collection/data/models/collected_part.dart';
import 'package:beyblade_x_collection/data/models/part_stats.dart';
import 'package:beyblade_x_collection/domain/usecases/rank_parts.dart';
import 'package:beyblade_x_collection/presentation/providers/analysis_provider.dart';
import 'package:beyblade_x_collection/presentation/providers/collection_provider.dart';
import 'package:beyblade_x_collection/presentation/providers/parts_provider.dart';
import 'package:beyblade_x_collection/presentation/widgets/stat_bar.dart';

class RankPartsScreen extends ConsumerStatefulWidget {
  const RankPartsScreen({super.key});

  @override
  ConsumerState<RankPartsScreen> createState() => _RankPartsScreenState();
}

class _RankPartsScreenState extends ConsumerState<RankPartsScreen> {
  PartCategory _category = PartCategory.blade;
  String _stat = 'attack';
  bool _onlyOwned = false;

  @override
  Widget build(BuildContext context) {
    final dbAsync = ref.watch(partsDatabaseProvider);
    final collectionAsync = ref.watch(collectionProvider);
    final rankPartsUC = ref.watch(rankPartsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Classifica Parti'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/analysis'),
        ),
      ),
      body: dbAsync.when(
        data: (db) {
          Map<String, PartStats> partsMap = switch (_category) {
            PartCategory.blade => db.blades,
            PartCategory.ratchet => db.ratchets,
            PartCategory.bit => db.bits,
          };

          // Filter by owned if toggle is on
          if (_onlyOwned) {
            final collection = collectionAsync.value;
            if (collection != null) {
              final ownedNames = collection.parts
                  .where((p) => p.category == _category)
                  .map((p) => p.name)
                  .toSet();
              partsMap = Map.fromEntries(
                partsMap.entries.where((e) => ownedNames.contains(e.key)),
              );
            }
          }

          final ranked = rankPartsUC.execute(parts: partsMap, stat: _stat);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    // Category chips
                    Row(
                      children: PartCategory.values.map((cat) {
                        return Expanded(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 4),
                            child: ChoiceChip(
                              label: Text(cat.name[0].toUpperCase() +
                                  cat.name.substring(1)),
                              selected: cat == _category,
                              onSelected: (_) =>
                                  setState(() => _category = cat),
                              selectedColor: BeybladeTheme.primary,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                    // Stat dropdown + owned toggle
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _stat,
                            decoration: const InputDecoration(
                                labelText: 'Statistica'),
                            items: StatUtils.allStats
                                .map((s) => DropdownMenuItem(
                                      value: s,
                                      child:
                                          Text(StatUtils.labelForStat(s)),
                                    ))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _stat = v);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        FilterChip(
                          label: const Text('Solo mie'),
                          selected: _onlyOwned,
                          onSelected: (v) =>
                              setState(() => _onlyOwned = v),
                          selectedColor: BeybladeTheme.accent,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: ranked.length,
                  itemBuilder: (context, index) {
                    final item = ranked[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 32,
                              child: Text(
                                '#${index + 1}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: index < 3
                                      ? BeybladeTheme.accent
                                      : BeybladeTheme.textSecondary,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                item.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                            SizedBox(
                              width: 120,
                              child: StatBar(
                                label: '',
                                value: item.value,
                                color: StatUtils.colorForStat(_stat),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Errore')),
      ),
    );
  }
}
```

- [ ] **Step 4: Write SuggestComboScreen**

Create `lib/presentation/screens/analysis/suggest_combo_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:beyblade_x_collection/core/theme/beyblade_theme.dart';
import 'package:beyblade_x_collection/core/utils/stat_utils.dart';
import 'package:beyblade_x_collection/data/models/collected_part.dart';
import 'package:beyblade_x_collection/domain/usecases/suggest_combo.dart';
import 'package:beyblade_x_collection/presentation/providers/analysis_provider.dart';
import 'package:beyblade_x_collection/presentation/providers/collection_provider.dart';
import 'package:beyblade_x_collection/presentation/providers/parts_provider.dart';
import 'package:beyblade_x_collection/presentation/widgets/stat_bar.dart';

class SuggestComboScreen extends ConsumerStatefulWidget {
  const SuggestComboScreen({super.key});

  @override
  ConsumerState<SuggestComboScreen> createState() =>
      _SuggestComboScreenState();
}

class _SuggestComboScreenState extends ConsumerState<SuggestComboScreen> {
  String _strategy = 'attack';
  bool _onlyOwned = true;
  List<ComboResult> _results = [];

  @override
  Widget build(BuildContext context) {
    final dbAsync = ref.watch(partsDatabaseProvider);
    final collectionAsync = ref.watch(collectionProvider);
    final suggestComboUC = ref.watch(suggestComboProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Suggerisci Combo'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/analysis'),
        ),
      ),
      body: dbAsync.when(
        data: (db) => collectionAsync.when(
          data: (collection) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Strategy selector
                DropdownButtonFormField<String>(
                  value: _strategy,
                  decoration:
                      const InputDecoration(labelText: 'Strategia'),
                  items: const [
                    DropdownMenuItem(
                        value: 'attack', child: Text('Attacco')),
                    DropdownMenuItem(
                        value: 'defense', child: Text('Difesa')),
                    DropdownMenuItem(
                        value: 'stamina', child: Text('Stamina')),
                    DropdownMenuItem(
                        value: 'balance', child: Text('Bilanciato')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _strategy = v);
                  },
                ),
                const SizedBox(height: 12),

                // Owned toggle
                FilterChip(
                  label: const Text('Solo parti possedute'),
                  selected: _onlyOwned,
                  onSelected: (v) =>
                      setState(() => _onlyOwned = v),
                  selectedColor: BeybladeTheme.accent,
                ),
                const SizedBox(height: 16),

                // Suggest button
                ElevatedButton.icon(
                  onPressed: () {
                    List<String> blades;
                    List<String> ratchets;
                    List<String> bits;

                    if (_onlyOwned) {
                      blades = collection.parts
                          .where(
                              (p) => p.category == PartCategory.blade)
                          .map((p) => p.name)
                          .toList();
                      ratchets = collection.parts
                          .where(
                              (p) => p.category == PartCategory.ratchet)
                          .map((p) => p.name)
                          .toList();
                      bits = collection.parts
                          .where(
                              (p) => p.category == PartCategory.bit)
                          .map((p) => p.name)
                          .toList();
                    } else {
                      blades = db.blades.keys.toList();
                      ratchets = db.ratchets.keys.toList();
                      bits = db.bits.keys.toList();
                    }

                    setState(() {
                      _results = suggestComboUC.execute(
                        db: db,
                        strategy: _strategy,
                        availableBlades: blades,
                        availableRatchets: ratchets,
                        availableBits: bits,
                      );
                    });
                  },
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Suggerisci'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BeybladeTheme.accent,
                    foregroundColor: BeybladeTheme.background,
                    minimumSize: const Size.fromHeight(50),
                  ),
                ),
                const SizedBox(height: 24),

                // Results
                if (_results.isEmpty && _strategy.isNotEmpty)
                  Center(
                    child: Text(
                      'Tocca "Suggerisci" per vedere le migliori combo',
                      style:
                          TextStyle(color: BeybladeTheme.textSecondary),
                    ),
                  ),
                ..._results.asMap().entries.map((entry) {
                  final i = entry.key;
                  final combo = entry.value;
                  final bladeStats = db.blades[combo.blade];
                  final ratchetStats = db.ratchets[combo.ratchet];
                  final bitStats = db.bits[combo.bit];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: i == 0
                                ? BeybladeTheme.accent
                                : BeybladeTheme.primary,
                            width: 4,
                          ),
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: i == 0
                                      ? BeybladeTheme.accent
                                      : BeybladeTheme.primary,
                                  borderRadius:
                                      BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '#${i + 1}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: i == 0
                                        ? BeybladeTheme.background
                                        : Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Score: ${combo.score.toStringAsFixed(1)}',
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _comboRow('Blade', combo.blade),
                          _comboRow('Ratchet', combo.ratchet),
                          _comboRow('Bit', combo.bit),
                          if (bladeStats != null &&
                              ratchetStats != null &&
                              bitStats != null) ...[
                            const Divider(height: 20),
                            for (final stat in [
                              'attack',
                              'defense',
                              'stamina'
                            ])
                              StatBar(
                                label: StatUtils.labelForStat(stat),
                                value: ((StatUtils.getStatValue(
                                                bladeStats, stat) +
                                            StatUtils.getStatValue(
                                                ratchetStats, stat) +
                                            StatUtils.getStatValue(
                                                bitStats, stat)) /
                                        3)
                                    .round(),
                                color: StatUtils.colorForStat(stat),
                              ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
              ],
            );
          },
          loading: () =>
              const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(child: Text('Errore')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Errore')),
      ),
    );
  }

  Widget _comboRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: TextStyle(
                color: BeybladeTheme.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/screens/analysis/
git commit -m "feat: add analysis screens (compare, rank, suggest combo)"
```

---

### Task 12: Wishlist Screen

**Files:**
- Create: `lib/presentation/screens/wishlist/wishlist_screen.dart`

- [ ] **Step 1: Write WishlistScreen**

Create `lib/presentation/screens/wishlist/wishlist_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:beyblade_x_collection/core/theme/beyblade_theme.dart';
import 'package:beyblade_x_collection/core/utils/stat_utils.dart';
import 'package:beyblade_x_collection/data/models/collected_part.dart';
import 'package:beyblade_x_collection/data/models/part_stats.dart';
import 'package:beyblade_x_collection/presentation/providers/collection_provider.dart';
import 'package:beyblade_x_collection/presentation/providers/parts_provider.dart';
import 'package:beyblade_x_collection/presentation/widgets/part_card.dart';

class WishlistScreen extends ConsumerStatefulWidget {
  const WishlistScreen({super.key});

  @override
  ConsumerState<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends ConsumerState<WishlistScreen> {
  @override
  Widget build(BuildContext context) {
    final collectionAsync = ref.watch(collectionProvider);
    final dbAsync = ref.watch(partsDatabaseProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wishlist'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddToWishlistDialog(context),
        child: const Icon(Icons.add),
      ),
      body: collectionAsync.when(
        data: (collection) => dbAsync.when(
          data: (db) {
            if (collection.wishlist.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.favorite_border,
                        size: 64, color: BeybladeTheme.textSecondary),
                    const SizedBox(height: 12),
                    Text(
                      'Wishlist vuota',
                      style:
                          TextStyle(color: BeybladeTheme.textSecondary),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: collection.wishlist.length,
              itemBuilder: (context, index) {
                final partName = collection.wishlist[index];

                // Find the part in DB
                PartStats? stats;
                PartCategory? category;
                if (db.blades.containsKey(partName)) {
                  stats = db.blades[partName];
                  category = PartCategory.blade;
                } else if (db.ratchets.containsKey(partName)) {
                  stats = db.ratchets[partName];
                  category = PartCategory.ratchet;
                } else if (db.bits.containsKey(partName)) {
                  stats = db.bits[partName];
                  category = PartCategory.bit;
                }

                return Dismissible(
                  key: Key('wishlist_$partName'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: BeybladeTheme.secondary,
                    child:
                        const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) {
                    ref
                        .read(collectionProvider.notifier)
                        .removeFromWishlist(partName);
                  },
                  child: Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: stats != null
                          ? Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: StatUtils.colorForType(stats.type)
                                    .withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.catching_pokemon,
                                color:
                                    StatUtils.colorForType(stats.type),
                              ),
                            )
                          : null,
                      title: Text(partName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700)),
                      subtitle: stats?.type != null
                          ? Text(stats!.type!,
                              style: TextStyle(
                                  color: StatUtils.colorForType(
                                      stats.type)))
                          : null,
                      trailing: category != null
                          ? IconButton(
                              icon: const Icon(Icons.add_circle,
                                  color: BeybladeTheme.accent),
                              tooltip: 'Aggiungi alla collezione',
                              onPressed: () {
                                ref
                                    .read(collectionProvider.notifier)
                                    .moveWishlistToCollection(
                                        partName, category!);
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        '$partName aggiunto alla collezione!'),
                                    backgroundColor:
                                        BeybladeTheme.primary,
                                  ),
                                );
                              },
                            )
                          : null,
                    ),
                  ),
                );
              },
            );
          },
          loading: () =>
              const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(child: Text('Errore')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Errore')),
      ),
    );
  }

  void _showAddToWishlistDialog(BuildContext context) {
    final db = ref.read(partsDatabaseProvider).value;
    if (db == null) return;

    final allParts = <String>[
      ...db.blades.keys,
      ...db.ratchets.keys,
      ...db.bits.keys,
    ]..sort();

    final collection = ref.read(collectionProvider).value;
    final wishlist = collection?.wishlist ?? [];

    // Filter out already wishlisted
    final available =
        allParts.where((p) => !wishlist.contains(p)).toList();

    String search = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final filtered = available
              .where((p) =>
                  p.toLowerCase().contains(search.toLowerCase()))
              .toList();

          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.7,
            builder: (_, scrollController) => Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Cerca parti...',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (v) =>
                        setModalState(() => search = v),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: filtered.length,
                    itemBuilder: (_, index) {
                      final name = filtered[index];
                      return ListTile(
                        title: Text(name),
                        trailing: const Icon(Icons.favorite_border,
                            color: BeybladeTheme.secondary),
                        onTap: () {
                          ref
                              .read(collectionProvider.notifier)
                              .addToWishlist(name);
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/presentation/screens/wishlist/
git commit -m "feat: add WishlistScreen with add/remove and move to collection"
```

---

### Task 13: Settings Screen

**Files:**
- Create: `lib/presentation/screens/settings/settings_screen.dart`

- [ ] **Step 1: Write SettingsScreen**

Create `lib/presentation/screens/settings/settings_screen.dart`:

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:beyblade_x_collection/core/theme/beyblade_theme.dart';
import 'package:beyblade_x_collection/presentation/providers/collection_provider.dart';
import 'package:beyblade_x_collection/presentation/providers/parts_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dbAsync = ref.watch(partsDatabaseProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Impostazioni'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Database section
          const Text(
            'DATABASE',
            style: TextStyle(
              color: BeybladeTheme.accent,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.storage,
                      color: BeybladeTheme.primary),
                  title: const Text('Versione Database'),
                  subtitle: dbAsync.when(
                    data: (db) => Text(
                      'v${db.version} — ${db.blades.length} blade, ${db.ratchets.length} ratchet, ${db.bits.length} bit',
                    ),
                    loading: () => const Text('Caricamento...'),
                    error: (_, __) => const Text('Errore'),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.cloud_download,
                      color: BeybladeTheme.primary),
                  title: const Text('Aggiorna Database'),
                  subtitle: const Text(
                      'Scarica l\'ultima versione dal server'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _updateDatabase(context, ref),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Collection section
          const Text(
            'COLLEZIONE',
            style: TextStyle(
              color: BeybladeTheme.accent,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.upload,
                      color: Color(0xFF2ECC71)),
                  title: const Text('Esporta Collezione'),
                  subtitle: const Text('Condividi come file JSON'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _exportCollection(context, ref),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.download,
                      color: Color(0xFF4A90D9)),
                  title: const Text('Importa Collezione'),
                  subtitle: const Text('Carica da file JSON'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _importCollection(context, ref),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // About section
          const Text(
            'INFO',
            style: TextStyle(
              color: BeybladeTheme.accent,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline,
                  color: BeybladeTheme.textSecondary),
              title: const Text('Beyblade X Manager'),
              subtitle: const Text('v1.0.0'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateDatabase(BuildContext context, WidgetRef ref) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Aggiornamento in corso...'),
        backgroundColor: BeybladeTheme.primary,
      ),
    );

    await ref.read(partsDatabaseProvider.notifier).forceUpdate();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Database aggiornato!'),
          backgroundColor: Color(0xFF2ECC71),
        ),
      );
    }
  }

  Future<void> _exportCollection(
      BuildContext context, WidgetRef ref) async {
    final jsonString =
        await ref.read(collectionProvider.notifier).exportCollection();
    if (jsonString.isEmpty) return;

    final directory = await getTemporaryDirectory();
    final file =
        File('${directory.path}/beyblade_collection.json');
    await file.writeAsString(jsonString);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: 'La mia collezione Beyblade X',
      ),
    );
  }

  Future<void> _importCollection(
      BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null || result.files.single.path == null) return;

    final file = File(result.files.single.path!);
    final jsonString = await file.readAsString();

    if (!context.mounted) return;

    // Confirm import
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Importa Collezione'),
        content: const Text(
            'Questa operazione sostituira la collezione attuale. Continuare?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Importa'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await ref
        .read(collectionProvider.notifier)
        .importCollection(jsonString);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Collezione importata!'
              : 'Errore: file non valido'),
          backgroundColor:
              success ? const Color(0xFF2ECC71) : BeybladeTheme.secondary,
        ),
      );
    }
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/presentation/screens/settings/
git commit -m "feat: add SettingsScreen with DB update, export/import"
```

---

### Task 14: App Router and Entry Point

**Files:**
- Create: `lib/app.dart`
- Modify: `lib/main.dart`

- [ ] **Step 1: Write app.dart with GoRouter**

Create `lib/app.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:beyblade_x_collection/core/theme/beyblade_theme.dart';
import 'package:beyblade_x_collection/presentation/screens/home/home_screen.dart';
import 'package:beyblade_x_collection/presentation/screens/collection/collection_screen.dart';
import 'package:beyblade_x_collection/presentation/screens/collection/add_part_screen.dart';
import 'package:beyblade_x_collection/presentation/screens/deck/deck_list_screen.dart';
import 'package:beyblade_x_collection/presentation/screens/deck/deck_edit_screen.dart';
import 'package:beyblade_x_collection/presentation/screens/analysis/analysis_menu_screen.dart';
import 'package:beyblade_x_collection/presentation/screens/analysis/compare_parts_screen.dart';
import 'package:beyblade_x_collection/presentation/screens/analysis/rank_parts_screen.dart';
import 'package:beyblade_x_collection/presentation/screens/analysis/suggest_combo_screen.dart';
import 'package:beyblade_x_collection/presentation/screens/wishlist/wishlist_screen.dart';
import 'package:beyblade_x_collection/presentation/screens/settings/settings_screen.dart';

final GoRouter router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (_, __) => const HomeScreen(),
    ),
    GoRoute(
      path: '/collection',
      builder: (_, __) => const CollectionScreen(),
    ),
    GoRoute(
      path: '/collection/add',
      builder: (_, __) => const AddPartScreen(),
    ),
    GoRoute(
      path: '/deck',
      builder: (_, __) => const DeckListScreen(),
    ),
    GoRoute(
      path: '/deck/edit/:index',
      builder: (_, state) {
        final index = int.parse(state.pathParameters['index']!);
        return DeckEditScreen(deckIndex: index);
      },
    ),
    GoRoute(
      path: '/analysis',
      builder: (_, __) => const AnalysisMenuScreen(),
    ),
    GoRoute(
      path: '/analysis/compare',
      builder: (_, __) => const ComparePartsScreen(),
    ),
    GoRoute(
      path: '/analysis/rank',
      builder: (_, __) => const RankPartsScreen(),
    ),
    GoRoute(
      path: '/analysis/suggest',
      builder: (_, __) => const SuggestComboScreen(),
    ),
    GoRoute(
      path: '/wishlist',
      builder: (_, __) => const WishlistScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (_, __) => const SettingsScreen(),
    ),
  ],
);

class BeybladeApp extends StatelessWidget {
  const BeybladeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Beyblade X Manager',
      theme: BeybladeTheme.darkTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
```

- [ ] **Step 2: Write main.dart**

Replace `lib/main.dart` with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: BeybladeApp(),
    ),
  );
}
```

- [ ] **Step 3: Verify compilation**

```bash
flutter analyze
```

Expected: No errors.

- [ ] **Step 4: Commit**

```bash
git add lib/app.dart lib/main.dart
git commit -m "feat: add GoRouter navigation and app entry point"
```

---

### Task 15: Integration Test and Final Verification

**Files:**
- Modify: various (any fixes needed)

- [ ] **Step 1: Run all tests**

```bash
flutter test
```

Expected: All tests PASS.

- [ ] **Step 2: Build Android APK**

```bash
flutter build apk --debug
```

Expected: Build succeeds.

- [ ] **Step 3: Build iOS (check only)**

```bash
flutter build ios --no-codesign --debug 2>&1 || echo "iOS build requires macOS - skip if on Linux"
```

Expected: On macOS, build succeeds. On Linux, skip is expected.

- [ ] **Step 4: Fix any compilation errors found**

If there are compilation errors, fix them in the relevant files. Common issues to check:
- Import paths are all correct
- Generated `.freezed.dart` and `.g.dart` files exist (re-run `dart run build_runner build --delete-conflicting-outputs`)
- All required widgets/models are properly imported

- [ ] **Step 5: Final commit**

```bash
git add -A
git commit -m "feat: complete Flutter migration — all screens, providers, and tests working"
```

---

## Summary

| Task | Description | Files |
|------|-------------|-------|
| 1 | Project scaffolding | pubspec.yaml, assets, .gitignore |
| 2 | Data models (Freezed) | 6 models + 3 test files |
| 3 | Core theme + constants | 3 files |
| 4 | Data layer | 2 datasources + 2 repos + 2 abstract repos + 2 test files |
| 5 | Use cases | 3 use cases + 3 test files |
| 6 | Riverpod providers | 3 provider files |
| 7 | Shared widgets | 4 widgets + 2 test files |
| 8 | Home screen | 1 file |
| 9 | Collection screens | 2 files |
| 10 | Deck screens | 2 files |
| 11 | Analysis screens | 4 files |
| 12 | Wishlist screen | 1 file |
| 13 | Settings screen | 1 file |
| 14 | Router + entry point | 2 files |
| 15 | Integration + verification | Fixes as needed |
