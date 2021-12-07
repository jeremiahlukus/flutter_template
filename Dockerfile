FROM cirrusci/flutter:beta

USER root

# android sdk
RUN yes "y" | sdkmanager "build-tools;30.0.2" \
  && yes "y" | sdkmanager "platforms;android-30" \
  && yes "y" | sdkmanager "platform-tools" \
  && yes "y" | sdkmanager "emulator" \
  && yes "y" | sdkmanager "system-images;android-30;google_apis_playstore;x86_64"

RUN rm -rf /sdks/*
RUN git clone https://github.com/flutter/flutter.git /sdks/flutter/
RUN dart pub global activate derry
# Run basic check to download Dark SDK
RUN flutter doctor
RUN flutter emulators --create \
  && flutter update-packages \
  && flutter emulators --launch flutter_emulator \
  && rm -f ~/.gitconfig
