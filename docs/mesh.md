# roamd: роуминг Wi-Fi и Mesh

Памятка: как поставить [roamd](https://github.com/Ground-Zerro/roamd) —
демон бесшовного роуминга Wi-Fi для OpenWrt — из зеркала в этом
репозитории, без подключения чужого репозитория и без прямых
запросов к GitHub Releases.

Скрипт: `scripts/install-mesh.sh` (личный, в README не афишируется).

## Что делает

1. Определяет ветку OpenWrt и архитектуру:
   - ветки — только **24.10** и **25.12**;
   - архитектура берётся из `DISTRIB_ARCH` (`aarch64_cortex-a53`,
     `mipsel_24kc` и т.д.).
2. Выбирает пакеты:

   | Пакет | Назначение |
   |---|---|
   | `roamd` | демон роуминга (band steering, 802.11k/v/r) |
   | `luci-app-roamd` | страница **Сеть → Роуминг Wi-Fi** |
   | `luci-i18n-roamd-ru` | русский перевод |

3. Скачивает их из зеркала по очереди: jsDelivr → raw.githubusercontent
   → github.com/raw → официальный релиз.
4. Сверяет `sha256` по манифесту `third_party/roamd/SHA256SUMS`.
5. Ставит локально через `apk` (25.12) или `opkg` (24.10).
6. Включает автозапуск и перезапускает службу `roamd`.

Перед установкой проверяются:

- свободное место во флеш-памяти — не меньше 2 МБ;
- конфликты: если стоят `usteer` или `dawn`, скрипт откажется
  ставить roamd, потому что они мешают друг другу;
- вариант `wpad`: если стоит `wpad-basic-*`, `wpad-mini` или `wpad`
  без SAE, скрипт предложит заменить его на `wpad-mbedtls`
  (см. раздел ниже).

## Требуется полный wpad

roamd включает 802.11v и прописывает в `/etc/config/wireless`:

```uci
option bss_transition '1'
option wnm_sleep_mode '1'
```

`wpad-basic-*` этого не умеет, и hostapd не поднимает точки доступа:

```
Line 79: unknown configuration item 'bss_transition'
Line 80: unknown configuration item 'wnm_sleep_mode'
hostapd.add_iface failed for phy phy0 ifname=phy0-ap0
```

Снаружи это выглядит так:

- сеть создана, но в **Сеть → Беспроводная сеть** у неё «отключено»;
- в **Сеть → Роуминг Wi-Fi** — «Радиоинтерфейсы не найдены»;
- SSID не вещается.

Нужен полный пакет **`wpad-mbedtls`**: в нём есть и 802.11v, и SAE
(WPA3). Важно: в OpenWrt 25.12 пакет с именем просто `wpad` — это
полный 802.1X/RADIUS-вариант **без SAE**, для режима `sae-mixed` он
не подходит:

```
unknown configuration item 'sae_password_file'
invalid key_mgmt 'SAE'
```

Замена:

```sh
# OpenWrt 25.12 (apk)
apk del wpad-basic-mbedtls
apk add wpad-mbedtls

# OpenWrt 24.10 (opkg)
opkg remove wpad-basic-mbedtls
opkg install wpad-mbedtls

/etc/init.d/wpad restart
wifi up
```

Если замена не помогла, проверить:

```sh
iw dev                                  # должны быть phy0-ap0, phy1-ap0 с ssid
logread | grep hostapd | tail -20       # не должно быть unknown configuration item
ubus call network.wireless status       # "up": true, "disabled": false
```

## Запуск

```sh
wget -O /tmp/install-mesh.sh https://raw.githubusercontent.com/k4reon/k4reon-mihomo-rules/main/scripts/install-mesh.sh && sh /tmp/install-mesh.sh
```

Меню:

```
========================================
 roamd: роуминг Wi-Fi
========================================
 устройство: GL.iNet GL-MT6000
 OpenWrt 25.12.5, aarch64_cortex-a53
 пакет: apk
 статус: установлен 1.2.0-r2

Что сделать?
  1) Установить / обновить roamd
  2) Доустановить русский перевод
  3) Проверить состояние
  4) Удалить roamd
  0) Выйти
```

Без вопросов:

```sh
sh /tmp/install-mesh.sh --yes        # установить / обновить
sh /tmp/install-mesh.sh --status     # состояние
sh /tmp/install-mesh.sh --uninstall  # удалить
sh /tmp/install-mesh.sh --dry-run    # только план
```

Пункт 1 ставит всё сразу: демон, LuCI-приложение и перевод.
Пункт 2 нужен, если перевод не встал или его удалили отдельно.

Повторный запуск безопасен: если версии совпадают, скрипт пишет
«обновлять нечего» и ничего не трогает.

## Удаление

Пункт 4 (или `--uninstall`) сначала предупреждает и спрашивает `[y/N]`,
затем удаляет пакеты. Конфиг `/etc/config/roamd` по умолчанию
**остаётся**; после удаления пакетов скрипт отдельно спрашивает,
удалять ли его.

С `--yes` подтверждения пропускаются, конфиг сохраняется.

## Зеркало

```
third_party/roamd/
├── 24.10/      # 102 ipk
├── 25.12/      # 100 apk
├── SHA256SUMS
└── LICENSE
```

Пакеты взяты из релиза `v1.2.0-r1` без изменений. Лицензия Apache-2.0,
автор — Ground-Zerro. Подробности и порядок обновления —
`third_party/roamd/README.md`.

Если архитектуры нет в зеркале, скрипт попробует официальный релиз
(для этого нужен доступ к GitHub, например через VPN), а если и там
нет — завершится с ошибкой и ничего не поставит.

## Проверено

- GL.iNet GL-MT6000, OpenWrt 25.12.5, `aarch64_cortex-a53`, `apk`;
- netis NX30 V2, OpenWrt 25.12.6, `aarch64_cortex-a53`, `apk`:
  с `wpad-basic-mbedtls` сеть создавалась, но точки доступа не
  поднимались; после замены на `wpad-mbedtls` SSID поднялся на
  2,4 и 5 ГГц;
- `--status` показывает пакеты, wpad, автозапуск, службу и конфиг;
- `--dry-run` на установленной версии отвечает «обновлять нечего»;
- пакеты из зеркала скачиваются с правильными `sha256`.
