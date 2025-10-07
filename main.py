from beyblade_manager import BeybladeManager
from ui import (
    print_main_menu, print_collection_menu, print_analysis_menu, print_deck_menu, print_utility_menu,
    get_part_type_from_choice, quick_add_parts, quick_remove_parts, show_available_parts, restore_from_backup
)

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
