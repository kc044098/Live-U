import 'package:mt_plugin/MtQuickBeautyDefault.dart';
import 'package:mt_plugin/data/mt_cache_utils.dart';
import 'package:mt_plugin/generated/l10n.dart';

import '../mt_plugin.dart';

///美颜参数
class MTParameter {
  static MTParameter? _instance;

  MTParameter._internal() {}

  static MTParameter get instance => _getInstance();

  static MTParameter _getInstance() {
    if (_instance == null) {
      _instance = new MTParameter._internal();
    }
    return _instance!;
  }

   List<MeiYanItem> meiYanItems = [
    //美白
    MeiYanItem(
        title: S.current.whiteness,
        SelectedImageRes: "mt_icon/icon_whitening_selected.png",
        normalImageRes: "mt_icon/icon_whitening_unselected.png"),
    //磨皮
    MeiYanItem(
        title: S.current.blurriness,
        SelectedImageRes: "mt_icon/icon_blemish_removal_selected.png",
        normalImageRes: "mt_icon/icon_blemish_removal_unselected.png"),
    //红润
    MeiYanItem(
        title: S.current.rosiness,
        SelectedImageRes: "mt_icon/icon_tenderness_selected.png",
        normalImageRes: "mt_icon/icon_tenderness_unselected.png"),
    //清晰
    MeiYanItem(
        title: S.current.clearness,
        SelectedImageRes: "mt_icon/icon_skin_sharpness_selected.png",
        normalImageRes: "mt_icon/icon_skin_sharpness_unselected.png"),
    //亮度
    MeiYanItem(
        title: S.current.brightness,
        SelectedImageRes: "mt_icon/icon_brightness_selected.png",
        normalImageRes: "mt_icon/icon_brightness_unselected.png"),
     //去黑眼圈
     MeiYanItem(
         title: S.current.undereye_circles,
         SelectedImageRes: "mt_icon/icon_dark_circle_lessening_selected.png",
         normalImageRes: "mt_icon/icon_dark_circle_lessening_unselected.png"),
     //去法令纹
     MeiYanItem(
         title: S.current.nasolabial_fold,
         SelectedImageRes: "mt_icon/icon_nasolabial_lessening_selected.png",
         normalImageRes: "mt_icon/icon_nasolabial_lessening_unselected.png"),
  ];

   List<MeiXingItem> meiXingItems = [
    //大眼
    MeiXingItem(
        title: S.current.eye_enlarging,
        selectedImageRes: "mt_icon/icon_eye_magnifying_selected.png",
        normalImageRes: "mt_icon/icon_eye_magnifying_unselected.png"),
    //圆眼
    MeiXingItem(
        title: S.current.eye_rounding,
        selectedImageRes: "mt_icon/icon_eye_round_selected.png",
        normalImageRes: "mt_icon/icon_eye_round_unselected.png"),
    //瘦脸
    MeiXingItem(
        title: S.current.cheek_thinning,
        selectedImageRes: "mt_icon/icon_chin_slimming_selected.png",
        normalImageRes: "mt_icon/icon_chin_slimming_unselected.png"),
    //V脸
    MeiXingItem(
        title: S.current.v_shaping,
        selectedImageRes: "mt_icon/icon_cheek_v_shaping_selected.png",
        normalImageRes: "mt_icon/icon_cheek_v_shaping_unselected.png"),
    //窄脸
    MeiXingItem(
        title: S.current.cheek_narrowing,
        selectedImageRes: "mt_icon/icon_face_narrowing_selected.png",
        normalImageRes: "mt_icon/icon_face_narrowing_unselected.png"),
    //收颧骨
    MeiXingItem(
        title: S.current.cheek_bone_thinning,
        selectedImageRes: "mt_icon/icon_cheek_bone_thinning_selected.png",
        normalImageRes: "mt_icon/icon_cheek_bone_thinning_unselected.png"),
    //收下颌骨
    MeiXingItem(
        title: S.current.jaw_bone_thinning,
        selectedImageRes: "mt_icon/icon_jaw_bone_thinning_selected.png",
        normalImageRes: "mt_icon/icon_jaw_bone_thinning_unselected.png"),
    //丰太阳穴
    MeiXingItem(
        title: S.current.temple_enlarging,
        selectedImageRes: "mt_icon/icon_temple_enlarging_selected.png",
        normalImageRes: "mt_icon/icon_temple_enlarging_unselected.png"),
    //小头
    MeiXingItem(
        title: S.current.head_lessening,
        selectedImageRes: "mt_icon/icon_head_lessening_selected.png",
        normalImageRes: "mt_icon/icon_head_lessening_unselected.png"),
    //小脸
    MeiXingItem(
        title: S.current.face_lessening,
        selectedImageRes: "mt_icon/icon_face_lessening_selected.png",
        normalImageRes: "mt_icon/icon_face_lessening_unselected.png"),
    //短脸
    MeiXingItem(
        title: S.current.face_shortening,
        selectedImageRes: "mt_icon/icon_cheek_shortening_selected.png",
        normalImageRes: "mt_icon/icon_cheek_shortening_unselected.png"),
    //下巴
    MeiXingItem(
        title: S.current.chin_trimming,
        canMinus: true,
        selectedImageRes: "mt_icon/icon_jaw_transforming_selected.png",
        normalImageRes: "mt_icon/icon_jaw_transforming_unselected.png"),
    //缩人中
    MeiXingItem(
        title: S.current.philtrum_trimming,
        canMinus: true,
        selectedImageRes: "mt_icon/icon_philtrum_trimming_selected.png",
        normalImageRes: "mt_icon/icon_philtrum_trimming_unselected.png"),
    //发际线
    MeiXingItem(
        title: S.current.forehead_trimming,
        canMinus: true,
        selectedImageRes: "mt_icon/icon_forehead_transforming_selected.png",
        normalImageRes: "mt_icon/icon_forehead_transforming_unselected.png"),
    //眼间距
    MeiXingItem(
        title: S.current.eye_sapcing,
        canMinus: true,
        selectedImageRes: "mt_icon/icon_eye_spacing_selected.png",
        normalImageRes: "mt_icon/icon_eye_spacing_unselected.png"),
    //倾斜
    MeiXingItem(
        title: S.current.eye_corner_trimming,
        selectedImageRes: "mt_icon/icon_eye_corners_selected.png",
        normalImageRes: "mt_icon/icon_eye_corners_unselected.png"),
    //开眼角
    MeiXingItem(
        title: S.current.eye_corner_enlarging,
        selectedImageRes: "mt_icon/icon_eye_corner_enlarging_selected.png",
        normalImageRes: "mt_icon/icon_eye_corner_enlarging_unselected.png"),
    //长鼻
    MeiXingItem(
        title: S.current.nose_enlarging,
        canMinus: true,
        selectedImageRes: "mt_icon/icon_nose_elongating_selected.png",
        normalImageRes: "mt_icon/icon_nose_elongating_unselected.png"),
    //瘦鼻
    MeiXingItem(
        title: S.current.nose_thinning,
        canMinus: true,
        selectedImageRes: "mt_icon/icon_nose_minifying_selected.png",
        normalImageRes: "mt_icon/icon_nose_minifying_unselected.png"),
    //鼻头
    MeiXingItem(
        title: S.current.nose_apex_lessening,
        selectedImageRes: "mt_icon/icon_nose_apex_lessening_selected.png",
        normalImageRes: "mt_icon/icon_nose_apex_lessening_unselected.png"),
    //山根
    MeiXingItem(
        title: S.current.nose_root_enlarging,
        selectedImageRes: "mt_icon/icon_nose_root_enlarging_selected.png",
        normalImageRes: "mt_icon/icon_nose_root_enlarging_unselected.png"),
    //嘴型
    MeiXingItem(
        title: S.current.mouth_trimming,
        canMinus: true,
        selectedImageRes: "mt_icon/icon_mouth_trimming_selected.png",
        normalImageRes: "mt_icon/icon_mouth_trimming_unselected.png"),
    //微笑嘴角
    MeiXingItem(
        title: S.current.mouth_smiling,
        selectedImageRes: "mt_icon/icon_mouth_smiling_selected.png",
        normalImageRes: "mt_icon/icon_mouth_smiling_unselected.png"),
  ];

   //一键美颜
  List<QuickMakeUpItem> quickMakeUpItems = [
    //原图
    QuickMakeUpItem(
        title: S.current.none,
        iconRes: "mt_icon/icon_quick_makeup/ic_makeup_none.png",
        isSelected: true,
        beautyDefault: MtQuickBeautyDefault.STANDARD_DEFAULT,
        type:0),
    //清纯白花
    QuickMakeUpItem(
        title: S.current.qingchunbaihua,
        iconRes: "mt_icon/icon_quick_makeup/ic_makeup_01.png",
        beautyDefault: MtQuickBeautyDefault.LOLITA_DEFAULT,
        type:1),
    //狐系美人
    QuickMakeUpItem(
        title: S.current.huximeiren,
        iconRes: "mt_icon/icon_quick_makeup/ic_makeup_02.png",
        beautyDefault: MtQuickBeautyDefault.GODDESS_DEFAULT,
        type:2),
    //清甜妆
    QuickMakeUpItem(
        title: S.current.qingtianzhuang,
        iconRes: "mt_icon/icon_quick_makeup/ic_makeup_03.png",
        beautyDefault: MtQuickBeautyDefault.CELEBRITY_DEFAULT,
        type:3),
    //白露
    QuickMakeUpItem(
        title: S.current.bailu,
        iconRes: "mt_icon/icon_quick_makeup/ic_makeup_04.png",
        beautyDefault: MtQuickBeautyDefault.NATURAL_DEFAULT,
        type:4),
    //冷调
    QuickMakeUpItem(
        title: S.current.lengdiao,
        iconRes: "mt_icon/icon_quick_makeup/ic_makeup_05.png",
        beautyDefault: MtQuickBeautyDefault.MILK_DEFAULT,
        type:5),
    //元气少女
    QuickMakeUpItem(
        title: S.current.yuanqishaonv,
        iconRes: "mt_icon/icon_quick_makeup/ic_makeup_06.png",
        beautyDefault: MtQuickBeautyDefault.CARMEL_DEFAULT,
        type:6),
    //女团
    QuickMakeUpItem(
        title: S.current.nvtuan,
        iconRes: "mt_icon/icon_quick_makeup/ic_makeup_07.png",
        beautyDefault: MtQuickBeautyDefault.PAINTING_DEFAULT,
        type:7),
    //纯欲妆
    QuickMakeUpItem(
        title: S.current.chunyuzhuang,
        iconRes: "mt_icon/icon_quick_makeup/ic_makeup_08.png",
        beautyDefault: MtQuickBeautyDefault.NECTARINE_DEFAULT,
        type:8),
  ];

   List<List<FilterItem>> FilterItems = [
    //风格滤镜
    [
      //原图
      FilterItem(
          title: S.current.none,
          img: "mt_icon/icon_beauty_filter/ic_filter_yuantu.png",
          filterName: "",
          isSelected: true),
      //自然1
      FilterItem(
          title: S.current.ziran1,
          img: "mt_icon/icon_beauty_filter/ic_filter_ziran1.png",
          filterName: "ziran1"),
      //自然2
      FilterItem(
          title: S.current.ziran2,
          img: "mt_icon/icon_beauty_filter/ic_filter_ziran2.png",
          filterName: "ziran2"),
      //自然3
      FilterItem(
          title: S.current.ziran3,
          img: "mt_icon/icon_beauty_filter/ic_filter_ziran3.png",
          filterName: "ziran3"),
      //自然4
      FilterItem(
          title: S.current.ziran4,
          img: "mt_icon/icon_beauty_filter/ic_filter_ziran4.png",
          filterName: "ziran4"),
      //自然5
      FilterItem(
          title: S.current.ziran5,
          img: "mt_icon/icon_beauty_filter/ic_filter_ziran5.png",
          filterName: "ziran5"),
      //自然6
      FilterItem(
          title: S.current.ziran6,
          img: "mt_icon/icon_beauty_filter/ic_filter_ziran6.png",
          filterName: "ziran6"),
      //月色
      FilterItem(
          title: S.current.yuese,
          img: "mt_icon/icon_beauty_filter/ic_filter_yuese.png",
          filterName: "yuese"),
      //月辉
      FilterItem(
          title: S.current.yuehui,
          img: "mt_icon/icon_beauty_filter/ic_filter_yuehui.png",
          filterName: "yuehui"),
      //日光
      FilterItem(
          title: S.current.riguang,
          img: "mt_icon/icon_beauty_filter/ic_filter_riguang.png",
          filterName: "riguang"),
      //落霞
      FilterItem(
          title: S.current.luoxia,
          img: "mt_icon/icon_beauty_filter/ic_filter_luoxia.png",
          filterName: "luoxia"),
      //质感1
      FilterItem(
          title: S.current.zhigan1,
          img: "mt_icon/icon_beauty_filter/ic_filter_zhigan1.png",
          filterName: "zhigan1"),
      //质感2
      FilterItem(
          title: S.current.zhigan2,
          img: "mt_icon/icon_beauty_filter/ic_filter_zhigan2.png",
          filterName: "zhigan2"),
      //质感3
      FilterItem(
          title: S.current.zhigan3,
          img: "mt_icon/icon_beauty_filter/ic_filter_zhigan3.png",
          filterName: "zhigan3"),
      //质感4
      FilterItem(
          title: S.current.zhigan4,
          img: "mt_icon/icon_beauty_filter/ic_filter_zhigan4.png",
          filterName: "zhigan4"),
      //质感5
      FilterItem(
          title: S.current.zhigan5,
          img: "mt_icon/icon_beauty_filter/ic_filter_zhigan5.png",
          filterName: "zhigan5"),
      //shadow1
      FilterItem(
          title: S.current.shadow1,
          img: "mt_icon/icon_beauty_filter/ic_filter_shadow1.png",
          filterName: "shadow1"),
      //shadow2
      FilterItem(
          title: S.current.shadow2,
          img: "mt_icon/icon_beauty_filter/ic_filter_shadow2.png",
          filterName: "shadow2"),
      //shadow3
      FilterItem(
          title: S.current.shadow3,
          img: "mt_icon/icon_beauty_filter/ic_filter_shadow3.png",
          filterName: "shadow3"),
      //shadow4
      FilterItem(
          title: S.current.shadow4,
          img: "mt_icon/icon_beauty_filter/ic_filter_shadow4.png",
          filterName: "shadow4"),
      //月夜
      FilterItem(
          title: S.current.yueye,
          img: "mt_icon/icon_beauty_filter/ic_filter_yueye.png",
          filterName: "yueye"),
      //米茶
      FilterItem(
          title: S.current.micha,
          img: "mt_icon/icon_beauty_filter/ic_filter_micha.png",
          filterName: "micha"),
      //静谧
      FilterItem(
          title: S.current.jingmi,
          img: "mt_icon/icon_beauty_filter/ic_filter_jingmi.png",
          filterName: "jingmi"),
      //柔光
      FilterItem(
          title: S.current.rouguang,
          img: "mt_icon/icon_beauty_filter/ic_filter_rouguang.png",
          filterName: "rouguang"),
      //奶杏
      FilterItem(
          title: S.current.naixing,
          img: "mt_icon/icon_beauty_filter/ic_filter_naixing.png",
          filterName: "naixing"),
      //烟色
      FilterItem(
          title: S.current.yanse,
          img: "mt_icon/icon_beauty_filter/ic_filter_yanse.png",
          filterName: "yanse"),
      //青雾
      FilterItem(
          title: S.current.qingwu,
          img: "mt_icon/icon_beauty_filter/ic_filter_qingwu.png",
          filterName: "qingwu"),
      //轻曝
      FilterItem(
          title: S.current.qingbao,
          img: "mt_icon/icon_beauty_filter/ic_filter_qingbao.png",
          filterName: "qingbao"),
      //幻紫
      FilterItem(
          title: S.current.huanzi,
          img: "mt_icon/icon_beauty_filter/ic_filter_huanzi.png",
          filterName: "huanzi"),
      //幻色
      FilterItem(
          title: S.current.huanse,
          img: "mt_icon/icon_beauty_filter/ic_filter_huanse.png",
          filterName: "huanse"),
      //旧照
      FilterItem(
          title: S.current.jiuzhao,
          img: "mt_icon/icon_beauty_filter/ic_filter_jiuzhao.png",
          filterName: "jiuzhao"),
      //迷幻
      FilterItem(
          title: S.current.mihuan,
          img: "mt_icon/icon_beauty_filter/ic_filter_mihuan.png",
          filterName: "mihuan"),
      //异彩
      FilterItem(
          title: S.current.yicai,
          img: "mt_icon/icon_beauty_filter/ic_filter_yicai.png",
          filterName: "yicai"),
      //春晖
      FilterItem(
          title: S.current.chunhui,
          img: "mt_icon/icon_beauty_filter/ic_filter_chunhui.png",
          filterName: "chunhui"),
      //光晕
      FilterItem(
          title: S.current.guangyun,
          img: "mt_icon/icon_beauty_filter/ic_filter_guangyun.png",
          filterName: "guangyun"),
      //柔雾
      FilterItem(
          title: S.current.rouwu,
          img: "mt_icon/icon_beauty_filter/ic_filter_rouwu.png",
          filterName: "rouwu"),
      //直射灯
      FilterItem(
          title: S.current.zhishedeng,
          img: "mt_icon/icon_beauty_filter/ic_filter_zhishedeng.png",
          filterName: "zhishedeng"),
      //初春
      FilterItem(
          title: S.current.chuchun,
          img: "mt_icon/icon_beauty_filter/ic_filter_chuchun.png",
          filterName: "chuchun"),
      //初恋
      FilterItem(
          title: S.current.chulian,
          img: "mt_icon/icon_beauty_filter/ic_filter_chulian.png",
          filterName: "chulian"),
      //初学
      FilterItem(
          title: S.current.chuxue,
          img: "mt_icon/icon_beauty_filter/ic_filter_chuxue.png",
          filterName: "chuxue"),
      //粉瓷
      FilterItem(
          title: S.current.fenci,
          img: "mt_icon/icon_beauty_filter/ic_filter_fenci.png",
          filterName: "fenci"),
      //冷冬
      FilterItem(
          title: S.current.lengdong,
          img: "mt_icon/icon_beauty_filter/ic_filter_lengdong.png",
          filterName: "lengdong"),
      //梦境
      FilterItem(
          title: S.current.mengjing,
          img: "mt_icon/icon_beauty_filter/ic_filter_mengjing.png",
          filterName: "mengjing"),
      //清透
      FilterItem(
          title: S.current.qingtou,
          img: "mt_icon/icon_beauty_filter/ic_filter_qingtou.png",
          filterName: "qingtou"),
      //新叶
      FilterItem(
          title: S.current.xinye,
          img: "mt_icon/icon_beauty_filter/ic_filter_xinye.png",
          filterName: "xinye"),
      //冰茶
      FilterItem(
          title: S.current.bingcha,
          img: "mt_icon/icon_beauty_filter/ic_filter_bingcha.png",
          filterName: "bingcha"),
      //浪漫
      FilterItem(
          title: S.current.langman,
          img: "mt_icon/icon_beauty_filter/ic_filter_langman.png",
          filterName: "langman"),
      //迷雾
      FilterItem(
          title: S.current.miwu,
          img: "mt_icon/icon_beauty_filter/ic_filter_miwu.png",
          filterName: "miwu"),
      //青木
      FilterItem(
          title: S.current.qingmu,
          img: "mt_icon/icon_beauty_filter/ic_filter_qingmu.png",
          filterName: "qingmu"),
      //轻沙
      FilterItem(
          title: S.current.qingsha,
          img: "mt_icon/icon_beauty_filter/ic_filter_qingsha.png",
          filterName: "qingsha"),
      //情绪
      FilterItem(
          title: S.current.qingxu,
          img: "mt_icon/icon_beauty_filter/ic_filter_qingxu.png",
          filterName: "qingxu"),
      //森雾
      FilterItem(
          title: S.current.senwu,
          img: "mt_icon/icon_beauty_filter/ic_filter_senwu.png",
          filterName: "senwu"),
      //沙漫
      FilterItem(
          title: S.current.shaman,
          img: "mt_icon/icon_beauty_filter/ic_filter_shaman.png",
          filterName: "shaman"),
      //温柔
      FilterItem(
          title: S.current.wenrou,
          img: "mt_icon/icon_beauty_filter/ic_filter_wenrou.png",
          filterName: "wenrou"),
      //庙会
      FilterItem(
          title: S.current.miaohui,
          img: "mt_icon/icon_beauty_filter/ic_filter_miaohui.png",
          filterName: "miaohui"),
      //晴空
      FilterItem(
          title: S.current.qingkong,
          img: "mt_icon/icon_beauty_filter/ic_filter_qingkong.png",
          filterName: "qingkong"),
      //山间
      FilterItem(
          title: S.current.shanjian,
          img: "mt_icon/icon_beauty_filter/ic_filter_shanjian.png",
          filterName: "shanjian"),
      //香松
      FilterItem(
          title: S.current.xiangsong,
          img: "mt_icon/icon_beauty_filter/ic_filter_xiangsong.png",
          filterName: "xiangsong"),
      //标准
      FilterItem(
          title: S.current.biaozhun,
          img: "mt_icon/icon_beauty_filter/ic_filter_biaozhun.png",
          filterName: "biaozhun"),
      //水光
      FilterItem(
          title: S.current.shuiguang,
          img: "mt_icon/icon_beauty_filter/ic_filter_shuiguang.png",
          filterName: "shuiguang"),
      //水雾
      FilterItem(
          title: S.current.shuiwu,
          img: "mt_icon/icon_beauty_filter/ic_filter_shuiwu.png",
          filterName: "shuiwu"),
      //冷淡
      FilterItem(
          title: S.current.lengdan,
          img: "mt_icon/icon_beauty_filter/ic_filter_lengdan.png",
          filterName: "lengdan"),
      //白兰
      FilterItem(
          title: S.current.bailan,
          img: "mt_icon/icon_beauty_filter/ic_filter_bailan.png",
          filterName: "bailan"),
      //纯真
      FilterItem(
          title: S.current.chunzhen,
          img: "mt_icon/icon_beauty_filter/ic_filter_chunzhen.png",
          filterName: "chunzhen"),
      //超脱
      FilterItem(
          title: S.current.chaotuo,
          img: "mt_icon/icon_beauty_filter/ic_filter_chaotuo.png",
          filterName: "chaotuo"),
      //森系
      FilterItem(
          title: S.current.senxi,
          img: "mt_icon/icon_beauty_filter/ic_filter_senxi.png",
          filterName: "senxi"),
      //暖阳
      FilterItem(
          title: S.current.nuanyang,
          img: "mt_icon/icon_beauty_filter/ic_filter_nuanyang.png",
          filterName: "nuanyang"),
      //夏日
      FilterItem(
          title: S.current.xiari,
          img: "mt_icon/icon_beauty_filter/ic_filter_xiari.png",
          filterName: "xiari"),
      //蜜桃乌龙
      FilterItem(
          title: S.current.mitaowulong,
          img: "mt_icon/icon_beauty_filter/ic_filter_mitaowulong.png",
          filterName: "mitaowulong"),
      //少女
      FilterItem(
          title: S.current.shaonv,
          img: "mt_icon/icon_beauty_filter/ic_filter_shaonv.png",
          filterName: "shaonv"),
      //元气
      FilterItem(
          title: S.current.yuanqi,
          img: "mt_icon/icon_beauty_filter/ic_filter_yuanqi.png",
          filterName: "yuanqi"),
      //绯樱
      FilterItem(
          title: S.current.feiying,
          img: "mt_icon/icon_beauty_filter/ic_filter_feiying.png",
          filterName: "feiying"),
      //清新
      FilterItem(
          title: S.current.qingxin,
          img: "mt_icon/icon_beauty_filter/ic_filter_qingxin.png",
          filterName: "qingxin"),
      //日系
      FilterItem(
          title: S.current.rixi,
          img: "mt_icon/icon_beauty_filter/ic_filter_rixi.png",
          filterName: "rixi"),
      //反差色
      FilterItem(
          title: S.current.fanchase,
          img: "mt_icon/icon_beauty_filter/ic_filter_fanchase.png",
          filterName: "fanchase"),
      //复古
      FilterItem(
          title: S.current.fugu,
          img: "mt_icon/icon_beauty_filter/ic_filter_fugu.png",
          filterName: "fugu"),
      //回忆
      FilterItem(
          title: S.current.huiyi,
          img: "mt_icon/icon_beauty_filter/ic_filter_huiyi.png",
          filterName: "huiyi"),
      //怀旧
      FilterItem(
          title: S.current.huaijiu,
          img: "mt_icon/icon_beauty_filter/ic_filter_huaijiu.png",
          filterName: "huaijiu")
    ],
    //特效滤镜
    [
      //原画
      FilterItem(
          title: S.current.none,
          img: "mt_icon/icon_effect_filter/ht_yuantu_icon.webp",
          filterName: "0",
          isSelected: true),
      //灵魂出窍
      FilterItem(
          title: S.current.lhcq,
          img: "mt_icon/icon_effect_filter/ht_lhcq_icon.webp",
          filterName: "1"),
      //黑白电影
      FilterItem(
          title: S.current.hbdy,
          img: "mt_icon/icon_effect_filter/ht_hbdy_icon.webp",
          filterName: "2"),
      //魔法镜面
      FilterItem(
          title: S.current.mfjm,
          img: "mt_icon/icon_effect_filter/ht_mfjm_icon.webp",
          filterName: "3"),
      //炫彩抖动
      FilterItem(
          title: S.current.xcdd,
          img: "mt_icon/icon_effect_filter/ht_xcdd_icon.webp",
          filterName: "4"),
      //头晕目眩
      FilterItem(
          title: S.current.tymx,
          img: "mt_icon/icon_effect_filter/ht_tymx_icon.webp",
          filterName: "5"),
      //动感分屏
      FilterItem(
          title: S.current.dgfp,
          img: "mt_icon/icon_effect_filter/ht_dgfp_icon.webp",
          filterName: "6"),
      //四宫格
      FilterItem(
          title: S.current.sgg,
          img: "mt_icon/icon_effect_filter/ht_sfp_icon.webp",
          filterName: "7"),
      //四屏镜像
      FilterItem(
          title: S.current.spjx,
          img: "mt_icon/icon_effect_filter/ht_spjx_icon.webp",
          filterName: "8"),
      //毛玻璃
      FilterItem(
          title: S.current.mbl,
          img: "mt_icon/icon_effect_filter/ht_maoboli_icon.webp",
          filterName: "9"),
      //边界模糊
      FilterItem(
          title: S.current.bjmh,
          img: "mt_icon/icon_effect_filter/ht_bkmh_icon.webp",
          filterName: "10"),
      //模糊分屏
      FilterItem(
          title: S.current.mhfp,
          img: "mt_icon/icon_effect_filter/ht_mhfp_icon.webp",
          filterName: "11"),
      //瞬间石化
      FilterItem(
          title: S.current.sjsh,
          img: "mt_icon/icon_effect_filter/ht_sjsh_icon.webp",
          filterName: "12"),
      //轻彩抖动
      FilterItem(
          title: S.current.qcdd,
          img: "mt_icon/icon_effect_filter/ht_qcdd_icon.webp",
          filterName: "13"),
      //一键乐高
      FilterItem(
          title: S.current.yjlg,
          img: "mt_icon/icon_effect_filter/ht_yjlg_icon.png",
          filterName: "14"),
      //九宫格
      FilterItem(
          title: S.current.jgg,
          img: "mt_icon/icon_effect_filter/ht_jgg_icon.webp",
          filterName: "15"),
      //反光镜
      FilterItem(
          title: S.current.fgj,
          img: "mt_icon/icon_effect_filter/ht_fgj_icon.webp",
          filterName: "16"),
      //虚拟镜像
      FilterItem(
          title: S.current.xnjx,
          img: "mt_icon/icon_effect_filter/ht_xnjx_icon.webp",
          filterName: "17"),
      //幻觉残影
      FilterItem(
          title: S.current.hjcy,
          img: "mt_icon/icon_effect_filter/ht_hjcy_icon.webp",
          filterName: "18"),
      //三分屏
      FilterItem(
          title: S.current.sfp,
          img: "mt_icon/icon_effect_filter/ht_sanfp_icon.png",
          filterName: "19"),
      //碎玻璃
      FilterItem(
          title: S.current.sbl,
          img: "mt_icon/icon_effect_filter/ht_sbl_icon.png",
          filterName: "20"),
    ],
    //哈哈镜
     [
      //原图
      FilterItem(
          title: S.current.none,
          img: "mt_icon/icon_funny_filter/icon_funny_none.webp",
          filterName: "0"),
      //外星人
      FilterItem(
          title: S.current.funny_alien,
          img: "mt_icon/icon_funny_filter/icon_funny_alien.webp",
          filterName: "1"),
      //大鼻子
      FilterItem(
          title: S.current.funny_big_nose,
          filterName: "2",
          img: "mt_icon/icon_funny_filter/icon_funny_bignose.webp"),
      //大嘴巴
      FilterItem(
          title: S.current.funny_big_mouth,
          filterName: "3",
          img: "mt_icon/icon_funny_filter/icon_funny_bigmouth.webp"),
      //方形脸
      FilterItem(
          title: S.current.funny_square_face,
          filterName: "4",
          img: "mt_icon/icon_funny_filter/icon_funny_squareface.webp"),
      //大头
      FilterItem(
          title: S.current.funny_big_head,
          filterName: "5",
          img: "mt_icon/icon_funny_filter/icon_funny_bighead.webp"),
      //嘟嘟脸
      FilterItem(
          title: S.current.funny_plump_face,
          filterName: "6",
          img: "mt_icon/icon_funny_filter/icon_funny_pearface.webp"),
      //豆豆眼
      FilterItem(
          title: S.current.funny_peas_eyes,
          filterName: "7",
          img: "mt_icon/icon_funny_filter/icon_funny_smalleye.webp"),
      //蛇精脸
      FilterItem(
          title: S.current.funny_snake_spirit_face,
          filterName: "8",
          img: "mt_icon/icon_funny_filter/icon_funny_thinface.webp"),
    ]
  ];
}

///美颜数据基类
class MeiYanItem {
  MeiYanItem(
      {required this.title,
      required this.SelectedImageRes,
      required this.normalImageRes,
      this.isSelected = false,
      this.progress = 0});

  String title; //标题名称

  String SelectedImageRes; // 选中时候的图标

  String normalImageRes; //未选中时的图标

  bool isSelected; //是否选中

  int progress; //进度

  void apply() {
    if (title == S.current.whiteness) {
      MtPlugin.setWhitenessValue(progress);
    }

    if (title == S.current.blurriness) {
      MtPlugin.setBlurrinessValue(progress);
    }

    if (title == S.current.rosiness) {
      MtPlugin.setRosinessValue(progress);
    }

    if (title == S.current.clearness) {
      MtPlugin.setClearnessValue(progress);
    }

    if (title == S.current.brightness) {
      MtPlugin.setBrightnessValue(progress);
    }
    if (title == S.current.undereye_circles) {
      MtPlugin.setUndereyeCirclesValue(progress);
    }
    if (title == S.current.nasolabial_fold) {
      MtPlugin.setNasolabialFoldValue(progress);
    }
    MtCacheUtils.instance.setValueWithName(title, progress);
  }
}

///一键美颜数据基类
class QuickMakeUpItem {
  final String title; //底部名称

  final String iconRes; //图标

  bool isSelected; //是否选中

  int type; //类型

  int progress; //强度 1-100

  MtQuickBeautyDefault beautyDefault;

  QuickMakeUpItem({
    required this.title,
    required this.iconRes,
    required this.beautyDefault,
    required this.type,
    this.isSelected = false,
    this.progress = 0,
  });
}

///滤镜单元
class FilterItem {
  final String title; //名称

  final String img; //图标

  bool isSelected; //是否选中

  String filterName;

  int progress = 0;

  FilterItem(
      {required this.title,
      required this.img,
      this.isSelected = false,
      required this.filterName});
}

///美型的数据单元
class MeiXingItem {
  MeiXingItem(
      {required this.title,
      required this.selectedImageRes,
      required this.normalImageRes,
      this.canMinus = false,
      this.isSelected = false,
      this.progress = 0});

  String title; //标题名称

  String selectedImageRes; // 选中时候的图标

  String normalImageRes; //未选中时的图标

  bool isSelected; //是否选中

  int progress; //进度

  bool canMinus; //是否可以是负数

  apply() {
    if (title == S.current.eye_enlarging) {
      //大眼
      MtPlugin.setEyeEnlargingValue(progress);
    }

    if (title == S.current.eye_rounding) {
      //圆眼
      MtPlugin.setEyeRoundingValue(progress);
    }

    if (title == S.current.cheek_thinning) {
      //瘦脸
      MtPlugin.setCheekThinningValue(progress);
    }

    if (title == S.current.v_shaping) {
      //V脸
      MtPlugin.setCheekVValue(progress);
    }

    if (title == S.current.cheek_narrowing) {
      //窄脸
      MtPlugin.setCheekNarrowingValue(progress);
    }

    if (title == S.current.cheek_bone_thinning) {
      //瘦颧骨
      MtPlugin.setCheekThinningValue(progress);
    }

    if (title == S.current.jaw_bone_thinning) {
      //瘦下颌骨
      MtPlugin.setJawboneThinningValue(progress);
    }

    if (title == S.current.temple_enlarging) {
      //丰太阳穴
      MtPlugin.setTempleEnlargingValue(progress);
    }

    if (title == S.current.head_lessening) {
      //小头
      MtPlugin.setHeadLesseningValue(progress);
    }

    if (title == S.current.face_lessening) {
      //小脸
      MtPlugin.setFaceLesseningValue(progress);
    }

    if (title == S.current.face_shortening) {
      //短脸
      MtPlugin.setFaceShorteningValue(progress);
    }

    if (title == S.current.chin_trimming) {
      //下巴
      MtPlugin.setChinTrimmingValue(progress);
    }

    if (title == S.current.philtrum_trimming) {
      //缩人中
      MtPlugin.setPhiltrumTrimmingValue(progress);
    }

    if (title == S.current.forehead_trimming) {
      //发际线
      MtPlugin.setForeheadTrimmingValue(progress);
    }

    if (title == S.current.eye_sapcing) {
      //眼间距
      MtPlugin.setEyeSpacingTrimmingValue(progress);
    }

    if (title == S.current.eye_corner_trimming) {
      //倾斜
      MtPlugin.setEyeCornerTrimmingValue(progress);
    }

    if (title == S.current.eye_corner_enlarging) {
      //开眼角
      MtPlugin.setEyeCornerTrimmingValue(progress);
    }

    if (title == S.current.nose_enlarging) {
      //长鼻
      MtPlugin.setNoseEnlargingValue(progress);
    }

    if (title == S.current.nose_thinning) {
      //瘦鼻
      MtPlugin.setNoseThinningValue(progress);
    }

    if (title == S.current.nose_apex_lessening) {
      //鼻头
      MtPlugin.setNoseApexLesseningValue(progress);
    }

    if (title == S.current.nose_root_enlarging) {
      //山根
      MtPlugin.setNoseRootEnlargingValue(progress);
    }

    if (title == S.current.mouth_trimming) {
      //嘴型
      MtPlugin.setMouthTrimmingValue(progress);
    }

    if (title == S.current.mouth_smiling) {
      //微笑嘴角
      MtPlugin.setMouthSmilingEnlargingValue(progress);
    }
    MtCacheUtils.instance.setValueWithName(title, progress);
  }
}
