# Lern-Apps (Leistung und Motor): Einrichtung mit Klassenwertung und QR-Prüfung

Das Projekt enthält die **Lernlandkarte** (`nut.html`, Selbsteinschätzung zu allen 26 Kompetenzen des NuT-Lehrplans, braucht weder Datenbank noch Schlüssel) und zwanzig Lern-Apps: **Leistung** (`index.html`), **Motor: Elektromotor und Generator** (`motor.html`) und **7_4 Bewegungen erkunden** (`7_4_Bewegungen_erkunden.html`) **7_1 Naturwissenschaften erkunden** (`7_1_Naturwissenschaften_erkunden.html`), **7_5 Energie erkunden** (`7_5_Energie_erkunden.html`), **7_7 Chemische Reaktionen untersuchen** (`7_7_Chemische_Reaktionen_untersuchen.html`) **8_1 Stromkreise untersuchen** (`8_1_Stromkreise_untersuchen.html`) , **7_3 Reize und Sinne untersuchen** (`7_3_Reize_und_Sinne_untersuchen.html`), **8_5 Kräfte, Arbeit und Leistung erforschen** (`8_5_Kraefte_Arbeit_und_Leistung_erforschen.html`), **8_2 Gewässer-Ökosysteme erforschen** (`8_2_Gewaesser_Oekosysteme_erforschen.html`) und **8_3 Funktionen des Körpers analysieren** (`8_3_Funktionen_des_Koerpers_analysieren.html`). Die Lern-Apps (pro NaTech-Kapitel eine App) teilen sich Datenbank, `config.js` und Prüf-App. Die Punkte der Apps bleiben getrennt.

Du brauchst nur dein GitHub-Konto. Kosten: 0 CHF. Zeitbedarf: etwa 45 Minuten für Teil 1 bis 3, danach 10 Minuten für Teil 4.
Die Menünamen bei GitHub und Supabase ändern sich gelegentlich. Wenn etwas anders heisst, such nach dem fettgedruckten Stichwort.
Die Klassenwertung (Teil 1 und 2) und die QR-Prüfung (Teil 4) sind unabhängig voneinander. Du kannst auch nur eins davon einrichten.

## Teil 1: Datenbank bei Supabase

1. Öffne **supabase.com** und melde dich mit **GitHub** an.
2. Lege ein neues Projekt an (Name zum Beispiel `leistung-app`). Notiere das Datenbank-Passwort. Wähle eine **europäische Region**.
3. Schalte die anonyme Anmeldung ein: **Authentication**, dann **Sign In / Providers** (oder «Sign In / Up»), dort **Allow anonymous sign-ins** aktivieren. So braucht kein Schüler ein Konto.
4. Öffne den **SQL Editor**, wähle **New query**, kopiere den ganzen Inhalt von `supabase_setup.sql` hinein und klicke **Run**. Es sollte «Success» erscheinen. Das Skript gilt für beide Apps. Hast du eine ältere Version des Skripts schon ausgeführt, lösche vorher die Tabellen `players` und `challenge_results` im **Table Editor**.
5. Öffne **Project Settings**, dann **API** (oder «API Keys»). Kopiere zwei Werte:
   - **Project URL**
   - den öffentlichen Schlüssel (**anon** bzw. **publishable key**)

   Verwende niemals den Schlüssel `service_role` oder `secret`. Der darf nirgends in der App stehen.

## Teil 2: Webseite bei GitHub

1. Entpacke das ZIP auf deinem Computer.
2. Auf **github.com**: **New repository**, Name `leistung-lernapp`, Sichtbarkeit **Public**, erstellen.
3. Klicke **uploading an existing file** und ziehe alle Dateien und Ordner aus dem entpackten Ordner hinein (`index.html`, `motor.html`, `7_4_Bewegungen_erkunden.html`, `7_1_Naturwissenschaften_erkunden.html`, `7_5_Energie_erkunden.html`, `7_7_Chemische_Reaktionen_untersuchen.html`, `8_1_Stromkreise_untersuchen.html`, `7_3_Reize_und_Sinne_untersuchen.html`, `8_5_Kraefte_Arbeit_und_Leistung_erforschen.html`, `nut.html`, `pruefen.html`, `config.js`, `logo.png`, Ordner `fonts` und `vendor`). Dann **Commit changes**.
4. Öffne `config.js`, klicke auf den Stift und trage Project URL und Schlüssel zwischen die Anführungszeichen ein. **Commit changes**.
5. **Settings**, dann **Pages**: Quelle **Deploy from a branch**, Branch `main`, Ordner `/ (root)`, **Save**. Nach ein bis zwei Minuten steht oben die Adresse, ungefähr `https://DEINNAME.github.io/leistung-lernapp/`.
6. Öffne die Adresse auf deinem Handy. Es sollte die Karte «Meine Klasse» erscheinen. Die Motor-App liegt unter `https://DEINNAME.github.io/leistung-lernapp/motor.html`.

## Teil 3: Im Unterricht

- **Klassencode:** Pro Klasse ein Code (derselbe Code gilt in beiden Apps; die Ranglisten sind pro App getrennt) mit mindestens 3 Zeichen aus Buchstaben, Ziffern und Bindestrich, zum Beispiel `9B-NUT`. Alle in der Klasse tragen denselben Code ein. Wer einen anderen Code hat, sieht eine andere Klasse.
- **Challenge:** Schreib einen Code an die Tafel, zum Beispiel `3-LEISTUNG`. Die Ziffer begrenzt die Fragen auf die Stationen 1 bis 3. Alle bekommen dieselben 6 Fragen. Die Rangliste erscheint, wenn die Schüler zusätzlich einer Klasse beigetreten sind.
- **Wertung:** Wochenwertung von Montag bis Sonntag. Schüler sehen die Top 5 und ihren eigenen Platz. Das Klassenziel stellst du in `config.js` ein (`weeklyGoalPerPlayer`).
- **Alle Daten ansehen:** Supabase, dann **Table Editor**, Tabellen `players` und `challenge_results`.
- **Daten löschen:** Schüler können in der App «Klasse verlassen» oder «Fortschritt zurücksetzen» wählen. Dabei werden ihre Zeilen gelöscht. Alles löschen am Ende des Schuljahres: im SQL Editor `delete from public.players; delete from public.challenge_results;`

## Teil 4: Lernstand per QR-Code prüfen (ohne Server)

So funktioniert es: Die Schüler-App verschlüsselt den Lernstand mit deinem **öffentlichen** Schlüssel in einen QR-Code. Nur deine Prüf-App (`pruefen.html`) besitzt den dazu passenden **privaten** Schlüssel und kann den Code öffnen. Es wird nichts hochgeladen.

1. Öffne `pruefen.html` auf dem Gerät, mit dem du später scannen willst (Adresse: `https://DEINNAME.github.io/leistung-lernapp/pruefen.html`).
2. Klicke **Schlüssel erzeugen**. Kopiere den **öffentlichen Schlüssel**.
3. Öffne auf GitHub `config.js`, klicke auf den Stift, füge den Schlüssel bei `teacherKey` zwischen die Anführungszeichen ein und klicke **Commit changes**. Nach ein bis zwei Minuten ist er in der App aktiv.
4. Mache direkt eine **Sicherung** (Passwort mit mindestens 8 Zeichen, dann «Sicherung speichern»). Bewahre Datei und Passwort getrennt auf.
5. Die Schüler finden auf dem Lernpfad die Karte **Mein Lernstand**. Sie können freiwillig ihren Namen eintragen (steht nur im verschlüsselten Code) und tippen **QR-Code anzeigen**.
6. In der Prüf-App klickst du **Kamera starten** und hältst sie auf den Code. Das Ergebnis erscheint sofort und landet in der Liste. Die Liste kannst du als CSV speichern (öffnet sich in Excel).

Was die Prüf-App meldet:
- **Plausibel:** Alle Werte passen zusammen.
- **Auffällig:** Etwas passt nicht, zum Beispiel mehr Punkte, als mit den gespielten Runden möglich sind, oder eine Station, die noch gesperrt war.
- **Ungültig:** Der Code wurde verändert oder gehört zu einem anderen Schlüssel.
- **Abgelaufen:** Ein Code gilt nur 10 Minuten.
- **Schon gescannt:** Jeder Code zählt nur einmal.

Wichtig zu wissen:
- **Grenze der Prüfung:** Die Verschlüsselung schützt den Inhalt vor Mitlesen. Sie beweist aber nicht, dass die Schüler ihre Punkte ehrlich verdient haben. Die App läuft auf dem Gerät der Schüler, und wer sich auskennt, kann dort Werte ändern. Die Plausibilitätsprüfung erkennt die typischen Manipulationen, aber nicht jede geschickte. Verwende den Lernstand nicht als alleinige Grundlage für Noten.
- **Schlüssel:** Der private Schlüssel liegt nur in dem Browser, in dem du ihn erzeugt hast. Löschst du dessen Daten, brauchst du die Sicherung. Erzeugst du einen neuen Schlüssel, musst du `config.js` anpassen, und alte Codes sind nicht mehr lesbar.
- **Kamera:** Die Kamera braucht eine sichere Verbindung (https) und deine Erlaubnis im Browser. GitHub Pages erfüllt das. Falls die Kamera nicht geht, kannst du den Code als Text einfügen.
- **Uhrzeit:** Die Geräte der Schüler müssen ungefähr die richtige Uhrzeit haben, sonst meldet die Prüf-App «Abgelaufen» oder «Uhrzeit prüfen».
- **Datenschutz:** Die Liste mit Namen liegt in deinem Browser. Leere sie, wenn du sie nicht mehr brauchst.

## Wichtig zu wissen (Klassenwertung)

- **Pause nach Ferien:** Kostenlose Supabase-Projekte werden nach einer Woche ohne Aktivität pausiert. Öffne nach den Ferien vorher das Dashboard und klicke **Restore**.
- **Anmelde-Limit:** Anonyme Anmeldungen sind pro IP-Adresse begrenzt (30 pro Stunde). Im Schulnetz teilen sich viele Geräte oft eine Adresse. Lass nicht mehrere Klassen gleichzeitig zum ersten Mal beitreten. Die Anmeldung passiert nur einmal pro Gerät.
- **Schummeln:** Der Server weist unplausible Punktestände ab (höchstens etwa 3 XP pro Sekunde). Wer technisch versiert ist, kann trotzdem tricksen. Nutze die Rangliste nicht für Noten.
- **Schütze dein GitHub-Konto** mit Zwei-Faktor-Anmeldung. Es gibt Zugriff auf dein Supabase-Projekt.
- **Gespeichert wird (Klassenwertung):** Zufallsname, Klassencode, Punktestand, Challenge-Ergebnisse. Keine Klarnamen. Schriften und Bibliotheken liegen im Projekt, die App ruft keine Google-Server auf.
- **Ohne Backend** funktioniert die App weiter, nur ohne Klassenwertung. Das passiert, wenn `config.js` leer ist.


## Trophäen

Jede Lern-App hat 17 Trophäen zum Freischalten (zum Beispiel «Erster Schritt», «Volltreffer», «Sternenhimmel», «Dranbleiber»). Sie werden nur auf dem Gerät gespeichert und erscheinen auf der Startseite unter «Trophäen».


## Schulinterne Wertung und Klassenduell

Zusätzlich zur Klassenwertung gibt es zwei Ansichten. Beide erscheinen in der Klassenkarte als Reiter «Schule» und «Klassenduell», sobald die Klasse beigetreten ist.

- **Schule:** Rangliste aller Lernenden der Schule in der laufenden Woche (Top 10 und der eigene Platz). Gezeigt werden nur Zufallsnamen und der Klassencode. Es gibt keine öffentliche Wertung über die Schule hinaus.
- **Klassenduell:** Vergleich von Klassen und Gruppen nach Wochenpunkten pro Person. So haben grosse und kleine Gruppen die gleiche Chance. Wenn du zwei bis acht Klassencodes eingibst (zum Beispiel `KL-7A, KL-7B`), treten genau diese gegeneinander an. Bei leerem Feld werden alle Klassen der Schule verglichen. Gruppen innerhalb einer Klasse sind einfach eigene Codes (zum Beispiel `KL-7A-ROT`).
- **Challenge-Duell:** Spielen mehrere Klassen denselben Challenge-Code, erscheint nach der Challenge der Vergleich der Klassen (Durchschnitt der richtigen Antworten und der Zeit pro Person).

### Einrichten

1. Führe das aktuelle `supabase_setup.sql` im SQL Editor von Supabase noch einmal aus. Das Skript darf mehrmals ausgeführt werden. Es ergänzt die Datenbank um den Schulcode und die drei neuen Funktionen, bestehende Daten bleiben erhalten.
2. Trage in `config.js` den `schoolCode` ein (vorbelegt mit `HALINGEN`, mindestens 3 Zeichen, nur Grossbuchstaben, Ziffern und Bindestrich). Bleibt der Wert leer, gibt es keine Schulwertung und kein Klassenduell.
3. Die Wertung gilt pro App. Eine Klasse sieht also die Schulwertung der Lern-App, die sie gerade benutzt.

### Wichtig zu wissen

- Der Schulcode ist kein Geheimnis. Er trennt die Wertungen verschiedener Schulen, schützt aber nichts. Sichtbar sind ohnehin nur Zufallsnamen, Klassencodes und Punkte.
- Wähle Klassencodes ohne Hinweise auf Personen (zum Beispiel `KL-7A` statt Namen).
- Wer früher schon einer Klasse beigetreten war, erscheint in der Schulwertung nach der nächsten Runde (dann wird der Schulcode mitgesendet).
- Klassen mit weniger als drei Personen werden im Duell als «wenige Teilnehmende» markiert, weil ihr Durchschnitt wenig aussagt.
- Die Wertung lässt sich technisch nicht fälschungssicher machen. Wer die App verändert, kann sich Punkte geben. Das SQL begrenzt die Punkte pro Zeit, mehr nicht.
- Gespeichert werden Zufallsname, Klassencode, Schulcode, Punkte und Challenge-Ergebnisse. Keine Klarnamen.


## Startseite mit allen Kapiteln

`lernapp.html` ist die gemeinsame Startseite. Sie zeigt alle Kapitel gruppiert (Kapitel 7, 8, 9 und Vertiefungen). Pro Kapitel siehst du Punkte, Stufe und bestandene Stationen. Tippe ein Kapitel an, dann erscheinen seine Stationen als Unterkapitel. Mit einer Station startest du direkt in der Lektion. Kapitel, für die es noch keine Lern-App gibt, erscheinen als «In Planung».

- Die Startseite liest den Fortschritt der einzelnen Kapitel-Apps aus dem Browser. Das funktioniert nur, wenn alle Seiten vom selben Ort kommen, zum Beispiel von GitHub Pages. Aus einzelnen heruntergeladenen Dateien funktioniert es nicht.
- Sie zeigt zusätzlich acht Gesamt-Trophäen, die über alle Kapitel zählen (zum Beispiel «Tausender» oder «Kapitel geschafft»).
- Die Klassen- und Schulwertung bleibt pro Kapitel. Eine gemeinsame Wertung über alle Kapitel gibt es noch nicht.
- Jede Kapitel-App hat in der Fusszeile den Link «Alle Kapitel».
- Neue Kapitel erscheinen automatisch, sobald sie im Projekt gebaut sind.


## Kapitel 9 (nach den Themenbüchern)

Für NaTech 9 (9_1 bis 9_8) lagen keine Lehrerkommentare vor. Diese acht Apps sind nach den Themenbüchern gebaut: `9_1_Optische_Phaenomene_erkunden.html`, `9_2_Atommodelle_nutzen.html`, `9_3_Elektronische_Schaltungen_untersuchen.html`, `9_4_Energie_und_Leistung_erfassen.html`, `9_5_Genetik_und_Gentechnik_verstehen.html`, `9_6_Evolution_nachvollziehen.html`, `9_7_Land_Oekosysteme_erforschen.html`, `9_8_Stoffkreislaeufe_erkunden.html`. Die Aufgaben sind eigene Formulierungen. Bitte prüfe sie fachlich, besonders die Modell-Experimente mit Beispielwerten.

## Noch nicht enthalten

- 7_2 und 7_6: Die Lehrerkommentare liegen nur als Scan vor.
