import 'package:get/get.dart';
import 'package:mt_plugin/bean/atmospheres.dart';

/**
 * 气氛的状态
 */
class AtmosphereState {
  Rx<bool> hasLoad = false.obs; //配置文件是否加载完成

  Rx<bool> canCancel = false.obs; //是否可以取消效果

  //贴纸集合
  List<Rx<Atmosphere>> items = [];
}


