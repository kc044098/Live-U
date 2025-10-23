#import "MtPlugin.h"
#import <Foundation/Foundation.h>
#import <FaceBeauty/FaceBeauty.h>

#if __has_include(<mt_plugin/mt_plugin-Swift.h>)
#import <mt_plugin/mt_plugin-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "mt_plugin-Swift.h"
#endif

@implementation MtPlugin

// 实现协议中的注册方法，这个方法主要是用来定义与上层代码通信的通道
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* methodChannel = [FlutterMethodChannel methodChannelWithName:@"mt_plugin" binaryMessenger:[registrar messenger]];
    MtPlugin* instance = [[MtPlugin alloc] init];
    [registrar addMethodCallDelegate:instance channel:methodChannel];
    
}

// 实现协议中的注册方法，用来响应上层调用
- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result{

    int value = 0;
    if (call.arguments[@"value"]) {
        value = [call.arguments[@"value"] intValue];
    }
    
    
    // MARK: 渲染总开关
    if ([call.method isEqualToString:@"SET_RENDER_ENABLE"]) {
        NSLog(@"call.method: 渲染总开关 %@",call.arguments[@"enable"]);
        [[FaceBeauty shareInstance] setRenderEnable:[call.arguments[@"enable"] boolValue]];
    }
    
    // MARK: 美颜调节
    if ([call.method isEqualToString:@"SET_FACE_BEAUTY_ENABLE"]) {
        NSLog(@"call.method: 美颜开关 %@",call.arguments[@"enable"]);
        [[FaceBeauty shareInstance] setRenderEnable:[call.arguments[@"enable"] boolValue]];
    }
    if ([call.method isEqualToString:@"SET_WHITENESS_VALUE"]) {
        NSLog(@"call.method: 美白 %d",value);
        [[FaceBeauty shareInstance] setBeauty:FBBeautySkinWhitening value:value];
    }
    if ([call.method isEqualToString:@"SET_BLURRINESS_VALUE"]) {
        NSLog(@"call.method: 磨皮 %d",value);
        [[FaceBeauty shareInstance] setBeauty:FBBeautyClearSmoothing value:value];
    }
    if ([call.method isEqualToString:@"SET_ROSINESS_VALUE"]) {
        NSLog(@"call.method: 红润 %d",value);
        [[FaceBeauty shareInstance] setBeauty:FBBeautySkinRosiness value:value];
    }
    if ([call.method isEqualToString:@"SET_CLEAR_NESS_VALUE"]) {
        NSLog(@"call.method: 鲜明 %d",value);
        [[FaceBeauty shareInstance] setBeauty:FBBeautyImageSharpness value:value];
    }
    if ([call.method isEqualToString:@"SET_BRIGHTNESS_VALUE"]) {
        NSLog(@"call.method: 亮度 %d",value);
        [[FaceBeauty shareInstance] setBeauty:FBBeautyImageBrightness value:value];
    }
    if ([call.method isEqualToString:@"SET_UNDEREYE_CIRCLES_VALUE"]) {
        NSLog(@"call.method: 去黑眼圈 %d",value);
        [[FaceBeauty shareInstance] setBeauty:FBBeautyDarkCircleLessening value:value];
    }
    if ([call.method isEqualToString:@"SET_NASOLABIAL_FOLD_VALUE"]) {
        NSLog(@"call.method: 去法令纹 %d",value);
        [[FaceBeauty shareInstance] setBeauty:FBBeautyNasolabialLessening value:value];
    }
    // MARK: 美型调节
    if ([call.method isEqualToString:@"SET_FACE_SHAPE_ENABLE"]) {
        NSLog(@"call.method: 美型开关 %@",call.arguments[@"value"]);
        [[FaceBeauty shareInstance] setRenderEnable:[call.arguments[@"value"] boolValue]];
    }
    if ([call.method isEqualToString:@"SET_EYE_ENLARGING_VALUE"]) {
        NSLog(@"call.method: 大眼 %d",value);
        [[FaceBeauty shareInstance] setReshape:FBReshapeEyeEnlarging value:value];
    }
    if ([call.method isEqualToString:@"SET_EYE_ROUNDING_VALUE"]) {
        NSLog(@"call.method: 圆眼 %d",value);
        [[FaceBeauty shareInstance] setReshape:FBReshapeEyeRounding value:value];
    }
    if ([call.method isEqualToString:@"SET_CHEEK_THINNING_VALUE"]) {
        NSLog(@"call.method: 瘦脸 %d",value);
        [[FaceBeauty shareInstance] setReshape:FBReshapeCheekThinning value:value];
    }
    if ([call.method isEqualToString:@"SET_CHEEK_V_VALUE"]) {
        NSLog(@"call.method: V脸 %d",value);
        [[FaceBeauty shareInstance] setReshape:FBReshapeCheekVShaping value:value];
    }
    if ([call.method isEqualToString:@"SET_CHEEK_NARROWING_VALUE"]) {
        NSLog(@"call.method: 窄脸 %d",value);
        [[FaceBeauty shareInstance] setReshape:FBReshapeCheekNarrowing value:value];
    }
    if ([call.method isEqualToString:@"SET_CHEEK_BONE_THINNING"]) {
        NSLog(@"call.method: 瘦颧骨 %d",value);
        [[FaceBeauty shareInstance] setReshape:FBReshapeEyeEnlarging value:value];
    }
    if ([call.method isEqualToString:@"SET_JAW_BONE_THINNING_VALUE"]) {
        NSLog(@"call.method: 瘦下颌骨 %d",value);
        [[FaceBeauty shareInstance] setReshape:FBReshapeCheekboneThinning value:value];
    }
    if ([call.method isEqualToString:@"SET_TEMPLE_ENLARG_ING_VALUE"]) {
        NSLog(@"call.method: 丰太阳穴 %d",value);
        [[FaceBeauty shareInstance] setReshape:FBReshapeTempleEnlarging value:value];
    }
    if ([call.method isEqualToString:@"SET_HEAD_LESSENING_VALUE"]) {
        NSLog(@"call.method: 小头 %d",value);
        [[FaceBeauty shareInstance] setReshape:FBReshapeHeadLessening value:value];
    }
    if ([call.method isEqualToString:@"SET_FACE_LESSENING_VALUE"]) {
        NSLog(@"call.method: 小脸 %d",value);
        [[FaceBeauty shareInstance] setReshape:FBReshapeFaceLessening value:value];
    }
    if ([call.method isEqualToString:@"SET_FACE_SHORTENING_VALUE"]) {
        NSLog(@"call.method: 短脸 %d",value);
        [[FaceBeauty shareInstance] setReshape:FBReshapeCheekShortening value:value];
    }
    if ([call.method isEqualToString:@"SET_CHIN_TRIMMING_VALUE"]) {
        NSLog(@"call.method: 下巴 %d",value);
        [[FaceBeauty shareInstance] setReshape:FBReshapeChinTrimming value:value];
    }
    if ([call.method isEqualToString:@"SET_PHILTRUMTRIMMINGVALUE"]) {
        NSLog(@"call.method: 缩人中 %d",value);
        [[FaceBeauty shareInstance] setReshape:FBReshapePhiltrumTrimming value:value];
    }
    if ([call.method isEqualToString:@"SET_FOREHEAD_TRIMMING_VALUE"]) {
        NSLog(@"call.method: 发际线 %d",value);
        [[FaceBeauty shareInstance] setReshape:FBReshapeForeheadTrimming value:value];
    }
    
    if ([call.method isEqualToString:@"SET_EYE_SPACING_TRIMMING_VALUE"]) {
        NSLog(@"call.method: 眼间距 %d",value);
        [[FaceBeauty shareInstance] setReshape:FBReshapeEyeSpaceTrimming value:value];
    }
    if ([call.method isEqualToString:@"SET_EYE_CORNER_TRIMMING_VALUE"]) {
        NSLog(@"call.method: 眼角倾斜 %d",value);
        [[FaceBeauty shareInstance] setReshape:FBReshapeEyeCornerTrimming value:value];
    }

    if ([call.method isEqualToString:@"SET_NOSE_ENLARGING_VALUE"]) {
        NSLog(@"call.method: 长鼻 %d",value);
        [[FaceBeauty shareInstance] setReshape:FBReshapeNoseEnlarging value:value];
    }
    if ([call.method isEqualToString:@"SET_NOSE_THINNING_VALUE"]) {
        NSLog(@"call.method: 瘦鼻 %d",value);
        [[FaceBeauty shareInstance] setReshape:FBReshapeNoseThinning value:value];
    }
    if ([call.method isEqualToString:@"SET_NOSE_APEX_LESSENING_VALUE"]) {
        NSLog(@"call.method: 鼻头 %d",value);
        [[FaceBeauty shareInstance] setReshape:FBReshapeNoseApexLessening value:value];
    }
    if ([call.method isEqualToString:@"SET_NOSE_ROOT_RNLARING"]) {
        NSLog(@"call.method: 山根 %d",value);
        [[FaceBeauty shareInstance] setReshape:FBReshapeNoseRootEnlarging value:value];
    }
    
    if ([call.method isEqualToString:@"SET_MOUTH_TRIMMING_VALUE"]) {
        NSLog(@"call.method: 嘴型 %d",value);
        [[FaceBeauty shareInstance] setReshape:FBReshapeMouthTrimming value:value];
    }
    if ([call.method isEqualToString:@"SET_MOUTH_SMILING_ENLARGING_VALUE"]) {
        NSLog(@"call.method: 微笑嘴角 %d",value);
        [[FaceBeauty shareInstance] setReshape:FBReshapeMouthSmiling value:value];
    }
    
    int progress = 0;
    if (call.arguments[@"progress"]) {
        progress = [call.arguments[@"progress"] intValue];
    }
    
    // MARK: 一键美颜调节
    if ([call.method isEqualToString:@"SET_BEAUTY_STYLE"]) {
        //通过字符串得到对应的一键美颜枚举
        id typeValue = call.arguments[@"type"];
        // 确保取出的值是 NSNumber 类型，并转换为 int
        if ([typeValue isKindOfClass:[NSNumber class]]) {
            int type = [typeValue intValue];
//            [[FaceBeauty shareInstance] setStyle:type];
        } else {
            // 处理非法输入
            NSLog(@"Invalid argument type for key 'type'");
        }
    }

    // MARK: 美颜滤镜调节
    if ([call.method isEqualToString:@"SET_BEAUTY_FILTER_NAME"]) {
        NSString *name = call.arguments[@"name"];
        NSLog(@"call.method: 美颜滤镜 %@ %d",name,value);
        [[FaceBeauty shareInstance] setFilter:FBFilterBeauty name:name];
    }

    // MARK: 特效滤镜调节
    if ([call.method isEqualToString:@"SET_EFFECT_FILTER_TYPE"]) {
        //通过字符串得到对应的特效滤镜枚举
        NSString *name = call.arguments[@"name"];
        [[FaceBeauty shareInstance] setFilter:FBFilterEffect name:name];
    }

    // MARK: 趣味滤镜调节
    if ([call.method isEqualToString:@"SET_FUNNY_FILTER_TYPE"]) {
        //通过字符串得到对应的趣味滤镜枚举
        NSString *name = call.arguments[@"name"];
        [[FaceBeauty shareInstance] setFilter:FBFilterFunny name:name];
    }

    
    // MARK: 贴纸效果调节
    if ([call.method isEqual:@"SET_DYNAMIC_STICKER_NAME"]) {
        NSString *name = call.arguments[@"name"];
        NSLog(@"call.method: 动态贴纸 %@",name);
        [[FaceBeauty shareInstance] setARItem:FBItemSticker name:name];
    }
    // MARK: 表情效果调节
    if ([call.method isEqual:@"SET_EXPRESSION_RECREATION_NAME"]) {
        NSString *name = call.arguments[@"name"];
        NSLog(@"call.method: 表情 %@",name);
    }
    // MARK: 面具效果调节
    if ([call.method isEqualToString:@"SET_MASK_NAME"]) {
        NSString *name = call.arguments[@"name"];
        NSLog(@"call.method: 面具 %@",name);
        [[FaceBeauty shareInstance] setARItem:FBItemMask name:name];
    }
    //MARK: 礼物效果调节
    if ([call.method isEqualToString:@"SET_GIFT_NAME"]) {
        NSString *name = call.arguments[@"name"];
        NSLog(@"call.method: 礼物 %@",name);
        [[FaceBeauty shareInstance] setARItem:FBItemGift name:name];
    }
    // MARK: 水印效果调节
//    if ([call.method isEqualToString:@"SET_WATERMARK_NAME"]) {
//        NSString *name = call.arguments[@"name"];
//        NSLog(@"call.method: 水印 %@",name);
//        [[FaceBeauty shareInstance] setARItem:FBItemWatermark name:name];
//    }
    // MARK: 水印效果调节
    if ([call.method isEqualToString:@"SET_WATER_NAME"]) {
        NSString *name = call.arguments[@"name"];
        int x = [call.arguments[@"x"] intValue];
        int y = [call.arguments[@"y"] intValue];
        int ratio = [call.arguments[@"ratio"] intValue];
        NSLog(@"call.method: 水印 %@ %d %d %d",name,x,y,ratio);
        [[FaceBeauty shareInstance] setARItem:FBItemWatermark name:name];
    }
    // MARK: 人像抠图效果调节
    if ([call.method isEqualToString:@"SET_PORTRAIT_NAME"]) {
        NSString *name = call.arguments[@"name"];
        NSLog(@"call.method: 人像抠图 %@",name);
        [[FaceBeauty shareInstance] setAISegEffect:name];
    }
    // MARK: 绿幕效果调节
    if ([call.method isEqualToString:@"SET_GREEN_SCREEN"]) {
        NSString *name = call.arguments[@"name"];
        NSLog(@"call.method: 绿幕 %@",name);
        [[FaceBeauty shareInstance] setChromaKeyingScene:name];
    }
}


/**
 * 字符串获取一键美颜枚举
 */
//- (HTStyleTypes)stringToBeautyEnum:(NSInteger *)stringName
//{
//
//    if ([stringName isEqualToString:@"LOLITA"]) {
//        return 0;
//    }
//    if ([stringName isEqualToString:@"GODDESS"]) {
//        return 1;
//    }
//    if ([stringName isEqualToString:@"CELEBRITY"]) {
//        return 2;
//    }
//    if ([stringName isEqualToString:@"NATURAL"]) {
//        return 3;
//    }
//    if ([stringName isEqualToString:@"MILK"]) {
//        return 4;
//    }
//    if ([stringName isEqualToString:@"CARMEL"]) {
//        return 5;
//    }
//    if ([stringName isEqualToString:@"PAINTING"]) {
//        return 6;
//    }
//    if ([stringName isEqualToString:@"NECTARINE"]) {
//        return 7;
//    }
//    if ([stringName isEqualToString:@"HOLIDAY"]) {
//        return 8;
//    }
//    return 0;
//
//}


@end
