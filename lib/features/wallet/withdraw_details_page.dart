import 'package:flutter/material.dart';

class WithdrawDetailsPage extends StatelessWidget {
  const WithdrawDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> records = [
      {'method': 'Visa', 'date': '2025-04-13 12:00:00', 'amount': '- 100.00'},
      {'method': 'Paypal', 'date': '2025-04-13 12:00:00', 'amount': '- 100.00'},
      {'method': 'Apple錢包', 'date': '2025-04-13 12:00:00', 'amount': '- 100.00'},
      {'method': 'Visa', 'date': '2025-04-13 12:00:00', 'amount': '- 100.00'},
      {'method': 'Paypal', 'date': '2025-04-13 12:00:00', 'amount': '- 100.00'},
      {'method': 'Apple錢包', 'date': '2025-04-13 12:00:00', 'amount': '- 100.00'},
      {'method': 'Visa', 'date': '2025-04-13 12:00:00', 'amount': '- 100.00'},
      {'method': 'Paypal', 'date': '2025-04-13 12:00:00', 'amount': '- 100.00'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '提現明細',
          style: TextStyle(fontSize: 16, color: Colors.black),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: Colors.white,
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: records.length,
        separatorBuilder: (_, __) => const Divider(
          height: 24,
          thickness: 1,
          color: Color(0xFFEDEDED),
        ),
        itemBuilder: (context, index) {
          final item = records[index];
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '提現到${item['method']}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['date']!,
                      style: const TextStyle(fontSize: 14, color: Color(0xFF999999)),
                    ),
                  ],
                ),
              ),
              Text(
                item['amount']!,
                style: const TextStyle(fontSize: 18),
              ),
            ],
          );
        },
      ),
    );
  }
}