# RenkuOS용 Go 도구

[English](README.md) · [Italiano](README.it.md) · [日本語](README.ja.md) · 한국어

rclone, Syncthing, GitHub CLI, restic, Hugo, Caddy, fzf, lazygit을
RenkuOS(Haiku)의 arm64, x86_64, 32비트 x86용으로 빌드한 것입니다. 비공식
빌드이며 각 프로젝트나 GitHub와는 관련이 없습니다.

| 도구 | 버전 | 패키지 | 32비트 x86 패키지 |
| --- | --- | --- | --- |
| rclone | 1.76.0 | `rclone` | `rclone_x86` |
| Syncthing | 1.30.0 | `syncthing` | `syncthing_x86` |
| GitHub CLI (`gh`) | 2.100.0 | `github_cli` | `github_cli_x86` |
| restic | 0.19.1 | `restic` | `restic_x86` |
| Hugo | 0.165.0 | `hugo` | `hugo_x86` |
| Caddy | 2.11.9 | `caddy` | `caddy_x86` |
| fzf | 0.75.0 | `fzf` | `fzf_x86` |
| lazygit | 0.66.3 | `lazygit` | `lazygit_x86` |

## pkgman으로 설치

저장소를 한 번 추가한 뒤 필요한 것을 설치합니다.

| 시스템 | 저장소 | 예 |
| --- | --- | --- |
| arm64 | `pkgman add-repo http://pkgman.rainygirl.com/arm64` | `pkgman install rclone` |
| x86_64 | `pkgman add-repo https://pkgman.rainygirl.com/x86_64` | `pkgman install rclone` |
| 32비트 x86 (x86_gcc2) | `pkgman add-repo https://pkgman.rainygirl.com/x86_gcc2` | `pkgman install rclone_x86` |

`pkgman add-repo`가 `Operation not supported`로 실패하면 그 이미지의 네트워크
키트에 TLS가 없는 것입니다. 주소의 `https://`를 `http://`로 바꿔 쓰세요.

각 패키지는 `/boot/system/bin`에 명령 하나를 설치합니다(`rclone`,
`syncthing`, `gh`, `restic`, `hugo`, `caddy`, `fzf`, `lazygit`).

## 패키지 파일로 설치

저장소 없이 `package.sh`로 만든 `.hpkg`를 쓰는 경우:

```sh
pkgman install ./rclone-1.76.0-2-arm64.hpkg
```

패키지 리비전: arm64에서는 `rclone`, `syncthing`, `github_cli`가 리비전
2이고 나머지는 리비전 1입니다. 32비트 x86에서는 `rclone_x86`,
`syncthing_x86`, `github_cli_x86`가 리비전 2이고 나머지는 리비전 1이며,
x86_64는 모두 리비전 1입니다. arm64 패키지는 시그널을 전달하는
golang_bin 리비전 10의 Go 툴체인으로 빌드했습니다.

## rclone

```sh
rclone config                # 리모트 설정
rclone copy ~/Documents remote:backup
```

`rclone mount`는 쓸 수 없습니다. Haiku에는 Go 바인딩이 쓸 수 있는 FUSE가
없습니다. 나머지는 원래의 rclone 그대로입니다. Terminal에서 설정 파일은
`~/config/settings/rclone/rclone.conf`입니다.

## Syncthing

```sh
syncthing                    # 그다음 http://127.0.0.1:8384 를 엽니다
```

- 1.x 계열입니다. Syncthing 2.x는 데이터베이스로 SQLite를 쓰는데, 그 라이브러리가
  Haiku로 포팅되어 있지 않습니다.
- Haiku용 파일 감시 기능이 없어서 폴더의 변경은 다시 스캔할 때 반영됩니다.
  기본 간격은 1시간입니다. 변경을 더 빨리 보내려면 폴더 설정의
  *Full Rescan Interval*을 줄이세요.
- 자동 업그레이드는 꺼져 있습니다. 새 버전은 새 패키지로 제공됩니다.
- 이 패키지는 로그인할 때 Syncthing을 시작하지 않습니다.

## GitHub CLI

```sh
gh auth login
```

`gh`는 Haiku의 `open` 명령으로 웹 페이지를 엽니다. 2.100.0은 32비트
툴체인으로 빌드할 수 있는 가장 최신 릴리스이며, 세 시스템 모두 같은 버전을
받습니다.

## restic

```sh
restic init --repo ~/restic-repo
restic -r ~/restic-repo backup ~/Documents
restic -r ~/restic-repo snapshots
restic -r ~/restic-repo restore latest --target ~/restored
```

로컬 디렉터리, SFTP, REST 서버, S3 등 다른 백엔드로의 백업은 원래의 restic과
같이 동작합니다. `restic mount`(FUSE 없음)와 `restic self-update`는 쓸 수
없습니다. 확장 속성은 백업하지 않습니다.

## Hugo

```sh
hugo new site mysite
cd mysite
hugo server                  # 그다음 http://127.0.0.1:1313 을 엽니다
hugo                         # public/에 빌드
```

표준 에디션입니다. 확장(extended) 에디션의 Sass 컴파일러와 WebP 인코더는
cgo가 필요하므로, "Hugo extended"가 필요한 테마는 빌드되지 않습니다.
`hugo server`는 실행 중에 바뀐 파일을 감지해 다시 빌드합니다.

## Caddy

```sh
caddy file-server --root ~/public_html --listen 127.0.0.1:8080
caddy run --config Caddyfile
caddy reload --config Caddyfile
caddy stop
```

표준 모듈(파일 서버, 리버스 프록시, 자동 HTTPS, Caddyfile)이 들어 있습니다.
관리 엔드포인트는 `localhost:2019` 대신 `127.0.0.1:2019`에서 대기합니다.
x86_64와 32비트 x86에서는 Haiku에 `/etc/hosts`가 없어서 Go 프로그램이 아직
`localhost`를 찾지 못합니다. 그쪽에서는 `reverse_proxy 127.0.0.1:3000`처럼
`localhost` 대신 `127.0.0.1`로 쓰세요. arm64 빌드는 Haiku의 hosts 파일을
읽으므로 `localhost`가 동작합니다.

## fzf

```sh
ls /boot/system/bin | fzf
fzf --filter=term < list.txt   # 비대화식
```

## lazygit

```sh
cd my-repository
lazygit
```

lazygit에는 `git` 2.32 이상이 필요합니다. x86_64와 32비트 x86의 Haiku에는
있습니다(`pkgman install git`, 32비트 x86에서는 `git_x86`). RenkuOS arm64
저장소에는 아직 git이 없어서, 그곳에서 lazygit은 그 사실을 알리고 끝납니다.

## 실행 중인 명령 멈추기

세 시스템 모두에서 Ctrl-C와 `kill`로 `syncthing`, `rclone serve`,
`hugo server`, `caddy file-server` 등을 멈출 수 있습니다. arm64에서는 고친
툴체인으로 빌드한 패키지(위의 리비전 참고)여야 합니다. 이전 arm64 빌드는
둘 다 무시했고 `kill -9`로만 멈췄습니다.

## 제거

```sh
pkgman uninstall rclone      # 또는 syncthing, github_cli, restic, hugo, caddy,
                             # fzf, lazygit. 32비트 x86에서는 _x86을 붙입니다
```

## 빌드

`build.sh`가 워크스테이션에서 도구를 크로스 빌드하고 `package.sh`가 패키지를
만듭니다. 패치와 필요한 Go 툴체인은 [docs/PORTING.md](docs/PORTING.md)(영문)에
설명되어 있습니다.

## AI 사용 고지

이 포트의 일부는 AI 코딩 도구(Anthropic Claude)의 도움을 받아 개발했습니다.
모든 코드는 작성자가 검토하고 테스트했습니다.
