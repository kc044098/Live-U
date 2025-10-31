import 'package:get/get.dart';
import 'package:mt_plugin/bean/portraits.dart';

///抠图面板的状态
class PortraitsState {
  //配置文件是否加载完成
  Rx<bool> hasLoad = false.obs;

  //是否可以取消效果
  Rx<bool> canCancel = false.obs;

  //人像抠图列表
  List<Rx<Portrait>> items = [];

}
