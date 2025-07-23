import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../profile/profile_controller.dart';
import '../wallet/withdraw_page.dart';

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
    final user = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('我的邀請',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black,
            )),
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
                            backgroundImage: user?.photoURL != null
                                ? NetworkImage(user!.photoURL!)
                                : null,
                            child: user?.photoURL == null
                                ? const Icon(Icons.person, size: 28)
                                : null,
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
                              child: const Text(
                                '提現',
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
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('累計佣金獎勵',
                                style: TextStyle(fontSize: 14, color: Colors.black54),
                              ),
                              SizedBox(height: 8),
                              Text(
                                '\$ 100.00',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(left: 36),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('可提現金額',
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.black54),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  '\$ 100.00',
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black),
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
              tabs: const [
                Tab(text: '我的獎勵'),
                Tab(text: '我邀請的人'),
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

class RewardTabView extends StatefulWidget {
  const RewardTabView({super.key});

  @override
  State<RewardTabView> createState() => _RewardTabViewState();
}

class _RewardTabViewState extends State<RewardTabView> {
  int selectedIndex = 0;

  final tabs = ['今日', '昨日', '累計'];



  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 上方切換按鈕
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: List.generate(tabs.length, (index) {
              final isSelected = selectedIndex == index;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedIndex = index;
                    });
                  },
                  child: Container(
                    width: 70,
                    height: 30,
                    decoration: BoxDecoration(
                      color: isSelected ? Color(0xFFFFEFEF) : Color(0xFFFAFAFA),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      tabs[index],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Color(0xFFFF4D67) : Color(0xFF888888),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),

        // 下方資料區塊
        Expanded(
          child: _buildContentForSelectedIndex(),
        ),
      ],
    );
  }

  Widget _buildContentForSelectedIndex() {
    // 模擬每種 tab 對應的金額與次數
    final rewardStats = [
      RewardStat(amount: 10.0, times: 3),  // 今日
      RewardStat(amount: 20.0, times: 5),  // 昨日
      RewardStat(amount: 100.0, times: 15), // 累計
    ];

    final currentStat = rewardStats[selectedIndex];

    return Column(
      children: [
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
                    const Text('佣金獎勵', style: TextStyle(fontSize: 12, color: Color(0xFFB1A3A9))),
                    const SizedBox(height: 8),
                    Text(
                      '\$ ${currentStat.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text('獎勵次數', style: TextStyle(fontSize: 12, color: Color(0xFFB1A3A9))),
                    const SizedBox(height: 8),
                    Text(
                      '\$ ${currentStat.times.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),
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
                    children: const [
                      Expanded(
                        child: Text(
                          '用戶',
                          textAlign: TextAlign.start,
                          style: TextStyle(fontSize: 14, color: Color(0xFF9E9E9E), fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '充值獎勵',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: Color(0xFF9E9E9E), fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),

                // 假資料列表
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    itemCount: 8,
                    itemBuilder: (context, index) {
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            // 頭像
                            const CircleAvatar(
                              radius: 15,
                              backgroundImage: NetworkImage('https://i.imgur.com/BoN9kdC.png'), // 假資料
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                '帥氣的小哥哥',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                            const Text(
                              '\$ 1.00',
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      );
                    },
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
}

class RewardStat {
  final double amount;
  final int times;

  RewardStat({required this.amount, required this.times});
}

class InviteTabView extends StatefulWidget {
  const InviteTabView({super.key});

  @override
  State<InviteTabView> createState() => _InviteTabViewState();
}

class _InviteTabViewState extends State<InviteTabView> {
  int selectedIndex = 0;
  final tabs = ['今日', '昨日', '累計'];

  final inviteCounts = [20, 50, 100]; // 假資料

  @override
  Widget build(BuildContext context) {
    final currentCount = inviteCounts[selectedIndex];

    return Column(
      children: [
        // 🔘 切換按鈕
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
                    width: 70,
                    height: 30,
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFFFEFEF) : const Color(0xFFFAFAFA),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      tabs[index],
                      style: TextStyle(
                        fontSize: 16,
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

        // 🟣 上方粉紅區塊：顯示邀請人數
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFFEEEF4),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Column(
            children: [
              const Text('邀請人數（人）', style: TextStyle(fontSize: 12, color: Color(0xFFB1A3A9))),
              const SizedBox(height: 8),
              Text(
                '$currentCount',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // 📝 列表區塊
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
                  child: const Row(
                    children: [
                      Expanded(
                        child: Text(
                          '用戶',
                          textAlign: TextAlign.start,
                          style: TextStyle(fontSize: 14, color: Color(0xFF9E9E9E), fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '註冊時間',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: Color(0xFF9E9E9E), fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),

                // 用戶資料
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: 9,
                    itemBuilder: (_, index) {
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            // 頭像
                            const CircleAvatar(
                              radius: 15,
                              backgroundImage: NetworkImage('https://i.imgur.com/wedIDwN.jpeg'), // 假資料
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                '淘氣的小弟弟',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                            Text(
                              '2025-02-02 12:00:00',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      );
                    },
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
}
