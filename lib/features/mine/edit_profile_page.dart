import 'dart:async';
import 'dart:io';

import 'package:djs_live_stream/features/mine/user_repository_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';

import 'dart:typed_data';
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

  Future<void> _pickMedia(int tappedIndex) async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 100,
    );
    if (file == null) return;

    final allowedExtensions = ['jpg', 'jpeg', 'png'];
    final ext = file.path.split('.').last.toLowerCase();
    if (!allowedExtensions.contains(ext)) {
      Fluttertoast.showToast(msg: "只允許上傳 JPG / JPEG / PNG 圖片");
      return;
    }

    setState(() {
      _mediaFiles[tappedIndex] = file;
    });

    _updatePhoto(tappedIndex, file.path);
  }

  /// 新增或更新圖片
  void _updatePhoto(int index, String filePath) {
    final user = ref.read(userProfileProvider);
    final currentList = List<String>.from(user?.photoURL ?? []);

    if (index < currentList.length) {
      currentList[index] = filePath;
    } else {
      while (currentList.length < index) {
        currentList.add('');
      }
      currentList.add(filePath);
    }

    _savePhotoList(currentList);
  }

  /// 刪除照片並自動前移
  Future<void> _deletePhotoByUrl(String url) async {
    final user = ref.read(userProfileProvider);
    if (user == null) return;

    final oldList = List<String>.from(user.photoURL);
    final newList = List<String>.from(oldList)..remove(url);

    // ① 樂觀更新（立即讓 UI 消失）
    _applyOptimisticAvatarList(newList);

    // ② 背景同步（不彈 Dialog、不阻塞）
    final svc = ref.read(backgroundApiServiceProvider);
    try {
      await svc.updateMemberInfoQueued({'avatar': newList});
      // 成功就什麼都不用做
    } catch (e, st) {
      // ③ 失敗回滾（還原 UI）
      _rollbackAvatarList(oldList);
      debugPrint('刪除頭像背景同步失敗：$e');
    }
  }

  // 同步更新到 user model
  Future<void> _savePhotoList(List<String> list) async {
    // 清理
    final clean = List<String>.from(list)..removeWhere((e) => e.isEmpty);

    // 取 cdn base
    final me = ref.read(userProfileProvider);
    final cdn = me?.cdnUrl ?? '';

    // ① 先把「可立即顯示」的部份（已是 http 的）直接套用到 UI
    final immediate = <String>[];
    final localFiles = <String>[];
    for (final p in clean) {
      if (p.startsWith('http')) {
        immediate.add(p);
      } else {
        localFiles.add(p); // 這些要上傳
      }
    }
    _applyOptimisticAvatarList([...immediate, ...localFiles]); // 預先顯示本地檔（UI 會用 FileImage）

    // ② 背景：只上傳本地檔案，成功後得到雲端 URL，合併 & 同步到後端
    final svc = ref.read(backgroundApiServiceProvider);
    try {
      final uploaded = await svc.uploadAvatarsAndUpdate(
        paths: clean,      // 混和清單：svc 內部會分辨 http / local
        cdnBase: cdn,
      );
      // 背景成功，同步 userProvider 由服務內處理；這裡不用再動
    } catch (e, st) {
      // ③ 失敗：回滾（你可選擇只回滾本次改動，或全數回滾；這裡用「保留原狀」）
      debugPrint('背景上傳/更新失敗：$e');
      if (me != null) _rollbackAvatarList(me.photoURL);
    }
  }

  void _applyOptimisticAvatarList(List<String> newList) {
    // 更新 Provider + 本地存檔（不阻塞 UI）
    final currentUser = ref.read(userProfileProvider);
    if (currentUser == null) return;

    final updated = currentUser.copyWith(photoURL: newList);
    ref.read(userProfileProvider.notifier).setUser(updated);
    // 非阻塞保存（不要等待）
    unawaited(UserLocalStorage.saveUser(updated));

    // 同步刷新本頁縮略圖陣列（避免空白）
    if (mounted) {
      setState(() {
        // 把 _mediaFiles 跟著移位，單純清掉對應格子即可
        for (int i = 0; i < _mediaFiles.length; i++) {
          _mediaFiles[i] = null; // 讓 UI 重新由 photoURL 取圖，不依賴舊的 XFile
        }
      });
    }
  }

  void _rollbackAvatarList(List<String> oldList) {
    final currentUser = ref.read(userProfileProvider);
    if (currentUser == null) return;

    final updated = currentUser.copyWith(photoURL: oldList);
    ref.read(userProfileProvider.notifier).setUser(updated);
    unawaited(UserLocalStorage.saveUser(updated));
    if (mounted) setState(() {}); // 觸發重建
  }

  bool _isVideo(XFile file) {
    final path = file.path.toLowerCase();
    return path.endsWith('.mp4') || path.endsWith('.mov') || path.endsWith('.avi');
  }

  @override
  void initState() {
    super.initState();
    final user = ref.read(userProfileProvider);
    final photos = user?.photoURL ?? [];
    for (int i = 0; i < photos.length && i < 3; i++) {
      if (photos[i].isNotEmpty && !photos[i].startsWith('http')) {
        // 只有本地檔案才存入 XFile
        _mediaFiles[i] = XFile(photos[i]);
      } else {
        _mediaFiles[i] = null; // 網路圖片不轉成本地檔案
      }
    }

    // 伺服器獲取的所有tags
    _loadAllTags();
  }

  @override
  Widget build(BuildContext context) {
    final extra = ref.watch(userProfileProvider)?.extra ?? {};

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
              final isVideo = file != null && _isVideo(file);

              return Expanded(
                child: GestureDetector(
                  onTap: () => _pickMedia(index),
                  child: Container(
                    margin: EdgeInsets.only(right: index < 2 ? 12 : 0),
                    height: 100,
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                            image: (() {
                              final user = ref.read(userProfileProvider);
                              final photos = user?.photoURL ?? [];
                              final photoUrl = (index < photos.length) ? photos[index] : '';

                              if (file != null && !isVideo && File(file.path).existsSync()) {
                                return DecorationImage(image: FileImage(File(file.path)), fit: BoxFit.cover);
                              } else if (photoUrl.startsWith('http')) {
                                return DecorationImage(image: NetworkImage(photoUrl), fit: BoxFit.cover);
                              }
                              return null;
                            })(),
                          ),
                          child: (() {
                            final user = ref.read(userProfileProvider);
                            final photos = user?.photoURL ?? [];
                            final photoUrl = (index < photos.length) ? photos[index] : '';
                            final hasImage = (file != null) || photoUrl.startsWith('http');
                            return hasImage
                                ? null
                                : const Center(child: Icon(Icons.add, size: 32, color: Colors.grey));
                          })(),
                        ),
                        // 右上角刪除 X
                        if (file != null || (ref.read(userProfileProvider)?.photoURL.length ?? 0) > index &&
                            ref.read(userProfileProvider)!.photoURL[index].startsWith('http'))
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () {
                                final url = ref.read(userProfileProvider)?.photoURL[index];
                                setState(() {
                                  _mediaFiles[index] = null;
                                  if (url != null) {
                                    _deletePhotoByUrl(url);
                                  }
                                });
                              },
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
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
                      if (nickname.length > 20) {
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
    int selectedYear = _selectedDate.year;
    int selectedMonth = _selectedDate.month;
    int selectedDay = _selectedDate.day;

    final years = List.generate(100, (index) => DateTime.now().year - index);
    final months = [
      "January","February","March","April","May","June",
      "July","August","September","October","November","December"
    ];

    int daysInMonth(int year, int month) {
      return DateTime(year, month + 1, 0).day;
    }

    int maxDays = daysInMonth(selectedYear, selectedMonth);

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
                            final tempDate = DateTime(
                                selectedYear, selectedMonth, selectedDay);

                            // 計算年齡
                            final now = DateTime.now();
                            int age = now.year - tempDate.year;
                            if (now.month < tempDate.month ||
                                (now.month == tempDate.month &&
                                    now.day < tempDate.day)) {
                              age--;
                            }
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (_) => const Center(child: CircularProgressIndicator()),
                            );
                            try {
                              // 呼叫後端 API 上傳年齡
                              final repo = ref.read(userRepositoryProvider);
                              await repo.updateMemberInfo({
                                'detail': {
                                  'age': '$age',
                                }
                              });

                              // 更新本地 userModel 的 extra
                              final currentUser = ref.read(userProfileProvider);
                              if (currentUser != null) {
                                final updatedExtra = Map<String, dynamic>.from(
                                    currentUser.extra ?? {});
                                updatedExtra['age'] = '$age岁';
                                _updateExtra('age', '$age岁');

                                final updatedUser =
                                currentUser.copyWith(extra: updatedExtra);
                                ref
                                    .read(userProfileProvider.notifier)
                                    .setUser(updatedUser);
                                await UserLocalStorage.saveUser(updatedUser);
                              }

                              _selectedDate = tempDate;
                              Fluttertoast.showToast(msg: '年齡已更新');
                            } catch (e) {
                              Fluttertoast.showToast(msg: '年齡更新失敗：$e');
                            }
                            Navigator.of(context).pop(); // ✅ 關閉 loading dialog
                            Navigator.of(context).pop(); // ✅ 關閉 bottom sheet
                          },
                          child: const Text('Done',
                              style: TextStyle(
                                color: Color(0xFFFF4D67),
                                fontSize: 16,
                              )),
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
                          // 分隔線置中
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
                              // 月份
                              Expanded(
                                child: ListWheelScrollView.useDelegate(
                                  itemExtent: 40,
                                  useMagnifier: true,
                                  magnification: 1.0,
                                  physics: const FixedExtentScrollPhysics(),
                                  controller: FixedExtentScrollController(
                                      initialItem: selectedMonth - 1),
                                  onSelectedItemChanged: (index) {
                                    setModalState(() {
                                      selectedMonth = index + 1;
                                      maxDays = daysInMonth(selectedYear, selectedMonth);
                                      if (selectedDay > maxDays) selectedDay = maxDays;
                                    });
                                  },
                                  childDelegate: ListWheelChildBuilderDelegate(
                                    childCount: months.length,
                                    builder: (context, index) {
                                      final isSelected = index == selectedMonth - 1;
                                      return Center(
                                        child: Text(
                                          months[index],
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: isSelected
                                                ? Colors.black
                                                : const Color(0xFF9E9E9E),
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),

                              // 日期
                              Expanded(
                                child: ListWheelScrollView.useDelegate(
                                  itemExtent: 40,
                                  useMagnifier: true,
                                  magnification: 1.0,
                                  physics: const FixedExtentScrollPhysics(),
                                  controller: FixedExtentScrollController(
                                      initialItem: selectedDay - 1),
                                  onSelectedItemChanged: (index) {
                                    setModalState(() => selectedDay = index + 1);
                                  },
                                  childDelegate: ListWheelChildBuilderDelegate(
                                    childCount: maxDays,
                                    builder: (context, index) {
                                      final isSelected = index == selectedDay - 1;
                                      return Center(
                                        child: Text(
                                          '${index + 1}',
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: isSelected
                                                ? Colors.black
                                                : const Color(0xFF9E9E9E),
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),

                              // 年份
                              Expanded(
                                child: ListWheelScrollView.useDelegate(
                                  itemExtent: 40,
                                  useMagnifier: true,
                                  magnification: 1.0,
                                  physics: const FixedExtentScrollPhysics(),
                                  controller: FixedExtentScrollController(
                                      initialItem: years.indexOf(selectedYear)),
                                  onSelectedItemChanged: (index) {
                                    setModalState(() {
                                      selectedYear = years[index];
                                      maxDays = daysInMonth(selectedYear, selectedMonth);
                                      if (selectedDay > maxDays) selectedDay = maxDays;
                                    });
                                  },
                                  childDelegate: ListWheelChildBuilderDelegate(
                                    childCount: years.length,
                                    builder: (context, index) {
                                      final isSelected = years[index] == selectedYear;
                                      return Center(
                                        child: Text(
                                          '${years[index]}',
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: isSelected
                                                ? Colors.black
                                                : const Color(0xFF9E9E9E),
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
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