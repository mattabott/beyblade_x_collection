import json
import os
from typing import Dict, List, Optional, Tuple
from collections import defaultdict
from difflib import get_close_matches
import time

def load_parts_database(filename=" beyblade_parts_db.json"):
    """Carica il database delle parti Beyblade X da file JSON"""
    try:
        with open(filename, 'r', encoding='utf-8') as f:
            db = json.load(f)
        # Crea un dizionario case-insensitive per lookup veloce
        normalized_db = {"blades": {}, "ratchets": {}, "bits": {}}
        for part_type in ["blades", "ratchets", "bits"]:
            for name, stats in db[part_type].items():
                normalized_db[part_type][name.lower()] = {"original_name": name, "stats": stats}
        return db, normalized_db
    except FileNotFoundError:
        print(f"⚠️  File '{filename}' non trovato!")
        return {"blades": {}, "ratchets": {}, "bits": {}}, {"blades": {}, "ratchets": {}, "bits": {}}
    except json.JSONDecodeError:
        print(f"⚠️  Errore nel leggere '{filename}'. Il file JSON non è valido.")
        return {"blades": {}, "ratchets": {}, "bits": {}}, {"blades": {}, "ratchets": {}, "bits": {}}

# Carica il database all'avvio
PARTS_DATABASE, NORMALIZED_DB = load_parts_database()

class BeybladeManager:
    def __init__(self, filename=" beyblade_collection.json"):
        self.filename = filename
        self.collection = self.load_collection()
        self.decks = self.collection.get("decks", {})
        self._dirty = False
        self._last_save = time.time()
        self._save_interval = 5.0
        self._parts_cache = self._build_parts_cache()

    def load_collection(self) -> Dict:
        """Carica la collezione dal file JSON"""
        if os.path.exists(self.filename):
            try:
                with open(self.filename, 'r', encoding='utf-8') as f:
                    return json.load(f)
            except json.JSONDecodeError:
                print(f"⚠️  Errore nel leggere {self.filename}. Creo una nuova collezione.")
        return {"blades": [], "ratchets": [], "bits": [], "decks": {}}

    def _build_parts_cache(self):
        """Costruisce una cache per ricerca veloce delle parti"""
        cache = {"blades": {}, "ratchets": {}, "bits": {}}
        for part_type in ["blades", "ratchets", "bits"]:
            for i, part in enumerate(self.collection[part_type]):
                name = part["name"].lower()
                if name not in cache[part_type]:
                    cache[part_type][name] = []
                cache[part_type][name].append(i)
        return cache

    def _mark_dirty(self):
        """Marca la collezione come modificata"""
        self._dirty = True

    def save_collection(self, force=False):
        """Salva la collezione nel file JSON (con debouncing e backup)"""
        current_time = time.time()
        if not force and not self._dirty:
            return
        if not force and (current_time - self._last_save) < self._save_interval:
            return

        # Protezione: non salvare collezioni vuote se il file esisteva
        total_parts = len(self.collection.get("blades", [])) + len(self.collection.get("ratchets", [])) + len(self.collection.get("bits", []))
        if total_parts == 0 and os.path.exists(self.filename) and os.path.getsize(self.filename) > 10:
            print("⚠️  SICUREZZA: Evitato salvataggio di collezione vuota sopra file esistente!")
            return

        self.collection["decks"] = self.decks

        # Backup automatico prima di salvare
        if os.path.exists(self.filename) and os.path.getsize(self.filename) > 0:
            backup_file = self.filename + ".backup"
            try:
                import shutil
                shutil.copy2(self.filename, backup_file)
            except:
                pass

        try:
            with open(self.filename, 'w', encoding='utf-8') as f:
                json.dump(self.collection, f, indent=2, ensure_ascii=False)
            self._dirty = False
            self._last_save = current_time
        except Exception as e:
            print(f"❌ Errore nel salvare: {e}")

    def _find_part_in_db(self, part_type: str, name: str) -> Tuple[Optional[str], Optional[dict]]:
        """Trova una parte nel database con fuzzy matching e case-insensitive"""
        name_lower = name.lower()

        # Ricerca esatta case-insensitive
        if name_lower in NORMALIZED_DB[part_type]:
            entry = NORMALIZED_DB[part_type][name_lower]
            return entry["original_name"], entry["stats"]

        # Ricerca parziale - cerca il pattern nel nome (es. "MN" in "Metal Needle (MN)")
        for db_name in PARTS_DATABASE[part_type].keys():
            # Cerca pattern tra parentesi o come parola intera
            if f"({name.upper()})" in db_name or f"({name.lower()})" in db_name:
                return db_name, PARTS_DATABASE[part_type][db_name]
            # Cerca pattern all'inizio del nome
            if db_name.lower().startswith(name_lower):
                return db_name, PARTS_DATABASE[part_type][db_name]

        # Fuzzy matching come fallback
        all_names = list(PARTS_DATABASE[part_type].keys())
        matches = get_close_matches(name, all_names, n=1, cutoff=0.6)
        if matches:
            matched_name = matches[0]
            return matched_name, PARTS_DATABASE[part_type][matched_name]

        return None, None

    def add_part(self, part_type: str, name: str, quiet=False, allow_duplicates=True):
        """Aggiunge una parte alla collezione"""
        if part_type not in ["blades", "ratchets", "bits"]:
            if not quiet:
                print("❌ Tipo di parte non valido!")
            return False

        # Cerca nel database con fuzzy matching e ricerca parziale
        matched_name, stats = self._find_part_in_db(part_type, name)

        if matched_name:
            name_to_use = matched_name
            if matched_name.lower() != name.lower() and not quiet:
                print(f"💡 Trovato: '{matched_name}' (cercavi '{name}')")
        else:
            name_to_use = name
            if not quiet:
                print(f"⚠️  '{name}' non trovato nel database. Aggiunto senza statistiche.")
            stats = {}

        # Verifica duplicati solo se richiesto
        if not allow_duplicates:
            name_lower = name_to_use.lower()
            if name_lower in self._parts_cache[part_type]:
                if not quiet:
                    print(f"⚠️  '{name_to_use}' già presente nella collezione!")
                return False

        new_part = {"name": name_to_use, "stats": stats if stats else {}}

        # Aggiorna collezione e cache
        index = len(self.collection[part_type])
        self.collection[part_type].append(new_part)
        name_key = new_part["name"].lower()
        if name_key not in self._parts_cache[part_type]:
            self._parts_cache[part_type][name_key] = []
        self._parts_cache[part_type][name_key].append(index)

        self._mark_dirty()
        if not quiet:
            count = len(self._parts_cache[part_type][name_key])
            if count > 1:
                print(f"✅ {new_part['name']} aggiunto ({count}x nella collezione)!")
            else:
                print(f"✅ {new_part['name']} aggiunto alla collezione di {part_type}!")
        return True

    def remove_part(self, part_type: str, name: str, quiet=False):
        """Rimuove una parte dalla collezione (ottimizzato)"""
        if part_type not in ["blades", "ratchets", "bits"]:
            if not quiet:
                print("❌ Tipo di parte non valido!")
            return False

        name_lower = name.lower()

        # Ricerca fuzzy anche in rimozione
        if name_lower not in self._parts_cache[part_type]:
            # Prova fuzzy matching tra le parti nella collezione
            collection_names = [p["name"] for p in self.collection[part_type]]
            matches = get_close_matches(name, collection_names, n=1, cutoff=0.6)
            if matches:
                name = matches[0]
                name_lower = name.lower()
                if not quiet:
                    print(f"💡 Trovato: '{name}' (simile a quello cercato)")
            else:
                if not quiet:
                    print(f"❌ {name} non trovato nella collezione!")
                return False

        indices = self._parts_cache[part_type].get(name_lower, [])
        if not indices:
            if not quiet:
                print(f"❌ {name} non trovato nella collezione!")
            return False

        # Rimuovi l'ultima occorrenza (più efficiente con le liste)
        index_to_remove = indices[-1]
        removed_part = self.collection[part_type].pop(index_to_remove)

        # Aggiornamento incrementale della cache
        self._parts_cache[part_type][name_lower].pop()
        if not self._parts_cache[part_type][name_lower]:
            del self._parts_cache[part_type][name_lower]

        # Aggiorna solo gli indici superiori a quello rimosso
        for cached_name, cached_indices in self._parts_cache[part_type].items():
            self._parts_cache[part_type][cached_name] = [
                idx - 1 if idx > index_to_remove else idx
                for idx in cached_indices
            ]

        self._mark_dirty()
        if not quiet:
            print(f"✅ {removed_part['name']} rimosso dalla collezione!")
        return True

    def batch_add_parts(self, parts_list: List[Tuple[str, str]]):
        """Aggiunge multiple parti velocemente"""
        added = 0
        for part_type, name in parts_list:
            # Trova il nome corretto dal database
            matched_name, _ = self._find_part_in_db(part_type, name)
            display_name = matched_name if matched_name else name

            if self.add_part(part_type, name, quiet=True, allow_duplicates=True):
                added += 1
                # Mostra quante copie ci sono
                name_key = display_name.lower()
                count = len(self._parts_cache[part_type].get(name_key, []))
                if count > 1:
                    print(f"  ✅ {display_name} ({count}x)")
                else:
                    print(f"  ✅ {display_name}")
            else:
                print(f"  ⏭️  {display_name} (errore)")
        print(f"\n✅ Aggiunte {added}/{len(parts_list)} parti!")
        self.save_collection(force=True)

    def batch_remove_parts(self, parts_list: List[Tuple[str, str]]):
        """Rimuove multiple parti velocemente"""
        removed = 0
        for part_type, name in parts_list:
            if self.remove_part(part_type, name, quiet=True):
                removed += 1
                print(f"  ✅ {name} rimosso")
            else:
                print(f"  ⏭️  {name} (non trovato)")
        print(f"\n✅ Rimosse {removed}/{len(parts_list)} parti!")
        self.save_collection(force=True)

    def fix_missing_stats(self):
        """Aggiorna le statistiche mancanti dalle parti nella collezione"""
        fixed = 0
        for part_type in ["blades", "ratchets", "bits"]:
            for part in self.collection[part_type]:
                if not part.get("stats"):
                    matched_name, stats = self._find_part_in_db(part_type, part["name"])
                    if stats:
                        part["stats"] = stats
                        if matched_name != part["name"]:
                            part["name"] = matched_name
                        fixed += 1
        if fixed > 0:
            self._mark_dirty()
            self.save_collection(force=True)
            print(f"✅ Aggiornate {fixed} parti con statistiche mancanti!")
        else:
            print("✅ Tutte le parti hanno già le statistiche!")

    def list_parts(self, part_type: str, show_images=True):
        """Elenca tutte le parti di un tipo"""
        if part_type not in ["blades", "ratchets", "bits"]:
            print("❌ Tipo di parte non valido!")
            return

        parts = self.collection[part_type]
        if not parts:
            print(f"📭 Nessun {part_type} nella collezione.")
            return

        # Conta le occorrenze di ogni parte
        part_counts = {}
        for part in parts:
            name = part["name"]
            if name not in part_counts:
                part_counts[name] = {"count": 0, "stats": part.get("stats", {})}
            part_counts[name]["count"] += 1

        print(f"\n🎯 {part_type.upper()} nella collezione ({len(parts)} parti totali):")
        print("=" * 80)

        for name in sorted(part_counts.keys()):
            count = part_counts[name]["count"]
            stats = part_counts[name]["stats"]
            count_str = f"x{count}" if count > 1 else ""

            # Ottieni URL immagine dal database
            image_url = None
            name_lower = name.lower()
            if name_lower in NORMALIZED_DB[part_type]:
                image_url = NORMALIZED_DB[part_type][name_lower]["stats"].get("image_url")
            elif name in PARTS_DATABASE[part_type]:
                image_url = PARTS_DATABASE[part_type][name].get("image_url")

            if stats:
                stats_str = " | ".join([f"{k.capitalize()}: {v}" for k, v in list(stats.items())[:4]])
                print(f"  • {name:<25} {count_str:<4} - {stats_str}")
            else:
                print(f"  • {name:<25} {count_str:<4} - ⚠️  Nessuna statistica")

            # Mostra immagine se richiesto
            if show_images and image_url:
                print(f"    🖼️  {image_url}")

        print("=" * 80)

    def compare_parts(self, part_type: str, name1: str, name2: str):
        """Confronta due parti"""
        if part_type not in ["blades", "ratchets", "bits"]:
            print("❌ Tipo di parte non valido!")
            return

        part1 = next((p for p in self.collection[part_type] if p["name"].lower() == name1.lower()), None)
        part2 = next((p for p in self.collection[part_type] if p["name"].lower() == name2.lower()), None)

        if not part1 or not part2:
            print("❌ Una o entrambe le parti non sono nella collezione!")
            return

        stats1 = part1.get("stats", {})
        stats2 = part2.get("stats", {})

        print(f"\n⚔️  CONFRONTO: {part1['name']} vs {part2['name']}")
        print("=" * 70)
        print(f"{ 'Statistica':<20} | {part1['name']:<15} | {part2['name']:<15} | Differenza")
        print("-" * 70)

        all_stats = set(stats1.keys()) | set(stats2.keys())
        for stat in sorted(all_stats):
            val1 = stats1.get(stat, 0)
            val2 = stats2.get(stat, 0)
            diff = val1 - val2
            winner = "←" if diff > 0 else "→" if diff < 0 else "="
            print(f"{stat.capitalize():<20} | {val1:<15} | {val2:<15} | {diff:+3} {winner}")
        print("=" * 70)

    def rank_parts(self, part_type: str, stat: str):
        """Classifica le parti per una statistica"""
        if part_type not in ["blades", "ratchets", "bits"]:
            print("❌ Tipo di parte non valido!")
            return

        parts = self.collection[part_type]
        ranked = []

        for part in parts:
            stats = part.get("stats", {})
            if stat in stats:
                ranked.append((part["name"], stats[stat]))

        if not ranked:
            print(f"❌ Nessuna parte con la statistica '{stat}'!")
            return

        ranked.sort(key=lambda x: x[1], reverse=True)

        print(f"\n🏆 CLASSIFICA {part_type.upper()} per {stat.upper()}")
        print("=" * 50)
        for i, (name, value) in enumerate(ranked, 1):
            bar = "█" * int(value)
            print(f"{i}. {name:<25} {value:>2} {bar}")
        print("=" * 50)

    def suggest_combo(self, combo_type: str):
        """Suggerisce la migliore combinazione per un tipo"""
        type_map = {
            "attack": "attack",
            "defense": "defense",
            "stamina": "stamina",
            "balance": "attack"
        }

        if combo_type.lower() not in type_map:
            print("❌ Tipo non valido! Usa: attack, defense, stamina, balance")
            return

        stat = type_map[combo_type.lower()]

        if not self.collection["blades"]:
            print("❌ Nessuna blade nella collezione!")
            return
        if not self.collection["ratchets"]:
            print("❌ Nessun ratchet nella collezione!")
            return
        if not self.collection["bits"]:
            print("❌ Nessun bit nella collezione!")
            return

        best_blade = max(self.collection["blades"],
                        key=lambda x: x.get("stats", {}).get(stat, 0))
        best_ratchet = max(self.collection["ratchets"],
                          key=lambda x: x.get("stats", {}).get(stat, 0))
        best_bit = max(self.collection["bits"],
                      key=lambda x: x.get("stats", {}).get(stat, 0))

        print(f"\n💡 COMBO SUGGERITA per {combo_type.upper()}")
        print("=" * 60)
        print(f"Blade:   {best_blade['name']}")
        print(f"Ratchet: {best_ratchet['name']}")
        print(f"Bit:     {best_bit['name']}")
        print("=" * 60)

        total_stats = {}
        for part in [best_blade, best_ratchet, best_bit]:
            for stat_name, value in part.get("stats", {}).items():
                if isinstance(value, (int, float)):
                    total_stats[stat_name] = total_stats.get(stat_name, 0) + value

        print("\nStatistiche totali:")
        for stat_name, value in sorted(total_stats.items()):
            print(f"  {stat_name.capitalize():<20}: {value}")
        print("=" * 60)

    def create_deck(self, deck_name: str):
        """Crea un nuovo deck vuoto"""
        if deck_name in self.decks:
            print(f"❌ Il deck '{deck_name}' esiste già!")
            return

        self.decks[deck_name] = {
            " beyblade1": {"blade": None, "ratchet": None, "bit": None},
            " beyblade2": {"blade": None, "ratchet": None, "bit": None},
            " beyblade3": {"blade": None, "ratchet": None, "bit": None}
        }
        self._mark_dirty()
        self.save_collection(force=True)
        print(f"✅ Deck '{deck_name}' creato!")

    def add_to_deck(self, deck_name: str, bey_slot: str, blade: str, ratchet: str, bit: str):
        """Aggiunge un Beyblade a un deck verificando che le parti non siano già usate"""
        if deck_name not in self.decks:
            print(f"❌ Il deck '{deck_name}' non esiste!")
            return

        if bey_slot not in [" beyblade1", " beyblade2", " beyblade3"]:
            print("❌ Slot non valido! Usa: beyblade1, beyblade2, beyblade3")
            return

        # Verifica esistenza con case-insensitive
        blade_found = any(p["name"].lower() == blade.lower() for p in self.collection["blades"])
        ratchet_found = any(p["name"].lower() == ratchet.lower() for p in self.collection["ratchets"])
        bit_found = any(p["name"].lower() == bit.lower() for p in self.collection["bits"])

        if not blade_found:
            print(f"❌ Blade '{blade}' non nella collezione!")
            return
        if not ratchet_found:
            print(f"❌ Ratchet '{ratchet}' non nella collezione!")
            return
        if not bit_found:
            print(f"❌ Bit '{bit}' non nella collezione!")
            return

        # Verifica parti non già usate
        for slot, bey in self.decks[deck_name].items():
            if slot == bey_slot:
                continue
            if bey["blade"] and bey["blade"].lower() == blade.lower():
                print(f"❌ Blade '{blade}' già usato in {slot}!")
                return
            if bey["ratchet"] and bey["ratchet"].lower() == ratchet.lower():
                print(f"❌ Ratchet '{ratchet}' già usato in {slot}!")
                return
            if bey["bit"] and bey["bit"].lower() == bit.lower():
                print(f"❌ Bit '{bit}' già usato in {slot}!")
                return

        self.decks[deck_name][bey_slot] = {
            "blade": blade,
            "ratchet": ratchet,
            "bit": bit
        }
        self._mark_dirty()
        self.save_collection(force=True)
        print(f"✅ Beyblade aggiunto a {bey_slot} nel deck '{deck_name}'!")

    def show_deck(self, deck_name: str):
        """Mostra un deck"""
        if deck_name not in self.decks:
            print(f"❌ Il deck '{deck_name}' non esiste!")
            return

        print(f"\n🎴 DECK: {deck_name}")
        print("=" * 70)
        for slot, bey in self.decks[deck_name].items():
            if bey["blade"]:
                print(f"{slot}:")
                print(f"  Blade:   {bey['blade']}")
                print(f"  Ratchet: {bey['ratchet']}")
                print(f"  Bit:     {bey['bit']}")
                print()
            else:
                print(f"{slot}: [Vuoto]")
        print("=" * 70)

    def list_decks(self):
        """Elenca tutti i deck"""
        if not self.decks:
            print("📭 Nessun deck creato.")
            return

        print("\n🎴 DECKS:")
        print("=" * 50)
        for deck_name in self.decks.keys():
            print(f"  • {deck_name}")
        print("=" * 50)

    def delete_deck(self, deck_name: str):
        """Elimina un deck"""
        if deck_name not in self.decks:
            print(f"❌ Il deck '{deck_name}' non esiste!")
            return

        del self.decks[deck_name]
        self._mark_dirty()
        self.save_collection(force=True)
        print(f"✅ Deck '{deck_name}' eliminato!")


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

def main():
    """Funzione principale con la nuova interfaccia numerica a sottomenu."""
    manager = BeybladeManager()

    try:
        while True:
            print_main_menu()
            choice = input("\n👉 Scelta: ").strip()

            if choice == "1": # Gestione Collezione
                while True:
                    print_collection_menu()
                    sub_choice = input("\n👉 Scelta Collezione: ").strip()
                    if sub_choice in ["1", "2", "3"]:
                        part_type = get_part_type_from_choice(sub_choice)
                        name = input(f"Nome del {part_type[:-1]}: ").strip()
                        manager.add_part(part_type, name)
                        manager.save_collection(force=True)
                    elif sub_choice == "4":
                        part_type_choice = input("Tipo di parte (1:Blade, 2:Ratchet, 3:Bit): ").strip()
                        part_type = get_part_type_from_choice(part_type_choice)
                        if part_type:
                            name = input(f"Nome del {part_type[:-1]} da rimuovere: ").strip()
                            manager.remove_part(part_type, name)
                            manager.save_collection(force=True)
                        else:
                            print("❌ Scelta non valida!")
                    elif sub_choice == "5":
                        quick_add_parts(manager)
                    elif sub_choice == "6":
                        quick_remove_parts(manager)
                    elif sub_choice == "0":
                        break
                    else:
                        print("❌ Scelta non valida!")

            elif choice == "2": # Analisi Collezione
                while True:
                    print_analysis_menu()
                    sub_choice = input("\n👉 Scelta Analisi: ").strip()
                    if sub_choice == "1":
                        manager.list_parts("blades")
                        manager.list_parts("ratchets")
                        manager.list_parts("bits")
                    elif sub_choice == "2":
                        manager.list_parts("blades")
                    elif sub_choice == "3":
                        manager.list_parts("ratchets")
                    elif sub_choice == "4":
                        manager.list_parts("bits")
                    elif sub_choice == "5":
                        part_type_choice = input("Tipo di parte (1:Blade, 2:Ratchet, 3:Bit): ").strip()
                        part_type = get_part_type_from_choice(part_type_choice)
                        if part_type:
                            name1 = input("Prima parte: ").strip()
                            name2 = input("Seconda parte: ").strip()
                            manager.compare_parts(part_type, name1, name2)
                        else:
                            print("❌ Scelta non valida!")
                    elif sub_choice == "6":
                        part_type_choice = input("Tipo di parte (1:Blade, 2:Ratchet, 3:Bit): ").strip()
                        part_type = get_part_type_from_choice(part_type_choice)
                        if part_type:
                            stat = input("Statistica (es. attack, defense, stamina): ").strip().lower()
                            manager.rank_parts(part_type, stat)
                        else:
                            print("❌ Scelta non valida!")
                    elif sub_choice == "7":
                        combo_type = input("Tipo di combo (attack, defense, stamina, balance): ").strip().lower()
                        manager.suggest_combo(combo_type)
                    elif sub_choice == "0":
                        break
                    else:
                        print("❌ Scelta non valida!")

            elif choice == "3": # Gestione Deck
                while True:
                    print_deck_menu()
                    sub_choice = input("\n👉 Scelta Deck: ").strip()
                    if sub_choice == "1":
                        deck_name = input("Nome del nuovo deck: ").strip()
                        manager.create_deck(deck_name)
                    elif sub_choice == "2":
                        deck_name = input("Nome del deck: ").strip()
                        if deck_name not in manager.decks:
                            print(f"❌ Il deck '{deck_name}' non esiste!")
                            continue
                        slot = input("Slot ( beyblade1, beyblade2, beyblade3): ").strip()
                        blade = input("Blade: ").strip()
                        ratchet = input("Ratchet: ").strip()
                        bit = input("Bit: ").strip()
                        manager.add_to_deck(deck_name, slot, blade, ratchet, bit)
                    elif sub_choice == "3":
                        deck_name = input("Nome del deck da mostrare: ").strip()
                        manager.show_deck(deck_name)
                    elif sub_choice == "4":
                        manager.list_decks()
                    elif sub_choice == "5":
                        deck_name = input("Nome del deck da eliminare: ").strip()
                        if input(f"Sei sicuro di voler eliminare '{deck_name}'? (s/n): ").lower() == 's':
                            manager.delete_deck(deck_name)
                    elif sub_choice == "0":
                        break
                    else:
                        print("❌ Scelta non valida!")

            elif choice == "4": # Utility
                while True:
                    print_utility_menu()
                    sub_choice = input("\n👉 Scelta Utility: ").strip()
                    if sub_choice == "1":
                        show_available_parts()
                    elif sub_choice == "2":
                        manager.fix_missing_stats()
                    elif sub_choice == "3":
                        restore_from_backup(manager)
                    elif sub_choice == "0":
                        break
                    else:
                        print("❌ Scelta non valida!")

            elif choice == "0":
                print("\n👋 Ciao! Buone battaglie con i tuoi Beyblade!")
                break

            else:
                print("❌ Scelta non valida! Riprova.")

    finally:
        manager.save_collection(force=True)


if __name__ == "__main__":
    main()