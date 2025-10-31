import 'package:get/get.dart';
import 'package:mt_plugin/bean/gifts.dart';
import 'package:mt_plugin/components/gift_view/state.dart';
import 'package:mt_plugin/dio_utils.dart';
import 'package:mt_plugin/mt_plugin.dart';

import '../../file_tools.dart';

class GiftViewLogic extends GetxController {
  final GiftState state = GiftState();

  //点击面具
  void clickGift(Rx<Gift> gift) {
    if (gift.value.isDownloading == true) return;

    if (gift.value.downloaded == 0) {
      //下载贴纸

      gift.update((item) {
        item?.isDownloading = true;
      });

      DioUtils.instance.downloadGift(gift.value.dir, (dynamic) {
        gift.update((item) {
          if (item != null) item.setDownload(2);
          item?.isDownloading = false;
          List<Gift> list = [];
          state.items.forEach((item) {
            // element.forEach((item) {
            print("缓存贴纸：${item.value.name}/${item.value.category}");
            list.add(item.value);
            // });
          });

          FileTools.instance.saveGift(list);
        });
      }, (error) {
        gift.update((item) {
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
      gift.update((value) {
        value?.isSelected = true;
      });
      state.canCancel(true);
      MtPlugin.setGiftName(gift.value.name);
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
    MtPlugin.setGiftName("");
  }
}
