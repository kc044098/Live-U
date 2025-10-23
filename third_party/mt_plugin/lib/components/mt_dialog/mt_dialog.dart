import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mt_plugin/components/theme/mt_theme.dart';


class MtDialog extends Dialog {
  final String title;

  final Function onClickOk;

  final Function onClickCancel;

  MtDialog(
      {Key? key,
      this.title = "将所有参数恢复默认吗？",
      required this.onClickOk,
      required this.onClickCancel})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width; //屏幕宽度
    double screenHeight = MediaQuery.of(context).size.height; //屏幕高度
    double mHorizontalMargin = 45.0; //水平间距
    double verticalMargin =
        (screenHeight - (screenWidth - 2 * mHorizontalMargin) * 3 / 4) / 2 -
            15; //垂直间距
    return Container(
      margin: EdgeInsets.only(
          left: mHorizontalMargin,
          right: mHorizontalMargin,
          top: verticalMargin,
          bottom: verticalMargin),
      height: double.minPositive,
      alignment: Alignment.center,
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(10))),
      //圆角
      child: Stack(
        alignment: Alignment(0, 0), //居中对齐
        children: <Widget>[
          Positioned(
            top: 40,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  '${title}',
                  style: TextStyle(
                      fontSize: 13,
                      decoration: TextDecoration.none,
                      color: Colors.black87,
                      fontStyle: FontStyle.normal,
                      fontWeight: FontWeight.normal),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 25),
                Container(
                  width: 180,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFFFC9DD4),
                          Color(0xFFFF8BC0),
                          Color(0xFFB2DDFC)
                        ],
                      )),
                  child: TextButton(
                    style: ButtonStyle(
                        padding: MaterialStateProperty.all(EdgeInsets.all(2)),
                        backgroundColor:
                            MaterialStateProperty.all(Colors.transparent),
                        shape: MaterialStateProperty.all(RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24.0)))),
                    onPressed: () {
                      onClickOk();
                      Get.back();
                    },
                    child: Text(
                      '确定',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ), //按钮形状
                  ),
                ),
                SizedBox(height: 18),
                Container(
                  width: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextButton(
                    style: ButtonStyle(
                        padding: MaterialStateProperty.all(EdgeInsets.all(2)),
                        backgroundColor:
                            MaterialStateProperty.all(Colors.transparent),
                        shape: MaterialStateProperty.all(RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24.0)))),
                    onPressed: () {
                      onClickCancel();
                      Get.back();
                    },
                    child: Text(
                      '取消',
                      style:
                          TextStyle(color: MtTheme.THEME_COLOR, fontSize: 13),
                    ), //按钮形状
                  ),
                ),
                SizedBox(height: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }

  show(BuildContext context) {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return this;
        });
  }
}
