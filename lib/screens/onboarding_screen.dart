import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../widgets/mission_widgets.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  static const _pages = [
    (
      title: 'Read the world like a navigator',
      body:
          'Use roads, terrain, language, and architecture to triangulate each drop zone.',
      icon: Icons.travel_explore_rounded,
    ),
    (
      title: 'Track live telemetry',
      body:
          'HUD modules surface streaks, accuracy, and seasonal progress while you play.',
      icon: Icons.radar_rounded,
    ),
    (
      title: 'Squad up for relay missions',
      body:
          'Friends can challenge, spectate, and compare replays across your vault unlocks.',
      icon: Icons.groups_rounded,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_page == _pages.length - 1) {
      Navigator.of(context).pop();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF050B14),
                  Color(0xFF111D34),
                  Color(0xFF1B1630)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.public_rounded, color: KuglaColors.cyan),
                      const SizedBox(width: 10),
                      Text(
                        'Mission Briefing',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Skip'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: PageView.builder(
                      controller: _controller,
                      onPageChanged: (value) => setState(() => _page = value),
                      itemCount: _pages.length,
                      itemBuilder: (context, index) {
                        final page = _pages[index];
                        return Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 680),
                            child: GlassPanel(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 92,
                                      height: 92,
                                      decoration: BoxDecoration(
                                        color:
                                            KuglaColors.cyan.withValues(alpha: 0.14),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(page.icon,
                                          size: 42,
                                          color: KuglaColors.cyanSoft),
                                    ),
                                    const SizedBox(height: 28),
                                    Text(
                                      page.title,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w900,
                                          ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      page.body,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: KuglaColors.textMuted,
                                        fontSize: 16,
                                        height: 1.6,
                                      ),
                                    ),
                                    const SizedBox(height: 28),
                                    const Wrap(
                                      spacing: 10,
                                      runSpacing: 10,
                                      alignment: WrapAlignment.center,
                                      children: [
                                        Chip(
                                            label: Text(
                                                'Street View expeditions')),
                                        Chip(label: Text('Squad challenges')),
                                        Chip(label: Text('Vault progression')),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      ...List.generate(
                        _pages.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.only(right: 8),
                          width: _page == index ? 28 : 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _page == index
                                ? KuglaColors.cyan
                                : Colors.white24,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: _next,
                        icon: Icon(_page == _pages.length - 1
                            ? Icons.check_rounded
                            : Icons.arrow_forward_rounded),
                        label: Text(_page == _pages.length - 1
                            ? 'Launch Kugla'
                            : 'Next'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
