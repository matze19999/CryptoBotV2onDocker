# CryptoBotV2onDocker (deutsch / Euro)
## This is a Telegram Bot for checking your refund and some other values based on your coinbase pro account.

## Base Image
nimmis/apache:latest

## Architecture
amd32 / amd64

## Image Size
26 MB



![alt text](https://github.com/matze19999/CryptoBotV2onDocker/blob/master/images/CryptoBotV2onDocker.png)



### Setup:

1. Set up the Stack and copy the files to your Docker Host.

2. Create a new telegram bot with the bot father.

3. Change the variables in the trade.js file and in your Stack.

4. Start the Bot:

### Possible Telegram Commands:

/getprofit (No Parameters, checks your Wallet)

/calculatefuture 9343.43 (Check how high your refund would be on the course)

/cancel BTC (cancels all open orders on coinbase pro for BTC)

/buy COIN AMOUNT COURSE (To create a buy order)

/sell COIN AMOUNT COURSE (To create a sell order)

/setprofit 300 (automatically sell your coin if your refund is 300€ or higher)

/setalert 250 (get an alert if your refund is 250€ or higher)
