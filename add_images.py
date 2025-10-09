#!/usr/bin/env python3
"""Script per aggiungere URL immagini al database Beyblade X"""

import json
import sys
import os

def add_image_urls():
    """Aggiunge URL immagini al database in modo più intelligente, gestendo alias."""

    db_file = 'beyblade_parts_db.json'
    backup_file = 'beyblade_parts_db.json.backup'

    # Crea un backup prima di modificare
    if os.path.exists(db_file):
        with open(db_file, 'r', encoding='utf-8') as f:
            original_db = json.load(f)
        with open(backup_file, 'w', encoding='utf-8') as f:
            json.dump(original_db, f, indent=2, ensure_ascii=False)
        print(f"📝 Backup dell'originale salvato in: {backup_file}")

    # Carica il database
    with open(db_file, 'r', encoding='utf-8') as f:
        db = json.load(f)

    # URL delle immagini (fonte: Beyblade Fandom Wiki)
    image_mapping = {
        'blades': {
            'Dran Sword': 'https://static.wikia.nocookie.net/beyblade/images/5/5f/BladeDranSword.png',
            'Phoenix Wing': 'https://static.wikia.nocookie.net/beyblade/images/2/2d/BladePhoenixWing.png',
            'Shark Edge': 'https://static.wikia.nocookie.net/beyblade/images/2/2e/BladeSharkEdge.png',
            'Knight Shield': 'https://static.wikia.nocookie.net/beyblade/images/d/d0/BladeKnightShield.png',
            'Wizard Arrow': 'https://static.wikia.nocookie.net/beyblade/images/d/d7/BladeWizardArrow.png',
            'Hells Scythe': 'https://static.wikia.nocookie.net/beyblade/images/b/b6/BladeHellsScythe.png',
            'Hells Chain': 'https://static.wikia.nocookie.net/beyblade/images/8/88/BladeHellsChain.png',
        },
        'ratchets': {
            '3-60': 'https://static.wikia.nocookie.net/beyblade/images/c/c7/Ratchet3-60.png',
            '4-60': 'https://static.wikia.nocookie.net/beyblade/images/5/5e/Ratchet4-60.png',
            '5-60': 'https://static.wikia.nocookie.net/beyblade/images/b/bb/Ratchet5-60.png',
            '9-60': 'https://static.wikia.nocookie.net/beyblade/images/4/4f/Ratchet9-60.png',
            '3-80': 'https://static.wikia.nocookie.net/beyblade/images/4/4c/Ratchet3-80.png',
            '4-80': 'https://static.wikia.nocookie.net/beyblade/images/7/77/Ratchet4-80.png',
        },
        'bits': {
            'Flat (F)': 'https://static.wikia.nocookie.net/beyblade/images/1/1f/BitFlat.png',
            'Ball (B)': 'https://static.wikia.nocookie.net/beyblade/images/a/a5/BitBall.png',
            'Point (P)': 'https://static.wikia.nocookie.net/beyblade/images/8/8d/BitPoint.png',
            'Needle (N)': 'https://static.wikia.nocookie.net/beyblade/images/f/f5/BitNeedle.png',
            'Low Flat (LF)': 'https://static.wikia.nocookie.net/beyblade/images/3/32/BitLowFlat.png',
            'Gear Flat (GF)': 'https://static.wikia.nocookie.net/beyblade/images/e/ef/BitGearFlat.png',
            'High Needle (HN)': 'https://static.wikia.nocookie.net/beyblade/images/7/78/BitHighNeedle.png',
            'Orb (O)': 'https://static.wikia.nocookie.net/beyblade/images/7/7d/BitOrb.png',
            'Rush (R)': 'https://static.wikia.nocookie.net/beyblade/images/0/0f/BitRush.png',
            'Taper (T)': 'https://static.wikia.nocookie.net/beyblade/images/6/60/BitTaper.png',
        }
    }

    # Mappatura degli alias ai nomi ufficiali presenti in image_mapping
    alias_mapping = {
        'blades': {
            'Sword Dran': 'Dran Sword',
            'Arrow Wizard': 'Wizard Arrow',
            'Helm Knight': 'Knight Shield',
            'Scythe Incendio': 'Hells Scythe',
        }
    }

    # Aggiungi URL immagini
    added_count = 0
    updated_count = 0
    for part_type in ['blades', 'ratchets', 'bits']:
        for name, data in db[part_type].items():
            # Controlla se l'immagine è già presente e corretta
            current_url = data.get('image_url')

            # Determina il nome da cercare
            official_name = alias_mapping.get(part_type, {}).get(name, name)

            # Cerca l'URL nell'image_mapping
            image_url = image_mapping.get(part_type, {}).get(official_name)

            if image_url:
                if current_url != image_url:
                    db[part_type][name]['image_url'] = image_url
                    if current_url:
                        updated_count += 1
                        print(f"🔄 {name} - Immagine aggiornata.")
                    else:
                        added_count += 1
                        print(f"✅ {name} - Immagine aggiunta.")
                # Se l'URL è già corretto, non fare nulla
            elif current_url is None:
                # Se non c'è URL e non ne abbiamo trovato uno, lo impostiamo a null esplicitamente
                 db[part_type][name]['image_url'] = None


    # Salva il database aggiornato
    with open(db_file, 'w', encoding='utf-8') as f:
        json.dump(db, f, indent=2, ensure_ascii=False)

    print(f"\n✅ Database aggiornato!")
    if added_count > 0:
        print(f"   - {added_count} nuove immagini aggiunte.")
    if updated_count > 0:
        print(f"   - {updated_count} immagini esistenti aggiornate.")
    if added_count == 0 and updated_count == 0:
        print("   - Nessuna modifica necessaria.")

    return added_count + updated_count

if __name__ == "__main__":
    try:
        add_image_urls()
    except Exception as e:
        print(f"❌ Errore durante l'aggiornamento del database: {e}")
        sys.exit(1)