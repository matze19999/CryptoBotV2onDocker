# CryptoBotV2onDocker (deutsch / Euro)
## This is a Telegram Bot for checking your refund and some other values based on your coinbase pro account.

## Base Image
nimmis/apache:latest

## Architecture
amd32 / amd64

## Image Size
26 MB



![alt text](https://github.com/matze19999/CryptoBotV2onDocker/blob/master/images/CryptoBotV2onDocker.png)


### Funktionen des Bots:

- Monitoren eines Coins bei "Coinbase Pro"  über Kurs, Gewinn bei sofortigem Verkauf, Gewinn bei möglichem Kurs, Kauf eines bestimmten Coins, Verkauf eines bestimmten Coins

Der Bot ruft alle Informationen automatisch über die Coinbase Pro API ab, wie z.B.

Angaben über den Kauf des letzten Coins (Kurs bei Kauf, Anzahl der gekauften Coins, welcher Coin)

Aktueller Kurs des zuletzt gekauften Coins in Euro und USD

Gebühren bei Kauf des Coins

Mit diesen Angaben werden dann weitere Werte wie Gewinn, Gebühren beim Verkauf usw. ermittelt.

Der Bot sendet alle 30 Minuten Infos über die Kurswerte und den Gewinn per Telegram Nachricht

#### Folgende Angaben sind beim einrichten des Bots nötig:

Coinbase Pro API Schlüssel
Telegram Benutzername & ID
Zeitzone

#### Weitere optionalen Angaben:

- Sleeptime (Standard: 0,7 Sek)
- DND (Standard von 22 bis 06 Uhr)

Diese Angaben werden im Docker Stack in Environment Variablen hinterlegt.

Das Docker Image ist 26MB groß und basiert auf Alpine Linux 

Der Bot kann automatisch bei einer bestimmten Gewinnhöhe den aktuellen Coin verkaufen.

Folgende Telegram Befehle beherscht der Bot:

/getprofit (Keine Parameter, checkt Infos über den Coin)

/calculatefuture 9343.43 (Berechnet Gewinn bei angegebenem Kurs)

/cancel BTC (löscht alle offenen Order für bestimmten Coin)

/buy COIN AMOUNT COURSE (Erstellt eine Kauf Order)

/sell COIN AMOUNT COURSE (Erstellt eine Verkauf Order)

/setprofit 300 (Verkauft automatisch alles von dem Coin bei diesem Gewinnn)

/setalert 250 (Bekomme eine Telegram Nachricht wenn der Gewinn diese Zahl überschreitet)


### Limitierungen:

In der aktuellen Version kann der Bot nur mit einem Coin gleichzeitig umgehen. Sobald man also mehrere Coins bei Conbase Pro hält, müsste man den Bot mehrmals installieren und leicht abändern.

Nur kompatibel zur Coinbase Pro API

Es wird ein Telegram Nutzername benötigt
