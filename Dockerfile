FROM cirrusci/flutter:beta

USER root
RUN rm -rf /sdks/*
RUN git clone https://github.com/flutter/flutter.git /sdks/flutter/
RUN dart pub global activate derry
# Run basic check to download Dark SDK
RUN flutter doctor
