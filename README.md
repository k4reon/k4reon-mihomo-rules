# MRS-MIHOMO — k4reon rules for mihomo (games + discord)

Репозиторий с кастомными правилами Mihomo для игр и Discord.
Все собранные файлы и rule-provider'ы имеют префикс `k4reon-`.

Дополняет готовые наборы (DustinWin `games.mrs`, Keviin560 `Discord.mrs`),
но содержит то, чего в публичных наборах нет:

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
│  │  └─ ports.yaml       # порты и AND-правила (behavior: classical)
│  └─ discord/
│     ├─ domains.txt
│     ├─ ipcidr.txt
│     └─ ports.yaml
├─ dist/                  # собранные .mrs (генерируется build-скриптом)
│  ├─ k4reon-games-domains.mrs
│  ├─ k4reon-games-ip.mrs
│  ├─ k4reon-games-ports.yaml
│  ├─ k4reon-discord-domains.mrs
│  ├─ k4reon-discord-ip.mrs
│  └─ k4reon-discord-ports.yaml
├─ build.ps1              # сборка на Windows
├─ build.sh               # сборка на Linux/macOS
├─ config-example.yaml    # пример подключения в Mihomo
└─ .github/workflows/build.yml
```

## Важно про формат mrs

`mrs` поддерживает только:

- `behavior: domain` — домены;
- `behavior: ipcidr` — IP-подсети.

Порты (`DST-PORT`), `AND`, `SRC-IP-CIDR` и прочие составные правила
в `mrs` не помещаются. Они лежат в `ports.yaml` и подключаются как
`behavior: classical`, `format: yaml`.

## Сборка локально

Windows (PowerShell):

```powershell
.\build.ps1
```

Linux/macOS:

```bash
./build.sh
```

Скрипт сам скачает Mihomo в `.tools/` и соберёт файлы в `dist/`.

## Подключение в Mihomo

Локально (файлы лежат рядом с конфигом):

```yaml
rule-providers:
  k4reon-games-domains:
    type: file
    behavior: domain
    format: mrs
    path: ./local-rules/k4reon-games-domains.mrs
  k4reon-games-ip:
    type: file
    behavior: ipcidr
    format: mrs
    path: ./local-rules/k4reon-games-ip.mrs
  k4reon-games-ports:
    type: file
    behavior: classical
    format: yaml
    path: ./local-rules/k4reon-games-ports.yaml

rules:
  - RULE-SET,k4reon-games-domains,Games
  - RULE-SET,k4reon-games-ip,Games
  - RULE-SET,k4reon-games-ports,Games
```

Через GitHub (после пуша):

```yaml
rule-providers:
  k4reon-games-domains:
    type: http
    behavior: domain
    format: mrs
    url: https://raw.githubusercontent.com/k4reon/k4reon-mihomo-rules/main/dist/k4reon-games-domains.mrs
    path: ./ruleset/k4reon-games-domains.mrs
    interval: 86400
```

Полный пример — в `config-example.yaml`.

## Что уже покрыто готовыми наборами

- CoD / Demonware / Activision / BattlEye — `DustinWin games.mrs`
- Steam / Steam SDR — `DustinWin games.mrs` + `games@ip`
- Discord-домены — `Keviin560 Discord.mrs`
- Discord TURN `66.22.192.0/18` — стандартный диапазон

Поэтому в этот репозиторий вынесено только то, чего там нет.
Дублирование не вредно, но при желании лишние строки можно убрать.

## Как добавлять новое

1. Домен — строка в `rules/games/domains.txt`.
2. Стабильная подсеть — CIDR в `rules/games/ipcidr.txt`.
3. Порт/составное правило — в `rules/games/ports.yaml` в формате
   `payload` без цели (цель задаёт `RULE-SET`).
4. Пересобрать: `./build.ps1` или `./build.sh`.
5. Закоммитить `dist/` (или дать GitHub Actions собрать автоматически).

## Проверка после применения

В `/connections` у игровых соединений должно быть:

```
rule    = RuleSet / DomainSuffix / And
payload = k4reon-games-domains / k4reon-games-ports
chains  = Games / <выбранный сервер>
```

Если соединение всё ещё `Match → PROXY` — добавить его IP/порт/домен
в соответствующий файл и пересобрать.
