import 'package:get/get.dart';
import 'package:mt_plugin/data/mt_parameter.dart';
import 'package:mt_plugin/generated/l10n.dart';

class FilterState {
  late Rx<int> currentTabIndex = 0.obs; //选中的顶部第几个


  late List<Rx<TitleTab>> tabTitles = [
    //美颜滤镜
    TitleTab(tabName: S.current.beauty_filter, selected: true).obs,
    //特效滤镜
    // TitleTab(tabName: S.current.effect_filter).obs,
    // 趣味滤镜
    // TitleTab(tabName: S.current.funny_filter).obs,
  ];

  Rx<int> currentMeiYanIndex = 0.obs; //选中了第几个美颜滤镜

  // Rx<int> currentTeXiaoIndex = 0.obs; //选中了第几个特效滤镜

  // Rx<int> currentQuWeiIndex = 0.obs; //选中了第几个趣味滤镜

  late List<List<Rx<FilterItem>>> items;

  // FilterState() {
  //   items = MTParameter.instance.FilterItems.map((list) {
  //     return list.map((element) => element.obs).toList();
  //   }).toList();
  // }

  FilterState() {
    // 只加载美颜滤镜数据：
    // MTParameter.instance.FilterItems 是 List<List<FilterItem>>
    // 这里只取第0组，即美颜滤镜组
    items = [
      MTParameter.instance.FilterItems[0].map((element) => element.obs).toList()
    ];
  }
}

///Tab
class TitleTab {
  final String tabName; //名称

  bool selected; //是否选中

  TitleTab({required this.tabName, this.selected = false});
}


