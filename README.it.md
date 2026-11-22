# Strumenti Go per RenkuOS

[English](README.md) · Italiano · [日本語](README.ja.md) · [한국어](README.ko.md)

rclone, Syncthing, la CLI di GitHub, restic, Hugo, Caddy, fzf e lazygit,
compilati per RenkuOS (Haiku) su arm64, x86_64 e x86 a 32 bit. Build non
ufficiali, non affiliate a nessuno di questi progetti né a GitHub.

| Strumento | Versione | Pacchetto | Pacchetto su x86 a 32 bit |
| --- | --- | --- | --- |
| rclone | 1.76.0 | `rclone` | `rclone_x86` |
| Syncthing | 1.30.0 | `syncthing` | `syncthing_x86` |
| GitHub CLI (`gh`) | 2.100.0 | `github_cli` | `github_cli_x86` |
| restic | 0.19.1 | `restic` | `restic_x86` |
| Hugo | 0.165.0 | `hugo` | `hugo_x86` |
| Caddy | 2.11.9 | `caddy` | `caddy_x86` |
| fzf | 0.75.0 | `fzf` | `fzf_x86` |
| lazygit | 0.66.3 | `lazygit` | `lazygit_x86` |

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
`syncthing`, `gh`, `restic`, `hugo`, `caddy`, `fzf` o `lazygit`.

## Installazione da un file di pacchetto

Senza il repository, con un `.hpkg` prodotto da `package.sh`:

```sh
pkgman install ./rclone-1.76.0-2-arm64.hpkg
```

Revisioni dei pacchetti: su arm64 `rclone`, `syncthing` e `github_cli`
sono alla revisione 2 e gli altri alla revisione 1; su x86 a 32 bit
`rclone_x86`, `syncthing_x86` e `github_cli_x86` sono alla revisione 2 e
gli altri alla 1; su x86_64 sono tutti alla revisione 1. I pacchetti arm64
sono compilati con la toolchain Go di golang_bin revisione 10, che
consegna i segnali.

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

## restic

```sh
restic init --repo ~/restic-repo
restic -r ~/restic-repo backup ~/Documents
restic -r ~/restic-repo snapshots
restic -r ~/restic-repo restore latest --target ~/restored
```

I backup su una directory locale, SFTP, un server REST, S3 e gli altri
backend funzionano come nel restic originale. Non disponibili: `restic mount`
(niente FUSE) e `restic self-update`. Gli attributi estesi non vengono salvati.

## Hugo

```sh
hugo new site mysite
cd mysite
hugo server                  # poi apri http://127.0.0.1:1313
hugo                         # compila in public/
```

È l'edizione standard. Il compilatore Sass e l'encoder WebP dell'edizione
extended richiedono cgo, quindi i temi che vogliono "Hugo extended" non si
compilano. `hugo server` rileva le modifiche e ricompila mentre è in
esecuzione.

## Caddy

```sh
caddy file-server --root ~/public_html --listen 127.0.0.1:8080
caddy run --config Caddyfile
caddy reload --config Caddyfile
caddy stop
```

I moduli standard (file server, reverse proxy, HTTPS automatico, Caddyfile).
L'endpoint di amministrazione ascolta su `127.0.0.1:2019` invece di
`localhost:2019`. Su x86_64 e x86 a 32 bit i programmi Go non sanno ancora
risolvere `localhost`, perché Haiku non ha `/etc/hosts`: lì scrivi
`127.0.0.1` invece di `localhost`, come in `reverse_proxy 127.0.0.1:3000`.
La build arm64 legge il file hosts di Haiku, quindi lì `localhost`
funziona.

## fzf

```sh
ls /boot/system/bin | fzf
fzf --filter=term < list.txt   # non interattivo
```

## lazygit

```sh
cd my-repository
lazygit
```

lazygit richiede `git` 2.32 o successivo. Su x86_64 e x86 a 32 bit Haiku ce
l'ha (`pkgman install git`, oppure `git_x86` su x86 a 32 bit); il repository
RenkuOS arm64 non ha ancora git, quindi lì lazygit si avvia solo quanto basta
per dirlo.

## Fermare un comando in esecuzione

Ctrl-C e `kill` fermano `syncthing`, `rclone serve`, `hugo server`,
`caddy file-server` e gli altri su tutti e tre i sistemi. Su arm64 servono
i pacchetti compilati con la toolchain corretta (vedi le revisioni sopra):
le build arm64 precedenti ignoravano entrambi e si fermavano solo con
`kill -9`.

## Disinstallazione

```sh
pkgman uninstall rclone      # oppure syncthing, github_cli, restic, hugo, caddy,
                             # fzf, lazygit; con _x86 su x86 a 32 bit
```

## Compilazione

`build.sh` compila uno strumento in cross-compilazione su una workstation e
`package.sh` crea il pacchetto. Le patch e le toolchain Go necessarie sono
descritte in [docs/PORTING.md](docs/PORTING.md) (in inglese).

## Uso dell'IA

Parti di questo port sono state sviluppate con l'aiuto di strumenti di programmazione basati sull'IA (Claude di Anthropic). Tutto il codice è stato rivisto e testato dall'autore.
