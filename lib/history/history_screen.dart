import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import '../core/localization/app_localizations.dart';
import '../core/widgets/gradient_background.dart';
import '../core/services/history_service.dart';
import '../core/services/favorites_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with WidgetsBindingObserver {
  int _selectedTab = 0;
  bool _showFavoritesOnly = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() {});
    }
  }

  List<HistoryEntry> get _allEntries {
    if (_selectedTab == 0) {
      return HistoryService.instance.getMeditationEntries();
    }
    return HistoryService.instance.getBreathingEntries();
  }

  List<HistoryEntry> get _entries {
    final all = _allEntries;
    if (!_showFavoritesOnly) return all;
    final favIds = FavoritesService.instance
        .getFavorites()
        .map((f) => f.id)
        .toSet();
    return all.where((e) => favIds.contains(e.id)).toList();
  }

  void _deleteEntry(HistoryEntry entry) {
    HistoryService.instance.deleteEntry(
      entry.id,
      isMeditation: _selectedTab == 0,
    );
    setState(() {});
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final entries = _entries;

    return GradientBackground(
      child: Column(
        children: [
          SizedBox(height: topPadding + 12),
          _buildHeader(l10n),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _TabSwitcher(
              selected: _selectedTab,
              onChanged: (i) => setState(() => _selectedTab = i),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: entries.isEmpty
                ? Center(
                    child: Text(
                      _showFavoritesOnly
                          ? l10n.t('no_favorites')
                          : (_selectedTab == 0
                              ? l10n.t('no_meditations')
                              : l10n.t('no_breathing')),
                      style: const TextStyle(
                        fontFamily: 'FunnelDisplay',
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFFAAAEBA),
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () async => _refresh(),
                    color: const Color(0xFF111111),
                    child: ListView.separated(
                      padding: EdgeInsets.fromLTRB(
                        24, 0, 24, bottomPadding + 62 + 8 + 32,
                      ),
                      itemCount: entries.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => _HistoryCard(
                        entry: entries[i],
                        isFavorite:
                            FavoritesService.instance.isFavorite(entries[i].id),
                        onDelete: () => _deleteEntry(entries[i]),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        height: 40,
        child: Stack(
          children: [
            Center(
              child: Text(
                l10n.t('history_title'),
                style: const TextStyle(
                  fontFamily: 'FunnelDisplay',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111111),
                  letterSpacing: -0.5,
                ),
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: GestureDetector(
                onTap: () =>
                    setState(() => _showFavoritesOnly = !_showFavoritesOnly),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _showFavoritesOnly
                        ? const Color(0xFF111111)
                        : Colors.white,
                  ),
                  child: Icon(
                    _showFavoritesOnly
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: _showFavoritesOnly
                        ? Colors.white
                        : const Color(0xFFAAAEBA),
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabSwitcher extends StatelessWidget {
  const _TabSwitcher({required this.selected, required this.onChanged});

  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        children: [
          _tab(l10n.t('tab_meditations'), 0),
          _tab(l10n.t('tab_breathing'), 1),
        ],
      ),
    );
  }

  Widget _tab(String label, int index) {
    final isActive = selected == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(index),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF111111) : Colors.transparent,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'FunnelDisplay',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.white : const Color(0xFFAAAEBA),
              letterSpacing: -0.3,
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.entry,
    required this.isFavorite,
    required this.onDelete,
  });

  final HistoryEntry entry;
  final bool isFavorite;
  final VoidCallback onDelete;

  String _formattedDate(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    return DateFormat('d MMM, HH:mm', locale).format(entry.date);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isMeditation = entry.type == 'meditation';

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 88,
              height: 88,
              color: isMeditation
                  ? const Color(0xFFE8E4EC)
                  : const Color(0xFFF0F8F0),
              child: Stack(
                children: [
                  Center(
                    child: isMeditation
                        ? const Icon(
                            Icons.self_improvement,
                            size: 40,
                            color: Color(0xFFAAAEBA),
                          )
                        : SvgPicture.asset(
                            'assets/images/breathing_exercise.svg',
                            width: 40,
                            height: 40,
                            colorFilter: const ColorFilter.mode(
                              Color(0xFF77C97E),
                              BlendMode.srcIn,
                            ),
                          ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 36,
                    child: ClipRRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Color(0x52111111),
                                Color(0x00111111),
                              ],
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${entry.durationMinutes} MIN',
                            style: const TextStyle(
                              fontFamily: 'FunnelDisplay',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              height: 20 / 12,
                              letterSpacing: -0.5,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        entry.title,
                        style: const TextStyle(
                          fontFamily: 'FunnelDisplay',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111111),
                          height: 24 / 16,
                          letterSpacing: -0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isFavorite)
                      const Padding(
                        padding: EdgeInsets.only(right: 4),
                        child: Icon(
                          Icons.favorite,
                          size: 16,
                          color: Color(0xFFCBA7FF),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: GestureDetector(
                        onTap: onDelete,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF6F7FA),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          padding: const EdgeInsets.all(6),
                          child: SvgPicture.asset(
                            'assets/images/trash.svg',
                            width: 20,
                            height: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  entry.goal.isNotEmpty ? entry.goal : _formattedDate(context),
                  style: const TextStyle(
                    fontFamily: 'FunnelDisplay',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFFAAAEBA),
                    height: 20 / 14,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    SvgPicture.asset(
                      isMeditation
                          ? 'assets/images/generate_meditation.svg'
                          : 'assets/images/breathing_exercise.svg',
                      width: 18,
                      height: 18,
                      colorFilter: ColorFilter.mode(
                        isMeditation
                            ? const Color(0xFFCBA7FF)
                            : const Color(0xFF7ACBFF),
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isMeditation
                          ? l10n.t('meditation_type')
                          : l10n.t('breathing_type'),
                      style: TextStyle(
                        fontFamily: 'FunnelDisplay',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isMeditation
                            ? const Color(0xFFCBA7FF)
                            : const Color(0xFF7ACBFF),
                        height: 15 / 12,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formattedDate(context),
                      style: const TextStyle(
                        fontFamily: 'FunnelDisplay',
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFFAAAEBA),
                        height: 15 / 12,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
