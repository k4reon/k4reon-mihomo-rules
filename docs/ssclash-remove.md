# Удаление SSClash

Памятка: как полностью удалить SSClash-Go и SSClash (legacy) с роутера.
Команды взяты из официальных README проектов.

## Перед удалением

Если включён **Kill switch**, сначала выключите его в веб-интерфейсе
(Настройки → Options) и нажмите **Save & Apply**. Иначе на роутере
останутся правила firewall, блокирующие выход в интернет.

## SSClash-Go — OpenWrt

```sh
/etc/init.d/ssclash stop
/etc/init.d/ssclash disable
rm -f /etc/init.d/ssclash
rm -rf /opt/clash
```

## SSClash-Go — Keenetic (Entware)

```sh
/opt/etc/init.d/S99ssclash stop
rm -f /opt/etc/init.d/S99ssclash
rm -f /opt/etc/ndm/netfilter.d/50-ssclash.sh
rm -rf /opt/clash
```

## SSClash (legacy, LuCI) — OpenWrt

```sh
# OpenWrt >= 25 (apk)
apk del luci-app-ssclash

# OpenWrt < 25 (opkg)
opkg remove luci-app-ssclash

rm -rf /opt/clash
```

## После удаления

- `rm -rf /opt/clash` удаляет конфиги, подписки, кэш правил и секрет API.
  Если что-то нужно сохранить — сделайте копию заранее;
- перезагрузка не обязательна, но полезна, чтобы сбросить остатки
  firewall-правил, ip rule и маршрутизации;
- SSClash (legacy) на Keenetic не ставится — это LuCI-пакет для OpenWrt.

Источники:

- [SSClash-Go](https://github.com/zerolabnet/SSClash-Go) — раздел «Удаление»;
- [SSClash](https://github.com/zerolabnet/SSClash) — раздел «Remove Clash».
