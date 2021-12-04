// Copyright (c) 2021, Very Good Ventures
// https://verygood.ventures
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

// Project imports:
import 'package:flutter_template/app/app.dart';
import 'package:flutter_template/bootstrap.dart';

void main() {
  bootstrap(
    () => const App(),
    sentryUrl: 'https://8a60663eda2040fea03dcb1516c256be@o240021.ingest'
        '.sentry.io/6089800',
  );
}
