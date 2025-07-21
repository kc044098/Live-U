import 'package:djs_live_stream/features/wallet/payment_details_page.dart';
import 'package:flutter/material.dart';

class WalletDetailPage extends StatelessWidget {
  const WalletDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final transactions = [
      {'title': 'Paypal充值 - XXX币', 'time': '2025-04-13 12:00:00', 'amount': 20},
      {'title': '儲金充值 - XXX币', 'time': '2025-04-13 12:00:00', 'amount': 20},
      {'title': '給主播送禮物', 'time': '2025-04-13 12:00:00', 'amount': -10},
      {'title': '儲金充值 - XXX币', 'time': '2025-04-13 12:00:00', 'amount': 100},
      {'title': '和主播視頻連線', 'time': '2025-04-13 12:00:00', 'amount': -100},
      {'title': '和主播語音連線', 'time': '2025-04-13 12:00:00', 'amount': -20},
      {'title': '儲金充值 - XXX币', 'time': '2025-04-13 12:00:00', 'amount': 20},
      {'title': '儲金充值 - XXX币', 'time': '2025-04-13 12:00:00', 'amount': 20},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('明細', style: TextStyle(fontSize: 16, color: Colors.black)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _showFilterBottomSheet(context);
            },
            child: const Text('篩選', style: TextStyle(color: Colors.pinkAccent, fontSize: 16)),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: transactions.length,
        separatorBuilder: (_, __) => const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Divider(height: 1),
        ),
        itemBuilder: (context, index) {
          final item = transactions[index];
          final num amount = item['amount'] as num;
          final isPositive = amount >= 0;

          return ListTile(
            title: Text(item['title'].toString(), style: const TextStyle(fontSize: 16)),
            subtitle: Text(item['time'].toString(), style: const TextStyle(fontSize: 14, color: Colors.grey)),
            trailing: Text(
              '${isPositive ? '+' : ''}$amount',
              style: const TextStyle(fontSize: 18, color: Colors.black),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PaymentDetailsPage(
                    amount: 100.0,
                    coinAmount: 1000,
                    paymentMethod: '佣金充值',
                    time: '2025-02-02 12:00:00',
                    orderId: '35481234567890',
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        int selectedIndex = 0;
        final filterLabels = [
          '全部', '充值', '送禮', '收禮', '視頻消費', '語音消費', '活動獎勵',
        ];

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '選擇交易類型',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: List.generate(filterLabels.length, (index) {
                      final label = filterLabels[index];
                      final selected = selectedIndex == index;

                      return GestureDetector(
                        onTap: () {
                          setModalState(() {
                            selectedIndex = index;
                          });
                          // TODO: 在這裡也可以呼叫 setState 更新主頁顯示內容
                        },
                        child: Container(
                          height: 64,
                          width: 116,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: selected ? const Color(0xFFFFF0F0) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: selected ? Colors.pink : const Color(0xFFE0E0E0)),
                          ),
                          child: Center(
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: 14,
                                color: selected ? Colors.pink : Colors.black,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
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