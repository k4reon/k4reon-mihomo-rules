# MRS-MIHOMO — k4reon rules for mihomo (games + discord)

Кастомные правила Mihomo для игр и Discord. Все файлы и rule-provider'ы
имеют префикс `k4reon-`.

Дополняет готовые наборы (DustinWin `games.mrs`, Keviin560 `Discord.mrs`)
тем, чего в публичных наборах нет:

- Bungie / Destiny 2: `gravityshavings.net`, `deadorbit.net`, `bungie.net`
- Path of Exile 2: `pathofexile2.com`, `pathofexile.com`, `poecdn.com`
- Игровые порты PoE2 / Destiny 2 / Steam SDR
- Discord Go Live: UDP `50000-65535`
- Discord TURN: `66.22.192.0/18`

## Структура

```
MRS-MIHOMO/
├─ rules/
│  ├─ games/
│  │  ├─ domains.txt      # домены (behavior: domain)
│  │  ├─ ipcidr.txt       # CIDR (behavior: ipcidr)
│  │  └─ ports.txt        # порты/AND (behavior: classical, format: text)
│  └─ discord/
│     ├─ domains.txt
│     ├─ ipcidr.txt
│     └─ ports.txt
├─ dist/                  # собранные файлы
│  ├─ k4reon-games-domains.mrs
│  ├─ k4reon-games-ip.mrs
│  ├─ k4reon-games-ports.txt
│  ├─ k4reon-discord-domains.mrs
│  ├─ k4reon-discord-ip.mrs
│  └─ k4reon-discord-ports.txt
├─ build.ps1              # сборка на Windows
├─ build.sh               # сборка на Linux/macOS
├─ config-example.yaml    # пример в стиле твоего конфига (anchors)
└─ .github/workflows/build.yml
```

## Важно про формат mrs

`mrs` поддерживает только `behavior: domain` и `behavior: ipcidr`.
Порты (`DST-PORT`), `AND` и прочие составные правила в `mrs` не помещаются —
они лежат в `ports.txt` и подключаются как `behavior: classical`,
`format: text` (anchor `*classical`, как в твоём конфиге).

## Сборка

Windows:

```powershell
.\build.ps1
```

Linux/macOS:

```bash
./build.sh
```

Скрипт сам скачивает Mihomo в `.tools/` и собирает `dist/`.

## Подключение (как в твоём config.yaml)

У тебя уже есть anchors:

```yaml
anchors:
  a1: &domain { type: http, format: mrs, behavior: domain, interval: 43200 }
  a2: &ipcidr { type: http, format: mrs, behavior: ipcidr, interval: 43200 }
  a3: &classical { type: http, format: text, behavior: classical, interval: 43200 }
```

Тогда `rule-providers` — по одной строке на провайдер, без `path` и `interval`:

```yaml
  k4reon-games-domains: { <<: *domain, url: https://raw.githubusercontent.com/k4reon/k4reon-mihomo-rules/main/dist/k4reon-games-domains.mrs }
  k4reon-games-ip: { <<: *ipcidr, url: https://raw.githubusercontent.com/k4reon/k4reon-mihomo-rules/main/dist/k4reon-games-ip.mrs }
  k4reon-games-ports: { <<: *classical, url: https://raw.githubusercontent.com/k4reon/k4reon-mihomo-rules/main/dist/k4reon-games-ports.txt }
  k4reon-discord-domains: { <<: *domain, url: https://raw.githubusercontent.com/k4reon/k4reon-mihomo-rules/main/dist/k4reon-discord-domains.mrs }
  k4reon-discord-ip: { <<: *ipcidr, url: https://raw.githubusercontent.com/k4reon/k4reon-mihomo-rules/main/dist/k4reon-discord-ip.mrs }
  k4reon-discord-ports: { <<: *classical, url: https://raw.githubusercontent.com/k4reon/k4reon-mihomo-rules/main/dist/k4reon-discord-ports.txt }
```

И в `rules` — до `GEOIP,RU` и `MATCH,PROXY`:

```yaml
  - RULE-SET,k4reon-games-domains,Games
  - RULE-SET,k4reon-games-ip,Games
  - RULE-SET,k4reon-games-ports,Games
  - RULE-SET,k4reon-discord-domains,Discord
  - RULE-SET,k4reon-discord-ip,Discord
  - RULE-SET,k4reon-discord-ports,Discord
```

Если нужны локальные файлы вместо HTTP:

```yaml
  k4reon-games-domains: { type: file, format: mrs, behavior: domain, path: ./local-rules/k4reon-games-domains.mrs }
  k4reon-games-ports: { type: file, format: text, behavior: classical, path: ./local-rules/k4reon-games-ports.txt }
```

## Что покрыто готовыми наборами

- CoD / Demonware / Activision / BattlEye — `DustinWin games.mrs`
- Steam / Steam SDR — `DustinWin games.mrs` + `games@ip`
- Discord-домены — `Keviin560 Discord.mrs`
- Discord TURN `66.22.192.0/18` — стандартный диапазон

В репозиторий вынесено только то, чего там нет. Дублирование не вредно.

## Как добавлять новое

1. Домен — строка в `rules/games/domains.txt`.
2. Подсеть — CIDR в `rules/games/ipcidr.txt`.
3. Порт/составное правило — строка в `rules/games/ports.txt`
   без цели (цель задаёт `RULE-SET`).
4. Пересобрать: `./build.ps1` или `./build.sh`.
5. Закоммитить `dist/` (или дать GitHub Actions собрать автоматически).

## Проверка после применения

В `/connections`:

```
rule    = RuleSet / DomainSuffix / And
payload = k4reon-games-domains / k4reon-games-ports
chains  = Games / <выбранный сервер>
```
