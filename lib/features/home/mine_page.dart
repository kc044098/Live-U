// # 第三個頁籤內容

import 'dart:io';

import 'package:djs_live_stream/features/mine/liked_users_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../data/models/user_model.dart';
import '../../data/network/avatar_cache.dart';
import '../mine/account_manage_page.dart';
import '../mine/dnd_mode_page.dart';
import '../mine/invite_friend_page.dart';
import '../mine/price_setting_page.dart';
import '../mine/vip_privilege_page.dart';
import '../mine/who_likes_me_page.dart';
import '../mine/logout_confirm_dialog.dart';
import '../profile/profile_controller.dart';
import '../mine/edit_mine_page.dart';
import '../wallet/my_wallet_page.dart';
import '../wallet/wallet_repository.dart';

class MinePage extends ConsumerStatefulWidget {
  const MinePage({super.key});

  @override
  ConsumerState<MinePage> createState() => _MinePageState();
}

class _MinePageState extends ConsumerState<MinePage> with WidgetsBindingObserver {
  static const double _tabBarHeight = 64.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(walletBalanceProvider);
      ref.refresh(walletBalanceProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProfileProvider);
    final wallet = ref.watch(walletBalanceProvider);
    final coinLatest = wallet.maybeWhen(
      data: (w) => w.gold,
      orElse: () => user?.gold ?? 0,
    );
    final bottomGap = MediaQuery.of(context).padding.bottom + _tabBarHeight + 16;

    ref.listen<
        AsyncValue<({int gold, int? vipExpire, int inviteNum, int totalIncome, int cashAmount})>
    >(
      walletBalanceProvider,
          (prev, next) {
        next.whenData((w) {
          final u = ref.read(userProfileProvider);
          if (u != null && (u.gold != w.gold || u.vipExpire != w.vipExpire)) {
            ref.read(userProfileProvider.notifier).state =
                u.copyWith(gold: w.gold, vipExpire: w.vipExpire);
          }
        });
      },
    );

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          SizedBox(
            width: double.infinity,
            height: 250,
            child: SvgPicture.asset(
              'assets/bg_mine_page.svg',
              fit: BoxFit.fitWidth,
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(bottom: bottomGap),
              child: Column(
                children: [
                  // Header: 頭像 + 暱稱 + VIP + ID
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 40, 20, 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Avatar
                        GestureDetector(
                          onTap: () async {},
                          child: CircleAvatar(
                            radius: 32,
                            backgroundImage: buildAvatarProvider(
                              avatarUrl: user.avatarUrlAbs,
                              context: context,
                              logicalSize: 64,
                            ),
                          )
                        ),
                        const SizedBox(width: 16),
                        // 名稱 + VIP 標籤 + ID
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    user.displayName ?? '',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(width: 6),

                                  // ✅ 僅當 user 是 VIP 才顯示 VIP 標籤
                                  if (user.isVip == true)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(6),
                                        gradient: const LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Color(0xFFFFA770),
                                            Color(0xFFD247FE)
                                          ],
                                        ),
                                      ),
                                      child: const Text(
                                        'VIP',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),

                                  const SizedBox(width: 4),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const EditMinePage(),
                                        ),
                                      );
                                      if (!mounted) return;
                                      ref.invalidate(walletBalanceProvider);
                                      ref.refresh(walletBalanceProvider);
                                    },
                                    child: SvgPicture.asset(
                                      'assets/icon_edit1.svg',
                                      width: 24,
                                      height: 24,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text('ID:    ${user.uid ?? '未知'}',
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // VIP 特權卡 + 邀請好友卡
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const VipPrivilegePage(),
                                  ));
                            },
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: SvgPicture.asset(
                                    'assets/mine_pic_1.svg',
                                    width: double.infinity,
                                    height: 94,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                // 內容區塊
                                Positioned.fill(
                                  child: IgnorePointer(
                                    ignoring: false, // 允許內部按鈕點擊
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 8),
                                          const Text('VIP特权',
                                              style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF836810))),
                                          const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '开通专属特权',
                                              style: const TextStyle(fontSize: 12, color: Color(0xFFD1B765)),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis, // 超出以…顯示
                                              softWrap: false,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          OutlinedButton(
                                            onPressed: () async {
                                              await Navigator.push(
                                                context,
                                                MaterialPageRoute(builder: (_) => const VipPrivilegePage()),
                                              );
                                              setState(() {});
                                            },
                                            style: OutlinedButton.styleFrom(
                                              side: const BorderSide(color: Color(0xFF836810), width: 1),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                              minimumSize: Size.zero,
                                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              visualDensity: VisualDensity.compact,
                                            ),
                                            child: Text(
                                              user.isVip == true ? '已开通' : '立即开通',
                                              style: const TextStyle(fontSize: 12, color: Color(0xFF836810)),
                                            ),
                                          ),
                                        ],
                                      ),
                                      ],
                                      ),
                                    ),
                                  ),
                                ),
                                // 裝飾圖（右上）
                                Positioned(
                                  top: -10,
                                  right: -4,
                                  child: Image.asset(
                                    'assets/mine_vip_pic.png',
                                    width: 85,
                                    height: 54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        // 右側卡片（未變動）
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const InviteFriendPage()),
                              );
                            },
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: SvgPicture.asset(
                                    'assets/mine_pic_2.svg',
                                    width: double.infinity,
                                    height: 94,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned.fill(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 8),
                                        const Text(
                                          '邀请好友',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFFF4D67),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              '赚取永久佣金',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFFFF92A2),
                                              ),
                                            ),
                                            IgnorePointer(
                                              child: OutlinedButton(
                                                onPressed: () {},
                                                style: OutlinedButton.styleFrom(
                                                  side: const BorderSide(
                                                      color: Color(0xFFFF4D67),
                                                      width: 1),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20),
                                                  ),
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 10,
                                                      vertical: 12),
                                                  minimumSize: Size.zero,
                                                  tapTargetSize:
                                                      MaterialTapTargetSize
                                                          .shrinkWrap,
                                                  visualDensity:
                                                      VisualDensity.compact,
                                                ),
                                                child: const Text(
                                                  '立即邀请',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Color(0xFFFF4D67),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 我的錢包
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 20),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const MyWalletPage()),
                        );
                        if (!mounted) return;
                        ref.invalidate(walletBalanceProvider);
                        ref.refresh(walletBalanceProvider);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05), // 非常淡的陰影
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            SvgPicture.asset(
                              'assets/icon_mine_wallet.svg',
                              width: 24,
                              height: 24,
                            ),
                            const SizedBox(width: 8),
                            const Text('我的钱包', style: TextStyle(fontSize: 16)),
                            const Spacer(),
                            Text('$coinLatest 金币', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                gradient: const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0xFFFFA770),
                                    Color(0xFFD247FE)
                                  ],
                                ),
                              ),
                              child: const Text(
                                '充值',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // 功能列表
                  _buildFunctionList(context, user),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFunctionList(BuildContext context, UserModel user) {
    final isBroadcaster = user.isBroadcaster; // 主播判斷

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          if (isBroadcaster) ...[
            // 主播的兩段列表
            _buildFunctionCard([
              _buildMenuItem('assets/icon_mine_ticket.svg', '价格设置', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PriceSettingPage(),
                  ),
                );
              }),
              /*
              _buildMenuItem('assets/icon_mine_beauty.svg', '美颜设置', () {
                Fluttertoast.showToast(msg: "尚未實現美顏功能");
              }),*/
            ]),
            const SizedBox(height: 12),
            _buildFunctionCard([
              _buildMenuItem('assets/icon_mine_people.svg', '谁喜欢我', () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const WhoLikesMePage(),
                  ),
                );
              }),
              _buildMenuItem('assets/icon_mine_like.svg', '我喜欢的', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LikedUsersPage(),
                  ),
                );
              }),
              _buildMenuItem('assets/icon_mine_filter.svg', '账号管理', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AccountManagePage(),
                  ),
                );
              }),
              _buildMenuItem('assets/icon_mine_logout.svg', '退出登陆', () {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const LogoutConfirmDialog(),
                );
              }),
            ]),
          ] else
            // 普通用戶列表
            _buildFunctionCard([
              /*
              _buildMenuItem('assets/icon_mine_beauty.svg', '美颜设置', () {
                Fluttertoast.showToast(msg: "尚未實現美顏功能");
              }),*/
              _buildMenuItem('assets/icon_mine_people.svg', '谁喜欢我', () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const WhoLikesMePage(),
                  ),
                );
                if (result == true) {
                  setState(() {});
                }
              }),
              _buildMenuItem('assets/icon_mine_like.svg', '我喜欢的', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LikedUsersPage(),
                  ),
                );
              }),
              _buildMenuItem('assets/icon_mine_filter.svg', '账号管理', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AccountManagePage(),
                  ),
                );
              }),
              _buildMenuItem('assets/notify_mode.svg', '勿扰模式', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DndModePage(),
                  ),
                );
              }),
              _buildMenuItem('assets/icon_mine_logout.svg', '退出登陆', () {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const LogoutConfirmDialog(),
                );
              }),
            ]),
        ],
      ),
    );
  }

  Widget _buildFunctionCard(List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: List.generate(
          items.length * 2 - 1,
          (index) => index.isEven
              ? items[index ~/ 2]
              : const Divider(
                  height: 1,
                  indent: 20,
                  endIndent: 20,
                  color: Color(0xFFD8D8D8),
                ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(String icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: SvgPicture.asset(
        icon,
        fit: BoxFit.fitWidth,
      ),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right, color: Colors.black26),
      onTap: onTap,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // 回到前景時再取一次最新餘額
      ref.invalidate(walletBalanceProvider);
      ref.refresh(walletBalanceProvider);
    }
  }

}
