import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'dart:typed_data';

import '../profile/profile_controller.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});
  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final ImagePicker _picker = ImagePicker();
  final List<XFile?> _mediaFiles = [null, null, null];
  final List<Uint8List?> _thumbnails = [null, null, null];
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('只允許上傳 JPG / JPEG / PNG 圖片')),
      );
      return;
    }

    // 讀取縮圖
    final bytes = await file.readAsBytes();
    final base64Thumb = base64Encode(bytes);

    setState(() {
      _mediaFiles[tappedIndex] = file;
      _thumbnails[tappedIndex] = bytes;
    });

    // 圖片存到 extra（如 photo1、photo2、photo3）
    final key = 'photo${tappedIndex + 1}';
    _updateExtra(key, base64Thumb);


    // 如果是第一張圖片，設定為預設頭像
    if (tappedIndex == 0) {
      _updateExtra('localAvatar', file.path);
    }
  }


  bool _isVideo(XFile file) {
    final path = file.path.toLowerCase();
    return path.endsWith('.mp4') || path.endsWith('.mov') || path.endsWith('.avi');
  }

  @override
  void initState() {
    super.initState();
    final user = ref.read(userProfileProvider);
    final extra = user?.extra ?? {};

    for (int i = 0; i < 3; i++) {
      final key = 'photo${i + 1}';
      final base64Image = extra[key] as String?;
      if (base64Image != null && base64Image.isNotEmpty) {
        try {
          final bytes = base64Decode(base64Image);
          _thumbnails[i] = bytes;
          _mediaFiles[i] = null;
        } catch (e) {
          debugPrint('解碼 $key 失敗: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    final extra = ref.watch(userProfileProvider)?.extra ?? {};
    String displayBody = '';
    if (extra['body'] != null && extra['body']!.toString().contains('-')) {
      final parts = extra['body']!.toString().split('-');
      if (parts.length == 3) {
        displayBody = '胸围 ${parts[0]} 腰围 ${parts[1]} 臀围 ${parts[2]}';
      }
    }
    final profileItems = [
      {'label': '昵称', 'value': ref.watch(userProfileProvider)?.displayName ?? ''},
      {'label': '性别', 'value': extra['gender'] ?? '女'},
      {'label': '生日', 'value': extra['birthdayAge'] ?? ''},
      {'label': '身高', 'value': extra['height'] ?? ''},
      {'label': '体重', 'value': extra['weight'] ?? ''},
      {'label': '三围', 'value': displayBody.isNotEmpty ? displayBody : '胸围 0 腰围 0 臀围 0'},
      {'label': '城市', 'value': extra['city'] ?? '武汉'},
      {'label': '工作', 'value': extra['job'] ?? '人事'},
      {'label': '个人标签', 'value': extra['tags'] ?? '立即添加'},
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
          // 📸 照片 / 影片 區域
          Row(
            children: List.generate(3, (index) {
              final file = _mediaFiles[index];
              final isVideo = file != null && _isVideo(file);
              final thumbnail = _thumbnails[index];
              return Expanded(
                child: GestureDetector(
                  onTap: () => _pickMedia(index),
                  child: Container(
                    margin: EdgeInsets.only(right: index < 2 ? 12 : 0),
                    height: 100,
                    child: Stack(
                      children: [
                        // 背景圖片
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                            image: (file != null && !isVideo)
                                ? DecorationImage(
                              image: FileImage(File(file.path)),
                              fit: BoxFit.cover,
                            )
                                : (_thumbnails[index] != null
                                ? DecorationImage(
                              image: MemoryImage(_thumbnails[index]!),
                              fit: BoxFit.cover,
                            )
                                : null),
                          ),
                          child: (file == null && _thumbnails[index] == null)
                              ? const Center(
                            child: Icon(Icons.add, size: 32, color: Colors.grey),
                          )
                              : null,
                        ),

                        // 刪除按鈕（file 或縮圖有值時才出現）
                        if (file != null || _thumbnails[index] != null)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _mediaFiles[index] = null;
                                  _thumbnails[index] = null;

                                  // 清除 extra 中對應的圖片
                                  _updateExtra('photo${index + 1}', '');
                                  if (index == 0) _updateExtra('localAvatar', '');
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

          Container(
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
                          Text(
                            item['value']!,
                            style: const TextStyle(fontSize: 14, color: Colors.black87),
                          ),
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
                          default:
                          // 其他欄位後續再做
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
          ),
        ],
      ),
    );
  }

  void _showNicknameSheet() {
    final user = ref.read(userProfileProvider);
    final controller = TextEditingController(text: user?.displayName ?? "");

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return Padding(
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
                  onPressed: () {
                    final nickname = controller.text.trim();
                    if (nickname.isNotEmpty) {
                      final user = ref.read(userProfileProvider);
                      ref.read(userProfileProvider.notifier)
                          .state = user!.copyWith(displayName: nickname);
                    }
                    Navigator.pop(context);
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return Padding(
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
                  onPressed: () {
                    final height = '${int.tryParse(controller.text) ?? 0}cm';
                    _updateExtra('height', height);
                    Navigator.pop(context);
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
        );
      },
    );
  }

  void _showWeightSheet() {
    final extra = ref.read(userProfileProvider)?.extra ?? {};
    final controller = TextEditingController(text: (extra['weight'] ?? '').replaceAll('磅', ''),);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return Padding(
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
                    backgroundColor: Colors.white, // 白色背景
                    side: const BorderSide(color: Color(0xFFFF4D67)), // 紅色外框
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30), // 保持圓角
                    ),
                  ),
                  onPressed: () {
                    final weight = '${int.tryParse(controller.text) ?? 0}磅';
                    _updateExtra('weight', weight);
                    Navigator.pop(context);
                  },
                  child: const Text(
                    '保存',
                    style: TextStyle(
                      color: Color(0xFFFF4D67), // 文字紅色
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
            ],
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
                          onTap: () {
                            setState(() {
                              final tempDate =
                              DateTime(selectedYear, selectedMonth, selectedDay);

                              // 計算年齡
                              final now = DateTime.now();
                              int age = now.year - tempDate.year;
                              if (now.month < tempDate.month ||
                                  (now.month == tempDate.month &&
                                      now.day < tempDate.day)) {
                                age--;
                              }
                              _updateExtra('birthdayAge', '$age岁');
                              _selectedDate = tempDate;
                            });
                            Navigator.pop(context);
                          },
                          child: const Text('Done',
                              style: TextStyle(
                                  color: Color(0xFFFF4D67),
                                  fontSize: 16,)),
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
    final bustController =
    TextEditingController(text: (extra['bust'] ?? '0cm').replaceAll('cm', ''));
    final waistController =
    TextEditingController(text: (extra['waist'] ?? '0cm').replaceAll('cm', ''));
    final hipController =
    TextEditingController(text: (extra['hip'] ?? '0cm').replaceAll('cm', ''));

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return Padding(
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
                  onPressed: () {
                    final bust = '${int.tryParse(bustController.text) ?? 0}cm';
                    final waist = '${int.tryParse(waistController.text) ?? 0}cm';
                    final hip = '${int.tryParse(hipController.text) ?? 0}cm';

                    // 存 extra (同時存三個欄位)
                    _updateExtra('bust', bust);
                    _updateExtra('waist', waist);
                    _updateExtra('hip', hip);

                    final bodySummary = '$bust-$waist-$hip'.replaceAll('cm', '');
                    _updateExtra('body', bodySummary);

                    Navigator.pop(context);
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
        );
      },
    );
  }

  void _showJobSheet() {
    final extra = ref.read(userProfileProvider)?.extra ?? {};
    final controller = TextEditingController(text: extra['job'] ?? '');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return Padding(
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
                  onPressed: () {
                    final job = controller.text.trim();
                    if (job.isNotEmpty) {
                      _updateExtra('job', job);
                    }
                    Navigator.pop(context);
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

  void _updateExtra(String key, String value) {
    final user = ref.read(userProfileProvider);
    final newExtra = {...(user?.extra ?? {}), key: value};
    final updatedUser = user?.copyWith(extra: newExtra);
    ref.read(userProfileProvider.notifier).state = updatedUser!;
  }

}
