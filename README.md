# EB_Optimizer

Windows-Performance-Suite als **eine einzige Datei**: `EB_Optimizer_v13.5.cmd`.

Doppelklick genügt. Keine Installation, keine `.ps1` daneben, keine Signatur,
keine Änderung der ExecutionPolicy — auch nicht unter `AllSigned`.

## Wie das geht

Die Datei ist ein Batch-Starter mit angehängter PowerShell-Nutzlast. Der Starter
liest sich selbst ein und führt den Teil hinter der Marke `#__EB_PAYLOAD__` über
`Invoke-Expression` aus. Damit wird **keine Skriptdatei geladen** — die
ExecutionPolicy greift an dieser Stelle nicht. Fehlende Administratorrechte holt
der Starter selbst über eine Abfrage nach.

## Ablauf beim Start

```mermaid
flowchart TD
    A([Doppelklick auf EB_Optimizer_v13.5.cmd]) --> B[Batch-Kopf: Farben, Banner,<br/>eigener Pfad in EB_SELF]
    B --> C{Administrator?}
    C -- nein --> D[Selbst neu starten<br/>mit Rechteabfrage]
    D --> C
    C -- ja --> E[Datei liest sich selbst ein:<br/>alles hinter der Marke EB_PAYLOAD]
    E --> F[Invoke-Expression:<br/>kein Skript auf der Platte,<br/>keine ExecutionPolicy, keine Signatur]
    F --> G[Einstellungen laden<br/>Altdaten übernehmen]
    G --> H[Sprache setzen<br/>DE / EN / TR / AR]
    H --> I{Läuft schon<br/>eine Instanz?}
    I -- ja --> J([Vorhandenes Fenster<br/>in den Vordergrund])
    I -- nein --> K([Hauptfenster: Seitenleiste,<br/>Ansicht, Protokoll])
```

## Wie eine Aktion abläuft

Jeder Eingriff folgt demselben Muster — das ist der Grund, warum das Fenster
nicht einfriert und warum sich alles zurücknehmen lässt.

```mermaid
flowchart TD
    A([Klick auf eine Karte]) --> B[Messen:<br/>Ist-Zustand lesen]
    B --> C{Etwas zu tun?}
    C -- nein --> D([Hinweis ins Protokoll:<br/>steht schon so])
    C -- ja --> E[Rückfrage mit Zahlen:<br/>was, wie viel, welches Risiko]
    E -- abgelehnt --> F([Nichts passiert])
    E -- bestätigt --> G[Wartefläche an<br/>Fortschritt + Abbrechen]
    G --> H{Dauert der Befehl<br/>lange?}
    H -- ja --> I[Eigener Hintergrundlauf<br/>mit Zeitlimit]
    H -- nein --> J[Direkt ausführen,<br/>Schleifen reichen<br/>Fenster-Nachrichten durch]
    I --> K[Nachlesen:<br/>Zustand erneut messen]
    J --> K
    K --> L{Wirklich<br/>geändert?}
    L -- nein --> M([Fehler melden —<br/>kein Journaleintrag])
    L -- ja --> N[Eintrag ins Änderungsjournal]
    N --> O([Bilanz: x von y erledigt])
    O -.-> P[Änderungsjournal:<br/>einzeln oder alles rückgängig]
```

## Aufbau des Programms

```mermaid
flowchart LR
    subgraph UI[Oberfläche]
        V1[21 Ansichten<br/>Übersicht, Tweaks, Defender,<br/>Dienste, Journal, …]
        V2[Wartefläche<br/>Fortschritt + Abbruch]
        V3[Protokoll + Hinweise]
    end
    subgraph M[Modell - reine Funktionen]
        M1[Get-*Rows<br/>Listen ohne Fenster]
        M2[Get-*Plan<br/>Entscheidungen]
        M3[Get-*Result<br/>Urteile]
    end
    subgraph W[Arbeit abseits der Oberfläche]
        W1[Hintergrundladung<br/>mit Zwischenspeicher]
        W2[Hintergrundlauf<br/>mit Zeitlimit]
    end
    subgraph S[System]
        S1[Registrierung]
        S2[Dienste & Aufgaben]
        S3[Dateien & Datenträger]
        S4[Defender, Netzwerk, Updates]
    end
    V1 --> M1 & M2
    V1 --> W1
    V1 --> W2
    W1 --> S1 & S2 & S3 & S4
    W2 --> S1 & S2 & S3 & S4
    W2 --> M3
    M3 --> V3
    W1 --> M1
    V2 -. "hält die Oberfläche am Leben" .-> W2
    S1 & S2 & S3 & S4 --> J[(Änderungsjournal<br/>changes.jsonl)]
    J -. "Rücknahme" .-> S1 & S2 & S3 & S4
```

## Funktionen

| Bereich | Inhalt |
| --- | --- |
| Übersicht | Systemwerte, Gesundheitsbewertung, Schnellaktionen |
| Aufräumen | 9 Ziele (Temp, Logs, Miniaturansichten, Browser, Windows-Update …) mit Messung vor dem Löschen |
| Tweaks | 12 Karten: Dienste, Debloat, Core-Parking, Netzwerk, Eingabe |
| Defender | Ausnahmen anlegen, prüfen, entfernen — mit Rücknahme |
| Dienste · Autostart · Aufgaben · Prozesse | Listen mit Filter, Sortierung, Schutzlisten |
| Datenträger · Netzwerk · Updates | Analyse, DNS-Profile, Update-Pause (1–35 Tage) |
| Registrierung | 4 Aufräumkarten, jede sichert vorher nach `.reg` |
| Änderungsjournal | jeder Eingriff wird aufgezeichnet und lässt sich einzeln zurücknehmen |
| Reparatur | SFC, DISM, CHKDSK, Wiederherstellungspunkte |
| Benchmark | CPU, RAM, Datenträger mit Vergleich zum letzten Lauf |

Oberfläche in **Deutsch, Englisch, Türkisch und Arabisch** (inklusive
Rechts-nach-links-Darstellung).

## Grundsätze im Code

* **Messen → fragen → ausführen → nachlesen → aufzeichnen.** Nichts
  Zerstörendes ohne Rückfrage, nichts gilt als erledigt ohne erneutes Prüfen.
* **Nichts Langsames im Oberflächenstrang.** Lange Aufrufe laufen in einem
  Hintergrundlauf mit Zeitlimit, Fortschritt und Abbruch; lange Schleifen
  reichen Fenster-Nachrichten durch.
* **Modell und Darstellung getrennt.** Listen entstehen aus reinen Funktionen
  (`Get-*Rows`), die sich ohne Fenster prüfen lassen.

## Dateien

```
EB_Optimizer_v13.5.cmd   Das Programm. Mehr wird nicht gebraucht.
.gitattributes           Schützt die Zeilenenden der .cmd vor Git.
```

## Wichtig beim Klonen

`*.cmd` ist in `.gitattributes` von der Zeilenenden-Umwandlung ausgenommen.
Wird die Datei über die GitHub-Weboberfläche bearbeitet oder mit einem Editor
gespeichert, der UTF-8 **mit** BOM schreibt, startet sie nicht mehr.

## Einstellungen

`%APPDATA%\EB_Optimizer\settings.json` · Sicherungen in
`Dokumente\EB_Optimizer_Backups`. Daten einer früheren Version
(`EB_EHAB_Optimizer`) werden beim ersten Start übernommen.

## Systemvoraussetzungen

Windows 10 (Build 10586) oder neuer, Windows PowerShell 5.1 (in Windows
enthalten), Administratorrechte.
