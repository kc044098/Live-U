import 'dart:io';

import 'package:archive/archive.dart';
import 'package:dio/dio.dart';

import 'file_tools.dart';

typedef DioCallback<D> = dynamic Function(D data);

/**
 * 下载的网络请求封装
 */
class DioUtils {
  static DioUtils? _instance;

  String url = "https://hteffect-resource.oss-cn-shanghai.aliyuncs.com/";

  late Dio dio;

  static DioUtils get instance => getInstance();

  late BaseOptions options;

  DioUtils() {
    dio = Dio();
  }

  DioUtils.init() {
    options = new BaseOptions();
    // options.connectTimeout = 5000;
    // options = new BaseOptions(connectTimeout: 5000, maxRedirects: 10);
    dio = new Dio(options);
  }

  static DioUtils getInstance() {
    if (_instance == null) {
      _instance = DioUtils.init();
    }
    return _instance!;
  }

  /**
   * 下载贴纸
   * dir:贴纸dir
   * successCallback:成功的回调
   * failCallback:失败的回调
   */
  downloadSticker(String? dir, DioCallback<dynamic> successCallBack,
      DioCallback<DioError> failCallBack) async {
    if (Platform.isAndroid) {
      downloadZipFile(
          "${this.url + "sticker/"}${dir}.zip",
          "${FileTools.instance.PATH_BASE}/files/fbeffect/sticker/${dir}.zip",
          "${FileTools.instance.PATH_BASE}/files/fbeffect/sticker",
          (data) => {},
          successCallBack,
          failCallBack);
    } else if (Platform.isIOS) {
      downloadZipFile(
          "${this.url + "sticker/"}${dir}.zip",
          "${FileTools.instance.PATH_BASE}/FBEffect/sticker/${dir}.zip",
          "${FileTools.instance.PATH_BASE}/FBEffect/sticker",
          (data) => {},
          successCallBack,
          failCallBack);
    }
  }

  /**
   * 下载表情
   * dir:表情dir
   * successCallback:成功的回调
   * failCallback:失败的回调
   */
  downloadExpression(String? dir, DioCallback<dynamic> successCallBack,
      DioCallback<DioError> failCallBack) async {
    if (Platform.isAndroid) {
      downloadZipFile(
          "${this.url + "expression/"}${dir}.zip",
          "${FileTools.instance.PATH_BASE}/files/toivan/expression/${dir}.zip",
          "${FileTools.instance.PATH_BASE}/files/toivan/expression",
          (data) => {},
          successCallBack,
          failCallBack);
    } else if (Platform.isIOS) {
      downloadZipFile(
          "${this.url + "expression/"}${dir}.zip",
          "${FileTools.instance.PATH_BASE}/Toivan/expression/${dir}.zip",
          "${FileTools.instance.PATH_BASE}/Toivan/expression",
          (data) => {},
          successCallBack,
          failCallBack);
    }
  }

  /**
   * 下载面具
   * dir:面具dir
   * successCallback:成功的回调
   * failCallback:失败的回调
   */
  downloadMask(String? dir, DioCallback<dynamic> successCallBack,
      DioCallback<DioError> failCallBack) async {
    if (Platform.isAndroid) {
      downloadZipFile(
          "${this.url + "mask/"}${dir}.zip",
          "${FileTools.instance.PATH_BASE}/files/fbeffect/mask/${dir}.zip",
          "${FileTools.instance.PATH_BASE}/files/fbeffect/mask",
          (data) => {},
          successCallBack,
          failCallBack);
    } else if (Platform.isIOS) {
      downloadZipFile(
          "${this.url + "mask/"}${dir}.zip",
          "${FileTools.instance.PATH_BASE}/FBEffect/mask/${dir}.zip",
          "${FileTools.instance.PATH_BASE}/FBEffect/mask",
          (data) => {},
          successCallBack,
          failCallBack);
    }
  }

  /**
   * 下载礼物
   * dir:礼物dir
   * successCallback:成功的回调
   * failCallback:失败的回调
   */
  downloadGift(String? dir, DioCallback<dynamic> successCallBack,
      DioCallback<DioError> failCallBack) async {
    if (Platform.isAndroid) {
      downloadZipFile(
          "${this.url + "gift/"}${dir}.zip",
          "${FileTools.instance.PATH_BASE}/files/fbeffect/gift/${dir}.zip",
          "${FileTools.instance.PATH_BASE}/files/fbeffect/gift",
              (data) => {},
          successCallBack,
          failCallBack);
    } else if (Platform.isIOS) {
      downloadZipFile(
          "${this.url + "gift/"}${dir}.zip",
          "${FileTools.instance.PATH_BASE}/FBEffect/gift/${dir}.zip",
          "${FileTools.instance.PATH_BASE}/FBEffect/gift",
              (data) => {},
          successCallBack,
          failCallBack);
    }
  }

  /**
   * 下载水印
   * dir:水印dir
   * successCallback:成功的回调
   * failCallback:失败的回调
   */
  downloadWaterMark(String? dir, DioCallback<dynamic> successCallBack,
      DioCallback<DioError> failCallBack) async {
    if (Platform.isAndroid) {
      downloadZipFile(
          "${this.url + "watermark/"}${dir}.zip",
          "${FileTools.instance.PATH_BASE}/files/toivan/watermark/${dir}.zip",
          "${FileTools.instance.PATH_BASE}/files/toivan/watermark",
              (data) => {},
          successCallBack,
          failCallBack);
    } else if (Platform.isIOS) {
      downloadZipFile(
          "${this.url + "watermark/"}${dir}.zip",
          "${FileTools.instance.PATH_BASE}/Toivan/watermark/${dir}.zip",
          "${FileTools.instance.PATH_BASE}/Toivan/watermark",
              (data) => {},
          successCallBack,
          failCallBack);
    }
  }

  /**
   * 下载人像抠图
   * dir:下载地址
   * successCallBack：成功的回调
   * failCallBack：失败的回调
   */
  downloadPortrait(String? dir, DioCallback<dynamic> successCallBack,
      DioCallback<DioError> failCallBack) {
    if (Platform.isAndroid) {
      downloadZipFile(
          "${this.url + "portrait/"}${dir}.zip",
          "${FileTools.instance.PATH_BASE}/files/toivan/portrait/${dir}.zip",
          "${FileTools.instance.PATH_BASE}/files/toivan/portrait",
          (data) => {},
          successCallBack,
          failCallBack);
    } else if (Platform.isIOS) {
      downloadZipFile(
          "${this.url + "portrait/"}${dir}.zip",
          "${FileTools.instance.PATH_BASE}/Toivan/portrait/${dir}.zip",
          "${FileTools.instance.PATH_BASE}/Toivan/portrait",
          (data) => {},
          successCallBack,
          failCallBack);
    }
  }

  /**
   * 下载绿幕资源文件
   * dir:下载地址
   * successCallBack：成功的回调
   * failCallBack：失败的回调
   */
  downloadGreenScreen(String? dir, DioCallback<dynamic> successCallBack,
      DioCallback<DioError> failCallBack) {
    if (Platform.isAndroid) {
      downloadFile(
          "${this.url + "greenscreen/"}${dir}.png",
          "${FileTools.instance.PATH_BASE}/files/toivan/greenscreen/${dir}.png",
          "${FileTools.instance.PATH_BASE}/files/toivan/greenscreen",
          (data) => {},
          successCallBack,
          failCallBack);
    } else if (Platform.isIOS) {
      downloadFile(
          "${this.url + "greenscreen/"}${dir}.png",
          "${FileTools.instance.PATH_BASE}/Toivan/greenscreen/${dir}.png",
          "${FileTools.instance.PATH_BASE}/Toivan/greenscreen",
          (data) => {},
          successCallBack,
          failCallBack);
    }
  }

  /**
   * 下载气氛
   * dir:气氛dir
   * successCallback:成功的回调
   * failCallback:失败的回调
   */
  downloadAtmosphere(String? dir, DioCallback<dynamic> successCallBack,
      DioCallback<DioError> failCallBack) async {
    if (Platform.isAndroid) {
      downloadZipFile(
          "${this.url + "atmosphere/"}${dir}.zip",
          "${FileTools.instance.PATH_BASE}/files/toivan/atmosphere/${dir}.zip",
          "${FileTools.instance.PATH_BASE}/files/toivan/atmosphere",
          (data) => {},
          successCallBack,
          failCallBack);
    } else if (Platform.isIOS) {
      downloadZipFile(
          "${this.url + "atmosphere/"}${dir}.zip",
          "${FileTools.instance.PATH_BASE}/Toivan/atmosphere/${dir}.zip",
          "${FileTools.instance.PATH_BASE}/Toivan/atmosphere",
          (data) => {},
          successCallBack,
          failCallBack);
    }
  }

  /**
   * 下载文件
   * url:下载的网络地址
   * savePath:保存的地址
   * totalCallback:进度回调
   * successCallback:成功的回调
   * failCallback:失败的回调
   */
  downloadZipFile(
      String urlPath,
      String saveFirepath,
      String savePath,
      DioCallback<int> fractCallback,
      DioCallback<dynamic> successCallBack,
      DioCallback<DioError> failCallBack) async {
    Response? response;
    try {
      response = await dio.download(urlPath, saveFirepath,
          onReceiveProgress: (int count, int total) {
        //进度
        print("进度：${(count / total) * 100}%");
        fractCallback(((count / total) * 100).toInt());
      });
      print('----------下载成功---------');
      //获取下载的内容
      File zipFile = File(saveFirepath);
      //读取下载的zip文件
      List<int> bytes = zipFile.readAsBytesSync();
      //进行解码
      Archive archive = ZipDecoder().decodeBytes(bytes);

      //将内容放到磁盘
      for (ArchiveFile file in archive) {
        if (file.isFile) {
          List<int> data = file.content;
          File(savePath + "/" + file.name)
            ..createSync(recursive: true)
            ..writeAsBytesSync(data);
        } else {
          Directory(savePath + "/" + file.name)..create(recursive: true);
        }
      }
      successCallBack(null);
      print("解压完成");
    } on DioError catch (e) {
      print('下载失败---------$e');
      formatError(e);
      failCallBack(e);
    }
    return response?.data;
  }

  /**
   * 下载文件
   * url:下载的网络地址
   * savePath:保存的地址
   * totalCallback:进度回调
   * successCallback:成功的回调
   * failCallback:失败的回调
   */
  downloadFile(
      String urlPath,
      String saveFirepath,
      String savePath,
      DioCallback<int> fractCallback,
      DioCallback<dynamic> successCallBack,
      DioCallback<DioError> failCallBack) async {
    Response? response;
    try {
      response = await dio.download(urlPath, saveFirepath,
          onReceiveProgress: (int count, int total) {
        //进度
        print("进度：${((count / total) * 100).round()}%");
        fractCallback(((count / total) * 100).toInt());
      });
      print('----------下载成功---------');
      successCallBack(null);
    } on DioError catch (e) {
      print('下载失败---------$e');
      formatError(e);
      failCallBack(e);
    }
    return response?.data;
  }

  /*
   * error统一处理
   */
  void formatError(DioError e) {
    // if (e.type == DioErrorType.connectTimeout) {
    if (e.type == DioErrorType.connectionTimeout) {
      // It occurs when url is opened timeout.
      print("连接超时");
    } else if (e.type == DioErrorType.sendTimeout) {
      // It occurs when url is sent timeout.
      print("请求超时");
    } else if (e.type == DioErrorType.receiveTimeout) {
      //It occurs when receiving timeout
      print("响应超时");
    } else if (e.type == DioErrorType.badResponse) {
      // When the server response, but with a incorrect status, such as 404, 503...
      print("出现异常");
    } else if (e.type == DioErrorType.cancel) {
      // When the request is cancelled, dio will throw a error with this type.
      print("请求取消");
    } else {
      //DEFAULT Default error type, Some other Error. In this case, you can read the DioError.error if it is not null.
      print("未知错误");
    }
  }

  //设置下载url
  void setUrl(String url) {
    this.url = url;
  }
}
