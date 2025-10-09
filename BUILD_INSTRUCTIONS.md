# Istruzioni per la Compilazione dell'APK Android

Questa guida ti spiegherà come compilare l'applicazione Beyblade X Manager in un file `.apk` che potrai installare sul tuo dispositivo Android.

Useremo **Buildozer**, uno strumento che automatizza il processo di packaging per Kivy.

## Prerequisiti

Prima di iniziare, assicurati di avere:
1.  **Python 3** installato sul tuo computer.
2.  **pip**, il gestore di pacchetti di Python.

## Passaggio 1: Installare Buildozer e le sue dipendenze

Buildozer richiede alcune librerie di sistema per funzionare. Apri un terminale o un prompt dei comandi ed esegui questi comandi.

**Su Linux (consigliato, es. Ubuntu/Debian):**
```bash
sudo apt update
sudo apt install -y git zip unzip openjdk-17-jdk python3-pip autoconf libtool pkg-config zlib1g-dev libncurses5-dev libncursesw5-dev libtinfo5 cmake libffi-dev libssl-dev
```

**Su macOS (con Homebrew):**
```bash
brew install autoconf automake libtool pkg-config
```

Dopo aver installato le dipendenze di sistema, installa Buildozer con `pip`:
```bash
pip install --upgrade buildozer
```

## Passaggio 2: Preparare l'ambiente Kivy per Android

Ora, installa le dipendenze Python necessarie per la compilazione Android:
```bash
pip install --upgrade cython
```
(Kivy è già nel nostro ambiente, ma se non lo fosse, dovresti installarlo con `pip install kivy`)

## Passaggio 3: Inizializzare Buildozer

Nel terminale, naviga fino alla cartella principale del nostro progetto (la stessa dove si trova `android_app.py`) e lancia questo comando:
```bash
buildozer init
```
Questo comando creerà un file chiamato `buildozer.spec`. È il file di configurazione per la tua app.

## Passaggio 4: Configurare `buildozer.spec`

Apri il file `buildozer.spec` con un editor di testo. Non ti spaventare, dobbiamo modificare solo poche righe.

Cerca le seguenti righe e modificale come mostrato qui sotto:

1.  **Titolo dell'app:**
    ```
    title = Beyblade X Manager
    ```

2.  **Nome del pacchetto:**
    ```
    package.name = beyblademanager
    ```

3.  **Dominio del pacchetto (puoi usare un nome fittizio):**
    ```
    package.domain = org.jules.beyblade
    ```

4.  **File di avvio:**
    ```
    source.include_exts = py,png,jpg,kv,atlas,json
    ```

5.  **Requisiti di Python (fondamentale!):**
    Assicurati che Kivy sia elencato qui.
    ```
    requirements = python3,kivy==2.1.0
    ```
    *Nota: Ho specificato la versione di Kivy per coerenza.*

6.  **Permessi Android (la nostra app non ne richiede di speciali):**
    Lascia la riga dei permessi vuota o commentata.
    ```
    android.permissions =
    ```

7.  **Orientamento dello schermo (opzionale, ma consigliato):**
    Possiamo bloccare l'orientamento in verticale.
    ```
    android.orientation = portrait
    ```

Salva e chiudi il file `buildozer.spec`.

## Passaggio 5: Compilare l'APK

Sei pronto! Esegui questo comando dal terminale, sempre dalla cartella del progetto:
```bash
buildozer -v android debug
```
**Attenzione:** La prima volta che esegui questo comando, il processo sarà **molto lungo** (potrebbe richiedere 15-30 minuti o più), perché Buildozer scaricherà l'SDK e NDK di Android e preparerà l'ambiente. Le compilazioni successive saranno molto più veloci.

## Passaggio 6: Trovare e installare l'APK

Se tutto è andato a buon fine, troverai il tuo file `.apk` nella cartella `bin/`. Il file si chiamerà qualcosa come:
`bin/beyblademanager-0.1-debug.apk`

Ora puoi:
-   Trasferire questo file sul tuo telefono (via USB, email, Google Drive, ecc.).
-   Aprire il file sul telefono e installarlo (potrebbe essere necessario abilitare l'opzione "Installa da fonti sconosciute" nelle impostazioni di sicurezza di Android).

E questo è tutto! Avrai la tua applicazione Beyblade X Manager funzionante sul tuo dispositivo.