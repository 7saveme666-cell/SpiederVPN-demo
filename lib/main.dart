import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

const bg = Color(0xFF08070D);
const panel = Color(0xFF12101B);
const purple = Color(0xFF8B35FF);
const purpleLight = Color(0xFFB16CFF);
const white = Color(0xFFF5F1FF);
const muted = Color(0xFF938AA8);
const green = Color(0xFF55D69E);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final desktop = !kIsWeb &&
      (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  if (desktop) {
    await windowManager.ensureInitialized();
    const options = WindowOptions(
      size: Size(390, 720),
      minimumSize: Size(350, 620),
      center: true,
      title: 'Spieder VPN Demo',
      backgroundColor: bg,
    );
    await windowManager.waitUntilReadyToShow(options, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(const SpiederApp());
}

class SpiederApp extends StatelessWidget {
  const SpiederApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spieder VPN Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bg,
        colorScheme: const ColorScheme.dark(primary: purple, surface: panel),
        fontFamily: 'Segoe UI',
      ),
      home: const VpnHome(),
    );
  }
}

class VpnHome extends StatefulWidget {
  const VpnHome({super.key});

  @override
  State<VpnHome> createState() => _VpnHomeState();
}

class _VpnHomeState extends State<VpnHome>
    with SingleTickerProviderStateMixin {
  final countries = const [
    ('Швеция', '🇸🇪', '14 серверов'),
    ('Нидерланды', '🇳🇱', '12 серверов'),
    ('Финляндия', '🇫🇮', '8 серверов'),
    ('Германия', '🇩🇪', '20 серверов'),
    ('Польша', '🇵🇱', '10 серверов'),
    ('Латвия', '🇱🇻', '6 серверов'),
    ('США', '🇺🇸', '4 сервера'),
  ];

  String country = 'Швеция';
  bool connected = false;
  bool connecting = false;
  bool showProfile = false;
  int seconds = 0;

  Timer? clock;
  Timer? connectionTimer;
  late final AnimationController animation;

  String get flag => countries.firstWhere((item) => item.$1 == country).$2;

  String get formattedTime {
    final h = (seconds ~/ 3600).toString().padLeft(2, '0');
    final m = ((seconds ~/ 60) % 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  void initState() {
    super.initState();
    animation = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    clock?.cancel();
    connectionTimer?.cancel();
    animation.dispose();
    super.dispose();
  }

  Future<void> closeApp() async {
    final desktop = !kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

    if (desktop) {
      await windowManager.close();
    } else {
      await SystemNavigator.pop();
    }
  }

  void toggleConnection() {
    if (connected) {
      clock?.cancel();
      connectionTimer?.cancel();
      setState(() {
        connected = false;
        connecting = false;
        seconds = 0;
      });
      return;
    }

    if (connecting) return;

    setState(() => connecting = true);

    connectionTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;

      setState(() {
        connecting = false;
        connected = true;
      });

      clock = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => seconds++);
      });
    });
  }

  void selectCountry(String selected) {
    clock?.cancel();
    connectionTimer?.cancel();

    setState(() {
      country = selected;
      connected = false;
      connecting = false;
      seconds = 0;
    });
  }

  Future<void> chooseCountry() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: panel,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Text(
                'Выберите сервер',
                style: TextStyle(
                  color: white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...countries.map(
              (item) => ListTile(
                leading: Text(item.$2, style: const TextStyle(fontSize: 24)),
                title: Text(item.$1),
                subtitle: Text(
                  item.$3,
                  style: const TextStyle(color: muted),
                ),
                trailing: item.$1 == country
                    ? const Icon(Icons.check, color: purpleLight)
                    : null,
                onTap: () {
                  selectCountry(item.$1);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            Expanded(
              child: showProfile ? _profilePage() : _homePage(),
            ),
            _bottomNavigation(),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
      child: Row(
        children: [
          if (showProfile)
            IconButton(
              onPressed: () => setState(() => showProfile = false),
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: purpleLight,
              ),
            )
          else
            const SizedBox(width: 12),
          const Spacer(),
          const Icon(Icons.pets, color: purple, size: 25),
          const SizedBox(width: 8),
          const Text(
            'Spieder ',
            style: TextStyle(
              color: white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const Text(
            'VPN',
            style: TextStyle(
              color: purpleLight,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Закрыть',
            onPressed: closeApp,
            icon: const Icon(Icons.close, color: white),
          ),
        ],
      ),
    );
  }

  Widget _homePage() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      children: [
        _serverCard(),
        SizedBox(
          height: 330,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: animation,
                  builder: (_, __) => CustomPaint(
                    painter: WebPainter(
                      progress: connecting ? animation.value : 0,
                      active: connected,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 24,
                child: Icon(
                  Icons.pets,
                  size: 46,
                  color: purpleLight.withOpacity(0.95),
                ),
              ),
              Transform.translate(
                offset: const Offset(0, 25),
                child: GestureDetector(
                  onTap: toggleConnection,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    width: 112,
                    height: 112,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: bg,
                      border: Border.all(
                        color: connected || connecting
                            ? purpleLight
                            : purple,
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: purple.withOpacity(
                            connecting || connected ? 0.55 : 0.22,
                          ),
                          blurRadius: connecting || connected ? 32 : 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.power_settings_new,
                      color: white,
                      size: 48,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Text(
          connected
              ? 'Подключено'
              : connecting
                  ? 'Подключение...'
                  : 'Не подключено',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: connected ? green : muted,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          connected ? formattedTime : '',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: white,
            fontSize: 25,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 22),
        OutlinedButton(
          onPressed: chooseCountry,
          style: OutlinedButton.styleFrom(
            foregroundColor: white,
            side: const BorderSide(color: purple, width: 1.3),
            padding: const EdgeInsets.symmetric(
              vertical: 17,
              horizontal: 18,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.bolt, color: purpleLight),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Лучший сервер  $flag  $country',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15),
                ),
              ),
              const Icon(Icons.chevron_right, color: purpleLight),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Демо: VPN-сервер не используется.',
          textAlign: TextAlign.center,
          style: TextStyle(color: muted, fontSize: 11),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _serverCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: panel,
        border: Border.all(color: const Color(0xFF302344)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Text(flag, style: const TextStyle(fontSize: 25)),
          const SizedBox(width: 12),
          Text(
            country,
            style: const TextStyle(
              color: white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: chooseCountry,
            child: const Text(
              'Изменить ›',
              style: TextStyle(color: purpleLight),
            ),
          ),
        ],
      ),
    );
  }

  Widget _profilePage() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      children: [
        const SizedBox(height: 12),
        const Icon(Icons.pets, color: purple, size: 58),
        const SizedBox(height: 10),
        const Text(
          'Spieder VPN',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Твой безопасный интернет',
          textAlign: TextAlign.center,
          style: TextStyle(color: muted),
        ),
        const SizedBox(height: 24),
        _profileTile(
          Icons.workspace_premium,
          'Демо-подписка',
          'Подписка не активна',
        ),
        const SizedBox(height: 12),
        _sectionTitle('Полезные ссылки'),
        _profileTile(
          Icons.language,
          'Официальный сайт',
          'Ссылку можно добавить позже',
        ),
        const SizedBox(height: 10),
        _profileTile(
          Icons.send,
          'Telegram канал',
          'Ссылку можно добавить позже',
        ),
        const SizedBox(height: 12),
        _sectionTitle('Управление'),
        _profileTile(Icons.devices, 'Устройства', 'Демо-режим'),
        const SizedBox(height: 10),
        _profileTile(
          Icons.support_agent,
          'Поддержка',
          'Ссылку можно добавить позже',
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 10),
      child: Text(
        title,
        style: const TextStyle(
          color: muted,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _profileTile(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: panel,
        border: Border.all(color: const Color(0xFF282132)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, color: purpleLight, size: 27),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: white)),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: muted, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: purpleLight),
        ],
      ),
    );
  }

  Widget _bottomNavigation() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0E0B15),
        border: Border(top: BorderSide(color: Color(0xFF21182D))),
      ),
      child: Row(
        children: [
          _navItem(
            Icons.home_rounded,
            'Главная',
            !showProfile,
            () => setState(() => showProfile = false),
          ),
          _navItem(
            Icons.person_rounded,
            'Профиль',
            showProfile,
            () => setState(() => showProfile = true),
          ),
        ],
      ),
    );
  }

  Widget _navItem(
    IconData icon,
    String title,
    bool selected,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: selected ? purple : muted, size: 24),
              const SizedBox(height: 3),
              Text(
                title,
                style: TextStyle(
                  color: selected ? purpleLight : muted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WebPainter extends CustomPainter {
  WebPainter({required this.progress, required this.active});

  final double progress;
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 20);
    final maxRadius = math.min(size.width, size.height) * 0.46;

    final webPaint = Paint()
      ..color = purple.withOpacity(active ? 0.27 : 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    for (final fraction in [0.48, 0.68, 0.88, 1.0]) {
      canvas.drawCircle(center, maxRadius * fraction, webPaint);
    }

    for (var i = 0; i < 16; i++) {
      final angle = i * math.pi / 8;
      final end =
          center + Offset(math.cos(angle), math.sin(angle)) * maxRadius;
      canvas.drawLine(center, end, webPaint);
    }

    if (progress > 0 || active) {
      final strandPaint = Paint()
        ..color = purpleLight.withOpacity(active ? 0.6 : 0.9)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

      final reach = active ? 1.0 : progress;

      for (var i = 0; i < 12; i++) {
        final angle = (i * math.pi / 6) + progress * math.pi * 2;
        final radius = maxRadius * (0.25 + 0.75 * reach);
        final end = center + Offset(math.cos(angle), math.sin(angle)) * radius;
        canvas.drawLine(center, end, strandPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant WebPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.active != active;
  }
}
