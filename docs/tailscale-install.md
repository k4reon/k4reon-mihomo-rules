# Tailscale: установка и настройка на OpenWrt

Памятка: установка Tailscale и настройка интерфейса и firewall одной командой,
без ручного создания зоны в LuCI.

## Что делает скрипт

Повторяет ручную настройку:

1. ставит пакет `tailscale` (`apk` на OpenWrt 25+, `opkg` на 24 и ниже);
2. включает и запускает службу;
3. создаёт интерфейс `network.tailscale`:

   ```uci
   network.tailscale=interface
   network.tailscale.proto='none'
   network.tailscale.device='tailscale0'
   network.tailscale.multipath='off'
   ```

4. создаёт зону firewall `tailscale`:

   | Параметр | Значение |
   |---|---|
   | Входящий трафик | `ACCEPT` |
   | Исходящий трафик | `ACCEPT` |
   | Пересылка внутри зоны | `REJECT` |
   | Маскарадинг IPv4 | включён (`masq=1`) |
   | Ограничение MSS | включено (`mtu_fix=1`) |
   | Охватываемые сети | `tailscale` |

5. создаёт forwarding `tailscale → wan`;
6. применяет настройки (`uci commit`, `reload network/firewall`).

Подключение к tailnet скрипт не делает: после настройки выполните
`tailscale up` сами (или подключитесь как обычно по SSH).

## Запуск

Одна команда на роутере по SSH от root:

```sh
wget -O /tmp/tailscale-install.sh https://raw.githubusercontent.com/k4reon/k4reon-mihomo-rules/main/scripts/tailscale-install.sh && sh /tmp/tailscale-install.sh
```

Дальше скрипт покажет меню:

```
========================================
 Tailscale: установка и настройка
========================================
 init: /etc/init.d/tailscale
 пакет: apk
 статус: не установлен

Что сделать?
  1) Установить Tailscale и настроить интерфейс/firewall
  2) Проверить состояние и память
  3) Настроить память (покажет до и после)
  4) Вернуть исходный init-скрипт (память)
  5) Остановить Tailscale и выйти (logout)
  0) Выйти
```

При выборе 1 — скрипт все установит и настроит. В конце напишет:
`Дальше подключитесь сами: tailscale up`.

Пункт 2 (или `--status`) ничего не меняет — показывает: установлен ли
пакет, включён ли автозапуск, запущен ли процесс, есть ли интерфейс,
зона и forwarding, настроена ли память, сколько занимает `tailscaled`
(RSS), сколько ОЗУ свободно и подключён ли tailnet (без списка устройств).

Пункт 3 (или `--tune`) ограничивает память Tailscale: сначала показывает
текущее состояние (RSS `tailscaled` и свободная память), затем добавляет
`GOMEMLIMIT` и `GODEBUG=madvdontneed=1`, делает бэкап init-скрипта
и перезапускает службу. После перезапуска выводит те же цифры ещё раз —
видно, сколько было и сколько стало. Пункт 4 (или `--tune-restore`)
возвращает исходный init из бэкапа. Только память можно посмотреть
командой `--mem`.

Пункт 5 — остановить Tailscale и выполнить logout. Сначала выводится
предупреждение, что устройство пропадёт из tailnet, и запрос `[y/N]`.
Только после `y` выполняется `tailscale logout` и остановка службы.
При `N` (или любом другом ответе) — «Отменено» и возврат в меню, ничего
не меняется.

## Без вопросов

```sh
sh /tmp/tailscale-install.sh --yes       # установить и настроить
sh /tmp/tailscale-install.sh --dry-run   # только показать план
sh /tmp/tailscale-install.sh --status    # состояние и память
sh /tmp/tailscale-install.sh --mem       # только память: RSS и ОЗУ
sh /tmp/tailscale-install.sh --tune      # настроить память
sh /tmp/tailscale-install.sh --tune-restore  # вернуть init из бэкапа
sh /tmp/tailscale-install.sh --stop --yes  # остановить и выйти (logout)
```

## Память

Tailscale — Go-приложение; на роутере он занимает порядка 90–100 МБ.
Пункт 3 (или `--tune`) добавляет в `/etc/init.d/tailscale`:

| Параметр | Что делает |
|---|---|
| `GOMEMLIMIT` | мягкий лимит памяти Go: 25% ОЗУ, но не меньше 64 MiB и не больше 256 MiB |
| `GODEBUG=madvdontneed=1` | агрессивнее возвращать освобождённую память ОС |
| `TS_NO_LOGS_NO_SUPPORT=true` | не отправлять логи на log.tailscale.com (если строки ещё нет) |

Когда нужно:

| ОЗУ | Нужно? |
|---|---|
| 128–192 МБ | обязательно |
| 256 МБ | обязательно |
| 512 МБ | рекомендуется, если не хватает памяти |
| 1 ГБ и больше | обычно не требуется |

Скрипт показывает «Сейчас» (RSS `tailscaled` и свободная память), что
будет добавлено, делает бэкап `/etc/init.d/tailscale.bak`, перезапускает
службу и выводит «После перезапуска» — те же цифры плюс переменные
`GOMEMLIMIT` и `GODEBUG`. `GOMEMLIMIT` — мягкий лимит, RSS он жёстко
не ограничивает, но освобождённая память возвращается ОС активнее;
сразу после старта RSS обычно ниже, чем в работе.

Пример вывода:

```
ОЗУ роутера: 256 MiB
GOMEMLIMIT: 64MiB

Сейчас:
  tailscaled (pid 2409): 97 MiB RSS
  ОЗУ: свободно 48 MiB из 256 MiB

Будет добавлено:
  procd_append_param env GOMEMLIMIT=64MiB
  procd_append_param env GODEBUG=madvdontneed=1

...
После перезапуска:
  tailscaled (pid 3120): 61 MiB RSS
  ОЗУ: свободно 83 MiB из 256 MiB
  переменные:
    GOMEMLIMIT=64MiB
    GODEBUG=madvdontneed=1
```

Посмотреть память позже: пункт 2 меню или `--mem`.

## Проверено

Чистый OpenWrt 25.12.6 (`apk`), пакет `tailscale` 1.104.1:

- `apk` определился автоматически, вместе с пакетом поставился `kmod-tun`;
- интерфейс, зона и forwarding созданы с первого запуска;
- ошибок нет.

В логе установки могут появляться строки — это нормально:

- `Program starting ... --cleanup` — штатный post-install пакета;
- `linuxfw: clear iptables: executable file not found` — на 24/25 firewall
  на nftables, чистить iptables нечего;
- `failed to look up link "tailscale0": Link not found` — интерфейс появится
  после первого `tailscale up`.

После настройки:

```sh
tailscale up
tailscale status
ip link show tailscale0
```

## Важно

- скрипт **идемпотентен**: если интерфейс, зона или forwarding уже есть,
  он их не дублирует, а только приводит параметры к нужным;
- `network reload` и `firewall reload` кратко прерывают сеть — это нормально
  для настройки;
- при установке на OpenWrt 24 используется `opkg`, на 25 — `apk`;
  имя пакета в обоих случаях `tailscale`;
- память настраивается там же: пункт 3 меню или `--tune`
  (на 256 МБ обязательно); пункт 4 или `--tune-restore` — откат;
- после установки проверка:

  ```sh
  tailscale status
  uci show network | grep tailscale
  uci show firewall | grep -A8 "name='tailscale'"
  ```
