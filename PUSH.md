# Hochladen zu GitHub

Das Repository ist hier fertig vorbereitet: Erstcommit, Build-55-Commit,
Branch `main`, Remote `https://github.com/EhabYT/EB_Optimizer.git`.
Was fehlt, ist die Anmeldung — die kann ich von hier aus nicht leisten.

## Weg A — ZIP herunterladen und pushen (empfohlen)

1. `EB_Optimizer_repo.zip` aus dem Arbeitsbereich herunterladen und entpacken.
   Die komplette Git-Historie ist enthalten, Remote und Branch sind gesetzt.
2. In den entpackten Ordner wechseln und pushen:

```
cd EB_Optimizer
git push -u origin main
```

Beim ersten Mal fragt Windows nach der Anmeldung (Browser-Fenster von
Git Credential Manager). Falls stattdessen nach Benutzername und Kennwort
gefragt wird: Benutzername = `EhabYT`, Kennwort = ein **Personal Access Token**
(github.com → Settings → Developer settings → Personal access tokens →
Fine-grained → Repository `EB_Optimizer`, Berechtigung
*Contents: Read and write*). Das normale GitHub-Kennwort wird nicht akzeptiert.

## Weg B — du hast den Ordner schon lokal

```
git init
git add .
git commit -m "EB_Optimizer v13.5"
git branch -M main
git remote add origin https://github.com/EhabYT/EB_Optimizer.git
git push -u origin main
```

**Vorher** eine Datei `.gitattributes` mit dieser Zeile anlegen:

```
*.cmd -text diff
```

Ohne sie wandelt Git die Zeilenenden der `.cmd` um und der Starter ist kaputt.

## Wenn der Push abgewiesen wird

Wurde das Repository auf GitHub mit README oder Lizenz angelegt, ist es nicht
leer:

```
git pull --rebase origin main
git push -u origin main
```

## Zwei Dinge, die die Datei zerstören

* **Nicht über die GitHub-Weboberfläche bearbeiten.** Der Editor speichert LF
  und oft UTF-8 mit BOM — danach startet die `.cmd` nicht mehr.
* **Keine Zeilenenden-Umwandlung.** Geprüft: mit der `.gitattributes` kommt die
  Datei aus einem Klon byte-identisch zurück, auch bei `core.autocrlf=true`.

## Stand

| Commit | Inhalt |
| --- | --- |
| `2ce85ad` | EB_Optimizer v13.5 — Einzeldatei-Start (Batch + PowerShell) |
| `9acd368` | Build 55 — Reparatur-Center |
