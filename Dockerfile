# Telegram Bot for Coinbase Pro
# telegram_coinbasepro:20200203

# Use this Image
FROM alpine:latest

# Install this packages
RUN apk --no-cache --update add npm bash nodejs curl bc wget grep jq sed && \
rm -rf /var/cache/apk/*

RUN cd /

# Create Workdir
RUN mkdir /workdir
RUN cd /workdir

# Install official coinbase pro library
RUN npm install coinbase-pro

# Delete this package to reduce Image size
RUN apk del npm

# run bot when container booted
ENTRYPOINT ["/bin/bash", "/workdir/*.sh"]
#CMD /bin/bash /workdir/*.sh
