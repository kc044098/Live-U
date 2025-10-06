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
import '../../l10n/l10n.dart';
import '../call/call_request_page.dart';
import '../live/gift_providers.dart';
import '../message/chat_providers.dart';
import '../message/chat_thread_item.dart';
import '../message/chat_ws_service.dart';
import '../message/data_model/call_record_item.dart';
import '../message/emoji/emoji_pack.dart';
import '../message/emoji/emoji_text.dart';
import '../message/message_chat_page.dart';
import '../mine/member_fans_provider.dart';
import '../mine/show_like_alert_dialog.dart';
import '../mine/who_likes_me_page.dart';
import '../profile/profile_controller.dart';
import '../wallet/payment_method_page.dart';
import '../widgets/cached_network_image.dart';

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

  final RefreshController _inboxRc = RefreshController(initialRefresh: false);
  bool _inboxHasMore = true;
  bool _inboxPaging = false;

  int _lastSilentReloadMs = 0;

  final RefreshController _callRc = RefreshController(initialRefresh: false);
  List<CallRecordItem> _callItems = [];
  bool _callLoading = false;
  bool _callHasMore = true;
  int _callPage = 1;
  int? _callToUidFilter;

  // 只拿來決定長度=2；實際 Tab 文案用 S.of(context)
  final List<Tab> _tabs = const [
    Tab(text: '消息'),
    Tab(text: '通話'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _emojiPackFut = EmojiPack.loadFromFolder('assets/emojis/basic/');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadThreads(page: 1);
      ref.read(memberFansProvider.notifier).loadFirstPage();
    });

    _loadCallPage(page: 1, reset: true);
  }

  Future<void> _loadThreads({int page = 1}) async {
    setState(() {
      _loading = page == 1 ? true : _loading;
      _error = null;
    });
    try {
      final repo = ref.read(chatRepositoryProvider);
      final res = await repo.fetchUserMessageList(page: page);
      if (!mounted) return;

      setState(() {
        if (page == 1) {
          _threads = res.items;
        } else {
          final seen = <String>{ for (final t in _threads) '${t.fromUid}-${t.toUid}' };
          for (final t in res.items) {
            if (seen.add('${t.fromUid}-${t.toUid}')) _threads.add(t);
          }
        }
        _page = page;
        _loading = false;
        _inboxHasMore = res.items.isNotEmpty;
      });
    } catch (e) {
      if (!mounted) return;

      if (_isNoDataError(e)) {
        setState(() {
          if (page == 1) {
            _threads = [];
            _page = 1;
            _loading = false;
            _error = null;
          }
          _inboxHasMore = false;
        });
        return;
      }

      if (_isNetworkIssue(e)) {
        _toastNetworkError();
        setState(() {
          _loading = false;
        });
      } else {
        setState(() {
          _error = '$e';
          _loading = false;
        });
      }
    }
  }

  Future<void> _refreshInbox() async {
    await _loadThreads(page: 1);
    _inboxRc.refreshCompleted();
    _inboxHasMore ? _inboxRc.resetNoData() : _inboxRc.loadNoData();
  }

  Future<void> _loadMoreInbox() async {
    if (_inboxPaging || !_inboxHasMore) {
      _inboxRc.loadNoData();
      return;
    }
    _inboxPaging = true;
    try {
      await _loadThreads(page: _page + 1);
      _inboxHasMore ? _inboxRc.loadComplete() : _inboxRc.loadNoData();
    } catch (_) {
      _inboxRc.loadFailed();
    } finally {
      _inboxPaging = false;
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
    final t = S.of(context);

    ref.listen<AsyncValue<void>>(inboxBumpProvider, (prev, next) {
      next.whenData((_) {
        if (!mounted) return;
        _reloadThreadsSilently();
      });
    });

    final user = ref.watch(userProfileProvider);
    return Column(
      children: [
        const SizedBox(height: 40),
        TabBar(
          controller: _tabController,
          isScrollable: true,
          labelPadding: const EdgeInsets.symmetric(horizontal: 16),
          tabAlignment: TabAlignment.start,
          tabs: [Tab(text: t.messagesTab), Tab(text: t.callsTab)],
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
          indicatorColor: Colors.transparent,
          dividerColor: Colors.transparent,
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildMessageContent(user),
              _buildCallContent(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageContent(UserModel? user) {
    final t = S.of(context);
    final me = user!;

    final fans = ref.watch(memberFansProvider);
    final int likeCount = fans.totalCount;
    final String? lastName = (fans.items.isNotEmpty) ? fans.items.last.name : null;

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
            Text('${t.loadFailedPrefix}$_error'),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => _loadThreads(page: 1),
              child: Text(t.retry),
            ),
          ],
        ),
      );
    }

    const hasLikeCard = true;
    final totalRows = _threads.length + 1;

    return Stack(
      children: [
        SmartRefresher(
          controller: _inboxRc,
          enablePullDown: true,
          enablePullUp: _inboxHasMore,
          header: const ClassicHeader(),
          footer: const ClassicFooter(),
          onRefresh: _refreshInbox,
          onLoading: _loadMoreInbox,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 120),
            itemCount: totalRows,
            itemBuilder: (context, index) {
              if (hasLikeCard && index == 0) {
                final titleText = t.whoLikesMeTitleCount(likeCount > 0 ? likeCount : 0);
                final subtitleText = (likeCount > 0 && (lastName != null && lastName.isNotEmpty))
                    ? t.lastUserJustLiked(lastName)
                    : t.noNewLikes;

                return Column(
                  children: [
                    ListTile(
                      leading: SvgPicture.asset('assets/message_like_1.svg', width: 48, height: 48),
                      title: Text(titleText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      subtitle: Text(subtitleText, style: const TextStyle(color: Colors.grey)),
                      onTap: () async {
                        final canEnter = (me.isBroadcaster == true) || (me.isVip == true);
                        if (canEnter) {
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

              final tIndex = hasLikeCard ? index - 1 : index;
              final it = _threads[tIndex];

              final avatarRel = it.avatars.isNotEmpty ? it.avatars.first : '';
              final avatarUrl = _fullUrl(me.cdnUrl ?? '', avatarRel);

              return Column(
                children: [
                  ListTile(
                      leading: Stack(
                        children: [
                          buildAvatarCircle(url: avatarUrl, radius: 24),
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
                      subtitle: _threadSubtitle(it, me, gifts),
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
                      onTap: () async {
                        final partnerUid = _partnerUid(it, me);
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MessageChatPage(
                              partnerName: _partnerName(it, me),
                              partnerAvatar: it.avatars.isNotEmpty ? '${me.cdnUrl}${it.avatars.first}' : 'assets/my_icon_defult.jpeg',
                              vipLevel: it.vip,
                              statusText: it.status,
                              partnerUid: partnerUid,
                            ),
                          ),
                        );
                        if (!mounted) return;
                        _silentReloadDebounced(force: true);
                      }
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
              Text(
                S.of(context).totalUnreadMessages(_totalUnread),
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const Expanded(child: Divider(color: Colors.grey, thickness: 0.5, indent: 8)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCallContent() {
    final t = S.of(context);
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
          final title = (it.nickname.isNotEmpty) ? it.nickname : t.userWithId(it.uid);
          final statusText = _callStatusText(it);
          // 用「本地化 token」判斷是否標紅
          final isMissed = statusText.contains(t.missedToken) || statusText.contains(t.canceledToken);

          return ListTile(
            leading: buildAvatarCircle(url: url, radius: 24),
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
    final t = S.of(context);
    final d = (it.endAt > it.startAt) ? (it.endAt - it.startAt) : 0;
    if (d > 0) {
      final dur = Duration(seconds: d);
      final mm = dur.inMinutes.remainder(60).toString().padLeft(2, '0');
      final ss = dur.inSeconds.remainder(60).toString().padLeft(2, '0');
      return t.callDuration(mm, ss);
    }
    if (it.status == 4) return t.callCanceled;
    return t.callNotConnected;
  }

  Widget _threadSubtitle(ChatThreadItem it, UserModel me, List<GiftItemModel> gifts) {
    final t = S.of(context);
    const greyStyle = TextStyle(color: Colors.grey, fontSize: 14);

    Map<String, dynamic>? gift = _parseGiftPayloadFromChatText(it.lastText);
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
      final count   = _asInt(gift['gift_count']  ?? 1) ?? 1;

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
          Text(t.giftLabel, style: greyStyle),
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
              child: Image.network(
                iconFull,
                width: 16,
                height: 16,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  _silentReloadDebounced();
                  return const SizedBox(width: 16, height: 16);
                },
              ),
            ),
          const SizedBox(width: 6),
          Text('x$count', style: greyStyle),
        ],
      );
    }

    if (it.lastIsVoice) {
      final sec = it.lastVoiceDuration;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.mic, size: 14, color: Colors.grey),
          const SizedBox(width: 4),
          Text((sec != null && sec > 0) ? '${sec}"' : t.voiceLabel, style: greyStyle),
        ],
      );
    }

    if (it.lastIsImage) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.image, size: 14, color: Colors.grey),
          const SizedBox(width: 4),
          Text(t.imageLabel, style: greyStyle),
        ],
      );
    }

    final txt = it.lastText.trim();
    if (txt.isNotEmpty) {
      if (_looksLikeTransportError(txt)) {
        _silentReloadDebounced();
        return const Text('…', style: TextStyle(color: Colors.grey, fontSize: 14));
      }
      return _subtitleWithEmoji(txt);
    }

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
                Text((sec != null && sec > 0) ? '$sec' : t.voiceLabel, style: greyStyle),
              ],
            );
          }
          final img = (c['img_path'] ?? c['image_path'])?.toString() ?? '';
          if (img.isNotEmpty) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.image, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(t.imageLabel, style: greyStyle),
              ],
            );
          }
        }
      } catch (_) {}
    }

    return const Text('…', style: TextStyle(color: Colors.grey));
  }

  Future<void> _reloadThreadsSilently() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastSilentReloadMs < 800) return;
    _lastSilentReloadMs = now;

    try {
      final repo = ref.read(chatRepositoryProvider);
      final res  = await repo.fetchUserMessageList(page: 1);

      if (!mounted) return;
      setState(() {
        _threads = res.items;
        _page = 1;
      });
    } catch (_) {}
    _inboxHasMore ? _inboxRc.resetNoData() : _inboxRc.loadNoData();
  }

  String _formatRelative(int epochSec) {
    final t = S.of(context);
    if (epochSec <= 0) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(epochSec * 1000, isUtc: true).toLocal();
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return t.justNow;
    if (diff.inHours   < 1) return t.minutesAgo(diff.inMinutes);
    if (diff.inHours  < 24) return t.hoursAgo(diff.inHours);
    return t.dateYmd(dt.year, dt.month, dt.day);
  }

  ImageProvider _avatarOf(String cdnUrl, ChatThreadItem it) {
    if (it.avatars.isNotEmpty) {
      final p = it.avatars.first;
      final url = p.startsWith('http') ? p : '$cdnUrl$p';
      return NetworkImage(url);
    }
    return const AssetImage('assets/my_icon_defult.jpeg');
  }

  int _partnerUid(ChatThreadItem it, UserModel me) {
    final my = int.tryParse(me.uid) ?? -1;
    return it.fromUid == my ? it.toUid : it.fromUid;
  }

  String _partnerName(ChatThreadItem it, UserModel me) {
    if ((it.nickname ?? '').isNotEmpty) return it.nickname!;
    final puid = _partnerUid(it, me);
    return S.of(context).userWithId(puid);
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
      final items = await repo.fetchUserCallRecordList(page: page, toUid: _callToUidFilter);

      if (reset) _callItems = [];
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
      if (_isNoDataError(e)) {
        if (reset) {
          _callItems = [];
          _callPage = 1;
          _callHasMore = false;
          _callRc.refreshCompleted();
          _callRc.loadNoData();
        } else {
          _callHasMore = false;
          _callRc.loadNoData();
        }
      } else if (_isNetworkIssue(e)) {
        _toastNetworkError();
        if (reset) {
          _callRc.refreshCompleted();
          _callRc.resetNoData();
        } else {
          _callRc.loadComplete();
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
      case 0: return Colors.grey;
      case 1:
      case 2: return Colors.green;
      case 3:
      case 4:
      case 5: return Colors.orange;
      default: return Colors.grey;
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
    Fluttertoast.showToast(msg: S.of(context).networkFetchError);
  }

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
      if (sc == 502 || sc == 503 || sc == 504) return true;
      if (e.error is SocketException) return true;
    } else if (e is SocketException) {
      return true;
    }
    return false;
  }

  void _silentReloadDebounced({int gapMs = 800, bool force = false}) {
    if (!force) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - _lastSilentReloadMs < gapMs) return;
      _lastSilentReloadMs = now;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _reloadThreadsSilently());
  }

  bool _isNoDataError(Object e) {
    bool _msgNoData(String? s) {
      if (s == null) return false;
      final t = s.toLowerCase();
      return t.contains('暫無資料') || t.contains('no data');
    }

    int? _codeFrom(dynamic data) {
      if (data is Map) {
        final c = data['code'];
        if (c is num) return c.toInt();
        return int.tryParse('${c ?? ''}');
      }
      if (data is String) {
        try {
          final m = jsonDecode(data);
          if (m is Map) {
            final c = m['code'];
            if (c is num) return c.toInt();
            return int.tryParse('${c ?? ''}');
          }
        } catch (_) {}
      }
      return null;
    }

    String? _msgFrom(dynamic data) {
      if (data is Map) return data['message']?.toString();
      if (data is String) {
        try {
          final m = jsonDecode(data);
          if (m is Map) return m['message']?.toString();
        } catch (_) {}
        return data;
      }
      return null;
    }

    if (e is DioException) {
      final sc = e.response?.statusCode ?? 0;
      if (sc == 404) return true;

      final data = e.response?.data;
      final code = _codeFrom(data);
      final msg  = _msgFrom(data);
      if (code == 404 || code == 100) return true;
      if (_msgNoData(msg)) return true;
    } else {
      final s = e.toString();
      if (_msgNoData(s)) return true;
      if (s.contains(' 404 ')) return true;
    }
    return false;
  }

  bool _looksLikeTransportError(String s) {
    final t = s.toLowerCase();
    return t.contains('httpexception')
        || t.contains('socketexception')
        || t.contains('connection closed')
        || t.contains('failed host lookup')
        || t.contains('timed out')
        || t.contains('network is unreachable')
        || t.contains('sslhandshake');
  }
}

