# MRS-MIHOMO — k4reon unified bases (games + discord + ru)

Своя база правил Mihomo: публичные списки от разных авторов **сливаются
в один набор** и дополняются моими находками. В конфиге остаётся
8 провайдеров вместо десятка.

## Что внутри

| Набор | Доменов / CIDR | Источники |
|---|---|---|
| `k4reon-games-domains.mrs` | ~942 | DustinWin `games.list`, Keviin560 `Game_Proxy`, v2fly `category-games-!cn` + наши домены |
| `k4reon-games-ip.mrs` | 61 CIDR | Keviin560 `Game_IP` + наши Bungie/Demonware диапазоны |
| `k4reon-games-ports.txt` | 10 правил | PoE2 / Destiny 2 / Steam SDR |
| `k4reon-discord-domains.mrs` | 29 | Keviin560 `Discord`, v2fly `discord` + наши |
| `k4reon-discord-ip.mrs` | 1 CIDR | `66.22.192.0/18` (Discord TURN) |
| `k4reon-discord-ports.txt` | 2 правила | голос `19294-19344`, Go Live `50000-65535` |
| `k4reon-ru-domains.mrs` | ~1886 | v2fly `category-ru` (со всеми include) + перенесённый `ru-whitelist` |
| `k4reon-ru-classical.txt` | 11 TLD | `ru`, `su`, `moscow`, `tatar`, `xn--*` |

`ru-whitelist` с k4reon.com перенесён в `rules/ru/domains.txt` и больше
не зависит от твоего сервера.

Мусор отсекается в `rules/denylist.txt`: репаки, пиратки, ускорители,
реклама. IP из доменных списков, `keyword`/`regexp`, `@ads`/`@cn`
и дубликаты убираются автоматически.

## Структура

```
MRS-MIHOMO/
├─ sources.json           # откуда брать публичные списки
├─ scripts/merge.py       # слияние + фильтрация + дедупликация
├─ rules/
│  ├─ games/  (domains.txt, ipcidr.txt, ports.txt)
│  ├─ discord/(domains.txt, ipcidr.txt, ports.txt)
│  ├─ ru/     (domains.txt, ipcidr.txt, classical.txt)
│  └─ denylist.txt
├─ build/                 # промежуточные списки (не коммитится)
├─ dist/                  # готовые mrs/txt (коммитится)
├─ build.ps1 / build.sh
├─ config-example.yaml
└─ .github/workflows/build.yml
```

## Сборка

```powershell
.\build.ps1
```

или:

```bash
./build.sh
```

Скрипт:
1. скачивает Mihomo;
2. скачивает `Game_IP.mrs` и конвертирует в текст;
3. запускает `merge.py` — тянет источники из `sources.json`,
   добавляет локальные правила, фильтрует, дедуплицирует;
4. собирает `dist/*.mrs` и копирует `*.txt`.

## Подключение (стиль твоего config.yaml)

```yaml
a1: &domain { type: http, format: mrs, behavior: domain, interval: 43200 }
a2: &ipcidr { type: http, format: mrs, behavior: ipcidr, interval: 43200 }
a3: &classical { type: http, format: text, behavior: classical, interval: 43200 }
```

`rule-providers`:

```yaml
  k4reon-games-domains: { <<: *domain, url: https://raw.githubusercontent.com/k4reon/k4reon-mihomo-rules/main/dist/k4reon-games-domains.mrs }
  k4reon-games-ip: { <<: *ipcidr, url: https://raw.githubusercontent.com/k4reon/k4reon-mihomo-rules/main/dist/k4reon-games-ip.mrs }
  k4reon-games-ports: { <<: *classical, url: https://raw.githubusercontent.com/k4reon/k4reon-mihomo-rules/main/dist/k4reon-games-ports.txt }
  k4reon-discord-domains: { <<: *domain, url: https://raw.githubusercontent.com/k4reon/k4reon-mihomo-rules/main/dist/k4reon-discord-domains.mrs }
  k4reon-discord-ip: { <<: *ipcidr, url: https://raw.githubusercontent.com/k4reon/k4reon-mihomo-rules/main/dist/k4reon-discord-ip.mrs }
  k4reon-discord-ports: { <<: *classical, url: https://raw.githubusercontent.com/k4reon/k4reon-mihomo-rules/main/dist/k4reon-discord-ports.txt }
  k4reon-ru-domains: { <<: *domain, url: https://raw.githubusercontent.com/k4reon/k4reon-mihomo-rules/main/dist/k4reon-ru-domains.mrs }
  k4reon-ru-classical: { <<: *classical, url: https://raw.githubusercontent.com/k4reon/k4reon-mihomo-rules/main/dist/k4reon-ru-classical.txt }
```

`rules`:

```yaml
  - RULE-SET,k4reon-ru-domains,DIRECT
  - RULE-SET,k4reon-ru-classical,DIRECT
  - RULE-SET,k4reon-games-domains,Games
  - AND,((NETWORK,UDP),(RULE-SET,k4reon-games-ip)),Games
  - RULE-SET,k4reon-games-ports,Games
  - RULE-SET,k4reon-discord-domains,Discord
  - RULE-SET,k4reon-discord-ip,Discord
  - RULE-SET,k4reon-discord-ports,Discord
```

**Что можно удалить из конфига:**

```yaml
  games@domain
  games@ip
  steam@domain
  discord@domain
  ru-whitelist
  category-ru@domain
```

Остальные провайдеры (`google`, `youtube`, `telegram`, `ai`, `private`,
`torrent` и т.д.) не трогаем.

## Как добавить нового автора

Открой `sources.json` и добавь URL + формат:

```json
{ "url": "https://raw.githubusercontent.com/AUTHOR/REPO/main/games.list", "format": "plain" }
```

Форматы:

- `plain` — по одному домену в строке;
- `loon` — `DOMAIN,` / `DOMAIN-SUFFIX,`;
- `v2fly` — списки с `include:`, `full:`, `keyword:`.

После этого — `./build.ps1` и коммит `dist/`.

## Проверка

```bash
clash -t -d /tmp/k4reon-test -f test.yaml
```

Проверено на роутере: `test is successful`.
