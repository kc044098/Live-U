import 'package:get/get.dart';
import 'package:mt_plugin/bean/expressions.dart';
import 'package:mt_plugin/components/expressions/state.dart';
import 'package:mt_plugin/dio_utils.dart';
import 'package:mt_plugin/mt_plugin.dart';
import '../../file_tools.dart';



class ExpressionsViewLogic extends GetxController {
  final ExpressionState state = ExpressionState();

  //点击表情的处理
  void clickExpression(Rx<Expression> expression) {
    if (expression.value.isDownloading == true) return;

    if (expression.value.downloaded == false &&
        expression.value.isDownloading == false) {
      expression.update((value) {
        value?.isDownloading = true;
      });

      DioUtils.instance.downloadExpression(expression.value.dir, (dynamic) {
        expression.update((value) {
          value?.isDownloading = false;
          value?.setDownload(true);
          List<Expression> list = state.items.map((e) => e.value).toList();
          FileTools.instance.saveExpressions(list);
        });
      }, (error) {
        expression.update((value) {
          value?.isDownloading = false;
        });
      });
    } else {
      state.items.forEach((element) {
        element.update((value) {
          value?.isSelected = false;
        });
      });

      expression.update((value) {
        value?.isSelected = true;
      });
      state.canCancel(true);
      MtPlugin.setExpressionRecreationName(expression.value.name.toString());
    }
  }

  void cancelAll() {
    state.canCancel(false);
    state.items.forEach((element) {
      element.update((value) {
        value?.isSelected = false;
      });
    });
    MtPlugin.setExpressionRecreationName("");
  }
}
