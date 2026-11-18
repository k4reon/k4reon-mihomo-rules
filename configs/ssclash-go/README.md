# Профили SSClash-Go

В папке четыре профиля — по два на каждый режим:

| Файл | Правила | Геоданные | Для чего |
|---|---|---|---|
| `full-proxy.yaml` | `MATCH,AUTO` | `geoip` / `geosite` | роутер с запасом флеша |
| `full-direct.yaml` | `MATCH,DIRECT` | `geoip` / `geosite` | всё напрямую |
| `lite-proxy.yaml` | `MATCH,AUTO` | без геоданных | 44–128 МБ флеша |
| `lite-direct.yaml` | `MATCH,DIRECT` | без геоданных | 44–128 МБ флеша |

## Чем lite отличается от full

1. **Нет геоданных.**
   - `geo-auto-update: false`, убран `geox-url`;
   - `GEOIP,RU` заменён на `RULE-SET,k4reon-ru-ip`;
   - `geosite:category-ru` в `nameserver-policy` заменён на маски
     `'+.ru'`, `'+.su'`, `'+.xn--p1ai'`, `'+.xn--p1acf'`, `'+.moscow'`,
     `'+.tatar'`.

   В результате не нужны `geoip.metadb` (8 МБ) и `GeoSite.dat` (4,2 МБ).

2. **RU IP-список.** Добавлен провайдер `k4reon-ru-ip`:

   ```yaml
   type: http, behavior: ipcidr, format: text, proxy: DIRECT
   url: https://www.ipdeny.com/ipblocks/data/aggregated/ru-aggregated.zone
   ```

3. **Обновление провайдеров** — раз в 6 часов (`interval: 21600`).

4. **Списки правил не упрощались**: те же категории, что в полных профилях.

## Чем отличается PROXY и DIRECT

- `*-proxy.yaml` — полный набор правил, включая RU-IP и Google direct;
- `*-direct.yaml` — без RU/private/torrent/google/custom-direct:
  всё остальное закрывает `MATCH,DIRECT`.

## Что проверить на роутере

1. **Конфиг запускается**, в логе нет ошибок про geoip/geosite.
2. **RU-сайты идут напрямую** — например, `2ip.ru` показывает российский IP.
3. **YouTube, Discord, AI, мессенджеры, игры** — идут через свои группы.
4. **Google** в PROXY-профиле открывается напрямую (российский IP).
5. **DNS для `.ru`** работает: `nslookup yandex.ru` через DNS mihomo.
6. **Память и место**:

   ```sh
   free -m
   df -h /overlay
   du -sh /opt/clash
   ls -l /opt/clash/*.dat /opt/clash/*.metadb 2>/dev/null
   ```

   В lite-профилях файлов `GeoSite.dat` / `geoip.metadb` быть не должно.

## Ожидаемая экономия lite

- flash: **−12,2 МБ** (8 МБ geoip + 4,2 МБ geosite);
- RAM: ориентировочно 10–25 МБ за счёт отказа от geo-матчеров;
- трафик: нет обновления геоданных.

## Известные риски

- `GEOIP,SU` убран: legacy-адреса бывшего СССР могут уйти в `MATCH`
  (в PROXY-профиле — через прокси).
- `k4reon-ru-ip` тянется с `ipdeny.com` напрямую; если сайт недоступен,
  список не обновится, но правило продолжит работать с прошлой копией.
- Маски `'+.ru'` в DNS-политике должны вести себя как `geosite:category-ru`;
  на практике подтверждено на Cudy WR3000S.

## Статус

`lite-direct` проверен на Cudy WR3000S (44 МБ флеша), `lite-proxy` —
тестовый. Полные профили проверены на GL-MT6000.

## SSClash 4

Те же четыре профиля лежат в `configs/ssclash-4/` — отличие только в блоке
контроллера и UI (`external-controller`, `external-ui`).
