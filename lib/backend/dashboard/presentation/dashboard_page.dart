import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/auth/shared/providers.dart';
import 'package:flutter_template/backend/core/notifiers/user_notifier.dart';
import 'package:flutter_template/backend/core/shared/providers.dart';
import 'package:flutter_template/core/presentation/toasts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  @override
  void initState() {
    ref.read(userNotifierProvider.notifier).getUserPage();
    super.initState();
  }

  bool hasShownNoConnectionToast = false;
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userNotifierProvider);
    final auth = ref.watch(authNotifierProvider.notifier).checkAndUpdateAuthStatus();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Screen'),
        actions: [
          IconButton(
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
          crossAxisAlignment: CrossAxisAlignment.center,
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
