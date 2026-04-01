import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'package:google_fonts/google_fonts.dart';

class SetSelectScreen extends StatelessWidget {
  const SetSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios_rounded, color: Color(0xFF003266)),
        ),
        title: Text(
          'Choose a Set',
          style: GoogleFonts.nunito(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF003266),
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Which set do you want to review?',
              style: GoogleFonts.nunito(
                fontSize: 15,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            _SetCard(
              label: 'Set A',
              questionCount: 50,
              levelCount: 5,
              isActive: provider.activeSet == QuizSet.a,
              unlockedLevels: provider.unlockedLevelsFor(QuizSet.a),
              onTap: () {
                provider.setActiveSet(QuizSet.a);
                Navigator.pushNamed(context, '/levels');
              },
            ),
            const SizedBox(height: 16),
            _SetCard(
              label: 'Set B',
              questionCount: 57,
              levelCount: 6,
              isActive: provider.activeSet == QuizSet.b,
              unlockedLevels: provider.unlockedLevelsFor(QuizSet.b),
              onTap: () {
                provider.setActiveSet(QuizSet.b);
                Navigator.pushNamed(context, '/levels');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SetCard extends StatelessWidget {
  final String label;
  final int questionCount;
  final int levelCount;
  final bool isActive;
  final int unlockedLevels;
  final VoidCallback onTap;

  const _SetCard({
    required this.label,
    required this.questionCount,
    required this.levelCount,
    required this.isActive,
    required this.unlockedLevels,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF003266) : const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? const Color(0xFF003266) : const Color(0xFFE8ECF0),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.nunito(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: isActive ? Colors.white : const Color(0xFF003266),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$questionCount questions · $levelCount levels',
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      color: isActive ? Colors.white70 : Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Level $unlockedLevels unlocked',
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isActive ? const Color(0xFF38BDF8) : const Color(0xFF003266),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: isActive ? Colors.white70 : const Color(0xFF003266),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
