from typing import Optional
import os
import json
from beyblade_manager import BeybladeManager, PARTS_DATABASE

def print_main_menu():
    """Stampa il menu principale numerico."""
    print("\n" + "="*70)
    print("🎯 BEYBLADE X COLLECTION MANAGER")
    print("="*70)
    print("1 - Gestione Collezione")
    print("2 - Analisi Collezione")
    print("3 - Gestione Deck")
    print("4 - Utility")
    print("0 - Esci")
    print("="*70)

def print_collection_menu():
    """Stampa il sottomenu per la gestione della collezione."""
    print("\n" + "-"*70)
    print("📦 Gestione Collezione")
    print("-"*70)
    print("1 - Aggiungi Blade")
    print("2 - Aggiungi Ratchet")
    print("3 - Aggiungi Bit")
    print("4 - Rimuovi parte")
    print("5 - Aggiunta veloce (batch)")
    print("6 - Rimozione veloce (batch)")
    print("0 - Torna al menu principale")
    print("-"*70)

def print_analysis_menu():
    """Stampa il sottomenu per l'analisi della collezione."""
    print("\n" + "-"*70)
    print("📊 Analisi Collezione")
    print("-"*70)
    print("1 - Mostra tutte le parti")
    print("2 - Mostra solo Blades")
    print("3 - Mostra solo Ratchets")
    print("4 - Mostra solo Bits")
    print("5 - Confronta due parti")
    print("6 - Classifica parti per statistica")
    print("7 - Suggerisci combo ottimale")
    print("0 - Torna al menu principale")
    print("-"*70)

def print_deck_menu():
    """Stampa il sottomenu per la gestione dei deck."""
    print("\n" + "-"*70)
    print("🎴 Gestione Deck")
    print("-"*70)
    print("1 - Crea nuovo deck")
    print("2 - Aggiungi Beyblade a deck")
    print("3 - Mostra deck")
    print("4 - Lista tutti i deck")
    print("5 - Elimina deck")
    print("0 - Torna al menu principale")
    print("-"*70)

def print_utility_menu():
    """Stampa il sottomenu per le utility."""
    print("\n" + "-"*70)
    print("🛠️ Utility")
    print("-"*70)
    print("1 - Mostra database completo delle parti")
    print("2 - Ripara statistiche mancanti")
    print("3 - Ripristina da backup")
    print("0 - Torna al menu principale")
    print("-"*70)

def get_part_type_from_choice(choice: str) -> Optional[str]:
    """Converte la scelta numerica in un tipo di parte."""
    part_type_map = {"1": "blades", "2": "ratchets", "3": "bits"}
    return part_type_map.get(choice)

def show_available_parts():
    """Mostra tutte le parti disponibili nel database"""
    print("\n" + "="*70)
    print("📚 DATABASE PARTI DISPONIBILI")
    print("="*70)

    print(f"\n🗡️  BLADES ({len(PARTS_DATABASE['blades'])} parti):")
    for name in sorted(PARTS_DATABASE["blades"].keys()):
        stats = PARTS_DATABASE["blades"][name]
        print(f"  • {name:<25} - Type: {stats.get('type', 'N/A')}")

    print(f"\n⚙️  RATCHETS ({len(PARTS_DATABASE['ratchets'])} parti):")
    for name in sorted(PARTS_DATABASE["ratchets"].keys()):
        print(f"  • {name}")

    print(f"\n🔩 BITS ({len(PARTS_DATABASE['bits'])} parti):")
    for name in sorted(PARTS_DATABASE["bits"].keys()):
        stats = PARTS_DATABASE["bits"][name]
        print(f"  • {name:<25} - Type: {stats.get('type', 'N/A')}")
    print("="*70)

def quick_add_parts(manager: BeybladeManager):
    """Interfaccia veloce per aggiungere più parti"""
    print("\n🚀 AGGIUNTA VELOCE PARTI")
    print("Formato: tipo:nome (es. b:Sword Dran, r:1-60, t:Flat)")
    print("Tipi: b=blade, r=ratchet, t=bit")
    print("Digita 'done' per terminare, 'list' per vedere il database")
    print("="*70)

    parts_to_add = []
    type_map = {'b': 'blades', 'r': 'ratchets', 't': 'bits'}

    while True:
        user_input = input("Parte: ").strip()
        if user_input.lower() == 'done':
            break
        if user_input.lower() == 'list':
            show_available_parts()
            continue

        if ':' not in user_input:
            print("❌ Formato errato! Usa tipo:nome")
            continue

        type_abbr, name = user_input.split(':', 1)

        if type_abbr.lower() not in type_map:
            print("❌ Tipo non valido! Usa b, r, o t")
            continue

        parts_to_add.append((type_map[type_abbr.lower()], name.strip()))

    if parts_to_add:
        print(f"\n📦 Aggiunta di {len(parts_to_add)} parti...")
        manager.batch_add_parts(parts_to_add)

def quick_remove_parts(manager: BeybladeManager):
    """Interfaccia veloce per rimuovere più parti"""
    print("\n🗑️  RIMOZIONE VELOCE PARTI")
    print("Formato: tipo:nome (es. b:Sword Dran, r:1-60, t:Flat)")
    print("Tipi: b=blade, r=ratchet, t=bit")
    print("Digita 'done' per terminare")
    print("="*70)

    parts_to_remove = []
    type_map = {'b': 'blades', 'r': 'ratchets', 't': 'bits'}

    while True:
        user_input = input("Parte da rimuovere: ").strip()
        if user_input.lower() == 'done':
            break

        if ':' not in user_input:
            print("❌ Formato errato! Usa tipo:nome")
            continue

        type_abbr, name = user_input.split(':', 1)

        if type_abbr.lower() not in type_map:
            print("❌ Tipo non valido! Usa b, r, o t")
            continue

        parts_to_remove.append((type_map[type_abbr.lower()], name.strip()))

    if parts_to_remove:
        print(f"\n🗑️  Rimozione di {len(parts_to_remove)} parti...")
        manager.batch_remove_parts(parts_to_remove)

def restore_from_backup(manager: BeybladeManager):
    """Ripristina la collezione dal backup"""
    backup_file = manager.filename + ".backup"

    if not os.path.exists(backup_file):
        print("❌ Nessun file di backup trovato!")
        return

    try:
        with open(backup_file, 'r', encoding='utf-8') as f:
            backup_data = json.load(f)

        # Mostra info sul backup
        blades = len(backup_data.get("blades", []))
        ratchets = len(backup_data.get("ratchets", []))
        bits = len(backup_data.get("bits", []))

        print(f"\n📦 Backup trovato con:")
        print(f"  • {blades} blades")
        print(f"  • {ratchets} ratchets")
        print(f"  • {bits} bits")

        confirm = input("\nVuoi ripristinare dal backup? (s/n): ").strip().lower()
        if confirm == 's':
            manager.collection = backup_data
            manager.decks = backup_data.get("decks", {})
            manager._parts_cache = manager._build_parts_cache()
            manager._mark_dirty()
            manager.save_collection(force=True)
            print("✅ Collezione ripristinata dal backup!")
        else:
            print("❌ Ripristino annullato")

    except Exception as e:
        print(f"❌ Errore nel ripristino: {e}")
