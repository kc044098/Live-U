import 'package:get/get.dart';
import 'package:mt_plugin/bean/green_screens.dart';
import 'package:mt_plugin/mt_plugin.dart';

import '../../dio_utils.dart';
import '../../file_tools.dart';
import 'state.dart';

class GreenScreenLogic extends GetxController {
  final state = GreenScreenState();

  ///点击某个效果
  void clickItem(Rx<GreenScreen> item) {
    if (item.value.isDownloading == false && item.value.downloaded == false) {
      //如果不是下载状态且没有下载过
      item.update((value) {
        value?.isDownloading = true;
      });

      DioUtils.instance.downloadGreenScreen(item.value.dir, (dynamic) {
        item.update((value) {
          value?.isDownloading = false;
          value?.setDownload(true);
          List<GreenScreen> list = state.items.map((e) => e.value).toList();
          FileTools.instance.saveGreenScreen(list);
        });
      }, (error) {
        item.update((value) {
          value?.isDownloading = false;
        });
      });
    } else {
      state.items.forEach((element) {
        element.update((value) {
          value?.isSelected = false;
        });
      });
      item.update((value) {
        value?.isSelected = true;
      });
      state.canCancel(true);
      MtPlugin.setGreenScreen(item.value.name.toString());
    }
  }

  ///关闭所有效果
  void cancelAll() {
    state.canCancel(false);
    state.items.forEach((element) {
      element.update((value) {
        value?.isSelected = false;
      });
    });
    MtPlugin.setGreenScreen("");
  }
}
