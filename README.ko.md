# RenkuOS용 Go 도구

[English](README.md) · [Italiano](README.it.md) · [日本語](README.ja.md) · 한국어

rclone, Syncthing, GitHub CLI를 RenkuOS(Haiku)의 arm64, x86_64, 32비트 x86용으로
빌드한 것입니다. 비공식 빌드이며 rclone 프로젝트, Syncthing Foundation,
GitHub와는 관련이 없습니다.

| 도구 | 버전 | 패키지 | 32비트 x86 패키지 |
| --- | --- | --- | --- |
| rclone | 1.76.0 | `rclone` | `rclone_x86` |
| Syncthing | 1.30.0 | `syncthing` | `syncthing_x86` |
| GitHub CLI (`gh`) | 2.100.0 | `github_cli` | `github_cli_x86` |

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
`syncthing`, `gh`).

## 패키지 파일로 설치

저장소 없이 `package.sh`로 만든 `.hpkg`를 쓰는 경우:

```sh
pkgman install ./rclone-1.76.0-1-arm64.hpkg
```

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

## arm64에서 실행 중인 명령 멈추기

RenkuOS arm64에서는 Go 프로그램이 아직 Ctrl-C나 `kill`에 반응하지 않습니다
(그쪽 Go 런타임이 시그널을 전달하지 않습니다). 그래서 `syncthing`이나
`rclone serve`는 계속 실행됩니다. Syncthing은 웹 페이지(Actions ->
Shutdown)에서 종료하고, 나머지는 `kill -9 <team id>`나 ProcessController로
멈추세요. x86_64와 32비트 x86에는 해당하지 않습니다.

## 제거

```sh
pkgman uninstall rclone      # 또는 syncthing, github_cli. 32비트 x86에서는 _x86을 붙입니다
```

## 빌드

`build.sh`가 워크스테이션에서 도구를 크로스 빌드하고 `package.sh`가 패키지를
만듭니다. 패치와 필요한 Go 툴체인은 [docs/PORTING.md](docs/PORTING.md)(영문)에
설명되어 있습니다.

## AI 사용 고지

이 포트의 일부는 AI 코딩 도구(Anthropic Claude)의 도움을 받아 개발했습니다.
모든 코드는 작성자가 검토하고 테스트했습니다.
