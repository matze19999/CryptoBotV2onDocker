#!/bin/bash

# This bot was written by matze19999 and published here: https://github.com/matze19999/CryptoBotV2onDocker/

# System Variables, write them into your Docker Stack.
# BOTAPITOKEN='vasdfas435v4v5a4w5vse4vd4v5 d45v' # Telegram Bot Token
# TELEGRAMUSERNAME='YOURUSERNAME'
# TELEGRAMUSERID='3465456'
# SLEEPTIME='0.7'

COUNTER=0
CURRENTFOLDER=`pwd`


# Get Infos from CSV file and the Coinbase Pro API
if [ -f "$CURRENTFOLDER/config.csv" ];then
    CSVDATEN=`tail -1 "$CURRENTFOLDER/config.csv"`

    REQUESTAMOUNTCOINS=`node "trade.js" "requestamountcoins"`

    COIN=`echo $REQUESTAMOUNTCOINS | grep "currency" | head -n 1 | cut -d "'" -f 2`

    REQUESTBUYPRICE=`node "trade.js" 'requestbuyprice' "$COIN"`
    
    BUYPRICE=`echo $REQUESTBUYPRICE | grep 'price:' | head -n 1 | cut -d "'" -f 2 | cut -c 1-10`
    COINCOUNT=`echo $REQUESTAMOUNTCOINS | grep "$COIN" -A1 | tail -n 1 | cut -d "'" -f 2 | cut -c 1-10`
    LASTACTION=`echo $REQUESTBUYPRICE | grep "side:" | head -n 1 | cut -d "'" -f 2`
    FEEWITHDRAW=`echo $REQUESTBUYPRICE | grep "fee:" | head -n 1 | cut -d "'" -f 2 | cut -c 1-10`

    SELLPROFIT=`echo "$CSVDATEN" | cut -d ';' -f 1`
    ALERT=`echo "$CSVDATEN" | cut -d ';' -f 2`

else
    echo "Bitte benutze die Telegram Kommandos /coin /buyprice und /count zum starten des Bots"
    echo
    echo "z.B.: /coin BTC /buyprice 7530.43 /count 3"
    echo
    echo "Dies bedeutet, du hast 3 Bitcoins zu je 7530,43€ gekauft."
fi

# which curl nodejs npm bc wget bash grep cut jq sed > /dev/null
# if [[ "$?" == '1' ]];then
#     if (($EUID != "0")); then
#         echo "Bitte starte das Script einmal als root, damit alle nötigen Pakete installiert werden können."
#     else
#         apt update
#         apt install --no-install-recommends --no-install-depencies curl nodejs npm bc wget bash grep cut jq sed -y
#     fi
# fi


# Write updated variables to CSV file.
function writecsv {

    calculate
    if [ ! -f "$CURRENTFOLDER/config.csv" ];then
        WRITECSV='Gewinnhöhe bei Autoverkauf;Gewinnhöhe bei Benachrichtigung'
        echo "$WRITECSV" >> "$CURRENTFOLDER/config.csv"
        sendmessage "CSV Datei wurde erstellt!"
    fi

    WRITECSV="$SELLPROFIT"";""$ALERT"
    echo "$WRITECSV" >> "$CURRENTFOLDER/config.csv"

}

# Get the latest telegram message sent to the bot
function getlatestmessage {

    API=`wget --no-cache --no-cookies "https://api.telegram.org/bot$BOTAPITOKEN/getUpdates" --no-check-certificate -q -O -`
    LATESTMESSAGE=`echo "$API" | jq -r ".result[-1].message.text"`
    LATESTUSERNAME=`echo "$API" | jq -r ".result[-1].message.chat.username"`
    CHATID_LASTMESSAGE=`echo "$API" | jq -r ".result[-1].message.chat.id"`

}

# send a telegram message to you
function sendmessage {

    curl -s -X POST "https://api.telegram.org/bot$BOTAPITOKEN/sendMessage" -d "parse_mode=HTML" -d "chat_id=$TELEGRAMUSERID" -d text="$1" > /dev/null

}

# Function for received message "/getprofit"
function getprofit {

    calculate
    sendmessage "<b>Deine $COIN Übersicht</b>%0A%0ADein Gewinn ist bei $PROFIT€%0A%0ADeine Einzahlung: $DEPOSIT€%0A%0AGebühren bei Verkauf max.: $FEE€%0A%0ADeine Auszahlung: $WITHDRAW€%0A%0AEurokurs ist bei $EUROPRICE€%0A%0ADollarkurs ist bei \$$USDPRICE%0A%0AAutoverkauf bei Gewinnhöhe: $SELLPROFIT€%0A%0Ahttps://pro.coinbase.com/trade/$COIN-EUR"

}

# Calculate all your financial infos
function calculate {

    curl -s -X POST "https://api.telegram.org/$BOTAPITOKEN/sendChatAction" -d "chat_id=$TELEGRAMUSERID" -d "action=typing" > /dev/null
    DEPOSIT=`echo "$BUYPRICE * $COINCOUNT - $FEEWITHDRAW" | bc | cut -c 1-8`
    EUROPRICE=`curl "https://api.coinbase.com/v2/prices/$COIN-EUR/spot" -s | cut -d '"' -f 14 | cut -c 1-8`
    USDPRICE=`curl "https://api.coinbase.com/v2/prices/$COIN-USD/spot" -s | cut -d '"' -f 14`
    PROFIT=`echo "scale=5; $EUROPRICE * $COINCOUNT - $DEPOSIT" | bc | cut -c 1-6`
    WITHDRAW=`echo "$DEPOSIT + $PROFIT" | bc`
    FEE=`bc -l <<< "($WITHDRAW / 100) * 0.50" | cut -c 1-6`
    FEE=`echo '0'"$FEE"`
    WITHDRAW=`echo "$WITHDRAW - $FEE" | bc`
    PROFIT=`echo "scale=5; $PROFIT - $FEE" | bc`
    maybesell

}

# Check if its a good time to sell your coin
function maybesell {

    if (( $(echo "$PROFIT > $SELLPROFIT" | bc -l) ));then
        node "$CURRENTFOLDER/trade.js" "sell" "$COIN" "$COINAMOUNT" "$EUROPRICE"
        sendmessage "⚠ $COIN wurde zu $PROFIT€ Gewinn verkauft! ⚠"
    fi
}

# "How high is my refund if the coin has this course"
function calculatefuture {

    curl -s -X POST "https://api.telegram.org/$BOTAPITOKEN/sendChatAction" -d "chat_id=$TELEGRAMUSERID" -d "action=typing" > /dev/null
    DEPOSIT=`echo "$BUYPRICE * $COINCOUNT" | bc`
    EUROPRICE="$1"
    PROFIT=`echo "scale=5; $1*$COINCOUNT - $DEPOSIT" | bc | cut -c 1-6`
    WITHDRAW=`echo "$DEPOSIT + $PROFIT" | bc`
    FEE=`bc -l <<< "($WITHDRAW / 100) * 0.50" | cut -c 1-6`
    FEE=`echo '0'"$FEE"`
    WITHDRAW=`echo "$WITHDRAW - $FEE" | bc`
    PROFIT=`echo "scale=5; $PROFIT - $FEE" | bc`

}
echo "Warte auf Nachrichten..."
getlatestmessage

# Check for some things like if a new message was sent, the clock, your profit and so on.
while true;
do
    MINUTE=`date +%M`
    HOUR=`date +%H`
    OLDMESSAGEDATE=`echo "$API" | jq -r ".result[-1].message.date"`
    getlatestmessage
    MESSAGEDATE=`echo "$API" | jq -r ".result[-1].message.date"`

    if [[ "$OLDMESSAGEDATE" != "$MESSAGEDATE" ]] && [[ "$LATESTUSERNAME" == "$TELEGRAMUSERNAME" ]];then
        echo "Letzte Nachricht: $LATESTMESSAGE von $LATESTUSERNAME"

        # Bei Nachricht "/getprofit"
        if [[ "$LATESTMESSAGE" == '/getprofit' ]];then
            getprofit

        elif [[ "$LATESTMESSAGE" == "/setprofit "* ]];then
                SELLPROFIT=`echo "$LATESTMESSAGE" | cut -d ' ' -f 2`
                writecsv
                sendmessage "Gewinnhöhe wurde zu $SELLPROFIT€ geändert!"
                writecsv

        elif [[ "$LATESTMESSAGE" == "/setalert "* ]];then
                ALERT=`echo "$LATESTMESSAGE" | cut -d ' ' -f 2`
                writecsv
                sendmessage "Benachrichtung bei Gewinn wurde zu $ALERT€ geändert!"

        elif [[ "$LATESTMESSAGE" == "/calculatefuture "* ]];then
                NEWPRICE=`echo "$LATESTMESSAGE" | cut -d ' ' -f 2`
                calculatefuture "$NEWPRICE"
                sendmessage "<b>⚠️ Deine mögliche $COIN Übersicht ⚠️</b>%0A%0ADeine Einzahlung: $DEPOSIT€%0A%0ADein Gewinn wäre bei $PROFIT€%0A%0AGebühren bei Verkauf wären max.: $FEE€%0A%0ADeine Auszahlung wäre: $WITHDRAW€%0A%0AEurokurs wäre bei $EUROPRICE€%0A%0Ahttps://pro.coinbase.com/trade/$COIN-EUR"

        elif [[ "$LATESTMESSAGE" == "/cancel "* ]];then
                COINDEL=`echo "$LATESTMESSAGE" | cut -d ' ' -f 2`
                node "$CURRENTFOLDER/trade.js" "cancel" "$COINDEL"
                sendmessage "Vorhandene Order vom Coin $COINDEL wurden gelöscht!%0A%0Ahttps://pro.coinbase.com/trade/$COIN-EUR"
                COINDEL=0

        elif [[ "$LATESTMESSAGE" == "/buy "* ]];then
                COINBUY=`echo "$LATESTMESSAGE" | cut -d ' ' -f 2`
                COINAMOUNT=`echo "$LATESTMESSAGE" | cut -d ' ' -f 3`
                COINMONEY=`echo "$LATESTMESSAGE" | cut -d ' ' -f 4`
                node "$CURRENTFOLDER/trade.js" "buy" "$COINBUY" "$COINAMOUNT" "$COINMONEY"
                sendmessage "Coin $COINBUY wird gekauft.%0A%0AAnzahl: $COINAMOUNT%0A%0AKurs: $COINMONEY€%0A%0Ahttps://pro.coinbase.com/trade/$COIN-EUR"
                COIBUY=0
                COINAMOUNT=0
                COINMONEY=0

        elif [[ "$LATESTMESSAGE" == "/sell "* ]];then
                COINSELL=`echo "$LATESTMESSAGE" | cut -d ' ' -f 2`
                COINAMOUNT=`echo "$LATESTMESSAGE" | cut -d ' ' -f 3`
                COINMONEY=`echo "$LATESTMESSAGE" | cut -d ' ' -f 4`
                node "$CURRENTFOLDER/trade.js" "sell" "$COINSELL" "$COINAMOUNT" "$COINMONEY"
                sendmessage "Coin $COINSELL wird verkauft.%0A%0AAnzahl: $COINAMOUNT%0A%0AKurs: $COINMONEY€%0A%0Ahttps://pro.coinbase.com/trade/$COIN-EUR"
                COINSELL=0
                COINAMOUNT=0
                COINMONEY=0

        fi

    # Jede halbe Stunde
    elif [[ "$MINUTE" == "00" ]] || [[ "$MINUTE" == "30" ]] && [[ "$HOUR" -le "22" ]] && [[ "$HOUR" -ge "6" ]];then
        getprofit
        sleep 60

    elif [[ "$COUNTER" == "50" ]];then
        calculate
        if (( $(echo "$PROFIT > $ALERT" | bc -l) ));then
            echo "test"
            sendmessage "⚠ GEWINN  IST BEI $PROFIT! ⚠️"
            COUNTER=0
        fi

    fi

    let COUNTER++

sleep $SLEEPTIME
done
