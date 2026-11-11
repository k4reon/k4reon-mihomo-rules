# Mihomo SSClash

> Материал перенесён из Notion.

> Источник: https://ssclash.notion.site/Mihomo-SSClash-15989188f6b48051a97fc887adea736a

Точечный обход блокировок на OpenWrt (и немного на Keenetic)
VPN на роутере с поддержкой подписок, обход блокировок мобильной связи по белым спискам, любые интерфейсы и протоколы, VLESS, AWG2.0, HY2, правила маршрутизации по спискам, IP и доменам.
19.08.2026: Новый SSClash-go ‣

## Установка SSClash 4 на OpenWrt

Super Simple Clash от Zerolab.net

## 1. Скриптом из терминала на роутере:

Скрипт сам опередлит версию OpenWrt, скачает нужные утилиты и зависимости, поставит luci-app-ssclash и ядро Mihomo для архитектуры вашего роутера или обновит:

```Bash
wget --no-proxy -qO- https://github.com/zerolabnet/SSClash/raw/refs/heads/main/install-ssclash.sh | ash
```

## 2. Вручную мышкой:

1. Скачать свежую ‣
1. Веб интерфейс → Software → Update lists → Upload Package установить скачанный файл .ipk или .apk c —allow-untrusted
1. В фильтре ищем и ставим coreutils-base64, kmod-tun, а также kmod-nft-tproxy для OpenWrt 23-24 или iptables-mod-tproxy для древних OpenWrt.
1. Выходим из админки Log out и заходим снова, появляется меню Services → SSClash
1. SSClash → вкладка Settings → внизу скачать ядро Mihomo Download Core
1. Вместо TPROXY выбрать Mixed (TCP+UDP)
1. Если используете подписки с модемом на белых спиках, лучше отключить Store rules and proxy providers in RAM (tmpfs)
1. По мануалу настраиваем, а всё, что ниже, можно не читать.

## 3. Вручную клавиатурой:

Для выполнения команд, подключитесь к вашему роутеру по SSH (например, через Termius, Putty или командную строку Windows). Установите ваш часовой пояс и синхронизируйте время на роутере!

### Что такое SSH?

Скачайте Termius, он удобный и красивый. Там создайте подключение к вашему роутеру.
Нажмите кнопочку NEW HOST
Address 192.168.1.1 (обычно это IP адрес вашего роутера по умолчанию, у вас может быть другой).

> 

  Чтобы узнать адрес своего роутера, можно в Termius открыть TERMINAL и ввести там ipconfig /all
username root
password - пароль от админки вашего роутера (если вы не задавали, то скорее всего он пустой)
Connect

![image](https://prod-files-secure.s3.us-west-2.amazonaws.com/06a07c1f-d5e4-4915-bbbd-d00edd657e56/f1d75950-4c66-466e-b776-6eff994dd081/Screenshot_2024-12-17_210527.png)

Увидите что-то типа такого, скорее всего, текстовую ASCII картинку с надписью OpenWRT и предложение что-нибудь ввести. Вот тут и нужно вводить все эти команды для установки Super Simple Clash.
В Termius скопированные команды можно вставлять правой кнопкой мышки. Если вы ткнули не туда и у вас уже так не вставляется, для вставки можно нажимать на клавиатуре ctrl+shift+v

## OpenWrt 25.12.x

```Bash
apk update
apk add curl kmod-nft-tproxy kmod-tun coreutils-base64
curl -L https://github.com/zerolabnet/SSClash/releases/download/v4.7.0/luci-app-ssclash-4.7.0-r1.apk -o /tmp/luci-app-ssclash.apk
apk add /tmp/luci-app-ssclash.apk --allow-untrusted && rm -rf /tmp/*.apk
```

## OpenWRT 23.05.x - 24.10.x

```Shell
opkg update && opkg install curl kmod-nft-tproxy kmod-tun coreutils-base64
curl -L https://github.com/zerolabnet/SSClash/releases/download/v4.7.0/luci-app-ssclash_4.7.0-r1_all.ipk -o /tmp/luci-app-ssclash.ipk && opkg install /tmp/luci-app-ssclash.ipk && rm -rf /tmp/*.ipk
```

Для OpenWrt 21.x вместо kmod-nft-tproxy нужен iptables-mod-tproxy

## Ядро Mihomo

ARM64 (Mediatek Filogic: Xiaomi AX3000T, Routerich AX3000, RAX3000Me, Cudy TR3000, gl.inet GL-MT3000, MT6000, Huasifei WH3000 Pro и др):

```Bash
releasemihomo=$(curl -s -L https://github.com/MetaCubeX/mihomo/releases/latest | grep "title>Release" | cut -d " " -f 4)
curl -L https://github.com/MetaCubeX/mihomo/releases/download/$releasemihomo/mihomo-linux-arm64-$releasemihomo.gz -o /tmp/clash.gz
gunzip -c /tmp/clash.gz > /opt/clash/bin/clash
chmod +x /opt/clash/bin/clash
rm -rf /tmp/clash.gz
```

mipsel_24kc (Almond 3S, Netis N6 и подобные):

```Bash
releasemihomo=$(curl -s -L https://github.com/MetaCubeX/mihomo/releases/latest | grep "title>Release" | cut -d " " -f 4)
curl -L https://github.com/MetaCubeX/mihomo/releases/download/$releasemihomo/mihomo-linux-mipsle-softfloat-$releasemihomo.gz -o /tmp/clash.gz
gunzip -c /tmp/clash.gz > /opt/clash/bin/clash
chmod +x /opt/clash/bin/clash
rm -rf /tmp/clash.gz
```

AMD64 (x86 сборки OpenWrt для мини ПК):

```Bash
releasemihomo=$(curl -s -L https://github.com/MetaCubeX/mihomo/releases/latest | grep "title>Release" | cut -d " " -f 4)
curl -L https://github.com/MetaCubeX/mihomo/releases/download/$releasemihomo/mihomo-linux-amd64-compatible-$releasemihomo.gz -o /tmp/clash.gz
gunzip -c /tmp/clash.gz > /opt/clash/bin/clash
chmod +x /opt/clash/bin/clash
rm -rf /tmp/clash.gz
```

Ядра для других архитектур: https://github.com/MetaCubeX/mihomo/releases

Стандартный конфиг Clash нужно отредактировать, прописав хотя бы один рабочий сервер, а затем применить Save & Apply. Если в конфиге нет ошибок, Clash запустится и загорится зелёная надпись Clash is running, если есть ошибки, останется красная надпись Clash stopped, а в соседней вкладке Log можно почитать, что ему не нравится и попробовать исправить. Чтобы увидеть больше информации в логах, стартуйте Clash из консоли:

```Bash
service clash start
```

## За основу берите этот конфиг и редактируйте:

Конфигурация

## Установка SSClash-GO 6 - новая закрытая версия

‣

## Скриптом из терминала на роутере:

Скрипт сам опередлит версию OpenWrt, скачает нужные утилиты и зависимости, поставит ядро Mihomo для архитектуры вашего роутера или обновит:

```Bash
wget -T 30 -qO- https://github.com/zerolabnet/SSClash-Go/raw/refs/heads/main/install-ssclash-go.sh | ash
```

Заходите на ваш роутер IP:9091 - на этом порту висит новая админка, задаёте в первый раз на неё пароль, запоминаете и настраиваете дальше, как обычно. Сам сервис теперь лежит в /opt/clash/bin/ssclash
Стандартный конфиг Clash нужно отредактировать, прописав хотя бы один рабочий сервер, а затем применить Save & Reload. В верхней панельке должен отображаться статус Running, если нет, запустите сервис в первый раз вручную. Если не скачалось ядро Mihomo, его можно скачать из вкладки Settings - в самом низу.

> 

  Исходники этой версии не доступны, поэтому ставить или нет - решать вам.

## За основу берите этот конфиг и редактируйте:

Конфигурация

## Настройка конфигурации

> 

  Рекомендуется отключить IPv6 на роутере. В некоторых случаях он выдаёт ваше местоположение сервисам гугла, из-за этого могут не работать всякие Gemini.
Ядро Mihomo использует язык разметки YAML - важно соблюдать отступы и сохранять вложенность. Иногда недостающий пробел мешает запустить конфиг.
Для начала возьмите конфиг из примера, в &warp-common меняйте private-key на ваш, его можно сгенерировать здесь. Это ваш бесплатный Cloudflare WARP конфиг обфусцированный с помощью Amnezia 2.0, с ним можно ускорить YouTube и бесплатно открыть всё, что заблокировано внутри страны.
После тестов, обязательно настройте себе нормальный сервер c vless или купите одну из подписок, например, ASB, Furk, SouthNetworks, Ledokol, VME_Boost, Shadow, Burger. Бесплатные варианты, как правило, работают плохо.

> 

  WARP не может обойти блокировку ресурсов, доступ к которым возможен только из других стран, так как он не меняет страну! Для открытия ChatGPT, нужно зарегистрировать ProtonVPN и бесплатно создать дополнительный Wireguard конфиг, а затем пустить его цепочкой через WARP (просто подставьте значения в конфиг ниже).

## Конфиг без пояснений

В этом примере используются два бесплатных варианта обхода - WARP + ProtonVPN.

```YAML
mode: rule
ipv6: false
log-level: error
allow-lan: false
mixed-port: 7890
tproxy-port: 7894
unified-delay: true
tcp-concurrent: true
external-controller: 0.0.0.0:9090
external-ui: ./ui
external-ui-url: "https://github.com/Zephyruso/zashboard/releases/latest/download/dist-cdn-fonts.zip"

hosts:
  app.4pda.to: 31.131.253.250
  ntc.party: 130.255.77.28

dns:
  enable: true
  listen: 0.0.0.0:7874
  ipv6: false
  default-nameserver:
    - 9.9.9.9
    - 149.112.112.112
  nameserver:
    - https://dns.quad9.net/dns-query
    - https://dns10.quad9.net/dns-query
  nameserver-policy:
    "+.lan": system
    "msftconnecttest.com": system
    "msftncsi.com": system
    "kion.ru": system
    'rule-set:gemini': 'https://1.1.1.1/dns-query#disable-ipv6=true'

keep-alive-idle: 600
keep-alive-interval: 30

profile:
  store-selected: true

routing-mark: 2

sniffer:
  enable: true
  force-dns-mapping: true
  parse-pure-ip: true
  sniff:
    HTTP:
      ports: [80, 8080-8880]
      override-destination: true
    TLS:
      ports: [443, 8443]
  skip-domain:
    - "Mijia Cloud"
    - '+.lan'
    - '+.local'
    - '+.push.apple.com'
    - '+.apple.com'
    - '+.msftconnecttest.com'
    - '+.3gppnetwork'

warp-common: &warp-common
  type: wireguard
  ip: 172.16.0.2
  ipv6: 2606:4700:110:8053:e6ab:f13c:d346:54fb
  private-key: dzp43BNFsLTVCacK+2bi2kxUHlUyMJCJw/NPsmshb6o=
  public-key: bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo=
  allowed-ips: ['0.0.0.0/0']
  udp: true
  mtu: 1280
  remote-dns-resolve: true
  dns: [1.1.1.1, 1.0.0.1, 2606:4700:4700::1111, 2606:4700:4700::1001]

proxies:

- name: "🇷🇺 WARP1"
  <<: *warp-common
  server: 162.159.192.1
  port: 4500
  amnezia-wg-option:
   jc: 4
   jmin: 40
   jmax: 70
   s1: 0
   s2: 0
   h1: 1
   h2: 2
   h4: 3
   h3: 4  
   i1: <b 0xce000000010897a297ecc34cd6dd000044d0ec2e2e1ea2991f467ace4222129b5a098823784694b4897b9986ae0b7280135fa85e196d9ad980b150122129ce2a9379531b0fd3e871ca5fdb883c369832f730e272d7b8b74f393f9f0fa43f11e510ecb2219a52984410c204cf875585340c62238e14ad04dff382f2c200e0ee22fe743b9c6b8b043121c5710ec289f471c91ee414fca8b8be8419ae8ce7ffc53837f6ade262891895f3f4cecd31bc93ac5599e18e4f01b472362b8056c3172b513051f8322d1062997ef4a383b01706598d08d48c221d30e74c7ce000cdad36b706b1bf9b0607c32ec4b3203a4ee21ab64df336212b9758280803fcab14933b0e7ee1e04a7becce3e2633f4852585c567894a5f9efe9706a151b615856647e8b7dba69ab357b3982f554549bef9256111b2d67afde0b496f16962d4957ff654232aa9e845b61463908309cfd9de0a6abf5f425f577d7e5f6440652aa8da5f73588e82e9470f3b21b27b28c649506ae1a7f5f15b876f56abc4615f49911549b9bb39dd804fde182bd2dcec0c33bad9b138ca07d4a4a1650a2c2686acea05727e2a78962a840ae428f55627516e73c83dd8893b02358e81b524b4d99fda6df52b3a8d7a5291326e7ac9d773c5b43b8444554ef5aea104a738ed650aa979674bbed38da58ac29d87c29d387d80b526065baeb073ce65f075ccb56e47533aef357dceaa8293a523c5f6f790be90e4731123d3c6152a70576e90b4ab5bc5ead01576c68ab633ff7d36dcde2a0b2c68897e1acfc4d6483aaaeb635dd63c96b2b6a7a2bfe042f6aed82e5363aa850aace12ee3b1a93f30d8ab9537df483152a5527faca21efc9981b304f11fc95336f5b9637b174c5a0659e2b22e159a9fed4b8e93047371175b1d6d9cc8ab745f3b2281537d1c75fb9451871864efa5d184c38c185fd203de206751b92620f7c369e031d2041e152040920ac2c5ab5340bfc9d0561176abf10a147287ea90758575ac6a9f5ac9f390d0d5b23ee12af583383d994e22c0cf42383834bcd3ada1b3825a0664d8f3fb678261d57601ddf94a8a68a7c273a18c08aa99c7ad8c6c42eab67718843597ec9930457359dfdfbce024afc2dcf9348579a57d8d3490b2fa99f278f1c37d87dad9b221acd575192ffae1784f8e60ec7cee4068b6b988f0433d96d6a1b1865f4e155e9fe020279f434f3bf1bd117b717b92f6cd1cc9bea7d45978bcc3f24bda631a36910110a6ec06da35f8966c9279d130347594f13e9e07514fa370754d1424c0a1545c5070ef9fb2acd14233e8a50bfc5978b5bdf8bc1714731f798d21e2004117c61f2989dd44f0cf027b27d4019e81ed4b5c31db347c4a3a4d85048d7093cf16753d7b0d15e078f5c7a5205dc2f87e330a1f716738dce1c6180e9d02869b5546f1c4d2748f8c90d9693cba4e0079297d22fd61402dea32ff0eb69ebd65a5d0b687d87e3a8b2c42b648aa723c7c7daf37abcc4bb85caea2ee8f55bec20e913b3324ab8f5c3304f820d42ad1b9f2ffc1a3af9927136b4419e1e579ab4c2ae3c776d293d397d575df181e6cae0a4ada5d67ecea171cca3288d57c7bbdaee3befe745fb7d634f70386d873b90c4d6c6596bb65af68f9e5121e67ebf0d89d3c909ceedfb32ce9575a7758ff080724e1ab5d5f43074ecb53a479af21ed03d7b6899c36631c0166f9d47e5e1d4528a5d3d3f744029c4b1c190cbfbad06f5f83f7ad0429fa9a2719c56ffe3783460e166de2d8>

- name: "🇷🇺 WARP2"
  <<: *warp-common
  server: 162.159.192.1
  port: 4500
  amnezia-wg-option:
   jc: 4
   jmin: 40
   jmax: 70
   s1: 0
   s2: 0
   h1: 1
   h2: 2
   h4: 3
   h3: 4
   i1: <b 0xc7000000010809a1ed4edbbe7615000044d017a61a0d774f04290f119e701ef0035df2b0ed571b0b575e6a07246b856eb6ec036fef07f1e07b861251ad737abeb67e64be714c1dcd865312b1b6c35c089c997aeb5c18f808696fe97289513945d84ca846467603e94e44224877f2c1d3261e4ac18740be4bd064369c94fc08978d99b54bf615250998639010c1284248e1d73004b81fcb20b559d8a17eced7eab3964b5b88ca7a3b8579fc8c1c934189e77143b4ac434138114b1048651b56545b87acbef0952763538f3ddeb37cfc6d58b4881c3b719d7ff78f6ee1324a2914a32381c05a64c700466d280be007253bb030d179c4f1b3dc221e1974e2ee6d6e2b9e8d709159b5ef22e1783dbba845c20ca1c83b066c73835920ad70b806df0aee0351e3fc9ab1e42e8b2a30fe235ff0612eee19744949cecee0463b76514ad90c1f7ceaa557c18586ab561d49482e73c85d0143785da14a441bf82f78783b61cccd44aecb1947516e79b5ca5a6b3a8aed6040fae0eeabdc55a88dc19ade832d99fca90c7a629cacc07192d7e47e3c6a271b95b0ea3392562a06a1cab79f40ea92916ebee197b7b5f14b251824e1ed20ff2ca80b1f03a43e45157589bc61b978e97851025b3b7ccc17d291e1cb60fe48a5c26829dce11dd23c2e73265a9ebf8617c985e4fee4681e863f990061f4dea465a7d2524bd0edcf4b48d4b8f25fc359b15babd2637284a4774077dca60091f1a781cfee1bef9713dd5943a579d7470bc5970542fbb27fdf77880a8d8751b1f642c7a3f019a05ab94bf63d3525ef34e9290b5c8d477f2714e6d6e3e4d35c1983f5e16fda57fcdf071b513f8f088dbe8d5a97577d17a5383a496c3f313adfdd47c962bbaebd6aa13b46439eb742622c29ca067db0ec1853064c3cbbffe0a215a19fce47d49703ed58ebbd89721172d256d1cf30188106fb2f863186511401fad54d087aa2fb3d1b85768db386bd7102e8060ac157bac011acdcdae2799b9aee1467c3424013455bd028fcaacdc3c77d28ea199967d617ea7d0d0815f3cc407934a76d1293dccba210d1709a13e5dd67c9ba47cd113f5bdd740358eff13164159fd09bc2f7ec6cfa64d9df7e2e2f88706b0ff3a92ccf6f078456cfe0bdd89292cfe2680badc1eac9f7d36efe8eb6912c7b164508d13e6c0911c15f73c233cbe4fc70ff2ade1e1be4bbb738e0939159e2078a9438f05b756a003371f4861481c38f1cdd2d7b06deb62869e9fe79a8abaa920646fa2e8fa28f0d80c136376c7b56046bae4c05c0cdf64efb8c47bbfc5a1a4c0b045061ef0d71618e0d206a1d7f245fd5c03191b152673ba8dff8e1b8de7c50234a93cba91e3888adb228cc02beded4b1c0946797d3ef02dec2edb6ad0ac21f89f4be364c317da7c22440e9f358d512203f4b7ab20388af68b8915d0152db2c8a0687bfaea870f7529bb92a22b35bd79bc6d490591406346ecd78342ee3563c4883a8251679691c2d4e963397e24653520795511b018915374c954bddb940a9d7a16d1c8bd798fc7dbfb0599a7074e13f87e14efa8d511bb2579ec029b1bda18fe971b30fbe19e986ff2686a69bf3f1bb929de93ae70345ebca998b11e0a2b41890cba628d8f6e7c4e94790735e5299b4ff07cd3080f7d53c9cbe1911d2cd5925b3213e033c272506a87886cf761a283a779564d3241e3c28f632e166b5d756e1786ce077614c4444e3f2aed5decb3613b925ea3e558c21d4faf8ba54edd0f3a5d4>

- name: "🇷🇺 WARP3"
  <<: *warp-common
  server: 162.159.192.1
  port: 4500
  amnezia-wg-option:
   jc: 4
   jmin: 40
   jmax: 70
   s1: 0
   s2: 0
   h1: 1
   h2: 2
   h4: 3
   h3: 4   
   i1: <b 0x494e56495445207369703a626f624062696c6f78692e636f6d205349502f322e300d0a5669613a205349502f322e302f55445020706333332e61746c616e74612e636f6d3b6272616e63683d7a39684734624b3737366173646864730d0a4d61782d466f7277617264733a2037300d0a546f3a20426f62203c7369703a626f624062696c6f78692e636f6d3e0d0a46726f6d3a20416c696365203c7369703a616c6963654061746c616e74612e636f6d3e3b7461673d313932383330313737340d0a43616c6c2d49443a20613834623463373665363637313040706333332e61746c616e74612e636f6d0d0a435365713a2033313431353920494e564954450d0a436f6e746163743a203c7369703a616c69636540706333332e61746c616e74612e636f6d3e0d0a436f6e74656e742d547970653a206170706c69636174696f6e2f7364700d0a436f6e74656e742d4c656e6774683a20300d0a0d0a>
   i2: <b 0x5349502f322e302031303020547279696e670d0a5669613a205349502f322e302f55445020706333332e61746c616e74612e636f6d3b6272616e63683d7a39684734624b3737366173646864730d0a546f3a20426f62203c7369703a626f624062696c6f78692e636f6d3e0d0a46726f6d3a20416c696365203c7369703a616c6963654061746c616e74612e636f6d3e3b7461673d313932383330313737340d0a43616c6c2d49443a20613834623463373665363637313040706333332e61746c616e74612e636f6d0d0a435365713a2033313431353920494e564954450d0a436f6e74656e742d4c656e6774683a20300d0a0d0a>

# Поменяйте на значения из вашего аккаунта protonvpn.com
- name: 🇳🇱 Proton
  dialer-proxy: PROXY-RU
  type: wireguard
  server: 185.177.125.4
  port: 51820
  ip: 10.2.0.2
  private-key: oIbnW+SKRTq1MiEC6PWh9uvWF0BOkdW5C+f2mBjPD0k=
  public-key: VeS8osqHoOiCaQMLsiGn2km54e4L+h9eH5nJNy0k3Es=
  allowed-ips: ['0.0.0.0/0']
  udp: true
  remote-dns-resolve: true
  dns: [10.2.0.1]

proxy-groups:

  - name: PROXY
    type: url-test
    interval: 30
    icon: https://fastly.jsdelivr.net/gh/Koolson/Qure@master/IconSet/Color/Proxy.png
    include-all: true
    exclude-filter: "🇷🇺|Russia|Россия"

  - name: PROXY-RU
    type: url-test
    interval: 30
    icon: https://fastly.jsdelivr.net/gh/Koolson/Qure@master/IconSet/Color/Russia.png
    include-all: true
    filter: "🇷🇺|Russia|Россия"

  - name: YOUTUBE
    icon: https://fastly.jsdelivr.net/gh/Koolson/Qure@master/IconSet/Color/YouTube.png
    type: url-test
    interval: 30
    proxies: [PROXY-RU, PROXY]

rule-providers:

  ru-blocked:
    behavior: domain
    type: http
    format: text
    url: 'https://cdn.jsdelivr.net/gh/shvchk/unblock-net/lists/clash/ru-blocked'
    interval: 86400
    path: ./ruleset/ru-blocked.yaml

  twitter:
    behavior: classical
    type: http
    url: "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/Clash/Twitter/Twitter.yaml"
    interval: 86400
    path: ./ruleset/twitter.yaml

  instagram:
    behavior: classical
    type: http
    url: "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/Clash/Instagram/Instagram.yaml"
    interval: 86400
    path: ./ruleset/instagram.yaml

  facebook:
    behavior: classical
    type: http
    url: "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/Clash/Facebook/Facebook.yaml"
    interval: 86400
    path: ./ruleset/facebook.yaml

  youtube:
    behavior: classical
    type: http
    url: "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/Clash/YouTube/YouTube.yaml"
    interval: 86400
    path: ./ruleset/youtube.yaml

  discord-domain:
    behavior: classical
    type: http
    url: "https://raw.githubusercontent.com/fildunsky/clash_discord/refs/heads/main/discord-domain.yaml"
    interval: 86400
    path: ./ruleset/discord-domain.yaml

  discord-ip:
    behavior: ipcidr
    type: http
    format: text
    url: "https://raw.githubusercontent.com/fildunsky/clash_discord/refs/heads/main/discord-ip.list"
    interval: 86400
    path: ./ruleset/discord-ip.list

  whatsapp:
    behavior: classical
    type: http
    url: "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/refs/heads/master/rule/Clash/Whatsapp/Whatsapp.yaml"    
    interval: 86400
    path: ./ruleset/whatsapp.yaml

  notion:
    behavior: classical
    type: http
    url: "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/refs/heads/master/rule/Clash/Notion/Notion.yaml"
    interval: 86400
    path: ./ruleset/notion.yaml

  gemini:
    behavior: domain
    type: http
    url: "https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/refs/heads/meta/geo/geosite/google-gemini.yaml"
    interval: 86400
    path: ./ruleset/gemini.yaml
    
  openai:
    behavior: classical
    type: http
    format: yaml
    url: "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/refs/heads/master/rule/Clash/OpenAI/OpenAI.yaml"
    interval: 86400
    path: ./ruleset/openai.yaml

  cloudflare:
    behavior: ipcidr
    type: http
    format: text
    url: "https://raw.githubusercontent.com/itdoginfo/allow-domains/refs/heads/main/Subnets/IPv4/cloudflare.lst"
    interval: 86400
    path: ./ruleset/cloudflare.lst

  telegram:
    behavior: classical
    type: http
    proxy: PROXY
    url: "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/refs/heads/master/rule/Clash/Telegram/Telegram.yaml"    
    interval: 86400
    path: ./ruleset/telegram.yaml

  telegram-ip:
    behavior: ipcidr
    format: text
    type: http
    url: "https://core.telegram.org/resources/cidr.txt"    
    interval: 86400
    path: ./ruleset/telegram-ip.txt

  claude:
    behavior: classical
    type: http
    url: "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/refs/heads/master/rule/Clash/Claude/Claude.yaml"
    interval: 86400
    path: ./ruleset/claude.yaml

rules:
  - DOMAIN-SUFFIX,ipwho.is,DIRECT
  - AND,((NETWORK,UDP),(DST-PORT,443)),REJECT
# Google Meet --->>
  - IP-CIDR,74.125.250.0/24,PROXY
  - IP-CIDR,74.125.247.128/32,PROXY
  - IP-CIDR,142.250.82.0/24,PROXY
  - IP-CIDR6,2001:4860:4864:5::0/64,PROXY
  - IP-CIDR6,2001:4860:4864:4:8000::/128,PROXY
  - IP-CIDR6,2001:4860:4864:6::/64,PROXY
  - DOMAIN-SUFFIX,workspace.turns.goog,PROXY
  - DOMAIN-SUFFIX,meet.turns.goog,PROXY
  - DOMAIN-SUFFIX,meet.google.com,PROXY
# <<--- Google Meet 
  - RULE-SET,telegram,PROXY
  - RULE-SET,telegram-ip,PROXY
  - RULE-SET,whatsapp,PROXY
  - RULE-SET,cloudflare,PROXY
  - RULE-SET,gemini,PROXY
  - RULE-SET,openai,PROXY
  - RULE-SET,claude,PROXY
  - RULE-SET,youtube,YOUTUBE
  - RULE-SET,twitter,PROXY
  - RULE-SET,instagram,PROXY
  - RULE-SET,facebook,PROXY
  - RULE-SET,discord-domain,PROXY
  - RULE-SET,discord-ip,PROXY
  - RULE-SET,notion,PROXY
  - DOMAIN-KEYWORD,4pda,PROXY
  - RULE-SET,ru-blocked,PROXY
  - MATCH,DIRECT
```

## Пояснения

#### Основные настройки

```YAML
mode: rule # режим работы по правилам
ipv6: false # выключаем IPv6
log-level: error # уровень предупреждений в журнале
allow-lan: false # если true, можно открыть SOCKS5 для ваших устройств
tproxy-port: 7894 # порт прозрачного прокси
unified-delay: true # серверы пингуются по два раза, показывая лучшую скорость
tcp-concurrent: true # ускоряет работу
external-controller: 0.0.0.0:9090 # адрес Dashboard панели Mihomo
secret: "Kruto!P@ro11" # пароль на панель можно менять
external-ui: ./ui # папка, в которую Mihomo качает файлы панели Dashboard
external-ui-url: "https://github.com/Zephyruso/zashboard/releases/latest/download/dist-cdn-fonts.zip" # ссылка позволяет обновлять панель при наличии обновлений
```

#### DNS

```YAML
dns:
  enable: true
  listen: 0.0.0.0:7874
  ipv6: false
  default-nameserver:
    - 9.9.9.9
    - 149.112.112.112
  nameserver:
    - https://dns.quad9.net/dns-query
    - https://dns10.quad9.net/dns-query

keep-alive-idle: 600
keep-alive-interval: 30

# Блок правил вашего профиля
profile:
  store-selected: true # сохраняет при перезагрузках выбор серверов для групп типа select в панели Dashboard

routing-mark: 2 # необходимо помечать траффик, которым управляет Mihomo для маршрутизации по правилам

# Cниффер - система помогает Mihomo разбираться, какой траффик куда направлять, но как и fake-ip может давать сбои, так как идёт вмешательство в траффик, некоторые программы или сервисы, направленные напрямую мимо ВПН, всё равно могут ругаться на то, что включен ВПН, тогда нужно добавить исключения ниже в skip-domain
sniffer:
  enable: true
  force-dns-mapping: true
  parse-pure-ip: true
  sniff:
    HTTP:
      ports: [80, 8080-8880]
      override-destination: true
    TLS:
      ports: [443, 8443]
  skip-domain:
    - "Mijia Cloud"
    - '+.lan'
    - '+.local'
    - '+.push.apple.com'
    - '+.apple.com'
    - '+.msftconnecttest.com' # чтобы Windows не показывал глобус вместо Wifi
    - '+.3gppnetwork' # voWifi

  skip-src-address:
    - 192.168.8.108/32 # если нужно исключить конкретное устройство в вашей сети, пропишите его адрес с /32 на конце здесь
  skip-dst-address:
    - 192.168.8.108/32 # если нужно исключить конкретное устройство в вашей сети, пропишите его адрес с /32 на конце здесь
```

#### Серверы

В блоке proxies: описываются ваши серверы
Поддерживаются WireGuard, Amnezia 2.0, VLESS, VMESS, Hysteria2, Socks5, Shadowsocks, и многое другое. Можно добавлять любые интерфейсы роутера расширяя функционал до бесконечности. Каждый сервер описывается блоком начиная с пары отступов и дефиса. Имя name может быть любым, для вашего удобства и красоты в имя можно вставлять emoji флаг страны сервера, если у вас их несколько.
AmneziaWG 2.0 Cloudflare WARP:

```YAML
proxies:

  - name: 🇷🇺 WARP
    type: wireguard
    private-key: +Al97TGBYk9XMwTtiXjuZ06azVTFdV23ABWc8SfdyHY= # Поменяйте на ваш ключ Cloudflare WARP
    server: 162.159.192.1 # Endpoint можно менять на другой IP адрес из генератора
    port: 500 # можно менять на порт из генератора
    ip: 172.16.0.2
    public-key: bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo=
    allowed-ips: ['0.0.0.0/0']
    udp: true
    mtu: 1280 # на некоторых провайдерах этот параметр может мешать, если нет пинга, пробуйте эту строку убрать
    remote-dns-resolve: true # на некоторых провайдерах этот параметр может мешать (конфиг запустится, но сайты не будут открываться), тогда пробуйте его убрать вместе со строкой dns: ниже либо перевести в режим false
    dns: [1.1.1.1, 1.0.0.1] 
    amnezia-wg-option:
      jc: 120 # Можно менять количество мусорных пакетов от 1 до 128, меньше = быстрее
      jmin: 23 # от 1 до 1280, но меньше jmax
      jmax: 911 # до 1280, но больше jmin
      s1: 0
      s2: 0
      h1: 1
      h2: 2
      h3: 3
      h4: 4
      # AWG 2.0
      i1: <b 0xc2000000011419fa4bb3599f336777de79f81ca9a8d80d91eeec000044c635cef024a885dcb66d1420a91a8c427e87d6cf8e08b563932f449412cddf77d3e2594ea1c7a183c238a89e9adb7ffa57c133e55c59bec101634db90afb83f75b19fe703179e26a31902324c73f82d9354e1ed8da39af610afcb27e6590a44341a0828e5a3d2f0e0f7b0945d7bf3402feea0ee6332e19bdf48ffc387a97227aa97b205a485d282cd66d1c384bafd63dc42f822c4df2109db5b5646c458236ddcc01ae1c493482128bc0830c9e1233f0027a0d262f92b49d9d8abd9a9e0341f6e1214761043c021d7aa8c464b9d865f5fbe234e49626e00712031703a3e23ef82975f014ee1e1dc428521dc23ce7c6c13663b19906240b3efe403cf30559d798871557e4e60e86c29ea4504ed4d9bb8b549d0e8acd6c334c39bb8fb42ede68fb2aadf00cfc8bcc12df03602bbd4fe701d64a39f7ced112951a83b1dbbe6cd696dd3f15985c1b9fef72fa8d0319708b633cc4681910843ce753fac596ed9945d8b839aeff8d3bf0449197bd0bb22ab8efd5d63eb4a95db8d3ffc796ed5bcf2f4a136a8a36c7a0c65270d511aebac733e61d414050088a1c3d868fb52bc7e57d3d9fd132d78b740a6ecdc6c24936e92c28672dbe00928d89b891865f885aeb4c4996d50c2bbbb7a99ab5de02ac89b3308e57bcecf13f2da0333d1420e18b66b4c23d625d836b538fc0c221d6bd7f566a31fa292b85be96041d8e0bfe655d5dc1afed23eb8f2b3446561bbee7644325cc98d31cea38b865bdcc507e48c6ebdc7553be7bd6ab963d5a14615c4b81da7081c127c791224853e2d19bafdc0d9f3f3a6de898d14abb0e2bc849917e0a599ed4a541268ad0e60ea4d147dc33d17fa82f22aa505ccb53803a31d10a7ca2fea0b290a52ee92c7bf4aab7cea4e3c07b1989364eed87a3c6ba65188cd349d37ce4eefde9ec43bab4b4dc79e03469c2ad6b902e28e0bbbbf696781ad4edf424ffb35ce0236d373629008f142d04b5e08a124237e03e3149f4cdde92d7fae581a1ac332e26b2c9c1a6bdec5b3a9c7a2a870f7a0c25fc6ce245e029b686e346c6d862ad8df6d9b62474fbc31dbb914711f78074d4441f4e6e9edca3c52315a5c0653856e23f681558d669f4a4e6915bcf42b56ce36cb7dd3983b0b1d6fdf0f8efddb68e7ca0ae9dd4570fe6978fbb524109f6ec957ca61f1767ef74eb803b0f16abd0087cf2d01bc1db1c01d97ac81b3196c934586963fe7cf2d310e0739621e8bd00dc23fded18576d8c8f285d7bb5f43b547af3c76235de8b6f757f817683b2151600b11721219212bf27558edd439e73fce951f61d582320e5f4d6c315c71129b719277fc144bbe8ded25ab6d29b6e189c9bd9b16538faf60cc2aab3c3bb81fc2213657f2dd0ceb9b3b871e1423d8d3e8cc008721ef03b28e0ee7bb66b8f2a2ac01ef88df1f21ed49bf1ce435df31ac34485936172567488812429c269b49ee9e3d99652b51a7a614b7c460bf0d2d64d8349ded7345bedab1ea0a766a8470b1242f38d09f7855a32db39516c2bd4bcc538c52fa3a90c8714d4b006a15d9c7a7d04919a1cab48da7cce0d5de1f9e5f8936cffe469132991c6eb84c5191d1bcf69f70c58d9a7b66846440a9f0eef25ee6ab62715b50ca7bef0bc3013d4b62e1639b5028bdf757454356e9326a4c76dabfb497d451a3a1d2dbd46ec283d255799f72dfe878ae25892e25a2542d3ca9018394d8ca35b53ccd94947a8>
```

ProtonVPN

```YAML
  - name: 🇳🇱 Proton
    type: wireguard
    dialer-proxy: 🇷🇺 WARP # Цепочка WARP -> Proton
    private-key: wBWnH4yYbVt+kRje04uNHb8/CM0eitsRNXBv8qpWWV8=
    server: 138.199.53.242
    port: 51820
    ip: 10.2.0.2
    public-key: +DE6qrCbWBxBY2rkopc+jVUDnQ60VYuTkkV6LM4rcwg=
    allowed-ips: ['0.0.0.0/0']
    udp: true
    mtu: 1280
    remote-dns-resolve: true
    dns: [10.2.0.1]
```

VLESS

```YAML
  - name: 🇬🇧 UK
    type: vless
    server: XX.XXX.XX.XXX
    port: 443
    uuid: dedaBaba-papa-mama-ya43-4857s75
    network: tcp
    tls: true
    udp: true
    flow: xtls-rprx-vision
    servername: yandex.ru
    reality-opts:
      public-key: 583z_mc-Antoha-fLxrlB5tpszb4Z8$5fh893h
      short-id: 848485Hdhbfh
    client-fingerprint: chrome
```

Далее идут описания групп (даже если у вас один сервер, его нужно включить в группу)

```YAML
proxy-groups:

  - name: YT
    type: fallback
    icon: https://fastly.jsdelivr.net/gh/Koolson/Qure@master/IconSet/Color/YouTube.png
    proxies:
      - 🇷🇺 WARP
      - 🇳🇱 Proton
      - 🇬🇧 UK
      - DIRECT
    url: https://gstatic.com/generate_204
    interval: 300

  - name: PROXY
    type: fallback
    proxies:
      - 🇳🇱 Proton
      - 🇬🇧 UK
      - DIRECT
    url: https://gstatic.com/generate_204
    interval: 300
```

На случай, если все тоннели отвалятся, последним “сервером” в списке стоит DIRECT (обходы работать не будут, но хотя бы телега чат будет ходить и то, что не заблочено).
Блок описания списков для формирования правил:

```YAML
rule-providers:

  ru-blocked: # имя списка
    behavior: domain # тип списка - по доменам
    type: http # http означает, что список находится где-то в сети и его нужно скачать
    format: text # формат списка
    url: 'https://cdn.jsdelivr.net/gh/shvchk/unblock-net/lists/clash/ru-blocked'
    interval: 86400 # раз в сутки список автоматически обновляется
    path: ./ruleset/ru-blocked.yaml # путь и имя файла этого списка на роутере
```

Правила, как и что Clash будет маршрутизировать. Самым последним правилом желательно оставлять - МATCH,DIRECT - если хотите, чтобы всё остальное, что не описано правилами, шло напрямую минуя тоннели ВПН.

```YAML
rules:
  - RULE-SET,telegram,PROXY
  - RULE-SET,whatsapp,PROXY
  - RULE-SET,cloudflare,PROXY
  - RULE-SET,gemini,PROXY
  - RULE-SET,openai,PROXY
  - RULE-SET,youtube,YOUTUBE
  - RULE-SET,twitter,PROXY
  - RULE-SET,instagram,PROXY
  - RULE-SET,facebook,PROXY
  - RULE-SET,discord-domain,PROXY
  - RULE-SET,discord-ip,PROXY
  - RULE-SET,notion,PROXY
  - DOMAIN-KEYWORD,4pda,PROXY
  - RULE-SET,ru-blocked,PROXY
  - MATCH,DIRECT
```

Чтобы увидеть больше информации, почему ваш Clash не стартует, нужно делать его старт в консоли:

```Bash
service clash start
```

Официальное wiki проекта со всеми настройками
  gemini:
    behavior: domain
    type: http
    url: "https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/refs/heads/meta/geo/geosite/google-gemini.yaml"
    interval: 86400
    path: ./ruleset/gemini.yaml

## Реальное разграничение трафика

### Рабочий конфиг fake-ip

Поменяйте private-key у &warp-common на свой, добавьте свои серверы и/или вставьте ссылки на свои подписки:

```YAML
mode: rule
# Proxy Mode: MIXED (TCP via TPROXY port 7894, UDP via TUN/gVisor)
mixed-port: 7890
tproxy-port: 7894
tun:
  enable: true
  device: clash-tun
  stack: gvisor
  auto-route: false
  auto-redirect: false
  auto-detect-interface: false
ipv6: false
log-level: warning
allow-lan: true
unified-delay: true
tcp-concurrent: true
external-controller: 0.0.0.0:9090
external-ui: ./ui
external-ui-url: "https://github.com/Zephyruso/zashboard/releases/latest/download/dist-cdn-fonts.zip"

hosts:
  ntc.party: 130.255.77.28

dns:
  enable: true
  listen: 0.0.0.0:7874
  ipv6: false
  default-nameserver:
    - 9.9.9.9
    - 149.112.112.112
  nameserver:
    - https://dns.quad9.net/dns-query
    - https://dns10.quad9.net/dns-query
  nameserver-policy:
    "+.lan": system
    "*.lan": system
    "msftconnecttest.com": system
    "msftncsi.com": system
    "kion.ru": system
    'rule-set:gemini': 'https://1.1.1.1/dns-query#disable-ipv6=true'
  enhanced-mode: fake-ip
  fake-ip-range: 198.18.0.0/15
  fake-ip-filter-mode: whitelist
  fake-ip-filter:
    - '*.4pda.to'
    - '*.4pda.ws'
    - 'ip.wtf'
    - '*.ip.wtf'
    - 'workspace.turns.goog'
    - '*.workspace.turns.goog'
    - 'meet.turns.goog'
    - '*.meet.turns.goog'
    - 'meet.google.com'
    - '*.meet.google.com'
    - RULE-SET:adobe
    - RULE-SET:claude
    - RULE-SET:discord-domain
    - RULE-SET:facebook
    - RULE-SET:gemini
    - RULE-SET:github
    - RULE-SET:intel
    - RULE-SET:instagram
    - RULE-SET:mega
    - RULE-SET:microsoft
    - RULE-SET:notion
    - RULE-SET:openai
    - RULE-SET:ru-blocked
    - RULE-SET:soundcloud
    - RULE-SET:speedtest
    - RULE-SET:spotify
    - RULE-SET:steam
    - RULE-SET:telegram
    - RULE-SET:tik-tok
    - RULE-SET:twitter
    - RULE-SET:vimeo
    - RULE-SET:whatsapp
    - RULE-SET:wix
    - RULE-SET:youtube

keep-alive-idle: 600
keep-alive-interval: 30

profile:
  store-selected: true
  store-fake-ip: true

routing-mark: 2

sniffer:
  enable: true
  force-dns-mapping: true
  parse-pure-ip: true
  sniff:
    HTTP:
      ports:
      - 80
      - 8080-8880
      override-destination: true
    TLS:
      ports:
      - 443
      - 8443
  skip-domain:
    - 'Mijia Cloud'
    - +.lan
    - +.msftconnecttest.com
    - +.msftncsi.com
    - +.3gppnetwork.org
    - +.openwrt.org
    - +.vsean.net
    - cudy.net
    - +.msftconnecttest.com
    - +.3gppnetwork

warp-common: &warp-common
  type: wireguard
  ip: 172.16.0.2
  ipv6: 2606:4700:110:8f35:c656:fbd6:9607:4042
  private-key: V+opMoJQrFe/2Ersz2dWut5zZZq1Lc4vzRjwYHCfZI0= # поменяйте!
  public-key: bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo=
  allowed-ips: ['0.0.0.0/0']
  udp: true
  mtu: 1280
  remote-dns-resolve: true
  dns: [1.1.1.1, 1.0.0.1, 2606:4700:4700::1111, 2606:4700:4700::1001]

proxies:

- name: "🇷🇺 WARP1"
  <<: *warp-common
  server: 162.159.192.1
  port: 4500
  amnezia-wg-option:
   jc: 4
   jmin: 40
   jmax: 70
   s1: 0
   s2: 0
   h1: 1
   h2: 2
   h4: 3
   h3: 4  
   i1: <b 0xce000000010897a297ecc34cd6dd000044d0ec2e2e1ea2991f467ace4222129b5a098823784694b4897b9986ae0b7280135fa85e196d9ad980b150122129ce2a9379531b0fd3e871ca5fdb883c369832f730e272d7b8b74f393f9f0fa43f11e510ecb2219a52984410c204cf875585340c62238e14ad04dff382f2c200e0ee22fe743b9c6b8b043121c5710ec289f471c91ee414fca8b8be8419ae8ce7ffc53837f6ade262891895f3f4cecd31bc93ac5599e18e4f01b472362b8056c3172b513051f8322d1062997ef4a383b01706598d08d48c221d30e74c7ce000cdad36b706b1bf9b0607c32ec4b3203a4ee21ab64df336212b9758280803fcab14933b0e7ee1e04a7becce3e2633f4852585c567894a5f9efe9706a151b615856647e8b7dba69ab357b3982f554549bef9256111b2d67afde0b496f16962d4957ff654232aa9e845b61463908309cfd9de0a6abf5f425f577d7e5f6440652aa8da5f73588e82e9470f3b21b27b28c649506ae1a7f5f15b876f56abc4615f49911549b9bb39dd804fde182bd2dcec0c33bad9b138ca07d4a4a1650a2c2686acea05727e2a78962a840ae428f55627516e73c83dd8893b02358e81b524b4d99fda6df52b3a8d7a5291326e7ac9d773c5b43b8444554ef5aea104a738ed650aa979674bbed38da58ac29d87c29d387d80b526065baeb073ce65f075ccb56e47533aef357dceaa8293a523c5f6f790be90e4731123d3c6152a70576e90b4ab5bc5ead01576c68ab633ff7d36dcde2a0b2c68897e1acfc4d6483aaaeb635dd63c96b2b6a7a2bfe042f6aed82e5363aa850aace12ee3b1a93f30d8ab9537df483152a5527faca21efc9981b304f11fc95336f5b9637b174c5a0659e2b22e159a9fed4b8e93047371175b1d6d9cc8ab745f3b2281537d1c75fb9451871864efa5d184c38c185fd203de206751b92620f7c369e031d2041e152040920ac2c5ab5340bfc9d0561176abf10a147287ea90758575ac6a9f5ac9f390d0d5b23ee12af583383d994e22c0cf42383834bcd3ada1b3825a0664d8f3fb678261d57601ddf94a8a68a7c273a18c08aa99c7ad8c6c42eab67718843597ec9930457359dfdfbce024afc2dcf9348579a57d8d3490b2fa99f278f1c37d87dad9b221acd575192ffae1784f8e60ec7cee4068b6b988f0433d96d6a1b1865f4e155e9fe020279f434f3bf1bd117b717b92f6cd1cc9bea7d45978bcc3f24bda631a36910110a6ec06da35f8966c9279d130347594f13e9e07514fa370754d1424c0a1545c5070ef9fb2acd14233e8a50bfc5978b5bdf8bc1714731f798d21e2004117c61f2989dd44f0cf027b27d4019e81ed4b5c31db347c4a3a4d85048d7093cf16753d7b0d15e078f5c7a5205dc2f87e330a1f716738dce1c6180e9d02869b5546f1c4d2748f8c90d9693cba4e0079297d22fd61402dea32ff0eb69ebd65a5d0b687d87e3a8b2c42b648aa723c7c7daf37abcc4bb85caea2ee8f55bec20e913b3324ab8f5c3304f820d42ad1b9f2ffc1a3af9927136b4419e1e579ab4c2ae3c776d293d397d575df181e6cae0a4ada5d67ecea171cca3288d57c7bbdaee3befe745fb7d634f70386d873b90c4d6c6596bb65af68f9e5121e67ebf0d89d3c909ceedfb32ce9575a7758ff080724e1ab5d5f43074ecb53a479af21ed03d7b6899c36631c0166f9d47e5e1d4528a5d3d3f744029c4b1c190cbfbad06f5f83f7ad0429fa9a2719c56ffe3783460e166de2d8>

- name: "🇷🇺 WARP2"
  <<: *warp-common
  server: 162.159.192.1
  port: 4500
  amnezia-wg-option:
   jc: 4
   jmin: 40
   jmax: 70
   s1: 0
   s2: 0
   h1: 1
   h2: 2
   h4: 3
   h3: 4
   i1: <b 0xc7000000010809a1ed4edbbe7615000044d017a61a0d774f04290f119e701ef0035df2b0ed571b0b575e6a07246b856eb6ec036fef07f1e07b861251ad737abeb67e64be714c1dcd865312b1b6c35c089c997aeb5c18f808696fe97289513945d84ca846467603e94e44224877f2c1d3261e4ac18740be4bd064369c94fc08978d99b54bf615250998639010c1284248e1d73004b81fcb20b559d8a17eced7eab3964b5b88ca7a3b8579fc8c1c934189e77143b4ac434138114b1048651b56545b87acbef0952763538f3ddeb37cfc6d58b4881c3b719d7ff78f6ee1324a2914a32381c05a64c700466d280be007253bb030d179c4f1b3dc221e1974e2ee6d6e2b9e8d709159b5ef22e1783dbba845c20ca1c83b066c73835920ad70b806df0aee0351e3fc9ab1e42e8b2a30fe235ff0612eee19744949cecee0463b76514ad90c1f7ceaa557c18586ab561d49482e73c85d0143785da14a441bf82f78783b61cccd44aecb1947516e79b5ca5a6b3a8aed6040fae0eeabdc55a88dc19ade832d99fca90c7a629cacc07192d7e47e3c6a271b95b0ea3392562a06a1cab79f40ea92916ebee197b7b5f14b251824e1ed20ff2ca80b1f03a43e45157589bc61b978e97851025b3b7ccc17d291e1cb60fe48a5c26829dce11dd23c2e73265a9ebf8617c985e4fee4681e863f990061f4dea465a7d2524bd0edcf4b48d4b8f25fc359b15babd2637284a4774077dca60091f1a781cfee1bef9713dd5943a579d7470bc5970542fbb27fdf77880a8d8751b1f642c7a3f019a05ab94bf63d3525ef34e9290b5c8d477f2714e6d6e3e4d35c1983f5e16fda57fcdf071b513f8f088dbe8d5a97577d17a5383a496c3f313adfdd47c962bbaebd6aa13b46439eb742622c29ca067db0ec1853064c3cbbffe0a215a19fce47d49703ed58ebbd89721172d256d1cf30188106fb2f863186511401fad54d087aa2fb3d1b85768db386bd7102e8060ac157bac011acdcdae2799b9aee1467c3424013455bd028fcaacdc3c77d28ea199967d617ea7d0d0815f3cc407934a76d1293dccba210d1709a13e5dd67c9ba47cd113f5bdd740358eff13164159fd09bc2f7ec6cfa64d9df7e2e2f88706b0ff3a92ccf6f078456cfe0bdd89292cfe2680badc1eac9f7d36efe8eb6912c7b164508d13e6c0911c15f73c233cbe4fc70ff2ade1e1be4bbb738e0939159e2078a9438f05b756a003371f4861481c38f1cdd2d7b06deb62869e9fe79a8abaa920646fa2e8fa28f0d80c136376c7b56046bae4c05c0cdf64efb8c47bbfc5a1a4c0b045061ef0d71618e0d206a1d7f245fd5c03191b152673ba8dff8e1b8de7c50234a93cba91e3888adb228cc02beded4b1c0946797d3ef02dec2edb6ad0ac21f89f4be364c317da7c22440e9f358d512203f4b7ab20388af68b8915d0152db2c8a0687bfaea870f7529bb92a22b35bd79bc6d490591406346ecd78342ee3563c4883a8251679691c2d4e963397e24653520795511b018915374c954bddb940a9d7a16d1c8bd798fc7dbfb0599a7074e13f87e14efa8d511bb2579ec029b1bda18fe971b30fbe19e986ff2686a69bf3f1bb929de93ae70345ebca998b11e0a2b41890cba628d8f6e7c4e94790735e5299b4ff07cd3080f7d53c9cbe1911d2cd5925b3213e033c272506a87886cf761a283a779564d3241e3c28f632e166b5d756e1786ce077614c4444e3f2aed5decb3613b925ea3e558c21d4faf8ba54edd0f3a5d4>

- name: "🇷🇺 WARP3"
  <<: *warp-common
  server: 162.159.192.1
  port: 4500
  amnezia-wg-option:
   jc: 4
   jmin: 40
   jmax: 70
   s1: 0
   s2: 0
   h1: 1
   h2: 2
   h4: 3
   h3: 4   
   i1: <b 0x494e56495445207369703a626f624062696c6f78692e636f6d205349502f322e300d0a5669613a205349502f322e302f55445020706333332e61746c616e74612e636f6d3b6272616e63683d7a39684734624b3737366173646864730d0a4d61782d466f7277617264733a2037300d0a546f3a20426f62203c7369703a626f624062696c6f78692e636f6d3e0d0a46726f6d3a20416c696365203c7369703a616c6963654061746c616e74612e636f6d3e3b7461673d313932383330313737340d0a43616c6c2d49443a20613834623463373665363637313040706333332e61746c616e74612e636f6d0d0a435365713a2033313431353920494e564954450d0a436f6e746163743a203c7369703a616c69636540706333332e61746c616e74612e636f6d3e0d0a436f6e74656e742d547970653a206170706c69636174696f6e2f7364700d0a436f6e74656e742d4c656e6774683a20300d0a0d0a>
   i2: <b 0x5349502f322e302031303020547279696e670d0a5669613a205349502f322e302f55445020706333332e61746c616e74612e636f6d3b6272616e63683d7a39684734624b3737366173646864730d0a546f3a20426f62203c7369703a626f624062696c6f78692e636f6d3e0d0a46726f6d3a20416c696365203c7369703a616c6963654061746c616e74612e636f6d3e3b7461673d313932383330313737340d0a43616c6c2d49443a20613834623463373665363637313040706333332e61746c616e74612e636f6d0d0a435365713a2033313431353920494e564954450d0a436f6e74656e742d4c656e6774683a20300d0a0d0a>

# Поменяйте на значения из вашего аккаунта protonvpn.com
- name: 🇳🇱 Proton
  dialer-proxy: PROXY-RU
  type: wireguard
  server: 185.177.125.4
  port: 51820
  ip: 10.2.0.2
  private-key: oIbnW+SKRTq1MiEC6PWh9uvWF0BOkdW5C+f2mBjPD0k=
  public-key: VeS8osqHoOiCaQMLsiGn2km54e4L+h9eH5nJNy0k3Es=
  allowed-ips: ['0.0.0.0/0']
  udp: true
  remote-dns-resolve: true
  dns: [10.2.0.1]

proxy-providers:

  LastDep:
    type: http
    url: "https://sub.../***" # << ссылка подписки
    path: ./lastdep.yaml
    interval: 10800
    health-check:
      enable: true
      url: https://gstatic.com/generate_204
      interval: 300
      timeout: 5000
      expected-status: 204
    header:
      User-Agent: [Happ]
      x-hwid: [c404no99i108387b]
      x-device-os: [Android]
      x-ver-os: [16]
      x-device-model: [samsung SM-S918B]

  Ledokol:
    type: http
    url: "https://sub.../***" # << ссылка подписки
    path: ./ledokol.yaml
    interval: 10800
    health-check:
      enable: true
      url: https://gstatic.com/generate_204
      interval: 300
      timeout: 5000
      expected-status: 204
    header:
      User-Agent: [Happ]
      x-hwid: [c404no99i108387b]
      x-device-os: [Android]
      x-ver-os: [16]
      x-device-model: [samsung SM-S918B]

  Glush:
    type: http
    url: "https://sub.../***" # << ссылка подписки
    path: ./glush.yaml
    interval: 10800
    health-check:
      enable: true
      url: https://gstatic.com/generate_204
      interval: 300
      timeout: 5000
      expected-status: 204
    header:
      User-Agent: [Happ]
      x-hwid: [c404no99i108387b]
      x-device-os: [Android]
      x-ver-os: [16]
      x-device-model: [samsung SM-S918B]

proxy-groups:

  - name: AI
    type: fallback
    interval: 300
    icon: https://fastly.jsdelivr.net/gh/Koolson/Qure@master/IconSet/Color/ChatGPT.png
    include-all: true
    exclude-filter: "🇷🇺|Russia|Россия|Беларусь|Казахстан|Kazakhstan"

  - name: PROXY
    type: url-test
    interval: 300
    icon: https://fastly.jsdelivr.net/gh/Koolson/Qure@master/IconSet/Color/Proxy.png
    include-all: true
    exclude-filter: "🇷🇺|Russia|Россия|Kazakhstan"

  - name: PROXY-RU
    type: url-test
    interval: 60
    icon: https://fastly.jsdelivr.net/gh/Koolson/Qure@master/IconSet/Color/Russia.png
    include-all: true
    filter: "🇷🇺|Russia|Россия"

  - name: YOUTUBE
    type: url-test
    interval: 30
    icon: https://fastly.jsdelivr.net/gh/Koolson/Qure@master/IconSet/Color/YouTube.png
    proxies: [PROXY-RU, PROXY]

rule-providers:

  adobe:
    behavior: classical
    type: http
    url: "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/refs/heads/master/rule/Clash/Adobe/Adobe.yaml"
    interval: 86400
    path: ./ruleset/adobe.yaml

  claude:
    behavior: classical
    type: http
    url: "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/refs/heads/master/rule/Clash/Claude/Claude.yaml"
    interval: 86400
    path: ./ruleset/claude.yaml

  discord-domain:
    behavior: classical
    type: http
    url: "https://raw.githubusercontent.com/fildunsky/clash_discord/refs/heads/main/discord-domain.yaml"
    interval: 86400
    path: ./ruleset/discord-domain.yaml

  discord-ip:
    behavior: ipcidr
    type: http
    format: text
    url: "https://raw.githubusercontent.com/fildunsky/clash_discord/refs/heads/main/discord-ip.list"
    interval: 86400
    path: ./ruleset/discord-ip.list

  facebook:
    behavior: classical
    type: http
    url: "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/Clash/Facebook/Facebook.yaml"
    interval: 86400
    path: ./ruleset/facebook.yaml

  gemini:
    behavior: domain
    type: http
    url: "https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/refs/heads/meta/geo/geosite/google-gemini.yaml"
    interval: 86400
    path: ./ruleset/gemini.yaml

  github:
    behavior: classical
    type: http
    url: "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/refs/heads/master/rule/Clash/GitHub/GitHub.yaml"
    interval: 86400
    path: ./ruleset/github.yaml

  instagram:
    behavior: classical
    type: http
    url: "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/Clash/Instagram/Instagram.yaml"
    interval: 86400
    path: ./ruleset/instagram.yaml

  intel:
    behavior: classical
    type: http
    url: "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/Clash/Intel/Intel.yaml"
    interval: 86400
    path: ./ruleset/intel.yaml

  mega:
    behavior: classical
    type: http
    url: "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/refs/heads/master/rule/Clash/MEGA/MEGA.yaml"
    interval: 86400
    path: ./ruleset/mega.yaml

  microsoft:
    behavior: classical
    type: http
    url: "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/refs/heads/master/rule/Clash/Microsoft/Microsoft.yaml"
    interval: 86400
    path: ./ruleset/microsoft.yaml

  notion:
    behavior: classical
    type: http
    url: "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/refs/heads/master/rule/Clash/Notion/Notion.yaml"
    interval: 86400
    path: ./ruleset/notion.yaml

  openai:
    behavior: classical
    type: http
    format: yaml
    url: "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/refs/heads/master/rule/Clash/OpenAI/OpenAI.yaml"
    interval: 86400
    path: ./ruleset/openai.yaml

  ru-blocked:
    behavior: domain
    type: http
    format: text
    url: 'https://cdn.jsdelivr.net/gh/shvchk/unblock-net/lists/clash/ru-blocked'
    interval: 86400
    path: ./ruleset/ru-blocked.yaml

  soundcloud:
    behavior: classical
    type: http
    url: "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/refs/heads/master/rule/Clash/SoundCloud/SoundCloud.yaml"
    interval: 86400
    path: ./ruleset/soundcloud.yaml

  speedtest:
    behavior: classical
    type: http
    url: "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/Clash/Speedtest/Speedtest.yaml"
    interval: 86400
    path: ./ruleset/speedtest.yaml

  spotify:
    behavior: classical
    type: http
    url: "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/refs/heads/master/rule/Clash/Spotify/Spotify.yaml"
    interval: 86400
    path: ./ruleset/spotify.yaml

  steam:
    behavior: classical
    type: http
    format: yaml
    url: "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/Clash/Steam/Steam.yaml"
    interval: 86400
    path: ./ruleset/steam.yaml

  telegram:
    behavior: classical
    type: http
    url: "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/refs/heads/master/rule/Clash/Telegram/Telegram.yaml"
    interval: 86400
    path: ./ruleset/telegram.yaml

  telegram-ip:
    behavior: ipcidr
    format: text
    type: http
    url: "https://core.telegram.org/resources/cidr.txt"
    interval: 86400
    path: ./ruleset/telegram-ip.txt
    proxy: PROXY

  tik-tok:
    behavior: classical
    type: http
    url: "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/refs/heads/master/rule/Clash/TikTok/TikTok.yaml"
    interval: 86400
    path: ./ruleset/tik-tok.yaml

  twitter:
    behavior: classical
    type: http
    url: "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/Clash/Twitter/Twitter.yaml"
    interval: 86400
    path: ./ruleset/twitter.yaml

  vimeo:
    behavior: classical
    type: http
    url: "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/Clash/Vimeo/Vimeo.yaml"
    interval: 86400
    path: ./ruleset/vimeo.yaml

  whatsapp:
    behavior: classical
    type: http
    url: "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/Clash/Whatsapp/Whatsapp.yaml"
    interval: 86400
    path: ./ruleset/whatsapp.yaml

  wix:
    behavior: classical
    type: http
    url: "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/Clash/WIX/WIX.yaml"
    interval: 86400
    path: ./ruleset/wix.yaml

  youtube:
    behavior: classical
    type: http
    url: "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/Clash/YouTube/YouTube.yaml"
    interval: 86400
    path: ./ruleset/youtube.yaml

rules:
  - AND,((NETWORK,UDP),(DST-PORT,443)),REJECT
  - DOMAIN-KEYWORD,4pda,PROXY
  - DOMAIN-SUFFIX,ip.wtf,PROXY
  - RULE-SET,adobe,PROXY
  - RULE-SET,claude,AI
  - IP-CIDR,160.79.104.0/23,AI
  - SRC-IP-CIDR,160.79.104.0/23,AI
  - RULE-SET,discord-domain,PROXY
  - RULE-SET,discord-ip,PROXY
  - RULE-SET,facebook,PROXY
  - RULE-SET,gemini,PROXY
  - RULE-SET,github,PROXY
  # Google Meet >>
  - IP-CIDR,74.125.250.0/24,PROXY
  - IP-CIDR,74.125.247.128/32,PROXY
  - IP-CIDR,142.250.82.0/24,PROXY
  - IP-CIDR6,2001:4860:4864:5::0/64,PROXY
  - IP-CIDR6,2001:4860:4864:4:8000::/128,PROXY
  - IP-CIDR6,2001:4860:4864:6::/64,PROXY
  - DOMAIN-SUFFIX,workspace.turns.goog,PROXY
  - DOMAIN-SUFFIX,meet.turns.goog,PROXY
  - DOMAIN-SUFFIX,meet.google.com,PROXY
# << Google Meet
  - RULE-SET,youtube,YOUTUBE
  - RULE-SET,instagram,PROXY
  - RULE-SET,intel,PROXY
  - RULE-SET,microsoft,PROXY
  - RULE-SET,notion,PROXY
  - RULE-SET,openai,AI
  - RULE-SET,soundcloud,PROXY
  - RULE-SET,speedtest,PROXY
  - RULE-SET,spotify,PROXY
  - RULE-SET,spotify,PROXY
  - RULE-SET,steam,PROXY
  - RULE-SET,telegram,PROXY
  - RULE-SET,telegram-ip,PROXY
  - RULE-SET,tik-tok,PROXY
  - RULE-SET,twitter,PROXY
  - RULE-SET,vimeo,PROXY
  - RULE-SET,whatsapp,PROXY
  - RULE-SET,wix,PROXY
  - RULE-SET,ru-blocked,PROXY
  - MATCH,GLOBAL
```

### Добавляем сайт в fake-ip

Наверху конфига в блоке dns: найдите:

```YAML
  fake-ip-filter:
    - 'ip.wtf'
    - '*.ip.wtf'
```

новый сайт (в примере google.com) добавляется строкой ниже с 4 пробелами в начале:

```YAML
  fake-ip-filter:
    - 'ip.wtf'
    - '*.ip.wtf'
    - 'google.com'
    - '*.google.com'
```

> 

  *.google.com не включает в себя сам google.com, а только его поддомены, поэтому приходится прописывать дважды.
далее в самом низу, под rules:

```YAML
rules:
  - DOMAIN-SUFFIX,ip.wtf,PROXY
```

нужно так же добавить с 2 пробелами в начале:

```YAML
rules:
  - DOMAIN-SUFFIX,ip.wtf,PROXY
  - DOMAIN-SUFFIX,google.com,PROXY
```

Если нужно, чтобы google.com и все его поддомены (mail.google.com, search.google.com, sheets.google.com и тп) отправились в группу PROXY.

### Не работает curl с fake-ip

В этом режиме не работает curl. Если вы привыкли качать файлы/программы на роутер по SSH, то быстрый фикс (надеюсь, автор скоро это исправит):

```Bash
nano /etc/firewall.user
```

Добавить туда две строки:

```Bash
nft add rule inet fw4 mangle_output ip daddr 198.18.0.0/15 counter mark set 0x1 comment "clash-output-fakeip"
nft add rule inet fw4 mangle_output meta skuid 0 counter return comment "clash-skip-root"
```

Активировать пользовательские правила, перезагрузить firewall:

```Bash
uci add firewall include
uci set firewall.@include[-1].type='script'
uci set firewall.@include[-1].path='/etc/firewall.user'
uci set firewall.@include[-1].enabled='1'
uci set firewall.@include[-1].fw4_compatible='1'
uci commit firewall
/etc/init.d/firewall restart
```

Стандартно, даже при работе в режиме mode: rule с единственным правилом - MATCH,DIRECT, весь трафик на роутере всё равно сначала проходит через ядро Mihomo, а оно пропускает его дальше, напрямую, это влияет на скорость, пинг, грузит процессор роутера, могут не работать проброшеные порты, локальные сервисы, домашние NAS, в тоннели попадает торрент трафик, который невозможно выделить и вынести в отдельные правила и т.п.

## fake-ip-filter-mode: whitelist

Позволяет направлять в ядро Mihomo только то, что попадает в белый список fake-ip. SSClash c 4 версии лучше поддерживает такой режим.
В настройках SSClash (вторая вкладка) необходимо выбрать:
🎯 Explicit Mode (Precise control) также, рекомендую Mixed (TCP+UDP) для нормальной работы голоса и видео в мессенджерах.
В конфиге добавить в секцию dns: все ваши classical и/или domain списки доменов и доменные суффиксы:

```YAML
dns:
  enhanced-mode: fake-ip
  fake-ip-range: 198.18.0.0/15
  fake-ip-filter-mode: whitelist
  fake-ip-filter:
    - '*.4pda.to'
    - '*.4pda.ws'
    - 'ip.wtf'
    - '*.ip.wtf'
    - 'workspace.turns.goog'
    - '*.workspace.turns.goog'
    - 'meet.turns.goog'
    - '*.meet.turns.goog'
    - 'meet.google.com'
    - '*.meet.google.com'
    - RULE-SET:telegram
    - RULE-SET:youtube
    - RULE-SET:whatsapp
```

> 

  - '+.ip.wtf' работает аналогично - DOMAIN-SUFFIX,ip.wtf 

```YAML
rule-providers:

  telegram:
    behavior: classical
    type: http
    url: "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/refs/heads/master/rule/Clash/Telegram/Telegram.yaml"    
    interval: 86400
    path: ./ruleset/telegram.yaml

  telegram-ip:
    behavior: ipcidr
    format: text
    type: http
    url: "https://core.telegram.org/resources/cidr.txt"
    interval: 86400
    path: ./ruleset/telegram-ip.txt
    proxy: PROXY

  youtube:
    behavior: classical
    type: http
    url: "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/Clash/YouTube/YouTube.yaml"
    interval: 86400
    path: ./ruleset/youtube.yaml

  whatsapp:
    behavior: classical
    type: http
    url: "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/Clash/Whatsapp/Whatsapp.yaml"
    interval: 86400
    path: ./ruleset/whatsapp.yaml

rules:
  - DOMAIN-KEYWORD,4pda,PROXY
  - DOMAIN-SUFFIX,ip.wtf,PROXY
  - DOMAIN-SUFFIX,workspace.turns.goog,PROXY
  - DOMAIN-SUFFIX,meet.turns.goog,PROXY
  - DOMAIN-SUFFIX,meet.google.com,PROXY
  - RULE-SET,youtube,YOUTUBE
  - RULE-SET,telegram-ip,PROXY
  - MATCH,PROXY
```

ipcidr списки нельзя добавлять в блок dns:, чтобы такие списки сработали (в примере выше это официальный диапазон IP адресов telegram-ip), такие RULE-SET должны быть перечислены в rules: (и не должны быть направлены в DIRECT), тогда SSClash их тоже автоматически пропишет в свой технический IPCIDR список /opt/clash/lst/fakeip-whitelist-ipcidr.txt (в интерфейсе ssclash это третья вкладка Rulesets).

> 

  После этих манипуляций в панели Dashboard в соединениях за редким исключением больше не должен отображаться трафик, который идёт напрямую в DIRECT, так как через ядро он уже не будет проходить вообще.
Сохраняем и перезапускаем сервис clash кнопкой stop/start service в интерфейсе или командой:

```Bash
service clash restart
```

## Мобильный интернет (БС)

Для обхода Белых Списков (когда связь глушат и работает только Яндекс, Озон и Макс), нужен сервер, который входит в диапазоны этих белых списков.

> 

  Чтобы подписки и правила не качались заново после перезагрузки роутера, в настройках SSClash снимите галочку с 💾 Хранить правила и proxy-providers в RAM (tmpfs) тогда они будут храниться в постоянной памяти роутера.
Например, ASB, Furk, SouthNetworks, Ledokol, VME_Boost, Shadow, Burger. Кстати, Glush - скамеры.
В этом конфиге весь трафик идёт через группу PROXY с зарубежными IP, все .ru, .su и .рф сайты не из белых списков и YouTube идут через серверы в РФ, чтобы не было рекламы, а если все эти серверы RU-PROXY недоступны, поток переключается на зарубежные PROXY. Белосписочные сайты идут мимо тоннелей напрямую в DIRECT.

> 

  На многих БС подписках перестал нормально работать Telegram, нужно выбрать режим Proxy Mode: TPROXY (вместо MIXED) во вкладке настроек ssclash

```YAML
mode: rule
# Proxy Mode: TPROXY
tproxy-port: 7894
ipv6: false
log-level: error
allow-lan: false
unified-delay: true
tcp-concurrent: true
external-controller: 0.0.0.0:9090
external-ui: ./ui
external-ui-url: "https://github.com/Zephyruso/zashboard/releases/latest/download/dist-cdn-fonts.zip"

hosts:
  app.4pda.to: 31.131.253.250
  ntc.party: 130.255.77.28

dns:
  enable: true
  ipv6: false
  listen: 0.0.0.0:7874
  enhanced-mode: redir-host
  nameserver:
    - 77.88.8.8
    - 77.88.8.2
  nameserver-policy:
    "+.lan": system
    "msftconnecttest.com": system
    "msftncsi.com": system

keep-alive-idle: 15
keep-alive-interval: 15

profile:
  store-selected: true

routing-mark: 2

sniffer:
  enable: true
  force-dns-mapping: true
  parse-pure-ip: true
  sniff:
    HTTP:
      ports:
      - 80
      - 8080-8880
      override-destination: true
    TLS:
      ports:
      - 443
      - 8443

proxy-providers:

  LastDep:
    type: http
    url: "https://sub.../***" # << ссылка подписки
    path: ./proxy_providers/lastdep.yaml # имя файла подписки на роутере
    interval: 10800
    health-check:
      enable: true
      url: https://gstatic.com/generate_204
      interval: 300
      timeout: 5000
      expected-status: 204
    header:
      User-Agent: [FlClash] # или [mihomo/1.19.27] или [Happ]
      x-hwid: [Router]
      x-device-os: [OpenWrt]
      x-ver-os: ["25.12.4"]
      x-device-model: [Huasifei WH3000 Pro]

proxy-groups:

  - name: PROXY
    type: url-test
    url: 'https://www.gstatic.com/generate_204'
    interval: 300
    timeout: 5000
    icon: https://fastly.jsdelivr.net/gh/Koolson/Qure@master/IconSet/Color/Proxy.png
    include-all: true
    exclude-filter: "🇷🇺|Russia|Россия"

  - name: PROXY-RU
    type: url-test
    url: 'http://ya.ru'
    interval: 300
    timeout: 5000
    icon: https://fastly.jsdelivr.net/gh/Koolson/Qure@master/IconSet/Color/Russia.png
    include-all: true
    filter: "🇷🇺|Russia|Россия"

  - name: RU
    type: url-test
    interval: 300
    timeout: 5000
    proxies: [PROXY-RU, PROXY]

rule-providers:

  whitelist:
    behavior: domain
    format: text
    type: http
    url: "https://raw.githubusercontent.com/hxehex/russia-mobile-internet-whitelist/refs/heads/main/whitelist.txt"
    interval: 86400
    proxy: PROXY
    path: ./ruleset/cidrwhitelist.txt

  vk:
    behavior: classical
    type: http
    url: "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/Clash/VK/VK.yaml"
    interval: 86400
    proxy: PROXY
    path: ./ruleset/vk.yaml

  yandex:
    behavior: classical
    type: http
    url: "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/Clash/Yandex/Yandex.yaml"
    interval: 86400
    proxy: PROXY
    path: ./ruleset/yandex.yaml

  russia-outside:
    behavior: classical
    type: http
    format: text
    url: "https://raw.githubusercontent.com/itdoginfo/allow-domains/main/Russia/outside-clashx.lst"
    interval: 86400
    proxy: PROXY
    path: ./ruleset/russia-outside.yaml

  russia-inside:
    behavior: classical
    type: http
    format: text
    url: "https://raw.githubusercontent.com/itdoginfo/allow-domains/main/Russia/inside-clashx.lst"
    interval: 86400
    proxy: PROXY
    path: ./ruleset/russia-inside.yaml

  youtube:
    behavior: classical
    type: http
    url: "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/Clash/YouTube/YouTube.yaml"
    interval: 86400
    proxy: PROXY
    path: ./ruleset/youtube.yaml

rules:
  - AND,((NETWORK,UDP),(DST-PORT,443)),REJECT

# 2GIS
  - DOMAIN-SUFFIX,2gis.ru,DIRECT
  - DOMAIN-SUFFIX,2gis.com,DIRECT

# Alfa
  - DOMAIN-SUFFIX,alfabank.ru,DIRECT
  - DOMAIN-SUFFIX,servicecdn.ru,DIRECT
  - DOMAIN-SUFFIX,mirconnect.ru,DIRECT
  - DOMAIN-SUFFIX,otm-r.ru,DIRECT

# T-Bank
  - DOMAIN-SUFFIX,appsflyersdk.com,REJECT
  - DOMAIN-SUFFIX,app-measurement.com,REJECT
  - DOMAIN-KEYWORD,t-bank-app,DIRECT
  - DOMAIN-SUFFIX,t-bank.ru,DIRECT
  - DOMAIN-SUFFIX,tbank.ru,DIRECT
  - DOMAIN-KEYWORD,tinkoff,DIRECT
  - DOMAIN-SUFFIX,tinsurance.ru,DIRECT
  - DOMAIN-SUFFIX,t-static.ru,DIRECT
  - DOMAIN-SUFFIX,cdn-tinkoff.ru,DIRECT
  
# Mobile Opers
  - DOMAIN-SUFFIX,beeline.ru,DIRECT
  - DOMAIN-SUFFIX,megafon.ru,DIRECT
  - DOMAIN-SUFFIX,mts.ru,DIRECT
  - DOMAIN-SUFFIX,t2.ru,DIRECT
  - DOMAIN-SUFFIX,tele2.ru,DIRECT
  - DOMAIN-SUFFIX,yota.ru,DIRECT

# Markets
  - DOMAIN-SUFFIX,wildberries.ru,DIRECT
  - DOMAIN-SUFFIX,wb.ru,DIRECT
  - DOMAIN-SUFFIX,paywb.com,DIRECT
  - DOMAIN-SUFFIX,wbbasket.ru,DIRECT
  - DOMAIN-SUFFIX,avito.ru,DIRECT
  - DOMAIN-SUFFIX,avito.st,DIRECT
  - DOMAIN-SUFFIX,ozon.ru,DIRECT
  - DOMAIN-SUFFIX,ozone.ru,DIRECT

# Sber
  - DOMAIN-SUFFIX,mindbox.ru,DIRECT
  - DOMAIN-SUFFIX,adriver.ru,REJECT
  - DOMAIN-SUFFIX,otello.ru,DIRECT
  - DOMAIN-KEYWORD,sberbank,DIRECT
  - DOMAIN-SUFFIX,sber.ru,DIRECT
  - DOMAIN-SUFFIX,mail.ru,DIRECT
  - DOMAIN-SUFFIX,imgsmail.ru,DIRECT
  - DOMAIN-SUFFIX,ok.ru,DIRECT

# VK
  - DOMAIN-SUFFIX,vkvideo.ru,DIRECT
  - DOMAIN-SUFFIX,vk-portal.net,DIRECT
  - DOMAIN-SUFFIX,vk.com,DIRECT
  - DOMAIN-SUFFIX,vk.ru,DIRECT
  - DOMAIN-SUFFIX,vk-analytics.ru,DIRECT
  - DOMAIN-SUFFIX,vk.link,DIRECT

# YouTube & Google Play
  - DOMAIN-SUFFIX,gvt1.com,PROXY
  - RULE-SET,youtube,RU

# White
  - DOMAIN-SUFFIX,qms.ru,DIRECT
  - DOMAIN-SUFFIX,oneme.ru,DIRECT
  - DOMAIN-SUFFIX,okcdn.ru,DIRECT
  - DOMAIN-SUFFIX,mycdn.me,DIRECT
  - DOMAIN-SUFFIX,dzen.ru,DIRECT
  - DOMAIN-SUFFIX,gosuslugi.ru,DIRECT
  - DOMAIN-SUFFIX,government.ru,DIRECT
  - DOMAIN-SUFFIX,gu-st.ru,DIRECT
  - DOMAIN-SUFFIX,kinopoisk.ru,DIRECT
  - DOMAIN-SUFFIX,lemanapro.ru,DIRECT
  - DOMAIN-SUFFIX,lenta.ru,DIRECT
  - DOMAIN-SUFFIX,lmru.tech,DIRECT
  - DOMAIN-SUFFIX,max.ru,DIRECT
  - DOMAIN-SUFFIX,mradx.net,DIRECT
  - DOMAIN-SUFFIX,pochta.ru,DIRECT
  - DOMAIN-SUFFIX,rambler.ru,DIRECT
  - DOMAIN-SUFFIX,rbc.ru,DIRECT
  - DOMAIN-SUFFIX,res-nsdi.ru,DIRECT
  - DOMAIN-SUFFIX,rustore.ru,DIRECT
  - DOMAIN-SUFFIX,inappstory.ru,DIRECT
  - DOMAIN-SUFFIX,rutube.ru,DIRECT
  - DOMAIN-SUFFIX,rutubelist.ru,DIRECT
  - DOMAIN-SUFFIX,rzd.ru,DIRECT
  - DOMAIN-SUFFIX,taximaxim.ru,DIRECT
  - DOMAIN-SUFFIX,tutu.ru,DIRECT
  - DOMAIN-SUFFIX,userapi.com,DIRECT
  - DOMAIN-SUFFIX,vtb.ru,DIRECT
  - DOMAIN-SUFFIX,xn--80ajghhoc2aj1c8b.xn--p1ai,DIRECT # честныйзнак.рф
  - DOMAIN-SUFFIX,ya.ru,DIRECT
  - DOMAIN-SUFFIX,yastatic.net,DIRECT
  - DOMAIN-SUFFIX,gov.ru,DIRECT
  - DOMAIN-KEYWORD,yandex,DIRECT
  - RULE-SET,whitelist,DIRECT
  - RULE-SET,vk,DIRECT
  - RULE-SET,yandex,DIRECT
  - RULE-SET,russia-outside,DIRECT
  - RULE-SET,russia-inside,PROXY
  - DOMAIN-SUFFIX,d-cd.net,RU
  - DOMAIN-SUFFIX,ru,RU
  - DOMAIN-SUFFIX,su,RU
  - DOMAIN-SUFFIX,рф,RU
  - MATCH,PROXY
```

> 

  Если у вас в этом режиме не обновляется список пакетов на роутере, но доступ из браузера к openwrt.org есть, можно по SSH ввести команду:
export https_proxy=http://127.0.0.1:7890
  После этого root трафик на роутере для текущей SSH сессии тоже начнёт ходить через ядро mihomo и команда apk update должна заработать.
  В config.yaml обязательны:

```YAML
mixed-port: 7890
allow-lan: true
```

  Для того, чтобы качать с помощью curl через proxy:

```Bash
curl -x http://127.0.0.1:7890 -L https://github.com/MetaCubeX/mihomo/releases/download/v1.19.33/mihomo-linux-arm64-v1.19.33.gz -o /tmp/clash.gz
```

## VLESS

```YAML
proxies:
      
  - name: MyServer
    type: vless
    server: XX.XXX.XX.XXX
    port: 443
    uuid: dedaBaba-papa-mama-ya43-4857s75
    network: tcp
    tls: true
    udp: true
    flow: xtls-rprx-vision
    servername: yahoo.com
    reality-opts:
      public-key: 583z_mc-Antoha-fLxrlB5tpszb4Z8$5fh8)*93h
      short-id: 848485Hdhbfh
    client-fingerprint: chrome

proxy-groups:

  - name: PROXY
    type: select
    proxies:
      - MyServer
    url: http://cp.cloudflare.com/generate_204
    interval: 300
```

Для того, чтобы создавать свои конфиги VLESS, вам нужен арендованный VDP/VPS сервер с установленной 3X-UI / X-UI панелью.

## Несколько серверов

Если у вас несколько серверов и нужен резерв - при недоступности первого, автоматически включается второй и далее по списку…

```YAML
proxies:
      
  - name: 🇫🇷 France
    type: vless
    server: XX.XXX.XX.XXX
    port: 443
    uuid: dedaBaba-papa-mama-ya43-4857s75
    network: tcp
    tls: true
    udp: true
    flow: xtls-rprx-vision
    servername: yahoo.com
    reality-opts:
      public-key: 583z_mc-Antoha-fLxrlB5tpszb4Z8$5fh8)*93h
      short-id: 848485Hdhbfh
    client-fingerprint: chrome

  - name: 🇧🇬 Bulgaria
    type: vless
    server: XX.XXX.XX.XXX
    port: 443
    uuid: dedaBaba-papa-mama-ya43-4857s75
    network: tcp
    tls: true
    udp: true
    flow: xtls-rprx-vision
    servername: yahoo.com
    reality-opts:
      public-key: 583z_mc-Antoha-fLxrlB5tpszb4Z8$5fh8)*93h
      short-id: 848485Hdhbfh
    client-fingerprint: chrome

  - name: 🇫🇮 Finland
    type: vless
    server: XX.XXX.XX.XXX
    port: 443
    uuid: dedaBaba-papa-mama-ya43-4857s75
    network: tcp
    tls: true
    udp: true
    flow: xtls-rprx-vision
    servername: yahoo.com
    reality-opts:
      public-key: 583z_mc-Antoha-fLxrlB5tpszb4Z8$5fh8)*93h
      short-id: 848485Hdhbfh
    client-fingerprint: chrome

proxy-groups:

  - name: PROXY
    type: fallback
    proxies:
      - 🇫🇷 France
      - 🇧🇬 Bulgaria
      - 🇫🇮 Finland
    url: http://cp.cloudflare.com/generate_204
    interval: 300
```

Для того, чтобы создавать свои конфиги VLESS, вам нужен арендованный VDP/VPS сервер с установленной 3X-UI / X-UI панелью.

## Ссылки vless:// без конвертации

Один из способов добавить в вашу конфигурацию SSClash конфиги vless, vmess, trojan, h2, ShadowSocks, SOCKS5 без конвертации в формат Clash - это создание подписки файлом.
Это можно сделать через SSH в терминале:

```Bash
nano /opt/clash/proxy_providers/local.yaml
```

```YAML
vless://cefd2353d9--b61b-72251fa359fa@XX.XXX.XXX.XXX:443?type=tcp&security=reality&pbk=
vless://d5ghf4565f6-04e8-6256c85d9b38@XX.X.XXX.XXX:XXX?type=tcp&security=reality
ss://YWV364FHfd@4zL%TI1NVRJFpvOXU4WT0@XX.XXX.XXX.XXX:XXXXX?type=tcp#moikrutoiservak
```

Затем в конфигурации Clash добавьте:

```YAML
proxy-providers:

  local:
    type: file
    path: ./proxy_providers/local.yaml
    format: text

proxy-groups:

  - name: PROXY
    type: fallback
    url: https://gstatic.com/generate_204
    expected-status: 204
    interval: 300
    lazy: true
    icon: https://fastly.jsdelivr.net/gh/Koolson/Qure@master/IconSet/Color/Proxy.png
    use: [local]
```

Подробнее про подписки.

## Конвертация в формат Clash

Удобный пошаговый Mihomo Configurator конфигуратор. На v2rayse.com можно конвертировать ссылки vless:// (vmess, trojan, ss…) в формат Clash.
Вставьте ссылку, выберите Mihomo, нажмите CONVERT, в окошке промотайте до proxies: - скопируйте оттуда только сами серверы, сконвертированные в нужный формат.
Есть ещё такой конвертер на русском, но там могут быть баги. Можно просить ChatGPT конвертировать vless ссылку в формат Clash, он отлично справится и возможно после этого вы даже научитесь их читать и доставать все нужные поля прямо из такой ссылки самостоятельно. Если ключ spiderX: пустой /, этот параметр нужно удалить.

## Правила и списки

Вот какие правила понимает Clash согласно официальной wiki https://wiki.metacubex.one/en/config/rules/
Правила прописываются в блок rules: и исполняются по порядку сверху вниз. Иногда это важно. На мой взгляд, для начала освоения Clash вам будет достаточно понять, следующие типы правил:

```YAML
rules:

- DOMAIN,ad.com,REJECT
- DOMAIN-SUFFIX,google.com,PROXY
- DOMAIN-KEYWORD,google,PROXY
- RULE-SET,providername,PROXY
- MATCH,DIRECT
```

REJECT - запрещает соединения, так можно резать рекламу, PROXY - здесь вместо этого может быть любое имя сервера или группы, через которую вы хотите пустить правило. DIRECT - пустить напрямую, минуя тоннель.
DOMAIN - это просто домен, а DOMAIN-SUFFIX - это все домены после точки (например mail.google.com, www.google.com, ai.google.com и тд). DOMAIN-KEYWORD означает все домены, в которых есть ключевое слово (например google-shmoogle-barabek.ru). RULE-SET - набор правил (скачанный список правил), который прописан выше в rule-providers:
- MATCH,DIRECT - желательно прописать последним, чтобы всё остальное, что не попало в правила, пошло напрямую в DIRECT, либо - MATCH,PROXY - чтобы всё пошло в тоннель PROXY.

## Пускаем одно устройство в сети напрямую (мимо тоннеля)

Допустим в вашей сети есть компьютер с IP адресом 192.168.1.77 и вы хотите, чтобы он не знал о существовании ВПН вообще (ходил напрямую, как будто бы на роутере не установлен Clash).

```YAML
- IP-CIDR,192.168.1.77/32,DIRECT
- SRC-IP-CIDR,192.168.1.77/32,DIRECT
```

#### Исключаем конкретные порты:

DST-PORT - порт назначения, SRC-PORT - исходящий порт источника, если не понятно, пробуйте прописывать сразу двумя правилами. 7777 - номер порта, который нужно направить в DIRECT (напрямую)

```YAML
- DST-PORT,7777,DIRECT
- SRC-PORT,7777,DIRECT
```

Вместо DIRECT может быть имя сервера или группы, тогда правило пойдёт в тоннель.

## Как работают списки правил

Clash умеет подгружать либо локальные списки доменов, суффиксов, IP диапазонов, так и скачивать такие списки из интернета. Для описания списков используется блок rule-providers:

```YAML
  youtube: # название списка
    behavior: classical # его тип, если используете готовые от BlackMatrix7, у него указан тип для каждого списка, можно брать оттуда
    type: http # http означает - удалённый, file - локальный список
    url: "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/Clash/YouTube/YouTube.yaml" # ссылка на список
    interval: 86400 # интервал обновления каждые 24 часа
    path: ./ruleset/youtube.yaml # куда сохранять файл списка, в данном случае это /opt/clash/ruleset/youtube.yaml
```

Сам по себе описанный в rule-providers: список никак не влияет на работу Clash, чтобы он заработал, для него нужно добавить правило RULE-SET в блок rules:

```YAML
  - RULE-SET,youtube,PROXY
```

PROXY в примере выше означает название вашей группы серверов или название сервера, здесь задаётся, через какой тоннель будет проходить этот список.

> 

  Обратите внимание на важность соблюдения вложенности, под rules: необходимо отступить два пробела

```YAML
rules:
  - RULE-SET,youtube,PROXY
```

## Скачивание списков правил через proxy

Если Github или какие-то конкретные списки правил оттуда у вас уже блокируются провайдером, Clash умеет их скачивать через любой настроенный в нём тоннель. В примере имя группы или сервера VPN, добавьте в блок описания списка строку

```YAML
proxy: VPN
```

То есть, примерно так:

```YAML
  youtube:
    behavior: classical
    type: http
    url: "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/Clash/YouTube/YouTube.yaml"
    interval: 86400
    path: ./ruleset/youtube.yaml
    proxy: VPN
```

## Виды списков

### Classical

behavior: classical
Тип classical поддерживает все виды правил, кроме rule-set и sub-rule.
format: yaml должен выглядеть примерно так:

```YAML
payload:
- DOMAIN-SUFFIX,google.com
- DOMAIN-KEYWORD,google
- DOMAIN,ad.com
- SRC-IP-CIDR,192.168.1.201/32
- IP-CIDR,127.0.0.0/8
- GEOIP,CN
- DST-PORT,80
- SRC-PORT,7777
```

format: text примерно такой

```Plain Text
DOMAIN-SUFFIX,google.com
DOMAIN-KEYWORD,google
DOMAIN,ad.com
SRC-IP-CIDR,192.168.1.201/32
IP-CIDR,127.0.0.0/8
GEOIP,CN
DST-PORT,80
SRC-PORT,7777
```

### Domain

behavior: domain 
Тип domain поддерживает подстановочные знаки Clash.
format: yaml

```YAML
payload:
- '.blogger.com'
- '*.*.microsoft.com'
- 'books.itunes.apple.com'
```

format: text 

```Plain Text
.blogger.com
*.*.microsoft.com
books.itunes.apple.com
```

### IPCIDR

behavior: ipcidr 
format: yaml 

```YAML
payload:
- '192.168.1.0/24'
- '10.0.0.1/32'
```

format: text 

```Plain Text
192.168.1.0/24
10.0.0.1/32
```

## Отключаем YouTube ребёнку

Фиксируем IP, добавляем

```YAML
  - AND,((SRC-IP-CIDR,192.168.1.197/32),(RULE-SET,youtube)),REJECT
```

И ставим его над основным правилом youtube или выше.

## Типы серверов

Какие бывают правила (из официальной Wiki)
Вот как рекомендует прописывать Wireguard или AmneziaWG
официальное Wiki. Для Amnezia просто уберите все знаки # и впишите свои данные. Там же есть примеры конфигов vless, vmess, shadowsocks, socks5 и тп.

## Wireguard и AmneziaWG

Amnezia, это просто обфусцированный Wireguard, Clash умеет с ней работать, можно из любого существующего Wireguard сервера сделать Amnezia, добавив “мусорные” параметры. К примеру, так можно запустить бесплатный конфиг от ProtonVPN (который вы можете получить на год после регистрации.
Прописывается в раздел proxies:

```YAML
- name: "wg"
  type: wireguard
  private-key: eCtXsJZ27+4PbhDkHnB923tkUn2Gj59wZw5wFA75MnU=
  server: 162.159.192.1
  port: 2480
  ip: 172.16.0.2
  public-key: Cr8hWlKvtDt7nrvf+f0brNQQzabAqrjfBvas9pmowjo=
  allowed-ips: ['0.0.0.0/0']
  # pre-shared-key: 31aIhAPwktDGpH4JDhA8GNvjFXEf/a6+UaQRyOAiyfM=
  # reserved: [209,98,59]
  udp: true
  # mtu: 1408
  # dialer-proxy: "ss1" # для создания цепочки прокси можно задать имя сервера/группы, через которую должно идти соединение
  # remote-dns-resolve: true # использовать DNS этого подключения
  # dns: [ 1.1.1.1, 8.8.8.8 ] # Если remote-dns-resolve: true
  # amnezia-wg-option: # Дополнительные параметры для AmneziaWG
  #   jc: 4
  #   jmin: 40
  #   jmax: 70
  #   s1: 0
  #   s2: 0
  #   h1: 1
  #   h2: 2
  #   h4: 3
  #   h3: 4
  ### С 1.19.13 Mihomo понимает AWG 1.5 ключи:
  #   i1: <b 0xc2000000011419fa4bb3599f336777de79f81ca9a8d80d91eeec000044c635cef024a885dcb66d1420a91a8c427e87d6cf8e08b563932f449412cddf77d3e2594ea1c7a183c238a89e9adb7ffa57c133e55c59bec101634db90afb83f75b19fe703179e26a31902324c73f82d9354e1ed8da39af610afcb27e6590a44341a0828e5a3d2f0e0f7b0945d7bf3402feea0ee6332e19bdf48ffc387a97227aa97b205a485d282cd66d1c384bafd63dc42f822c4df2109db5b5646c458236ddcc01ae1c493482128bc0830c9e1233f0027a0d262f92b49d9d8abd9a9e0341f6e1214761043c021d7aa8c464b9d865f5fbe234e49626e00712031703a3e23ef82975f014ee1e1dc428521dc23ce7c6c13663b19906240b3efe403cf30559d798871557e4e60e86c29ea4504ed4d9bb8b549d0e8acd6c334c39bb8fb42ede68fb2aadf00cfc8bcc12df03602bbd4fe701d64a39f7ced112951a83b1dbbe6cd696dd3f15985c1b9fef72fa8d0319708b633cc4681910843ce753fac596ed9945d8b839aeff8d3bf0449197bd0bb22ab8efd5d63eb4a95db8d3ffc796ed5bcf2f4a136a8a36c7a0c65270d511aebac733e61d414050088a1c3d868fb52bc7e57d3d9fd132d78b740a6ecdc6c24936e92c28672dbe00928d89b891865f885aeb4c4996d50c2bbbb7a99ab5de02ac89b3308e57bcecf13f2da0333d1420e18b66b4c23d625d836b538fc0c221d6bd7f566a31fa292b85be96041d8e0bfe655d5dc1afed23eb8f2b3446561bbee7644325cc98d31cea38b865bdcc507e48c6ebdc7553be7bd6ab963d5a14615c4b81da7081c127c791224853e2d19bafdc0d9f3f3a6de898d14abb0e2bc849917e0a599ed4a541268ad0e60ea4d147dc33d17fa82f22aa505ccb53803a31d10a7ca2fea0b290a52ee92c7bf4aab7cea4e3c07b1989364eed87a3c6ba65188cd349d37ce4eefde9ec43bab4b4dc79e03469c2ad6b902e28e0bbbbf696781ad4edf424ffb35ce0236d373629008f142d04b5e08a124237e03e3149f4cdde92d7fae581a1ac332e26b2c9c1a6bdec5b3a9c7a2a870f7a0c25fc6ce245e029b686e346c6d862ad8df6d9b62474fbc31dbb914711f78074d4441f4e6e9edca3c52315a5c0653856e23f681558d669f4a4e6915bcf42b56ce36cb7dd3983b0b1d6fdf0f8efddb68e7ca0ae9dd4570fe6978fbb524109f6ec957ca61f1767ef74eb803b0f16abd0087cf2d01bc1db1c01d97ac81b3196c934586963fe7cf2d310e0739621e8bd00dc23fded18576d8c8f285d7bb5f43b547af3c76235de8b6f757f817683b2151600b11721219212bf27558edd439e73fce951f61d582320e5f4d6c315c71129b719277fc144bbe8ded25ab6d29b6e189c9bd9b16538faf60cc2aab3c3bb81fc2213657f2dd0ceb9b3b871e1423d8d3e8cc008721ef03b28e0ee7bb66b8f2a2ac01ef88df1f21ed49bf1ce435df31ac34485936172567488812429c269b49ee9e3d99652b51a7a614b7c460bf0d2d64d8349ded7345bedab1ea0a766a8470b1242f38d09f7855a32db39516c2bd4bcc538c52fa3a90c8714d4b006a15d9c7a7d04919a1cab48da7cce0d5de1f9e5f8936cffe469132991c6eb84c5191d1bcf69f70c58d9a7b66846440a9f0eef25ee6ab62715b50ca7bef0bc3013d4b62e1639b5028bdf757454356e9326a4c76dabfb497d451a3a1d2dbd46ec283d255799f72dfe878ae25892e25a2542d3ca9018394d8ca35b53ccd94947a8> 
```

## Wireguard

То есть минимальный набор параметров для Wireguard должен быть таким:

```YAML
- name: "wg"
  type: wireguard
  private-key: eCtXsJZ27+4PbhDkHnB923tkUn2Gj59wZw5wFA75MnU=
  server: 162.159.192.1
  port: 2480
  ip: 172.16.0.2
  public-key: Cr8hWlKvtDt7nrvf+f0brNQQzabAqrjfBvas9pmowjo=
  allowed-ips: ['0.0.0.0/0']
  udp: true
```

## Amnezia AWG 1.5

```YAML
- name: "Amnezia"
  type: wireguard
  private-key: eCtXsJZ27+4PbhDkHnB923tkUn2Gj59wZw5wFA75MnU=
  server: 162.159.192.1
  port: 500
  ip: 172.16.0.2
  public-key: Cr8hWlKvtDt7nrvf+f0brNQQzabAqrjfBvas9pmowjo=
  allowed-ips: ['0.0.0.0/0']
  udp: true
  amnezia-wg-option:
    jc: 4
    jmin: 40
    jmax: 70
    s1: 0
    s2: 0
    h1: 1
    h2: 2
    h4: 3
    h3: 4
    i1: <b 0xc2000000011419fa4bb3599f336777de79f81ca9a8d80d91eeec000044c635cef024a885dcb66d1420a91a8c427e87d6cf8e08b563932f449412cddf77d3e2594ea1c7a183c238a89e9adb7ffa57c133e55c59bec101634db90afb83f75b19fe703179e26a31902324c73f82d9354e1ed8da39af610afcb27e6590a44341a0828e5a3d2f0e0f7b0945d7bf3402feea0ee6332e19bdf48ffc387a97227aa97b205a485d282cd66d1c384bafd63dc42f822c4df2109db5b5646c458236ddcc01ae1c493482128bc0830c9e1233f0027a0d262f92b49d9d8abd9a9e0341f6e1214761043c021d7aa8c464b9d865f5fbe234e49626e00712031703a3e23ef82975f014ee1e1dc428521dc23ce7c6c13663b19906240b3efe403cf30559d798871557e4e60e86c29ea4504ed4d9bb8b549d0e8acd6c334c39bb8fb42ede68fb2aadf00cfc8bcc12df03602bbd4fe701d64a39f7ced112951a83b1dbbe6cd696dd3f15985c1b9fef72fa8d0319708b633cc4681910843ce753fac596ed9945d8b839aeff8d3bf0449197bd0bb22ab8efd5d63eb4a95db8d3ffc796ed5bcf2f4a136a8a36c7a0c65270d511aebac733e61d414050088a1c3d868fb52bc7e57d3d9fd132d78b740a6ecdc6c24936e92c28672dbe00928d89b891865f885aeb4c4996d50c2bbbb7a99ab5de02ac89b3308e57bcecf13f2da0333d1420e18b66b4c23d625d836b538fc0c221d6bd7f566a31fa292b85be96041d8e0bfe655d5dc1afed23eb8f2b3446561bbee7644325cc98d31cea38b865bdcc507e48c6ebdc7553be7bd6ab963d5a14615c4b81da7081c127c791224853e2d19bafdc0d9f3f3a6de898d14abb0e2bc849917e0a599ed4a541268ad0e60ea4d147dc33d17fa82f22aa505ccb53803a31d10a7ca2fea0b290a52ee92c7bf4aab7cea4e3c07b1989364eed87a3c6ba65188cd349d37ce4eefde9ec43bab4b4dc79e03469c2ad6b902e28e0bbbbf696781ad4edf424ffb35ce0236d373629008f142d04b5e08a124237e03e3149f4cdde92d7fae581a1ac332e26b2c9c1a6bdec5b3a9c7a2a870f7a0c25fc6ce245e029b686e346c6d862ad8df6d9b62474fbc31dbb914711f78074d4441f4e6e9edca3c52315a5c0653856e23f681558d669f4a4e6915bcf42b56ce36cb7dd3983b0b1d6fdf0f8efddb68e7ca0ae9dd4570fe6978fbb524109f6ec957ca61f1767ef74eb803b0f16abd0087cf2d01bc1db1c01d97ac81b3196c934586963fe7cf2d310e0739621e8bd00dc23fded18576d8c8f285d7bb5f43b547af3c76235de8b6f757f817683b2151600b11721219212bf27558edd439e73fce951f61d582320e5f4d6c315c71129b719277fc144bbe8ded25ab6d29b6e189c9bd9b16538faf60cc2aab3c3bb81fc2213657f2dd0ceb9b3b871e1423d8d3e8cc008721ef03b28e0ee7bb66b8f2a2ac01ef88df1f21ed49bf1ce435df31ac34485936172567488812429c269b49ee9e3d99652b51a7a614b7c460bf0d2d64d8349ded7345bedab1ea0a766a8470b1242f38d09f7855a32db39516c2bd4bcc538c52fa3a90c8714d4b006a15d9c7a7d04919a1cab48da7cce0d5de1f9e5f8936cffe469132991c6eb84c5191d1bcf69f70c58d9a7b66846440a9f0eef25ee6ab62715b50ca7bef0bc3013d4b62e1639b5028bdf757454356e9326a4c76dabfb497d451a3a1d2dbd46ec283d255799f72dfe878ae25892e25a2542d3ca9018394d8ca35b53ccd94947a8> 
```

## VLESS

Основной часто задаваемый вопрос, как конвертировать ссылку вида vless:// в конфиг для Clash.
- Вручную подставить значения, открыв vless:// ссылку в Nekobox, husi, V2rayNG
- Использовать онлайн конвертеры
- Создать подписку в виде текстового файла
- Через Clash Verge Rev - добавив свои ссылки вы сможете посмотреть, как он их прописывает в файл конфига в папке с программой.

```YAML
  - name: 🇳🇱 Amsterdam
    type: vless
    server: XX.XXX.XX.XXX
    port: 443
    uuid: dedaBaba-papa-mama-ya43-4857s75
    network: tcp
    tls: true
    udp: true
    flow: xtls-rprx-vision
    servername: yahoo.com
    reality-opts:
      public-key: 583z_mc-Antoha-fLxrlB5tpszb4Z8$5fh
      short-id: 848485Hdhbfh
    client-fingerprint: chrome
```

Это основные параметры, обычно их бывает достаточно. Если есть необходимость, можно добавить кое-что ещё.

## ShadowSocks

```YAML
- name: "MyShadowSocks"
  type: ss
  server: server
  port: 443
  cipher: 2022-blake3-chacha20-poly1305
  password: "password"
  udp: true
  udp-over-tcp: false
  udp-over-tcp-version: 2
  ip-version: ipv4
  plugin: obfs
  plugin-opts:
    mode: tls
  smux:
    enabled: false
```

## SOCKS5

```YAML
- name: "MySocks"
  type: socks5
  server: server # адрес сервера
  port: 443 # номер порта сервера
  # остальные параметры ниже можно раскомментировать и использовать, если они вам нужны
  # username: username
  # password: password
  # tls: true
  # fingerprint: xxxx
  # skip-cert-verify: true
  # udp: true
  # ip-version: ipv6
```

## Интерфейсы роутера в качестве серверов

Интерфейсы тоже можно прописывать в виде серверов и направлять определённый траффик туда средствами Clash (например, у вас есть корпоративная сеть через Zerotier, к которой требуется доступ напрямую). Прописывается так же в proxies: с добавлением группы proxy-groups:

```YAML
proxies:

  - name: "Zerotier"
    type: direct
    interface-name: ztc43og8zn
    # udp: true
    # ip-version: ipv4
    # routing-mark: 1234
  
proxy-groups:

  - name: ZERO
    type: select
    proxies:
    - Zerotier
```

Хотя можно обойтись без proxies: сразу в proxy-groups:

```YAML
  proxy-groups:
  
  - name: TAILSCALE
	  type: select
	  interface-name: tailscale0
	  proxies:
	  - DIRECT
```

И затем направлять определенные устройства в rules:

```YAML
rules:
  - IP-CIDR,192.168.1.12/32,ZERO
  - IP-CIDR,192.168.1.8/32,TAILSCALE
```

## Группы серверов

После того, как в разделе proxies: вы описали все ваши серверы далее, для вашего удобства, и более гибкой маршрутизации можно создавать группы серверов в proxy-groups: и затем в правилах rules: можно указывать не только один сервер для правила, а целую группу.
Все ключи для описания групп можно посмотреть в официальном wiki.

#### Для чего это может быть нужно?

1. FALLBACK: например, есть бесплатный быстрый конфиг AmneziaWG Cloudflare WARP - через него хорошо смотреть YouTube без рекламы, скорость почти такая же, как скорость провайдера, но бывает так, что он перестаёт работать, а хочется бесперебойной работы. Также имеется арендованный сервер и vless конфиг, но он, к примеру, финский и если смотреть youtube через него, идёт финская реклама и скорость сервера не более 100 мегабит. Можно использовать его как резервный. Настроить группу FALLBACK так, чтобы первым для правила youtube работала Amnezia, а если она отвалится, то использовался финский сервер.
Поезд 🏴‍☠️ Amnezia → 🇫🇮 Helsinki vless отправляется с платформы 9 3/4
Для этого можно использовать тип группы type: fallback - Clash выбирает первый доступный в списке сервер и с периодичностью 60 секунд проверяет доступность (интервал можно сократить, но если сделать его слишком коротким, есть шанс, что будут ложные срабатывания и переключения туда-сюда на разные серверы в списке). Параметр lazy: true означает, что Clash не будет пинговать эти серверы, пока вся группа не задействуется в правилах и не открыт сайт из этих правил.

```YAML
proxy-groups:

  - name: RESERV
    type: fallback
    icon: https://fastly.jsdelivr.net/gh/Koolson/Qure@master/IconSet/Color/Proxy.png
    proxies:
      - 🏴‍☠️ Amnezia
      - 🇫🇮 Helsinki vless
    lazy: true
    url: https://gstatic.com/generate_204
    interval: 60
```

Пока группа RESERV не указана ни в каких правилах и не открыт сайт из этих правил, группа никак не работает и зря не пингуется Clash, чтобы не тратить ресурсы.
Чтобы она заработала, нужно в rule-providers: добавить набор правил для youtube (можно скачать список у BlackMatrix7):

```YAML
rule-providers:

  youtube:
    behavior: classical
    type: http
    url: "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/Clash/YouTube/YouTube.yaml"
    interval: 86400
    path: ./ruleset/youtube.yaml
```

А затем прописать правило для этого списка в rules:

```YAML
rules:

  - RULE-SET,youtube,RESERV
```

1. LOAD-BALANCE распределение нагрузки на ваши серверы (если у вас их несколько). Это может быть полезным, если на вашем роутере одновременно активно пользуется сетью большое количество устройств.

```YAML
proxy-groups:

- name: BALANCE
  type: load-balance
  proxies:
  - 🇫🇮 Helsinki vless
  - 🇳🇱 Amsterdam SS
  - 🇪🇪 Tallin Socks5
  url: https://gstatic.com/generate_204
  interval: 60
  lazy: true
  strategy: consistent-hashing # стратегия балансировки
```

Существует три стратегии распределения нагрузки или балансировки в Clash
- round-robin равномерно распределяет все запросы между всеми серверами группы
- consistent-hashing запросы на один и тот же адрес идут через один и тот же сервер в группе (это полезно, чтобы, к примеру, на YouTube шли запросы с одного и того же IP адреса, а не со всех трёх серверов по очереди.
- sticky-sessions запросы от одного и того же устройства к одному и тому же адресу идут через тот же сервер, такие сессии фиксируются на 10 минут.
Если ничего не понятно, оставьте consistent-hashing как вариант по умолчанию.
Тогда набор правил для списка youtube должен выглядеть так: 

```YAML
rules:

  - RULE-SET,youtube,BALANCE
```

1. URL-TEST Если у вас подписка на огромное количество серверов, которые периодически начинают тормозить или отваливаются (что часто случается с бесплатными подписками), можно использовать тип группы url-test - с заданной периодичностью Clash будет пинговать весь список серверов и выбирать самый быстрый.

```YAML
proxy-groups:

- name: SPEED
  type: url-test
  proxies:
  - 🇰🇿 KZ
  - 🇫🇮 FI
  - 🇳🇱 NL
  - 🇪🇪 EE
  - 🇩🇪 GE
  url: https://gstatic.com/generate_204
  interval: 300
  tolerance: 50
  lazy: true
```

Тогда набор правил для списка youtube должен выглядеть так: 

```YAML
rules:

  - RULE-SET,youtube,SPEED
```

1. SELECT Вы сами вручную выбираете сервер для какого-то конкретного правила через Clash Dashboard, либо Clash использует первый сервер из списка.

```YAML
proxy-groups:

- name: SELECT
  type: select
  proxies:
    - 🇭🇰
    - 🇸🇬
    - 🇺🇸
  url: https://gstatic.com/generate_204
  interval: 300
```

Тогда набор правил для списка youtube должен выглядеть так: 

```YAML
rules:

  - RULE-SET,youtube,SELECT
```

По умолчанию будет выбираться первый сервер, либо тот, который вы выберете вручную через Dashboard.

## Фильтр по ключевым словам

Если у вас много серверов и разных подписок, вы можете создавать автоматические группы с фильтрами по ключевым словам. 

```YAML
  - name: FIN+AWG
    type: select
    include-all: true # включает в себя все серверы
    filter: '🇫🇮|Finland|Helsinki|AWG' # из всех серверов выберет 🇫🇮, Finland, Helsinki или AWG
```

## Цепочка прокси

Метод соединения нескольких прокси-серверов в цепочку для обеспечения высокой безопасности или запутанности. Можно пустить один ваш vless через WARP и таким образом скрыть IP адрес вашего сервера в цепочке от конечных сайтов, которые вы посещаете.
Для этого достаточно в любой из серверов proxies: добавить dialer-proxy: имя сервера
В данном случае в 🔗 WARP добавлен dialer-proxy: 🇳🇱 NL, теперь если пустить траффик через🔗 WARP сервер, тоннель будет проходить сначала через ваш сервер в Нидерландах 🇳🇱 NL, а затем передаваться в Cloudflare WARP, тогда конечный IP адрес будет адресом Cloudflare Нидерландов - таким образом можно заставить работать некоторые AI, например, gemini - гугл как-то палит зарубежные серваки со временем и отмечает, что вы в России, а если ходить через цепочку, то всё работает (пока).

```Bash
proxies:
      
  - name: 🇳🇱 NL
    type: vless
    server: 73.18.127.92
    port: 443
    uuid: dedaBaba-papa-mama-ya43-4857s75
    network: tcp
    tls: true
    udp: true
    flow: xtls-rprx-vision
    servername: yahoo.com
    reality-opts:
      public-key: 583z_mc-Antoha-fLxrlB5tpszb4Z8$5fh8)*93h
      short-id: 848485Hdhbfh
    client-fingerprint: chrome
    
  - name: 🔗 WARP
    dialer-proxy: 🇳🇱 NL # ключевой момент!
    type: wireguard
    private-key: Sgeneri-Sebe-Sam-Instrukciya-Est=
    server: 188.114.97.66
    port: 3138
    ip: 172.16.0.2
    public-key: bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo=
    allowed-ips: ['0.0.0.0/0']
    udp: true
    mtu: 1280
    remote-dns-resolve: true
    dns: [1.1.1.1, 1.0.0.1] 
    amnezia-wg-option:
      jc: 4
      jmin: 40
      jmax: 70
      s1: 0
      s2: 0
      h1: 1
      h2: 2
      h3: 3
      h4: 4
```

## Обновление правил при включении интернета

Через командную строку устанавливаем на роутер текстовый редактор nano:

```Bash
opkg update && opkg install nano
```

Открываем пустой файл для создания скрипта:

```Bash
nano /etc/hotplug.d/iface/40-clash_rules
```

Вставляем туда этот текст (меняем в третьей строке IP на адрес вашего роутера)

```Bash
#!/bin/sh

# Add delay
sleep 10

# API IP address and port
api_base_url="http://192.168.1.1:9090"

# API URL
base_url="$api_base_url/providers/rules"

# Get JSON response with provider names
response=$(curl -s "$base_url")

# Extract provider names using standard utilities
providers=$(echo "$response" | grep -o '"name":"[^"]*"' | sed 's/"name":"\([^"]*\)"/\1/')

# Check if data retrieval was successful
if [ -z "$providers" ]; then
  echo "Failed to retrieve providers or no providers found."
  exit 1
fi

# Loop through each provider name and send PUT request to update
for provider in $providers; do
  echo "Updating provider: $provider"
  curl -X PUT "$base_url/$provider"

  # Check success and output the result
  if [ $? -eq 0 ]; then
    echo "Successfully updated $provider"
  else
    echo "Failed to update $provider"
  fi
done

# Service restart
/etc/init.d/clash reload
```

Выдаём права на исполнение:

```Bash
chmod 755 /etc/hotplug.d/iface/40-clash_rules
```

Теперь при каждой перезагрузке интернета Clash будет обновлять правила. Это не обязательно для его работы, в стандартном конфиге на каждое правило задаётся период обновления 86400 (24 часа), но кому-то в определённых условиях такой вариант пригодится.

## Подписки

Подписки, как правило, содержат сразу несколько серверов с разными конфигурациями и разными странами и обновления настроек самой подписки (если добавились новые серверы или поменялся конфиг) синхронизируются на роутере автоматически.
Подписки описываются в блоке proxy-providers: 
бывают двух типов: type: http (онлайн) и type: file (вы сами добавляете текстовый файл со своими серверами на роутер). Про подписки файлом → ‣ 

```YAML
proxy-providers:

  🇮🇳 India:
    type: http
    url: "https://istanbulsydneyhotel.com/blogs/site/sni.php?country=in"
    path: ./proxy_providers/in.yaml
    interval: 86400
    header:
      User-Agent:
      - "FlClash"
      x-hwid:
      - "OpenWrt"
    health-check:
      enable: true
      url: https://gstatic.com/generate_204
      interval: 300
      timeout: 5000
      lazy: true
      expected-status: 204
      
proxy-groups:

  - name: SUBSCRIPTION
    type: fallback
    url: https://gstatic.com/generate_204
    expected-status: 204
    interval: 300
    lazy: true
    use: [🇮🇳 India]
    exclude-filter: "Купить|Истекает|maintenance"
```

Или просто добавляете use: [🇮🇳 India] строку в любую группу серверов.
Простые подписки, которые ни от кого не маскируются, отдают конфиг файлом напрямую. А более сложные, типа LastDep с лимитом по количеству устройств HWID, отдают подписку только если есть правильный User-Agent (клиент Clash, а не браузер), например FlClash и HWID:

```YAML
    header:
      User-Agent: [mihomo/1.19.25]
      x-hwid: [Router]
      x-device-os: [Openwrt]
      x-ver-os: ["25.12.4"]
      x-device-model: [Magic Router]
```

Подборки бесплатных серверов, просто создаём подписку и в url меняем параметры (страна, тип сервера):

```YAML
https://istanbulsydneyhotel.com/blogs/site/sni.php?country=fl;&kind=vless
```

https://finevpn.org - бесплатные WG (можно обфусцировать Амнезией) на 30 дней, затем бесплатное продление в одно нажатие, с хорошей скоростью, есть Россия, Индия и многое другое экзотическое…

> 

  Используя чужие бесплатные серверы все риски вы берёте на себя.

## URL-test

Некоторые ссылки можно использовать для тестирования скорости ваших серверов, если стандартный https://cp.cloudflare.com/generate_204 показывает, что все серверы не доступны, попробуйте поменять ссылку для теста.

```HTML
https://www.gstatic.com/generate_204
https://www.google-analytics.com/generate_204
https://www.google.com/generate_204
https://connectivitycheck.gstatic.com/generate_204
https://captive.apple.com
https://www.apple.com/library/test/success.html
https://www.msftconnecttest.com/connecttest.txt
https://cp.cloudflare.com
https://detectportal.firefox.com/success.txt
https://www.v2ex.com/generate_204
https://connect.rom.miui.com/generate_204
https://connectivitycheck.cloudflare.com/generate_204
https://wifi.vivo.com.cn/generate_204
```

Если нужно знать скорость до определенного сервиса, например Instagram, можно проверять даже так: https://instagram.com/robots.txt

## Установка 3X-UI панели

Для полноценной работы Clash аренда своего сервера не обязательна, на данный момент вы можете использовать бесплатный генератор конфигов Amnezia Cloudflare WARP, а всякие chatgpt пустить через ваш бесплатный ProtonVPN Wireguard конфиг. Но всё-таки, в аренде своего VDS/VPS сервера есть свои плюсы. Если повезёт с провайдером, то как правило, такой сервер будет работать стабильно и вы сможете создавать конфиги для ваших друзей и семьи. А стоимость нормального сервера может быть около 200р в месяц с оплатой по QR СБП. Могу рекомендовать HostVDS только если умеете каскад IPv6 - пользовался им несколько лет, но с недавнего времени сервера стали баниться по IPv4 в РКН - по каким признакам, мне не известно. У других моих хостеров тоже самое.

## Установка происходит на вашем арендованном VDS/VPS сервере

Зайти на ваш сервер через SSH, например, через Termius, Putty или командную строку Windows, и выполнить всю эту команду целиком (обычно вставка работает через клик правой кнопкой мышки, либо это может быть CTRL+Shift+V):

```Shell
bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)
```

Если для вас это сложно, проконсультируйтесь.

## Панель управления

## Так называемый Dashboard

По умолчанию висит на 9090 порту вашего роутера, при успешно запущенном работающем Clash панель доступна по этому адресу (поменять IP на ваш)
http://192.168.1.1:9090/ui 
Для доступа к этой панели можно установить крутой пароль добавив в конфиг

```YAML
secret: "Kruto!P@ro11"
```

## MetaCubeXD

Официальная панель современного Mihomo, ведётся разработка, добавляются новые функции.

```YAML
external-ui: ./xd
```

Для экономии пространства на роутере, если не нужна панель, можно удалить папку /opt/clash/xd и убрать эту строку из конфига.
В любом случае, вы сможете открывать эту же панель по адресу metacubex.github.io/metacubexd и подключаться к своему роутеру оттуда. Для этого в настройках десктопного браузера (на мобильных не нашёл как это сделать) разрешите небезопасные соединения http Insecure Content Allow.
Панель показывает обновления ядра и самой себя и позволяет обновляться прямо из настроек. Можно быстро переключать режиме Rule - Global - Direct, переключать ваши серверы, смотреть пинг, маршруты. Есть разные темы оформления.

![image](https://prod-files-secure.s3.us-west-2.amazonaws.com/06a07c1f-d5e4-4915-bbbd-d00edd657e56/22e4696f-696a-4832-8abc-9268ef66dde0/Screenshot_2024-12-14_121255.png)

![image](https://prod-files-secure.s3.us-west-2.amazonaws.com/06a07c1f-d5e4-4915-bbbd-d00edd657e56/110dea24-5ba8-43b0-945c-f3ad21525ab3/Screenshot_2024-12-14_121225.png)

## Zashboard

Мой фаворит: ‣
Ведётся активная разработка, постоянно добавляются новые функции.
Панель весит меньше 2 Мб! Можете скачать её прямо на роутер, прописав в конфиге Clash:

```YAML
external-ui: ./ui
external-ui-url: "https://github.com/Zephyruso/zashboard/releases/latest/download/dist-cdn-fonts.zip"
```

Если у вас в настройках этой панели над номером версии висит точка, значит есть обновление. Для обновления достаточно нажать Update Dashboard подождать несколько секунд и обновить страницу.

![image](https://prod-files-secure.s3.us-west-2.amazonaws.com/06a07c1f-d5e4-4915-bbbd-d00edd657e56/2bd01eea-27b8-4bff-a0d5-785d4a44bfb9/Screenshot_2025-01-02_204111.png)

![image](https://prod-files-secure.s3.us-west-2.amazonaws.com/06a07c1f-d5e4-4915-bbbd-d00edd657e56/dc4718d7-5727-4848-8c68-25b5a2d00a70/Screenshot_2024-12-14_121403.png)

![image](https://prod-files-secure.s3.us-west-2.amazonaws.com/06a07c1f-d5e4-4915-bbbd-d00edd657e56/b705f146-f1ab-46e5-8c5c-9e749a3e85e4/Screenshot_2025-01-02_204203.png)

Можно добавить https://bing.img.run/uhd.php в качестве url для custom backrounds, тогда у вас каждый день будет подгружаться случайная картинка на задний план.

## YACD

Yet Another Clash Dashboard (Очередная панель управления Clash)
Устаревшая, больше не развивающаяся, но до сих пор вполне рабочая, простая, лаконичная, красивая панель, в стандартном пакете SSClash установлена именно она, занимает 3.7Мб, лежит в папке /opt/clash/ui и в стандартном конфиге прописана так: 

```YAML
external-ui: ./ui
```

Можно подключаться через этот сайт https://yacd.metacubex.one/
Либо локально, прописав такие настройки в конфиге, если вы удалили её из папки /opt/clash/ui

```YAML
external-ui: ./yacd-meta
external-ui-url: "https://github.com/MetaCubeX/Yacd-meta/archive/refs/tags/v0.3.7.zip"
```

![image](https://prod-files-secure.s3.us-west-2.amazonaws.com/06a07c1f-d5e4-4915-bbbd-d00edd657e56/24240511-eefb-4d82-b745-844821d33aa1/Screenshot_2024-12-14_121526.png)

## RazorD

Меньше 1 мб. Есть все основные функции, похож на YACD, несколько лет не обновлялся. Настроек меньше (нельзя обновить ядро из интерфейса), но всё основное есть. 

```YAML
external-ui: ./razor
external-ui-url: "https://github.com/MetaCubeX/Razord-meta/archive/refs/heads/gh-pages.zip"
```

![image](https://prod-files-secure.s3.us-west-2.amazonaws.com/06a07c1f-d5e4-4915-bbbd-d00edd657e56/fc648086-8bf6-4073-a96f-44d99b54f8c1/Screenshot_2024-12-14_123055.png)

![image](https://prod-files-secure.s3.us-west-2.amazonaws.com/06a07c1f-d5e4-4915-bbbd-d00edd657e56/7ca7bd1e-5c83-45b0-b341-7a0d759c9fd1/Screenshot_2024-12-14_123111.png)

![image](https://prod-files-secure.s3.us-west-2.amazonaws.com/06a07c1f-d5e4-4915-bbbd-d00edd657e56/3acdc731-db6b-4107-9037-26571d50bbf8/Screenshot_2024-12-14_123122.png)

## Роутер с Clash как Socks5 

Clash умеет открывать http/socks5 порты для подключений других устройств по локальной сети или через интернет, если у вас белый IP или настроен Zerotier.
Это можно использовать для выхода в интернет удалённо через вашего домашнего провайдера со всеми настроенными обходами и правилами, например, во время путешествий или чтобы ваш работодатель видел, что вы работаете из дома.

## Zerotier

У вас должен быть белый IP, либо на домашнем роутере нужно поднять удалённый доступ любым удобным вам способом, например, NedBird, Tailscale, Zerotier. В примере ниже IP домашнего  роутера в сети Zerotier 100.99.99.1.

## Clash

В конфиге Clash домашнего роутера необходимо включить allow-lan: true и открыть SOCKS5 порт socks-port: 7891 , и добавить логин и пароль, самая верхняя часть конфига у вас может выглядеть примерно так:

```YAML
mode: rule
ipv6: false
log-level: error
allow-lan: true
tproxy-port: 7894
socks-port: 7891
authentication:
  - "user1:pass1"
unified-delay: true
tcp-concurrent: true
external-controller: 0.0.0.0:9090
external-ui: ./ui
```

## Клиент

Клиентом может выступать любое устройство, например, ваш телефон на мобильном интернете, или компьютер. Обычно, есть глобальные системные настройки прокси, указав там IP адрес вашего роутера в сети Zerotier и подключившись к ней мобильным клиентом Zerotier вы сможете выходить в интернет через Clash вашего роутера.

## Либо настроить второй роутер для путешествий

Настроить Zerotier (например, с IP 100.99.99.2) и в Super Simple Clash этого второго роутера добавить SOCKS5 в качестве сервера.

```YAML
proxies:

  - name: "Home"
    type: socks5
    server: 100.99.99.1
    port: 7891
    username: user1
    password: pass1
    skip-cert-verify: true
    udp: true
```

И оставить лишь одно правило в самом низу конфига роутера для путешествий, чтобы пустить весь траффик в этот тоннель:

```YAML
rules:
  - MATCH,Home
```

## Собственный сервер списков

Создатель Super Simple Clash также написал удобный инструмент для формирования своих списков на удалённом сервере. ‣ Это может быть удобно, если у вас несколько роутеров или устройств с настроенными Clash, а правила нужно использовать одни и те же и вы единственный админ всей этой радости.
Ставим в Docker на VDS
Можете поставить на тот же сервер, где у вас x-ui.

```Shell
# Создаём папку на сервере
mkdir -p /data/sscrulesets/{conf,lists}
chown -R 1000:1000 /data/sscrulesets

# Запускаем контейнер
docker run -d \
  --name sscrulesets \
  --restart=unless-stopped \
  -e PORT=8080 \
  -e SESSION_SECRET_KEY=your-very-secret-key \
  -v /data/sscrulesets/conf:/app/conf \
  -v /data/sscrulesets/lists:/app/lists \
  -p 8080:8080 \
  zerolabnet/sscrulesets:latest
```

Чтобы посмотреть пароль для авторизации в сервис формирования списков

```Shell
docker logs sscrulesets
```

Далее в Luci в настройках SSClash в rule-providers: добавляете свои списки:

```YAML
rule-providers:

  proxy-domain:
    behavior: classical
    type: http
    format: text
    url: 'http://your-sscrulesets-host/proxy-domain.list'
    interval: 1800
    path: ./ruleset/proxy-domain.txt

rules:
  - RULE-SET,proxy-domain,PROXY
```

![image](attachment:d2b0f0ba-bfbe-4702-8230-7833c35b3e50:scr-01.png)

У сервиса простой, удобный интерфейс, доступ к нему по http://YOUR_IP:8080 
Круто, что вы можете просто добавлять домены в список, а SSCRulesets сам подставит DOMAIN-SUFFIX, перед ними, если там ничего не стоит. Тоже самое касается и правил IP-CIDR

## Сжатие Mihomo через UPX

Если на роутере не хватает места, можно ужать ядро Mihomo с помощью UPX до ~10мб.
Так можно уместить весь пакет в ~20-30мб:

```Bash
du -h /opt/clash
9.1M    /opt/clash/bin
9.7M    /opt/clash/zash/assets
9.7M    /opt/clash/ui
4.0K    /opt/clash/proxy_providers
28.5M   /opt/clash
```

Также, при обновлении ядра Clash из меню настроек через Dashboard, автоматически создаётся резервная копия, которую можно удалить:

```Bash
rm -rf /opt/clash/bin/meta-backup
```

Если не пользуетесь Dashboard, её нужно удалить из конфига и стереть /opt/clash/ui

## Telegram

Официальный список подсетей Telegram: https://core.telegram.org/resources/cidr.txt
Последнее время без cdn-ip-ranges-all списка телеграм стал часто вываливаться в “Соединение…”, поэтому:

```YAML
rule-providers:

  cdn-ip-ranges-all:
    behavior: ipcidr
    type: http
    url: "https://raw.githubusercontent.com/123jjck/cdn-ip-ranges/refs/heads/main/all/all_plain_ipv4.txt"
    interval: 86400
    format: text
    path: ./ruleset/cdn-ip-ranges-all.txt

  telegram:
    behavior: classical
    type: http
    url: "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/refs/heads/master/rule/Clash/Telegram/Telegram.yaml"
    interval: 86400
    path: ./ruleset/telegram.yaml

  telegram-ip:
    behavior: ipcidr
    format: text
    type: http
    url: "https://core.telegram.org/resources/cidr.txt"
    interval: 86400
    path: ./ruleset/telegram-ip.txt
```

и правила в rules:

```YAML
rules:

  - RULE-SET,cdn-ip-ranges-all,PROXY
  - RULE-SET,telegram,PROXY
  - RULE-SET,telegram-ip,PROXY
```

## Viber

Если вы тоже пострадали от того, что ваш управдом бабуля завела домовой чат в этом мессенджере и вам обязательно нужно там быть, попробуйте добавить такие правила:

## Вариант 1

В rule-providers: добавьте следующее правило:

```Bash
rule-providers:

  viber:
    type: http
    behavior: ipcidr
    format: text
    url: "https://raw.githubusercontent.com/routir/unblock/refs/heads/main/services/viber-ip-de.lst"
    path: ./ruleset/viber.yaml
    interval: 86400
```

И добавьте следующие правила в rules:

```YAML
rules:

  # Основные домены
  - DOMAIN-SUFFIX,viber.com,PROXY
  - DOMAIN-SUFFIX,rakuten.com,PROXY
  # IP адреса подсетей Viber Европы (должны подойти для пользователей из России)
  - RULE-SET,viber,PROXY
```

## Вариант 2

```Bash
  - DOMAIN-SUFFIX,viber.com,PROXY
  - DOMAIN-SUFFIX,amazonaws.com,PROXY
  - DOMAIN-SUFFIX,rakuten.com,PROXY
  - DOMAIN-SUFFIX,rakuten-static.com,PROXY
  - IP-CIDR,3.64.0.0/12,PROXY
  - IP-CIDR,3.120.0.0/14,PROXY
  - IP-CIDR,3.124.0.0/14,PROXY
  - IP-CIDR,15.184.0.0/14,PROXY
  - IP-CIDR,18.156.0.0/14,PROXY
  - IP-CIDR,18.184.0.0/13,PROXY
  - IP-CIDR,18.192.0.0/13,PROXY
  - IP-CIDR,34.192.0.0/12,PROXY
  - IP-CIDR,35.156.0.0/14,PROXY
  - IP-CIDR,35.207.0.0/16,PROXY
  - IP-CIDR,52.0.0.0/15,PROXY
  - IP-CIDR,52.56.0.0/14,PROXY
  - IP-CIDR,63.176.0.0/14,PROXY
```

## Альтернативы

Super Simple Clash - это просто клиент Mihomo для OpenWrt. Вот альтернатива, которая мне понравилась.

### OpenWrt Nikki

‣ - в отличие от SSClash, .ipk и .apk пакеты Nikki сразу включают в себя ядро Mihomo, есть наглядные настройки, можно сразу вставить подписку, есть возможность загрузить готовые .yaml конфиги файлами, между ними можно переключаться, есть возможность настроить работу одновременно и tproxy / redir, и tun, что должно улучшить ситуацию со звонками в мессенджерах.

### Установка и настройка OpenWrt-Nikki

Все новые версии SSClash после 2.9.1 и до 3.6.0 лично у меня глючили с base64 подписками при перезагрузке SSClash вис на резолвинге IP из base64 подписок, uhttpd не поднимался, инета не было и зайти в luci было невозможно. Поэтому я попробовал Nikki, она пожирнее, но тут есть свои плюсы.
В отличие от SSClash, тут все зависимости и ядро Mihomo при установке сразу подтягиваются. Можно ссылкой вставлять свою подписку, можно загружать несколько конфигов .yaml файлами и переключаться между ними - полезно, если у вас разные правила и серверы для моментов глушения мобильной сети и для основного интернета. Из коробки одновременно работает режим tun для udp (туда идёт голос в мессенджерах, например) и tproxy / redir для tcp (в ssclash теперь тоже есть такая настройка).

## Установка

### Вариант 1

Добавить фид Nikki, обновить список пакетов и поставить luci-app-nikki: 

#### Один раз выполнить, чтобы добавить фид на роутер

```Bash
wget -O - https://github.com/nikkinikki-org/OpenWrt-nikki/raw/refs/heads/main/feed.sh | ash
```

если через wget не качается, можно попробовать через curl:

#### 24.10.x

```Bash
opkg update && opkg install curl
curl -s -L https://github.com/nikkinikki-org/OpenWrt-nikki/raw/refs/heads/main/feed.sh | ash
opkg install luci-app-nikki
```

#### 25.12.x

```Bash
apk update && apk add curl
curl -s -L https://github.com/nikkinikki-org/OpenWrt-nikki/raw/refs/heads/main/feed.sh | ash
apk add luci-app-nikki
```

### Вариант 2

Установить всё одной командой без добавления фидов:

```Bash
wget -O - https://github.com/nikkinikki-org/OpenWrt-nikki/raw/refs/heads/main/install.sh | ash
```

или через curl:

```JavaScript
opkg update && opkg install curl
curl -s -L https://github.com/nikkinikki-org/OpenWrt-nikki/raw/refs/heads/main/install.sh | ash
```

### Вариант 3

Если пров блочит, скачайте пакеты nikki и luci-app-nikki для своей платформы вручную с https://nikkinikki.pages.dev 
После этого обновите список пакетов на роутере, затем через веб интерфейс luci в System → Software → Upload Package сначала установите файл nikki, потом luci-app-nikki.

## За основу берите этот конфиг:

Настройка Mihomo / Clash
Во вкладке Profile загружаете .yaml файл вашего конфига Clash (это обычный текстовый файл), в App Config выбираете этот файл, проставляете галочки Enable и Fast Reload, сохраняете. Больше никаких дополнительных настроек делать не нужно.

#### Чтобы включить режим tun для мессенджеров:

Proxy Config → TCP Mode: TPROXY Mode, UDP Mode: TUN Mode

![image](attachment:79a6d932-9804-452b-a721-49b4eb953857:Screenshot_from_2026-01-18_19-48-12.png)

## Windows, Mac, Linux, Android, iOS

### FlClashX

‣
Android, Windows, Linux, Mac
Кроссплатформенный, стильный, активно развивается, не хватает только поддержки iOS. Имеет единый интерфейс для всех платформ. Локальные и удалённые профили, подписки в качестве отдельных профилей, поддерживает HWID RemnaWave панели. На Android есть возможность включить его работу для определённых программ, а остальные исключить. Конфиг от вашего роутера он тоже поймёт.

![image](https://prod-files-secure.s3.us-west-2.amazonaws.com/06a07c1f-d5e4-4915-bbbd-d00edd657e56/52cef0c4-98e5-4a0b-9c20-2157f40e3abb/Screenshot_2024-12-16_121110.png)

### Happ

‣ - iOS, Android, Windows, Linux, Mac
Современный, простой, быстро развивающийся клиент для всех платформ, поддерживает HWID для RemnaWave. Подойдёт для бабушек - однокнопочник.

### Clash Verge Rev

‣ Windows, Linux, Mac
Понравился интерфейс, но самое главное - эта штука умеет быстро конвертировать ссылки на подписки, ссылки вида vless:// и остальное в формат Clash, можно быстро создавать и настраивать через меню программы группы proxy, проверять их в работе, программа создаёт текстовые файлы конфига, части которого можно добавлять на роутер в Super Simple Clash.

![image](https://prod-files-secure.s3.us-west-2.amazonaws.com/06a07c1f-d5e4-4915-bbbd-d00edd657e56/a0383086-231c-48fd-9e2a-8940f5ec01ce/Screenshot_2024-12-16_120312.png)

### Clash Nyanpasu

‣ Windows, Linux, Mac
Тоже очень стильный интерфейс, но здесь весь конфиг нужно полностью создавать свой (можно скопировать конфиг с роутера и тестировать в “полях”, когда вы не дома и вам нужны все те же возможности маршрутизации, что и в Clash на роутере). Поддерживает удалённые профили конфигов. Можно создать конфиг в виде .yaml файла для друга, положить его в секретное место на своём сервере и делиться, а затем, удалённо этот конфиг редактировать, чтобы друг получал обновления маршрутизации, которые вы пропишите. Хотя в Clash Verge Rev такое тоже возможно.

![image](https://prod-files-secure.s3.us-west-2.amazonaws.com/06a07c1f-d5e4-4915-bbbd-d00edd657e56/a31e4985-26a1-4c28-b151-82cf6bdc09de/Screenshot_2024-12-16_120221.png)

![image](https://prod-files-secure.s3.us-west-2.amazonaws.com/06a07c1f-d5e4-4915-bbbd-d00edd657e56/8189e271-c0a0-4a24-8b9b-fa9a30ec0cc9/Screenshot_2024-12-16_120241.png)

## ZRAM

Если на ваш роутер подключается много устройств, не хватает памяти и система убивает процесс Clash через OOM killer - это можно проверить в логах, когда пропадает интернет по команде:

```Bash
dmesg | grep oom
```

Вы можете увидеть строки типа таких:

```Bash
kern.err kernel: Out of memory: Killed process (clash) oom_score_adj:0
```

На Xiaomi AX3000T иногда возникает такая проблема, она решается установкой ZRAM:

```Bash
opkg update && opkg install kmod-zram zram-swap kmod-lib-lz4 kmod-lib-zstd
```

В админке luci откройте System → System → ZRam Settings
Алгоритм сжатия zstd или lz4 и размер памяти 50% от физического объема RAM. Перезагрузите роутер.
Проверить, появился ли SWAP можно по команде:

```Bash
free -h
```

Или в luci меню Status → Overview.

## Zerotier

Если вы пользуетесь Zerotier, на некоторых провайдерах может быть сложно получить доступ к роутеру, добавьте порты и планеты Zerotier в правила Clash.

```YAML
# Zerotier
  - SRC-PORT,9993,PROXY
  - DST-PORT,9993,PROXY
  - IP-CIDR,103.195.103.66/32,PROXY
  - SRC-IP-CIDR,103.195.103.66/32,PROXY
  - IP-CIDR,84.17.53.155/32,PROXY
  - SRC-IP-CIDR,84.17.53.155/32,PROXY
  - IP-CIDR,185.152.67.145/32,PROXY
  - SRC-IP-CIDR,185.152.67.145/32,PROXY
  - IP-CIDR,79.127.159.187/32,PROXY
  - SRC-IP-CIDR,79.127.159.187/32,PROXY
  - IP-CIDR,66.90.98.98/32,PROXY
  - SRC-IP-CIDR,66.90.98.98/32,PROXY
  - IP-CIDR,104.194.8.134/32,PROXY
  - SRC-IP-CIDR,104.194.8.134/32,PROXY
```

## TOR

У автора Super Simple Clash есть проект ‣. Ставим:

```Bash
apk add wget-ssl tor tor-geoip obfs4proxy
cd /tmp
wget https://github.com/zerolabnet/luci-app-torbp/releases/download/1.0/luci-app-torbp_1.0-1_all.ipk
apk add luci-app-torbp_1.0-1_all.ipk
rm *.ipk
```

Конфиг для luci-app-torbr:

```Bash
User tor
HardwareAccel 1
Log notice syslog
SocksPort 0.0.0.0:9150
DataDirectory /var/lib/tor
ExcludeExitNodes {us}
StrictNodes 1
UseBridges 1
ClientTransportPlugin obfs4 exec /usr/bin/obfs4proxy
Bridge obfs4 185.165.171.199:2345 BE408CBE160A649588E09F472725F3550CE3D823 cert=ZTJjsQ53dI3hu5zPwD8KUAHZQV1rMnHZyU3Tl8MDoachgis/8BreDPIpQu8iGCJ4eStqGA iat-mode=0
Bridge obfs4 70.81.252.86:9292 BDD7BB8DED7D613C916605F0EACF1454D30C8FEF cert=Dio4lUUeo96lwWHRPpPsJNrP2lKx6xeT0nTuCx5Op0BkTgp7PmRcWbgledt5Mhpey2uFUQ iat-mode=0
Bridge obfs4 49.13.126.113:17521 547A3A858B92D28C584FD0DA3B1E932467B244BA cert=j5iBsig0Q0FWbyzOBRAcqoO3vZ6FSgvfsYV2Fv3sDBlkA6lrzsu5G4NNcZJWnsa8HXC9cg iat-mode=0
Bridge obfs4 95.217.11.29:22134 9859875C752128125D3179F90BA6351744B09040 cert=W+qSHr6JcFY6UyJiXR3Ec5I5bYHFwDAXNq8HRQU3C56h/aJB8PQqbr8Sq04zKvhEWGbxEw iat-mode=0
```

Мосты могут быть не актуальными, подставьте свои вместо строк Bridge obfs4
В Super Simple Clash:

```YAML
proxies:

  - name: 🧅 Onion
    type: socks5
    server: 192.168.1.1 # IP адрес вашего роутера
    port: 9150

proxy-groups:

  - name: TOR
    type: select
    proxies: [🧅 Onion]
    url: 'http://gstatic.com/generate_204'
    icon: https://fastly.jsdelivr.net/gh/Koolson/Qure@master/IconSet/Color/Apeach.png
    expected-status: 204
    interval: 300

rules:
  - DOMAIN-SUFFIX,torproject.org,TOR
```

## Проброс портов

### Исключение трафика DNAT из проксирования

Чтобы обеспечить доступ к своим сервисам и сайтам извне, необходимо исключить трафик DNAT (настроить проброс портов) из проксирования. Для этого необходимо добавить в скрипт /opt/clash/bin/clash-rules исключения для nftables (в цепочки mangle и output) для полной защиты:
1. В apply_nft_rules() после создания цепочек - для входящего трафика
1. В apply_nft_output_rules() в начале функции - для исходящего трафика
Это гарантирует, что проброс портов будет работать в обоих направлениях:
- mangle: для трафика, идущего из интернета в локальную сеть
- output: для ответного трафика из локальной сети в интернет (через маршрутизатор)

> 

  Эти правила должны быть добавлены ДО других правил исключения, чтобы иметь приоритет.
В apply_nft_output_rules() добавляем:

```Bash
    # Исключить DNAT трафик (проброс портов) для локально сгенерированных пакетов
    nft add rule inet clash output ct status dnat return
    msg "DNAT traffic excluded from proxy in output chain"
```

Должно получиться так:

```Bash
# For nftables - apply output chain rules
apply_nft_output_rules() {
    local server_ips="$1"
    local excluded_interfaces="$2"
    local fake_ip_filter_mode="$3"
    local fake_ip_range="$4"

    # Исключить DNAT трафик (проброс портов) для локально сгенерированных пакетов
    nft add rule inet clash output ct status dnat return
    msg "DNAT traffic excluded from proxy in output chain"
```

В apply_nft_rules() добавляем:

```Bash
	# Исключить DNAT трафик (проброс портов) из проксирования
	nft add rule inet clash mangle ct status dnat return
	msg "DNAT traffic (port forwarding) excluded from proxy in mangle chain"
```

Должно получиться так:

```Bash
# Apply nftables rules dynamically
apply_nft_rules() {
    local server_ips="$1"
    local fake_ip_range="$2"
    local fake_ip_filter_mode="$3"

    nft delete table inet clash 2>/dev/null

    # Create table and chains with two-stage approach and proper priority ordering:
    # Stage 1: Mangle chain (priority -150) - interface filtering, exclusions, and packet marking
    # Stage 2: Proxy chain (priority -100) - TPROXY redirection for marked packets
    # Output chain (priority mangle) - handle locally generated traffic
    nft add table inet clash
    nft add chain inet clash mangle '{ type filter hook prerouting priority -150; policy accept; }'
    nft add chain inet clash proxy '{ type filter hook prerouting priority -100; policy accept; }'
    nft add chain inet clash output '{ type route hook output priority mangle; policy accept; }'
    nft add chain inet clash CLASH_MARK

	# Исключить DNAT трафик (проброс портов) из проксирования
	nft add rule inet clash mangle ct status dnat return
	msg "DNAT traffic (port forwarding) excluded from proxy in mangle chain"
```

Перезагружаем Clash:

```Bash
service clash restart
```

## apk update

Если ваш пров уже блокирует openwrt фиды и вы не можете обновлять пакеты, чтобы трафик самого роутера тоже проксировался, нужно помимо

```JavaScript
rules:
  - DOMAIN-SUFFIX,openwrt.org,PROXY
```

в конфиг Mihomo добавить:

```JavaScript
mixed-port: 7890
```

и для теста разово выполнить (будет работать до перезагрзуки):

```JavaScript
export http_proxy=http://127.0.0.1:7890
export https_proxy=http://127.0.0.1:7890
apk update
```

Если понравилось, и хотите, чтобы работало всегда, то

```JavaScript
cat > /etc/profile.d/proxy.sh << 'EOF'
export http_proxy=http://127.0.0.1:7890
export https_proxy=http://127.0.0.1:7890
export no_proxy=127.0.0.1,localhost,192.168.1.1
EOF
```

И перезагрузите роутер для теста.

## Дополнения

Здесь будут разные полезные заметки, не вошедшие в другие разделы

## Быстрый пинг - Unified Delay

Если в конфиге выставить unified-delay: true - тест скорости будет проводиться дважды подряд, чтобы не учитывать задержку первого подключения к серверу.

> 

  Без этой настройки до моих серверов Dashboard показывал 500-1000ms, а с ней всего 10-70ms.

## Включение существующего WireGuard интерфейса в тоннель и правила Clash

> 

  В /opt/clash/bin/clash-rules смотрите правила
Убрать "wg*" из исключений в блоке define RESERVED_IFACE
Теперь весь траффик из/в Wireguard, настроенный отдельно как интерфейс на роутере, пойдёт по правилам Clash. Но вообще, можно обойтись без создания интерфейсов и просто прописать ваш Wireguard в качестве сервера прямо в конфиге Clash.

## Как заставить умный дом Polaris ходить через Россию

При включённом Clash может не работать какой-нибудь умный чайник Polaris. В зависимости от того, какие используются DNS серверы, домен mqtt.cloud.polaris-iot.com использует европейские AWS серверы или российский. Для того, чтобы отрезолвился российский IP адрес, нужно либо использовать DNS Яндекса для всего, либо жёстко прописать соответствие домена mqtt.cloud.polaris-iot.com российскому IP адресу 5.189.239.239 добавить вот такой параметр в блок dns 

```Bash
  nameserver-policy:
    'mqtt.cloud.polaris-iot.com': '5.189.239.239'
  hosts:
    'mqtt.cloud.polaris-iot.com': '5.189.239.239'
```

## Как убрать локальный сайт из тоннеля

В /opt/clash/bin/clash-rules после oifname $RESERVED_IFACE return добавляем

```Bash
ip saddr LANIP tcp sport LANPort return
```

где LANIP - IP на который настроен проброс порта, LANPort - соответственно порт.
Должно получиться примерно так:

```Bash
        # Exclude reserved IPs and interfaces
        ip daddr $RESERVED_IP return
        iifname $RESERVED_IFACE return
        oifname $RESERVED_IFACE return
        ip saddr 192.168.1.99 tcp sport 443 return
        
        # Redirect traffic to TPROXY
```

При отсутствии доступа к вашим локальным сервисам по внешнему IP попробуйте добавить в chain prerouting и в chain output: ip daddr != 192.168.1.0/24 tcp dport PORT return нужным вам портам (подсеть сменить на вашу).

## Если периодически разрывается соединение

1. Если соединение стабильное и провайдер не разрывает простоящие TCP-соединения:
  - keep-alive-idle: 600 (10 минут)
  - keep-alive-interval: 60 (1 минута)
  - Это снизит нагрузку на сеть и серверы.
1. Если соединение часто разрывается или провайдер агрессивно закрывает неактивные TCP-соединения:
  - keep-alive-idle: 120 (2 минуты)
  - keep-alive-interval: 30 (30 секунд)
  - Это поможет поддерживать соединение активным.
1. Если нужна максимальная надёжность (но с повышенной нагрузкой на сеть):
  - keep-alive-idle: 60 (1 минута)
  - keep-alive-interval: 15 (15 секунд)
  - Используется в нестабильных сетях или при частых разрывах.
Вопросы и предложения, что дополнить, пишите на 4PDA в QMS.

## Подходящие роутеры

[Сравнение бюджетных роутеров MT7981](https://fildunsky.github.io/openwrt-router-compare/)

Список проверенных роутеров, на которые я ставил SSClash и Nikki. Для роутеров с 256мб оперативной памяти, рекомендую устанавливать пакет ZRAM. На 512+ нет необходимости. Жирным выделены те, у которых 512+ RAM.

## Mediatek Filogic 820

Airpi AP3000M
ASUS RT-AX59U
Bazis AX3000WM (WD-R3000N-G2A)
Cudy TR3000 / TR30 / WR3000E / WR3000H / WR3000S / WR3000P / WBR3000UAX
CMCC RAX3000M / RAX3000Me / XR30 - только UART
gl.inet GL-MT3000
Huasifei WH3000 / WH3000 Pro (1GB RAM)
Livinet Li320
netis NX31 / NX32U / NX62 (netcore N60 Pro)
Routerich AX3000 v1
SNR CPE AX2
Wavlink WL-WNT100X3
Xiaomi AX3000T / AX3200 / AX6s / AX6000 / WR30U

## Mediatek Filogic 830

gl.inet GL-MT6000 - с определёнными костылями работает на официальных прошивках от gl.inet, но лучше ставить чистую OpenWrt.

## Mipsel

Almond 3S - процессор слабоват, но всё работает
Netis N6 - процессор слабоват, но всё работает
* Не рекомендую версии роутеров gl.inet на Qualcomm, замучаетесь с настройкой.

## gl.inet Slate 7 / Flint 3

На новых прошивках, кажется, начиная с 4.8.1 поломалась маршрутизация. Нужно откатиться до старой версии и в настройках gl.inet админки отключить Ускорение сети, тогда SSClash и любые другие способы начнут работать.

> 

  Если вы являетесь несчастным обладателем одного из таких устройств на Qualcomm, лучше скорее продайте его тому, кто в этом тоже ничего не понимает - на закрытую систему вряд ли когда-либо появится полноценная поддержка OpenWrt.

## Чиним маршрутизацию SSClash

Вроде как, работает на новых прошивках:
Создать скрипт в /etc/hotplug.d/iface/ssclash.sh

```Bash
#!/bin/sh

# Запускаем только при поднятии интерфейса
if [ "$ACTION" = "ifup" ]; then
    # Даем системе 5 секунд прийти в себя
    sleep 5
    
    # 1. Маршрутизация Fake-IP
    ip route add local 198.18.0.0/16 dev lo table 100 2>/dev/null
    ip rule add to 198.18.0.0/16 lookup 100 priority 1 2>/dev/null
    
    # 2. Правила Firewall (nftables)
    # Создаем свою изолированную цепочку (приоритет -150 встает ДО системных правил)
    nft 'add chain inet fw4 clash_prerouting { type filter hook prerouting priority -150; }' 2>/dev/null
    
    # Очищаем ТОЛЬКО нашу цепочку, не трогая остальной роутер
    nft flush chain inet fw4 clash_prerouting 2>/dev/null
    
    # Перехват транзитного трафика (LAN -> Proxy)
    nft add rule inet fw4 clash_prerouting ip daddr 198.18.0.0/16 meta l4proto { tcp, udp } counter tproxy ip to :7893
    nft add rule inet fw4 forward ip daddr 198.18.0.0/16 counter accept 2>/dev/null
    
    # Перехват локального трафика самого роутера
    nft 'add chain inet fw4 clash_output { type filter hook output priority filter; }' 2>/dev/null
    nft flush chain inet fw4 clash_output 2>/dev/null
    nft add rule inet fw4 clash_output ip daddr 198.18.0.0/16 counter meta mark set 0x1 2>/dev/null
fi
```

```Bash
chmod +x /etc/hotplug.d/iface/ssclash.sh
```

## Keenetic XKeen + Mihomo

Ставите Entware (я не помню, как ставил, пробовал один раз). И там уже:

```Bash
exec sh
cd storage
opkg update && opkg upgrade && opkg install curl tar
curl -OL https://raw.githubusercontent.com/jameszeroX/XKeen/main/install.sh
chmod +x ./install.sh
./install.sh
```

Выбираете вариант с Mihomo, затем ставите текстовый редактор, например, nano и в нём редактируете конфиг Clash:

```Bash
opkg install nano
nano /opt/etc/mihomo/config.yaml
```

Умолчания для Кинетиков немного отличаются. Если не понимаете, лучше оставить всё, как есть. Только серверы свои добавьте.
Рестарт сервиса после правок конфига:

```Bash
xkeen -restart
```

Конфиг, с которым у меня всё заработало:

```YAML
mode: rule
ipv6: false
log-level: error
allow-lan: true
redir-port: 1182
tproxy-port: 1181
mixed-port: 1080
unified-delay: true
tcp-concurrent: true
find-process-mode: off
external-ui: ui
external-controller: 0.0.0.0:9090
external-ui-url: "https://github.com/Zephyruso/zashboard/releases/latest/download/dist-cdn-fonts.zip"

hosts:
  ntc.party: 130.255.77.28

dns:
  enable: true
  listen: 0.0.0.0:7874
  ipv6: false
  default-nameserver:
    - 9.9.9.9
    - 149.112.112.112
  nameserver:
    - https://dns.quad9.net/dns-query
    - https://dns10.quad9.net/dns-query
  nameserver-policy:
    "+.lan": system
    "msftconnecttest.com": system
    "msftncsi.com": system

profile:
  store-selected: true

keep-alive-idle: 15
keep-alive-interval: 15

sniffer:
  enable: true
  parse-pure-ip: true
  sniff:
    HTTP:
    TLS:

proxies:

  - name: 🇷🇺 WARP
    type: wireguard
    private-key: 9F52L4FtCKj3dp7kKi3+AWWsWlgAa7vorczBx07q73A= # поменяйте на свой
    server: 162.159.192.1
    port: 500
    ip: 172.16.0.2
    public-key: bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo=
    allowed-ips: ['0.0.0.0/0']
    udp: true
    mtu: 1280
    remote-dns-resolve: true
    dns: [1.1.1.1]
    amnezia-wg-option:
      jc: 5
      jmin: 12
      jmax: 48
      s1: 0
      s2: 0
      h1: 1
      h2: 2
      h3: 3
      h4: 4
      i1: <b 0xc2000000011419fa4bb3599f336777de79f81ca9a8d80d91eeec000044c635cef024a885dcb66d1420a91a8c427e87d6cf8e08b563932f449412cddf77d3e2594ea1c7a183c238a89e9adb7ffa57c133e55c59bec101634db90afb83f75b19fe703179e26a31902324c73f82d9354e1ed8da39af610afcb27e6590a44341a0828e5a3d2f0e0f7b0945d7bf3402feea0ee6332e19bdf48ffc387a97227aa97b205a485d282cd66d1c384bafd63dc42f822c4df2109db5b5646c458236ddcc01ae1c493482128bc0830c9e1233f0027a0d262f92b49d9d8abd9a9e0341f6e1214761043c021d7aa8c464b9d865f5fbe234e49626e00712031703a3e23ef82975f014ee1e1dc428521dc23ce7c6c13663b19906240b3efe403cf30559d798871557e4e60e86c29ea4504ed4d9bb8b549d0e8acd6c334c39bb8fb42ede68fb2aadf00cfc8bcc12df03602bbd4fe701d64a39f7ced112951a83b1dbbe6cd696dd3f15985c1b9fef72fa8d0319708b633cc4681910843ce753fac596ed9945d8b839aeff8d3bf0449197bd0bb22ab8efd5d63eb4a95db8d3ffc796ed5bcf2f4a136a8a36c7a0c65270d511aebac733e61d414050088a1c3d868fb52bc7e57d3d9fd132d78b740a6ecdc6c24936e92c28672dbe00928d89b891865f885aeb4c4996d50c2bbbb7a99ab5de02ac89b3308e57bcecf13f2da0333d1420e18b66b4c23d625d836b538fc0c221d6bd7f566a31fa292b85be96041d8e0bfe655d5dc1afed23eb8f2b3446561bbee7644325cc98d31cea38b865bdcc507e48c6ebdc7553be7bd6ab963d5a14615c4b81da7081c127c791224853e2d19bafdc0d9f3f3a6de898d14abb0e2bc849917e0a599ed4a541268ad0e60ea4d147dc33d17fa82f22aa505ccb53803a31d10a7ca2fea0b290a52ee92c7bf4aab7cea4e3c07b1989364eed87a3c6ba65188cd349d37ce4eefde9ec43bab4b4dc79e03469c2ad6b902e28e0bbbbf696781ad4edf424ffb35ce0236d373629008f142d04b5e08a124237e03e3149f4cdde92d7fae581a1ac332e26b2c9c1a6bdec5b3a9c7a2a870f7a0c25fc6ce245e029b686e346c6d862ad8df6d9b62474fbc31dbb914711f78074d4441f4e6e9edca3c52315a5c0653856e23f681558d669f4a4e6915bcf42b56ce36cb7dd3983b0b1d6fdf0f8efddb68e7ca0ae9dd4570fe6978fbb524109f6ec957ca61f1767ef74eb803b0f16abd0087cf2d01bc1db1c01d97ac81b3196c934586963fe7cf2d310e0739621e8bd00dc23fded18576d8c8f285d7bb5f43b547af3c76235de8b6f757f817683b2151600b11721219212bf27558edd439e73fce951f61d582320e5f4d6c315c71129b719277fc144bbe8ded25ab6d29b6e189c9bd9b16538faf60cc2aab3c3bb81fc2213657f2dd0ceb9b3b871e1423d8d3e8cc008721ef03b28e0ee7bb66b8f2a2ac01ef88df1f21ed49bf1ce435df31ac34485936172567488812429c269b49ee9e3d99652b51a7a614b7c460bf0d2d64d8349ded7345bedab1ea0a766a8470b1242f38d09f7855a32db39516c2bd4bcc538c52fa3a90c8714d4b006a15d9c7a7d04919a1cab48da7cce0d5de1f9e5f8936cffe469132991c6eb84c5191d1bcf69f70c58d9a7b66846440a9f0eef25ee6ab62715b50ca7bef0bc3013d4b62e1639b5028bdf757454356e9326a4c76dabfb497d451a3a1d2dbd46ec283d255799f72dfe878ae25892e25a2542d3ca9018394d8ca35b53ccd94947a8>

  - name: 🇳🇱 Proton
    type: wireguard
    dialer-proxy: 🇷🇺 WARP
    private-key: wBWnH4yYbVt+kRje04uNHb8/CM0eitsRNXBv8qpWWV8=
    server: 138.199.53.242
    port: 51820
    ip: 10.2.0.2
    public-key: +DE6qrCbWBxBY2rkopc+jVUDnQ60VYuTkkV6LM4rcwg=
    allowed-ips: ['0.0.0.0/0']
    udp: true
    mtu: 1280
    remote-dns-resolve: true
    dns: [10.2.0.1]

proxy-groups:

  - name: PROXY
    type: fallback
    url: http://gstatic.com/generate_204
    expected-status: 204
    interval: 300
    lazy: true
    icon: https://fastly.jsdelivr.net/gh/Koolson/Qure@master/IconSet/Color/Proxy.png
    proxies: [🇳🇱 Proton]

  - name: YT
    type: fallback
    url: http://gstatic.com/generate_204
    expected-status: 204
    interval: 300
    lazy: true
    icon: https://fastly.jsdelivr.net/gh/Koolson/Qure@master/IconSet/Color/YouTube.png
    proxies: [🇷🇺 WARP]
    
rule-providers:

  facebook:
    behavior: classical
    type: http
    proxy: PROXY
    url: "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/Clash/Facebook/Facebook.yaml"
    interval: 86400
    path: ./ruleset/facebook.yaml

  gemini:
    behavior: classical
    type: http
    proxy: PROXY
    format: yaml
    url: "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/Clash/Gemini/Gemini.yaml"
    interval: 86400
    path: ./ruleset/gemini.yaml

  instagram:
    behavior: classical
    type: http
    proxy: PROXY
    url: "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/Clash/Instagram/Instagram.yaml"
    interval: 86400
    path: ./ruleset/instagram.yaml

  intel:
    behavior: classical
    type: http
    proxy: PROXY
    url: "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/Clash/Intel/Intel.yaml"
    interval: 86400
    path: ./ruleset/intel.yaml

  microsoft:
    behavior: classical
    type: http
    proxy: PROXY
    url: "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/refs/heads/master/rule/Clash/Microsoft/Microsoft.yaml"    
    interval: 86400
    path: ./ruleset/microsoft.yaml

  notion:
    behavior: classical
    type: http
    proxy: PROXY
    url: "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/refs/heads/master/rule/Clash/Notion/Notion.yaml"
    interval: 86400
    path: ./ruleset/notion.yaml

  openai:
    behavior: classical
    type: http
    proxy: PROXY
    format: yaml
    url: "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/refs/heads/master/rule/Clash/OpenAI/OpenAI.yaml"
    interval: 86400
    path: ./ruleset/openai.yaml

  ru-blocked:
    behavior: domain
    type: http
    proxy: PROXY
    format: text
    url: 'https://cdn.jsdelivr.net/gh/shvchk/unblock-net/lists/clash/ru-blocked'
    interval: 86400
    path: ./ruleset/ru-blocked.yaml

  spotify:
    behavior: classical
    type: http
    proxy: PROXY
    url: "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/refs/heads/master/rule/Clash/Spotify/Spotify.yaml"
    interval: 86400
    path: ./ruleset/spotify.yaml

  telegram:
    behavior: classical
    type: http
    proxy: PROXY
    url: "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/refs/heads/master/rule/Clash/Telegram/Telegram.yaml"    
    interval: 86400
    path: ./ruleset/telegram.yaml

  tik-tok:
    behavior: classical
    type: http
    proxy: PROXY
    url: "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/refs/heads/master/rule/Clash/TikTok/TikTok.yaml"
    interval: 86400
    path: ./ruleset/tik-tok.yaml

  twitter:
    behavior: classical
    type: http
    proxy: PROXY
    url: "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/Clash/Twitter/Twitter.yaml"
    interval: 86400
    path: ./ruleset/twitter.yaml

  whatsapp:
    behavior: classical
    type: http
    proxy: PROXY
    url: "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/Clash/Whatsapp/Whatsapp.yaml"
    interval: 86400
    path: ./ruleset/whatsapp.yaml

  wix:
    behavior: classical
    type: http
    proxy: PROXY
    url: "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/Clash/WIX/WIX.yaml"
    interval: 86400
    path: ./ruleset/wix.yaml

  youtube:
    behavior: classical
    type: http
    proxy: PROXY
    url: "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/Clash/YouTube/YouTube.yaml"
    interval: 86400
    path: ./ruleset/youtube.yaml

  proxy-domain:
    behavior: classical
    type: http
    format: text
    proxy: PROXY
    url: "http://188.130.207.216:8080/proxy-domain.list"
    interval: 86400
    path: ./ruleset/proxy-domain.txt

  proxy-ip:
    behavior: classical
    type: http
    format: text
    proxy: PROXY
    url: "http://188.130.207.216:8080/proxy-ip.list"
    interval: 86400
    path: ./ruleset/proxy-ip.txt

rules:
  - AND,((NETWORK,UDP),(DST-PORT,443)),REJECT # обязательно оставьте это правило
  - RULE-SET,proxy-domain,PROXY
  - RULE-SET,proxy-ip,PROXY
  - RULE-SET,facebook,PROXY
  - RULE-SET,gemini,PROXY
  - RULE-SET,instagram,PROXY
  - RULE-SET,intel,PROXY
  - RULE-SET,microsoft,PROXY
  - RULE-SET,notion,PROXY
  - RULE-SET,openai,PROXY
  - RULE-SET,spotify,PROXY
  - RULE-SET,telegram,YT
  - RULE-SET,tik-tok,PROXY
  - RULE-SET,twitter,PROXY
  - RULE-SET,whatsapp,PROXY
  - RULE-SET,wix,PROXY
  - RULE-SET,youtube,YT
  - RULE-SET,ru-blocked,PROXY
  - MATCH,DIRECT
```

Также мне порекомендовали альтернативный способ, как более надёжное решение. Но я пока не разбирался.

## 4pda приложение

Приложение 4pda иногда залипает и страницы не открываются, но помогает перезапуск самого приложения? Есть костыльное решение:

```Bash
cat > /etc/nftables.d/50-block-4pda-imaps.nft <<'EOF'
## 4pda app: app.4pda.to:993 (selectel) hangs behind VPN. Reject with TCP RST
## before SSClash tproxy, so the app falls back to appbk.4pda.to:443.
chain block_4pda_imaps {
        type filter hook prerouting priority -200; policy accept;
        ip daddr 31.131.253.250 tcp dport 993 counter reject with tcp reset
}
EOF
nft add chain inet fw4 block_4pda_imaps '{ type filter hook prerouting priority -200; policy accept; }'
nft add rule inet fw4 block_4pda_imaps ip daddr 31.131.253.250 tcp dport 993 counter reject with tcp reset
```

Потом ребут роутера и всё.

## Поддержка проекта

Сами мы не местные, помогите, люди добрые!
Собрано на хлеб: 1008 рублей
USDT TRC20: TYMvqGyFx2AbLyHwXHu8AqkKdnupZCSyFt
USDT TON: UQA9POkuD8Bcxu8_cCO29eDmqUCd5lCH9v6Foc1n9qtRETkx
USDT ERC20: 0x32eD0bFe0cfDA50381a260Ee4DA3C3Df57F63E6a
BTC: bc1qtlsrfldgcu7yg88hmdc4wcs6qxlpdfaf80yy9k
Удалённая установка и настройка, платные консультации.
Гайд по настройке OpenWrt.
