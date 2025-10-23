//
//  FaceBeautyInterface.h
//  FaceBeauty
//

#import <UIKit/UIKit.h>
#import <OpenGLES/gltypes.h>

@protocol FaceBeautyDelegate <NSObject>

/**
 * 网络鉴权初始化成功回调函数
 */
- (void)onInitSuccess;

/**
 * 网络鉴权初始化失败回调函数
 */
- (void)onInitFailure;
 
@end

/**
 * 人脸检测结果报告
 */
@interface FBFaceDetectionReport : NSObject

/// 人脸边界框
@property (nonatomic, assign) CGRect rect;

/// 人脸关键点数组
@property (nonatomic, assign) CGPoint *keyPoints;

/// 人脸偏转角-yaw
@property (nonatomic, assign) CGFloat yaw;

/// 人脸偏转角-pitch
@property (nonatomic, assign) CGFloat pitch;

/// 人脸偏转角-roll
@property (nonatomic, assign) CGFloat roll;

/// 人脸动作-张嘴
@property (nonatomic, assign) CGFloat mouthOpen;

/// 人脸动作-眨眼
@property (nonatomic, assign) CGFloat eyeBlink;

/// 人脸动作-挑眉
@property (nonatomic, assign) CGFloat browJump;

@end

/**
 * 人体检测结果报告
 */
@interface FBPoseDetectionReport : NSObject

/// 人体骨骼关键点坐标
@property (nonatomic, assign) int pointNum;

/// 人体骨骼关键点3D坐标
@property (nonatomic, assign) CGPoint *keyPoints;

/// 人体区域坐标
@property (nonatomic, assign) BOOL *detected;

@end

@interface FaceBeauty: NSObject

#pragma mark - 数据类型

/**
 * 美肤类型枚举
 */
typedef NS_ENUM(NSInteger, FBBeautyTypes) {
    FBBeautySkinWhitening       = 0, //!< 美白，0~100，0为无效果
    FBBeautyClearSmoothing      = 1, //!< 精细磨皮，0~100，0为无效果
    FBBeautySkinRosiness        = 2, //!< 红润，0~100，0为无效果
    FBBeautyImageSharpness      = 3, //!< 锐化（原清晰），0~100，0为无效果
    FBBeautyImageBrightness     = 4, //!< 亮度，-50~50，0为无效果
    FBBeautyDarkCircleLessening = 5, //!< 去黑眼圈，0~100，0为无效果
    FBBeautyNasolabialLessening = 6, //!< 去法令纹，0~100，0为无效果
    FBBeautyToothWhitening      = 7, //!< 美牙，0～100，0为无效果
    FBBeautyEyeBrightening      = 8, //!< 亮眼，0～100，0为无效果
    FBBeautyWhiteBalance        = 9,  //!< 白平衡，-50-50，0为无效果
    FBBeautyImageClarity        = 10, //!< 清晰，0-100， 0为无效果
    FBBeautyFaceContouring      = 11 //!< 五官立体，0-100， 0为无效果
};

/**
 * 美型类型枚举
 */
typedef NS_ENUM(NSInteger, FBReshapeTypes) {
    //! 眼睛
    FBReshapeEyeEnlarging       = 10, //!< 大眼，0-100，0为无效果
    FBReshapeEyeRounding        = 11, //!< 圆眼，0-100，0为无效果
    FBReshapeEyeSpaceTrimming   = 12, //!< 眼间距，-50-50， 0为无效果
    FBReshapeEyeCornerTrimming  = 13, //!< 眼睛角度，-50-50， 0为无效果
    FBReshapeEyeCornerEnlarging = 14, //!< 开眼角，0-100， 0为无效果
    //! 脸廓
    FBReshapeCheekThinning      = 20, //!< 瘦脸，0-100，0为无效果
    FBReshapeCheekVShaping      = 21, //!< V脸，0-100，0为无效果
    FBReshapeCheekNarrowing     = 22, //!< 窄脸，0-100，0为无效果
    FBReshapeCheekboneThinning  = 23, //!< 瘦颧骨，0-100，0为无效果
    FBReshapeJawboneThinning    = 24, //!< 瘦下颌骨，0-100，0为无效果
    FBReshapeTempleEnlarging    = 25, //!< 丰太阳穴，0-100，0为无效果
    FBReshapeHeadLessening      = 26, //!< 小头，0-100，0为无效果
    FBReshapeFaceLessening      = 27, //!< 小脸，0-100，0为无效果
    FBReshapeCheekShortening    = 28, //!< 短脸，0-100，0为无效果
    //! 鼻部
    FBReshapeNoseEnlarging      = 30, //!< 长鼻
    FBReshapeNoseThinning       = 31, //!< 瘦鼻，0-100，0为无效果
    FBReshapeNoseApexLessening  = 32, //!< 鼻头，0-100，0为无效果
    FBReshapeNoseRootEnlarging  = 33, //!< 山根，0-100，0为无效果
    //! 嘴部
    FBReshapeMouthTrimming      = 40, //!< 嘴型，-50-50， 0为无效果
    FBReshapeMouthSmiling       = 41, //!< 微笑嘴角，0-100，0为无效果
    //! 其它
    FBReshapeChinTrimming       = 0,  //!< 下巴，-50-50， 0为无效果
    FBReshapeForeheadTrimming   = 1,  //!< 发际线，-50-50， 0为无效果
    FBReshapePhiltrumTrimming   = 2   //!< 缩人中，-50-50， 0为无效果
};

/**
 * 美发类型枚举
 */
typedef NS_ENUM(NSInteger, FBHairTypes) {
    FBHairTypeNone = 0,  //!< 无美发效果
    FBHairType1    = 1,  //!< 美发类型1，FaceBeauty UI显示名称为"神秘紫"
    FBHairType2    = 2,  //!< 美发类型2，FaceBeauty UI显示名称为"巧克力"
    FBHairType3    = 3,  //!< 美发类型3，FaceBeauty UI显示名称为"青木棕"
    FBHairType4    = 4,  //!< 美发类型4，FaceBeauty UI显示名称为"焦糖棕"
    FBHairType5    = 5,  //!< 美发类型5，FaceBeauty UI显示名称为"落日橘"
    FBHairType6    = 6,  //!< 美发类型6，FaceBeauty UI显示名称为"复古玫瑰"
    FBHairType7    = 7,  //!< 美发类型7，FaceBeauty UI显示名称为"深玫瑰"
    FBHairType8    = 8,  //!< 美发类型8，FaceBeauty UI显示名称为"雾霾香芋"
    FBHairType9    = 9,  //!< 美发类型9，FaceBeauty UI显示名称为"孔雀蓝"
    FBHairType10   = 10, //!< 美发类型10，FaceBeauty UI显示名称为"雾霾蓝灰"
    FBHairType11   = 11, //!< 美发类型11，FaceBeauty UI显示名称为"亚麻灰棕"
    FBHairType12   = 12  //!< 美发类型12，FaceBeauty UI显示名称为"亚麻浅灰"
};

/**
 * 滤镜类型枚举
 *
 * 滤镜类型分为风格滤镜，特效滤镜，哈哈镜
 */
typedef NS_ENUM(NSInteger, FBFilterTypes) {
    FBFilterBeauty = 0, //!< 风格滤镜
    FBFilterEffect = 1, //!< 特效滤镜
    FBFilterFunny  = 2  //!< 哈哈镜
};

/**
 * AR道具类型枚举
 *
 * AR道具类型目前支持2D贴纸，面具，礼物，水印
 */
typedef NS_ENUM(NSInteger, FBARItemTypes) {
    FBItemSticker   = 0, //!< 2D贴纸
    FBItemMask      = 1, //!< 面具
    FBItemGift      = 2, //!< 礼物
    FBItemWatermark = 3, //!< 水印
    FBItemAvater    = 4  //!< Avatar
};

/**
 * 美妆类型枚举
 *
 * 美妆类型分为口红、眉毛，腮红、眼影、眼线、睫毛、美瞳
 */
typedef NS_ENUM(NSInteger, FBMakeupTypes) {
    FBMakeupLipstick = 0, //!< 口红
    FBMakeupEyebrow = 1, //!< 眉毛
    FBMakeupBlush  = 2,  //!< 腮红
    FBMakeupEyeshadow  = 3, //!< 眼影
    FBMakeupEyeline  = 4, //!< 眼线
    FBMakeupEyelash  = 5, //!< 睫毛
    FBMakeupPupils  = 6 //!< 美瞳
};

/**
 * 美体类型枚举
 *
 * 美体类型分为长腿、瘦身
 */
typedef NS_ENUM(NSInteger, FBBodyBeautyTypes) {
    FBBodyBeautyLegSlimming = 0, //!< 长腿
    FBBodyBeautyBodyThinning = 1 //!< 瘦身
};

/**
 * 视频帧格式
 *
 * 支持对RGB、RGBA、BGR、BGRA、NV12、NV21、I420格式的视频帧进行渲染
 */
typedef NS_ENUM(NSInteger, FBFormatEnum) {
    FBFormatRGB  = 0, //!< RGB
    FBFormatRGBA = 1, //!< RGBA
    FBFormatBGR  = 2, //!< BGR
    FBFormatBGRA = 3, //!< BGRA
    FBFormatNV12 = 4, //!< NV12
    FBFormatNV21 = 5, //!< NV21
    FBFormatI420 = 6  //!< I420
};

/**
 * 视频帧朝向
 *
 */
typedef NS_ENUM(NSInteger, FBRotationEnum){
    FBRotationClockwise0   = 0,
    FBRotationClockwise90  = 90,
    FBRotationClockwise180 = 180,
    FBRotationClockwise270 = 270
};

/**
 * 手势分类枚举
 */
typedef NS_ENUM(NSInteger, FBGestureEnum) {
    FBGestureCall           = 0,
    FBGestureDislike        = 1,
    FBGestureFist           = 2,
    FBGestureFour           = 3,
    FBGestureLike           = 4,
    FBGestureMute           = 5,
    FBGestureOK             = 6,
    FBGestureOne            = 7,
    FBGesturePalm           = 8,
    FBGesturePeace          = 9,
    FBGestureRock           = 10,
    FBGestureStop           = 11,
    FBGestureStopInverted   = 12,
    FBGestureThree          = 13,
    FBGestureTwoUp          = 14,
    FBGestureTwoUpInverted  = 15,
    FBGestureThree2         = 16,
    FBGesturePeaceInverted  = 17,
    FBGestureNoGesture      = 18
};

/**
 * AI驱动类型枚举
 */
typedef NS_ENUM(NSInteger, NeonAITypes) {
    AINeonFace            = 0, //!< 人脸检测
    AINeonHair            = 1, //!< 头发分割
    AINeonMatting         = 2, //!< 人像分割
    AINeonHand            = 3, //!< 人手检测
    AINeonPose            = 4  //!< 人体检测
};

#pragma mark - 单例

/**
 * 单例
 */
+ (FaceBeauty *)shareInstance;

#pragma mark - 鉴权相关设置

/**
 * 设置鉴权网络节点
 *
 * @param node 节点名称，默认"cn"，国内节点
 *             "sg"，海外节点-新加坡
 */
- (void)setAuthNetworkNode:(NSString *)node;

#pragma mark - 资源文件拷贝

/**
 * 拷贝资源文件到指定沙盒路径
 *
 * @param bundlePath 本地资源文件路径
 * @param sandboxPath 目标沙盒路径
 *
 * @return 拷贝是否成功
 */
- (BOOL)copyResourceBundle:(NSString *)bundlePath toSandbox:(NSString *)sandboxPath;

#pragma mark - 初始化

/**
 * 初始化 - 在线授权
 *
 * @param appId 在线鉴权appId
 * @param delegate 代理
 */
- (void)initFaceBeauty:(NSString *)appId withDelegate:(id<FaceBeautyDelegate>)delegate;

/**
 * 初始化 - 离线授权
 *
 * @param license 离线鉴权license
 * @return 鉴权结果返回值
 */
- (int)initFaceBeauty:(NSString *)license;

#pragma mark - 初始化（剥离AI驱动加载方法），3.4.0版本开始使用

/**
 * 鉴权方法 - 在线
 *
 * @param appId 在线鉴权appId
 * @param delegate 代理
 */
- (void)authOnline:(NSString *)appId withDelegate:(id<FaceBeautyDelegate>)delegate;

/**
 * 鉴权方法 - 离线
 *
 * @param license 离线鉴权license
 * @return 鉴权结果返回值
 */
- (int)authOffline:(NSString *)license;

/**
 * 鉴权初始化结果，用于uniapp端
 *
 * @return 获取鉴权结果
 */
- (int)getAuthResult;

#pragma mark - 渲染处理

/**
 * 渲染总开关
 *
 * @param enable 开启为true， 关闭为false， 默认开启
 */
- (void)setRenderEnable:(BOOL)enable;

/**
 * 初始化纹理渲染器
 *
 * @param width    图像宽度
 * @param height   图像高度
 * @param rotation 图像是否需要旋转，不需旋转为CLOCKWISE_0
 * @param isMirror 图像是否存在镜像
 * @param maxFaces 人脸检测数目上限设置，推荐取值范围为1~5
 *
 * @return 返回初始化结果，成功返回true，失败返回false
 */
- (BOOL)initTextureRenderer:(int)width height:(int)height rotation:(FBRotationEnum)rotation isMirror:(BOOL)isMirror maxFaces:(int)maxFaces;

/**
 * 处理纹理数据输入
 *
 * @param textureId 纹理ID
 *
 * @return 返回处理后的纹理数据
 */
- (GLuint)processTexture:(GLuint)textureId;

/**
 * 销毁纹理渲染资源
 */
- (void)releaseTextureRenderer;

/**
 * 初始化视频帧渲染器
 *
 * @param format 视频帧格式
 * @param width    视频帧宽度
 * @param height   视频帧高度
 * @param rotation 视频帧图像是否需要旋转，不需旋转为CLOCKWISE_0
 * @param isMirror 视频帧图像是否存在镜像
 * @param maxFaces 人脸检测数目上限设置，推荐取值范围为1~5
 *
 * @return 返回初始化结果，成功返回true，失败返回false
 */
- (BOOL)initBufferRenderer:(FBFormatEnum)format width:(int)width height:(int)height rotation:(FBRotationEnum)rotation isMirror:(BOOL)isMirror maxFaces:(int)maxFaces;

/**
 * 处理视频帧数据输入
 *
 * @param pixels 视频帧数据
 */
- (void)processBuffer:(unsigned char *)pixels;

/**
 * 销毁视频帧渲染资源
 */
- (void)releaseBufferRenderer;

/**
 * 初始化图片渲染器
 *
 * @param format 图片格式
 * @param width    图片宽度
 * @param height   图片高度
 * @param rotation 图片是否需要旋转，不需旋转为CLOCKWISE_0
 * @param isMirror 图片是否存在镜像
 * @param maxFaces 人脸检测数目上限设置，推荐取值范围为1~5
 *
 * @return 返回初始化结果，成功返回true，失败返回false
 */
- (BOOL)initImageRenderer:(FBFormatEnum)format width:(int)width height:(int)height rotation:(FBRotationEnum)rotation isMirror:(BOOL)isMirror maxFaces:(int)maxFaces;

/**
 * 处理图片数据输入
 *
 * @param pixels 视频帧数据
 */
- (void)processImage:(unsigned char *)pixels;

/**
 * 销毁图片渲染资源
 */
- (void)releaseImageRenderer;

/**
 * 渲染UIImage图片
 * 该接口仅适用于图片渲染的场景，和processImage接口的区别在于无需初始化渲染器以及参数差异
 *
 * @param image 图片（UIImage格式）
 *
 * @return 渲染后的图片（UIImage格式）
 */
- (UIImage *)processUIImage:(UIImage *)image;

/**
 * 销毁UIImage图片渲染资源
 */
- (void)releaseUIImageRenderer;

#pragma mark - 美肤

/**
 * 设置美肤
 *
 * @param type 美肤类型，参考#FBBeautyTypes
 * @param value 美肤参数，取值范围 0-100
 */
- (void)setBeauty:(int)type value:(int)value;

#pragma mark - 美型
/**
 * 设置美型
 *
 * @param type 美型类型，参考#FBReshapeTypes
 * @param value 美型参数，0-100
 */
- (void)setReshape:(int)type value:(int)value;

#pragma mark - 美发
/**
 * 设置美发特效参数函数
 *
 * @param type 美发类型，参考#FBHairTypes
 * @param value 美发参数，0-100
 */
- (void)setHairStyling:(int)type value:(int)value;

#pragma mark - 滤镜

/**
 * 获取滤镜素材网络路径
 *
 * @return 返回滤镜素材网络路径
 */
- (NSString *)getFilterUrl;

/**
 * 获取滤镜素材沙盒路径
 *
 * @return 返回滤镜素材沙盒路径
 */
- (NSString *)getFilterPath;

/**
 * 设置滤镜
 *
 * @param type 滤镜类型，参考类型定义#FBFilterTypes
 * @param name 滤镜名称，如果传null或者空字符，则取消滤镜效果
 */
- (void)setFilter:(int)type name:(NSString *)name;

/**
 * 设置滤镜（新版本接口）
 *
 * @param type 滤镜类型，参考类型定义#FBFilterTypes
 * @param name 滤镜名称，如果传null或者空字符，则取消滤镜效果
 * @param value 滤镜强度，参数范围0-100
 */
- (void)setFilter:(int)type name:(NSString *)name value:(int)value;

#pragma mark - (风格设置：妆容推荐|一键美颜)

/**
 * 获取风格网络路径
 *
 * @return 返回风格素材网络路径
 */
- (NSString *)getStyleUrl;

/**
 * 获取风格沙盒路径
 *
 * @return 返回风格素材沙盒路径
 */
- (NSString *)getStylePath;

/**
 * 设置风格
 * 该接口为一键设置方法，可将多个特效组合设置，需留意所包含的特效是否具有权限
 *
 * @param name 风格名称
 * @param value 风格参数，参数范围0-100，默认为100
 */
- (void)setStyle:(NSString *)name value:(int)value;

#pragma mark - AR道具

/**
 * 获取AR道具素材网络路径
 *
 * @param  type AR道具类型，参考类型定义#FBARItemTypes
 * @return 返回AR道具素材网络路径
 */
- (NSString *)getARItemUrlBy:(int)type;

/**
 * 获取AR道具素材沙盒路径
 *
 * @param  type AR道具类型，参考类型定义#FBARItemTypes
 * @return 返回AR道具素材沙盒路径
 */
- (NSString *)getARItemPathBy:(int)type;

/**
 * 设置AR道具，v2.0后启用
 *
 * @param type AR道具类型，参考类型定义#FBARItemTypes
 * @param name AR道具名称，如果传null或者空字符，则取消道具效果
 */
- (void)setARItem:(int)type name:(NSString *)name;

/**
 * 设置AR道具-水印参数，v2.0后启用
 * 水印参数为水印图像在手机屏幕中相对视频帧的四个顶点的坐标值，配合外部操作框获取
 *
 * @param x1 左上角横坐标值
 * @param y1 左上角纵坐标值
 * @param x2 左下角横坐标值
 * @param y2 左下角纵坐标值
 * @param x3 右下角横坐标值
 * @param y3 右下角纵坐标值
 * @param x4 右上角横坐标值 
 * @param y4 右上角纵坐标值
 */
- (void)setWatermarkParam:(float)x1 y1:(float)y1 x2:(float)x2 y2:(float)y2 x3:(float)x3 y3:(float)y3 x4:(float)x4 y4:(float)y4;

/**
 * 设置AR道具-水印透明度参数函数
 *
 * @param value 透明度参数，0-100，默认100
 */
- (void)setWatermarkTransparency:(int)value;

#pragma mark - 人像抠图 - AI抠图

/**
 * 获取AI抠图素材网络路径
 *
 * @return 返回AI抠图素材网络路径
 */
- (NSString *)getAISegEffectUrl;

/**
 * 获取AI抠图素材沙盒路径
 *
 * @return 返回AI抠图素材沙盒路径
 */
- (NSString *)getAISegEffectPath;

/**
 * 设置AI抠图
 *
 * @param name AI抠图效果名称，如果传null或者空字符，则取消人像抠图效果
 */
- (void)setAISegEffect:(NSString *)name;

#pragma mark - 人像抠图 - 色（键）值抠图，原绿幕抠图

/**
 * 获取色（键）值抠图素材网络路径
 *
 * @return 返回色（键）值抠图素材网络路径
 */
- (NSString *)getChromaKeyingUrl;

/**
 * 获取色（键）值抠图素材沙盒路径
 *
 * @return 返回色（键）值抠图素材沙盒路径
 */
- (NSString *)getChromaKeyingPath;

/**
 * 设置色（键）值抠图特效场景
 *
 * @param name 场景名称
 */
- (void)setChromaKeyingScene:(NSString *)name;

/**
 * 设置色（键）值抠图特效幕布颜色
 *
 * @param color 幕布颜色，传字符串类型16进制色值
 *        目前仅支持绿幕 (#00ff00) 蓝幕(#0000ff)  白幕(#ffffff)三种幕布颜色和透明幕布，默认为绿幕
 */
- (void)setChromaKeyingCurtain:(NSString *)color;

/**
 * 设置色（键）值抠图特效调节参数
 *
 * @param type 参数类型，0-相似度；1-平滑度；2-祛色度；3-精确度
 * @param value 调节参数，参数范围0-100
 */
- (void)setChromaKeyingParams:(int)type value:(int)value;

#pragma mark - 手势识别

/**
 * 获取手势识别素材网络路径
 *
 * @return 返回手势识别素材网络路径
 */
- (NSString *)getGestureEffectUrl;

/**
 * 获取手势识别素材沙盒路径
 *
 * @return 返回手势识别素材沙盒路径
 */
- (NSString *)getGestureEffectPath;

/**
 * 设置手势识别特效
 *
 * @param name 手势识别效果名称，如果传null或者空字符，则取消手势识别效果
 */
- (void)setGestureEffect:(NSString *)name;

#pragma mark - 美妆
/**
 * 获取美妆素材总目录网络路径
 *
 * @return 返回美妆素材总目录网络路径
 */
- (NSString *)getMakeupUrl;

/**
 * 获取美妆素材总目录沙盒路径
 *
 * @return 返回美妆素材总目录沙盒路径
 */
- (NSString *)getMakeupPath;

/**
 * 获取美妆某一类型素材网络路径
 *
 * @return 返回美妆某一类型素材网络路径
 */
- (NSString *)getMakeupUrl:(int)type;

/**
 * 获取美妆某一类型素材沙盒路径
 *
 * @return 返回美妆某一类型素材沙盒路径
 */
- (NSString *)getMakeupPath:(int)type;

/**
 * 设置美妆特效
 *
 * @param type 美妆类型，参考#FBMakeupTypes
 * @param key 美妆属性，参考接口模型文档
 * @param value 美妆属性对应值，参考接口模型文档
 *
 */
- (void)setMakeup:(int)type property:(NSString *)key value:(NSString *)value;

#pragma mark - 美体

/**
 * 设置美体特效
 *
 * @param type 美体类别
 * @param value 美体名称
 */
- (void)setBodyBeauty:(int)type value:(int)value;

#pragma mark - 算法

/**
 * 加载AI驱动
 *
 * @param type AI驱动类型，参考类型定义#FBAITypes
 *
 * @return 当前AI驱动类型是否加载成功
 */
- (bool)loadAIProcessor:(int)type;

/**
 * 卸载AI驱动
 *
 * @param type AI驱动类型，参考类型定义#FBAITypes
 *
 */
- (void)removeAIProcessor:(int)type;

/**
 * 判断是否检测到人脸
 *
 * @return 检测到的人脸个数，返回 0 代表没有检测到人脸
 */
- (int)isTracking;

/**
 * 获取人脸检测结果报告
 */
- (NSArray<FBFaceDetectionReport *> *)getFaceDetectionReport;

/**
 * 判断是否检测到全身人体
 *
 * @return 检测到的全身人体个数，返回 0 代表没有检测到全身人体
 */
- (int)isFullBody;

/**
 * 获取人体检测结果报告
 */
- (NSArray<FBPoseDetectionReport *> *)getPoseDetectionReport;

#pragma mark - 其它
/**
 * 获取功能的参数值
 *
 * @param method 功能模块，参考API文档
 * @param key 该功能模块的属性，参考API文档
 *
 * @return 功能模块的参数值，统一返回NSString类型，需根据具体参数类型转换，如NSString->int, NSString->float...
 */
- (NSString *)getParamFrom:(NSString *)method property:(NSString *)key;

/**
 * 部分透明图渲染支持开关
 *
 * @param enable 开启为true， 关闭为false， 默认关闭
 */
- (void)setTransparencyRenderEnable:(BOOL)enable;

/**
 * 设置人脸检测器类型，默认为0
 *
 * @param type 人脸检测器类型
 */
- (void)setFaceDetectorType:(int)type;

/**
 * 设置人脸检测算法CPU多核运算开关，默认为false
 *
 * @param enable 开关，默认为false
 */
- (void)setFaceDetectionCPUPowersaveEnable:(BOOL)enable;

/**
 * 设置人脸检测距离级别，默认为1级，即能识别较近距离
 * 此接口生效的前置条件是人脸检测算法Base模式为开启状态
 *
 * @param level 人脸检测距离级别，默认为1级
 */
- (void)setFaceDetectionDistanceLevel:(int)level;

/**
 * 获取当前 SDK 版本号
 *
 * @return 版本号
 */
- (NSString *)getVersionCode;

/**
 * 获取当前 SDK 版本信息
 *
 * @return 版本信息
 */
- (NSString *)getVersion;

/**
 * 设置参数极值限制开关，默认为开
 */
- (void)setExtremeLimitEnable:(BOOL)enable;

/**
 * 设置性能优先模式开关，默认为开
 */
- (void)setPerformancePriorityEnable:(BOOL)enable;

/**
 * 设置素材网络路径
 * 将素材保存在自定义的网络存储中的情况下，设置网络路径
 *
 * @param url 素材网络路径
 */
- (void)setResourceUrl:(NSString *)url;

/**
 * 获取素材网络路径
 *
 * @return 素材网络路径
 */
- (NSString *)getResourceUrl;

@end
