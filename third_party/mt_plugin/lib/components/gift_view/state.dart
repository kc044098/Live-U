import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:mt_plugin/bean/gifts.dart';

class GiftState {

  Rx<bool> hasLoad = false.obs; //配置文件是否加载完成

  Rx<bool> canCancel = false.obs; //是否可以被取消

  //贴纸集合
  List<Rx<Gift>> items = [];
}
