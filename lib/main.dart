import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

const bg = Color(0xFF08070D);
const panel = Color(0xFF12101B);
const panel2 = Color(0xFF191525);
const purple = Color(0xFF8B35FF);
const purpleLight = Color(0xFFB16CFF);
const white = Color(0xFFF5F1FF);
const muted = Color(0xFF938AA8);
const green = Color(0xFF55D69E);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final isDesktop = !kIsWeb &&
      (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  if (isDesktop) {
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
        colorScheme: const ColorScheme.dark(
          primary: purple,
          surface: panel,
        ),
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
    with TickerProviderStateMixin {
  static const countries = [
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

  Timer? connectionTimer;
  Timer? clock;

  late final AnimationController webAnimation;
  late final AnimationController spiderSway;

  String get flag => countries.firstWhere((item) => item.$1 == country).$2;

  String get formattedTime {
    final hours = (seconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((seconds ~/ 60) % 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$secs';
  }

  @override
  void initState() {
    super.initState();

    webAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    spiderSway = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
  }

  @override
  void dispose() {
    connectionTimer?.cancel();
    clock?.cancel();
    webAnimation.dispose();
    spiderSway.dispose();
    super.dispose();
  }

  Future<void> closeApp() async {
    final isDesktop = !kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

    if (isDesktop) {
      await windowManager.close();
    } else {
      await SystemNavigator.pop();
    }
  }

  void toggleConnection() {
    if (connected) {
      connectionTimer?.cancel();
      clock?.cancel();
      spiderSway
        ..stop()
        ..reset();
      webAnimation.reset();

      setState(() {
        connected = false;
        connecting = false;
        seconds = 0;
      });
      return;
    }

    if (connecting) return;

    setState(() {
      connecting = true;
      seconds = 0;
    });

    webAnimation.forward(from: 0);

    connectionTimer = Timer(const Duration(milliseconds: 2200), () {
      if (!mounted) return;

      setState(() {
        connecting = false;
        connected = true;
      });

      // После подключения паук плавно покачивается на готовой паутине.
      spiderSway.repeat(reverse: true);

      clock = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() => seconds++);
        }
      });
    });
  }

  void selectCountry(String selectedCountry) {
    connectionTimer?.cancel();
    clock?.cancel();

    webAnimation.reset();
    spiderSway
      ..stop()
      ..reset();

    setState(() {
      country = selectedCountry;
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
                leading: Text(
                  item.$2,
                  style: const TextStyle(fontSize: 25),
                ),
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
        child: Container(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(color: purple, width: 1.5),
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: purple.withOpacity(0.16),
                blurRadius: 18,
              ),
            ],
          ),
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
      ),
    );
  }

  Widget _header() {
    return SizedBox(
      height: 58,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            if (showProfile)
              IconButton(
                tooltip: 'Назад',
                onPressed: () => setState(() => showProfile = false),
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: purpleLight,
                  size: 20,
                ),
              )
            else
              const SizedBox(width: 42),
            const Spacer(),
            const Icon(Icons.pets, color: purple, size: 23),
            const SizedBox(width: 7),
            const Text(
              'Spieder ',
              style: TextStyle(
                color: white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'VPN',
              style: TextStyle(
                color: purpleLight,
                fontSize: 17,
                fontWeight: FontWeight.bold,
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
      ),
    );
  }

  Widget _homePage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Expanded(
            child: AnimatedBuilder(
              animation: Listenable.merge([webAnimation, spiderSway]),
              builder: (context, _) {
                final progress = connected ? 1.0 : webAnimation.value;
                final sway = connected
                    ? math.sin(spiderSway.value * math.pi * 2) * 0.08
                    : 0.0;
                final bob = connected
                    ? math.sin(spiderSway.value * math.pi * 2) * 3
                    : 0.0;

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: WebPainter(
                          progress: progress,
                          visible: connecting || connected,
                        ),
                      ),
                    ),

                    // Паук остаётся над кнопкой; после подключения слегка качается.
                    Positioned(
                      top: 24,
                      child: Transform.translate(
                        offset: Offset(0, bob),
                        child: Transform.rotate(
                          angle: sway,
                          child: const CustomPaint(
                            size: Size(64, 72),
                            painter: SpiderPainter(),
                          ),
                        ),
                      ),
                    ),

                    GestureDetector(
                      onTap: toggleConnection,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF07060D),
                          border: Border.all(
                            color: connecting || connected
                                ? purpleLight
                                : purple,
                            width: 4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: purple.withOpacity(
                                connecting || connected ? 0.55 : 0.24,
                              ),
                              blurRadius: connecting || connected ? 28 : 16,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.power_settings_new_rounded,
                          color: white,
                          size: 54,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 4),
          Text(
            connected
                ? 'Подключено'
                : connecting
                    ? 'Подключение...'
                    : 'Не подключено',
            style: TextStyle(
              color: connected ? green : muted,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 34,
            child: Text(
              connected ? formattedTime : '',
              style: const TextStyle(
                color: white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: chooseCountry,
            style: OutlinedButton.styleFrom(
              foregroundColor: white,
              side: const BorderSide(color: purple, width: 1.2),
              padding: const EdgeInsets.symmetric(
                vertical: 15,
                horizontal: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.bolt, color: purpleLight),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Лучший сервер',
                    style: TextStyle(fontSize: 15),
                  ),
                ),
                Text(flag, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(country, style: const TextStyle(fontSize: 13)),
                const Icon(Icons.chevron_right, color: purpleLight),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Демо-режим: VPN-сервер не используется',
            textAlign: TextAlign.center,
            style: TextStyle(color: muted, fontSize: 10),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _profilePage() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      children: [
        const SizedBox(height: 8),
        Container(
          width: 100,
          height: 100,
          margin: const EdgeInsets.symmetric(horizontal: 95),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: purple, width: 1.5),
            color: panel,
          ),
          child: const CustomPaint(
            painter: SpiderPainter(),
          ),
        ),
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
          style: TextStyle(color: muted, fontSize: 13),
        ),
        const SizedBox(height: 18),
        _profileTile(
          Icons.workspace_premium,
          'Демо-подписка',
          'Подписка не активна',
          accent: true,
        ),
        const SizedBox(height: 16),
        _sectionTitle('Полезные ссылки'),
        _profileTile(Icons.language, 'Официальный сайт', 'Ссылка не задана'),
        const SizedBox(height: 8),
        _profileTile(Icons.send, 'Telegram канал', 'Ссылка не задана'),
        const SizedBox(height: 14),
        _sectionTitle('Управление'),
        _profileTile(Icons.devices, 'Добавить ещё устройство', 'Демо-режим'),
        const SizedBox(height: 8),
        _profileTile(Icons.support_agent, 'Обратиться в поддержку', ''),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: muted,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _profileTile(
    IconData icon,
    String title,
    String subtitle, {
    bool accent = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: panel2,
        border: Border.all(
          color: accent ? purple : const Color(0xFF282132),
        ),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: purpleLight,
            size: 25,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: accent ? purpleLight : white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(color: muted, fontSize: 11),
                  ),
                ],
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
      height: 64,
      decoration: const BoxDecoration(
        color: Color(0xFF0E0B15),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(24),
        ),
        border: Border(
          top: BorderSide(color: Color(0xFF21182D)),
        ),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: selected ? purple : muted,
              size: 23,
            ),
            const SizedBox(height: 3),
            Text(
              title,
              style: TextStyle(
                color: selected ? purpleLight : muted,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WebPainter extends CustomPainter {
  const WebPainter({
    required this.progress,
    required this.visible,
  });

  final double progress;
  final bool visible;

  @override
  void paint(Canvas canvas, Size size) {
    if (!visible) return;

    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) * 0.48;
    final p = progress.clamp(0.0, 1.0);

    final webPaint = Paint()
      ..color = purpleLight.withOpacity(0.48)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;

    // Радиальные нити прорисовываются от кнопки наружу.
    for (var i = 0; i < 16; i++) {
      final angle = i * math.pi / 8;
      final end = center +
          Offset(math.cos(angle), math.sin(angle)) * maxRadius * p;
      canvas.drawLine(center, end, webPaint);
    }

    // Кольца появляются последовательно, образуя паутину.
    for (var i = 1; i <= 5; i++) {
      final ringProgress = (p * 5 - (i - 1)).clamp(0.0, 1.0);
      if (ringProgress <= 0) continue;

      final radius = maxRadius * (i / 5) * ringProgress;
      canvas.drawCircle(center, radius, webPaint);
    }
  }

  @override
  bool shouldRepaint(covariant WebPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.visible != visible;
  }
}

class SpiderPainter extends CustomPainter {
  const SpiderPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final bodyPaint = Paint()
      ..color = purpleLight
      ..style = PaintingStyle.fill;

    final legPaint = Paint()
      ..color = purpleLight
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Голова и туловище паука.
    canvas.drawCircle(center + const Offset(0, -9), 6, bodyPaint);
    canvas.drawOval(
      Rect.fromCenter(
        center: center + const Offset(0, 6),
        width: 13,
        height: 19,
      ),
      bodyPaint,
    );

    // Четыре лапки с каждой стороны.
    for (final side in [-1.0, 1.0]) {
      for (var i = 0; i < 4; i++) {
        final startY = center.dy - 3 + i * 5.0;
        final elbowY = startY + (i < 2 ? -7 : 7);
        final endY = startY + (i < 2 ? -12 : 12);
        final outerX = 20 + (i.isOdd ? 3 : 0);

        final path = Path()
          ..moveTo(center.dx + side * 5, startY)
          ..lineTo(center.dx + side * 13, elbowY)
          ..lineTo(center.dx + side * outerX, endY);

        canvas.drawPath(path, legPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant SpiderPainter oldDelegate) => false;
}
