# SSClash 4 — зеркало пакетов

Личное зеркало [SSClash 4](https://github.com/zerolabnet/SSClash) — старой
LuCI-версии SSClash (Services → SSClash). Нужно, чтобы установка не
зависела от доступа к GitHub Releases.

| | |
|---|---|
| Автор | zerolabnet |
| Источник | https://github.com/zerolabnet/SSClash |
| Версия | 4.7.1 (релиз `v4.7.1`) |
| Лицензия | GPL-2.0 (`LICENSE`) |

## Файлы

| Файл | Формат | Размер | sha256 |
|---|---|---|---|
| `luci-app-ssclash-4.7.1-r1.apk` | OpenWrt 25.12 (apk) | 1 934 692 | `e8d4f416654792e7541442eb91b751c38d534448301e0c8706bf6f5c6d18074d` |
| `luci-app-ssclash_4.7.1-r1_all.ipk` | OpenWrt 24.10 и 23.05 (opkg) | 1 936 126 | `b61c19cd752013208e50107359ad782560b46e554045985e7a2cc3e0182d11f5` |

Пакеты не изменены. Целостность проверяется по `SHA256SUMS`.

Ядро Mihomo в зеркало не входит: оно ставится скриптом
`scripts/install-ssclash.sh` отдельно (общий файл для Go и SSClash 4).

## Обновление

1. Скачать новые `.apk`/`.ipk` из
   [релиза SSClash](https://github.com/zerolabnet/SSClash/releases).
2. Заменить файлы, обновить таблицу и `SHA256SUMS`:

   ```sh
   cd third_party/ssclash4
   sha256sum *.apk *.ipk > SHA256SUMS
   ```

3. Обновить версию и sha256 в `scripts/install-ssclash.sh`.
