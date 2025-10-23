// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(_current != null,
        'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.');
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(instance != null,
        'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?');
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `Reset`
  String get reset {
    return Intl.message(
      'Reset',
      name: 'reset',
      desc: '',
      args: [],
    );
  }

  /// `Reset all parameters to default?`
  String get is_reset_to_default {
    return Intl.message(
      'Reset all parameters to default?',
      name: 'is_reset_to_default',
      desc: '',
      args: [],
    );
  }

  /// `Yes`
  String get confirm {
    return Intl.message(
      'Yes',
      name: 'confirm',
      desc: '',
      args: [],
    );
  }

  /// `No`
  String get cancel {
    return Intl.message(
      'No',
      name: 'cancel',
      desc: '',
      args: [],
    );
  }

  /// `Beauty:On`
  String get beauty_on {
    return Intl.message(
      'Beauty:On',
      name: 'beauty_on',
      desc: '',
      args: [],
    );
  }

  /// `Beauty:Off`
  String get beauty_off {
    return Intl.message(
      'Beauty:Off',
      name: 'beauty_off',
      desc: '',
      args: [],
    );
  }

  /// `FaceTrim:On`
  String get face_trim_on {
    return Intl.message(
      'FaceTrim:On',
      name: 'face_trim_on',
      desc: '',
      args: [],
    );
  }

  /// `FaceTrim:Off`
  String get face_trim_off {
    return Intl.message(
      'FaceTrim:Off',
      name: 'face_trim_off',
      desc: '',
      args: [],
    );
  }

  /// `FaceBeauty`
  String get face_beauty {
    return Intl.message(
      'FaceBeauty',
      name: 'face_beauty',
      desc: '',
      args: [],
    );
  }

  /// `Whiteness`
  String get whiteness {
    return Intl.message(
      'Whiteness',
      name: 'whiteness',
      desc: '',
      args: [],
    );
  }

  /// `Blurriness`
  String get blurriness {
    return Intl.message(
      'Blurriness',
      name: 'blurriness',
      desc: '',
      args: [],
    );
  }

  /// `Rosiness`
  String get rosiness {
    return Intl.message(
      'Rosiness',
      name: 'rosiness',
      desc: '',
      args: [],
    );
  }

  /// `Clearness`
  String get clearness {
    return Intl.message(
      'Clearness',
      name: 'clearness',
      desc: '',
      args: [],
    );
  }

  /// `Brightness`
  String get brightness {
    return Intl.message(
      'Brightness',
      name: 'brightness',
      desc: '',
      args: [],
    );
  }
  //undereye_circles
  String get undereye_circles {
    return Intl.message(
      'Undereye_circles',
      name: 'undereye_circles',
      desc: '',
      args: [],
    );
  }
  //nasolabial_fold
  String get nasolabial_fold {
    return Intl.message(
      'Nasolabial_fold',
      name: 'nasolabial_fold',
      desc: '',
      args: [],
    );
  }

  /// `FaceShape`
  String get face_shape {
    return Intl.message(
      'FaceShape',
      name: 'face_shape',
      desc: '',
      args: [],
    );
  }

  /// `EyeEnlarge`
  String get eye_enlarging {
    return Intl.message(
      'EyeEnlarge',
      name: 'eye_enlarging',
      desc: '',
      args: [],
    );
  }

  /// `EyeRounding`
  String get eye_rounding {
    return Intl.message(
      'EyeRounding',
      name: 'eye_rounding',
      desc: '',
      args: [],
    );
  }

  /// `V_Shaping`
  String get v_shaping {
    return Intl.message(
      'V_Shaping',
      name: 'v_shaping',
      desc: '',
      args: [],
    );
  }

  /// `Face_Shortening`
  String get face_shortening {
    return Intl.message(
      'Face_Shortening',
      name: 'face_shortening',
      desc: '',
      args: [],
    );
  }

  /// `CheekThin`
  String get cheek_thinning {
    return Intl.message(
      'CheekThin',
      name: 'cheek_thinning',
      desc: '',
      args: [],
    );
  }

  /// `CheekNarrow`
  String get cheek_narrowing {
    return Intl.message(
      'CheekNarrow',
      name: 'cheek_narrowing',
      desc: '',
      args: [],
    );
  }

  /// `CheekBoneThin`
  String get cheek_bone_thinning {
    return Intl.message(
      'CheekBoneThin',
      name: 'cheek_bone_thinning',
      desc: '',
      args: [],
    );
  }

  /// `JawBoneThin`
  String get jaw_bone_thinning {
    return Intl.message(
      'JawBoneThin',
      name: 'jaw_bone_thinning',
      desc: '',
      args: [],
    );
  }

  /// `TempleEnlarge`
  String get temple_enlarging {
    return Intl.message(
      'TempleEnlarge',
      name: 'temple_enlarging',
      desc: '',
      args: [],
    );
  }

  /// `HeadLessen`
  String get head_lessening {
    return Intl.message(
      'HeadLessen',
      name: 'head_lessening',
      desc: '',
      args: [],
    );
  }

  /// `FaceLessen`
  String get face_lessening {
    return Intl.message(
      'FaceLessen',
      name: 'face_lessening',
      desc: '',
      args: [],
    );
  }

  /// `ChinTrim`
  String get chin_trimming {
    return Intl.message(
      'ChinTrim',
      name: 'chin_trimming',
      desc: '',
      args: [],
    );
  }

  /// `PhiltrumTrim`
  String get philtrum_trimming {
    return Intl.message(
      'PhiltrumTrim',
      name: 'philtrum_trimming',
      desc: '',
      args: [],
    );
  }

  /// `ForeheadTrim`
  String get forehead_trimming {
    return Intl.message(
      'ForeheadTrim',
      name: 'forehead_trimming',
      desc: '',
      args: [],
    );
  }

  /// `EyeSpace`
  String get eye_sapcing {
    return Intl.message(
      'EyeSpace',
      name: 'eye_sapcing',
      desc: '',
      args: [],
    );
  }

  /// `EyeCornerTrim`
  String get eye_corner_trimming {
    return Intl.message(
      'EyeCornerTrim',
      name: 'eye_corner_trimming',
      desc: '',
      args: [],
    );
  }

  /// `EyeCornerEnlarge`
  String get eye_corner_enlarging {
    return Intl.message(
      'EyeCornerEnlarge',
      name: 'eye_corner_enlarging',
      desc: '',
      args: [],
    );
  }

  /// `NoseEnlarge`
  String get nose_enlarging {
    return Intl.message(
      'NoseEnlarge',
      name: 'nose_enlarging',
      desc: '',
      args: [],
    );
  }

  /// `NoseThin`
  String get nose_thinning {
    return Intl.message(
      'NoseThin',
      name: 'nose_thinning',
      desc: '',
      args: [],
    );
  }

  /// `NoseApexLessen`
  String get nose_apex_lessening {
    return Intl.message(
      'NoseApexLessen',
      name: 'nose_apex_lessening',
      desc: '',
      args: [],
    );
  }

  /// `NoseRootEnlarge`
  String get nose_root_enlarging {
    return Intl.message(
      'NoseRootEnlarge',
      name: 'nose_root_enlarging',
      desc: '',
      args: [],
    );
  }

  /// `MouthTrim`
  String get mouth_trimming {
    return Intl.message(
      'MouthTrim',
      name: 'mouth_trimming',
      desc: '',
      args: [],
    );
  }

  /// `MouthSmile`
  String get mouth_smiling {
    return Intl.message(
      'MouthSmile',
      name: 'mouth_smiling',
      desc: '',
      args: [],
    );
  }

  /// `Cute`
  String get cute {
    return Intl.message(
      'Cute',
      name: 'cute',
      desc: '',
      args: [],
    );
  }

  /// `DynamicSticker`
  String get dynamic_sticker {
    return Intl.message(
      'DynamicSticker',
      name: 'dynamic_sticker',
      desc: '',
      args: [],
    );
  }

  /// `ExpressionRecreation`
  String get expression_recreation {
    return Intl.message(
      'ExpressionRecreation',
      name: 'expression_recreation',
      desc: '',
      args: [],
    );
  }

  /// `Mask`
  String get mask {
    return Intl.message(
      'Mask',
      name: 'mask',
      desc: '',
      args: [],
    );
  }

  ///'Gift'
  String get gift {
    return Intl.message(
      'Gift',
      name: 'gift',
      desc: '',
      args: [],
    );
  }

  /// `AtmosphereSticker`
  String get atmosphere_sticker {
    return Intl.message(
      'AtmosphereSticker',
      name: 'atmosphere_sticker',
      desc: '',
      args: [],
    );
  }

  /// `Watermark`
  String get watermark {
    return Intl.message(
      'Watermark',
      name: 'watermark',
      desc: '',
      args: [],
    );
  }

  /// `Hot`
  String get hot {
    return Intl.message(
      'Hot',
      name: 'hot',
      desc: '',
      args: [],
    );
  }

  /// `Festival`
  String get festival {
    return Intl.message(
      'Festival',
      name: 'festival',
      desc: '',
      args: [],
    );
  }

  /// `Cute`
  String get cute_series {
    return Intl.message(
      'Cute',
      name: 'cute_series',
      desc: '',
      args: [],
    );
  }

  /// `Filter`
  String get filter {
    return Intl.message(
      'Filter',
      name: 'filter',
      desc: '',
      args: [],
    );
  }

  /// `BeautyFilter`
  String get beauty_filter {
    return Intl.message(
      'BeautyFilter',
      name: 'beauty_filter',
      desc: '',
      args: [],
    );
  }

  /// `ziran1`
  String get ziran1 {
    return Intl.message(
      'ziran1',
      name: 'ziran1',
      desc: '',
      args: [],
    );
  }

  /// `ziran2`
  String get ziran2 {
    return Intl.message(
      'ziran2',
      name: 'ziran2',
      desc: '',
      args: [],
    );
  }

  /// `ziran3`
  String get ziran3 {
    return Intl.message(
      'ziran3',
      name: 'ziran3',
      desc: '',
      args: [],
    );
  }

  /// `ziran4`
  String get ziran4 {
    return Intl.message(
      'ziran4',
      name: 'ziran4',
      desc: '',
      args: [],
    );
  }

  /// `ziran5`
  String get ziran5 {
    return Intl.message(
      'ziran5',
      name: 'ziran5',
      desc: '',
      args: [],
    );
  }

  /// `ziran6`
  String get ziran6 {
    return Intl.message(
      'ziran6',
      name: 'ziran6',
      desc: '',
      args: [],
    );
  }

  /// `yuese`
  String get yuese {
    return Intl.message(
      'yuese',
      name: 'yuese',
      desc: '',
      args: [],
    );
  }

  /// `yuehui`
  String get yuehui {
    return Intl.message(
      'yuehui',
      name: 'yuehui',
      desc: '',
      args: [],
    );
  }

  /// `riguang`
  String get riguang {
    return Intl.message(
      'riguang',
      name: 'riguang',
      desc: '',
      args: [],
    );
  }

  /// `luoxia`
  String get luoxia {
    return Intl.message(
      'luoxia',
      name: 'luoxia',
      desc: '',
      args: [],
    );
  }

  /// `zhigan1`
  String get zhigan1 {
    return Intl.message(
      'zhigan1',
      name: 'zhigan1',
      desc: '',
      args: [],
    );
  }

  /// `zhigan2`
  String get zhigan2 {
    return Intl.message(
      'zhigan2',
      name: 'zhigan2',
      desc: '',
      args: [],
    );
  }

  /// `zhigan3`
  String get zhigan3 {
    return Intl.message(
      'zhigan3',
      name: 'zhigan3',
      desc: '',
      args: [],
    );
  }

  /// `zhigan4`
  String get zhigan4 {
    return Intl.message(
      'zhigan4',
      name: 'zhigan4',
      desc: '',
      args: [],
    );
  }

  /// `zhigan5`
  String get zhigan5 {
    return Intl.message(
      'zhigan5',
      name: 'zhigan5',
      desc: '',
      args: [],
    );
  }

  /// `shadow1`
  String get shadow1 {
    return Intl.message(
      'shadow1',
      name: 'shadow1',
      desc: '',
      args: [],
    );
  }

  /// `shadow2`
  String get shadow2 {
    return Intl.message(
      'shadow2',
      name: 'shadow2',
      desc: '',
      args: [],
    );
  }

  /// `shadow1`
  String get shadow3 {
    return Intl.message(
      'shadow3',
      name: 'shadow3',
      desc: '',
      args: [],
    );
  }

  /// `shadow4`
  String get shadow4 {
    return Intl.message(
      'shadow4',
      name: 'shadow4',
      desc: '',
      args: [],
    );
  }

  /// `yueye`
  String get yueye {
    return Intl.message(
      'yueye',
      name: 'yueye',
      desc: '',
      args: [],
    );
  }

  /// `micha`
  String get micha {
    return Intl.message(
      'micha',
      name: 'micha',
      desc: '',
      args: [],
    );
  }

  /// `jingmi`
  String get jingmi {
    return Intl.message(
      'jingmi',
      name: 'jingmi',
      desc: '',
      args: [],
    );
  }

  /// `rouguang`
  String get rouguang {
    return Intl.message(
      'rouguang',
      name: 'rouguang',
      desc: '',
      args: [],
    );
  }

  /// `naixing`
  String get naixing {
    return Intl.message(
      'naixing',
      name: 'naixing',
      desc: '',
      args: [],
    );
  }

  /// `yanse`
  String get yanse {
    return Intl.message(
      'yanse',
      name: 'yanse',
      desc: '',
      args: [],
    );
  }

  /// `qingwu`
  String get qingwu {
    return Intl.message(
      'qingwu',
      name: 'qingwu',
      desc: '',
      args: [],
    );
  }

  /// `qingbao`
  String get qingbao {
    return Intl.message(
      'qingbao',
      name: 'qingbao',
      desc: '',
      args: [],
    );
  }

  /// `huanzi`
  String get huanzi {
    return Intl.message(
      'huanzi',
      name: 'huanzi',
      desc: '',
      args: [],
    );
  }

  /// `huanse`
  String get huanse {
    return Intl.message(
      'huanse',
      name: 'huanse',
      desc: '',
      args: [],
    );
  }

  /// `jiuzhao`
  String get jiuzhao {
    return Intl.message(
      'jiuzhao',
      name: 'jiuzhao',
      desc: '',
      args: [],
    );
  }

  /// `mihuan`
  String get mihuan {
    return Intl.message(
      'mihuan',
      name: 'mihuan',
      desc: '',
      args: [],
    );
  }

  /// `yicai`
  String get yicai {
    return Intl.message(
      'yicai',
      name: 'yicai',
      desc: '',
      args: [],
    );
  }

  /// `chunhui`
  String get chunhui {
    return Intl.message(
      'chunhui',
      name: 'chunhui',
      desc: '',
      args: [],
    );
  }

  /// `guangyun`
  String get guangyun {
    return Intl.message(
      'guangyun',
      name: 'guangyun',
      desc: '',
      args: [],
    );
  }

  /// `rouwu`
  String get rouwu {
    return Intl.message(
      'rouwu',
      name: 'rouwu',
      desc: '',
      args: [],
    );
  }

  /// `zhishedeng`
  String get zhishedeng {
    return Intl.message(
      'zhishedeng',
      name: 'zhishedeng',
      desc: '',
      args: [],
    );
  }

  /// `chuchun`
  String get chuchun {
    return Intl.message(
      'chuchun',
      name: 'chuchun',
      desc: '',
      args: [],
    );
  }

  /// `chulian`
  String get chulian {
    return Intl.message(
      'chulian',
      name: 'chulian',
      desc: '',
      args: [],
    );
  }

  /// `chuxue`
  String get chuxue {
    return Intl.message(
      'chuxue',
      name: 'chuxue',
      desc: '',
      args: [],
    );
  }

  /// `fenci`
  String get fenci {
    return Intl.message(
      'fenci',
      name: 'fenci',
      desc: '',
      args: [],
    );
  }

  /// `lengdong`
  String get lengdong {
    return Intl.message(
      'lengdong',
      name: 'lengdong',
      desc: '',
      args: [],
    );
  }

  /// `mengjing`
  String get mengjing {
    return Intl.message(
      'mengjing',
      name: 'mengjing',
      desc: '',
      args: [],
    );
  }

  /// `qingtou`
  String get qingtou {
    return Intl.message(
      'qingtou',
      name: 'qingtou',
      desc: '',
      args: [],
    );
  }

  /// `xinye`
  String get xinye {
    return Intl.message(
      'xinye',
      name: 'xinye',
      desc: '',
      args: [],
    );
  }

  /// `bingcha`
  String get bingcha {
    return Intl.message(
      'bingcha',
      name: 'bingcha',
      desc: '',
      args: [],
    );
  }

  /// `langman`
  String get langman {
    return Intl.message(
      'langman',
      name: 'langman',
      desc: '',
      args: [],
    );
  }

  /// `miwu`
  String get miwu {
    return Intl.message(
      'miwu',
      name: 'miwu',
      desc: '',
      args: [],
    );
  }

  /// `qingmu`
  String get qingmu {
    return Intl.message(
      'qingmu',
      name: 'qingmu',
      desc: '',
      args: [],
    );
  }

  /// `qingsha`
  String get qingsha {
    return Intl.message(
      'qingsha',
      name: 'qingsha',
      desc: '',
      args: [],
    );
  }

  /// `qingxu`
  String get qingxu {
    return Intl.message(
      'qingxu',
      name: 'qingxu',
      desc: '',
      args: [],
    );
  }

  /// `senwu`
  String get senwu {
    return Intl.message(
      'senwu',
      name: 'senwu',
      desc: '',
      args: [],
    );
  }

  /// `shaman`
  String get shaman {
    return Intl.message(
      'shaman',
      name: 'shaman',
      desc: '',
      args: [],
    );
  }

  /// `wenrou`
  String get wenrou {
    return Intl.message(
      'wenrou',
      name: 'wenrou',
      desc: '',
      args: [],
    );
  }

  /// `miaohui`
  String get miaohui {
    return Intl.message(
      'miaohui',
      name: 'miaohui',
      desc: '',
      args: [],
    );
  }

  /// `qingkong`
  String get qingkong {
    return Intl.message(
      'qingkong',
      name: 'qingkong',
      desc: '',
      args: [],
    );
  }

  /// `shanjian`
  String get shanjian {
    return Intl.message(
      'shanjian',
      name: 'shanjian',
      desc: '',
      args: [],
    );
  }

  /// `xiangsong`
  String get xiangsong {
    return Intl.message(
      'xiangsong',
      name: 'xiangsong',
      desc: '',
      args: [],
    );
  }

  /// `biaozhun`
  String get biaozhun {
    return Intl.message(
      'biaozhun',
      name: 'biaozhun',
      desc: '',
      args: [],
    );
  }

  /// `shuiguang`
  String get shuiguang {
    return Intl.message(
      'shuiguang',
      name: 'shuiguang',
      desc: '',
      args: [],
    );
  }

  /// `shuiwu`
  String get shuiwu {
    return Intl.message(
      'shuiwu',
      name: 'shuiwu',
      desc: '',
      args: [],
    );
  }

  /// `lengdan`
  String get lengdan {
    return Intl.message(
      'lengdan',
      name: 'lengdan',
      desc: '',
      args: [],
    );
  }

  /// `bailan`
  String get bailan {
    return Intl.message(
      'bailan',
      name: 'bailan',
      desc: '',
      args: [],
    );
  }

  /// `chunzhen`
  String get chunzhen {
    return Intl.message(
      'chunzhen',
      name: 'chunzhen',
      desc: '',
      args: [],
    );
  }

  /// `chaotuo`
  String get chaotuo {
    return Intl.message(
      'chaotuo',
      name: 'chaotuo',
      desc: '',
      args: [],
    );
  }

  /// `senxi`
  String get senxi {
    return Intl.message(
      'senxi',
      name: 'senxi',
      desc: '',
      args: [],
    );
  }

  /// `nuanyang`
  String get nuanyang {
    return Intl.message(
      'nuanyang',
      name: 'nuanyang',
      desc: '',
      args: [],
    );
  }

  /// `xiari`
  String get xiari {
    return Intl.message(
      'xiari',
      name: 'xiari',
      desc: '',
      args: [],
    );
  }

  /// `mitaowulong`
  String get mitaowulong {
    return Intl.message(
      'mitaowulong',
      name: 'mitaowulong',
      desc: '',
      args: [],
    );
  }

  /// `shaonv`
  String get shaonv {
    return Intl.message(
      'shaonv',
      name: 'shaonv',
      desc: '',
      args: [],
    );
  }

  /// `yuanqi`
  String get yuanqi {
    return Intl.message(
      'yuanqi',
      name: 'yuanqi',
      desc: '',
      args: [],
    );
  }

  /// `feiying`
  String get feiying {
    return Intl.message(
      'feiying',
      name: 'feiying',
      desc: '',
      args: [],
    );
  }

  /// `qingxin`
  String get qingxin {
    return Intl.message(
      'qingxin',
      name: 'qingxin',
      desc: '',
      args: [],
    );
  }

  /// `rixi`
  String get rixi {
    return Intl.message(
      'rixi',
      name: 'rixi',
      desc: '',
      args: [],
    );
  }

  /// `fanchase`
  String get fanchase {
    return Intl.message(
      'fanchase',
      name: 'fanchase',
      desc: '',
      args: [],
    );
  }

  /// `fugu`
  String get fugu {
    return Intl.message(
      'fugu',
      name: 'fugu',
      desc: '',
      args: [],
    );
  }

  /// `huiyi`
  String get huiyi {
    return Intl.message(
      'huiyi',
      name: 'huiyi',
      desc: '',
      args: [],
    );
  }

  /// `huaijiu`
  String get huaijiu {
    return Intl.message(
      'huaijiu',
      name: 'huaijiu',
      desc: '',
      args: [],
    );
  }




  /// `cloud`
  String get yunshang {
    return Intl.message(
      'cloud',
      name: 'yunshang',
      desc: '',
      args: [],
    );
  }

  /// `chunzhen`
  String get name_chunzhen {
    return Intl.message(
      'chunzhen',
      name: 'name_chunzhen',
      desc: '',
      args: [],
    );
  }

  /// `white`
  String get name_white {
    return Intl.message(
      'white',
      name: 'name_white',
      desc: '',
      args: [],
    );
  }

  /// `qingxin`
  String get name_qingxin {
    return Intl.message(
      'qingxin',
      name: 'name_qingxin',
      desc: '',
      args: [],
    );
  }

  /// `langman`
  String get name_romantic {
    return Intl.message(
      'langman',
      name: 'name_romantic',
      desc: '',
      args: [],
    );
  }

  /// `rixi`
  String get name_rixi {
    return Intl.message(
      'rixi',
      name: 'name_rixi',
      desc: '',
      args: [],
    );
  }

  /// `qingliang`
  String get name_qingliang {
    return Intl.message(
      'qingliang',
      name: 'name_qingliang',
      desc: '',
      args: [],
    );
  }

  /// `bailan`
  String get name_bailan {
    return Intl.message(
      'bailan',
      name: 'name_bailan',
      desc: '',
      args: [],
    );
  }

  /// `landiao`
  String get name_landiao {
    return Intl.message(
      'landiao',
      name: 'name_landiao',
      desc: '',
      args: [],
    );
  }

  /// `chaotuo`
  String get name_chaotuo {
    return Intl.message(
      'chaotuo',
      name: 'name_chaotuo',
      desc: '',
      args: [],
    );
  }

  /// `fennen`
  String get name_fennen {
    return Intl.message(
      'fennen',
      name: 'name_fennen',
      desc: '',
      args: [],
    );
  }

  /// `biaozhun`
  String get name_standard_filter {
    return Intl.message(
      'biaozhun',
      name: 'name_standard_filter',
      desc: '',
      args: [],
    );
  }

  /// `huaijiu`
  String get name_huaijiu {
    return Intl.message(
      'huaijiu',
      name: 'name_huaijiu',
      desc: '',
      args: [],
    );
  }

  /// `weimei`
  String get name_weimei {
    return Intl.message(
      'weimei',
      name: 'name_weimei',
      desc: '',
      args: [],
    );
  }

  /// `xiangfen`
  String get name_xiangfen {
    return Intl.message(
      'xiangfen',
      name: 'name_xiangfen',
      desc: '',
      args: [],
    );
  }

  /// `yinghong`
  String get name_yinghong {
    return Intl.message(
      'yinghong',
      name: 'name_yinghong',
      desc: '',
      args: [],
    );
  }

  /// `yuanqi`
  String get name_yuanqi {
    return Intl.message(
      'yuanqi',
      name: 'name_yuanqi',
      desc: '',
      args: [],
    );
  }

  /// `yunshang`
  String get name_yunshang {
    return Intl.message(
      'yunshang',
      name: 'name_yunshang',
      desc: '',
      args: [],
    );
  }

  /// `MiracleFilter`
  String get effect_filter {
    return Intl.message(
      'MiracleFilter',
      name: 'effect_filter',
      desc: '',
      args: [],
    );
  }

  /// `lhcq`
  String get lhcq {
    return Intl.message(
      'lhcq',
      name: 'lhcq',
      desc: '',
      args: [],
    );
  }

  /// `hbdy`
  String get hbdy {
    return Intl.message(
      'hbdy',
      name: 'hbdy',
      desc: '',
      args: [],
    );
  }

  /// `mfjm`
  String get mfjm {
    return Intl.message(
      'mfjm',
      name: 'mfjm',
      desc: '',
      args: [],
    );
  }

  /// `xcdd`
  String get xcdd {
    return Intl.message(
      'xcdd',
      name: 'xcdd',
      desc: '',
      args: [],
    );
  }

  /// `tymx`
  String get tymx {
    return Intl.message(
      'tymx',
      name: 'tymx',
      desc: '',
      args: [],
    );
  }

  /// `dgfp`
  String get dgfp {
    return Intl.message(
      'dgfp',
      name: 'dgfp',
      desc: '',
      args: [],
    );
  }

  /// `sgg`
  String get sgg {
    return Intl.message(
      'sgg',
      name: 'sgg',
      desc: '',
      args: [],
    );
  }

  /// `spjx`
  String get spjx {
    return Intl.message(
      'spjx',
      name: 'spjx',
      desc: '',
      args: [],
    );
  }

  /// `mbl`
  String get mbl {
    return Intl.message(
      'mbl',
      name: 'mbl',
      desc: '',
      args: [],
    );
  }

  /// `bjmh`
  String get bjmh {
    return Intl.message(
      'bjmh',
      name: 'bjmh',
      desc: '',
      args: [],
    );
  }

  /// `mhfp`
  String get mhfp {
    return Intl.message(
      'mhfp',
      name: 'mhfp',
      desc: '',
      args: [],
    );
  }

  /// `sjsh`
  String get sjsh {
    return Intl.message(
      'sjsh',
      name: 'sjsh',
      desc: '',
      args: [],
    );
  }

  /// `qcdd`
  String get qcdd {
    return Intl.message(
      'qcdd',
      name: 'qcdd',
      desc: '',
      args: [],
    );
  }

  /// `yjlg`
  String get yjlg {
    return Intl.message(
      'yjlg',
      name: 'yjlg',
      desc: '',
      args: [],
    );
  }

  /// `jgg`
  String get jgg {
    return Intl.message(
      'jgg',
      name: 'jgg',
      desc: '',
      args: [],
    );
  }

  /// `fgj`
  String get fgj {
    return Intl.message(
      'fgj',
      name: 'fgj',
      desc: '',
      args: [],
    );
  }

  /// `xnjx`
  String get xnjx {
    return Intl.message(
      'xnjx',
      name: 'xnjx',
      desc: '',
      args: [],
    );
  }

  /// `hjcy`
  String get hjcy {
    return Intl.message(
      'hjcy',
      name: 'hjcy',
      desc: '',
      args: [],
    );
  }

  /// `sfp`
  String get sfp {
    return Intl.message(
      'sfp',
      name: 'sfp',
      desc: '',
      args: [],
    );
  }

  /// `sbl`
  String get sbl {
    return Intl.message(
      'sbl',
      name: 'sbl',
      desc: '',
      args: [],
    );
  }

  /// `katong`
  String get key_katong {
    return Intl.message(
      'katong',
      name: 'key_katong',
      desc: '',
      args: [],
    );
  }

  /// `youhua`
  String get key_youhua {
    return Intl.message(
      'youhua',
      name: 'key_youhua',
      desc: '',
      args: [],
    );
  }

  /// `sumiao`
  String get key_sumiao {
    return Intl.message(
      'sumiao',
      name: 'key_sumiao',
      desc: '',
      args: [],
    );
  }

  /// `banhua`
  String get key_banhua {
    return Intl.message(
      'banhua',
      name: 'key_banhua',
      desc: '',
      args: [],
    );
  }

  /// `fudiao`
  String get key_fudiao {
    return Intl.message(
      'fudiao',
      name: 'key_fudiao',
      desc: '',
      args: [],
    );
  }

  /// `masaike`
  String get key_masaike {
    return Intl.message(
      'masaike',
      name: 'key_masaike',
      desc: '',
      args: [],
    );
  }

  /// `yundong`
  String get key_yundong {
    return Intl.message(
      'yundong',
      name: 'key_yundong',
      desc: '',
      args: [],
    );
  }

  /// `jiaopian`
  String get key_jiaopian {
    return Intl.message(
      'jiaopian',
      name: 'key_jiaopian',
      desc: '',
      args: [],
    );
  }

  /// `yunying`
  String get key_yunying {
    return Intl.message(
      'yunying',
      name: 'key_yunying',
      desc: '',
      args: [],
    );
  }

  /// `aozhaopian`
  String get key_laozhaopian {
    return Intl.message(
      'aozhaopian',
      name: 'key_laozhaopian',
      desc: '',
      args: [],
    );
  }

  /// `FunnyFilter`
  String get funny_filter {
    return Intl.message(
      'FunnyFilter',
      name: 'funny_filter',
      desc: '',
      args: [],
    );
  }

  /// `Alien`
  String get funny_alien {
    return Intl.message(
      'Alien',
      name: 'funny_alien',
      desc: '',
      args: [],
    );
  }

  /// `BigNose`
  String get funny_big_nose {
    return Intl.message(
      'BigNose',
      name: 'funny_big_nose',
      desc: '',
      args: [],
    );
  }

  /// `BigMouth`
  String get funny_big_mouth {
    return Intl.message(
      'BigMouth',
      name: 'funny_big_mouth',
      desc: '',
      args: [],
    );
  }

  /// `SquareFace`
  String get funny_square_face {
    return Intl.message(
      'SquareFace',
      name: 'funny_square_face',
      desc: '',
      args: [],
    );
  }

  /// `BigHead`
  String get funny_big_head {
    return Intl.message(
      'BigHead',
      name: 'funny_big_head',
      desc: '',
      args: [],
    );
  }

  /// `PlumpFace`
  String get funny_plump_face {
    return Intl.message(
      'PlumpFace',
      name: 'funny_plump_face',
      desc: '',
      args: [],
    );
  }

  /// `PeasEyes`
  String get funny_peas_eyes {
    return Intl.message(
      'PeasEyes',
      name: 'funny_peas_eyes',
      desc: '',
      args: [],
    );
  }

  /// `LargeForehead`
  String get funny_large_forehead {
    return Intl.message(
      'LargeForehead',
      name: 'funny_large_forehead',
      desc: '',
      args: [],
    );
  }

  /// `ArchFace`
  String get funny_arch_face {
    return Intl.message(
      'ArchFace',
      name: 'funny_arch_face',
      desc: '',
      args: [],
    );
  }

  /// `SnakeSpiritFace`
  String get funny_snake_spirit_face {
    return Intl.message(
      'SnakeSpiritFace',
      name: 'funny_snake_spirit_face',
      desc: '',
      args: [],
    );
  }

  /// `MagicFilter`
  String get magic_filter {
    return Intl.message(
      'MagicFilter',
      name: 'magic_filter',
      desc: '',
      args: [],
    );
  }

  /// `RhythmSplit`
  String get magic_rhythm_split {
    return Intl.message(
      'RhythmSplit',
      name: 'magic_rhythm_split',
      desc: '',
      args: [],
    );
  }

  /// `VirtualMirror`
  String get magic_virtual_mirror {
    return Intl.message(
      'VirtualMirror',
      name: 'magic_virtual_mirror',
      desc: '',
      args: [],
    );
  }

  /// `BlackWhite`
  String get magic_black_white {
    return Intl.message(
      'BlackWhite',
      name: 'magic_black_white',
      desc: '',
      args: [],
    );
  }

  /// `GridView`
  String get magic_grid_view {
    return Intl.message(
      'GridView',
      name: 'magic_grid_view',
      desc: '',
      args: [],
    );
  }

  /// `FourScreen`
  String get magic_four_screen {
    return Intl.message(
      'FourScreen',
      name: 'magic_four_screen',
      desc: '',
      args: [],
    );
  }

  /// `DumpBeatWave`
  String get magic_dump_beat_wave {
    return Intl.message(
      'DumpBeatWave',
      name: 'magic_dump_beat_wave',
      desc: '',
      args: [],
    );
  }

  /// `AngelLight`
  String get magic_angel_light {
    return Intl.message(
      'AngelLight',
      name: 'magic_angel_light',
      desc: '',
      args: [],
    );
  }

  /// `ColorDance`
  String get magic_color_dance {
    return Intl.message(
      'ColorDance',
      name: 'magic_color_dance',
      desc: '',
      args: [],
    );
  }

  /// `FlashBurr`
  String get magic_flash_burr {
    return Intl.message(
      'FlashBurr',
      name: 'magic_flash_burr',
      desc: '',
      args: [],
    );
  }

  /// `IllusionVignette`
  String get magic_illusion_vignette {
    return Intl.message(
      'IllusionVignette',
      name: 'magic_illusion_vignette',
      desc: '',
      args: [],
    );
  }

  /// `ToneFilter`
  String get tone_filter {
    return Intl.message(
      'ToneFilter',
      name: 'tone_filter',
      desc: '',
      args: [],
    );
  }

  /// `LightExposure`
  String get tone_light_exposure {
    return Intl.message(
      'LightExposure',
      name: 'tone_light_exposure',
      desc: '',
      args: [],
    );
  }

  /// `Highlight`
  String get tone_highlight {
    return Intl.message(
      'Highlight',
      name: 'tone_highlight',
      desc: '',
      args: [],
    );
  }

  /// `Gray`
  String get tone_gray {
    return Intl.message(
      'Gray',
      name: 'tone_gray',
      desc: '',
      args: [],
    );
  }

  /// `American`
  String get tone_american {
    return Intl.message(
      'American',
      name: 'tone_american',
      desc: '',
      args: [],
    );
  }

  /// `BurlyWood`
  String get tone_burly_wood {
    return Intl.message(
      'BurlyWood',
      name: 'tone_burly_wood',
      desc: '',
      args: [],
    );
  }

  /// `LowKey`
  String get tone_low_key {
    return Intl.message(
      'LowKey',
      name: 'tone_low_key',
      desc: '',
      args: [],
    );
  }

  /// `Lucency`
  String get tone_lucency {
    return Intl.message(
      'Lucency',
      name: 'tone_lucency',
      desc: '',
      args: [],
    );
  }

  /// `tone_key_light_exposure`
  String get tone_key_light_exposure {
    return Intl.message(
      'tone_key_light_exposure',
      name: 'tone_key_light_exposure',
      desc: '',
      args: [],
    );
  }

  /// `tone_key_highlight`
  String get tone_key_highlight {
    return Intl.message(
      'tone_key_highlight',
      name: 'tone_key_highlight',
      desc: '',
      args: [],
    );
  }

  /// `tone_key_gray`
  String get tone_key_gray {
    return Intl.message(
      'tone_key_gray',
      name: 'tone_key_gray',
      desc: '',
      args: [],
    );
  }

  /// `tone_key_american`
  String get tone_key_american {
    return Intl.message(
      'tone_key_american',
      name: 'tone_key_american',
      desc: '',
      args: [],
    );
  }

  /// `tone_key_burly_wood`
  String get tone_key_burly_wood {
    return Intl.message(
      'tone_key_burly_wood',
      name: 'tone_key_burly_wood',
      desc: '',
      args: [],
    );
  }

  /// `tone_key_low_key`
  String get tone_key_low_key {
    return Intl.message(
      'tone_key_low_key',
      name: 'tone_key_low_key',
      desc: '',
      args: [],
    );
  }

  /// `tone_key_lucency`
  String get tone_key_lucency {
    return Intl.message(
      'tone_key_lucency',
      name: 'tone_key_lucency',
      desc: '',
      args: [],
    );
  }

  /// `QuickBeauty`
  String get quick_beauty {
    return Intl.message(
      'QuickBeauty',
      name: 'quick_beauty',
      desc: '',
      args: [],
    );
  }

  /// `Standard`
  String get standard {
    return Intl.message(
      'Standard',
      name: 'standard',
      desc: '',
      args: [],
    );
  }

  /// `Lolita`
  String get lolita {
    return Intl.message(
      'Lolita',
      name: 'lolita',
      desc: '',
      args: [],
    );
  }

  /// `Goddess`
  String get goddess {
    return Intl.message(
      'Goddess',
      name: 'goddess',
      desc: '',
      args: [],
    );
  }

  /// `Celebrity`
  String get celebrity {
    return Intl.message(
      'Celebrity',
      name: 'celebrity',
      desc: '',
      args: [],
    );
  }

  /// `Natural`
  String get natural {
    return Intl.message(
      'Natural',
      name: 'natural',
      desc: '',
      args: [],
    );
  }

  /// `Milk`
  String get milk {
    return Intl.message(
      'Milk',
      name: 'milk',
      desc: '',
      args: [],
    );
  }

  /// `Painting`
  String get painting {
    return Intl.message(
      'Painting',
      name: 'painting',
      desc: '',
      args: [],
    );
  }

  /// `Nectarine`
  String get nectarine {
    return Intl.message(
      'Nectarine',
      name: 'nectarine',
      desc: '',
      args: [],
    );
  }

  /// `Carmel`
  String get carmel {
    return Intl.message(
      'Carmel',
      name: 'carmel',
      desc: '',
      args: [],
    );
  }

  /// `Holiday`
  String get holiday {
    return Intl.message(
      'Holiday',
      name: 'holiday',
      desc: '',
      args: [],
    );
  }

  /// `qingchunbaihua`
  String get qingchunbaihua {
    return Intl.message(
      'qingchunbaihua',
      name: 'qingchunbaihua',
      desc: '',
      args: [],
    );
  }

  /// `huximeiren`
  String get huximeiren {
    return Intl.message(
      'huximeiren',
      name: 'huximeiren',
      desc: '',
      args: [],
    );
  }

  /// `qingtianzhuang`
  String get qingtianzhuang {
    return Intl.message(
      'qingtianzhuang',
      name: 'qingtianzhuang',
      desc: '',
      args: [],
    );
  }

  /// `bailu`
  String get bailu {
    return Intl.message(
      'bailu',
      name: 'bailu',
      desc: '',
      args: [],
    );
  }

  /// `lengdiao`
  String get lengdiao {
    return Intl.message(
      'lengdiao',
      name: 'lengdiao',
      desc: '',
      args: [],
    );
  }

  /// `yuanqishaonv`
  String get yuanqishaonv {
    return Intl.message(
      'yuanqishaonv',
      name: 'yuanqishaonv',
      desc: '',
      args: [],
    );
  }

  /// `nvtuan`
  String get nvtuan {
    return Intl.message(
      'nvtuan',
      name: 'nvtuan',
      desc: '',
      args: [],
    );
  }

  /// `chunyuzhuang`
  String get chunyuzhuang {
    return Intl.message(
      'chunyuzhuang',
      name: 'chunyuzhuang',
      desc: '',
      args: [],
    );
  }

  /// `portrait`
  String get portrait {
    return Intl.message(
      'portrait',
      name: 'portrait',
      desc: '',
      args: [],
    );
  }

  /// `GreenScreen`
  String get green_screen {
    return Intl.message(
      'GreenScreen',
      name: 'green_screen',
      desc: '',
      args: [],
    );
  }

  /// `NONE`
  String get none {
    return Intl.message(
      'NONE',
      name: 'none',
      desc: '',
      args: [],
    );
  }

  /// ``
  String get name_none {
    return Intl.message(
      '',
      name: 'name_none',
      desc: '',
      args: [],
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'zh', countryCode: 'CN'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
