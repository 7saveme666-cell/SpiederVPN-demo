import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

const bg = Color(0xFF08070D);
const panel = Color(0xFF12101B);
const panel2 = Color(0xFF191525);
const purple = Color(0xFF8B35FF);
const purpleLight = Color(0xFFB16CFF);
const white = Color(0xFFF5F1FF);
const muted = Color(0xFF938AA8);
const green = Color(0xFF55D69E);

void main() {
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
      home: const SpiederHome(),
    );
  }
}

class SpiederHome extends StatefulWidget {
  const SpiederHome({super.key});

  @override
  State<SpiederHome> createState() => _SpiederHomeState();
}

class _SpiederHomeState extends State<SpiederHome> with TickerProviderStateMixin {
  final countries = const [
    ('Швеция', '🇸🇪', '14 серверов'),
    ('Нидерланды', '🇳🇱', '12 серверов'),
    ('Финляндия', '🇫🇮', '8 серверов'),
    ('Германия', '🇩🇪', '20 серверов'),
    ('Польша', '🇵🇱', '10 серверов'),
    ('Латвия', '🇱🇻', '6 серверов'),
    ('США', '🇺🇸', '4 сервера'),
  ];

  String selectedCountry = 'Швеция';
  bool connected = false;
  bool connecting = false;
  bool showProfile = false;
  int seconds = 0;

  late final AnimationController spiderAnimation;
  Timer? timer;
  Timer? connectDelay;

  String get currentFlag =>
      countries.firstWhere((c) => c.$1 == selectedCountry).$2;

  String get formattedTime {
    final h = (seconds ~/ 3600).toString().padLeft(2, '0');
    final m = ((seconds ~/ 60) % 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  void initState() {
    super.initState();
    spiderAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    timer?.cancel();
    connectDelay?.cancel();
    spiderAnimation.dispose();
    super.dispose();
  }

  void toggleConnection() {
    if (connected) {
      timer?.cancel();
      connectDelay?.cancel();
      setState(() {
        connected = false;
        connecting = false;
        seconds = 0;
      });
      return;
    }

    if (connecting) return;

    setState(() => connecting = true);

    connectDelay = Timer(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      setState(() {
        connecting = false;
        connected = true;
      });

      timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() {
            seconds++;
          });
        }
      });
    });
  }

  void selectCountry(String country) {
    timer?.cancel();
    connectDelay?.cancel();

    setState(() {
      selectedCountry = country;
      connected = false;
      connecting = false;
      seconds = 0;
    });
  }

  Future<void> showCountrySheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: panel,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: SizedBox(
          height: 420,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(18, 10, 18, 12),
                child: Text(
                  'Выберите страну',
                  style: TextStyle(
                    color: white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...countries.map(
                (item) => ListTile(
                  leading: Text(item.$2, style: const TextStyle(fontSize: 28)),
                  title: Text(item.$1),
                  subtitle: Text(
                    item.$3,
                    style: const TextStyle(color: muted),
                  ),
                  trailing: item.$1 == selectedCountry
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: showProfile
              ? _buildProfileScreen()
              : _buildHomeScreen(),
        ),
      ),
    );
  }

  Widget _buildHomeScreen() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
          child: Row(
            children: [
              _iconButton(Icons.menu_rounded, onPressed: () {}),
              const Spacer(),
              const Icon(Icons.spoke, color: purple, size: 22),
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
              _iconButton(Icons.settings, onPressed: () {}),
            ],
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: purple, width: 2),
              borderRadius: BorderRadius.circular(24),
              color: bg,
            ),
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFF100D18),
                            border: Border.all(color: const Color(0xFF2B1D42)),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              Text(currentFlag, style: const TextStyle(fontSize: 24)),
                              const SizedBox(width: 12),
                              Text(
                                selectedCountry,
                                style: const TextStyle(
                                  color: white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: showCountrySheet,
                                style: const ButtonStyle(
                                  overlayColor: MaterialStatePropertyAll(
                                    Color(0x1F8B35FF),
                                  ),
                                ),
                                child: const Text(
                                  'Изменить ›',
                                  style: TextStyle(
                                    color: purpleLight,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Positioned.fill(
                                child: AnimatedBuilder(
                                  animation: spiderAnimation,
                                  builder: (_, __) {
                                    return CustomPaint(
                                      painter: WebPainter(
                                        active: connecting || connected,
                                        progress: spiderAnimation.value,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              Positioned(
                                top: 70,
                                child: CustomPaint(
                                  size: const Size(180, 180),
                                  painter: SpiderPainter(),
                                ),
                              ),
                              GestureDetector(
                                onTap: toggleConnection,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  width: 170,
                                  height: 170,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFF07060D),
                                    border: Border.all(
                                      color:
                                          connected || connecting ? purpleLight : purple,
                                      width: 4,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: purple.withOpacity(
                                          connected || connecting ? 0.70 : 0.30,
                                        ),
                                        blurRadius: 20,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.power_settings_new_rounded,
                                      size: 58,
                                      color: connected || connecting
                                          ? white
                                          : white.withOpacity(0.9),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          connected
                              ? 'Подключено'
                              : connecting
                                  ? 'Подключение...'
                                  : 'Не подключено',
                          style: TextStyle(
                            color: connected ? green : muted,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: const BoxDecoration(),
                          child: Text(
                            connected ? formattedTime : '',
                            style: const TextStyle(
                              color: white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
                          decoration: BoxDecoration(
                            color: panel2,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Color(0xFF2A1B45)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.bolt_rounded, color: purpleLight, size: 22),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Лучший сервер',
                                  style: TextStyle(
                                    color: white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                currentFlag,
                                style: const TextStyle(fontSize: 20),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                selectedCountry,
                                style: const TextStyle(
                                  color: white,
                                  fontSize: 12,
                                ),
                              ),
                              const Icon(Icons.chevron_right, color: purpleLight),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.only(bottom: 12),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0D0A13),
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {},
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.home_rounded, color: purpleLight, size: 26),
                              const SizedBox(height: 4),
                              const Text(
                                'Главная',
                                style: TextStyle(
                                  color: purpleLight,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() => showProfile = true);
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.person_rounded, color: muted, size: 26),
                              const SizedBox(height: 4),
                              const Text(
                                'Профиль',
                                style: TextStyle(
                                  color: muted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileScreen() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => showProfile = false),
                child: const Icon(Icons.arrow_back_ios_new_rounded, color: purpleLight),
              ),
              const Spacer(),
              const Text(
                'Профиль',
                style: TextStyle(
                  color: white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              _iconButton(Icons.settings, onPressed: () {}),
            ],
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: purple, width: 2),
              borderRadius: BorderRadius.circular(24),
              color: bg,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 14),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: purple, width: 2),
                      color: const Color(0xFF0C0914),
                    ),
                    child: Center(
                      child: CustomPaint(
                        size: const Size(80, 80),
                        painter: SpiderPainter(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Spieder VPN',
                    style: TextStyle(
                      color: white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Твой безопасный интернет',
                    style: TextStyle(
                      color: muted,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 18),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: panel2,
                      border: Border.all(color: const Color(0xFF2A1B45)),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.workspace_premium_rounded, color: purpleLight, size: 26),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Подписка активна',
                                style: TextStyle(
                                  color: white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'До 15.05.2025 • 30 дней',
                                style: TextStyle(
                                  color: muted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: purpleLight),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(left: 18),
                      child: const Text(
                        'Полезные ссылки',
                        style: TextStyle(
                          color: muted,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _profileRow(Icons.language_rounded, 'Официальный сайт', 'spiedervpn.com'),
                  _profileRow(Icons.send_rounded, 'Telegram канал', 't.me/spiedervpn'),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(left: 18),
                      child: const Text(
                        'Управление',
                        style: TextStyle(
                          color: muted,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _profileRow(Icons.add_rounded, 'Добавить ещё устройство', '(до 10)'),
                  _profileRow(Icons.support_agent_rounded, 'Обратиться в поддержку', ''),
                  _profileRow(Icons.logout_rounded, 'Выйти из аккаунта', ''),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() => showProfile = false);
                            },
                            child: Column(
                              children: const [
                                Icon(Icons.home_rounded, color: muted, size: 26),
                                SizedBox(height: 4),
                                Text(
                                  'Главная',
                                  style: TextStyle(color: muted, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {},
                            child: Column(
                              children: const [
                                Icon(Icons.person_rounded, color: purpleLight, size: 26),
                                SizedBox(height: 4),
                                Text(
                                  'Профиль',
                                  style: TextStyle(
                                    color: purpleLight,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _profileRow(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: panel2,
        border: Border.all(color: const Color(0xFF2A1B45)),
      ),
      child: Row(
        children: [
          Icon(icon, color: purpleLight, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: subtitle.isEmpty
                ? Text(
                    title,
                    style: const TextStyle(
                      color: white,
                      fontSize: 16,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
          ),
          const Icon(Icons.chevron_right_rounded, color: purpleLight),
        ],
      ),
    );
  }

  Widget _iconButton(IconData icon, {required VoidCallback onPressed}) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFF0F0D18),
          border: Border.all(color: const Color(0xFF2E1F45)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: white, size: 22),
      ),
    );
  }
}

class WebPainter extends CustomPainter {
  final double progress;
  final bool active;

  const WebPainter({
    required this.progress,
    required this.active,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 20);
    final maxRadius = math.min(size.width, size.height) * 0.42;

    final webPaint = Paint()
      ..color = purple.withOpacity(active ? 0.28 : 0.13)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (final r in [0.40, 0.60, 0.82, 1.0]) {
      canvas.drawCircle(center, maxRadius * r, webPaint);
    }

    for (var i = 0; i < 16; i++) {
      final angle = i * math.pi / 8;
      final end = center + Offset(math.cos(angle), math.sin(angle)) * maxRadius;
      canvas.drawLine(center, end, webPaint);
    }

    if (active) {
      final strandPaint = Paint()
        ..color = purpleLight.withOpacity(0.95)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

      for (var i = 0; i < 14; i++) {
        final angle = (i * math.pi / 7) + progress * math.pi * 2;
        final radius = maxRadius * (0.25 + 0.75 * (0.8 + (progress * 0.2)));
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

class SpiderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final body = Paint()..color = const Color(0xFF1B0F2B);
    final shadow = Paint()..color = const Color(0xFF6A2AFF).withOpacity(0.2);

    // body
    canvas.drawCircle(center, 34, body);
    canvas.drawCircle(center.offset(0, 24), 22, body);

    // legs
    final legPaint = Paint()
      ..color = purpleLight
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    for (final sign in [-1.0, 1.0]) {
      for (int i = 0; i < 4; i++) {
        final y = center.dy - 10 + i * 15;
        final x = center.dx + sign * (12 + i * 2);
        final end = Offset(x + sign * 26, y - 12 + i * 8);
        canvas.drawLine(
          Offset(center.dx + sign * 10, y),
          end,
          legPaint,
        );
      }
    }

    // eyes and glow
    final eyePaint = Paint()..color = Colors.white.withOpacity(0.9);
    final glowPaint = Paint()..color = purpleLight.withOpacity(0.7);

    canvas.drawCircle(center.offset(-8, -2), 4, eyePaint);
    canvas.drawCircle(center.offset(8, -2), 4, eyePaint);

    canvas.drawCircle(center.offset(0, 18), 10, glowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
