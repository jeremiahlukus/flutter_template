// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:flutter_template/features/counter/counter.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({Key? key}) : super(key: key);
  static const path = 'loading';

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: checkUserToken(context),
      builder: (BuildContext context, AsyncSnapshot<Widget> snapshot) {
        if (snapshot.hasData) return snapshot.data!;
        return const CircularProgressIndicator();
      },
    );
  }

  Future<Widget> checkUserToken(BuildContext context) async {
    try {
      return const CounterPage();
    } catch (e) {
      return const CounterPage();
    }
  }
}
