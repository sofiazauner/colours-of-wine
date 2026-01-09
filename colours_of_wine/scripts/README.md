# Scripts zum Aktualisieren der Sample-Wein-Daten

Diese Skripte extrahieren Wein-Beschreibungen aus lokalen Dateien und generieren Dart-Code für `lib/data/sample_wines.dart`.

## Voraussetzungen

1. **Python 3** muss installiert sein
2. **Optional** für PDF-Extraktion:
   ```bash
   pip3 install PyPDF2
   # oder
   pip3 install pdfplumber
   ```
3. **Bash** für die Shell-Skripte (auf Windows: Git Bash oder WSL)

## Struktur der Wein-Beschreibungen

Die Skripte erwarten folgende Ordnerstruktur:

```
/pfad/zu/wein-beschreibungen/
├── 01 Chardonnay Markowitsch/
│   ├── AproposWein.txt
│   ├── Grubis.txt
│   └── ...
├── 02 Tignanello/
│   ├── Beschreibung1.txt
│   └── ...
└── ...
```

Jeder Wein sollte in einem eigenen Ordner sein. Die Dateien können `.txt`, `.TXT` oder `.pdf` sein.

## Verwendung

### 1. Umgebungsvariable setzen

**Linux/Mac:**
```bash
export WINE_DESCRIPTIONS_DIR="/pfad/zu/wein-beschreibungen"
```

**Windows (PowerShell):**
```powershell
$env:WINE_DESCRIPTIONS_DIR="C:\pfad\zu\wein-beschreibungen"
```

**Windows (Git Bash):**
```bash
export WINE_DESCRIPTIONS_DIR="/c/pfad/zu/wein-beschreibungen"
```

### 2. Haupt-Skript ausführen

Das Haupt-Skript `extract_all_wines.py` extrahiert alle Beschreibungen und generiert Dart-Code:

```bash
cd colours_of_wine/scripts
python3 extract_all_wines.py
```

**Oder direkt mit Pfad:**
```bash
python3 extract_all_wines.py "/pfad/zu/wein-beschreibungen"
```

Das Skript erstellt `wine_descriptions_output.txt` mit dem generierten Dart-Code.

### 3. Output in sample_wines.dart integrieren

1. Öffne `lib/data/sample_wines.dart`
2. Finde den entsprechenden Wein (z.B. `id: '1'`)
3. Ersetze den `descriptions:` Block mit dem generierten Code aus `wine_descriptions_output.txt`

**Beispiel:**

Generierter Code aus `wine_descriptions_output.txt`:
```dart
// Wine ID 1: 01 Chardonnay Markowitsch
descriptions: [
  WineDescription(
    id: '1-1',
    source: 'AproposWein',
    url: 'https://example.com',
    text: 'Beschreibungstext...',
  ),
  ...
],
```

Einfügen in `sample_wines.dart`:
```dart
Wine(
  id: '1',
  name: 'Chardonnay',
  ...
  descriptions: [
    // Hier den generierten Code einfügen
    WineDescription(
      id: '1-1',
      source: 'AproposWein',
      url: 'https://example.com',
      text: 'Beschreibungstext...',
    ),
    ...
  ],
),
```

## Weitere Skripte

### `extract_pdf_texts.py`
Extrahiert nur PDF-Dateien (benötigt PyPDF2 oder pdfplumber):
```bash
python3 extract_pdf_texts.py
```

### `extract_txt_texts.py`
Extrahiert nur TXT-Dateien:
```bash
python3 extract_txt_texts.py
```

### `read_wine_texts.sh`
Zeigt alle Text-Dateien an:
```bash
chmod +x read_wine_texts.sh
./read_wine_texts.sh
```

### `update_all_wines.sh`
Zeigt eine Übersicht über alle gefundenen Beschreibungs-Dateien:
```bash
chmod +x update_all_wines.sh
./update_all_wines.sh
```

## Wein-ID Mapping

Das Skript verwendet folgendes Mapping von Ordnernamen zu Wein-IDs:

| Ordner-Name | Wein-ID |
|-------------|---------|
| 01 Chardonnay Markowitsch | 1 |
| 02 Tignanello | 2 |
| 03 Riesling Bürklin | 3 |
| 04 Ducru Beaucaillou | 4 |
| 07 Welschriesling TBA Kracher | 5 |
| 08 Pinot Noir Südfrankreich | 6 |
| 09 Zweigelt Achs | 7 |
| 10 Brut rosé Reserve Loimer | 8 |
| 04 Sauvignon blanc Cloudy Bay | 9 |
| 05 Weissburgunder Gross | 10 |

Wenn ein Ordner nicht im Mapping gefunden wird, gibt das Skript eine Warnung aus.

## Troubleshooting

### "Directory not found"
- Prüfe, ob der Pfad korrekt ist
- Auf Windows: Verwende `/c/pfad` statt `C:\pfad` in Git Bash
- Stelle sicher, dass die Umgebungsvariable gesetzt ist: `echo $WINE_DESCRIPTIONS_DIR`

### "No PDF library found"
- Installiere PyPDF2: `pip3 install PyPDF2`
- Oder pdfplumber: `pip3 install pdfplumber`

### "Warning: No mapping found for..."
- Der Ordner-Name passt nicht zum Mapping
- Passe das Mapping in `extract_all_wines.py` an (Zeile 42-53)

### Encoding-Fehler
- Die Skripte versuchen automatisch UTF-8 und Latin-1
- Falls weiterhin Probleme: Öffne die Datei in einem Editor und speichere als UTF-8

