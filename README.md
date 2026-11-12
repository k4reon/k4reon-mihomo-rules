<p align="center">
  <img src="docs/images/ssclash-logo.png" alt="SSClash — Super Simple Clash" width="180">
</p>

# mihomo rules for Russian home routers

Это рабочая база правил mihomo для домашних роутеров в России.
Конфигурация собрана и используется автором репозитория на своих
роутерах, а также публикуется для всех. В репозитории два профиля
и два полных конфига:

- `MATCH,PROXY` — всё неизвестное идёт в прокси;
- `MATCH,DIRECT` — всё неизвестное идёт напрямую, в прокси только сервисы.

![SSClash-Go: профиль k4reon-proxy](docs/images/ssclash-ui.png)

<sub>SSClash-Go 7.6.0, профиль `k4reon-proxy`: конфиг целиком редактируется
и проверяется в веб-интерфейсе роутера.</sub>

## Идея

Один набор правил и два профиля, которые автор использует на своих
роутерах. Публичные источники сведены вместе, очищены от мусора и
дополнены тем, чего в них не хватает. Репозиторий — не коллекция
чужих конфигов, а рабочая база, проверенная на реальном роутере.

## Основа

За основу конфигурации взят материал:

https://ssclash.notion.site/Mihomo-SSClash-15989188f6b48051a97fc887adea736a

Полный текст перенесён в `docs/ssclash-notion.md` — включая разделы
про SSClash 4 и SSClash-Go. Изображения в документе ссылаются на
исходные файлы Notion.

## Состав базы

| Категория | Домены | CIDR | Куда идёт |
|---|---:|---:|---|
| private | 133 | 15 | DIRECT |
| ads | 131 | — | REJECT |
| ru | 1886 | — | DIRECT |
| ru-classical | 11 TLD | — | DIRECT |
| torrent | 491 | — | DIRECT |
| youtube | 179 | 2 | YouTube |
| games | 942 | 63 | Games |
| discord | 29 | 1 | Discord |
| ai | 217 | 2 | Ai |
| google | 1047 | 4 | DIRECT |
| messengers | 41 | 24 | Messengers |
| social | 609 | 23 | Fast |
| custom | 28 | — | PROXY / DIRECT |

Итого около 5733 доменов и 134 CIDR.

Полные объединённые списки по каждой категории лежат в `dist/lists/`
(`k4reon-<категория>-domains.txt` и `k4reon-<категория>-ip.txt`).
В репозитории также остаются `rules/<категория>/*.txt` — это только
локальные добавления поверх публичных источников; итоговый список
получается их слиянием при сборке.

## Структура

```
configs/     ssclash-go/ и ssclash-4/ — полные конфиги PROXY и DIRECT
dist/        готовые k4reon-*.mrs и classical-*.txt
dist/lists/  полные объединённые списки в читаемом .txt
rules/       локальные добавления по категориям + denylist
scripts/     merge.py — слияние и фильтрация
sources.json откуда брать публичные списки
build.ps1 / build.sh
```

`configs/ssclash-go/*.yaml` — полные конфиги в стиле SSClash-Go: tproxy,
DNS, sniffer, proxy-providers, группы `fallback`/`url-test`/`select`,
rule-providers и rules. Их можно брать целиком, а не собирать по частям.

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

- `configs/ssclash-go/PROXY.yaml` — полный `MATCH,PROXY` для SSClash-Go;
- `configs/ssclash-go/DIRECT.yaml` — полный `MATCH,DIRECT` для SSClash-Go;
- `configs/ssclash-4/PROXY.yaml` — полный `MATCH,PROXY` для SSClash 4;
- `configs/ssclash-4/DIRECT.yaml` — полный `MATCH,DIRECT` для SSClash 4.

Отличие SSClash 4 только в блоке контроллера и UI:

```yaml
external-controller: 0.0.0.0:9090
external-ui: ./ui
external-ui-url: "https://github.com/Zephyruso/zashboard/releases/latest/download/dist-cdn-fonts.zip"
```

В SSClash-Go остаётся `external-controller: 127.0.0.1:9090`, UI отдаёт
сам SSClash. В SSClash 4 API доступен по сети — доступ стоит ограничить
firewall или задать `secret`.

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
3. `custom-proxy` → PROXY (выше RU, иначе `.ru` из `ru-classical` перебьёт)
4. `ru` → DIRECT
5. `torrent` → DIRECT
6. `youtube` → YouTube
7. `games` → Games
8. `discord` → Discord
9. `ai` → Ai
10. `google` → DIRECT
11. `messengers` → Messengers
12. `social` → Fast
13. `custom-direct` → DIRECT
14. `GEOIP,RU/SU` → DIRECT (только в PROXY)
15. `MATCH` → PROXY или DIRECT

Ключевые решения:

- **Реклама и custom-proxy выше RU.** `category-ru` содержит TLD `.ru`,
  поэтому `adriver.ru` и другие `.ru`-рекламники нужно блокировать до RU-правил,
  а `.ru`-домены из `custom-proxy` — иначе они уйдут в DIRECT по `DOMAIN-SUFFIX,ru`.
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

Домены в базе собираются как **суффиксные** (`+.domain`), а не точные.
Иначе `www.google.com` не совпал бы с `google.com` и ушёл бы в `MATCH`.

## Как использовать

**Вариант 1 — полный конфиг.**
Для SSClash-Go: `configs/ssclash-go/PROXY.yaml` или `DIRECT.yaml`.
Для SSClash 4: `configs/ssclash-4/PROXY.yaml` или `DIRECT.yaml`.
Заменить подписку и скопировать на роутер как `config.yaml`
(или в профиль SSClash).

**Вариант 2 — только правила.**
Перенести блоки `rule-providers` и `rules` из выбранного полного
конфига в существующий конфиг.

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

## Обновление

Списки обновляются сами, но не мгновенно — в два шага:

1. **Источники → дистрибутив.** GitHub Actions запускает сборку при
   каждом пуше в `main` и ежедневно по расписанию (03:00 UTC):
   перекачивает публичные списки, пересобирает `dist/*.mrs` и
   `dist/lists/*.txt` и коммитит изменения, если они есть.
2. **Дистрибутив → роутер.** mihomo обновляет `rule-providers`
   каждые 12 часов (`interval: 43200`), подписку — каждый час
   (`interval: 3600`). Отдельно ничего настраивать не нужно.

Вручную: кнопка **Update Providers** в веб-интерфейсе SSClash или
`PUT /providers/rules/<имя>` через API mihomo.

Нюансы:

- `raw.githubusercontent.com` отдаётся через CDN с кэшем около 5 минут,
  поэтому свежий коммит появляется у клиента не сразу;
- если правил нет в кэше клиента, первая загрузка идёт при старте;
- расписание GitHub может отключить после 60 дней без активности
  в репозитории — тогда сборка запускается вручную (`Run workflow`).

## Сборка

```powershell
.\build.ps1
```

или:

```bash
./build.sh
```

Скрипт скачивает mihomo, конвертирует mrs-источники в текст, запускает
`scripts/merge.py`, собирает `dist/*.mrs`, копирует classical-файлы
и публикует полные списки в `dist/lists/`.
GitHub Actions пересобирает `dist/` на каждый пуш и ежедневно по расписанию.

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
configs/ssclash-go/PROXY.yaml   → test is successful
configs/ssclash-go/DIRECT.yaml  → test is successful
configs/ssclash-4/PROXY.yaml    → test is successful
configs/ssclash-4/DIRECT.yaml   → test is successful
```

## Дисклеймер

Правила рассчитаны на типовой домашний роутер в России. Провайдеры,
регионы и блокировки меняются — конфигурацию стоит проверять на своём
подключении. Секретов и персональных данных в репозитории нет.
