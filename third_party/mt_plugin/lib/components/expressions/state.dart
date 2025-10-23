import 'package:get/get.dart';
import 'package:mt_plugin/bean/expressions.dart';

class ExpressionState {

  Rx<bool> hasLoad = false.obs; //配置文件是否加载完成

  Rx<bool> canCancel = false.obs; //是否可以被取消

  //贴纸集合
  List<Rx<Expression>> items = [];
}
