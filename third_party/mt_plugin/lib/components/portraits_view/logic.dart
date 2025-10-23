import 'package:get/get.dart';
import 'package:mt_plugin/bean/portraits.dart';
import 'package:mt_plugin/dio_utils.dart';
import 'package:mt_plugin/mt_plugin.dart';

import '../../file_tools.dart';
import 'state.dart';

///抠图面板的Logic
class PortraitsLogic extends GetxController {
  final state = PortraitsState();

  ///点击某个抠图效果
  void clickItem(Rx<Portrait> item) {
    if (item.value.downLoading == true) return;
    if (item.value.downloaded == false) {
      //更新状态为下载中....
      item.update((item) {
        item?.downLoading = true;
      });
      DioUtils.instance.downloadPortrait(item.value.dir, (data) {
        item.update((portrait) {
          portrait?.downLoading = false;
          portrait?.setDownloaded(true);
          List<Portrait> list = state.items.map((e) => e.value).toList();
          FileTools.instance.savePortrait(list);
        });
      }, (error) {
        item.update((atmosphere) {
          atmosphere?.downLoading = false;
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
      MtPlugin.setPortraitName(item.value.name.toString());
    }
  }

  ///关闭效果
  void cancelAll() {
    state.canCancel(false);
    state.items.forEach((element) {
      element.update((value) {
        value?.isSelected = false;
      });
    });
    MtPlugin.setPortraitName("");
  }
}
