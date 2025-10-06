#!/usr/bin/env python3
"""Script per aggiungere URL immagini al database Beyblade X"""

import json
import sys

def add_image_urls():
    """Aggiunge URL immagini al database"""

    # Carica il database
    with open('beyblade_parts_db.json', 'r', encoding='utf-8') as f:
        db = json.load(f)

    # URL immagini trovate (pattern: Beyblade Fandom Wiki)
    image_mapping = {
        'blades': {
            'Dran Sword': 'https://static.wikia.nocookie.net/beyblade/images/5/5f/BladeDranSword.png',
            'Sword Dran': 'https://static.wikia.nocookie.net/beyblade/images/5/5f/BladeDranSword.png',
            'Phoenix Wing': 'https://static.wikia.nocookie.net/beyblade/images/2/2d/BladePhoenixWing.png',
            'Shark Edge': 'https://static.wikia.nocookie.net/beyblade/images/2/2e/BladeSharkEdge.png',
            'Knight Shield': 'https://static.wikia.nocookie.net/beyblade/images/d/d0/BladeKnightShield.png',
            'Wizard Rod': 'https://static.wikia.nocookie.net/beyblade/images/f/f4/BladeWizardRod.png',
            'Hells Scythe': 'https://static.wikia.nocookie.net/beyblade/images/b/b6/BladeHellsScythe.png',
            'Hells Chain': 'https://static.wikia.nocookie.net/beyblade/images/8/88/BladeHellsChain.png',
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
        },
        'ratchets': {
            '3-60': 'https://static.wikia.nocookie.net/beyblade/images/c/c7/Ratchet3-60.png',
            '4-60': 'https://static.wikia.nocookie.net/beyblade/images/5/5e/Ratchet4-60.png',
            '5-60': 'https://static.wikia.nocookie.net/beyblade/images/b/bb/Ratchet5-60.png',
            '9-60': 'https://static.wikia.nocookie.net/beyblade/images/4/4f/Ratchet9-60.png',
            '3-80': 'https://static.wikia.nocookie.net/beyblade/images/4/4c/Ratchet3-80.png',
            '4-80': 'https://static.wikia.nocookie.net/beyblade/images/7/77/Ratchet4-80.png',
        }
    }

    # Aggiungi URL immagini
    added = 0
    for part_type in ['blades', 'bits', 'ratchets']:
        for name, data in db[part_type].items():
            # Aggiungi URL se disponibile
            if name in image_mapping.get(part_type, {}):
                db[part_type][name]['image_url'] = image_mapping[part_type][name]
                added += 1
                print(f"✅ {name} - Immagine aggiunta")
            else:
                # Imposta come None se non trovata
                db[part_type][name]['image_url'] = None

    # Salva il database aggiornato
    with open('beyblade_parts_db.json', 'w', encoding='utf-8') as f:
        json.dump(db, f, indent=2, ensure_ascii=False)

    print(f"\n✅ Database aggiornato! {added} immagini aggiunte.")
    print(f"📝 Backup salvato in: beyblade_parts_db.json.backup")

    return added

if __name__ == "__main__":
    try:
        add_image_urls()
    except Exception as e:
        print(f"❌ Errore: {e}")
        sys.exit(1)
