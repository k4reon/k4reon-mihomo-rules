# Lite-профили SSClash-Go

Конфиги для слабых роутеров (256 МБ RAM / 44–128 МБ flash):
Netis NX30, Xiaomi AX3000T, Cudy WR3000S/E и подобные.

**Статус:** `lite-direct` проверен на Cudy WR3000S; `lite-proxy` — тестовый.

## Что изменено относительно полных профилей

1. **Нет геоданных.**
   - `geo-auto-update: false`;
   - убран `geox-url`;
   - `GEOIP,RU` / `GEOIP,SU` заменены на `RULE-SET,k4reon-ru-ip`;
   - `geosite:category-ru` в `nameserver-policy` заменён на обычные маски
     `'+.ru'`, `'+.su'`, `'+.xn--p1ai'`, `'+.xn--p1acf'`, `'+.moscow'`,
     `'+.tatar'`.

   В результате не нужны `geoip.metadb` (8 МБ) и `GeoSite.dat` (4,2 МБ).

2. **RU IP-список.** Добавлен провайдер `k4reon-ru-ip`:

   ```yaml
   type: http, behavior: ipcidr, format: text, proxy: DIRECT
   url: https://www.ipdeny.com/ipblocks/data/aggregated/ru-aggregated.zone
   ```

3. **Обновление провайдеров** — раз в сутки (`interval: 86400` вместо `43200`).

4. **Списки правил не упрощались**: те же категории, что в полных профилях.

## Чем отличается PROXY и DIRECT

- `PROXY.yaml` — полный набор правил, включая RU-IP и Google direct;
- `DIRECT.yaml` — без RU/private/torrent/google/custom-direct, как и раньше:
  всё остальное закрывает `MATCH,DIRECT`.

## Что проверить на роутере

1. **Конфиг запускается**, в логе нет ошибок про geoip/geosite.
2. **RU-сайты идут напрямую** — например, `2ip.ru` показывает российский IP.
3. **YouTube, Discord, AI, мессенджеры, игры** — идут через свои группы.
4. **Google** в PROXY-профиле открывается напрямую (российский IP).
5. **DNS для `.ru`** работает: `nslookup yandex.ru` через DNS mihomo
   (`127.0.0.1:7874`) отдаёт ответ.
6. **Память и место**:

   ```sh
   free -m
   df -h /overlay
   du -sh /opt/clash
   ls -l /opt/clash/*.dat /opt/clash/*.metadb 2>/dev/null
   ```

   Файлов `GeoSite.dat` / `geoip.metadb` быть не должно — их можно
   удалить перед тестом.

## Ожидаемая экономия

- flash: **−12,2 МБ** (8 МБ geoip + 4,2 МБ geosite);
- RAM: ориентировочно 10–25 МБ за счёт отказа от geo-матчеров;
- трафик: нет ежедневной загрузки 12 МБ геоданных.

## Известные риски

- `GEOIP,SU` убран: legacy-адреса бывшего СССР могут уйти в `MATCH`
  (в PROXY-профиле — через прокси). Если это критично, вернём `GEOIP,SU`
  и geoip-файл.
- `k4reon-ru-ip` тянется с `ipdeny.com` напрямую; если сайт недоступен,
  список не обновится, но правило продолжит работать с прошлой копией.
- Маски `'+.ru'` в DNS-политике должны вести себя как `geosite:category-ru`;
  это надо подтвердить на тесте.

## Откат

Вернуть полные конфиги:

```
configs/ssclash-go/PROXY.yaml
configs/ssclash-go/DIRECT.yaml
```
