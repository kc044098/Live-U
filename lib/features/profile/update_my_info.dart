import 'package:flutter/material.dart';

class UpdateMyInfoPage extends StatelessWidget {
  const UpdateMyInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('完善資料'),
      ),
      body: const Center(
        child: Text(
          '這裡是 UpdateMyInfoPage\n之後可加上表單與詳細內容',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
