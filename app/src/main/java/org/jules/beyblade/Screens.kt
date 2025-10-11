package org.jules.beyblade

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.navigation.NavHostController
import coil.compose.AsyncImage

// --- Schermata Collezione ---

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CollectionScreen(navController: NavHostController, manager: BeybladeManager) {
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("La Mia Collezione") },
                navigationIcon = {
                    IconButton(onClick = { navController.popBackStack() }) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Indietro")
                    }
                }
            )
        }
    ) { padding ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(horizontal = 16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            item { PartSection("Blades", manager.userCollection.blades, manager) }
            item { PartSection("Ratchets", manager.userCollection.ratchets, manager) }
            item { PartSection("Bits", manager.userCollection.bits, manager) }
        }
    }
}

@Composable
fun PartSection(title: String, parts: List<CollectedPart>, manager: BeybladeManager) {
    Column(modifier = Modifier.padding(vertical = 8.dp)) {
        Text(text = title, style = MaterialTheme.typography.titleLarge, modifier = Modifier.padding(bottom = 8.dp))

        val uniqueParts = parts.groupingBy { it.name }.eachCount()

        if (uniqueParts.isEmpty()) {
            Text("Nessuna parte nella collezione.")
        } else {
            uniqueParts.entries.sortedBy { it.key }.forEach { (name, count) ->
                PartCard(name, count, manager)
            }
        }
    }
}

@Composable
fun PartCard(name: String, count: Int, manager: BeybladeManager) {
    val partDetails = manager.partsDatabase.blades[name] ?: manager.partsDatabase.ratchets[name] ?: manager.partsDatabase.bits[name]

    Card(
        modifier = Modifier.fillMaxWidth().padding(vertical = 4.dp),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Row(
            modifier = Modifier.padding(12.dp).fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            AsyncImage(
                model = partDetails?.imageUrl,
                contentDescription = name,
                modifier = Modifier.size(80.dp).padding(end = 12.dp)
            )
            Column(modifier = Modifier.weight(1f)) {
                Text(name, fontWeight = FontWeight.Bold, fontSize = 18.sp)
                partDetails?.stats?.let { stats ->
                    Text("ATK: ${stats.attack} | DEF: ${stats.defense} | STA: ${stats.stamina}", fontSize = 14.sp, lineHeight = 20.sp)
                }
            }
            if (count > 1) {
                Text(
                    text = "x$count",
                    style = MaterialTheme.typography.bodyLarge,
                    fontWeight = FontWeight.Bold,
                    modifier = Modifier.padding(start = 8.dp)
                )
            }
        }
    }
}


// --- Schermate Deck ---

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DecksScreen(navController: NavHostController, manager: BeybladeManager) {
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Gestione Deck") },
                navigationIcon = {
                    IconButton(onClick = { navController.popBackStack() }) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Indietro")
                    }
                }
            )
        },
        floatingActionButton = {
            FloatingActionButton(onClick = { navController.navigate("deck_edit/new") }) {
                Text("+ Crea")
            }
        }
    ) { padding ->
        LazyColumn(modifier = Modifier.padding(padding).padding(16.dp)) {
            if (manager.userCollection.decks.isEmpty()) {
                item { Text("Nessun deck creato.") }
            } else {
                items(manager.userCollection.decks.keys.sorted()) { deckName ->
                    Button(
                        onClick = { navController.navigate("deck_edit/$deckName") },
                        modifier = Modifier.fillMaxWidth().padding(vertical=4.dp)
                    ) {
                        Text(deckName)
                    }
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DeckEditScreen(navController: NavHostController, manager: BeybladeManager, deckName: String?) {
    val isNewDeck = deckName == "new"
    var currentDeckName by remember { mutableStateOf(if (isNewDeck) "" else deckName!!) }

    val deckData = if (isNewDeck) null else manager.userCollection.decks[deckName]

    var beyblade1 by remember { mutableStateOf(deckData?.get("beyblade1")) }
    var beyblade2 by remember { mutableStateOf(deckData?.get("beyblade2")) }
    var beyblade3 by remember { mutableStateOf(deckData?.get("beyblade3")) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(if (isNewDeck) "Crea Deck" else "Modifica Deck") },
                navigationIcon = {
                    IconButton(onClick = { navController.popBackStack() }) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Indietro")
                    }
                }
            )
        }
    ) { padding ->
        Column(modifier = Modifier.padding(padding).padding(16.dp).fillMaxSize()) {
            OutlinedTextField(
                value = currentDeckName,
                onValueChange = { currentDeckName = it },
                label = { Text("Nome del Deck") },
                modifier = Modifier.fillMaxWidth(),
                readOnly = !isNewDeck
            )
            Spacer(Modifier.height(16.dp))

            LazyColumn {
                item { BeybladeSlotEditor("Beyblade 1", beyblade1, manager) { beyblade1 = it } }
                item { BeybladeSlotEditor("Beyblade 2", beyblade2, manager) { beyblade2 = it } }
                item { BeybladeSlotEditor("Beyblade 3", beyblade3, manager) { beyblade3 = it } }
            }

            Spacer(Modifier.weight(1f))

            Button(onClick = {
                val finalDeckName = if (isNewDeck) currentDeckName else deckName!!
                if(finalDeckName.isNotBlank()){
                    if(isNewDeck) manager.createDeck(finalDeckName)
                    val newDeck = mapOf("beyblade1" to beyblade1, "beyblade2" to beyblade2, "beyblade3" to beyblade3)
                    manager.updateDeck(finalDeckName, newDeck)
                    navController.popBackStack()
                }
            }, modifier = Modifier.fillMaxWidth()) {
                Text("Salva Deck")
            }
            if (!isNewDeck) {
                Button(onClick = {
                    manager.deleteDeck(deckName!!)
                    navController.popBackStack()
                }, colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.error), modifier = Modifier.fillMaxWidth()) {
                    Text("Elimina Deck")
                }
            }
        }
    }
}

@Composable
fun BeybladeSlotEditor(title: String, slot: BeybladeSlot?, manager: BeybladeManager, onValueChange: (BeybladeSlot) -> Unit) {
    var blade by remember { mutableStateOf(slot?.blade ?: "Scegli Blade") }
    var ratchet by remember { mutableStateOf(slot?.ratchet ?: "Scegli Ratchet") }
    var bit by remember { mutableStateOf(slot?.bit ?: "Scegli Bit") }

    Column(modifier = Modifier.padding(vertical = 8.dp)) {
        Text(title, style = MaterialTheme.typography.titleMedium)
        PartSpinner("Blade", blade, manager.userCollection.blades.map { it.name }) { blade = it; onValueChange(BeybladeSlot(blade, ratchet, bit)) }
        PartSpinner("Ratchet", ratchet, manager.userCollection.ratchets.map { it.name }) { ratchet = it; onValueChange(BeybladeSlot(blade, ratchet, bit)) }
        PartSpinner("Bit", bit, manager.userCollection.bits.map { it.name }) { bit = it; onValueChange(BeybladeSlot(blade, ratchet, bit)) }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PartSpinner(label: String, selected: String, options: List<String>, onSelectionChanged: (String) -> Unit) {
    var expanded by remember { mutableStateOf(false) }

    ExposedDropdownMenuBox(expanded = expanded, onExpandedChange = { expanded = !expanded }, modifier = Modifier.padding(vertical = 4.dp)) {
        OutlinedTextField(
            value = selected,
            onValueChange = {},
            readOnly = true,
            label = { Text(label) },
            trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = expanded) },
            modifier = Modifier.menuAnchor().fillMaxWidth()
        )
        ExposedDropdownMenu(expanded = expanded, onDismissRequest = { expanded = false }) {
            options.forEach { option ->
                DropdownMenuItem(text = { Text(option) }, onClick = {
                    onSelectionChanged(option)
                    expanded = false
                })
            }
        }
    }
}


// --- Schermate Analisi ---

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AnalysisMenuScreen(navController: NavHostController) {
    Scaffold(
        topBar = { TopAppBar(title = { Text("Menu Analisi") }, navigationIcon = { IconButton(onClick = { navController.popBackStack() }) { Icon(Icons.Default.ArrowBack, "Indietro") } }) }
    ) { padding ->
        Column(modifier = Modifier.padding(padding).padding(16.dp).fillMaxSize(), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Button(onClick = { navController.navigate("compare_parts") }, modifier = Modifier.fillMaxWidth()) { Text("Confronta Parti") }
            Button(onClick = { navController.navigate("rank_parts") }, modifier = Modifier.fillMaxWidth()) { Text("Classifica Parti") }
            Button(onClick = { navController.navigate("suggest_combo") }, modifier = Modifier.fillMaxWidth()) { Text("Suggerisci Combo") }
        }
    }
}

@Composable
fun ComparePartsScreen(navController: NavHostController, manager: BeybladeManager) {
    var partType by remember { mutableStateOf("blades") }
    var part1Name by remember { mutableStateOf<String?>(null) }
    var part2Name by remember { mutableStateOf<String?>(null) }
    var comparisonResult by remember { mutableStateOf("") }

    Column(modifier = Modifier.padding(16.dp)) {
        PartSpinner("Tipo Parte", partType, listOf("blades", "ratchets", "bits")) { partType = it; part1Name = null; part2Name = null }

        val parts = manager.userCollection.run {
            when(partType) {
                "blades" -> blades
                "ratchets" -> ratchets
                else -> bits
            }
        }.map { it.name }

        PartSpinner("Parte 1", part1Name ?: "Scegli", parts) { part1Name = it }
        PartSpinner("Parte 2", part2Name ?: "Scegli", parts) { part2Name = it }

        Button(onClick = {
            if (part1Name != null && part2Name != null) {
                // Logica di confronto
                comparisonResult = "Risultato del confronto tra $part1Name e $part2Name..."
            }
        }) { Text("Confronta") }

        Text(comparisonResult)
    }
}

@Composable
fun RankPartsScreen(navController: NavHostController, manager: BeybladeManager) {
    var partType by remember { mutableStateOf("blades") }
    var stat by remember { mutableStateOf("attack") }
    var rankingResult by remember { mutableStateOf<List<Pair<String, Int>>>(emptyList()) }

    Column(modifier = Modifier.padding(16.dp)) {
        PartSpinner("Tipo Parte", partType, listOf("blades", "ratchets", "bits")) { partType = it }
        PartSpinner("Statistica", stat, listOf("attack", "defense", "stamina", "weight", "burst_resistance")) { stat = it }

        Button(onClick = {
            // Logica di classifica
        }) { Text("Mostra Classifica") }

        LazyColumn {
            items(rankingResult) { (name, value) ->
                Text("$name: $value")
            }
        }
    }
}

@Composable
fun SuggestComboScreen(navController: NavHostController, manager: BeybladeManager) {
    var comboType by remember { mutableStateOf("attack") }
    var suggestion by remember { mutableStateOf<Map<String, String>?>(null) }

    Column(modifier = Modifier.padding(16.dp).fillMaxSize(), verticalArrangement = Arrangement.spacedBy(8.dp)) {
        PartSpinner("Tipo di Combo", comboType, listOf("attack", "defense", "stamina", "balance")) { comboType = it }
        Button(onClick = { suggestion = manager.suggestCombo(combo_type) }, modifier = Modifier.fillMaxWidth()) {
            Text("Suggerisci Combo")
        }
        suggestion?.let {
            Card(modifier = Modifier.fillMaxWidth()) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Text("Blade: ${it["Blade"]}", style = MaterialTheme.typography.bodyLarge)
                    Text("Ratchet: ${it["Ratchet"]}", style = MaterialTheme.typography.bodyLarge)
                    Text("Bit: ${it["Bit"]}", style = MaterialTheme.typography.bodyLarge)
                }
            }
        }
    }
}