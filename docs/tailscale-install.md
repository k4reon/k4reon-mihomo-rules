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
  2) Проверить, установлен ли Tailscale
  3) Остановить Tailscale и выйти (logout)
  0) Выйти
```

При выборе 1 — скрипт все установит и настроит. В конце напишет:
`Дальше подключитесь сами: tailscale up`.

Пункт 2 (или `--status`) ничего не меняет — показывает: установлен ли
пакет, включён ли автозапуск, запущен ли процесс, есть ли интерфейс,
зона и forwarding, и подключён ли tailnet (без списка устройств).

Пункт 3 — остановить Tailscale и выполнить logout. Сначала выводится
предупреждение, что устройство пропадёт из tailnet, и запрос `[y/N]`.
Только после `y` выполняется `tailscale logout` и остановка службы.

## Без вопросов

```sh
sh /tmp/tailscale-install.sh --yes       # установить и настроить
sh /tmp/tailscale-install.sh --dry-run   # только показать план
sh /tmp/tailscale-install.sh --status    # проверить, установлен ли Tailscale
sh /tmp/tailscale-install.sh --stop --yes  # остановить и выйти (logout)
```

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
- отдельно можно ограничить память Tailscale скриптом
  `scripts/tailscale-tune.sh` (на 256 МБ рекомендуется);
- после установки проверка:

  ```sh
  tailscale status
  uci show network | grep tailscale
  uci show firewall | grep -A8 "name='tailscale'"
  ```
