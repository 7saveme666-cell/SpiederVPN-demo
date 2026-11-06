import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

const bg = Color(0xFF08060D);
const panel = Color(0xFF100D17);
const panel2 = Color(0xFF17111F);
const violet = Color(0xFF7226C9);
const violetGlow = Color(0xFF9B4DE0);
const white = Color(0xFFF4EFFA);
const muted = Color(0xFF91879D);
const green = Color(0xFF55D69E);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final isDesktop = !kIsWeb &&
      (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  if (isDesktop) {
    await windowManager.ensureInitialized();

    const options = WindowOptions(
      size: Size(440, 820),
      minimumSize: Size(390, 700),
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
          primary: violet,
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
      duration: const Duration(milliseconds: 2600),
    );

    spiderSway = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
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

    connectTimer = Timer(const Duration(milliseconds: 2600), () {
      if (!mounted) return;

      setState(() {
        connecting = false;
        connected = true;
      });

      // После подключения паук качается на нити.
      spiderSway.repeat(reverse: true);

      clock = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() => seconds++);
        }
      });
    });
  }

  void selectCountry(String selectedCountry) {
    connectTimer?.cancel();
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
                    ? const Icon(Icons.check, color: violetGlow)
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
            border: Border.all(
              color: violet.withOpacity(0.75),
              width: 1.4,
            ),
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: violet.withOpacity(0.12),
                blurRadius: 20,
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
                  color: violetGlow,
                  size: 19,
                ),
              )
            else
              IconButton(
                tooltip: 'Закрыть приложение',
                onPressed: closeApp,
                icon: const Icon(
                  Icons.close,
                  color: violetGlow,
                  size: 23,
                ),
              ),
            const Spacer(),
            const SpiderLogo(size: 26),
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
                icon: const Icon(
                  Icons.close,
                  color: violetGlow,
                  size: 23,
                ),
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
          _serverSummary(),
          const SizedBox(height: 8),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final orbitRadius = math.min(
                  constraints.maxWidth * 0.34,
                  constraints.maxHeight * 0.30,
                );

                return AnimatedBuilder(
                  animation: Listenable.merge([
                    webAnimation,
                    spiderSway,
                  ]),
                  builder: (context, _) {
                    final progress = connected ? 1.0 : webAnimation.value;

                    // Во время подключения паук облетает кнопку.
                    final orbitAngle =
                        -math.pi / 2 + progress * math.pi * 2;
                    final orbitOffset = Offset(
                      math.cos(orbitAngle) * orbitRadius,
                      math.sin(orbitAngle) * orbitRadius,
                    );

                    // После подключения паук висит сверху и плавно качается.
                    final swingAngle = connected
                        ? math.sin(
                              (spiderSway.value - 0.5) * math.pi,
                            ) *
                            0.16
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

                        if (connecting)
                          Transform.translate(
                            offset: orbitOffset,
                            child: Transform.rotate(
                              angle: orbitAngle * 0.12,
                              child: const CustomPaint(
                                size: Size(54, 81),
                                painter: SpiderPainter(drawThread: false),
                              ),
                            ),
                          ),

                        if (connected)
                          Transform.translate(
                            // Смещаем паука вверх так, чтобы верх нити
                            // оставался прикреплённым к паутине.
                            offset: Offset(0, -orbitRadius - 40),
                            child: Transform.rotate(
                              angle: swingAngle,
                              alignment: Alignment.topCenter,
                              child: const CustomPaint(
                                size: Size(54, 81),
                                painter: SpiderPainter(drawThread: true),
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
                                    ? violetGlow
                                    : violet,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: violet.withOpacity(
                                    connected || connecting ? 0.34 : 0.17,
                                  ),
                                  blurRadius:
                                      connected || connecting ? 26 : 17,
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
          const SizedBox(height: 8),
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
          const SizedBox(height: 7),
          Text(
            connected
                ? formattedTime
                : connecting
                    ? 'Паук плетёт паутину вокруг кнопки'
                    : 'Нажмите кнопку для подключения',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: muted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton(
            onPressed: chooseCountry,
            style: OutlinedButton.styleFrom(
              foregroundColor: white,
              side: BorderSide(
                color: violet.withOpacity(0.9),
                width: 1,
              ),
              minimumSize: const Size.fromHeight(62),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.bolt,
                  color: violetGlow,
                  size: 22,
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'Лучший сервер',
                    style: TextStyle(
                      color: white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(flag, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(country, style: const TextStyle(fontSize: 13)),
                const Icon(
                  Icons.chevron_right,
                  color: violetGlow,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Демо: VPN-сервер не используется',
            style: TextStyle(color: muted, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _serverSummary() {
    return InkWell(
      onTap: chooseCountry,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 13,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: panel,
          border: Border.all(color: const Color(0xFF282033)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Text(
              country,
              style: const TextStyle(
                color: white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            const Text(
              'Изменить',
              style: TextStyle(
                color: violetGlow,
                fontSize: 12,
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: violetGlow,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _profilePage() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
      children: [
        const SizedBox(height: 8),
        Center(
          child: Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: violet, width: 1.5),
              color: panel,
            ),
            child: const Center(
              child: SpiderLogo(size: 68),
            ),
          ),
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
        _profileTile(
          Icons.language,
          'Официальный сайт',
          'Ссылка не задана',
        ),
        const SizedBox(height: 9),
        _profileTile(
          Icons.send,
          'Telegram канал',
          'Ссылка не задана',
        ),
        const SizedBox(height: 18),
        _sectionTitle('Управление'),
        _profileTile(
          Icons.devices,
          'Добавить ещё устройство',
          'До 10 устройств',
        ),
        const SizedBox(height: 9),
        _profileTile(
          Icons.support_agent,
          'Обратиться в поддержку',
          '',
        ),
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
          color: accent ? violet : const Color(0xFF282033),
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, color: violetGlow, size: 25),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: accent ? violetGlow : white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: muted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right,
            color: violetGlow,
          ),
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
              color: selected ? violetGlow : muted,
              size: 23,
            ),
            const SizedBox(height: 3),
            Text(
              title,
              style: TextStyle(
                color: selected ? violetGlow : muted,
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

    final paint = Paint()
      ..color = violetGlow.withOpacity(0.38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.85;

    // Радиальные нити растут от кнопки наружу.
    for (var i = 0; i < 16; i++) {
      final angle = i * math.pi / 8;
      final end = center +
          Offset(math.cos(angle), math.sin(angle)) * radius * p;
      canvas.drawLine(center, end, paint);
    }

    // Кольца паутины появляются по очереди.
    for (var i = 1; i <= 6; i++) {
      final ringProgress = (p * 6 - (i - 1)).clamp(0.0, 1.0);
      if (ringProgress <= 0) continue;

      canvas.drawCircle(
        center,
        radius * (i / 6) * ringProgress,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant WebPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.visible != visible;
  }
}

class SpiderPainter extends CustomPainter {
  const SpiderPainter({
    this.drawThread = true,
  });

  final bool drawThread;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 150);

    final bodyPaint = Paint()
      ..color = violetGlow
      ..style = PaintingStyle.fill;

    final legsPaint = Paint()
      ..color = violetGlow
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final silkPaint = Paint()
      ..color = violetGlow.withOpacity(0.85)
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round;

    // Во время плетения нить скрыта, после подключения паук свисает с неё.
    if (drawThread) {
      canvas.drawLine(
        const Offset(50, 0),
        const Offset(50, 47),
        silkPaint,
      );
    }

    // Брюшко и головогрудь.
    canvas.drawOval(
      const Rect.fromLTRB(38, 45, 62, 101),
      bodyPaint,
    );
    canvas.drawOval(
      const Rect.fromLTRB(43, 99, 57, 123),
      bodyPaint,
    );

    // Восемь угловатых лап, по четыре с каждой стороны.
    final legs = <List<Offset>>[
      [const Offset(42, 55), const Offset(30, 44), const Offset(18, 27)],
      [const Offset(40, 65), const Offset(28, 64), const Offset(12, 47)],
      [const Offset(39, 76), const Offset(25, 88), const Offset(9, 84)],
      [const Offset(41, 88), const Offset(26, 103), const Offset(16, 137)],
      [const Offset(58, 55), const Offset(70, 44), const Offset(82, 27)],
      [const Offset(60, 65), const Offset(72, 64), const Offset(88, 47)],
      [const Offset(61, 76), const Offset(75, 88), const Offset(91, 84)],
      [const Offset(59, 88), const Offset(74, 103), const Offset(84, 137)],
    ];

    for (final points in legs) {
      final path = Path()
        ..moveTo(points[0].dx, points[0].dy)
        ..lineTo(points[1].dx, points[1].dy)
        ..lineTo(points[2].dx, points[2].dy);

      canvas.drawPath(path, legsPaint);
    }

    // Маленькие хелицеры под головой.
    final fangPaint = Paint()
      ..color = violetGlow
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final leftFang = Path()
      ..moveTo(47, 120)
      ..quadraticBezierTo(43, 130, 48, 134);

    final rightFang = Path()
      ..moveTo(53, 120)
      ..quadraticBezierTo(57, 130, 52, 134);

    canvas.drawPath(leftFang, fangPaint);
    canvas.drawPath(rightFang, fangPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant SpiderPainter oldDelegate) {
    return oldDelegate.drawThread != drawThread;
  }
}

class SpiderLogo extends StatelessWidget {
  const SpiderLogo({
    super.key,
    this.size = 26,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 0.67,
      height: size,
      child: const CustomPaint(
        painter: SpiderPainter(),
      ),
    );
  }
}
