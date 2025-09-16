import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart' hide RefreshIndicator;

import '../../data/models/gift_item.dart';
import '../../data/models/user_model.dart';
import '../call/call_request_page.dart';
import '../live/gift_providers.dart';
import '../message/chat_providers.dart';
import '../message/chat_repository.dart';
import '../message/chat_thread_item.dart';
import '../message/data_model/call_record_item.dart';
import '../message/emoji/emoji_pack.dart';
import '../message/emoji/emoji_text.dart';
import '../message/message_chat_page.dart';
import '../mine/member_fans_provider.dart';
import '../mine/show_like_alert_dialog.dart';
import '../mine/who_likes_me_page.dart';
import '../profile/profile_controller.dart';
import '../wallet/payment_method_page.dart';

class MessagePage extends ConsumerStatefulWidget {
  const MessagePage({super.key});

  @override
  ConsumerState<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends ConsumerState<MessagePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  late Future<EmojiPack> _emojiPackFut;

  List<ChatThreadItem> _threads = [];
  bool _loading = true;
  String? _error;
  int _page = 1;

  final RefreshController _callRc = RefreshController(initialRefresh: false);
  List<CallRecordItem> _callItems = [];
  bool _callLoading = false;
  bool _callHasMore = true;
  int _callPage = 1;
  int? _callToUidFilter;

  final List<Tab> _tabs = const [
    Tab(text: '消息'),
    Tab(text: '通話'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _emojiPackFut = EmojiPack.loadFromFolder('assets/emojis/basic/');

    // ✅ 首次載入「誰喜歡我」資料（非 VIP 才抓）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadThreads(page: 1);
      ref.read(memberFansProvider.notifier).loadFirstPage();
    });

    _loadCallPage(page: 1, reset: true);
  }

  Future<void> _loadThreads({int page = 1}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(chatRepositoryProvider);
      final res = await repo.fetchUserMessageList(page: page);
      if (!mounted) return;
      setState(() {
        _threads = res.items;
        _page = page;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (_isNetworkIssue(e)) {
        _toastNetworkError();
        setState(() {
          _loading = false; // ❗ 不設 _error → 不顯示錯誤畫面，保留原清單
        });
      } else {
        setState(() {
          _error = '$e';    // 非網路型錯誤才顯示錯誤畫面
          _loading = false;
        });
      }
    }
  }

  Future<void> _onRefresh() => _loadThreads(page: 1);

  int get _totalUnread => _threads.fold(0, (s, it) => s + (it.unread));

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProfileProvider);
    return Column(
      children: [
        const SizedBox(height: 40),
        TabBar(
          controller: _tabController,
          isScrollable: true,
          labelPadding: const EdgeInsets.symmetric(horizontal: 16),
          tabAlignment: TabAlignment.start,
          tabs: _tabs,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.normal,
          ),
          indicatorColor: Colors.transparent,
          dividerColor: Colors.transparent,
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildMessageContent( user),
              _buildCallContent(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageContent(UserModel? user) {
    final me = user!;

    // 讀誰喜歡我
    final fans = ref.watch(memberFansProvider);
    final int likeCount = fans.totalCount;
    final String? lastName = (fans.items.isNotEmpty) ? fans.items.last.name : null;

    // 讀取禮物列表（若還在載入就給空陣列）
    final gifts = ref.watch(giftListProvider).maybeWhen(
      data: (v) => v,
      orElse: () => const <GiftItemModel>[],
    );

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('載入失敗：$_error'),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: () => _loadThreads(page: 1), child: const Text('重試')),
          ],
        ),
      );
    }

    const hasLikeCard = true; // 所有人都顯示
    final totalRows = _threads.length + 1;

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _onRefresh,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 120),
            itemCount: totalRows,
            itemBuilder: (context, index) {
              // 0: 誰喜歡我
              if (hasLikeCard && index == 0) {
                final titleText = '誰喜歡我：有${likeCount > 0 ? likeCount : 0}個人新喜歡';
                final subtitleText = (likeCount > 0 && (lastName != null && lastName.isNotEmpty))
                    ? '[$lastName]  剛喜歡你'
                    : '暫無新喜歡';

                return Column(
                  children: [
                    ListTile(
                      leading: SvgPicture.asset('assets/message_like_1.svg', width: 48, height: 48),
                      title: Text(titleText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      subtitle: Text(subtitleText, style: const TextStyle(color: Colors.grey)),
                      onTap: () async {
                        if (me.isVip == true) {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const WhoLikesMePage()),
                          );
                          ref.read(memberFansProvider.notifier).loadFirstPage();
                        } else {
                          showLikeAlertDialog(
                            context,
                            ref,
                                () {},
                            onConfirmWithAmount: (amount) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => PaymentMethodPage(amount: amount)),
                              );
                            },
                          );
                        }
                      },
                    ),
                    const Divider(indent: 20, endIndent: 20),
                  ],
                );
              }

              // 其餘：API 會話列表
              final tIndex = hasLikeCard ? index - 1 : index;
              final it = _threads[tIndex];

              return Column(
                children: [
                  ListTile(
                    leading: Stack(
                      children: [
                        CircleAvatar(radius: 24, backgroundImage: _avatarOf(me.cdnUrl!, it)),
                        Positioned(
                          bottom: 2, right: 2,
                          child: Container(
                            width: 12, height: 12,
                            decoration: BoxDecoration(
                              color: _getStatusColor(it.status),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    title: Text(
                      _partnerName(it, me),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: _threadSubtitle(it, me, gifts),   // ★ 傳入 gifts
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatRelative(it.updateAt),
                          textAlign: TextAlign.right,
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        if (it.unread > 0)
                          Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: Container(
                              width: 20,
                              height: 20,
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: const BoxDecoration(
                                color: Colors.pink,
                                shape: BoxShape.circle,
                              ),
                              child: Text('${it.unread}',
                                  style: const TextStyle(color: Colors.white, fontSize: 12)),
                            ),
                          ),
                      ],
                    ),
                    onTap: () {
                      final partnerUid = _partnerUid(it, me);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MessageChatPage(
                            partnerName: _partnerName(it, me),
                            partnerAvatar: it.avatars.isNotEmpty
                                ? '${me.cdnUrl}${it.avatars.first}'
                                : 'assets/my_icon_defult.jpeg',
                            vipLevel: it.vip,
                            statusText: it.status,
                            partnerUid: partnerUid,
                          ),
                        ),
                      );
                    },
                  ),
                  const Divider(indent: 20, endIndent: 20),
                ],
              );
            },
          ),
        ),

        // 底部統計
        Positioned(
          left: 16, right: 16, bottom: 96,
          child: Row(
            children: [
              const Expanded(child: Divider(color: Colors.grey, thickness: 0.5, endIndent: 8)),
              Text('共${_totalUnread}條消息未讀', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const Expanded(child: Divider(color: Colors.grey, thickness: 0.5, indent: 8)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCallContent() {
    final me = ref.watch(userProfileProvider);
    final cdn = me?.cdnUrl ?? '';

    if (_callItems.isEmpty && _callLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SmartRefresher(
      controller: _callRc,
      enablePullDown: true,
      enablePullUp: true,
      onRefresh: _refreshCalls,
      onLoading: _loadMoreCalls,
      header: const ClassicHeader(),
      footer: const ClassicFooter(),
      child: ListView.separated(
        itemCount: _callItems.length,
        separatorBuilder: (_, __) => const Divider(indent: 20, endIndent: 20),
        itemBuilder: (context, index) {
          final it = _callItems[index];
          final avatar = (it.avatars.isNotEmpty ? it.avatars.first : '');
          final url = avatar.startsWith('http') ? avatar : (cdn.isNotEmpty ? '$cdn$avatar' : avatar);
          final title = (it.nickname.isNotEmpty) ? it.nickname : '用戶 ${it.uid}';
          final statusText = _callStatusText(it);
          final isMissed = statusText.contains('未接') || statusText.contains('取消');

          return ListTile(
            leading: CircleAvatar(radius: 24, backgroundImage: url.isNotEmpty
                ? NetworkImage(url)
                : const AssetImage('assets/my_icon_defult.jpeg') as ImageProvider),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              statusText,
              style: TextStyle(color: isMissed ? Colors.red : Colors.black54),
            ),
            trailing: SvgPicture.asset(
              it.flag == 2 ? 'assets/message_call_1.svg' : 'assets/message_call_2.svg',
              width: 32, height: 32,
            ),
            onTap: () {
              // 可選：再次撥打
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CallRequestPage(
                    broadcasterId: '${it.uid}',
                    broadcasterName: title,
                    broadcasterImage: url.isNotEmpty ? url : 'assets/my_icon_defult.jpeg',
                    isVideoCall: it.flag == 1,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _callStatusText(CallRecordItem it) {
    final d = (it.endAt > it.startAt) ? (it.endAt - it.startAt) : 0;
    if (d > 0) {
      final dur = Duration(seconds: d);
      final mm = dur.inMinutes.remainder(60).toString().padLeft(2, '0');
      final ss = dur.inSeconds.remainder(60).toString().padLeft(2, '0');
      return '通話時長 $mm:$ss';
    }
    // 沒有時長時的兜底對應（你可依實際後端語意再微調）
    if (it.status == 4) return '已取消通話';
    return '未接通';
  }

  // 顯示：禮物 / 語音 / 圖片 / 文字
  Widget _threadSubtitle(ChatThreadItem it, UserModel me, List<GiftItemModel> gifts) {
    const greyStyle = TextStyle(color: Colors.grey, fontSize: 14);

    // ---------- 先判斷：禮物 ----------
    Map<String, dynamic>? gift = _parseGiftPayloadFromChatText(it.lastText);

    // lastText 不是禮物，就從原始 contentRaw 裡找 chat_text 再解析
    if (gift == null && it.contentRaw.isNotEmpty) {
      try {
        final outer = jsonDecode(it.contentRaw);
        if (outer is Map) {
          final innerText = outer['chat_text']?.toString();
          gift = _parseGiftPayloadFromChatText(innerText);
        }
      } catch (_) {}
    }

    if (gift != null) {
      final id      = _asInt(gift['gift_id'] ?? gift['id']) ?? -1;
      String title  = (gift['gift_title'] ?? gift['title'] ?? '').toString();
      String iconRel= (gift['gift_icon']  ?? gift['icon']  ?? '').toString();
      final count   = _asInt(gift['gift_count'] ?? gift['count'] ?? 1) ?? 1;

      // 用禮物清單補齊缺資料
      if ((title.isEmpty || iconRel.isEmpty) && id >= 0) {
        final match = gifts.where((g) => g.id == id).toList();
        if (match.isNotEmpty) {
          title   = title.isEmpty   ? match.first.title : title;
          iconRel = iconRel.isEmpty ? match.first.icon  : iconRel;
        }
      }

      final iconFull = _fullUrl(me.cdnUrl ?? '', iconRel);

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.card_giftcard, size: 14, color: Colors.grey),
          const SizedBox(width: 4),
          const Text('禮物', style: greyStyle),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              title.isNotEmpty ? title : '—',
              style: greyStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          if (iconFull.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(iconFull, width: 16, height: 16, fit: BoxFit.cover),
            ),
          const SizedBox(width: 6),
          Text('x$count', style: greyStyle),  // ★ 數量在這裡
        ],
      );
    }

    // ---------- 語音 ----------
    if (it.lastIsVoice) {
      final sec = it.lastVoiceDuration;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.mic, size: 14, color: Colors.grey),
          const SizedBox(width: 4),
          Text((sec != null && sec > 0) ? '${sec}"' : '語音', style: greyStyle),
        ],
      );
    }

    // ---------- 圖片 ----------
    if (it.lastIsImage) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.image, size: 14, color: Colors.grey),
          SizedBox(width: 4),
          Text('圖片', style: greyStyle),
        ],
      );
    }

    // ---------- 文字（含表情渲染） ----------
    final t = it.lastText.trim();
    if (t.isNotEmpty) {
      return _subtitleWithEmoji(t);
    }

    // 兜底：從 raw content 再判斷一次語音/圖片
    if (it.contentRaw.isNotEmpty) {
      try {
        final c = jsonDecode(it.contentRaw);
        if (c is Map) {
          final voicePath = c['voice_path']?.toString() ?? '';
          if (voicePath.isNotEmpty) {
            final d = c['duration'];
            final sec = (d is num) ? d.toInt() : int.tryParse('$d');
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.mic, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text((sec != null && sec > 0) ? '$sec' : '語音', style: greyStyle),
              ],
            );
          }
          final img = (c['img_path'] ?? c['image_path'])?.toString() ?? '';
          if (img.isNotEmpty) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.image, size: 14, color: Colors.grey),
                SizedBox(width: 4),
                Text('圖片', style: greyStyle),
              ],
            );
          }
        }
      } catch (_) {}
    }

    return const Text('…', style: TextStyle(color: Colors.grey));
  }

  String _formatRelative(int epochSec) {
    if (epochSec <= 0) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(epochSec * 1000, isUtc: true).toLocal();
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return '剛剛';
    if (diff.inHours < 1) return '${diff.inMinutes} 分鐘前';
    if (diff.inHours < 24) return '${diff.inHours} 小時前';
    return '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}';
  }

  ImageProvider _avatarOf( String cdnUrl, ChatThreadItem it) {
    // 取第一張頭像；若是相對路徑，用你的檔案域名補上
    if (it.avatars.isNotEmpty) {
      final p = it.avatars.first;
      final url = p.startsWith('http')
          ? p
          : '$cdnUrl$p';
      return NetworkImage(url);
    }
    return const AssetImage('assets/my_icon_defult.jpeg');
  }

  // 判定會話對象（非自己那位）
  int _partnerUid(ChatThreadItem it, UserModel me) {
    final my = int.tryParse(me.uid) ?? -1;
    return it.fromUid == my ? it.toUid : it.fromUid;
  }

  String _partnerName(ChatThreadItem it, UserModel me) {
    // 先用後端給的暱稱，沒有就 fallback
    if ((it.nickname ?? '').isNotEmpty) return it.nickname!;
    final puid = _partnerUid(it, me);
    return '用戶 $puid';
  }

  Widget _subtitleWithEmoji(String text) {
    const style = TextStyle(color: Colors.grey, fontSize: 14);
    return FutureBuilder<EmojiPack>(
      future: _emojiPackFut,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done || snap.data == null) {
          return Text(text, style: style, maxLines: 1, overflow: TextOverflow.ellipsis);
        }
        return EmojiText(
          text,
          pack: snap.data!,
          style: style,
          emojiSize: 16,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }

  Future<void> _refreshCalls() => _loadCallPage(page: 1, reset: true);

  Future<void> _loadMoreCalls() async {
    if (!_callHasMore || _callLoading) {
      _callRc.loadNoData();
      return;
    }
    await _loadCallPage(page: _callPage + 1);
  }

  Future<void> _loadCallPage({required int page, bool reset = false}) async {
    _callLoading = true;
    try {
      final repo = ref.read(chatRepositoryProvider);
      final items = await repo.fetchUserCallRecordList(
        page: page,
        toUid: _callToUidFilter,
      );

      if (reset) _callItems = [];
      // 去重（依 createAt/uid/flag）
      final exists = <String>{ for (final x in _callItems) '${x.createAt}-${x.uid}-${x.flag}' };
      final fresh = items.where((e) => exists.add('${e.createAt}-${e.uid}-${e.flag}')).toList();

      _callItems.addAll(fresh);
      _callPage = page;
      _callHasMore = items.isNotEmpty;

      if (reset) {
        _callRc.refreshCompleted();
        _callRc.resetNoData();
      }
      _callHasMore ? _callRc.loadComplete() : _callRc.loadNoData();
    } catch (e) {
      if (_isNetworkIssue(e)) {
        _toastNetworkError();
        if (reset) {
          _callRc.refreshCompleted(); // 結束動畫即可，不顯示失敗
          _callRc.resetNoData();
        } else {
          _callRc.loadComplete();     // 不標成失敗，避免紅字
        }
      } else {
        if (reset) {
          _callRc.refreshFailed();
        } else {
          _callRc.loadFailed();
        }
      }
    } finally {
      _callLoading = false;
      if (mounted) setState(() {});
    }

  }

  Color _getStatusColor(int index) {
    switch (index) {
      case 0:
        return Colors.grey; // 離線
      case 1:
      case 2:
        return Colors.green; // 上線
      case 3:
      case 4:
      case 5:
        return Colors.orange; // 忙碌
      default:
        return Colors.grey; // 離線
    }
  }

  int? _asInt(dynamic v) => (v is num) ? v.toInt() : int.tryParse('$v');

  Map<String, dynamic>? _decodeJsonMap(String? s) {
    if (s == null || s.isEmpty) return null;
    try {
      final v = jsonDecode(s);
      if (v is Map) {
        return v.map((k, v) => MapEntry(k.toString(), v));
      }
    } catch (_) {}
    return null;
  }

  Map<String, dynamic>? _parseGiftPayloadFromChatText(String? chatText) {
    final inner = _decodeJsonMap(chatText);
    final type = (inner?['type'] ?? inner?['t'])?.toString().toLowerCase();
    if (type == 'gift') return inner;
    return null;
  }

  String _fullUrl(String base, String p) {
    if (p.isEmpty) return p;
    if (p.startsWith('http')) return p;
    if (base.isEmpty) return p;
    return p.startsWith('/') ? '$base$p' : '$base/$p';
  }

  void _toastNetworkError() {
    Fluttertoast.showToast(msg: '資料獲取失敗，網路連接異常');
  }

  /// 判斷是否屬於「網路/連線」型錯誤（離線、逾時、502/503/504 等）
  bool _isNetworkIssue(Object e) {
    if (e is DioException) {
      switch (e.type) {
        case DioExceptionType.connectionError:
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
          return true;
        default:
          break;
      }
      final sc = e.response?.statusCode ?? 0;
      if (sc == 502 || sc == 503 || sc == 504) return true;     // 反向代理/伺服器忙
      if (e.error is SocketException) return true;               // DNS/無網路
    } else if (e is SocketException) {
      return true;
    }
    return false;
  }

}
