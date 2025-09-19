import 'package:djs_live_stream/features/mine/user_repository_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../profile/profile_controller.dart';
import '../wallet/payment_method_page.dart';
import '../wallet/wallet_repository.dart';
import 'model/vip_plan.dart';

class VipPrivilegePage extends ConsumerStatefulWidget {
  const VipPrivilegePage({super.key});

  @override
  ConsumerState<VipPrivilegePage> createState() => _VipPrivilegePageState();
}

class _VipPrivilegePageState extends ConsumerState<VipPrivilegePage> {
  int selectedIndex = 0; // 由 API 回來後再決定預設
  List<VipPlan> _plans = const [];
  bool _loading = true;
  String? _error;
  int _bestIndex = 0; // 標示「最佳選擇」
  bool _buying = false;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(userRepositoryProvider);
      final plans = await repo.fetchVipPlans();

      // 預設選擇：優先 3 個月，其次「每月單價最低」
      int defaultIdx = plans.indexWhere((p) => p.month == 3);
      if (defaultIdx < 0) {
        double best = double.infinity;
        for (var i = 0; i < plans.length; i++) {
          final pm = plans[i].perMonth;
          if (pm < best) {
            best = pm;
            defaultIdx = i;
          }
        }
        if (defaultIdx < 0) defaultIdx = 0;
      }

      // 「最佳選擇」：每月單價最低（跟上面的 default 可以一致）
      int bestIdx = 0;
      double bestPer = plans.first.perMonth;
      for (var i = 1; i < plans.length; i++) {
        if (plans[i].perMonth < bestPer) {
          bestPer = plans[i].perMonth;
          bestIdx = i;
        }
      }

      setState(() {
        _plans = plans;
        selectedIndex = defaultIdx;
        _bestIndex = bestIdx;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  String _fmtMoney(double v) => '\$ ${v.toStringAsFixed(2)}';

  String _fmtPerMonth(VipPlan p) => '${_fmtMoney(p.perMonth)} / 月';

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProfileProvider);
    final vipActive = user?.isVipEffective == true;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('VIP特权',
            style: TextStyle(fontSize: 16, color: Colors.black)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('載入失敗：$_error'),
                      const SizedBox(height: 12),
                      OutlinedButton(
                          onPressed: _loadPlans, child: const Text('重試')),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 70),

                      // 🟣 會員特權區塊（不變）
                      Container(
                        width: double.infinity,
                        height: 235,
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 0),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          image: const DecorationImage(
                            image: AssetImage('assets/bg_vip.png'),
                            fit: BoxFit.fitWidth,
                          ),
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 10, top: 40),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('會員特權',
                                  style: TextStyle(
                                      fontSize: 28, color: Color(0xFF35012B))),
                              const SizedBox(height: 16),
                              const Text('解鎖特權，享頂級體驗',
                                  style: TextStyle(
                                      fontSize: 14, color: Color(0xFF35012B))),
                              const Spacer(),
                              Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(24),
                                    child: Image(
                                      image: user?.avatarImage ??
                                          const AssetImage(
                                              'assets/my_icon_defult.jpeg'),
                                      width: 30,
                                      height: 30,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(user?.displayName ?? '',
                                      style: const TextStyle(
                                          fontSize: 14, color: Colors.black)),
                                  const Spacer(),
                                  (user?.isVipEffective ?? false)
                                      ? Text(
                                          _fmtExpire(user?.vipExpireAt),
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF9E9E9E)),
                                        )
                                      : Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: const Text(
                                            '暫未開通',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.pinkAccent),
                                          ),
                                        ),
                                  const SizedBox(width: 10),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 🟣 方案卡片（可橫向捲動；每個 item 最小間距 10）
                      if (!vipActive) ...[
                        SizedBox(
                          height: 146, // 卡片120 + 上方徽標空間6 + 一點餘裕
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: _plans.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 10),
                            // 最小水平間隔 10
                            itemBuilder: (context, index) {
                              final p = _plans[index];
                              final selected = selectedIndex == index;

                              return GestureDetector(
                                onTap: () =>
                                    setState(() => selectedIndex = index),
                                child: SizedBox(
                                  width: 115,
                                  child: Stack(
                                    children: [
                                      // 把卡片整體往下 6px，留出徽標空間
                                      Positioned(
                                        top: 6,
                                        left: 0,
                                        right: 0,
                                        child: Container(
                                          height: 120,
                                          padding: const EdgeInsets.fromLTRB(
                                              12, 6, 12, 6),
                                          decoration: BoxDecoration(
                                            color: selected
                                                ? const Color(0xFFFFF5F5)
                                                : Colors.white,
                                            border: Border.all(
                                              color: selected
                                                  ? Colors.red
                                                  : const Color(0xFFE0E0E0),
                                              width: selected ? 2 : 1,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(16),
                                          ),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(p.title,
                                                  style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold)),
                                              const SizedBox(height: 4),
                                              Text(_fmtMoney(p.payPrice),
                                                  style: const TextStyle(
                                                      fontSize: 16,
                                                      color: Colors.black)),
                                              const SizedBox(height: 4),
                                              Text('原价 ${_fmtMoney(p.price)}',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey,
                                                    decoration: TextDecoration
                                                        .lineThrough,
                                                  )),
                                              const SizedBox(height: 4),
                                              Text(_fmtPerMonth(p),
                                                  style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey)),
                                            ],
                                          ),
                                        ),
                                      ),

                                      // 徽標放在 top: 0（不再使用負位移）
                                      if (index == _bestIndex)
                                        Positioned(
                                          top: 0,
                                          left: 0,
                                          child: Container(
                                            width: 60,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 2),
                                            decoration: const BoxDecoration(
                                              color: Color(0xFFFF4D67),
                                              borderRadius: BorderRadius.only(
                                                topRight: Radius.circular(8),
                                                topLeft: Radius.circular(8),
                                                bottomRight: Radius.circular(8),
                                              ),
                                            ),
                                            child: const Text(
                                              '最佳选择',
                                              style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.white),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      // 🟣 專屬特權清單（不變）
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '专属特权',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 6),
                            ...[
                              {
                                'icon': 'assets/icon_vip_privilege1.svg',
                                'title': 'VIP尊享标识',
                                'desc': '点亮特权，让你成为与众不同的那颗心',
                              },
                              {
                                'icon': 'assets/icon_vip_privilege2.svg',
                                'title': '访问记录全解锁',
                                'desc': '不错过每个喜欢你的人',
                              },
                              {
                                'icon': 'assets/icon_vip_privilege3.svg',
                                'title': '无限制连线',
                                'desc': '无限连线，给你更多可能',
                              },
                              {
                                'icon': 'assets/icon_vip_privilege4.svg',
                                'title': '畅想直接私聊',
                                'desc': '免费无线私聊，随时发起',
                              },
                              {
                                'icon': 'assets/icon_vip_privilege5.svg',
                                'title': '高级美颜',
                                'desc': '特效更多，妆造更美丽帅气',
                              },
                            ].map((item) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      padding: const EdgeInsets.all(8),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFFFEFEF),
                                        shape: BoxShape.circle,
                                      ),
                                      child: SvgPicture.asset(item['icon']!,
                                          width: 20, height: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item['title']!,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            item['desc']!,
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.black54),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 🟣 購買按鈕（用動態方案）
                      if (!vipActive && _plans.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _buying
                                  ? null
                                  : () async {
                                      final sel = _plans[selectedIndex];

                                      setState(() => _buying = true);
                                      try {
                                        await ref
                                            .read(userRepositoryProvider)
                                            .buyVip(id: sel.id);

                                        Fluttertoast.showToast(msg: '開通成功');

                                        // 刷新使用者/錢包，更新 vip 到期時間
                                        final walletRepo =
                                        ref.read(walletRepositoryProvider);
                                        final w =
                                        await walletRepo.fetchMoneyCash(); // ({gold, vipExpire, inviteNum, totalIncome, cashAmount})

                                        final user = ref.read(userProfileProvider);
                                        if (user != null) { ref.read(userProfileProvider.notifier).state = user.copyWith(
                                            isVip: true,
                                            vipExpire: w.vipExpire,
                                            gold: w.gold,
                                          );
                                        }
                                        setState(() {}); // 讓畫面上的「暫未開通」等依綁定狀態刷新
                                      } catch (e) {
                                        Fluttertoast.showToast(msg: '開通失敗：$e');
                                      } finally {
                                        if (mounted)
                                          setState(() => _buying = false);
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30)),
                                padding: EdgeInsets.zero,
                                backgroundColor: Colors.transparent,
                              ),
                              child: Ink(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFFFA06E),
                                      Color(0xFFDC5EF9)
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Container(
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${_fmtMoney(_plans[selectedIndex].payPrice).replaceAll("\$ ", "")} 美元 / ${_plans[selectedIndex].title} 开通身份',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 10),
                    ],
                  ),
                ),
    );
  }

  // 放在 _State 裡（工具函式）
  String _fmtExpire(DateTime? dt) {
    if (dt == null) return '';
    // 簡單格式化：yyyy-MM-dd HH:mm:ss
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    final ss = dt.second.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm:$ss 到期';
  }
}
