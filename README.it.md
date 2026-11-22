# Strumenti Go per RenkuOS

[English](README.md) · Italiano · [日本語](README.ja.md) · [한국어](README.ko.md)

rclone, Syncthing e la CLI di GitHub, compilati per RenkuOS (Haiku) su arm64,
x86_64 e x86 a 32 bit. Build non ufficiali, non affiliate al progetto rclone,
alla Syncthing Foundation o a GitHub.

| Strumento | Versione | Pacchetto | Pacchetto su x86 a 32 bit |
| --- | --- | --- | --- |
| rclone | 1.76.0 | `rclone` | `rclone_x86` |
| Syncthing | 1.30.0 | `syncthing` | `syncthing_x86` |
| GitHub CLI (`gh`) | 2.100.0 | `github_cli` | `github_cli_x86` |

## Installazione con pkgman

Aggiungi il repository una volta, poi installa quello che ti serve.

| Sistema | Repository | Esempio |
| --- | --- | --- |
| arm64 | `pkgman add-repo http://pkgman.rainygirl.com/arm64` | `pkgman install rclone` |
| x86_64 | `pkgman add-repo https://pkgman.rainygirl.com/x86_64` | `pkgman install rclone` |
| x86 a 32 bit (x86_gcc2) | `pkgman add-repo https://pkgman.rainygirl.com/x86_gcc2` | `pkgman install rclone_x86` |

Se `pkgman add-repo` fallisce con `Operation not supported`, il network kit di
quell'immagine non ha TLS: nell'indirizzo usa `http://` al posto di `https://`.

Ogni pacchetto installa un comando in `/boot/system/bin`: `rclone`,
`syncthing` o `gh`.

## Installazione da un file di pacchetto

Senza il repository, con un `.hpkg` prodotto da `package.sh`:

```sh
pkgman install ./rclone-1.76.0-1-arm64.hpkg
```

## rclone

```sh
rclone config                # configura un remote
rclone copy ~/Documents remote:backup
```

`rclone mount` non è disponibile: Haiku non ha un FUSE utilizzabile dai
binding Go. Tutto il resto è rclone così com'è. In Terminal il file di
configurazione è `~/config/settings/rclone/rclone.conf`.

## Syncthing

```sh
syncthing                    # poi apri http://127.0.0.1:8384
```

- È la serie 1.x. Syncthing 2.x tiene il database in SQLite tramite una
  libreria che non ha un port per Haiku.
- Su Haiku non c'è un file watcher, quindi una cartella viene aggiornata
  quando viene riscansionata. L'intervallo predefinito è un'ora: abbassa
  *Full Rescan Interval* nelle impostazioni della cartella se ti serve che le
  modifiche partano prima.
- Gli aggiornamenti automatici sono disattivati; una nuova versione arriva
  come nuovo pacchetto.
- Il pacchetto non avvia Syncthing all'accesso.

## GitHub CLI

```sh
gh auth login
```

`gh` apre le pagine web con il comando `open` di Haiku. La 2.100.0 è la
versione più recente che la toolchain a 32 bit riesce a compilare; i tre
sistemi ricevono la stessa versione.

## Su arm64: fermare un comando in esecuzione

Su RenkuOS arm64 un programma Go non reagisce ancora a Ctrl-C né a `kill` (lì
il runtime di Go non consegna i segnali), quindi `syncthing` o `rclone serve`
restano in esecuzione. Arresta Syncthing dalla sua pagina web (Actions ->
Shutdown); ferma tutto il resto con `kill -9 <team id>` o da
ProcessController. x86_64 e x86 a 32 bit non hanno questo problema.

## Disinstallazione

```sh
pkgman uninstall rclone      # oppure syncthing, github_cli; con _x86 su x86 a 32 bit
```

## Compilazione

`build.sh` compila uno strumento in cross-compilazione su una workstation e
`package.sh` crea il pacchetto. Le patch e le toolchain Go necessarie sono
descritte in [docs/PORTING.md](docs/PORTING.md) (in inglese).

## Uso dell'IA

Parti di questo port sono state sviluppate con l'aiuto di strumenti di programmazione basati sull'IA (Claude di Anthropic). Tutto il codice è stato rivisto e testato dall'autore.
