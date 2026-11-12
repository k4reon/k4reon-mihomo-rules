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
6. применяет настройки (`uci commit`, `reload network/firewall`);
7. предлагает ввести auth key и выполнить `tailscale up`
   (с вопросом про MagicDNS: по умолчанию DNS Tailscale выключен).

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
  2) Только настроить интерфейс/firewall
  3) Подключить к tailnet (auth key)
  0) Выйти
Выбор [1]:
```

Enter — установить и настроить. В конце скрипт попросит auth key:

- вставить ключ — выполнит `tailscale up --auth-key=...`;
- нажать Enter — пропустить, потом вручную `tailscale up` (покажет ссылку для входа).

## Без вопросов

```sh
sh /tmp/tailscale-install.sh --yes       # установить и настроить
sh /tmp/tailscale-install.sh --dry-run   # только показать план
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
