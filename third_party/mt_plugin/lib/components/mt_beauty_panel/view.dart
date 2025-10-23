import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:get/get.dart';
import 'package:mt_plugin/components/mt_beauty_panel/state.dart';

import 'logic.dart';
import 'panel/mt_beauty_panel.dart';

class MtBeautyPanelContainer extends GetView {

  final logic = Get.put(MtBeautyPanelLogic());

  final state = Get.find<MtBeautyPanelLogic>().state;

  @override
  Widget build(BuildContext context) {
    Widget getAndroidCameraView() {
      if (Theme.of(context).platform == TargetPlatform.android) {
        return AndroidView(
          viewType: "CameraView",
          creationParamsCodec: const StandardMessageCodec(),
        );
      } else if (Theme.of(context).platform == TargetPlatform.iOS) {
        return UiKitView(
            viewType: "CameraView",
            creationParamsCodec: const StandardMessageCodec());
      } else {
        return Text("暂时不支持该设备，敬请期待");
      }
    }

    return Scaffold(
      body: Container(
        color: Colors.black,
        alignment: Alignment.bottomCenter,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: <Widget>[
            Listener(
              onPointerDown: (event) => logic.backPanel(),
              child: Container(child: getAndroidCameraView()),
            ),
            Container(child: MtBeautyPanel(state)),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                child: InkWell(
                  onTap: () => logic.show(),
                  child: Obx(() => Visibility(
                        visible: (state.panelState.value & HIDE != 0),
                        child: Image.asset(
                          "mt_icon/icon_beauty_white.png",
                          package: "mt_plugin",
                          height: 44,
                          width: 44,
                          fit: BoxFit.cover,
                        ),
                      )),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
