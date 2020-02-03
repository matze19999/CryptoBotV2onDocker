#!/bin/bash

# This bot was written by matze19999 and published here: https://github.com/matze19999/CryptoBotV2onDocker/

# are now System Variables, write them into your Docker Stack.
# BOTAPITOKEN='' # Telegram Bot Token
# TELEGRAMUSERNAME='' # your telegram username
# TELEGRAMUSERID='' # send a message to the bot and watch stdout
# SLEEPTIME='0.7'
# TZ: "Europe/Berlin"
# DNDFROM: "23" #Uhr
# DNDTO: "5" #Uhr

# required Packages:
# curl nodejs npm bc wget bash grep cut jq sed


# set const
CURRENTFOLDER='/workdir'

# Get Infos from CSV file
if [ -f "$CURRENTFOLDER/config.csv" ];then
    CSVDATEN=`tail -1 "$CURRENTFOLDER/config.csv"`

    SELLPROFIT=`echo "$CSVDATEN" | cut -d ';' -f 1`
    ALERT=`echo "$CSVDATEN" | cut -d ';' -f 2`
    COIN=`echo "$CSVDATEN" | cut -d ';' -f 3`
    NOTIFICATIONSTATUS=`echo "$CSVDATEN" | cut -d ';' -f 4`
    DEPOSIT=`echo "$CSVDATEN" | cut -d ';' -f 5`

    CSVLINES=`wc -l "$CURRENTFOLDER/config.csv" | cut -d ' ' -f 1`
    if (( $(echo "$CSVLINES > 100" | bc -l) ));then
		rm -f "$CURRENTFOLDER/config.csv"
        writecsv
	fi
fi

# Get Data from Coinbase Pro API
REQUESTAMOUNTCOINS=`node "$CURRENTFOLDER/trade.js" "requestamountcoins" | grep "$COIN" -A5 -B1`
REQUESTBUYPRICE=`node "$CURRENTFOLDER/trade.js" 'requestbuyprice' "$COIN"`
COINCOUNT=`echo $REQUESTAMOUNTCOINS | grep "$COIN" -A1 | tail -n 1 | cut -d "'" -f 6 | cut -c 1-10`
LASTACTION=`echo $REQUESTBUYPRICE | grep "side:" | head -n 1 | cut -d "'" -f 20`
FEEWITHDRAW=`echo $REQUESTBUYPRICE | grep "fee:" | head -n 1 | cut -d "'" -f 18 | cut -c 1-10`


# Write updated variables to CSV file.
function writecsv {

    if [ ! -f "$CURRENTFOLDER/config.csv" ];then
        WRITECSV='Gewinnhöhe bei Autoverkauf;Gewinnhöhe bei Benachrichtigung;Coin;Nachrichtenstatus;Einzahlung'
        echo "$WRITECSV" >> "$CURRENTFOLDER/config.csv"
        sendmessage "CSV Datei wurde erstellt!"
        echo 
        echo "Bitte benutze die Telegram Kommandos /setprofit und /setalert"
        echo
        echo "z.B.: /setprofit 300 /setalert 250"
    fi

    WRITECSV="$SELLPROFIT"";""$ALERT"";""$COIN"";""$NOTIFICATIONSTATUS"";""$DEPOSIT"
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
    sendmessage "<b>Deine $COIN Übersicht</b>%0A%0ADein Gewinn ist bei $PROFIT€%0A%0ADeine Einzahlung: $DEPOSIT€%0A%0AGebühren bei Verkauf max.: $FEE€%0A%0ADeine Auszahlung: $WITHDRAW€%0A%0AEurokurs ist bei $EUROPRICE€%0A%0ADollarkurs ist bei \$$USDPRICE%0A%0AAutoverkauf bei Gewinnhöhe: $SELLPROFIT€%0A%0ANachricht bei Gewinnhöhe: $ALERT€%0A%0Ahttps://pro.coinbase.com/trade/$COIN-EUR"

}

# Calculate all your financial infos
function calculate {

    curl -s -X POST "https://api.telegram.org/bot$BOTAPITOKEN/sendChatAction" -d "chat_id=$TELEGRAMUSERID" -d "action=typing" > /dev/null

    COIN=`echo "$CSVDATEN" | cut -d ';' -f 3`

    REQUESTAMOUNTCOINS=`node "$CURRENTFOLDER/trade.js" "requestamountcoins" | grep "$COIN" -A5 -B1`

    REQUESTBUYPRICE=`node "$CURRENTFOLDER/trade.js" 'requestbuyprice' "$COIN"`

    COINPRICE=`node "$CURRENTFOLDER/trade.js" "getcoinstats" "$COIN" | sort | grep "price" | cut -d "'" -f 2`

    COINCOUNT=`echo $REQUESTAMOUNTCOINS | grep "$COIN" -A1 | tail -n 1 | cut -d "'" -f 6 | cut -c 1-10`
    LASTACTION=`echo $REQUESTBUYPRICE | grep "side:" | head -n 1 | cut -d "'" -f 20`
    FEEWITHDRAW=`echo $REQUESTBUYPRICE | grep "fee:" | head -n 1 | cut -d "'" -f 18 | cut -c 1-10`

    EUROPRICE=`echo "$COINPRICE" | head -n 1`
    USDPRICE=`echo "$COINPRICE" | tail -n 1`
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
        node "$CURRENTFOLDER/trade.js" "sell" "$COIN" "$COINCOUNT" "$EUROPRICE"
        sendmessage "⚠️ $COIN wurde zu $PROFIT€ Gewinn verkauft! ⚠️"
    fi
}

# "How high is my refund if the coin has this course"
function calculatefuture {

    curl -s -X POST "https://api.telegram.org/bot$BOTAPITOKEN/sendChatAction" -d "chat_id=$TELEGRAMUSERID" -d "action=typing" > /dev/null
    #DEPOSIT=`echo "$BUYPRICE * $COINCOUNT" | bc`
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
        echo "Letzte Nachricht: $LATESTMESSAGE von $LATESTUSERNAME mit der ID $CHATID_LASTMESSAGE"

        # Bei Nachricht "/getprofit"
        if [[ "$LATESTMESSAGE" == '/getprofit' ]];then
            getprofit

        elif [[ "$LATESTMESSAGE" == "/setprofit "* ]];then
                SELLPROFIT=`echo "$LATESTMESSAGE" | cut -d ' ' -f 2`
                writecsv
                sendmessage "Gewinnhöhe wurde zu $SELLPROFIT€ geändert 🤟🏼"

        elif [[ "$LATESTMESSAGE" == "/coin "* ]];then
                COIN=`echo "$LATESTMESSAGE" | cut -d ' ' -f 2`
                writecsv
                sendmessage "gekaufter Coin wurde zu $COIN geändert!"

        elif [[ "$LATESTMESSAGE" == "/setalert "* ]];then
                ALERT=`echo "$LATESTMESSAGE" | cut -d ' ' -f 2`
                writecsv
                sendmessage "Benachrichtung bei Gewinn wurde zu $ALERT€ geändert 👌🏼"

        elif [[ "$LATESTMESSAGE" == "/setdeposit "* ]];then
                LATESTMESSAGE=`echo "$LATESTMESSAGE" | cut -d ' ' -f 2`
                echo $DEPOSIT
                DEPOSIT=`echo "$DEPOSIT + $LATESTMESSAGE" | bc`
                writecsv
                sendmessage "Einzahlung wurde zu $DEPOSIT€ geändert 👌🏼"

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
                sendmessage "Coin $COINBUY wird gekauft 👌🏼%0A%0AAnzahl: $COINAMOUNT%0A%0AKurs: $COINMONEY€%0A%0Ahttps://pro.coinbase.com/trade/$COIN-EUR"
                COINBUY=0
                COINAMOUNT=0
                COINMONEY=0

        elif [[ "$LATESTMESSAGE" == "/sell "* ]];then
                COINSELL=`echo "$LATESTMESSAGE" | cut -d ' ' -f 2`
                COINAMOUNT=`echo "$LATESTMESSAGE" | cut -d ' ' -f 3`
                COINMONEY=`echo "$LATESTMESSAGE" | cut -d ' ' -f 4`
                node "$CURRENTFOLDER/trade.js" "sell" "$COINSELL" "$COINAMOUNT" "$COINMONEY"
                sendmessage "Coin $COINSELL wird verkauft 👍🏼%0A%0AAnzahl: $COINAMOUNT%0A%0AKurs: $COINMONEY€%0A%0Ahttps://pro.coinbase.com/trade/$COIN-EUR"
                COINSELL=0
                COINAMOUNT=0
                COINMONEY=0

        elif [[ "$LATESTMESSAGE" == "/notification "* ]];then
                NOTIFICATIONSTATUS=`echo "$LATESTMESSAGE" | cut -d ' ' -f 2`
                writecsv
                sendmessage "Nachrichtenstatus wurde zu $NOTIFICATIONSTATUS geändert!"

        else
                sendmessage "Ich verstehe kein Wort... 🤷🏼‍♂️"

        fi

    # Jede halbe Stunde
    elif [[ "$MINUTE" == "00" ]] || [[ "$MINUTE" == "30" ]] && (( $(echo "$HOUR < $DNDFROM" | bc -l) )) && (( $(echo "$HOUR > $DNDTO" | bc -l) ));then
        if [[ "$SLEEPFLAG" == 0 ]];then
            if [[ "$NOTIFICATIONSTATUS" == "true" ]];then
                getprofit
                SLEEPFLAG=1
            fi
        fi

    elif [[ "$MINUTE" == "01" ]] || [[ "$MINUTE" == "31" ]];then
        SLEEPFLAG=0

    elif [[ "$COUNTER" == "50" ]];then
        calculate
        if (( $(echo "$PROFIT > $ALERT" | bc -l) ));then
            sendmessage "⚠️ GEWINN  IST BEI $PROFIT! ⚠️"
            COUNTER=0
        fi

    fi

    let COUNTER++

sleep $SLEEPTIME
done
