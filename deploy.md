 # Cache Shaders for better performance
This needs to be on a real device, one for ios and one for android
flutter run --profile --cache-sksl --purge-persistent-cache

Once done navigating the app press `M` this will save a json
Use that json in the next commands

## Build Android
flutter build ipa  --bundle-sksl-path flutter_01.sksl.json --release

## Build IOS
flutter build appbundle --bundle-sksl-path flutter_02.sksl.json --release -v

## Build web
flutter build web --dart-define=FLUTTER_WEB_USE_SKIA=true --release

### Deploy to s3
aws s3 cp ./build/web s3://www.my-bucket/ --recursive --cache-control max-age=0 --acl public-read
