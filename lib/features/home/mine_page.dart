// # 第三個頁籤內容

import 'dart:io';

import 'package:djs_live_stream/features/mine/liked_users_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../data/models/user_model.dart';
import '../../data/network/avatar_cache.dart';
import '../../l10n/l10n.dart';
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
import '../widgets/tools/image_resolver.dart';

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

    // 進頁即拉一次，拿到結果直接寫回 UserModel
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final w = await ref.refresh(walletBalanceProvider.future);
      ref.read(userProfileProvider.notifier).applyWallet(w);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = S.of(context); // i18n
    final user = ref.watch(userProfileProvider);

    final coinLatest = user?.gold ?? 0;
    final bottomGap = MediaQuery.of(context).padding.bottom + _tabBarHeight + 16;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final avatarPath = sanitizeAvatarUrl(user.avatarUrl, cdnBase: user.cdnUrl);

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
                        CircleAvatar(
                          radius: 32,
                          backgroundImage: buildAvatarProvider(
                            avatarUrl: avatarPath,
                            context: context,
                            logicalSize: 64,
                          ),
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
                                  if (user.isVipEffective == true)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(6),
                                        gradient: const LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [Color(0xFFFFA770), Color(0xFFD247FE)],
                                        ),
                                      ),
                                      child: const Text(
                                        'VIP', // VIP 標籤保留字樣
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  IconButton(
                                    onPressed: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => const EditMinePage()),
                                      );
                                      if (!mounted) return;
                                      final w = await ref.refresh(walletBalanceProvider.future);
                                      ref.read(userProfileProvider.notifier).applyWallet(w);
                                    },
                                    icon: SvgPicture.asset('assets/icon_edit1.svg', width: 24, height: 24),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                                    splashRadius: 22,
                                  )
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                t.idLabel(user.uid ?? t.unknown), // i18n
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
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
                                MaterialPageRoute(builder: (_) => const VipPrivilegePage()),
                              );
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
                                // 內容區塊
                                Positioned.fill(
                                  child: IgnorePointer(
                                    ignoring: false,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 8),
                                          Text(
                                            t.vipPrivilegeTitle, // i18n
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF836810),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  t.vipPrivilegeSubtitle, // i18n
                                                  style: const TextStyle(fontSize: 12, color: Color(0xFFD1B765)),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
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
                                                  user.isVipEffective == true ? t.vipOpened : t.vipOpenNow, // i18n
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
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        // 右側卡片（邀請好友）
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const InviteFriendPage()),
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
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 8),
                                        Text(
                                          t.inviteFriends, // i18n
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFFF4D67),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              t.earnCommission, // i18n
                                              style: const TextStyle(fontSize: 12, color: Color(0xFFFF92A2)),
                                            ),
                                            IgnorePointer(
                                              child: OutlinedButton(
                                                onPressed: () {},
                                                style: OutlinedButton.styleFrom(
                                                  side: const BorderSide(color: Color(0xFFFF4D67), width: 1),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(20),
                                                  ),
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                                  minimumSize: Size.zero,
                                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                  visualDensity: VisualDensity.compact,
                                                ),
                                                child: Text(
                                                  t.inviteNow, // i18n
                                                  style: const TextStyle(fontSize: 12, color: Color(0xFFFF4D67)),
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const MyWalletPage()),
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
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            SvgPicture.asset('assets/icon_mine_wallet.svg', width: 24, height: 24),
                            const SizedBox(width: 8),
                            Text(t.myWallet, style: const TextStyle(fontSize: 16)), // i18n
                            const Spacer(),
                            Text(
                              '$coinLatest ${t.coinsUnit}', // i18n
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                gradient: const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Color(0xFFFFA770), Color(0xFFD247FE)],
                                ),
                              ),
                              child: Text(
                                t.recharge, // i18n
                                style: const TextStyle(
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
    final t = S.of(context); // i18n
    final isBroadcaster = user.isBroadcaster;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          if (isBroadcaster) ...[
            _buildFunctionCard([
              _buildMenuItem('assets/icon_mine_ticket.svg', t.priceSetting, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PriceSettingPage()),
                );
              }),
              // 若未使用就先保留註解
              // _buildMenuItem('assets/icon_mine_beauty.svg', t.beautySetting, () { ... });
            ]),
            const SizedBox(height: 12),
            _buildFunctionCard([
              _buildMenuItem('assets/icon_mine_people.svg', t.whoLikesMe, () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WhoLikesMePage()),
                );
              }),
              _buildMenuItem('assets/icon_mine_like.svg', t.iLiked, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LikedUsersPage()),
                );
              }),
              _buildMenuItem('assets/icon_mine_filter.svg', t.accountManage, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AccountManagePage()),
                );
              }),
              _buildMenuItem('assets/icon_mine_logout.svg', t.logout, () {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const LogoutConfirmDialog(),
                );
              }),
            ]),
          ] else
            _buildFunctionCard([
              // 若未使用就先保留註解
              // _buildMenuItem('assets/icon_mine_beauty.svg', t.beautySetting, () { ... });
              _buildMenuItem('assets/icon_mine_people.svg', t.whoLikesMe, () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WhoLikesMePage()),
                );
                if (result == true) {
                  setState(() {});
                }
              }),
              _buildMenuItem('assets/icon_mine_like.svg', t.iLiked, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LikedUsersPage()),
                );
              }),
              _buildMenuItem('assets/icon_mine_filter.svg', t.accountManage, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AccountManagePage()),
                );
              }),
              _buildMenuItem('assets/notify_mode.svg', t.dndMode, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DndModePage()),
                );
              }),
              _buildMenuItem('assets/icon_mine_logout.svg', t.logout, () {
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
      leading: SvgPicture.asset(icon, fit: BoxFit.fitWidth),
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
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      final w = await ref.refresh(walletBalanceProvider.future);
      ref.read(userProfileProvider.notifier).applyWallet(w);
    }
  }
}
