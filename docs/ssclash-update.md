# Обновление ядра Mihomo в SSClash-Go

Памятка: как обновить ядро `clash`/Mihomo на роутере с SSClash-Go и что
делать, если распаковка падает с `Text file busy`.

Установка SSClash-Go и SSClash 4 с зеркалами — `docs/ssclash-install.md`.

## Симптом

Скрипт обновления скачивает новый бинарь, останавливает службу, но при
распаковке получает:

```
[+] Распаковка в /opt/clash/bin/clash...
ash: can't create /opt/clash/bin/clash: Text file busy
[X] Ошибка распаковки
```

В логе перед этим видно, что остановился не тот сервис:

```
clash[6246]: Stopping Clash service...
clash-rules[6267]: Stopping Clash rules script
```

## Причина

На роутере могут одновременно лежать два init-скрипта:

| Скрипт | Что это |
|---|---|
| `/etc/init.d/clash` | легаси SSClash 4, обычно отключён |
| `/etc/init.d/ssclash` | SSClash-Go, он и управляет ядром |

Скрипт обновления находит первый (`/etc/init.d/clash`) и останавливает
его, а реальная служба — `ssclash`. Ядро `clash` при этом продолжает
работать **дочерним процессом** `ssclash serve`:

```
13129  /opt/clash/bin/ssclash serve
 9146  /opt/clash/bin/clash -d /opt/clash
```

Пока процесс исполняет файл, заменить его нельзя — отсюда `Text file busy`.

Проверить, кто на самом деле держит бинарь:

```sh
ps w | grep -E 'clash|ssclash' | grep -v grep
for p in /proc/[0-9]*; do
    t=$(readlink "$p/exe" 2>/dev/null)
    case "$t" in *clash*) echo "$p -> $t" ;; esac
done
```

## Правильное обновление

Остановить именно SSClash-Go, убедиться, что ядро завершилось, и только
потом запускать обновлятор:

```sh
/etc/init.d/ssclash stop
sleep 2
pidof clash          # должно быть пусто
# запустить скрипт обновления
/etc/init.d/ssclash start
```

Если `pidof clash` всё равно что-то показывает:

```sh
kill $(pidof clash)
sleep 2
pidof clash && kill -9 $(pidof clash)
```

## Ручная замена ядра

Если скрипт уже скачал архив в `/tmp/clash.gz`:

```sh
/etc/init.d/ssclash stop
sleep 2
pidof clash || echo "ядро остановлено"

gzip -t /tmp/clash.gz                       # проверить архив
gunzip -c /tmp/clash.gz > /tmp/clash.new
chmod 755 /tmp/clash.new
/tmp/clash.new -v                           # проверить версию

cp /opt/clash/bin/clash /opt/clash/bin/clash.bak
mv /tmp/clash.new /opt/clash/bin/clash

/etc/init.d/ssclash start
sleep 5
pidof clash
/opt/clash/bin/clash -v
```

Проверка через API (секрет лежит в `/opt/clash/.ssclash/session.secret`):

```sh
SECRET=$(cat /opt/clash/.ssclash/session.secret)
curl -s -H "Authorization: Bearer $SECRET" http://127.0.0.1:9090/version
```

Должно вернуться что-то вроде:

```json
{"meta":true,"version":"v1.19.34"}
```

И проверить, что правила снова применены:

```sh
nft list ruleset | grep -i clash
ip rule show
logread -e ssclash | tail
```

## Чтобы обновлятор не путался

Легаси-скрипт отключён и не используется, но обновлятор его находит.
Можно убрать его из `/etc/init.d/`:

```sh
mv /etc/init.d/clash /etc/init.d/clash.off
```

После этого обновлятор будет выбирать `ssclash`. Вернуть обратно:

```sh
mv /etc/init.d/clash.off /etc/init.d/clash
```

## Откат

```sh
/etc/init.d/ssclash stop
mv /opt/clash/bin/clash /opt/clash/bin/clash.new
mv /opt/clash/bin/clash.bak /opt/clash/bin/clash
/etc/init.d/ssclash start
```

## Проверено

- GL.iNet GL-MT6000, OpenWrt 25.12.5, SSClash-Go 7.6.0;
- обновление `v1.19.33` → `v1.19.34`: скрипт падал с `Text file busy`,
  после остановки `ssclash` и ручной замены ядро поднялось;
- API отвечает `v1.19.34`, правила `table inet clash` и tproxy
  `127.0.0.1:7894` на месте, трафик идёт через группы.
