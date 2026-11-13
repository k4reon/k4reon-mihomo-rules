# Тема LuCI Proton2025: установка и брендинг

Памятка: как поставить тёмную тему Proton2025 на роутер и включить
на странице входа свой логотип и название `k4reon.com`.

Скрипт: `scripts/install-theme.sh` (личный, в README не афишируется).

## Что делает

1. Ставит пакет `luci-theme-proton2025` (`apk` или `opkg`) из зеркала
   в этом репозитории, с запасными источниками и проверкой `sha256`.
2. Скачивает логотип `docs/images/login-logo.png`.
3. Кладёт логотип в UCI как `data:image/png;base64,...` и включает
   брендинг страницы входа.
4. Применяет оформление: тёмная тема, оранжевый акцент, анимация
   входа `circuit`, без фонового узора.
5. Переключает LuCI на тему и перезапускает `rpcd`/`uhttpd`.

Подключение к интернету и обновление остальных пакетов не трогается.

## Запуск

```sh
wget -O /tmp/install-theme.sh https://raw.githubusercontent.com/k4reon/k4reon-mihomo-rules/main/scripts/install-theme.sh && sh /tmp/install-theme.sh
```

Меню:

```
1) Установить тему и брендинг
2) Только брендинг (логотип и название)
3) Проверить состояние
0) Выйти
```

Без вопросов:

```sh
sh /tmp/install-theme.sh --yes        # тема + брендинг
sh /tmp/install-theme.sh --branding   # только логотип и название
sh /tmp/install-theme.sh --status     # состояние
sh /tmp/install-theme.sh --dry-run    # только план
```

Повторный запуск безопасен: если пакет уже стоит, установка
пропускается, настройки просто приводятся к нужным.

## Брендинг

| Параметр | Значение |
|---|---|
| `login_branding` | `1` — включён |
| `login_name` | `k4reon.com` |
| `login_logo` | `data:image/png;base64,...` из `docs/images/login-logo.png` |
| `login_logo_only` | `0` — логотип и название вместе |
| `mode` | `dark` |
| `accent` | `orange` |
| `login_animation` | `circuit` |
| `background_pattern` | `none` |

Настройки лежат в `/etc/config/proton2025` и переживают обновление
темы. Логотип в UCI ограничен 300 000 символов base64, то есть
картинка примерно до 225 КБ; текущий файл — 177 КБ.

Поменять название или логотип можно и руками:

```sh
uci set proton2025.settings.login_name='k4reon.com'
uci commit proton2025
```

Логотип кодируется на роутере через `ucode` (функция `b64enc`),
поэтому отдельный пакет `base64` не нужен.

## Источники загрузки

Скрипт пробует по очереди:

1. `cdn.jsdelivr.net/gh/k4reon/k4reon-mihomo-rules@main/...`
2. `raw.githubusercontent.com/k4reon/k4reon-mihomo-rules/main/...`
3. `github.com/k4reon/k4reon-mihomo-rules/raw/main/...`
4. официальный релиз темы на GitHub (для пакета).

Перед установкой сверяется `sha256`. Если все источники недоступны —
скрипт завершается с ошибкой и ничего не ставит.

## Обновление темы

1. Скачать новые `.apk`/`.ipk` из релиза
   [luci-theme-proton2025](https://github.com/ChesterGoodiny/luci-theme-proton2025/releases).
2. Заменить файлы в `third_party/proton2025/`.
3. Обновить версию и `sha256` в `scripts/install-theme.sh`
   и таблицу в `third_party/proton2025/README.md`.
4. Закоммитить.

На роутере достаточно снова запустить `install-theme.sh --yes`.

## Удаление

Официальный способ:

```sh
wget -qO- https://raw.githubusercontent.com/ChesterGoodiny/luci-theme-proton2025/main/uninstall.sh | sh
```

Он возвращает стоковую тему, удаляет пакет и `/etc/config/proton2025`
(вместе с брендингом). Перед удалением при необходимости сохраните
настройки: **System → System → Language and Style → Tools → Backup**.

## Лицензия и авторство

Тема распространяется по Apache-2.0 (+ MIT для анимации `fluid`).
Автор — ChesterGoodiny. Пакеты в `third_party/proton2025/` не изменены,
рядом лежат `LICENSE`, `NOTICE` и `MIT-fluid.txt`.

Логотип и название — свои, к теме отношения не имеют.

## Проверено

- MT6000, OpenWrt 25.12.5, тема 1.4.5-r1 (`apk`);
- `--status` показывает пакет, активную тему, брендинг и размер логотипа;
- `--branding` применяет логотип и название, страница входа
  открывается после `Ctrl+F5`.
