#!/bin/bash

flutter run -d web-server --web-port 8090 --web-hostname 0.0.0.0 --observatory-port 42000 --flavor development --target lib/main_development.dart
/bin/bash /usr/local/bin/chown.sh

exit
