// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// Project imports:
import 'package:flutter_template/auth/shared/providers.dart';
import 'package:flutter_template/backend/core/shared/providers.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  DashboardPageState createState() => DashboardPageState();
}

class DashboardPageState extends ConsumerState<DashboardPage> {
  @override
  void initState() {
    ref.read(userNotifierProvider.notifier).getUserPage();
    super.initState();
  }

  static const signOutButtonKey = ValueKey('signOutButtonKey');

  bool hasShownNoConnectionToast = false;
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userNotifierProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Screen'),
        actions: [
          IconButton(
            key: signOutButtonKey,
            onPressed: () {
              ref.read(authNotifierProvider.notifier).signOut();
            },
            icon: const FaIcon(
              FontAwesomeIcons.arrowRightFromBracket,
            ),
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            state.user.avatarUrl.isNotEmpty
                ? CircleAvatar(
                    backgroundColor: Colors.transparent,
                    backgroundImage: CachedNetworkImageProvider(
                      state.user.avatarUrlOverride('48'),
                    ),
                  )
                : const SizedBox(),
            Text(
              state.user.name,
              style: const TextStyle(fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }
}
