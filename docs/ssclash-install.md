# SSClash: установка SSClash-Go или SSClash 4

Памятка: как поставить SSClash на OpenWrt без доступа к GitHub на
роутере — на выезде, без ПК и без VPN.

> **Статус: в разработке.** SSClash 4 ставится из зеркала и работает
> без VPN. SSClash-Go зависит от доступа к GitHub: бесплатные прокси
> сейчас слишком медленные (сотни байт в секунду), поэтому для установки
> на выезде надёжнее установщик с ПК (`ssclash/install.bat`) или будущее
> приватное зеркало с токеном.

Скрипт: `scripts/install-ssclash.sh` (личный, в README не афишируется).

## Две версии

| | SSClash-Go | SSClash 4 |
|---|---|---|
| Интерфейс | веб на `:9091` | LuCI → Services → SSClash |
| Пакет | один бинарник | `luci-app-ssclash` |
| Лицензия | закрытая, перепубликация запрещена | GPL-2.0 |
| Откуда ставится | официальные ссылки через зеркала-прокси | зеркало в этом репозитории |

Обе версии используют один каталог `/opt/clash`, поэтому **вместе они
не работают**. Скрипт это видит и предлагает удалить текущую версию
перед установкой другой.

## Автоопределение

Ничего указывать не нужно:

- читается `/etc/openwrt_release`;
- `23.05` и `24.10` → `opkg` и `.ipk`;
- `25.12` → `apk` и `.apk`;
- архитектура — `aarch64` → `arm64` (пока только она);
- проверяется, что уже установлено: Go (`/opt/clash/bin/ssclash`,
  `/etc/init.d/ssclash`) или SSClash 4 (`luci-app-ssclash`).

## Запуск

```sh
wget -O /tmp/install-ssclash.sh https://raw.githubusercontent.com/k4reon/k4reon-mihomo-rules/main/scripts/install-ssclash.sh && sh /tmp/install-ssclash.sh
```

Главное меню:

```
========================================
 SSClash: установка и обновление
========================================
 устройство: GL.iNet GL-MT6000
 OpenWrt 25.12.5, aarch64_cortex-a53
 установлено: SSClash-Go v7.7.0 (ядро v1.19.34)

Что установить?
  1) SSClash-Go — новая версия, веб-интерфейс :9091
  2) SSClash 4 — LuCI, Services → SSClash
  0) Выйти
```

Для SSClash-Go:

```
  1) Установить / обновить всё
  2) Обновить только клиент
  3) Обновить только ядро Mihomo
  4) Проверить состояние
  5) Удалить SSClash-Go
  0) Назад
```

Для SSClash 4:

```
  1) Установить / обновить
  2) Обновить только ядро Mihomo
  3) Проверить состояние
  4) Удалить SSClash 4
  0) Назад
```

## Без вопросов

```sh
sh /tmp/install-ssclash.sh --go --yes            # SSClash-Go целиком
sh /tmp/install-ssclash.sh --go --client --yes   # только клиент
sh /tmp/install-ssclash.sh --go --core --yes     # только ядро
sh /tmp/install-ssclash.sh --ss4 --yes           # SSClash 4
sh /tmp/install-ssclash.sh --status              # состояние
sh /tmp/install-ssclash.sh --dry-run --go        # только план
sh /tmp/install-ssclash.sh --ss4 --uninstall     # удалить
```

## Откуда качается

**SSClash 4** — из зеркала `third_party/ssclash4/`:

1. jsDelivr;
2. raw.githubusercontent;
3. github.com/raw;
4. официальный релиз.

Файлы не изменены, `sha256` проверяется.

**SSClash-Go** — только официальные ссылки, но с обходом недоступного
GitHub:

1. `github.com/zerolabnet/SSClash-Go/releases/...`;
2. `ghproxy.net`;
3. `gh-proxy.com`;
4. `ghfast.top`.

Свойства:

- версии зашиты в скрипт: Go `7.7.1`, ядро `v1.19.34`;
- `sha256` клиента, init-скрипта и ядра проверяется обязательно;
- перепубликации нет — лицензия SSClash-Go это запрещает.

**Ядро Mihomo** — с официального релиза MetaCubeX через те же прокси.

## Установка и замена ядра

Порядок для обеих версий:

1. скачать во `/tmp`;
2. проверить `sha256`;
3. остановить службу и остатки ядра (иначе `Text file busy`);
4. распаковать новое ядро во временный файл, проверить `-v`;
5. заменить `/opt/clash/bin/clash`;
6. запустить службу (для Go) или оставить выключенной (для SSClash 4).

SSClash 4 после установки остаётся выключенным: открой LuCI →
**Services → SSClash**, проверь настройки и запусти.

## Переключение версий

Если установлена одна версия, а ставится другая, скрипт пишет:

```
Установлен SSClash-Go. Вместе с SSClash 4 они не работают.
Удалить SSClash-Go и продолжить? [y/N]
```

При `y` удаляется клиент и служба прежней версии, `/opt/clash`
с конфигом сохраняется. С `--yes` подтверждение не спрашивается.

## Удаление

- Go: останавливается служба, удаляются `/etc/init.d/ssclash` и
  `/opt/clash/bin/ssclash`;
- SSClash 4: удаляется пакет `luci-app-ssclash` и init-скрипт;
- отдельно спрашивается, удалять ли `/opt/clash` (конфиг, подписки,
  ядро).

## Если файлы уже скачаны на ПК

```sh
sh /tmp/install-ssclash.sh --go --yes --from /tmp/ssclash-files
```

В каталоге должны лежать:

- `ssclash-linux-arm64`
- `ssclash-openwrt-service.tar.gz`
- `mihomo-linux-arm64-v1.19.34.gz`

Для SSClash 4 — пакет `.apk`/`.ipk` под свою ветку.

## Проверено

- GL.iNet GL-MT6000, OpenWrt 25.12.5, `aarch64_cortex-a53`, `apk`;
- `--status`: определены обе версии, ядро `v1.19.34`, службы
  различаются корректно;
- `--dry-run --go` и `--dry-run --ss4`: показывают план и
  предупреждение о конфликте, ничего не меняют;
- `--go --uninstall --dry-run`: показывает план удаления.
