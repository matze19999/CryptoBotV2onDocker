#!/usr/local/bin/node

// This script was written by matze19999 and published here: https://github.com/matze19999/CryptoBotV2onDocker/

const CoinbasePro = require('coinbase-pro');
const publicClient = new CoinbasePro.PublicClient();

const accountID = ''; // this one you'll get with the "get Accounts Infos" Command  at the bottom of the script.

// your Coinbase Pro API Key
const key = '';
const secret = '';
const passphrase = '';

// Your API Key from https://public.sandbox.pro.coinbase.com/
const SANDBOXkey = '';
const SANDBOXsecret = '';
const SANDBOXpassphrase = '';

const apiURI = 'https://api.pro.coinbase.com';
const sandboxURI = 'https://api-public.sandbox.pro.coinbase.com';

const authedClient = new CoinbasePro.AuthenticatedClient(
  key,
  secret,
  passphrase,
  apiURI
);

const SBauthedClient = new CoinbasePro.AuthenticatedClient(
  SANDBOXkey,
  SANDBOXsecret,
  SANDBOXpassphrase,
  sandboxURI
);

const callback = (error, response, data) => {
    if (error)
       return console.dir(error);
   
    return console.dir(data);
  }

// get the Parameters given to the Script
var myArgs = process.argv.slice(2);

var action = myArgs[0];
var coin = myArgs[1];
var amount = myArgs[2];
var price = myArgs[3];

coin = (coin += "-EUR")


// case switch for the parameters given
switch (myArgs[0]) {
  case 'sell':
      var params = {
        side: 'sell',
        price: price,
        size: amount,
        product_id: coin
      };
      authedClient.placeOrder(params, callback)
      break;

  case 'buy':
      var params = {
        side: 'buy',
        price: price,
        size: amount,
        product_id: coin
      };
      authedClient.placeOrder(params, callback)
      break;

  case 'cancel':
      var x=5;
      while (x != 0){
      authedClient.cancelAllOrders({ product_id: coin }, callback);
      x--
      };
      break;

  case 'requestamountcoins':
    authedClient.getAccounts(callback);
    break;

  case 'requestbuyprice':
    var params = {
    product_id: coin,
    };
    authedClient.getFills(params, callback);
    break;

  default:
      console.log('Sorry, bitte sende mir ein paar Parameter mit');
      process.exit(1);
  }

// In the case switch, replace authedClient with SBauthedClient to use the Coinbase Pro Sandbox.


// get Account Infos
// authedClient.getAccounts(callback);