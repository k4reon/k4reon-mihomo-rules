# mihomo rules for Russian home routers

Это рабочая база правил mihomo для домашних роутеров в России.
Конфигурация собрана и используется автором репозитория на своих
роутерах, а также публикуется для всех. В репозитории два профиля
и два полных конфига:

- `MATCH,PROXY` — всё неизвестное идёт в прокси;
- `MATCH,DIRECT` — всё неизвестное идёт напрямую, в прокси только сервисы.

## Идея

Один набор правил и два профиля, которые автор использует на своих
роутерах. Публичные источники сведены вместе, очищены от мусора и
дополнены тем, чего в них не хватает. Репозиторий — не коллекция
чужих конфигов, а рабочая база, проверенная на реальном роутере.

## Состав базы

| Категория | Домены | CIDR | Куда идёт |
|---|---:|---:|---|
| private | 133 | 15 | DIRECT |
| ads | 131 | — | REJECT |
| ru | 1886 | — | DIRECT |
| ru-classical | 11 TLD | — | DIRECT |
| torrent | 490 | — | DIRECT |
| youtube | 179 | 2 | YouTube |
| games | 942 | 63 | Games |
| discord | 29 | 1 | Discord |
| ai | 217 | 2 | Ai |
| google | 1047 | 4 | DIRECT |
| messengers | 41 | 24 | Messengers |
| social | 609 | 23 | Fast |
| custom | 11 | — | PROXY / DIRECT |

Итого около 5700 доменов и 134 CIDR.

## Источники

База собрана из публичных списков:

- [MetaCubeX/meta-rules-dat](https://github.com/MetaCubeX/meta-rules-dat/tree/meta)
  — `category-ru`, `whatsapp`, реклама, AI, соцсети;
- [DustinWin/ruleset_geodata](https://github.com/DustinWin/ruleset_geodata/releases/tag/mihomo-ruleset)
  — `games`, `private`, `trackerslist`, `telegramip`;
- [Keviin560/Shunt_Rules](https://github.com/Keviin560/Shunt_Rules)
  — Google, Steam, YouTube, Gemini, AI, Discord, Telegram, WhatsApp,
  соцсети и IP-списки;
- [hydraponique/roscomvpn-geosite](https://cdn.jsdelivr.net/gh/hydraponique/roscomvpn-geosite/release/mihomo/)
  и `roscomvpn-geoip` — torrent и private IP;
- `k4reon.com/ru-whitelist` — RU-домены, перенесены в `rules/ru/domains.txt`.

[jameszeroX/zkeen-ip](https://github.com/jameszeroX/zkeen-ip) проверен,
но не используется: `ru` — 13.5k CIDR, которые дублируют `GEOIP,RU`,
а CDN/хостинги (Amazon, Datacamp, OVH и т.д.) для домашнего роутера
слишком широкие. Discord-набор zkeen (`35.192.0.0/11`, `104.16.0.0/13`,
`162.158.0.0/15`) без UDP-портов заворачивает лишнее.

## Полные конфиги

- `configs/PROXY.yaml` — профиль `MATCH,PROXY`;
- `configs/DIRECT.yaml` — профиль `MATCH,DIRECT`.

Перед использованием заменить:

- `url` подписки в `proxy-providers.main`;
- при необходимости — фильтры групп (в примерах они закомментированы).

### Почему такие настройки

**`tproxy-port` + `udp: true`**
Роутер работает в режиме шлюза, трафик заворачивается через tproxy.
UDP включён отдельно — без него не работают игры, Discord и часть AI.

**`endpoint-independent-nat: true`**
Full-cone NAT: на порт клиента создаётся одно NAT-отображение.
Это даёт открытый NAT в играх. Побочный эффект: P2P-потоки игры
(например, CoD) не видны в `/connections` отдельными строками — они
переиспользуют одно отображение.

**DNS**
- обычные запросы — DoH через группу `PROXY`;
- `.lan`, `.local`, `kion.ru`, `wink.ru` — системный DNS;
- `geosite:category-ru` — российские DNS (Yandex), чтобы RU-сервисы
  не зависели от прокси;
- `rule-set:k4reon-ai-domains` — DNS для AI через группу `Ai`;
- `respect-rules: false` — DNS не зависит от правил маршрутизации.

**Sniffer**
`force-dns-mapping` и `parse-pure-ip` нужны, чтобы доменные правила
срабатывали, когда приложение подключается по IP. Без этого часть
трафика уходила бы в `MATCH`.

**Группы**
`PROXY` — общий выход, `Fast` — ручной выбор узла. `YouTube`, `Ai`,
`Discord`, `Games`, `Messengers` — тематические группы. `Games`
по умолчанию `DIRECT`: для части игр прямой маршрут лучше, при
необходимости узел выбирается вручную.

### Порядок правил

1. `private` → DIRECT
2. `ads` → REJECT
3. `ru` → DIRECT
4. `torrent` → DIRECT
5. `youtube` → YouTube
6. `games` → Games
7. `discord` → Discord
8. `ai` → Ai
9. `google` → DIRECT
10. `messengers` → Messengers
11. `social` → Fast
12. `custom` → PROXY / DIRECT
13. `GEOIP,RU/SU` → DIRECT (только в PROXY)
14. `MATCH` → PROXY или DIRECT

Ключевые решения:

- **Реклама выше RU.** `category-ru` содержит TLD `.ru`, поэтому
  `adriver.ru` и другие `.ru`-рекламники нужно блокировать до RU-правил.
- **AI и YouTube выше Google.** Иначе `google.com` перехватит
  `gemini.google.com` и `youtube.com` и отправит их в DIRECT.
- **Google намеренно DIRECT** — поиск должен видеть российский IP.
  Нейросети при этом идут в `Ai`.
- **`games-ip` только для UDP:**
  `AND,((NETWORK,UDP),(RULE-SET,k4reon-games-ip)),Games`.
  В публичном `Game_IP` есть `35.192.0.0/12` (Google Cloud); без
  UDP-фильтра туда уйдёт лишний TCP.

### mrs и classical

`mrs` поддерживает только `behavior: domain` и `behavior: ipcidr`.
Порты и `AND` лежат в `*-ports.txt` / `*-classical.txt`
(`behavior: classical`, `format: text`).

## Как использовать

**Вариант 1 — полный конфиг.**
Взять `configs/PROXY.yaml` или `configs/DIRECT.yaml`, заменить подписку
и скопировать на роутер как `config.yaml` (или в профиль SSClash).

**Вариант 2 — только правила.**
Взять `profiles/PROXY.yaml` или `profiles/DIRECT.yaml` и перенести
блоки `rule-providers` и `rules` в существующий конфиг.

Если в конфиге уже есть anchors, строки можно сократить:

```yaml
k4reon-games-domains: { <<: *domain, url: ... }
k4reon-games-ip: { <<: *ipcidr, url: ... }
k4reon-games-ports: { <<: *classical, url: ... }
```

### Что можно удалить из старого конфига

Эти провайдеры заменены базой:

```
games@domain
games@ip
steam@domain
discord@domain
ru-whitelist
category-ru@domain
```

Остальные провайдеры (`google`, `youtube`, `telegram`, `ai`, `private`,
`torrent` и т.д.) тоже можно убрать, если они полностью покрыты
`k4reon-*` и имена групп совпадают.

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

## Добавление правил

- домен — `rules/<категория>/domains.txt`;
- CIDR — `rules/<категория>/ipcidr.txt`;
- порт/AND — `rules/<категория>/ports.txt` или `classical.txt`;
- новый источник — `sources.json` (`format`: `plain`, `loon`, `v2fly`, `mrs`);
- мусор — `rules/denylist.txt`.

После изменений: `./build.ps1`, затем коммит `dist/`.

## Проверка

Конфиги проверены на роутере:

```
configs/PROXY.yaml   → test is successful
configs/DIRECT.yaml  → test is successful
profiles/PROXY.yaml  → test is successful (24 провайдера, 27 правил)
profiles/DIRECT.yaml → test is successful (16 провайдеров, 17 правил)
```

## Дисклеймер

Правила рассчитаны на типовой домашний роутер в России. Провайдеры,
регионы и блокировки меняются — конфигурацию стоит проверять на своём
подключении. Секретов и персональных данных в репозитории нет.
