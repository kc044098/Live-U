// 喜歡我的 頁面

import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:djs_live_stream/features/mine/user_repository_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

import '../../data/network/background_api_service.dart';
import '../../l10n/l10n.dart';
import '../call/call_request_page.dart';
import '../profile/profile_controller.dart';
import '../profile/view_profile_page.dart';
import '../wallet/payment_method_page.dart';
import 'member_fans_provider.dart';
import 'model/fan_user.dart';
import 'model/vip_plan.dart';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WhoLikesMePage extends ConsumerStatefulWidget {
  const WhoLikesMePage({super.key});

  @override
  ConsumerState<WhoLikesMePage> createState() => _WhoLikesMePageState();
}

class _WhoLikesMePageState extends ConsumerState<WhoLikesMePage> {
  final _scroll = ScrollController();

  // VIP 方案區
  List<VipPlan> _plans = const [];
  int _selectedPlanIndex = 1;
  int _bestIndex = 0;
  bool _plansLoading = false;
  String? _plansError;

  @override
  void initState() {
    super.initState();

    // 進頁面抓第一頁粉絲
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(memberFansProvider.notifier).loadFirstPage();
    });

    // 無限滾動載入下一頁
    _scroll.addListener(() {
      if (!_scroll.hasClients) return;
      final pos = _scroll.position;
      if (pos.pixels >= pos.maxScrollExtent - 300) {
        ref.read(memberFansProvider.notifier).loadNextPage();
      }
    });
  }

  Future<void> _loadPlansIfNeeded() async {
    // 僅當遮罩會顯示（非 VIP 且非主播）才需要抓方案，避免多餘的 API
    final u = ref.read(userProfileProvider);
    final shouldBlock = (u != null) && !(u.isVipEffective || u.isBroadcaster);
    if (!shouldBlock) return;
    if (_plansLoading || _plans.isNotEmpty) return;

    setState(() {
      _plansLoading = true;
      _plansError = null;
    });

    try {
      final repo = ref.read(userRepositoryProvider);
      final plans = await repo.fetchVipPlans();

      // 「最佳選擇」：每月單價最低
      int bestIdx = 0;
      if (plans.isNotEmpty) {
        double bestPer = plans.first.perMonth;
        for (var i = 1; i < plans.length; i++) {
          if (plans[i].perMonth < bestPer) {
            bestPer = plans[i].perMonth;
            bestIdx = i;
          }
        }
      }

      // 預設選第二個；不足兩個就選第 0 個
      final defaultIdx = (plans.length >= 2) ? 1 : (plans.isNotEmpty ? 0 : 0);

      setState(() {
        _plans = plans;
        _bestIndex = bestIdx;
        _selectedPlanIndex = defaultIdx;
        _plansLoading = false;
      });
    } catch (e) {
      setState(() {
        _plansError = '$e';
        _plansLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = S.of(context); // ← 新增
    final fans = ref.watch(memberFansProvider);
    final me = ref.watch(userProfileProvider);
    final cdn = me?.cdnUrl ?? '';
    final showBlockLayer =
        (me != null) && !(me.isVipEffective || me.isBroadcaster);

    if (showBlockLayer && !_plansLoading && _plans.isEmpty) {
      Future.microtask(_loadPlansIfNeeded);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(t.whoLikesMeTitle,
            style: const TextStyle(color: Colors.black, fontSize: 16)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: Stack(
        children: [
          // Grid（任何身份都先渲染；被遮罩蓋住與否，交給 showBlockLayer 控制）
          GridView.builder(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 60),
            itemCount: fans.items.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 16,
              childAspectRatio: 0.66,
            ),
            itemBuilder: (context, index) {
              final u = fans.items[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      // 用後端回來的 id 導到個資頁
                      builder: (_) => ViewProfilePage(userId: u.id),
                    ),
                  );
                },
                child: _buildLikedCardFromApi(u, cdn),
              );
            },
          ),

          // 只有非 VIP 且非主播才顯示購買 VIP 的遮罩
          if (showBlockLayer) _buildOverlayLayer(t),
        ],
      ),
    );
  }

  Widget _buildLikedCardFromApi(MemberFanUser user, String cdnBase) {
    // 封面：相對路徑才拼 CDN，取第一張非空
    final coverRaw =
        user.avatars.firstWhere((e) => e.isNotEmpty, orElse: () => '');
    final coverUrl = joinCdnIfNeeded(coverRaw, cdnBase);

    final image = (coverUrl.isNotEmpty && coverUrl.startsWith('http'))
        ? CachedNetworkImage(imageUrl: coverUrl, fit: BoxFit.cover)
        : Image.asset('assets/pic_girl1.png', fit: BoxFit.cover); // fallback

    return AspectRatio(
      aspectRatio: 3 / 4,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // 背景大圖
            Positioned.fill(child: image),

            // 底部漸層 + 名字 + 通話圖示
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black54, Colors.transparent],
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        user.name.isNotEmpty
                            ? user.name
                            : S.of(context).userFallback,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          shadows: [
                            Shadow(blurRadius: 2, color: Colors.black45)
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => _handleCallRequest(context, user, cdnBase),
                      child: SvgPicture.asset(
                        'assets/logo_placeholder.svg',
                        height: 28,
                        width: 28,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleCallRequest(
      BuildContext context, MemberFanUser user, String cdnBase) {
    final broadcasterId = user.id.toString();
    final broadcasterName = user.name;
    final firstAvatar =
        user.avatars.firstWhere((e) => e.isNotEmpty, orElse: () => '');
    final broadcasterImage = firstAvatar.isNotEmpty
        ? joinCdnIfNeeded(firstAvatar, cdnBase)
        : 'assets/my_icon_defult.jpeg';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CallRequestPage(
          broadcasterId: broadcasterId,
          broadcasterName: broadcasterName,
          broadcasterImage: broadcasterImage,
        ),
      ),
    );
  }

  Widget _buildOverlayLayer(S t) {
    return Stack(
      children: [
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(color: Colors.black.withOpacity(0.6)),
        ),
        Align(
          alignment: Alignment.center,
          child: Container(
            margin: const EdgeInsets.all(32),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFC3C3), Color(0xFFFFEFEF)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 12,
                    offset: Offset(0, 6))
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(t.whoLikesMeTitle,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)), // ← 改
                const SizedBox(height: 16),
                Text(
                  t.whoLikesMeSubtitle, // ← 改
                  textAlign: TextAlign.center,
                  style:
                      const TextStyle(fontSize: 14, color: Color(0xfffb5d5d)),
                ),
                const SizedBox(height: 20),

                _plansSection(t), // ← 傳入 t

                const SizedBox(height: 20),
                SizedBox(
                  width: 180,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                    onPressed: (_plansLoading || _plans.isEmpty)
                        ? null
                        : () async {
                            final amt = _plans[_selectedPlanIndex].payPrice;
                            await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        PaymentMethodPage(amount: amt)));
                            Navigator.pop(context, true);
                          },
                    child: Text(
                      _plansLoading || _plans.isEmpty
                          ? t.loadingEllipsis // ← 改
                          : t.buyVipWithPrice(
                              _fmtMoney(_plans[_selectedPlanIndex].payPrice)),
                      // ← 改
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _fmtMoney(double v) => '\$ ${v.toStringAsFixed(2)}';

  Widget _plansSection(S t) {
    if (_plansLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_plansError != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(t.planLoadFailed,
              style: const TextStyle(fontSize: 13, color: Colors.white)),
          // ← 改
          const SizedBox(height: 8),
          OutlinedButton(onPressed: _loadPlansIfNeeded, child: Text(t.retry)),
          // ← 改
        ],
      );
    }
    if (_plans.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(t.noAvailablePlans,
            style: const TextStyle(fontSize: 13, color: Colors.white)), // ← 改
      );
    }
    return _plansGrid(t); // ← 傳入 t
  }

  Widget _plansGrid(S t) {
    return LayoutBuilder(
      builder: (context, cons) {
        const cols = 3;
        const crossSpacing = 12.0;
        final ts = MediaQuery.textScaleFactorOf(context).clamp(1.0, 1.6);

        // 估算卡片高度，避免文字溢出
        final baseTextH = (14 * 1.25 + 16 * 1.25 + 12 * 1.25 + 12 * 1.25);
        const vPadding = 6.0 * 2;
        const vSpacing = 2.0 * 3;
        final extra = 10.0;
        final tileH = (baseTextH * ts) + vPadding + vSpacing + extra;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _plans.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: tileH + 8,
          ),
          itemBuilder: (context, index) {
            final p = _plans[index];
            final selected = _selectedPlanIndex == index;

            return GestureDetector(
              onTap: () => setState(() => _selectedPlanIndex = index),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selected ? Colors.pink : const Color(0xFFE0E0E0),
                        width: selected ? 2 : 1,
                      ),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: Colors.pink.withOpacity(0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              )
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(p.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.red)),
                        const SizedBox(height: 2),
                        Text(_fmtMoney(p.payPrice),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(t.vipOriginalPrice(_fmtMoney(p.price)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              decoration: TextDecoration.lineThrough,
                            )),
                        const SizedBox(height: 2),
                        Text(t.vipPerMonth(_fmtMoney(p.perMonth)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  if (index == _bestIndex)
                    Positioned(
                      top: -8,
                      left: 0,
                      child: Container(
                        width: 60,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 2, vertical: 2),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF4D67),
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(8),
                            topLeft: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                          ),
                        ),
                        child: Text(t.vipBestChoice,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 10, color: Colors.white)),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
