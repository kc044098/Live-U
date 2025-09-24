import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:djs_live_stream/data/network/background_api_service.dart';
import 'package:djs_live_stream/features/mine/user_repository_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/user_local_storage.dart';
import '../profile/profile_controller.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});
  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final ImagePicker _picker = ImagePicker();
  final List<XFile?> _mediaFiles = [null, null, null];
  List<String> allTags = [];
  DateTime _selectedDate = DateTime(2005, 6, 17);
  List<String>? _photosShadow; // 即時 UI 用，本地快照
  static const _maxSlots = 3;

  List<String> _normalizeSlots(List<String> src) {
    final list = List<String>.from(src);
    while (list.length < _maxSlots) list.add('');
    if (list.length > _maxSlots) list.length = _maxSlots;
    return list;
  }

  Future<void> _pickMedia(int tappedIndex) async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 100);
    if (file == null) return;

    final ext = file.path.split('.').last.toLowerCase();
    if (!['jpg', 'jpeg', 'png'].contains(ext)) {
      Fluttertoast.showToast(msg: "只允許上傳 JPG / JPEG / PNG 圖片");
      return;
    }

    setState(() {
      _mediaFiles[tappedIndex] = file;
      final slots = _normalizeSlots(_photosShadow ?? ref.read(userProfileProvider)?.photoURL ?? []);
      slots[tappedIndex] = file.path;   // 只改這一格
      _photosShadow = slots;            // 保留其它格的空字串
    });

    _updatePhoto(tappedIndex, file.path);
  }

  /// 新增或更新圖片
  void _updatePhoto(int index, String filePath) {
    // 用 temp 為主，沒有就用 user.photoURL
    final base = _normalizeSlots(_photosShadow ?? ref.read(userProfileProvider)?.photoURL ?? []);
    base[index] = filePath; // 此處可能是本地路徑
    _savePhotoList(base);   // 直接把 3 格送進去（不壓縮）
  }

  // 同步更新到 user model
  Future<void> _savePhotoList(List<String> slots) async {
    // 先只更新 temp（畫面用），不要動 user.photoURL（它只能存 S3 相對路徑）
    _applyOptimisticAvatarList(slots);

    // 上傳前 log
    debugPrint('[Avatar] BEFORE UPLOAD tempSlots=${slots.toString()} '
        'user.photoURL=${ref.read(userProfileProvider)?.photoURL}');

    final svc = ref.read(backgroundApiServiceProvider);
    try {
      // 直接送 3 格（不壓縮），service 內會就地把本地檔轉 S3 相對路徑並保留位置
      await svc.uploadAvatarsAndUpdate(paths: _normalizeSlots(slots));
    } catch (e) {
      debugPrint('[Avatar] 上傳失敗：$e');
      // 回滾 temp → 以後端（或本地儲存）為準
      final me = ref.read(userProfileProvider);
      _rollbackAvatarList(_normalizeSlots(me?.photoURL ?? []));
    }
  }

  void _applyOptimisticAvatarList(List<String> slots) {
    if (mounted) setState(() => _photosShadow = _normalizeSlots(slots));
  }

  void _rollbackAvatarList(List<String> oldList) {
    if (mounted) setState(() => _photosShadow = _normalizeSlots(oldList));
  }


  Future<void> _persistAvatarList(
      List<String> newList, {
        required List<String> rollbackOnFail,
      }) async {
    final svc = ref.read(backgroundApiServiceProvider);
    try {
      // 直接送 3 格（包含空字串）
      await svc.updateMemberInfoQueued({'avatar': newList});

      // 成功 → 把 user.photoURL 同步成 3 格的最終結果（只會是 S3 相對路徑或空字串）
      final me = ref.read(userProfileProvider);
      if (me != null) {
        final updated = me.copyWith(photoURL: _normalizeSlots(newList));
        ref.read(userProfileProvider.notifier).setUser(updated);
        unawaited(UserLocalStorage.saveUser(updated));
      }
    } catch (e, st) {
      debugPrint('[Avatar] DELETE failed: $e\n$st');
      if (mounted) _rollbackAvatarList(rollbackOnFail);
    }
  }

  void _deletePhotoAtIndexImmediately(int index) {
    // 刪除前 log
    debugPrint('[Avatar] BEFORE DELETE index=$index '
        'temp=${_photosShadow} user=${ref.read(userProfileProvider)?.photoURL}');

    setState(() => _mediaFiles[index] = null);

    final oldSlots = _normalizeSlots(_photosShadow ?? ref.read(userProfileProvider)?.photoURL ?? []);
    final newSlots = List<String>.from(oldSlots)..[index] = ''; // 不位移

    final me = ref.read(userProfileProvider);
    if (me != null) {
      final serverSlots = _normalizeSlots(me.photoURL)..[index] = '';
      final updated = me.copyWith(photoURL: serverSlots);
      ref.read(userProfileProvider.notifier).setUser(updated);
      unawaited(UserLocalStorage.saveUser(updated));
      debugPrint('[Avatar] OPTIMISTIC photoURL=$serverSlots');
    }

    // 刪除「要送出去」的內容 log
    debugPrint('[Avatar] WILL SEND (DELETE) slots=$newSlots');

    _applyOptimisticAvatarList(newSlots);
    unawaited(_persistAvatarList(_normalizeSlots(newSlots), rollbackOnFail: oldSlots));
  }

  bool _isVideo(XFile file) {
    final path = file.path.toLowerCase();
    return path.endsWith('.mp4') || path.endsWith('.mov') || path.endsWith('.avi');
  }

  @override
  void initState() {
    super.initState();
    final user = ref.read(userProfileProvider);
    _photosShadow = _normalizeSlots(user?.photoURL ?? []);

    final photos = user?.photoURL ?? [];
    for (int i = 0; i < photos.length && i < 3; i++) {
      final p = photos[i];
      if (p.isLocalAbs || p.isDataUri || p.isContentUri) {
        _mediaFiles[i] = XFile(p);
      } else {
        _mediaFiles[i] = null;
      }
    }
    _loadAllTags();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProfileProvider);
    final extra = ref.watch(userProfileProvider)?.extra ?? {};
    final photos = _photosShadow ?? _normalizeSlots(user?.photoURL ?? []);

    String displayHeight = extra['height']?.toString() ?? '';
    if (displayHeight.isNotEmpty && !displayHeight.contains('cm')) {
      displayHeight += 'cm';
    }

    String displayWeight = extra['weight']?.toString() ?? '';
    if (displayWeight.isNotEmpty && !displayWeight.contains('磅')) {
      displayWeight += '磅';
    }

    String displayAge = extra['age']?.toString() ?? '';
    if (displayAge.isNotEmpty && !displayAge.contains('岁')) {
      displayAge += '岁';
    }

    String displayBody = '';
    if (extra['body'] != null && extra['body']!.toString().contains('-')) {
      final parts = extra['body']!.toString().split('-');
      if (parts.length == 3) {
        displayBody = '胸围 ${parts[0]} 腰围 ${parts[1]} 臀围 ${parts[2]}';
      }
    }
    final profileItems = [
      {'label': '昵称', 'value': (ref.watch(userProfileProvider)?.displayName ?? '').toString()},
      {
        'label': '性别',
        'value': (() {
          final sex = ref.watch(userProfileProvider)?.sex;
          switch (sex) {
            case 1:
              return '男';
            case 2:
              return '女';
            case 3:
              return '保密';
            default:
              return '未知';
          }
        })(),
      },
      {'label': '生日', 'value': displayAge},
      {'label': '身高', 'value': displayHeight},
      {'label': '体重', 'value': displayWeight},
      {'label': '三围', 'value': displayBody.isNotEmpty ? displayBody : '胸围 0 腰围 0 臀围 0'},
      {'label': '城市', 'value': (extra['city'] ?? '未知').toString()},
      {'label': '工作', 'value': (extra['job'] ?? '未知').toString()},
      {
        'label': '个人标签',
        'value': (() {
          final tags = ref.watch(userProfileProvider)?.tags;
          if (tags == null || tags.isEmpty) return '立即添加';
          return tags.join(', ');
        })(),
      },
    ];

    final cdn = user?.cdnUrl ?? '';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit profile'),
        centerTitle: true,
        leading: const BackButton(),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF8F8F8),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [


    Row(
    children: List.generate(3, (index) {
      final file = _mediaFiles[index];
      final raw = (index < photos.length) ? photos[index] : '';
      final isVideo = file != null && _isVideo(file);

      ImageProvider? provider;
      if (file != null && !isVideo && File(file.path).existsSync()) {
        provider = FileImage(File(file.path));               // 本地立即顯示
      } else if (raw.isHttp) {
        provider = CachedNetworkImageProvider(raw);          // 已是完整 http
      } else if (raw.isServerRelative) {
        provider = CachedNetworkImageProvider(joinCdnIfNeeded(raw, cdn)); // 相對路徑才拼
      } else if (raw.isLocalAbs) {
        provider = FileImage(File(raw));                     // 本地絕對路徑
      } // 其餘：保持 null → 顯示「+」

      return Expanded(
        child: GestureDetector(
          onTap: () => _pickMedia(index),
          child: Container(
            margin: EdgeInsets.only(right: index < 2 ? 12 : 0), height: 100,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                    image: provider == null
                        ? null
                        : DecorationImage(
                      image: (provider is CachedNetworkImageProvider)
                          ? ResizeImage(provider, width: 300, height: 300)
                          : provider,
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: provider == null
                      ? const Center(child: Icon(Icons.add, size: 32, color: Colors.grey))
                      : null,
                ),
                if (provider != null)
                  Positioned(
                    top: 4, right: 4,
                    child: GestureDetector(
                      onTap: () => _deletePhotoAtIndexImmediately(index),
                      child: Container(
                        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                        padding: const EdgeInsets.all(4),
                        child: const Icon(Icons.close, size: 16, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }),
    ),
    const SizedBox(height: 16),
          _buildProfileInfo(profileItems),
        ],
      ),
    );
  }

  Widget _buildProfileInfo(List<Map<String, String>> profileItems) {
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
        children: List.generate(profileItems.length, (index) {
          final item = profileItems[index];
          return Column(
            children: [
              ListTile(
                title: Text(item['label']!, style: const TextStyle(fontSize: 14)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(item['value']!,
                        style: const TextStyle(fontSize: 14, color: Colors.black87)),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                  ],
                ),
                onTap: () {
                  switch (item['label']) {
                    case '昵称':
                      _showNicknameSheet();
                      break;
                    case '身高':
                      _showHeightSheet();
                      break;
                    case '体重':
                      _showWeightSheet();
                      break;
                    case '生日':
                      _showBirthdayPicker();
                      break;
                    case '三围':
                      _showBodySheet();
                      break;
                    case '工作':
                      _showJobSheet();
                      break;
                    case '个人标签':
                      _showTagsSheet();
                      break;
                  }
                },
              ),
              if (index != profileItems.length - 1)
                const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFF5F5F5)),
            ],
          );
        }),
      ),
    );
  }

  void _showNicknameSheet() {
    final user = ref.read(userProfileProvider);
    final controller = TextEditingController(text: user?.displayName ?? "");

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 標題 + 關閉
                Stack(
                  alignment: Alignment.center,
                  children: [
                    const Center(
                      child: Text(
                        '填写昵称',
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      child: IconButton(
                        icon: const Icon(Icons.close),
                        iconSize: 20,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // 輸入框
                SizedBox(
                  width: 340,
                  child: TextField(
                    controller: controller,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.text,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(16),
                    ],
                    decoration: InputDecoration(
                      hintText: '请输入昵称',
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // 保存按鈕
                SizedBox(
                  width: 128,
                  height: 40,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFFFF4D67)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: () async {
                      final nickname = controller.text.trim();
                      if (nickname.isEmpty) {
                        Fluttertoast.showToast(msg: '請輸入暱稱');
                        return;
                      }
                      if (nickname.length > 16) {
                        Fluttertoast.showToast(msg: '暱稱長度過長, 請重新輸入');
                        return;
                      }
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => const Center(child: CircularProgressIndicator()),
                      );

                      try {
                        // 呼叫 API 更新暱稱
                        final repo = ref.read(userRepositoryProvider);
                        await repo.updateMemberInfo({'nick_name': nickname});

                        // 同步更新本地 user model
                        final user = ref.read(userProfileProvider);
                        final updatedUser = user?.copyWith(displayName: nickname);
                        if (updatedUser != null) {
                          ref.read(userProfileProvider.notifier).setUser(updatedUser);
                          await UserLocalStorage.saveUser(updatedUser);
                        }

                        Fluttertoast.showToast(msg: '暱稱更新成功');
                      } catch (e) {
                        Fluttertoast.showToast(msg: '暱稱更新失敗：$e');
                      } finally {
                        Navigator.of(context).pop(); // ✅ 關閉 loading dialog
                        Navigator.of(context).pop(); // ✅ 關閉 bottom sheet
                      }
                    },
                    child: const Text(
                      '确定',
                      style: TextStyle(
                        color: Color(0xFFFF4D67),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  void _showHeightSheet() {
    final extra = ref.read(userProfileProvider)?.extra ?? {};
    final controller = TextEditingController(
      text: (extra['height'] ?? '').replaceAll('cm', ''),
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 標題 + 關閉
                Stack(
                  alignment: Alignment.center,
                  children: [
                    const Center(
                      child: Text(
                        '填写身高',
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      child: IconButton(
                        icon: const Icon(Icons.close),
                        iconSize: 20,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // 輸入框
                SizedBox(
                  width: 340,
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                    decoration: InputDecoration(
                      suffixText: 'cm',
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 保存按鈕
                SizedBox(
                  width: 128,
                  height: 40,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFFFF4D67)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: () async {
                      final heightValue = int.tryParse(controller.text);
                      if (heightValue == null || heightValue <= 0) {
                        Fluttertoast.showToast(msg: '請輸入正確的身高');
                        return;
                      }
                      if (heightValue == null || heightValue <= 0 || heightValue > 999) {
                        Fluttertoast.showToast(msg: '請輸入 1–999 的身高');
                        return;
                      }
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => const Center(child: CircularProgressIndicator()),
                      );
                      try {
                        // 上傳到後端
                        final repo = ref.read(userRepositoryProvider);
                        await repo.updateMemberInfo({
                          'detail': {
                            'height': '$heightValue',
                          }
                        });

                        // 更新 local user state
                        final currentUser = ref.read(userProfileProvider);
                        if (currentUser != null) {
                          final updatedExtra = Map<String, dynamic>.from(currentUser.extra ?? {});
                          updatedExtra['height'] = '$heightValue';

                          final updatedUser = currentUser.copyWith(extra: updatedExtra);
                          ref.read(userProfileProvider.notifier).setUser(updatedUser);
                          await UserLocalStorage.saveUser(updatedUser);
                        }

                        final height = '${int.tryParse(controller.text) ?? 0}cm';
                        _updateExtra('height', height);

                        Fluttertoast.showToast(msg: '身高更新成功');
                      } catch (e) {
                        Fluttertoast.showToast(msg: '身高更新失敗：$e');
                      } finally {
                        Navigator.of(context).pop(); // ✅ 關閉 loading dialog
                        Navigator.of(context).pop(); // ✅ 關閉 bottom sheet
                      }
                    },
                    child: const Text(
                      '确定',
                      style: TextStyle(
                        color: Color(0xFFFF4D67),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showWeightSheet() {
    final extra = ref.read(userProfileProvider)?.extra ?? {};
    final controller = TextEditingController(text: (extra['weight'] ?? '').replaceAll('磅', ''),);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    const Center(
                      child: Text(
                        '填写体重',
                        style:
                        TextStyle(fontSize: 20),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      child: IconButton(
                        icon: const Icon(Icons.close),
                        iconSize: 20,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                SizedBox(
                  width: 340,
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                    decoration: InputDecoration(
                      suffixText: '磅',
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: Color(0xFFE0E0E0)), // 外框顏色
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: Color(0xFFE0E0E0)), // 聚焦時保持顏色
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 128,
                  height: 40,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFFFF4D67)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: () async {
                      final weightValue = int.tryParse(controller.text);
                      if (weightValue == null || weightValue <= 0) {
                        Fluttertoast.showToast(msg: '請輸入正確的體重');
                        return;
                      }
                      if (weightValue == null || weightValue <= 0 || weightValue > 999) {
                        Fluttertoast.showToast(msg: '請輸入 1–999 的體重');
                        return;
                      }
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => const Center(child: CircularProgressIndicator()),
                      );
                      try {
                        // 上傳到後端
                        final repo = ref.read(userRepositoryProvider);
                        await repo.updateMemberInfo({
                          'detail': {
                            'weight': '$weightValue',
                          }
                        });

                        // 更新 local user state
                        final currentUser = ref.read(userProfileProvider);
                        if (currentUser != null) {
                          final updatedExtra = Map<String, dynamic>.from(currentUser.extra ?? {});
                          updatedExtra['weight'] = '$weightValue磅';

                          final updatedUser = currentUser.copyWith(extra: updatedExtra);
                          ref.read(userProfileProvider.notifier).setUser(updatedUser);
                          await UserLocalStorage.saveUser(updatedUser);
                        }

                        final weight = '${int.tryParse(controller.text) ?? 0}磅';
                        _updateExtra('weight', weight);
                        Fluttertoast.showToast(msg: '體重更新成功');
                      } catch (e) {
                        Fluttertoast.showToast(msg: '體重更新失敗：$e');
                      } finally {
                        Navigator.of(context).pop(); // ✅ 關閉 loading dialog
                        Navigator.of(context).pop(); // ✅ 關閉 bottom sheet
                      }
                    },
                    child: const Text(
                      '保存',
                      style: TextStyle(
                        color: Color(0xFFFF4D67),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  void _showBirthdayPicker() {
    const int kMinAge = 18;
    final now = DateTime.now();
    // 這一天（含當天）之前出生 → 已滿 18
    final cutoff = DateTime(now.year - kMinAge, now.month, now.day);

    // 初始選中值：若目前 _selectedDate 小於 18 歲，就強制拉回臨界日
    DateTime initial = _selectedDate;
    if (initial.isAfter(cutoff)) initial = cutoff;

    int selectedYear  = initial.year;
    int selectedMonth = initial.month;
    int selectedDay   = initial.day;

    int daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

    // 年份清單：從「最年輕可選（=滿 18）」一路往前 100 年
    final youngestYear = cutoff.year;
    final oldestYear   = now.year - 100;
    final years = List.generate(
      (youngestYear - oldestYear) + 1,
          (i) => youngestYear - i,
    );

    // 針對當年(= youngestYear)限制月份/天數，避免選到比 cutoff 晚的日期
    int visibleMonthsForYear(int year) => (year == youngestYear) ? cutoff.month : 12;
    int visibleDaysFor(int year, int month) {
      int d = daysInMonth(year, month);
      if (year == youngestYear && month == cutoff.month) {
        d = min(d, cutoff.day);
      }
      return d;
    }

    // 先把目前的 月/日 壓到合法區間
    selectedMonth = min(selectedMonth, visibleMonthsForYear(selectedYear));
    selectedDay   = min(selectedDay, visibleDaysFor(selectedYear, selectedMonth));
    int maxDays   = visibleDaysFor(selectedYear, selectedMonth);

    final months = const [
      "January","February","March","April","May","June",
      "July","August","September","October","November","December"
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SizedBox(
              height: 300,
              child: Column(
                children: [
                  // 標題欄
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Text('Cancel',
                              style: TextStyle(color: Colors.black54, fontSize: 16)),
                        ),
                        GestureDetector(
                          onTap: () async {
                            final picked = DateTime(selectedYear, selectedMonth, selectedDay);

                            // 雙保險：若仍晚於 cutoff（理論上不會），擋掉
                            if (picked.isAfter(cutoff)) {
                              Fluttertoast.showToast(msg: '需年滿 18 歲');
                              return;
                            }

                            // 計算年齡
                            int age = now.year - picked.year;
                            if (now.month < picked.month ||
                                (now.month == picked.month && now.day < picked.day)) {
                              age--;
                            }

                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (_) => const Center(child: CircularProgressIndicator()),
                            );
                            try {
                              // 上傳到後端（你原本的流程）
                              final repo = ref.read(userRepositoryProvider);
                              await repo.updateMemberInfo({
                                'detail': { 'age': '$age' }
                              });

                              // 更新本地 userModel 的 extra
                              final currentUser = ref.read(userProfileProvider);
                              if (currentUser != null) {
                                final updatedExtra = Map<String, dynamic>.from(currentUser.extra ?? {});
                                updatedExtra['age'] = '$age岁';
                                _updateExtra('age', '$age岁');

                                final updatedUser = currentUser.copyWith(extra: updatedExtra);
                                ref.read(userProfileProvider.notifier).setUser(updatedUser);
                                await UserLocalStorage.saveUser(updatedUser);
                              }

                              _selectedDate = picked;
                              Fluttertoast.showToast(msg: '年齡已更新');
                            } catch (e) {
                              Fluttertoast.showToast(msg: '年齡更新失敗：$e');
                            }
                            Navigator.of(context).pop(); // 關 loading
                            Navigator.of(context).pop(); // 關 bottom sheet
                          },
                          child: const Text('Done',
                              style: TextStyle(color: Color(0xFFFF4D67), fontSize: 16)),
                        ),
                      ],
                    ),
                  ),

                  // 選擇器區域
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Stack(
                        children: [
                          // 中間高亮區
                          Align(
                            alignment: Alignment.center,
                            child: Container(
                              height: 40,
                              decoration: const BoxDecoration(
                                border: Border(
                                  top: BorderSide(color: Color(0xFFF5F5F5)),
                                  bottom: BorderSide(color: Color(0xFFF5F5F5)),
                                ),
                              ),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // 月份（依年份限制最大月份）
                              Expanded(
                                child: ListWheelScrollView.useDelegate(
                                  itemExtent: 40,
                                  useMagnifier: true,
                                  magnification: 1.0,
                                  physics: const FixedExtentScrollPhysics(),
                                  controller: FixedExtentScrollController(
                                    initialItem: selectedMonth - 1,
                                  ),
                                  onSelectedItemChanged: (index) {
                                    setModalState(() {
                                      selectedMonth = index + 1;
                                      // 月份改變 → 重新計算可選天數
                                      maxDays = visibleDaysFor(selectedYear, selectedMonth);
                                      if (selectedDay > maxDays) selectedDay = maxDays;
                                    });
                                  },
                                  childDelegate: ListWheelChildBuilderDelegate(
                                    childCount: visibleMonthsForYear(selectedYear),
                                    builder: (context, index) {
                                      final isSelected = (index + 1) == selectedMonth;
                                      return Center(
                                        child: Text(
                                          months[index],
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: isSelected ? Colors.black : const Color(0xFF9E9E9E),
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),

                              // 日期（依年份/月份限制最大天數）
                              Expanded(
                                child: ListWheelScrollView.useDelegate(
                                  itemExtent: 40,
                                  useMagnifier: true,
                                  magnification: 1.0,
                                  physics: const FixedExtentScrollPhysics(),
                                  controller: FixedExtentScrollController(
                                    initialItem: selectedDay - 1,
                                  ),
                                  onSelectedItemChanged: (index) {
                                    setModalState(() => selectedDay = index + 1);
                                  },
                                  childDelegate: ListWheelChildBuilderDelegate(
                                    childCount: maxDays,
                                    builder: (context, index) {
                                      final isSelected = (index + 1) == selectedDay;
                                      return Center(
                                        child: Text(
                                          '${index + 1}',
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: isSelected ? Colors.black : const Color(0xFF9E9E9E),
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),

                              // 年份（不能超過 youngestYear）
                              Expanded(
                                child: ListWheelScrollView.useDelegate(
                                  itemExtent: 40,
                                  useMagnifier: true,
                                  magnification: 1.0,
                                  physics: const FixedExtentScrollPhysics(),
                                  controller: FixedExtentScrollController(
                                    initialItem: years.indexOf(selectedYear),
                                  ),
                                  onSelectedItemChanged: (index) {
                                    setModalState(() {
                                      selectedYear = years[index];

                                      // 年份變動 → 先限月份，再限天數
                                      final maxMonth = visibleMonthsForYear(selectedYear);
                                      if (selectedMonth > maxMonth) selectedMonth = maxMonth;

                                      maxDays = visibleDaysFor(selectedYear, selectedMonth);
                                      if (selectedDay > maxDays) selectedDay = maxDays;
                                    });
                                  },
                                  childDelegate: ListWheelChildBuilderDelegate(
                                    childCount: years.length,
                                    builder: (context, index) {
                                      final y = years[index];
                                      final isSelected = y == selectedYear;
                                      return Center(
                                        child: Text(
                                          '$y',
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: isSelected ? Colors.black : const Color(0xFF9E9E9E),
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        ),
                                      );
                                    },
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
            );
          },
        );
      },
    );
  }

  void _showBodySheet() {
    final extra = ref.read(userProfileProvider)?.extra ?? {};
    List<String> parts = ['','',''];
    if (extra['body'] != null && extra['body']!.toString().contains('-')) {
      parts = extra['body']!.toString().split('-');
    }
    final bustController =
    TextEditingController(text: (parts[0]).replaceAll('cm', ''));
    final waistController =
    TextEditingController(text: (parts[1]).replaceAll('cm', ''));
    final hipController =
    TextEditingController(text: (parts[2]).replaceAll('cm', ''));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 標題 + 關閉
                Stack(
                  alignment: Alignment.center,
                  children: [
                    const Center(
                      child: Text(
                        '填写三围',
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      child: IconButton(
                        icon: const Icon(Icons.close),
                        iconSize: 20,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // 胸圍
                _buildBodyTextField('胸围', bustController),
                const SizedBox(height: 20),

                // 腰圍
                _buildBodyTextField('腰围', waistController),
                const SizedBox(height: 20),

                // 臀圍
                _buildBodyTextField('臀围', hipController),
                const SizedBox(height: 30),

                // 確定按鈕
                SizedBox(
                  width: 128,
                  height: 40,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFFFF4D67)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: () async {
                      final bust = '${int.tryParse(bustController.text) ?? 0}cm';
                      final waist = '${int.tryParse(waistController.text) ?? 0}cm';
                      final hip = '${int.tryParse(hipController.text) ?? 0}cm';

                      bool invalid(num? v) => v == null || v <= 0 || v > 999;

                      if (invalid(int.tryParse(bustController.text)) || invalid(int.tryParse(waistController.text)) || invalid(int.tryParse(hipController.text))) {
                        Fluttertoast.showToast(msg: '三圍每一項請輸入 1–999 的數值');
                        return;
                      }

                      // 存 extra (同時存三個欄位)
                      _updateExtra('bust', bust);
                      _updateExtra('waist', waist);
                      _updateExtra('hip', hip);

                      final bodySummary = '$bust-$waist-$hip'.replaceAll('cm', '');

                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => const Center(child: CircularProgressIndicator()),
                      );
                      try {
                        // 上傳到伺服器
                        final repo = ref.read(userRepositoryProvider);
                        await repo.updateMemberInfo({
                          'detail': {
                            'body': bodySummary,
                          }
                        });

                        // 更新本地資料
                        final currentUser = ref.read(userProfileProvider);
                        if (currentUser != null) {
                          final updatedExtra = Map<String, dynamic>.from(currentUser.extra ?? {});
                          updatedExtra['bust'] = bust;
                          updatedExtra['waist'] = waist;
                          updatedExtra['hip'] = hip;
                          updatedExtra['body'] = bodySummary;

                          final updatedUser = currentUser.copyWith(extra: updatedExtra);
                          ref.read(userProfileProvider.notifier).setUser(updatedUser);
                          await UserLocalStorage.saveUser(updatedUser);
                        }

                        // 提示成功
                        Fluttertoast.showToast(msg: '三围已更新');
                      } catch (e) {
                        Fluttertoast.showToast(msg: '更新失敗：$e');
                      } finally {
                        Navigator.of(context).pop(); // ✅ 關閉 loading dialog
                        Navigator.of(context).pop(); // ✅ 關閉 bottom sheet
                      }
                    },
                    child: const Text(
                      '确定',
                      style: TextStyle(
                        color: Color(0xFFFF4D67),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showJobSheet() {
    final extra = ref.read(userProfileProvider)?.extra ?? {};
    final controller = TextEditingController(text: extra['job'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 標題 + 關閉
                Stack(
                  alignment: Alignment.center,
                  children: [
                    const Center(
                      child: Text(
                        '填写职业',
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      child: IconButton(
                        icon: const Icon(Icons.close),
                        iconSize: 20,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // 輸入框
                SizedBox(
                  width: 340,
                  child: TextField(
                    controller: controller,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.text,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(12),
                    ],
                    decoration: InputDecoration(
                      hintText: '请输入职业',
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 保存按鈕
                SizedBox(
                  width: 128,
                  height: 40,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFFFF4D67)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: () async {
                      final job = controller.text.trim();
                      if (job.length > 12) {
                        Fluttertoast.showToast(msg: '職業最多輸入 12 個字元');
                        return;
                      }

                      if (job.isNotEmpty) {
                        _updateExtra('job', job);
                      }

                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) =>
                        const Center(child: CircularProgressIndicator()),
                      );

                      try {
                        // 上傳到伺服器
                        final repo = ref.read(userRepositoryProvider);
                        await repo.updateMemberInfo({
                          'detail': {
                            'job': job,
                          }
                        });

                        // 更新本地資料
                        final currentUser = ref.read(userProfileProvider);
                        if (currentUser != null) {
                          final updatedExtra = Map<String, dynamic>.from(currentUser.extra ?? {});
                          updatedExtra['job'] = job;

                          final updatedUser = currentUser.copyWith(extra: updatedExtra);
                          ref.read(userProfileProvider.notifier).setUser(updatedUser);
                          await UserLocalStorage.saveUser(updatedUser);
                        }


                        Fluttertoast.showToast(msg: '職業已更新');
                      } catch (e) {
                        Fluttertoast.showToast(msg: '更新失敗：$e');
                      } finally {
                        Navigator.of(context).pop(); // ✅ 關閉 loading dialog
                        Navigator.of(context).pop(); // ✅ 關閉 bottom sheet
                      }
                    },
                    child: const Text(
                      '确定',
                      style: TextStyle(
                        color: Color(0xFFFF4D67),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBodyTextField(String label, TextEditingController controller) {
    return Row(
      children: [
        SizedBox(width: 60, child: Text(label)),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(3),
            ],
            decoration: InputDecoration(
              suffixText: 'cm',
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
            ),
          ),
        ),
      ],
    );
  }



  Future<void> _showTagsSheet() async {

    final user = ref.read(userProfileProvider);
    final selectedTags = <String>{};
    final existing = user?.tags;
    if (existing != null && existing.isNotEmpty) {
      selectedTags.addAll(existing);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 標題 + Cancel / Done
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel', style: TextStyle(color: Colors.black54)),
                      ),
                      const Text('我的标签', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () async {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => const Center(
                                child: CircularProgressIndicator()),
                          );

                          try {
                            // 上傳到伺服器
                            final repo = ref.read(userRepositoryProvider);
                            await repo.updateMemberInfo({'tags': selectedTags.toList()});

                            // 更新本地資料
                            final user = ref.read(userProfileProvider);
                            final updatedUser = user?.copyWith(tags: selectedTags.toList());
                            if (updatedUser != null) {
                              ref.read(userProfileProvider.notifier).setUser(updatedUser);
                              await UserLocalStorage.saveUser(updatedUser);
                            }

                            Fluttertoast.showToast(msg: '標籤已更新');
                          } catch (e) {
                            Fluttertoast.showToast(msg: '更新失敗：$e');
                          } finally {
                            Navigator.of(context).pop(); // ✅ 關閉 loading dialog
                            Navigator.of(context).pop(); // ✅ 關閉 bottom sheet
                          }
                        },
                        child: const Text('Done', style: TextStyle(color: Color(0xFFFF4D67))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 300,
                    child: GridView.builder(
                      itemCount: allTags.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 2.4,
                      ),
                      itemBuilder: (context, index) {
                        final tag = allTags[index];
                        final isSelected = selectedTags.contains(tag);
                        return GestureDetector(
                          onTap: () {
                            setModalState(() {
                              if (isSelected) {
                                selectedTags.remove(tag);
                              } else {
                                if (selectedTags.length >= 5) {
                                  Fluttertoast.showToast(msg: '最多只能選擇5個標籤');
                                  return;
                                }
                                selectedTags.add(tag);
                              }
                            });
                          },
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFFF4D67) : Colors.white,
                              border: Border.all(
                                color: isSelected ? const Color(0xFFFF4D67) : Color(0xFFE0E0E0),
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black87,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        );
                      },
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

  Future<void> _loadAllTags() async {
    try {
      final repo = ref.read(userRepositoryProvider);
      final tags = await repo.fetchAllTags();
      setState(() {
        allTags = tags;
      });
    } catch (e) {
      debugPrint("❌ 抓取標籤失敗: $e");
    }
  }

  void _updateExtra(String key, String value) {
    final user = ref.read(userProfileProvider);
    final newExtra = {...(user?.extra ?? {}), key: value};
    final updatedUser = user?.copyWith(extra: newExtra);
    ref.read(userProfileProvider.notifier).state = updatedUser!;
  }

}