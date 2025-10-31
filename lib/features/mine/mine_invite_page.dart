import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import '../../l10n/l10n.dart';
import '../profile/profile_controller.dart';
import '../wallet/withdraw_page.dart';
import 'model/invite_list_state.dart';
import 'model/invite_user_item.dart';
import 'model/reward_item.dart';
import 'model/reward_list_state.dart';

class MyInvitePage extends ConsumerStatefulWidget {
  const MyInvitePage({super.key});

  @override
  ConsumerState<MyInvitePage> createState() => _MyInvitePageState();
}

class _MyInvitePageState extends ConsumerState<MyInvitePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final user = ref.watch(userProfileProvider);
    final int totalIncome = user?.totalIncome ?? 0; // 累計佣金獎勵
    final int cashAmount  = user?.cashAmount  ?? 0; // 可提現金額

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(s.myInvitesTitle, style: const TextStyle(fontSize: 16, color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            Stack(
              children: [
                Center(
                  child: Image.asset(
                    'assets/bg_my_invite_title.png',
                    width: 380,
                    height: 180,
                    fit: BoxFit.fitWidth,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.red, width: 2),
                          ),
                          child: CircleAvatar(
                          radius: 23,
                          backgroundImage: user?.avatarImage,
                        ),

                ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            user?.displayName ?? '',
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 30,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => WithdrawPage(),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFFA770),
                                    Color(0xFFD247FE)
                                  ],
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                s.withdraw,
                                style: TextStyle(
                                    fontSize: 16, color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  top: 90,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        // 左側：累計佣金獎勵（佔 50%）
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                s.totalCommissionReward,
                                style: TextStyle(fontSize: 14, color: Colors.black54),
                              ),
                              const SizedBox(height: 8),
                              // 長數字自動縮小以避免溢出
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '\$ ${(totalIncome / 100).toStringAsFixed(2)}',
                                  maxLines: 1,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // 右側：可提現金額（佔 50%）
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                s.withdrawableAmount,
                                style: TextStyle(fontSize: 14, color: Colors.black54),
                              ),
                              const SizedBox(height: 8),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '\$ ${(cashAmount / 100).toStringAsFixed(2)}',
                                  maxLines: 1,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
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
            ),
            const SizedBox(height: 5),
            TabBar(
              controller: _tabController,
              splashFactory: NoSplash.splashFactory,
              overlayColor: MaterialStateProperty.all(Colors.transparent),
              labelColor: Colors.black,
              unselectedLabelColor: Color(0xFF888888),
              labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              unselectedLabelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              dividerColor: Colors.transparent,
              indicator: const GradientTabIndicator(
                gradient: LinearGradient(
                  colors: [Color(0xFFFFA770), Color(0xFFD247FE)],
                ),
                indicatorHeight: 5,
                indicatorWidth: 30,
                radius: 6,
              ),
              tabs: [
                Tab(text: s.tabMyRewards),
                Tab(text: s.tabInvitees),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  RewardTabView(),
                  InviteTabView(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GradientTabIndicator extends Decoration {
  final LinearGradient gradient;
  final double indicatorHeight;
  final double indicatorWidth;
  final double radius;

  const GradientTabIndicator({
    required this.gradient,
    this.indicatorHeight = 5.0,
    this.indicatorWidth = 30.0,
    this.radius = 6.0,
  });

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _GradientPainter(this, onChanged);
  }
}

class _GradientPainter extends BoxPainter {
  final GradientTabIndicator decoration;

  _GradientPainter(this.decoration, VoidCallback? onChanged) : super(onChanged);

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final double tabWidth = configuration.size!.width;
    final double tabHeight = configuration.size!.height;

    final double left = offset.dx + (tabWidth - decoration.indicatorWidth) / 2;
    final double top = offset.dy + tabHeight - decoration.indicatorHeight;

    final Rect rect = Rect.fromLTWH(
      left,
      top,
      decoration.indicatorWidth,
      decoration.indicatorHeight,
    );

    final RRect rRect = RRect.fromRectAndRadius(rect, Radius.circular(decoration.radius));

    final Paint paint = Paint()
      ..shader = decoration.gradient.createShader(rect)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(rRect, paint);
  }
}

class RewardTabView extends ConsumerStatefulWidget {
  const RewardTabView({super.key});

  @override
  ConsumerState<RewardTabView> createState() => _RewardTabViewState();
}

class _RewardTabViewState extends ConsumerState<RewardTabView> {
  int selectedIndex = 0; // 0=今日, 1=昨日, 2=累計

  final RefreshController _rc = RefreshController(initialRefresh: false);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(rewardListProvider.notifier).loadFirstPage();
    });
  }

  @override
  void dispose() {
    _rc.dispose();
    super.dispose();
  }

  // ---------- 時間工具（與 InviteTabView 一致） ----------
  DateTime _startOfTodayLocal() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  bool _isToday(int epochSec) {
    if (epochSec <= 0) return false;
    final dt = DateTime.fromMillisecondsSinceEpoch(epochSec * 1000, isUtc: true).toLocal();
    final start = _startOfTodayLocal();
    final end = start.add(const Duration(days: 1));
    return !dt.isBefore(start) && dt.isBefore(end);
  }

  bool _isYesterday(int epochSec) {
    if (epochSec <= 0) return false;
    final dt = DateTime.fromMillisecondsSinceEpoch(epochSec * 1000, isUtc: true).toLocal();
    final startToday = _startOfTodayLocal();
    final startY = startToday.subtract(const Duration(days: 1));
    return !dt.isBefore(startY) && dt.isBefore(startToday);
  }

  List<RewardItem> _applyFilter(List<RewardItem> all) {
    switch (selectedIndex) {
      case 0: return all.where((e) => _isToday(e.createAt)).toList();     // 今日
      case 1: return all.where((e) => _isYesterday(e.createAt)).toList();  // 昨日
      case 2:
      default: return all;                                                // 累計
    }
  }

  String _fmtMoneyCents(int cents) => '\$ ${(cents / 100).toStringAsFixed(2)}';

  String _fullUrl(String base, String p) {
    if (p.isEmpty) return p;
    if (p.startsWith('http')) return p;
    if (base.isEmpty) return p;
    return p.startsWith('/') ? '$base$p' : '$base/$p';
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final tabs = [s.todayLabel, s.yesterdayLabel, s.totalLabel];

    final state = ref.watch(rewardListProvider);
    final cdn   = ref.watch(userProfileProvider)?.cdnUrl ?? '';

    final filtered = _applyFilter(state.items);
    final int totalCents = filtered.fold(0, (s, it) => s + it.gold);
    final int times = filtered.length;

    return Column(
      children: [
        // 🔘 過濾切換（今日/昨日/累計）
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: List.generate(tabs.length, (index) {
              final isSelected = selectedIndex == index;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GestureDetector(
                  onTap: () => setState(() => selectedIndex = index),
                  child: Container(
                    width: 76,
                    height: 30,
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFFFEFEF) : const Color(0xFFFAFAFA),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      tabs[index],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? const Color(0xFFFF4D67) : const Color(0xFF888888),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),

        // ▲ 上方統計卡
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          decoration: BoxDecoration(
            color: const Color(0xFFFEEEF4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(s.commissionRewards, style: TextStyle(fontSize: 12, color: Color(0xFFB1A3A9))),
                    const SizedBox(height: 8),
                    Text(
                      _fmtMoneyCents(totalCents),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(s.rewardsCountLabel, style: TextStyle(fontSize: 12, color: Color(0xFFB1A3A9))),
                    const SizedBox(height: 8),
                    Text(
                      '$times',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // ▼ 清單 + 分頁（用 SmartRefresher，僅顯示它的進度圈）
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                // 標題列
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(s.userWord,
                          textAlign: TextAlign.start,
                          style: const TextStyle(fontSize: 14, color: Color(0xFF9E9E9E), fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        child: Text(s.rechargeRewardLabel,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: Color(0xFF9E9E9E), fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SmartRefresher(
                    controller: _rc,
                    enablePullDown: true,
                    enablePullUp: state.hasMore, // 只有還有更多時才開啟，避免尾頁的 "No more data"
                    onRefresh: () async {
                      await ref.read(rewardListProvider.notifier).loadFirstPage();
                      final ns = ref.read(rewardListProvider);
                      _rc.refreshCompleted();
                      // 只有完全 0 筆才顯示 "No more data"
                      if (ns.items.isEmpty) {
                        _rc.loadNoData();
                      } else {
                        _rc.resetNoData();
                      }
                    },
                    onLoading: () async {
                      await ref.read(rewardListProvider.notifier).loadNextPage();
                      final ns = ref.read(rewardListProvider);
                      if (ns.hasMore) {
                        _rc.loadComplete();
                      } else {
                        // 沒更多頁：若總數為 0 才顯示 "No more data"；已有資料就不顯示
                        if (ns.items.isEmpty) {
                          _rc.loadNoData();
                        } else {
                          _rc.loadComplete();
                        }
                      }
                    },
                    header: const ClassicHeader(),
                    footer: const ClassicFooter(),
                    // ❗ 只渲染清單/空態/錯誤，不再加自訂 spinner，避免雙進度圈
                    child: _buildList(filtered, state, cdn),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildList(List<RewardItem> filtered, RewardListState state, String cdnBase) {
    final s = S.of(context);
    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.only(top: 40),
          child: Text(s.noData, style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (_, index) {
        final it = filtered[index];
        final avatarRel = it.avatar.isNotEmpty ? it.avatar.first : '';
        final avatarUrl = _fullUrl(cdnBase, avatarRel);
        final nick = it.nickName.isNotEmpty ? it.nickName : s.userWithId(it.uid);
        final amount = _fmtMoneyCents(it.gold);

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 15,
                backgroundImage: avatarUrl.isNotEmpty
                    ? NetworkImage(avatarUrl)
                    : const AssetImage('assets/my_icon_defult.jpeg') as ImageProvider,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(nick, style: const TextStyle(fontSize: 14))),
              Text(amount, style: const TextStyle(fontSize: 14)),
            ],
          ),
        );
      },
    );
  }
}

class RewardStat {
  final double amount;
  final int times;

  RewardStat({required this.amount, required this.times});
}

class InviteTabView extends ConsumerStatefulWidget {
  const InviteTabView({super.key});

  @override
  ConsumerState<InviteTabView> createState() => _InviteTabViewState();
}

class _InviteTabViewState extends ConsumerState<InviteTabView> {
  int selectedIndex = 0; // 0=今日, 1=昨日, 2=累計

  final RefreshController _rc = RefreshController(initialRefresh: false);

  @override
  void initState() {
    super.initState();
    // 首次載入第一頁
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(inviteListProvider.notifier).loadFirstPage();
    });
  }

  @override
  void dispose() {
    _rc.dispose();
    super.dispose();
  }

  // ---------- 時間工具 ----------
  DateTime _startOfTodayLocal() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  bool _isToday(int epochSec) {
    if (epochSec <= 0) return false;
    final dt = DateTime.fromMillisecondsSinceEpoch(epochSec * 1000, isUtc: true).toLocal();
    final start = _startOfTodayLocal();
    final end = start.add(const Duration(days: 1));
    return !dt.isBefore(start) && dt.isBefore(end);
  }

  bool _isYesterday(int epochSec) {
    if (epochSec <= 0) return false;
    final dt = DateTime.fromMillisecondsSinceEpoch(epochSec * 1000, isUtc: true).toLocal();
    final startToday = _startOfTodayLocal();
    final startY = startToday.subtract(const Duration(days: 1));
    return !dt.isBefore(startY) && dt.isBefore(startToday);
  }

  List<InviteUserItem> _applyFilter(List<InviteUserItem> all) {
    switch (selectedIndex) {
      case 0: // 今日
        return all.where((e) => _isToday(e.createAt)).toList();
      case 1: // 昨日
        return all.where((e) => _isYesterday(e.createAt)).toList();
      case 2: // 累計
      default:
        return all;
    }
  }

  String _fmtFull(int epochSec) {
    if (epochSec <= 0) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(epochSec * 1000, isUtc: true).toLocal();
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }

  String _fullUrl(String base, String p) {
    if (p.isEmpty) return p;
    if (p.startsWith('http')) return p;
    if (base.isEmpty) return p;
    return p.startsWith('/') ? '$base$p' : '$base/$p';
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final tabs = [s.todayLabel, s.yesterdayLabel, s.totalLabel];

    final state = ref.watch(inviteListProvider);
    final cdn   = ref.watch(userProfileProvider)?.cdnUrl ?? '';

    final filtered = _applyFilter(state.items);
    final currentCount = filtered.length; // 頂部顯示當前篩選的數量

    return Column(
      children: [
        // 🔘 篩選切換
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: List.generate(tabs.length, (index) {
              final isSelected = selectedIndex == index;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GestureDetector(
                  onTap: () => setState(() => selectedIndex = index),
                  child: Container(
                    width: 76,
                    height: 30,
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFFFEFEF) : const Color(0xFFFAFAFA),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      tabs[index],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? const Color(0xFFFF4D67) : const Color(0xFF888888),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),

        // 🟣 邀請人數（依過濾後）
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFFEEEF4),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Column(
            children: [
              Text(s.inviteesCountLabel, style: TextStyle(fontSize: 12, color: Color(0xFFB1A3A9))),
              const SizedBox(height: 8),
              Text(
                '$currentCount',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // 📝 列表 + 分頁
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                // 標題列
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(s.userWord, textAlign: TextAlign.start,
                          style: const TextStyle(fontSize: 14, color: Color(0xFF9E9E9E), fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        child: Text(s.registeredAt,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: Color(0xFF9E9E9E), fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SmartRefresher(
                    controller: _rc,
                    enablePullDown: true,
                    enablePullUp: state.hasMore,
                    onRefresh: () async {
                      await ref.read(inviteListProvider.notifier).loadFirstPage();
                      final ns = ref.read(inviteListProvider);
                      _rc.refreshCompleted();
                      // 只有清單真的是 0 筆，才顯示 "No more data"
                      if (ns.items.isEmpty) {
                        _rc.loadNoData();
                      } else {
                        _rc.resetNoData(); // 恢復成可載入狀態（避免殘留 noData 狀態）
                      }
                    },
                    onLoading: () async {
                      await ref.read(inviteListProvider.notifier).loadNextPage();
                      final ns = ref.read(inviteListProvider);

                      if (ns.hasMore) {
                        _rc.loadComplete(); // 還有下一頁 → 正常結束這次 loading
                      } else {
                        // 沒有更多了：只有完全沒有資料才顯示 "No more data"
                        if (ns.items.isEmpty) {
                          _rc.loadNoData();
                        } else {
                          // 列表已有資料，但到尾頁 → 不顯示 "No more data"
                          _rc.loadComplete();
                        }
                      }
                    },
                    header: const ClassicHeader(),
                    footer: const ClassicFooter(),
                    child: _buildList(filtered, state, cdn),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildList(List<InviteUserItem> filtered, InviteListState state, String cdnBase) {
    if (state.isLoading && state.items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 40),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.only(top: 40),
          child: Text(S.of(context).noData, style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (_, index) {
        final it = filtered[index];
        final avatarRel = it.avatar.isNotEmpty ? it.avatar.first : '';
        final avatarUrl = _fullUrl(cdnBase, avatarRel);
        final nick = it.nickName.isNotEmpty ? it.nickName : S.of(context).userWithId(it.inviteUid);
        final when = _fmtFull(it.createAt);

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 15,
                backgroundImage: avatarUrl.isNotEmpty
                    ? NetworkImage(avatarUrl)
                    : const AssetImage('assets/my_icon_defult.jpeg') as ImageProvider,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(nick, style: const TextStyle(fontSize: 14)),
              ),
              Text(
                when,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        );
      },
    );
  }
}

