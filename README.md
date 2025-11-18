# Software Praktikum
"Colours of Wine"

PR Software Praktikum WS 2025/26

Sofia Zauner, Peter Balint

## ✅ TO-DOs

### Data Extraction
- [ ] Rebsorte (evtl. weitere fehlende Daten?) mittels Gemini finden
      
### Web Descriptioins
- [ ] Descriptions filtern (momentan noch mit Domainnamen in der Suchanfrage - fuktioniert nicht so gut; wenn wir es so behalten, Logik davon in backend geben (Code Review))
- [ ] Nicht nur englische Descriptions suchen, sondern auch deutsche (oder überhaupt keinen Sprachfilter - Gemini übersetzt intern?)

### Summary
- [ ] Nicht nur Snippets verwenden, sondern ganze Descriptions auslesen (Readability.js?)
- [ ] Nicht erneut nach Descriptions suchen, sondern die bereits gefundenen verwenden (vllt. als Parameter übergeben?)
- [ ] Improve generation time (not sure if still relevant after model change?)

### Image Generation
- [ ] Mineralik-/Süße-Sidebar + Bubbles hinzufügen (Angabe von Anja)
- [ ] Bild downloadable (?)
- [ ] Farben auf #E- Format (?) (Code Review)
- [ ] Improve generation time (not sure if still relevant after model change?)
- [ ] Bild als multipart übergeben, nicht als base64

### Database
- [ ] Bild in der Db speichern (summary auch?)
- [ ] Direkte Neugenerierung möglich (?)
- [ ] "Reset search"- / "Close"-button oben fixieren (sonst zu lange scrollen, um Fenster schließen zu können)

### Etc
- [ ] Keys in protected Enviornment
- [ ] Vllt. message bei long loading-screens
- [ ] Structured Jason (Code review)
- [ ] Anzeige von Bild (momentan einf mit Summary unter Winecard, vllt eigenes Fenster oder so? und vllt größer)
- [ ] Merge ai-functions (descriptions+summary+image in one go; maybe faster, definitly avoids fetching descriprions twice (Alternative zur Parameterübergabe)) (?)
- [ ] Use Writer/Reviewer für Farbselektion (?)

