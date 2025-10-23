import 'package:get/get.dart';
import 'package:mt_plugin/bean/watermarks.dart';
import 'package:mt_plugin/components/watermark_view/state.dart';
import 'package:mt_plugin/mt_plugin.dart';


class WaterMarkLogic extends GetxController {
  final WaterMarkState state = WaterMarkState();

  void clickWater(Rx<WaterMark> item) {
    WaterMark itemValue = item.value;

    print(itemValue.name);
    print(itemValue.x);
    print(itemValue.y);

    state.items.forEach((element) {
      element.update((value) {
        value?.isSelected = false;
      });
    });

    item.update((value) {
      value?.isSelected = true;
    });
    state.canCancel(true);
    MtPlugin.setWatermarkName(
        itemValue.name, itemValue.x, itemValue.y, itemValue.ratio);
  }

  void cancelAll() {
    state.canCancel(false);
    state.items.forEach((element) {
      element.update((value) {
        value?.isSelected = false;
      });
    });
    MtPlugin.setWatermarkName("", 0, 0, 0);
  }
}
