# Juridisch — lees dit voor je iets installeert

Deze repo documenteert een technische opstelling. De juridische status van wat je ermee doet hangt af van **welke content** je streamt en **in welke jurisdictie** je bent.

## In het kort

- **De software zelf is legaal**: Stremio, Stremio Web, en Homebrew zijn open-source projecten. Deze repo bevat alleen code en documentatie.
- **De Torrentio-addon zoekt torrents** in publieke trackers. Dat is informatie-ophalen; het is wat je er vervolgens mee doet dat (il)legaal kan zijn.
- **Content streamen waar je geen rechten voor hebt** is in Nederland sinds het ACI Adam-arrest (HvJ EU, 2014) auteursrechtinbreuk. Dat geldt ook voor streaming uit een torrent.

## Risicoprofiel bij **persoonlijk**, **lokaal** gebruik

Jij in je eigen huis, op je eigen WiFi, voor jezelf en je gezin:

- **BREIN gaat bijna nooit achter individuele kijkers aan.** Hun focus ligt op uploaders en commerciële operators.
- **Civielrechtelijke boete**: in theorie mogelijk, in praktijk zeer zeldzaam voor solo-kijkers (<0.01% per jaar).
- **ISP ziet torrent-verkeer.** Odido/KPN/Ziggo loggen dit; bij een BREIN-rapportage over een specifieke titel kunnen ze doorverwijzen. Komt zelden voor voor losse kijkers.

Dit project is bedoeld voor dit scenario, en voor het streamen van content waar je wél rechten voor hebt (eigen BluRay-rips, public-domain films, etc.).

## Risicoprofiel bij **publieke** URL

Zodra je deze setup toegankelijk maakt via het publieke internet (Cloudflare Tunnel, Tailscale Funnel, ngrok, port forwarding, publiek DNS):

- Je bent in de wet een **operator** die piraterij faciliteert. Compleet ander juridisch wezen dan een kijker.
- BREIN scant actief op publieke pirate-indexes. Een URL die door een scanner wordt gevonden → kans op brief flink hoger.
- Jurisprudentie: **GS Media (HvJ EU 2016)**, **Filmspeler (HvJ EU 2017)**, **The Pirate Bay (HvJ EU 2017)** — allemaal zeggen: linken naar inbreukmakende content, in de wetenschap dat het inbreuk is, is zelf een "mededeling aan het publiek" en dus zelf inbreuk.
- Zelfs als jij de enige bezoeker bent: de URL staat open op het internet, dat is genoeg om "openbaar maken" te triggeren.

**Daarom staat in CLAUDE.md expliciet dat Claude dit NIET op publiek internet mag plaatsen.**

## Risicoprofiel bij **commercieel** doorverkopen

"Ik maak hier een €X/maand abonnement van en verkoop toegang":

- Dit is **strafrechtelijk** gebied. Strafrecht i.p.v. civielrecht.
- Recente Nederlandse zaken (laatste 2 jaar):
  - 2024: IPTV-verkoper → **36 maanden gevangenisstraf + €280.000** schadevergoeding
  - 2023: operator "serienstream"-kloon → **24 maanden gevangenisstraf + volledige winst afgedragen**
- BREIN werkt samen met politie en FIOD. Betalingsstromen (Stripe/bank) zijn bewijs.
- Als minderjarige: jeugdstrafrecht milder, maar wel permanent in justitiële documentatie.

Dit is **niet** waar deze repo voor is. Een "zelfgemaakte Netflix voor €6/maand" is een crimineel businessmodel, en zo dom als wat omdat Netflix miljarden betaalt voor rechten en jij nul.

## Advies

1. **Houd het strikt lokaal.** Geen tunnels, geen publieke URL, geen poortforwards.
2. **Niet delen met vreemden.** Dit repo delen met een vriend die het voor zichzelf op zijn eigen Mac draait → prima. Een service runnen voor meerdere mensen → nee.
3. **Realistische content**: wil je iets wat écht legaal is? Netflix (€14/maand) + Disney+ (€13/maand) + een losse film-huur op Pathé Thuis bij een premiere dekt 95% van wat je kijkt. Of koop BluRays die je ript voor eigen gebruik.
4. **Deze opzet is leuk voor archieven**: je eigen gedigitaliseerde BluRay-collectie, home-video's, public-domain films. Dat is onomstreden legaal.

## Disclaimer

De auteurs van dit repo zijn **geen juristen**. Dit document is een leek-samenvatting voor Nederlandse context. Voor specifiek juridisch advies: raadpleeg een advocaat. Dit repo is "as-is", de auteurs zijn niet aansprakelijk voor hoe jij deze setup gebruikt.

De keuze om deze setup te installeren en wat je ermee streamt is 100% jouw verantwoordelijkheid. Door dit repo te gebruiken ga je ermee akkoord dat je het risicoprofiel hierboven kent en accepteert.
