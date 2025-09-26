import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../widgets/cached_network_image.dart';

class IncomingCallBanner extends StatelessWidget {
  final String callerName;
  final String avatarUrl;
  final int flag; // 1=video, 2=voice
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const IncomingCallBanner({
    super.key,
    required this.callerName,
    required this.avatarUrl,
    required this.flag,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return IgnorePointer(
      ignoring: false,
      child: Stack(
        children: [
          // 點擊空白不關閉（如果想可包一層 GestureDetector）
          Align(
            alignment: Alignment.topCenter,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.only(top: top > 0 ? 6 : 12, left: 12, right: 12),
                child: Material(
                  elevation: 8,
                  color: Colors.black.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 76,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        buildAvatarCircle(url: avatarUrl, radius: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                callerName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                flag == 1 ? '邀請你進行視頻通話...' : '邀請你進行語音通話...',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // 拒接
                        GestureDetector(
                          onTap: onReject,
                          child: SvgPicture.asset('assets/call_end.svg', width: 36, height: 36),
                        ),
                        const SizedBox(width: 10),
                        // 接聽
                        GestureDetector(
                          onTap: onAccept,
                          child: SvgPicture.asset(
                            flag == 1 ? 'assets/call_live_accept.svg' : 'assets/call_voice_accept.svg',
                            width: 36, height: 36,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
