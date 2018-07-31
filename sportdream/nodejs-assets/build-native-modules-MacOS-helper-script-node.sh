#!/bin/bash
      # Helper script for Gradle to call node on macOS in case it is not found
      export PATH=$PATH:/Users/lili/sport_native/sportdream/node_modules/nodejs-mobile-react-native/node_modules/.bin:/Users/lili/.config/yarn/link/node_modules/.bin:/Users/lili/sport_native/sportdream/node_modules/nodejs-mobile-react-native/node_modules/.bin:/Users/lili/.config/yarn/link/node_modules/.bin:/usr/local/lib/node_modules/npm/bin/node-gyp-bin:/usr/local/bin/node_modules/npm/bin/node-gyp-bin:/Users/lili/Library/Android/sdk/platform-tools:/usr/local/opt/sqlite/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/Users/lili/.rvm/bin
      node $@
    