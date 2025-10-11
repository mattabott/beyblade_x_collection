package org.jules.beyblade

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * Definisce le statistiche di una singola parte.
 * I valori di default vengono usati in caso di dati mancanti nel JSON.
 */
@Serializable
data class PartStats(
    val attack: Int = 0,
    val defense: Int = 0,
    val stamina: Int = 0,
    val weight: Int = 0,
    val type: String? = null,
    @SerialName("burst_resistance") val burstResistance: Int? = null,
    @SerialName("image_url") val imageUrl: String? = null
)

/**
 * Rappresenta il database completo di tutte le parti esistenti, letto da `beyblade_parts_db.json`.
 */
@Serializable
data class PartsDatabase(
    val blades: Map<String, PartStats>,
    val ratchets: Map<String, PartStats>,
    val bits: Map<String, PartStats>
)

/**
 * Rappresenta una singola parte posseduta dall'utente nella sua collezione.
 */
@Serializable
data class CollectedPart(
    val name: String,
    // Le statistiche vengono incluse per coerenza, ma verranno primariamente lette dal PartsDatabase.
    val stats: PartStats = PartStats()
)

/**
 * Rappresenta la combinazione di parti che formano un singolo Beyblade in un deck.
 */
@Serializable
data class BeybladeSlot(
    val blade: String?,
    val ratchet: String?,
    val bit: String?
)

/**
 * Rappresenta l'intera collezione dell'utente, inclusi i deck.
 * Letto e scritto su `beyblade_collection.json`.
 * Le proprietà sono mutabili per permettere all'app di modificarle.
 */
@Serializable
data class UserCollection(
    var blades: MutableList<CollectedPart>,
    var ratchets: MutableList<CollectedPart>,
    var bits: MutableList<CollectedPart>,
    var decks: MutableMap<String, Map<String, BeybladeSlot?>>
)