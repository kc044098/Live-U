import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:mt_plugin/bean/stickers.dart';
import 'package:mt_plugin/generated/l10n.dart';

///贴纸
class StickersState {
  Rx<bool> hasLoad = false.obs; //配置文件是否加载完成

  late Rx<int> currentTabIndex = 0.obs; //选中的顶部第几个

  late Rx<int> hotIndex = (-1).obs; //选中了热门的第几个

  late Rx<bool> canCancel = false.obs; //是否可以取消

  late List<Rx<TitleTab>> tabTitles = [
    //热门
    TitleTab(tabName: S.current.hot, selected: true).obs,
  ];

  //贴纸集合
  List<List<Rx<Sticker>>> items = [];
}

///顶部title
class TitleTab {
  final String tabName; //名称
  bool selected; //是否选中
  TitleTab({required this.tabName, this.selected = false});
}
