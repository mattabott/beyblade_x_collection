package org.jules.beyblade

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.navigation.compose.*
import androidx.navigation.NavHostController

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val beybladeManager = BeybladeManager(applicationContext)

        setContent {
            BeybladeAppTheme {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    AppNavigator(manager = beybladeManager)
                }
            }
        }
    }
}

@Composable
fun BeybladeAppTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = lightColorScheme(
            primary = Color(0xFF007BFF),
            secondary = Color(0xFF28A745),
            background = Color(0xFFF0F2F5),
            surface = Color.White,
            onPrimary = Color.White,
            onSecondary = Color.White,
            onBackground = Color(0xFF333333),
            onSurface = Color(0xFF333333)
        ),
        typography = Typography(
            headlineLarge = androidx.compose.ui.text.TextStyle(
                fontWeight = FontWeight.Bold,
                fontSize = 32.sp
            ),
            titleLarge = androidx.compose.ui.text.TextStyle(
                fontWeight = FontWeight.SemiBold,
                fontSize = 24.sp
            ),
            bodyLarge = androidx.compose.ui.text.TextStyle(
                fontSize = 16.sp
            )
        ),
        content = content
    )
}

@Composable
fun AppNavigator(manager: BeybladeManager) {
    val navController = rememberNavController()
    NavHost(navController = navController, startDestination = "main_menu") {
        composable("main_menu") { MainMenuScreen(navController) }
        composable("collection") { CollectionScreen(navController, manager) }
        composable("decks") { DecksScreen(navController, manager) }
        composable("deck_edit/{deckName}") { backStackEntry ->
            DeckEditScreen(
                navController = navController,
                manager = manager,
                deckName = backStackEntry.arguments?.getString("deckName")
            )
        }
        composable("analysis_menu") { AnalysisMenuScreen(navController) }
        composable("compare_parts") { ComparePartsScreen(navController, manager) }
        composable("rank_parts") { RankPartsScreen(navController, manager) }
        composable("suggest_combo") { SuggestComboScreen(navController, manager) }
    }
}

@Composable
fun MainMenuScreen(navController: NavHostController) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        verticalArrangement = Arrangement.Center
    ) {
        Text(
            text = "Beyblade X Manager",
            style = MaterialTheme.typography.headlineLarge,
            modifier = Modifier.padding(bottom = 32.dp)
        )

        Button(
            onClick = { navController.navigate("collection") },
            modifier = Modifier.fillMaxWidth().padding(vertical = 8.dp)
        ) {
            Text("La Mia Collezione", fontSize = 18.sp)
        }

        Button(
            onClick = { navController.navigate("decks") },
            modifier = Modifier.fillMaxWidth().padding(vertical = 8.dp)
        ) {
            Text("Gestione Deck", fontSize = 18.sp)
        }

        Button(
            onClick = { navController.navigate("analysis_menu") },
            modifier = Modifier.fillMaxWidth().padding(vertical = 8.dp)
        ) {
            Text("Analisi", fontSize = 18.sp)
        }
    }
}