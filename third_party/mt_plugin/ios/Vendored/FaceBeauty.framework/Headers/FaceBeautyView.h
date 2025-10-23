//
//  FaceBeautyView.h
//  HTEffect
//

#import <GLKit/GLKit.h>
#import <AVFoundation/AVCaptureSession.h>

typedef NS_ENUM(NSInteger, FaceBeautyViewOrientation) {
    FaceBeautyViewOrientationPortrait              = 0,
    FaceBeautyViewOrientationLandscapeRight        = 1,
    FaceBeautyViewOrientationPortraitUpsideDown    = 2,
    FaceBeautyViewOrientationLandscapeLeft         = 3,
};

typedef NS_ENUM(NSInteger, FaceBeautyViewContentMode) {
    // 等比例短边充满
    FaceBeautyViewContentModeScaleAspectFill       = 0,
    // 拉伸铺满
    FaceBeautyViewContentModeScaleToFill           = 1,
    // 等比例长边充满
    FaceBeautyViewContentModeScaleAspectFit        = 2,

};

@interface FaceBeautyView : UIView

// 视频填充模式
@property (nonatomic, assign) FaceBeautyViewContentMode contentMode;

// 设置视频朝向，保证视频总是竖屏播放
@property (nonatomic, assign) FaceBeautyViewOrientation orientation;

// 预览渲染后的视频
- (void)displayPixelBuffer:(CVPixelBufferRef)pixelBuffer isMirror:(BOOL)isMirror;

@end
