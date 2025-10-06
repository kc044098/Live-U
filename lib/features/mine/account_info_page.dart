import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../l10n/l10n.dart';
import 'modify_password_page.dart';

class AccountInfoPage extends StatelessWidget {
  final ImageProvider avatarImage;
  final String modifyType;

  const AccountInfoPage({
    super.key,
    required this.avatarImage,
    required this.modifyType,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final modifyTitle = modifyType == 'account'
        ? s.changeAccountPassword
        : s.changeEmailPassword;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(s.accountInfoTitle,
            style: const TextStyle(fontSize: 16, color: Colors.black)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 40),

          // 頭像
          CircleAvatar(
            radius: 50,
            backgroundImage: avatarImage,
          ),

          const SizedBox(height: 30),
          const Divider(height: 1 , indent: 60, endIndent: 60, color: Color(0xFFEEEEEE)),
          const SizedBox(height: 20),

          // 修改密碼選項
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ListTile(
              leading: const Icon(Icons.lock_outline, color: Colors.black54),
              title: Text(modifyTitle, style: const TextStyle(fontSize: 16)),
              trailing: const Icon(Icons.chevron_right, color: Colors.black38),
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ModifyPasswordPage()),
                );
                if (result == true) {
                  Fluttertoast.showToast(msg: s.passwordResetSuccess);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
