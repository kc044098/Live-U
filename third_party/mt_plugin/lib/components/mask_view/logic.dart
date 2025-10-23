import 'package:get/get.dart';
import 'package:mt_plugin/bean/masks.dart';
import 'package:mt_plugin/components/mask_view/state.dart';
import 'package:mt_plugin/dio_utils.dart';
import 'package:mt_plugin/mt_plugin.dart';

import '../../file_tools.dart';

class MaskViewLogic extends GetxController {
  final MaskState state = MaskState();

  //点击面具
  void clickMask(Rx<Mask> mask) {
    if (mask.value.isDownloading == true) return;
    // if (mask.value.isDownloading == false && mask.value.downloaded == false) {
    //   //如果不是下载状态且没有下载过
    //   mask.update((value) {
    //     value?.isDownloading = true;
    //   });
    if (mask.value.downloaded == 0) {
      //下载贴纸

      mask.update((item) {
        item?.isDownloading = true;
      });

      DioUtils.instance.downloadMask(mask.value.dir, (dynamic) {
        mask.update((item) {
          // value?.isDownloading = false;
          // value?.setDownload(true);
          if (item != null) item.setDownload(2);
          item?.isDownloading = false;
          List<Mask> list = [];
          state.items.forEach((item) {
            // element.forEach((item) {
              print("缓存贴纸：${item.value.name}/${item.value.category}");
              list.add(item.value);
            // });
          });

          FileTools.instance.saveMask(list);
        });
      }, (error) {
        mask.update((item) {
          item?.isDownloading = false;
        });
      });
    } else {
      state.items.forEach((element) {
        // element.forEach((element) {
          element.update((value){
          value?.isSelected = false;
          // });
        });
      });
      mask.update((value) {
        value?.isSelected = true;
      });
      state.canCancel(true);
      MtPlugin.setMaskName(mask.value.name);
    }
  }

  ///取消所有效果
  void cancelAll() {
    state.canCancel(false);
    state.items.forEach((element) {
      // element.forEach((element) {
        element.update((value) {
          value?.isSelected = false;
        // });
      });
    });
    MtPlugin.setMaskName("");
  }
}
