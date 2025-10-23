import 'package:get/get.dart';
import 'package:mt_plugin/bean/atmospheres.dart';
import 'package:mt_plugin/components/atmosphere_view/state.dart';
import 'package:mt_plugin/dio_utils.dart';
import 'package:mt_plugin/file_tools.dart';
import 'package:mt_plugin/mt_plugin.dart';

/**
 * 气氛的状态控制
 */
class AtmosphereViewLogic extends GetxController {
  final AtmosphereState state = AtmosphereState();

  //点击气氛
  void clickAtmosphere(Rx<Atmosphere> item) {
    if (item.value.isDownloading == true) return;
    if (item.value.downloaded == false) {
      //更新状态为下载中....
      item.update((item) {
        item?.isDownloading = true;
      });

      DioUtils.instance.downloadAtmosphere(item.value.dir, (dynamic) {
        item.update((atmosphere) {
          atmosphere?.isDownloading = false;
          atmosphere?.setDownloaded(true);
          List<Atmosphere> list = state.items.map((e) => e.value).toList();
          FileTools.instance.saveAtmosphere(list);
        });
      }, (error) {
        item.update((atmosphere) {
          atmosphere?.isDownloading = false;
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
      MtPlugin.setAtmosphereItemName(item.value.name.toString());
    }
  }

  //取消所有效果
  void cancelAll() {
    state.canCancel(false);
    state.items.forEach((element) {
      element.update((value) {
        value?.isSelected = false;
      });
    });
    MtPlugin.setAtmosphereItemName("");
  }
}
