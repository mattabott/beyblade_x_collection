# Beyblade X Collection Manager — Flutter Migration Design

## Overview

Migrazione dell'app Android nativa (Kotlin/Jetpack Compose) a Flutter per supporto Android + iOS, con miglioramenti significativi a funzionalità, stabilità e UX.

## Piattaforme target

- Android
- iOS

## Architettura

Clean Architecture con 3 layer:

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── theme/
│   ├── constants/
│   └── utils/
├── data/
│   ├── models/
│   ├── repositories/
│   ├── datasources/
│   │   ├── local/
│   │   └── remote/
│   └── mappers/
├── domain/
│   ├── repositories/
│   └── usecases/
├── presentation/
│   ├── providers/
│   ├── screens/
│   │   ├── home/
│   │   ├── collection/
│   │   ├── deck/
│   │   ├── analysis/
│   │   ├── wishlist/
│   │   └── settings/
│   └── widgets/
└── assets/
    ├── data/
    └── images/
```

**Stack tecnologico:**
- State management: Riverpod
- Navigazione: GoRouter
- Serializzazione: Freezed + json_serializable
- HTTP: Dio
- Grafici: fl_chart
- Immagini: cached_network_image
- Animazioni: flutter_animate

**Flusso dati:**
1. App parte con DB locale (bundled negli asset)
2. All'avvio, check asincrono versione remota (GitHub raw URL)
3. Se versione remota > locale, scarica e salva localmente
4. Collezione utente sempre locale, con export/import via JSON file

## Data Models

```dart
class PartStats {
  final int attack;
  final int defense;
  final int stamina;
  final int weight;
  final String? type;         // "Attack", "Defense", "Stamina", "Balance"
  final int? burstResistance;
  final String? imageUrl;
}

enum PartCategory { blade, ratchet, bit }

class BeybladePart {
  final String name;
  final PartCategory category;
  final PartStats stats;
}

class CollectedPart {
  final String name;
  final PartCategory category;
  final int quantity;
}

class BeybladeSlot {
  final String? blade;
  final String? ratchet;
  final String? bit;
}

class Deck {
  final String name;
  final List<BeybladeSlot> slots; // max 3
}

class UserCollection {
  final List<CollectedPart> parts;
  final List<Deck> decks;
  final List<String> wishlist;
}

class PartsDatabase {
  final Map<String, PartStats> blades;
  final Map<String, PartStats> ratchets;
  final Map<String, PartStats> bits;
  final int version;
}
```

Tutti i modelli usano `freezed` + `json_serializable` per immutabilità e serializzazione automatica.

## Schermate e navigazione

### Routes (GoRouter)

| Route | Schermata | Descrizione |
|-------|-----------|-------------|
| `/` | HomeScreen | Menu principale con 5 card |
| `/collection` | CollectionScreen | Lista parti possedute con tab, ricerca, filtri |
| `/collection/add` | AddPartScreen | Aggiungi parti dal database alla collezione |
| `/deck` | DeckListScreen | Lista deck con anteprima stats |
| `/deck/edit/:id` | DeckEditScreen | Crea/modifica deck con 3 slot |
| `/analysis` | AnalysisMenuScreen | Menu analisi |
| `/analysis/compare` | ComparePartsScreen | Confronto 2+ parti con radar chart |
| `/analysis/rank` | RankPartsScreen | Classifica parti per stat |
| `/analysis/suggest` | SuggestComboScreen | Suggerisci top 3 combo |
| `/wishlist` | WishlistScreen | Lista desideri con shortcut a collezione |
| `/settings` | SettingsScreen | Export/import, aggiornamento DB |

### Dettaglio schermate

**HomeScreen:** Logo/titolo tematico, 5 card (Collezione, Deck, Analisi, Wishlist, Impostazioni), badge con conteggi.

**CollectionScreen:** Tab bar (Blade/Ratchet/Bit), barra ricerca, filtri per tipo, lista PartCard (immagine, nome, stat bar, quantità), FAB "+", swipe/long-press per rimuovere/modificare quantità.

**AddPartScreen:** Selezione categoria, lista parti dal DB con ricerca, parti già possedute evidenziate, tap per aggiungere con counter quantità.

**DeckListScreen:** Card per deck con anteprima 3 beyblade e stats aggregate, FAB per nuovo deck.

**DeckEditScreen:** Nome editabile, 3 slot con dropdown (solo parti possedute), anteprima stats in tempo reale, salva/elimina.

**ComparePartsScreen:** Selezione 2+ parti stesso tipo, grafico radar con fl_chart, evidenzia migliore per stat.

**RankPartsScreen:** Selezione categoria e stat, lista ordinata con barre progresso, toggle tutte/solo possedute.

**SuggestComboScreen:** Selezione strategia (ATK/DEF/STA/Balance), toggle solo possedute/tutte, mostra top 3 combo con stats e spiegazione.

**WishlistScreen:** Lista parti desiderate con stats/immagine, bottone per spostare in collezione, aggiunta da browser DB.

**SettingsScreen:** Aggiorna DB manualmente, info versione/data, export (share_plus), import (file_picker con validazione e conferma).

## Tema Beyblade (gaming/energetico)

### Palette colori
- Primario: `#1A3A7D` (blu intenso)
- Secondario: `#E63946` (rosso energetico)
- Accento: `#FFB703` (giallo/oro)
- Background: `#1C1C2E` (grigio scuro)
- Surface: `#2A2A3D` (antracite)
- Testo primario: `#F0F0F0`
- Testo secondario: `#A0A0B0`

### Colori stats
- Attack: `#E63946` (rosso)
- Defense: `#4A90D9` (blu)
- Stamina: `#2ECC71` (verde)
- Weight: `#F39C12` (arancio)
- Burst Resistance: `#9B59B6` (viola)

### Tipografia
- Titoli: bold/heavy, leggermente condensato
- Body: leggibile, medium weight
- Stats/numeri: monospace

### Componenti condivisi
- **PartCard:** bordo colorato per tipo, immagine, stat bar orizzontali
- **StatBar:** barra progresso animata (0-10), colore per stat
- **StatRadar:** grafico radar (fl_chart) per confronto
- **DeckPreview:** 3 mini-card con stats aggregate

### Animazioni
- Transizioni pagina con slide fluido
- StatBar con animazione fill all'apertura
- Feedback tattile con ripple effect

## Logica business

### Use cases

| Use case | Descrizione |
|----------|-------------|
| GetPartsDatabase | Carica DB (locale o remoto) |
| UpdatePartsDatabase | Scarica e salva versione aggiornata |
| GetUserCollection | Carica collezione |
| SaveUserCollection | Salva collezione |
| AddPartToCollection | Aggiunge parte o incrementa quantità |
| RemovePartFromCollection | Rimuove parte o decrementa quantità |
| AddToWishlist | Aggiunge parte alla wishlist |
| RemoveFromWishlist | Rimuove dalla wishlist |
| MoveWishlistToCollection | Sposta da wishlist a collezione |
| CreateDeck | Crea nuovo deck |
| UpdateDeck | Modifica deck |
| DeleteDeck | Elimina deck |
| CompareParts | Confronta stats di 2+ parti |
| RankParts | Ordina parti per stat selezionata |
| SuggestCombo | Trova migliori combo per strategia |
| ExportCollection | Serializza e condividi |
| ImportCollection | Valida e importa |

### Algoritmo SuggestCombo

Pesi per strategia:
- **Attacco:** 60% ATK, 20% STA, 20% weight
- **Difesa:** 60% DEF, 20% burstResistance, 20% STA
- **Stamina:** 60% STA, 20% DEF, 20% weight
- **Bilanciato:** 33% ATK, 33% DEF, 34% STA

Calcola score pesato per ogni combinazione blade+ratchet+bit disponibile. Restituisce le top 3 combo.

### Database remoto
- URL configurabile (default: raw GitHub file del repo)
- JSON remoto include campo `version` (intero incrementale)
- All'avvio: confronta versione locale vs remota
- Se remota > locale, aggiorna
- Fallback offline: usa DB locale/bundled
- Check asincrono, non blocca avvio app

### Storage locale
- Database parti: JSON in `getApplicationDocumentsDirectory()`
- Collezione utente: JSON separato, stessa directory
- `path_provider` per path cross-platform

### Export/Import
- Export: serializza UserCollection → JSON, condividi con `share_plus`
- Import: `file_picker` per selezionare JSON, validazione, conferma utente

## Dipendenze

```yaml
dependencies:
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
  build_runner: ^2.4.0
  freezed: ^2.5.0
  json_serializable: ^6.8.0
  riverpod_generator: ^2.4.0
  flutter_lints: ^3.0.0
  mocktail: ^1.0.0
```
