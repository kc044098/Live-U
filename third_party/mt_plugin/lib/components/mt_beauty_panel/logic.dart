import 'package:get/get.dart';
import 'package:mt_plugin/components/mt_beauty_panel/state.dart';

class MtBeautyPanelLogic extends GetxController {
  MtBeautyPanelState state = MtBeautyPanelState.instance;

  //切换面板
  void switchPanel(int panel) {
    state.panelState(SHOWED | panel);
  }

  void backPanel() {
    print("状态：${state.panelState.value}");
    if ((state.panelState.value & MODE_SELECT) != 0) {
      print("隐藏");
      hide();
      return;
    }
    if ((state.panelState.value & MEI_XIN) != 0 ||
        (state.panelState.value & MEI_YAN) != 0 ||
        (state.panelState.value & FILTER) != 0 ||
        (state.panelState.value & QUICK_BEAUTY) != 0 ||
        (state.panelState.value & CUTE) != 0) {
      print("返回模式选择");
      switchPanel(MODE_SELECT);
      return;
    }
    if ((state.panelState.value & GIFT) != 0 ||
        (state.panelState.value & ATMOSPHERE) != 0 ||
        (state.panelState.value & MASK) != 0 ||
        (state.panelState.value & STICKERS) != 0 ||
        (state.panelState.value & WATERMARK) != 0 ||
        (state.panelState.value & PORTRAIT) != 0 ||
        (state.panelState.value & GREEN_SCREEN) != 0
    ) {
    print("返回AR");
    switchPanel(CUTE);
    return;
    }
  }

  void hide() {
    state.panelState(HIDE);
  }

  void show() {
    if ((state.panelState.value & HIDE) != 0) {
      switchPanel(MODE_SELECT);
    } else {
      print("返回上级页面");
      backPanel();
    }
  }
}
