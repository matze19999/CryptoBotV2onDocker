# CryptoBotV2onDocker
##This is a Telegram Bot for checking your refund and some other values based on your coinbase pro account.

### Setup:

1. Set up the Stack and copy the files to your Docker Host.

2. Create a new telegram bot with the bot father.

3. Change the variables in the trade.js file and in your Stack.

4. Start the Bot and send it this telegram messages:

  /coin BTC (If you bought BTC)
  /buyprice 7520 (the course for what you bought your BTC in Euro)
  /count 2 (If you bought 2 Bitcoin)
  /getrefund (to check the math ;) )
  
Possible Telegram Commands:

/getprofit (No Parameters, check your Wallet)
/coin BTC (set your bought Coin)
/buyprice 7532.43 (the cource you bought the coin)
/withdraw 1200.34 (set how much you withdraw)
/count 3 (amount of the coin you bought)
/calculatefuture 9343.43 (Check how high your refund would be on the course)
/cancel BTC (cancels all open orders on coinbase pro for BTC)
/buy COIN AMOUNT COURSE (To create a buy order)
/sell COIN AMOUNT COURSE (To create a sell order)
/setprofit 300 (automatically sell your coin if your refund is 300€ or higher)
/setalert 250 (get an alert if your refund is 250€ or higher)
