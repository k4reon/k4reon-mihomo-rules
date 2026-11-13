# roamd — зеркало пакетов

Личное зеркало [roamd](https://github.com/Ground-Zerro/roamd) — демона
роуминга Wi-Fi и Mesh для OpenWrt. Нужно, чтобы установка не зависела
от доступа к GitHub Releases.

| | |
|---|---|
| Автор | Ground-Zerro |
| Источник | https://github.com/Ground-Zerro/roamd |
| Версия | 1.2.0 (релиз `v1.2.0-r1`, 2026-09-23) |
| Лицензия | Apache-2.0 (`LICENSE`) |

## Что лежит

```
third_party/roamd/
├── LICENSE
├── SHA256SUMS
├── 24.10/   # ipk для OpenWrt 24.10 (102 файла)
└── 25.12/   # apk для OpenWrt 25.12 (100 файлов)
```

Имена файлов повторяют оригинальные:

- `24.10-<архитектура>-roamd_1.2.0-r2_<архитектура>.ipk`
- `24.10-<архитектура>-luci-app-roamd_1.2.0-r1_all.ipk`
- `24.10-<архитектура>-luci-i18n-roamd-ru_1.2.0-r1_all.ipk`
- `25.12-<архитектура>-roamd-1.2.0-r2.apk`
- `25.12-<архитектура>-luci-app-roamd-1.2.0-r1.apk`
- `25.12-<архитектура>-luci-i18n-roamd-ru-1.2.0-r1.apk`

Пакеты не изменены. Целостность проверяется по `SHA256SUMS`.

## Обновление

1. Скачать новые пакеты из
   [релиза roamd](https://github.com/Ground-Zerro/roamd/releases).
2. Заменить каталоги `24.10/` и `25.12/`.
3. Пересобрать `SHA256SUMS`:

   ```sh
   cd third_party/roamd
   ( cd 24.10 && sha256sum * ) > SHA256SUMS
   ( cd 25.12 && sha256sum * ) >> SHA256SUMS
   ```

4. Обновить версию в `scripts/install-mesh.sh` и в этой таблице.
