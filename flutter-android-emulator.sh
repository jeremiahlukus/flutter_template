#!/bin/bash

flutter emulators --launch flutter_emulator

started=0
while [ $started -eq 0 ]
do
  sleep 1
  started=$(flutter devices | grep emulator | wc -l)
done

flutter run --observatory-port 42000 --flavor development --target lib/main_development.dart

/bin/bash /usr/local/bin/chown.sh

exit
