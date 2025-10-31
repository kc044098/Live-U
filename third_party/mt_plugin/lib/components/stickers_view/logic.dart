import 'package:get/get.dart';
import 'package:mt_plugin/bean/stickers.dart';
import 'package:mt_plugin/components/stickers_view/state.dart';
import 'package:mt_plugin/dio_utils.dart';
import 'package:mt_plugin/mt_plugin.dart';

import '../../file_tools.dart';

class StickersLogic extends GetxController {
  final StickersState state = StickersState();

  //点击顶部tab
  void clickTab() {}

  //点击贴纸
  void clickSticker(Rx<Sticker> sticker) {
    if (sticker.value.isDownloading == true) return;

    if (sticker.value.downloaded == 0) {
      //下载贴纸

      sticker.update((item) {
        item?.isDownloading = true;
      });

      DioUtils.instance.downloadSticker(sticker.value.dir, (dynamic) {
        sticker.update((item) {
          if (item != null) item.setDownload(2);
          item?.isDownloading = false;
          List<Sticker> list = [];
          state.items.forEach((element) {
            element.forEach((item) {
              print("缓存贴纸：${item.value.name}/${item.value.category}");
              list.add(item.value);
            });
          });

          FileTools.instance.saveStickers(list);
        });
      }, (error) {
        sticker.update((item) {
          item?.isDownloading = false;
        });
      });
    } else {
      //应用贴纸
      state.items.forEach((element) {
        element.forEach((element) {
          element.update((value) {
            value?.isSelected = false;
          });
        });
      });
      sticker.update((value) {
        value?.isSelected = true;
      });
      state.canCancel(true);
      MtPlugin.setDynamicStickerName(sticker.value.name);
    }
  }

  void cancelAll() {
    state.canCancel(false);
    state.items.forEach((element) {
      element.forEach((element) {
        element.update((value) {
          value?.isSelected = false;
        });
      });
    });
    MtPlugin.setDynamicStickerName("");
  }
}
