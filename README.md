# k4reon mihomo rules

Единая база правил mihomo для домашних роутеров в России.
Публичные списки от разных авторов слиты в один набор, очищены от мусора
и разложены по категориям. В репозитории — **два готовых профиля**:
полный (`MATCH,PROXY`) и лёгкий (`MATCH,DIRECT`).

## Что внутри

| Категория | Доменов | CIDR | Куда идёт |
|---|---:|---:|---|
| `private` | 133 | 15 | DIRECT |
| `ads` | 131 | — | REJECT |
| `ru` | 1886 | — | DIRECT |
| `ru-classical` | 11 TLD | — | DIRECT |
| `torrent` | 490 | — | DIRECT |
| `youtube` | 179 | 2 | YouTube |
| `games` | 942 | 63 | Games |
| `discord` | 29 | 1 | Discord |
| `ai` | 217 | 2 | Ai |
| `google` | 1047 | 4 | DIRECT |
| `messengers` | 41 | 24 | Messengers |
| `social` | 609 | 23 | Fast |
| `custom` | 11 | — | PROXY / DIRECT |

Итого ~5700 доменов и ~134 CIDR.

## Источники

- **MetaCubeX/meta-rules-dat** — `category-ru`, `whatsapp`, реклама, AI, соцсети.
- **DustinWin/ruleset_geodata** — `games`, `private`, `trackerslist`, `telegramip`.
- **Keviin560/Shunt_Rules** — Google, Steam, YouTube, Gemini, AI, Discord,
  Telegram, WhatsApp, соцсети и IP-списки.
- **hydraponique/roscomvpn-geosite / geoip** — torrent и private IP.
- **k4reon.com/ru-whitelist** — перенесён в репозиторий (`rules/ru/domains.txt`).

`jameszeroX/zkeen-ip` проанализирован, но **не включён**: его `ru` — 13.5k CIDR,
которые дублируют `GEOIP,RU`, а CDN/хостинги (Amazon, Datacamp, OVH и т.д.)
для домашнего роутера слишком широкие. Discord-набор zkeen тоже широкий
(`35.192.0.0/11`, `104.16.0.0/13`, `162.158.0.0/15`) и без UDP-портов
заворачивает лишнее.

## Профили

### `profiles/PROXY.yaml` — полный (`MATCH,PROXY`)

Всё, что не совпало, идёт в прокси. Поэтому здесь перечислены все исключения:

```
private → DIRECT
ads → REJECT
ru → DIRECT
torrent → DIRECT
youtube → YouTube
games → Games
discord → Discord
ai → Ai
google → DIRECT
messengers → Messengers
social → Fast
custom-proxy → PROXY
custom-direct → DIRECT
GEOIP,RU / GEOIP,SU → DIRECT
MATCH → PROXY
```

### `profiles/DIRECT.yaml` — лёгкий (`MATCH,DIRECT`)

Всё, что не совпало, идёт напрямую. Здесь только то, что должно в прокси:

```
ads → REJECT
youtube → YouTube
games → Games
discord → Discord
ai → Ai
messengers → Messengers
social → Fast
custom-proxy → PROXY
MATCH → DIRECT
```

В лёгком профиле не нужны `ru`, `private`, `torrent`, `google`, `GEOIP,RU/SU`
и direct-часть custom — они и так идут напрямую.

## Важные нюансы

1. **AI стоит выше Google.** `gemini.google.com` и другие нейросети должны
   попадать в `Ai`, а не в `DIRECT` через `google.com`.
2. **YouTube стоит выше Google** по той же причине.
3. **Реклама стоит выше RU.** `category-ru` содержит TLD `.ru`, поэтому
   `adriver.ru` и другие `.ru`-рекламники нужно блокировать до RU-правил.
4. **`games-ip` применяется только к UDP:**
   `AND,((NETWORK,UDP),(RULE-SET,k4reon-games-ip)),Games`.
   В публичном `Game_IP` есть `35.192.0.0/12` (Google Cloud); без UDP-фильтра
   туда уйдёт лишний TCP.
5. **Google намеренно `DIRECT`** — чтобы поиск выдавал результаты по
   российскому IP. Сами нейросети при этом идут в `Ai`.
6. **`mrs` поддерживает только domain/ipcidr.** Порты и `AND` лежат в
   `*-ports.txt` / `*-classical.txt` (`behavior: classical`, `format: text`).

## Как подключить

1. Открой `profiles/PROXY.yaml` или `profiles/DIRECT.yaml`.
2. Скопируй блок `rule-providers` в свою секцию `rule-providers`.
3. Скопируй блок `rules` в свою секцию `rules`.
4. Удали старые провайдеры, которые теперь заменены:
   `games@domain`, `games@ip`, `steam@domain`, `discord@domain`,
   `ru-whitelist`, `category-ru@domain`.
5. Остальные провайдеры (`google`, `youtube`, `telegram`, `ai`, `private`,
   `torrent` и т.д.) тоже можно убрать, если они полностью покрыты
   `k4reon-*` — но проверь, что твои группы называются так же.

Если в конфиге уже есть anchors, можно сократить строки:

```yaml
k4reon-games-domains: { <<: *domain, url: ... }
k4reon-games-ip: { <<: *ipcidr, url: ... }
k4reon-games-ports: { <<: *classical, url: ... }
```

## Сборка

```powershell
.\build.ps1
```

или:

```bash
./build.sh
```

Скрипт скачивает mihomo, конвертирует mrs-источники в текст, запускает
`scripts/merge.py`, собирает `dist/*.mrs` и копирует classical-файлы.

GitHub Actions пересобирает `dist/` на каждый пуш.

## Как добавлять своё

- Домен — в `rules/<категория>/domains.txt`.
- CIDR — в `rules/<категория>/ipcidr.txt`.
- Порт/AND — в `rules/<категория>/ports.txt` или `classical.txt`.
- Новый источник — в `sources.json` (`format`: `plain`, `loon`, `v2fly`, `mrs`).
- Мусор — в `rules/denylist.txt`.

После изменений: `./build.ps1`, затем коммит `dist/`.

## Проверка

Оба профиля проверены на роутере:

```
clash -t ... → test is successful
```

Скрипт проверки: `profiles/` + локальные файлы из `dist/`
(24 провайдера / 27 правил для PROXY, 16 / 17 для DIRECT).

## Дисклеймер

Правила — это база для типового домашнего роутера в России.
Провайдеры, регионы и блокировки меняются; проверяй на своём подключении.
Секретов и персональных данных в репозитории нет — только публичные
домены, CIDR и порты.
