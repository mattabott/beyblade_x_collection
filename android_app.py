import kivy
from kivy.app import App
from kivy.uix.screenmanager import ScreenManager, Screen
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.gridlayout import GridLayout
from kivy.uix.scrollview import ScrollView
from kivy.uix.label import Label
from kivy.uix.button import Button
from kivy.uix.image import AsyncImage
from kivy.uix.spinner import Spinner
from kivy.uix.textinput import TextInput
from kivy.core.window import Window
from kivy.utils import get_color_from_hex
from beyblade_manager import BeybladeManager

kivy.require('2.1.0')

# Colori per un tema più gradevole
Window.clearcolor = get_color_from_hex('#f0f0f0')
PRIMARY_COLOR = get_color_from_hex('#3498db')
SECONDARY_COLOR = get_color_from_hex('#2ecc71')
ACCENT_COLOR = get_color_from_hex('#e74c3c')


class BeybladeApp(App):
    """Applicazione principale Kivy per la gestione della collezione Beyblade."""
    def build(self):
        self.title = 'Beyblade X Manager'
        self.manager = BeybladeManager()

        sm = ScreenManager()
        sm.add_widget(MainMenuScreen(name='main_menu'))
        sm.add_widget(CollectionScreen(name='collection', app=self))
        sm.add_widget(DecksScreen(name='decks', app=self))
        sm.add_widget(DeckEditScreen(name='deck_edit', app=self))
        # Schermate di Analisi
        sm.add_widget(AnalysisMenuScreen(name='analysis_menu', app=self))
        sm.add_widget(ComparePartsScreen(name='compare_parts', app=self))
        sm.add_widget(RankPartsScreen(name='rank_parts', app=self))
        sm.add_widget(SuggestComboScreen(name='suggest_combo', app=self))
        return sm

    def load_data(self):
        """Ricarica i dati dai file JSON nel manager."""
        self.manager.collection = self.manager.load_collection()
        self.manager.decks = self.manager.collection.get("decks", {})

    def get_collection_parts(self, part_type):
        """Ottiene un elenco di nomi unici per un tipo di parte dalla collezione."""
        parts = self.manager.collection.get(part_type, [])
        return sorted(list(set(p['name'] for p in parts)))


class MainMenuScreen(Screen):
    """Schermata del menu principale."""
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        layout = BoxLayout(orientation='vertical', padding=20, spacing=15)
        title = Label(text='Beyblade X Manager', font_size='48sp', size_hint_y=None, height=100, bold=True, color=(0,0,0,1))

        buttons = {
            'La Mia Collezione': ('collection', PRIMARY_COLOR),
            'Gestione Deck': ('decks', SECONDARY_COLOR),
            'Analisi e Confronto': ('analysis_menu', get_color_from_hex('#f1c40f'))
        }

        for text, (screen_name, color) in buttons.items():
            btn = Button(text=text, font_size='32sp', background_color=color)
            btn.screen_name = screen_name
            btn.bind(on_press=self.go_to_screen)
            layout.add_widget(btn)

        self.add_widget(layout)

    def go_to_screen(self, instance):
        self.manager.current = instance.screen_name


class Header(BoxLayout):
    """Widget riutilizzabile per l'header delle schermate."""
    def __init__(self, title_text, back_screen, **kwargs):
        super().__init__(size_hint_y=None, height=60, **kwargs)
        btn_back = Button(text='< Indietro', size_hint_x=0.25)
        btn_back.bind(on_press=lambda x: setattr(App.get_running_app().root, 'current', back_screen))
        title = Label(text=title_text, font_size='32sp', bold=True, color=(0,0,0,1))
        self.add_widget(btn_back)
        self.add_widget(title)


class CollectionScreen(Screen):
    """Schermata per visualizzare la collezione di parti."""
    def __init__(self, app, **kwargs):
        super().__init__(**kwargs)
        self.app = app
        self.layout = BoxLayout(orientation='vertical')
        self.add_widget(self.layout)

    def on_enter(self):
        self.layout.clear_widgets()
        self.app.load_data()
        self.build_ui()

    def build_ui(self):
        main_layout = BoxLayout(orientation='vertical', padding=10, spacing=10)
        main_layout.add_widget(Header('La Mia Collezione', 'main_menu'))

        scroll_view = ScrollView()
        grid_layout = GridLayout(cols=1, spacing=10, size_hint_y=None)
        grid_layout.bind(minimum_height=grid_layout.setter('height'))

        self.add_parts_to_layout(grid_layout, 'blades', 'Blades')
        self.add_parts_to_layout(grid_layout, 'ratchets', 'Ratchets')
        self.add_parts_to_layout(grid_layout, 'bits', 'Bits')

        scroll_view.add_widget(grid_layout)
        main_layout.add_widget(scroll_view)
        self.layout.add_widget(main_layout)

    def add_parts_to_layout(self, layout, part_type, title_text):
        layout.add_widget(Label(text=title_text, font_size='28sp', size_hint_y=None, height=50, bold=True, color=(0,0,0,1)))

        collected_parts = self.app.manager.collection.get(part_type, [])
        db_parts = self.app.manager.PARTS_DATABASE.get(part_type, {})

        if not collected_parts:
            layout.add_widget(Label(text=f'Nessun {title_text.lower()} nella collezione.', size_hint_y=None, height=40, color=(0,0,0,0.7)))
            return

        for part_data in collected_parts:
            part_name = part_data.get('name')
            part_details = db_parts.get(part_name)
            if not part_details: continue

            part_box = BoxLayout(size_hint_y=None, height=120, padding=10)
            img_url = part_details.get('image_url')
            image = AsyncImage(source=img_url if img_url else 'atlas://data/images/defaulttheme/button', size_hint_x=0.3)

            details_layout = BoxLayout(orientation='vertical')
            name_label = Label(text=part_name, font_size='20sp', bold=True, halign='left', color=(0,0,0,1), text_size=(Window.width * 0.6, None))
            stats_text = ', '.join([f"{k.capitalize()}: {v}" for k, v in part_details.get('stats', {}).items()])
            stats_label = Label(text=stats_text, font_size='14sp', halign='left', color=(0,0,0,0.8), text_size=(Window.width * 0.6, None))

            details_layout.add_widget(name_label)
            details_layout.add_widget(stats_label)
            part_box.add_widget(image)
            part_box.add_widget(details_layout)
            layout.add_widget(part_box)


class DecksScreen(Screen):
    """Schermata per visualizzare e gestire i deck."""
    def __init__(self, app, **kwargs):
        super().__init__(**kwargs)
        self.app = app
        self.layout = BoxLayout(orientation='vertical')
        self.add_widget(self.layout)

    def on_enter(self):
        self.layout.clear_widgets()
        self.app.load_data()
        self.build_ui()

    def build_ui(self):
        main_layout = BoxLayout(orientation='vertical', padding=10, spacing=10)
        main_layout.add_widget(Header('I Miei Deck', 'main_menu'))

        scroll_view = ScrollView()
        grid_layout = GridLayout(cols=1, spacing=10, size_hint_y=None)
        grid_layout.bind(minimum_height=grid_layout.setter('height'))

        decks = self.app.manager.decks
        if not decks:
            grid_layout.add_widget(Label(text='Nessun deck creato. Creane uno!', size_hint_y=None, height=60, color=(0,0,0,0.7)))
        else:
            for deck_name in sorted(decks.keys()):
                btn_deck = Button(text=deck_name, font_size='24sp', size_hint_y=None, height=80)
                btn_deck.bind(on_press=self.edit_deck)
                grid_layout.add_widget(btn_deck)

        scroll_view.add_widget(grid_layout)

        btn_new_deck = Button(text='Crea Nuovo Deck', size_hint_y=None, height=60, background_color=SECONDARY_COLOR)
        btn_new_deck.bind(on_press=self.create_new_deck)

        main_layout.add_widget(scroll_view)
        main_layout.add_widget(btn_new_deck)
        self.layout.add_widget(main_layout)

    def edit_deck(self, instance):
        edit_screen = self.manager.get_screen('deck_edit')
        edit_screen.deck_name = instance.text
        self.manager.current = 'deck_edit'

    def create_new_deck(self, instance):
        edit_screen = self.manager.get_screen('deck_edit')
        edit_screen.deck_name = None
        self.manager.current = 'deck_edit'


class DeckEditScreen(Screen):
    """Schermata per creare o modificare un deck."""
    def __init__(self, app, **kwargs):
        super().__init__(**kwargs)
        self.app = app
        self.deck_name = None
        self.layout = BoxLayout(orientation='vertical')
        self.add_widget(self.layout)
        self.spinners = {}

    def on_enter(self):
        self.layout.clear_widgets()
        self.app.load_data()
        self.build_ui()

    def build_ui(self):
        main_layout = BoxLayout(orientation='vertical', padding=10, spacing=10)

        header_text = 'Nuovo Deck' if self.deck_name is None else f"Modifica: {self.deck_name}"
        main_layout.add_widget(Header(header_text, 'decks'))

        self.deck_name_input = TextInput(text=self.deck_name or '', hint_text='Nome del Deck', size_hint_y=None, height=50)
        main_layout.add_widget(self.deck_name_input)

        bey_grid = GridLayout(cols=1, spacing=15, size_hint_y=None)
        bey_grid.bind(minimum_height=bey_grid.setter('height'))

        current_deck = self.app.manager.decks.get(self.deck_name, {})

        for i in range(1, 4):
            slot_name = f"beyblade{i}"
            bey_box = BoxLayout(orientation='vertical', spacing=5, size_hint_y=None, height=200)
            bey_box.add_widget(Label(text=f"Slot {i}", font_size='20sp', bold=True, color=(0,0,0,1)))

            slot_data = current_deck.get(slot_name, {})

            blade_spinner = Spinner(text=slot_data.get('blade') or 'Scegli Blade', values=self.app.get_collection_parts('blades'))
            ratchet_spinner = Spinner(text=slot_data.get('ratchet') or 'Scegli Ratchet', values=self.app.get_collection_parts('ratchets'))
            bit_spinner = Spinner(text=slot_data.get('bit') or 'Scegli Bit', values=self.app.get_collection_parts('bits'))

            self.spinners[f'blade{i}'] = blade_spinner
            self.spinners[f'ratchet{i}'] = ratchet_spinner
            self.spinners[f'bit{i}'] = bit_spinner

            bey_box.add_widget(blade_spinner)
            bey_box.add_widget(ratchet_spinner)
            bey_box.add_widget(bit_spinner)
            bey_grid.add_widget(bey_box)

        action_layout = BoxLayout(size_hint_y=None, height=60, spacing=10)
        btn_save = Button(text='Salva Deck', background_color=SECONDARY_COLOR)
        btn_save.bind(on_press=self.save_deck)
        action_layout.add_widget(btn_save)

        if self.deck_name:
            btn_delete = Button(text='Elimina', background_color=ACCENT_COLOR)
            btn_delete.bind(on_press=self.delete_deck)
            action_layout.add_widget(btn_delete)

        main_layout.add_widget(ScrollView(add_widget=bey_grid, do_scroll_x=False))
        main_layout.add_widget(action_layout)
        self.layout.add_widget(main_layout)

    def save_deck(self, instance):
        new_name = self.deck_name_input.text.strip()
        if not new_name: return

        if self.deck_name and new_name != self.deck_name:
            self.app.manager.delete_deck(self.deck_name)

        self.app.manager.create_deck(new_name)

        for i in range(1, 4):
            blade = self.spinners[f'blade{i}'].text
            ratchet = self.spinners[f'ratchet{i}'].text
            bit = self.spinners[f'bit{i}'].text

            if not any('Scegli' in s for s in [blade, ratchet, bit]):
                self.app.manager.add_to_deck(new_name, f" beyblade{i}", blade, ratchet, bit)

        self.manager.current = 'decks'

    def delete_deck(self, instance):
        if self.deck_name:
            self.app.manager.delete_deck(self.deck_name)
            self.manager.current = 'decks'


class AnalysisMenuScreen(Screen):
    """Menu per le diverse funzioni di analisi."""
    def __init__(self, app, **kwargs):
        super().__init__(**kwargs)
        self.app = app
        layout = BoxLayout(orientation='vertical', padding=10, spacing=10)
        layout.add_widget(Header('Analisi Collezione', 'main_menu'))

        buttons = {
            'Confronta Parti': 'compare_parts',
            'Classifica Parti': 'rank_parts',
            'Suggerisci Combo': 'suggest_combo'
        }

        for text, screen_name in buttons.items():
            btn = Button(text=text, font_size='24sp', size_hint_y=0.2)
            btn.screen_name = screen_name
            btn.bind(on_press=lambda x: setattr(self.manager, 'current', x.screen_name))
            layout.add_widget(btn)

        self.add_widget(layout)


class ComparePartsScreen(Screen):
    def __init__(self, app, **kwargs):
        super().__init__(**kwargs)
        self.app = app
        self.layout = BoxLayout(orientation='vertical', padding=10, spacing=10)
        self.add_widget(self.layout)

    def on_enter(self):
        self.app.load_data()
        self.build_ui()

    def build_ui(self):
        self.layout.clear_widgets()
        self.layout.add_widget(Header('Confronta Parti', 'analysis_menu'))

        # Selettori
        selector_layout = BoxLayout(size_hint_y=None, height=50)
        self.part_type_spinner = Spinner(text='Tipo Parte', values=('blades', 'ratchets', 'bits'))
        self.part_type_spinner.bind(text=self.update_part_spinners)
        selector_layout.add_widget(self.part_type_spinner)

        self.part1_spinner = Spinner(text='Parte 1')
        self.part2_spinner = Spinner(text='Parte 2')
        selector_layout.add_widget(self.part1_spinner)
        selector_layout.add_widget(self.part2_spinner)

        self.layout.add_widget(selector_layout)

        # Bottone di azione
        btn_compare = Button(text='Confronta', size_hint_y=None, height=50)
        btn_compare.bind(on_press=self.display_comparison)
        self.layout.add_widget(btn_compare)

        # Area Risultati
        self.results_label = Label(text='', font_size='16sp', halign='left', valign='top', color=(0,0,0,1))
        self.results_label.bind(size=self.results_label.setter('text_size'))
        self.layout.add_widget(self.results_label)

    def update_part_spinners(self, spinner, text):
        parts = self.app.get_collection_parts(text)
        self.part1_spinner.values = parts
        self.part2_spinner.values = parts
        self.part1_spinner.text = 'Parte 1'
        self.part2_spinner.text = 'Parte 2'

    def display_comparison(self, instance):
        part_type = self.part_type_spinner.text
        name1 = self.part1_spinner.text
        name2 = self.part2_spinner.text

        if 'Tipo' in part_type or 'Parte' in name1 or 'Parte' in name2:
            self.results_label.text = "Seleziona tipo e due parti da confrontare."
            return

        part1 = next((p for p in self.app.manager.collection[part_type] if p["name"] == name1), None)
        part2 = next((p for p in self.app.manager.collection[part_type] if p["name"] == name2), None)

        if not part1 or not part2: return

        stats1 = part1.get("stats", {})
        stats2 = part2.get("stats", {})

        result_text = f"[b]Confronto: {name1} vs {name2}[/b]\n\n"
        all_stats = sorted(set(stats1.keys()) | set(stats2.keys()))

        for stat in all_stats:
            v1 = stats1.get(stat, 0)
            v2 = stats2.get(stat, 0)
            diff = v1 - v2
            winner = " <-- Vantaggio" if diff > 0 else " --> Vantaggio" if diff < 0 else ""
            result_text += f"{stat.capitalize():<15} | {v1:<4} vs {v2:<4} | Diff: {diff: <4}{winner}\n"

        self.results_label.text = result_text


class RankPartsScreen(Screen):
    def __init__(self, app, **kwargs):
        super().__init__(**kwargs)
        self.app = app
        self.layout = BoxLayout(orientation='vertical', padding=10, spacing=10)
        self.add_widget(self.layout)

    def on_enter(self):
        self.app.load_data()
        self.build_ui()

    def build_ui(self):
        self.layout.clear_widgets()
        self.layout.add_widget(Header('Classifica Parti', 'analysis_menu'))

        selector_layout = BoxLayout(size_hint_y=None, height=50)
        self.part_type_spinner = Spinner(text='Tipo Parte', values=('blades', 'ratchets', 'bits'))
        self.stat_spinner = Spinner(text='Statistica', values=('attack', 'defense', 'stamina', 'weight', 'burst_resistance'))
        selector_layout.add_widget(self.part_type_spinner)
        selector_layout.add_widget(self.stat_spinner)
        self.layout.add_widget(selector_layout)

        btn_rank = Button(text='Mostra Classifica', size_hint_y=None, height=50)
        btn_rank.bind(on_press=self.display_ranking)
        self.layout.add_widget(btn_rank)

        self.results_label = Label(text='', markup=True, font_size='16sp', color=(0,0,0,1))
        self.layout.add_widget(ScrollView(add_widget=self.results_label, do_scroll_x=False))

    def display_ranking(self, instance):
        part_type = self.part_type_spinner.text
        stat = self.stat_spinner.text

        if 'Tipo' in part_type or 'Stat' in stat:
            self.results_label.text = "Seleziona tipo e statistica."
            return

        parts = [p for p in self.app.manager.collection.get(part_type, []) if stat in p.get('stats', {})]
        ranked = sorted(parts, key=lambda p: p['stats'][stat], reverse=True)

        result_text = f"[b]Classifica per {stat.upper()}[/b]\n\n"
        for i, part in enumerate(ranked, 1):
            result_text += f"{i}. {part['name']:<25} - {part['stats'][stat]}\n"

        self.results_label.text = result_text


class SuggestComboScreen(Screen):
    def __init__(self, app, **kwargs):
        super().__init__(**kwargs)
        self.app = app
        self.layout = BoxLayout(orientation='vertical', padding=10, spacing=10)
        self.add_widget(self.layout)

    def on_enter(self):
        self.app.load_data()
        self.build_ui()

    def build_ui(self):
        self.layout.clear_widgets()
        self.layout.add_widget(Header('Suggerisci Combo', 'analysis_menu'))

        self.combo_type_spinner = Spinner(text='Tipo di Combo', values=('attack', 'defense', 'stamina', 'balance'), size_hint_y=None, height=50)
        self.layout.add_widget(self.combo_type_spinner)

        btn_suggest = Button(text='Suggerisci', size_hint_y=None, height=50)
        btn_suggest.bind(on_press=self.display_suggestion)
        self.layout.add_widget(btn_suggest)

        self.results_label = Label(text='', markup=True, font_size='18sp', color=(0,0,0,1))
        self.layout.add_widget(self.results_label)

    def display_suggestion(self, instance):
        combo_type = self.combo_type_spinner.text
        if 'Tipo' in combo_type:
            self.results_label.text = "Seleziona un tipo di combo."
            return

        stat_map = {"attack": "attack", "defense": "defense", "stamina": "stamina", "balance": "attack"}
        stat = stat_map[combo_type]

        best_parts = {}
        for part_type in ['blades', 'ratchets', 'bits']:
            collection = self.app.manager.collection.get(part_type, [])
            if not collection:
                self.results_label.text = f"Nessun {part_type} nella collezione."
                return
            best_parts[part_type] = max(collection, key=lambda x: x.get("stats", {}).get(stat, 0))

        result_text = f"[b]Combo {combo_type.upper()} Suggerita:[/b]\n\n"
        result_text += f"Blade:   [b]{best_parts['blades']['name']}[/b]\n"
        result_text += f"Ratchet: [b]{best_parts['ratchets']['name']}[/b]\n"
        result_text += f"Bit:     [b]{best_parts['bits']['name']}[/b]"

        self.results_label.text = result_text


if __name__ == '__main__':
    BeybladeApp().run()