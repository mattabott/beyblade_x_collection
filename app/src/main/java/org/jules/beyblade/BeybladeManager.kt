package org.jules.beyblade

import android.content.Context
import kotlinx.serialization.json.Json
import kotlinx.serialization.encodeToString
import java.io.IOException

class BeybladeManager(private val context: Context) {

    lateinit var partsDatabase: PartsDatabase
        private set
    lateinit var userCollection: UserCollection
        private set

    // Formato JSON per la (de)serializzazione, ignora chiavi sconosciute per robustezza.
    private val json = Json { ignoreUnknownKeys = true }
    private val collectionFileName = "beyblade_collection.json"

    init {
        loadPartsDatabase()
        loadUserCollection()
    }

    /**
     * Carica il database di tutte le parti esistenti dalla cartella assets (sola lettura).
     */
    private fun loadPartsDatabase() {
        try {
            val jsonString = context.assets.open("beyblade_parts_db.json").bufferedReader().use { it.readText() }
            partsDatabase = json.decodeFromString(jsonString)
        } catch (e: IOException) {
            e.printStackTrace()
            // In caso di errore, inizializza con un database vuoto.
            partsDatabase = PartsDatabase(emptyMap(), emptyMap(), emptyMap())
        }
    }

    /**
     * Carica la collezione dell'utente. Prima tenta dal file interno (salvato),
     * altrimenti usa la versione di default presente in assets.
     */
    fun loadUserCollection() {
        val internalFile = context.getFileStreamPath(collectionFileName)
        val jsonString = if (internalFile.exists()) {
            context.openFileInput(collectionFileName).bufferedReader().use { it.readText() }
        } else {
            context.assets.open(collectionFileName).bufferedReader().use { it.readText() }
        }
        userCollection = json.decodeFromString(jsonString)
    }

    /**
     * Salva lo stato corrente della collezione dell'utente nel file interno del dispositivo.
     */
    fun saveUserCollection() {
        try {
            val jsonString = json.encodeToString(userCollection)
            context.openFileOutput(collectionFileName, Context.MODE_PRIVATE).use {
                it.write(jsonString.toByteArray())
            }
        } catch (e: IOException) {
            e.printStackTrace()
        }
    }

    // --- Gestione Deck ---

    fun createDeck(deckName: String) {
        if (userCollection.decks.containsKey(deckName)) return
        userCollection.decks[deckName] = mapOf(
            "beyblade1" to null,
            "beyblade2" to null,
            "beyblade3" to null
        )
        saveUserCollection()
    }

    fun deleteDeck(deckName: String) {
        userCollection.decks.remove(deckName)
        saveUserCollection()
    }

    fun updateDeck(deckName: String, newDeck: Map<String, BeybladeSlot?>) {
        userCollection.decks[deckName] = newDeck
        saveUserCollection()
    }

    // --- Funzioni di Analisi ---

    /**
     * Suggerisce la migliore combinazione di parti per un dato tipo di statistica.
     */
    fun suggestCombo(stat: String): Map<String, String> {
        val bestBlade = userCollection.blades.maxByOrNull { partsDatabase.blades[it.name]?.let { s -> getStatValue(s, stat) } ?: 0 }?.name
        val bestRatchet = userCollection.ratchets.maxByOrNull { partsDatabase.ratchets[it.name]?.let { s -> getStatValue(s, stat) } ?: 0 }?.name
        val bestBit = userCollection.bits.maxByOrNull { partsDatabase.bits[it.name]?.let { s -> getStatValue(s, stat) } ?: 0 }?.name

        return mapOf(
            "Blade" to (bestBlade ?: "N/A"),
            "Ratchet" to (bestRatchet ?: "N/A"),
            "Bit" to (bestBit ?: "N/A")
        )
    }

    /**
     * Funzione helper per ottenere il valore di una statistica da una PartStats.
     */
    private fun getStatValue(stats: PartStats, statName: String): Int {
        return when (statName.lowercase()) {
            "attack" -> stats.attack
            "defense" -> stats.defense
            "stamina" -> stats.stamina
            "weight" -> stats.weight
            "burst resistance" -> stats.burstResistance ?: 0
            else -> 0
        }
    }
}