import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

const bg = Color(0xFF08070D);
const panel = Color(0xFF100D17);
const purple = Color(0xFF9B35FF);
const purpleLight = Color(0xFFBC72FF);
const white = Color(0xFFF5F1FF);
const muted = Color(0xFF968CA8);
const green = Color(0xFF55D69E);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final desktop = !kIsWeb &&
      (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  if (desktop) {
    await windowManager.ensureInitialized();
    const options = WindowOptions(
      size: Size(440, 820),
      minimumSize: Size(400, 740),
      center: true,
      title: 'Spieder VPN',
      backgroundColor: bg,
      titleBarStyle: TitleBarStyle.hidden,
      windowButtonVisibility: false,
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
      title: 'Spieder VPN',
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

  Timer? connectTimer;
  Timer? clock;
  late final AnimationController webAnimation;
  late final AnimationController spiderSway;

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
    connectTimer?.cancel();
    clock?.cancel();
    webAnimation.dispose();
    spiderSway.dispose();
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
      connectTimer?.cancel();
      clock?.cancel();
      webAnimation.reset();
      spiderSway
        ..stop()
        ..reset();

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

    connectTimer = Timer(const Duration(milliseconds: 2200), () {
      if (!mounted) return;

      setState(() {
        connecting = false;
        connected = true;
      });

      spiderSway.repeat(reverse: true);

      clock = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => seconds++);
      });
    });
  }

  void selectCountry(String selected) {
    connectTimer?.cancel();
    clock?.cancel();
    webAnimation.reset();
    spiderSway
      ..stop()
      ..reset();

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
                leading: Text(item.$2, style: const TextStyle(fontSize: 25)),
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
                  size: 19,
                ),
              )
            else
              IconButton(
                tooltip: 'Закрыть приложение',
                onPressed: closeApp,
                icon: const Icon(Icons.close, color: purpleLight, size: 23),
              ),
            const Spacer(),
            const SpiderLogo(size: 24),
            const SizedBox(width: 8),
            Text(
              showProfile ? 'Профиль' : 'Spieder VPN',
              style: const TextStyle(
                color: white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            if (showProfile)
              IconButton(
                tooltip: 'Закрыть приложение',
                onPressed: closeApp,
                icon: const Icon(Icons.close, color: purpleLight, size: 23),
              )
            else
              const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }

  Widget _homePage() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
      child: Column(
        children: [
          const Spacer(flex: 2),
          Expanded(
            flex: 7,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return AnimatedBuilder(
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
                        if (connecting || connected)
                          Positioned(
                            top: constraints.maxHeight * 0.17,
                            child: Transform.translate(
                              offset: Offset(0, bob),
                              child: Transform.rotate(
                                angle: sway,
                                child: const CustomPaint(
                                  size: Size(66, 72),
                                  painter: SpiderPainter(),
                                ),
                              ),
                            ),
                          ),
                        GestureDetector(
                          onTap: toggleConnection,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF0A0810),
                              border: Border.all(
                                color: connected || connecting
                                    ? purpleLight
                                    : purple,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: purple.withOpacity(
                                    connected || connecting ? 0.35 : 0.16,
                                  ),
                                  blurRadius: connected || connecting ? 28 : 18,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.power_settings_new_rounded,
                              color: white,
                              size: 50,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Text(
            connected
                ? 'Подключено'
                : connecting
                    ? 'Подключение...'
                    : 'Не подключено',
            style: const TextStyle(
              color: white,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            connected
                ? formattedTime
                : connecting
                    ? 'Создаём защищённое соединение...'
                    : 'Нажмите кнопку для подключения',
            style: const TextStyle(color: muted, fontSize: 12),
          ),
          const Spacer(flex: 2),
          OutlinedButton(
            onPressed: chooseCountry,
            style: OutlinedButton.styleFrom(
              foregroundColor: white,
              side: const BorderSide(color: purple, width: 1),
              minimumSize: const Size.fromHeight(62),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.bolt, color: purpleLight, size: 22),
                SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Лучший сервер',
                    style: TextStyle(
                      color: white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, color: purpleLight, size: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _profilePage() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
      children: [
        const SizedBox(height: 8),
        Container(
          width: 112,
          height: 112,
          margin: const EdgeInsets.symmetric(horizontal: 125),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: purple, width: 1.5),
            color: panel,
          ),
          child: const SpiderLogo(size: 62),
        ),
        const SizedBox(height: 14),
        const Text(
          'Spieder VPN',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Твой безопасный интернет',
          textAlign: TextAlign.center,
          style: TextStyle(color: muted, fontSize: 13),
        ),
        const SizedBox(height: 22),
        _profileTile(
          Icons.workspace_premium,
          'Демо-подписка',
          'Подписка не активна',
          accent: true,
        ),
        const SizedBox(height: 18),
        _sectionTitle('Полезные ссылки'),
        _profileTile(Icons.language, 'Официальный сайт', 'Ссылка не задана'),
        const SizedBox(height: 9),
        _profileTile(Icons.send, 'Telegram канал', 'Ссылка не задана'),
        const SizedBox(height: 18),
        _sectionTitle('Управление'),
        _profileTile(Icons.devices, 'Добавить ещё устройство', 'До 10 устройств'),
        const SizedBox(height: 9),
        _profileTile(Icons.support_agent, 'Обратиться в поддержку', ''),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 9),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: panel,
        border: Border.all(
          color: accent ? purple : const Color(0xFF211A2B),
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, color: purpleLight, size: 25),
          const SizedBox(width: 14),
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
                  const SizedBox(height: 4),
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
      height: 66,
      decoration: const BoxDecoration(
        color: Color(0xFF0C0A11),
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
    final radius = math.min(size.width, size.height) * 0.48;
    final p = progress.clamp(0.0, 1.0);

    final webPaint = Paint()
      ..color = purpleLight.withOpacity(0.34)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    // Радиальные нити растут от кнопки наружу.
    for (var i = 0; i < 16; i++) {
      final angle = i * math.pi / 8;
      final end = center +
          Offset(math.cos(angle), math.sin(angle)) * radius * p;
      canvas.drawLine(center, end, webPaint);
    }

    // Круговые нити появляются по очереди.
    for (var i = 1; i <= 6; i++) {
      final ringProgress = (p * 6 - (i - 1)).clamp(0.0, 1.0);
      if (ringProgress <= 0) continue;

      final ringRadius = radius * (i / 6) * ringProgress;
      canvas.drawCircle(center, ringRadius, webPaint);
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

    final legsPaint = Paint()
      ..color = purpleLight
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Голова и туловище.
    canvas.drawCircle(center + const Offset(0, -10), 6, bodyPaint);
    canvas.drawOval(
      Rect.fromCenter(
        center: center + const Offset(0, 5),
        width: 13,
        height: 19,
      ),
      bodyPaint,
    );

    // Четыре лапы с каждой стороны.
    for (final side in [-1.0, 1.0]) {
      for (var i = 0; i < 4; i++) {
        final startY = center.dy - 3 + i * 5.0;
        final elbowY = startY + (i < 2 ? -7 : 7);
        final endY = startY + (i < 2 ? -13 : 13);
        final endX = 21 + (i.isOdd ? 3 : 0);

        final leg = Path()
          ..moveTo(center.dx + side * 5, startY)
          ..lineTo(center.dx + side * 13, elbowY)
          ..lineTo(center.dx + side * endX, endY);

        canvas.drawPath(leg, legsPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant SpiderPainter oldDelegate) => false;
}

class SpiderLogo extends StatelessWidget {
  const SpiderLogo({super.key, this.size = 24});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: SpiderPainter(),
      ),
    );
  }
}
