import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/storage_service.dart';
import 'providers/study_provider.dart';
import 'models/character_state.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko');
  final prefs = await SharedPreferences.getInstance();
  final storageService = StorageService(prefs);

  runApp(StudyAnxietyApp(storageService: storageService));
}

class StudyAnxietyApp extends StatelessWidget {
  final StorageService storageService;

  const StudyAnxietyApp({super.key, required this.storageService});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => StudyProvider(storageService),
      child: const CupertinoApp(
        title: '불공사',
        theme: CupertinoThemeData(
          primaryColor: CupertinoColors.systemBlue,
          brightness: Brightness.light,
          scaffoldBackgroundColor: CupertinoColors.systemGroupedBackground,
        ),
        home: MainScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static const Color _pixelBg = Color(0xFFF5F0E8);
  static const Color _pixelBorder = Color(0xFF3D3D3D);
  static const Color _pixelAccent = Color(0xFF5B8C5A);
  static const Color _pixelWarm = Color(0xFFE8D4B8);

  final List<Widget> _screens = const [HomeScreen(), StatsScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pixelBg,
      body: _screens[_selectedIndex],
      bottomNavigationBar: _buildPixelTabBar(),
    );
  }

  Widget _buildPixelTabBar() {
    return Container(
      decoration: const BoxDecoration(
        color: _pixelWarm,
        border: Border(top: BorderSide(color: _pixelBorder, width: 3)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: _buildTabItem(index: 0, icon: '🏠', label: 'HOME'),
              ),
              Container(width: 3, height: 40, color: _pixelBorder),
              Expanded(
                child: _buildTabItem(index: 1, icon: '📊', label: 'STATS'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem({
    required int index,
    required String icon,
    required String label,
  }) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? _pixelAccent : Colors.transparent,
          border: Border.all(
            color: isSelected ? _pixelBorder : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
                color: isSelected ? Colors.white : _pixelBorder,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Home Screen - Character Display + Timer
// ============================================================
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const Color _pixelBg = Color(0xFFF5F0E8);
  static const Color _pixelBorder = Color(0xFF3D3D3D);
  static const Color _pixelAccent = Color(0xFF5B8C5A);
  static const Color _pixelWarm = Color(0xFFE8D4B8);

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: _pixelBg,
      child: SafeArea(
        child: Consumer<StudyProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return _buildLoadingScreen();
            }
            return Column(
              children: [
                const SizedBox(height: 20),
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 16),
                        _buildCharacterSection(provider),
                        const SizedBox(height: 24),
                        _buildTodayStats(provider),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                _buildTimerSection(context, provider),
                const SizedBox(height: 24),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: _pixelBorder, width: 4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(child: CupertinoActivityIndicator(radius: 20)),
          ),
          const SizedBox(height: 16),
          const Text(
            '로딩 중...',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _pixelBorder,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _pixelWarm,
        border: Border.all(color: _pixelBorder, width: 3),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('📚 ', style: TextStyle(fontSize: 18)),
          Text(
            'STUDY BUDDY',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: _pixelBorder,
              letterSpacing: 2,
            ),
          ),
          Text(' 📚', style: TextStyle(fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildCharacterSection(StudyProvider provider) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildStatusBadge(provider.anxietyLevel),
        const SizedBox(height: 16),
        _buildCharacterFrame(provider),
        const SizedBox(height: 16),
        _buildMessageBox(provider.anxietyLevel.message),
      ],
    );
  }

  Widget _buildStatusBadge(AnxietyLevel level) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _getStatusColor(level),
        border: Border.all(color: _pixelBorder, width: 2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '[ ${level.label.toUpperCase()} ]',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildCharacterFrame(StudyProvider provider) {
    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _pixelBorder, width: 4),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            offset: Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getBackgroundColor(provider.anxietyLevel),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Center(
            child: Image.asset(
              provider.anxietyLevel.imagePath,
              width: 180,
              height: 180,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.none,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBox(String message) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _pixelBorder, width: 2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: _pixelBorder,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildTodayStats(StudyProvider provider) {
    if (provider.isStudying) {
      return _buildTimerDisplay(provider);
    }

    final totalSeconds = provider.todaySeconds;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    String timeStr;
    if (hours > 0) {
      timeStr = '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      timeStr = '${minutes}m ${seconds}s';
    } else {
      timeStr = '${seconds}s';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: _pixelWarm,
        border: Border.all(color: _pixelBorder, width: 2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('⏱️ ', style: TextStyle(fontSize: 20)),
          const Text(
            'TODAY: ',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _pixelBorder,
            ),
          ),
          Text(
            timeStr,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: _pixelAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerDisplay(StudyProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: _pixelAccent.withOpacity(0.1),
        border: Border.all(color: _pixelAccent, width: 3),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          const Text(
            '📖 공부 중...',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _pixelAccent,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            provider.formatDuration(provider.currentSessionDuration),
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w800,
              color: _pixelBorder,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerSection(BuildContext context, StudyProvider provider) {
    if (provider.isStudying) {
      return _buildPixelButton(
        onPressed: () => provider.stopStudySession(),
        label: '■ 그만하기',
        color: const Color(0xFFD9534F),
      );
    }

    return _buildPixelButton(
      onPressed: () => provider.startStudySession(),
      label: '▶ 공부 시작!',
      color: _pixelAccent,
    );
  }

  Widget _buildPixelButton({
    required VoidCallback onPressed,
    required String label,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: _pixelBorder, width: 3),
          borderRadius: BorderRadius.circular(4),
          boxShadow: const [
            BoxShadow(
              color: Color(0x44000000),
              offset: Offset(3, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(AnxietyLevel level) {
    switch (level) {
      case AnxietyLevel.peaceful:
        return const Color(0xFF5B8C5A);
      case AnxietyLevel.slightlyAnxious:
        return const Color(0xFF6B8E9F);
      case AnxietyLevel.anxious:
        return const Color(0xFFE6A23C);
      case AnxietyLevel.veryAnxious:
        return const Color(0xFFE87D7D);
      case AnxietyLevel.panic:
        return const Color(0xFFD9534F);
    }
  }

  Color _getBackgroundColor(AnxietyLevel level) {
    switch (level) {
      case AnxietyLevel.peaceful:
        return const Color(0xFFE8F5E9);
      case AnxietyLevel.slightlyAnxious:
        return const Color(0xFFFFF8E1);
      case AnxietyLevel.anxious:
        return const Color(0xFFFFF3E0);
      case AnxietyLevel.veryAnxious:
        return const Color(0xFFFFEBEE);
      case AnxietyLevel.panic:
        return const Color(0xFFFCE4EC);
    }
  }
}

// ============================================================
// Stats Screen - Weekly Chart + Daily Breakdown
// ============================================================
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  static const Color _pixelBg = Color(0xFFF5F0E8);
  static const Color _pixelBorder = Color(0xFF3D3D3D);
  static const Color _pixelAccent = Color(0xFF5B8C5A);
  static const Color _pixelWarm = Color(0xFFE8D4B8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pixelBg,
      body: SafeArea(
        child: Consumer<StudyProvider>(
          builder: (context, provider, child) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildWeeklySummaryCard(provider),
                  const SizedBox(height: 20),
                  _buildWeeklyChartCard(provider),
                  const SizedBox(height: 20),
                  _buildDailyBreakdown(provider),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _pixelWarm,
        border: Border.all(color: _pixelBorder, width: 3),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('📊 ', style: TextStyle(fontSize: 18)),
          Text(
            'STUDY STATS',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: _pixelBorder,
              letterSpacing: 2,
            ),
          ),
          Text(' 📊', style: TextStyle(fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildWeeklySummaryCard(StudyProvider provider) {
    final totalMinutes = provider.weeklyStats.fold<int>(
      0,
      (sum, s) => sum + s.totalMinutes,
    );
    final totalHours = totalMinutes ~/ 60;
    final remainingMinutes = totalMinutes % 60;
    final avgMinutesPerDay = provider.weeklyStats.isNotEmpty
        ? (totalMinutes / provider.weeklyStats.length).round()
        : 0;
    final totalSessions = provider.weeklyStats.fold<int>(
      0,
      (sum, s) => sum + s.sessionCount,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _pixelAccent,
        border: Border.all(color: _pixelBorder, width: 3),
        borderRadius: BorderRadius.circular(4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x44000000),
            offset: Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📚 이번 주 공부 시간',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            totalHours > 0
                ? '${totalHours}h ${remainingMinutes}m'
                : '${remainingMinutes}m',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(40),
              border: Border.all(color: Colors.white.withAlpha(80), width: 2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildSummaryItem('⏱️ 일 평균', '${avgMinutesPerDay}분'),
                ),
                Container(
                  width: 2,
                  height: 30,
                  color: Colors.white.withAlpha(80),
                ),
                Expanded(
                  child: _buildSummaryItem('📖 총 세션', '$totalSessions회'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withAlpha(200),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyChartCard(StudyProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _pixelBorder, width: 3),
        borderRadius: BorderRadius.circular(4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            offset: Offset(3, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📈 주간 공부 시간',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: _pixelBorder,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: provider.weeklyStats.isEmpty
                ? const Center(
                    child: Text(
                      '📭 아직 데이터가 없어요',
                      style: TextStyle(
                        color: _pixelBorder,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : _buildBarChart(provider.weeklyStats),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(List<dynamic> stats) {
    final maxMinutes = stats.fold<int>(
      0,
      (max, s) => s.totalMinutes > max ? s.totalMinutes : max,
    );
    final maxY = (maxMinutes / 60.0).ceil().toDouble() + 1;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY > 0 ? maxY : 5,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => _pixelBorder,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final minutes = (rod.toY * 60).round();
              return BarTooltipItem(
                '$minutes분',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < stats.length) {
                  final date = stats[index].date;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      DateFormat.E('ko').format(date),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _pixelBorder,
                      ),
                    ),
                  );
                }
                return const SizedBox();
              },
              reservedSize: 28,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}h',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _pixelBorder,
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(color: _pixelBorder.withAlpha(40), strokeWidth: 1);
          },
        ),
        barGroups: stats.asMap().entries.map((entry) {
          final index = entry.key;
          final stat = entry.value;
          final hours = stat.totalMinutes / 60.0;

          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: hours,
                color: _pixelAccent,
                width: 20,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(2),
                  topRight: Radius.circular(2),
                ),
                borderSide: const BorderSide(color: _pixelBorder, width: 2),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDailyBreakdown(StudyProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _pixelWarm,
            border: Border.all(color: _pixelBorder, width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            '📅 일별 상세',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: _pixelBorder,
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...provider.weeklyStats.reversed.map((stat) => _buildDayItem(stat)),
      ],
    );
  }

  Widget _buildDayItem(dynamic stat) {
    final isToday = _isToday(stat.date);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isToday ? _pixelAccent.withAlpha(30) : Colors.white,
        border: Border.all(
          color: isToday ? _pixelAccent : _pixelBorder,
          width: isToday ? 3 : 2,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          if (isToday) const Text('⭐ ', style: TextStyle(fontSize: 16)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('M월 d일 (E)', 'ko').format(stat.date),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                    color: _pixelBorder,
                  ),
                ),
                if (isToday)
                  const Text(
                    'TODAY',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: _pixelAccent,
                      letterSpacing: 1,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _pixelWarm,
              border: Border.all(color: _pixelBorder, width: 2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  stat.formattedDuration,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _pixelBorder,
                  ),
                ),
                Text(
                  '${stat.sessionCount}회',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _pixelBorder,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}
