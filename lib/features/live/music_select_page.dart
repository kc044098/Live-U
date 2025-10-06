import 'package:djs_live_stream/features/live/video_repository_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../l10n/l10n.dart';
import '../profile/profile_controller.dart';
import 'data_model/music_track.dart';

class MusicSelectPage extends ConsumerStatefulWidget {
  const MusicSelectPage({Key? key}) : super(key: key);

  @override
  ConsumerState<MusicSelectPage> createState() => _MusicSelectPageState();
}

class _MusicSelectPageState extends ConsumerState<MusicSelectPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final TextEditingController _search = TextEditingController();
  String? _selectedPath;

  // 本地收藏 / 用過（以 track.id 為準）
  final Set<String> _favoritedIds = {};
  final Set<String> _usedIds = {};

  final AudioPlayer _player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _player.setReleaseMode(ReleaseMode.loop);
  }

  @override
  void dispose() {
    _player.stop();
    _player.dispose();
    _tab.dispose();
    _search.dispose();
    super.dispose();
  }

  Future<void> _playPreview(String absUrl) async {
    try {
      await _player.stop();
      await _player.play(UrlSource(absUrl));
    } catch (e) {
      debugPrint('預聽失敗： $e');
    }
  }

  List<MusicTrack> _filtered(List<MusicTrack> all, int tabIndex) {
    final q = _search.text.trim();
    Iterable<MusicTrack> src;
    switch (tabIndex) {
      case 0: // 推荐
        src = all.where((e) => e.recommended);
        break;
      case 1: // 收藏（本地）
        src = all.where((e) => _favoritedIds.contains(e.id));
        break;
      default: // 用過（本地）
        src = all.where((e) => _usedIds.contains(e.id));
        break;
    }
    if (q.isEmpty) return src.toList();
    return src
        .where((e) =>
    e.title.toLowerCase().contains(q.toLowerCase()) ||
        e.artist.toLowerCase().contains(q.toLowerCase()))
        .toList();
  }

  String _mmss(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final top = MediaQuery.of(context).padding.top;
    final asyncTracks = ref.watch(musicListProvider);

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _selectedPath); // 帶回路徑（可能為 null）
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            SizedBox(height: top),
            _AppBar(onBack: () {
              Navigator.pop(context, _selectedPath);
            }),
            // 搜索框
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F5F7),
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Color(0xFFB8BBC2)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: TextField(
                        controller: _search,
                        decoration: InputDecoration(
                          hintText: s.musicSearchHint,
                          isCollapsed: true,
                          border: InputBorder.none,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Tabs
            _MusicTabs(controller: _tab),
            // 列表（根據 provider 狀態顯示）
            Expanded(
              child: asyncTracks.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, st) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(s.musicLoadFailedTitle, style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 8),
                      Text(
                        '$err',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => ref.refresh(musicListProvider),
                        child: Text(s.retry),
                      ),
                    ],
                  ),
                ),
                data: (all) => TabBarView(
                  controller: _tab,
                  children: List.generate(3, (index) {
                    final items = _filtered(all, index);
                    if (items.isEmpty) {
                      return Center(
                        child: Text(s.musicNoContent,  style: const TextStyle(color: Colors.grey)),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const Divider(
                        height: 1, indent: 68, endIndent: 16, color: Color(0xFFEDEDF0),
                      ),
                      itemBuilder: (ctx, i) {
                        final t = items[i];
                        final selected = (t.path == _selectedPath);
                        final isFav = _favoritedIds.contains(t.id);

                        return _MusicCell(
                          track: t,
                          highlightUse: selected,
                          durationText: _mmss(t.duration),
                          onUse: () {
                            final cdnUrl = ref.watch(userProfileProvider)?.cdnUrl;
                            setState(() {
                              _selectedPath = t.path;                         // 回傳相對路徑
                              _usedIds.add(t.id);
                            });
                            _playPreview('$cdnUrl${t.path}');                // ★ 循環預聽
                          },
                          onToggleFav: () {
                            setState(() {
                              if (isFav) {
                                _favoritedIds.remove(t.id);
                              } else {
                                _favoritedIds.add(t.id);
                              }
                            });
                          },
                          isFavorited: isFav,
                        );
                      },
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MusicTabs extends StatelessWidget {
  final TabController controller;
  const _MusicTabs({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return TabBar(
      dividerColor: Colors.transparent,
      controller: controller,
      labelColor: const Color(0xFFFB4C61),
      unselectedLabelColor: const Color(0xFF8E8895),
      indicatorColor: const Color(0xFFFB4C61),
      indicatorWeight: 2,
      tabs: [
        Tab(text: s.musicTabRecommend), // ✅ '推荐'
        Tab(text: s.musicTabFavorites), // ✅ '收藏'
        Tab(text: s.musicTabUsed),      // ✅ '用过'
      ],
    );
  }
}


class _MusicCell extends StatelessWidget {
  final MusicTrack track;
  final bool highlightUse;
  final String durationText;
  final VoidCallback onUse;
  final VoidCallback onToggleFav;
  final bool isFavorited;

  const _MusicCell({
    Key? key,
    required this.track,
    required this.highlightUse,
    required this.durationText,
    required this.onUse,
    required this.onToggleFav,
    required this.isFavorited,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final titleStyle = TextStyle(
      fontSize: 15,
      color: Colors.black87,
      fontWeight: FontWeight.w600,
      height: 1.1,
      shadows: highlightUse ? [const Shadow(blurRadius: 0.1)] : null,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          // Emoji 圓頭像
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: highlightUse
                  ? const LinearGradient(colors: [Color(0xFF4DE1E2), Color(0xFFFF4C6A)])
                  : null,
            ),
            padding: const EdgeInsets.all(2),
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle, color: Color(0xFFF3F6FA),
              ),
              alignment: Alignment.center,
              child: Text(track.coverEmoji, style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 12),
          // 文案
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Flexible(
                    child: Text(track.title, style: titleStyle, overflow: TextOverflow.ellipsis),
                  ),
                  if (highlightUse) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.equalizer, size: 14, color: Color(0xFFFB4C61)),
                  ],
                ]),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        track.artist,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF8E8895)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text('· $durationText',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF8E8895))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // 使用 + 收藏
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _UseButton(
                emphasized: highlightUse,
                enabled: true,
                onTap: onUse,
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onToggleFav,
                child: Icon(
                  isFavorited ? Icons.star_rounded : Icons.star_border_rounded,
                  color: isFavorited ? const Color(0xFFFB4C61) : const Color(0xFFCDD0D6),
                  size: 22,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UseButton extends StatelessWidget {
  final bool emphasized;
  final bool enabled;
  final VoidCallback onTap;

  const _UseButton({
    Key? key,
    required this.emphasized,
    required this.enabled,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final bg = emphasized ? const Color(0xFFFB4C61) : const Color(0xFFF2F3F5);
    final fg = emphasized ? Colors.white : const Color(0xFF8E8895);
    return Opacity(
      opacity: enabled ? 1 : .6,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            s.useAction,
            style:
                TextStyle(color: fg, fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

class _AppBar extends StatelessWidget {
  final VoidCallback onBack;

  const _AppBar({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios,
                size: 20, color: Colors.black87),
            onPressed: onBack,
          ),
          Expanded(
            child: Text(
              s.musicAddTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 18,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}
