# Telegram Bot for Coinbase Pro
# telegram_coinbasepro:20191023

# Use this Image
FROM alpine:latest

# Install this packages
RUN apk --no-cache --update add npm bash nodejs curl bc wget grep jq sed && \
rm -rf /var/cache/apk/*

RUN cd /

# Install official coinbase pro library
RUN npm install coinbase-pro

# Delete this package to reduce Image size
RUN apk del npm

# Create dummy scripts
RUN touch /run.sh
RUN touch /trade.js

RUN chmod +x /run.sh
RUN chmod +x /trade.js

# run bot when container booted
CMD /bin/bash /run.sh