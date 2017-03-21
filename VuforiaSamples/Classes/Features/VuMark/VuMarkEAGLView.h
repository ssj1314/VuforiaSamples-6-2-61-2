/*===============================================================================
Copyright (c) 2016 PTC Inc. All Rights Reserved.

Copyright (c) 2012-2015 Qualcomm Connected Experiences, Inc. All Rights Reserved.

Vuforia is a trademark of PTC Inc., registered in the United States and other 
countries.
===============================================================================*/

#import <UIKit/UIKit.h>

#import <Vuforia/UIGLViewProtocol.h>

#import "Texture.h"
#import "SampleApplicationSession.h"
#import "SampleApplication3DModel.h"
#import "SampleGLResourceHandler.h"
#import "SampleAppRenderer.h"


#define kNumAugmentationTextures 1   //Num增强纹理


// EAGLView is a subclass of UIView and conforms to the informal protocol
// UIGLViewProtocol
//eaglview是UIView子类和符合非正式协议  uiglviewprotocol
@interface VuMarkEAGLView : UIView <UIGLViewProtocol, SampleGLResourceHandler, SampleAppRendererControl> {
@private
    // OpenGL ES context   上下文
    EAGLContext *context;//上下文
    
    // The OpenGL ES names for the framebuffer and renderbuffers used to render
    // to this view OpenGL ES的名字为帧和渲染缓存用来渲染这个视图
    GLuint defaultFramebuffer;//默认的帧缓存
    GLuint colorRenderbuffer;//色彩渲染缓冲区
    GLuint depthRenderbuffer;//深度缓冲区

    // Shader handles 着色处理
    GLuint shaderProgramID;//着色器程序ID
    GLint vertexHandle;//顶点处理
    GLint normalHandle;//正常的处理
    GLint textureCoordHandle;//纹理坐标处理
    GLint mvpMatrixHandle;//图矩阵处理
    GLint texSampler2DHandle;//二维特展开行动
    GLint calphaHandle;
    
    // Texture used when rendering augmentation 纹理渲染时使用的纹理
    Texture* augmentationTexture[kNumAugmentationTextures];//增强的纹理
    
    BOOL offTargetTrackingEnabled;//启用目标跟踪
    SampleApplication3DModel * buildingModel;//App的3D模型  buildingModel建立模型
    
    UILabel * cardIdLabel;//cardID标签
    UILabel * cardTypeLabel;
    UIImageView * vuMarkImage;//card类型标签image类型
    NSString * currentVumarkIdOnCard;//在当前vumark ID卡
    
    CGFloat padding;//填充
    CGFloat textBoxWidth;//文本框的宽度
    CGFloat textBoxHeight;//文本框的高度
    CGFloat textLabelHeight;//文本标签的高度
    
    UIView * cardView;//vard视图
    CGRect cardFrameVisible;//card框架可见
    CGRect cardFrameHidden;//card框架隐藏
    bool cardViewVisible;//card在视图中可见
    
    SampleAppRenderer * sampleAppRenderer;//App渲染器

}

@property (nonatomic, weak) SampleApplicationSession * vapp;//示例应用程序的会话

- (id)initWithFrame:(CGRect)frame appSession:(SampleApplicationSession *) app;//初始化框架

- (void)finishOpenGLESCommands;//完成OpenGLES的命令
- (void)freeOpenGLESResources;//免费的OpenGLES资源

- (void) setOffTargetTrackingMode:(BOOL) enabled;//设定目标跟踪模式
- (void)configureVideoBackgroundWithViewWidth:(float)viewWidth andHeight:(float)viewHeight;//配置视频背景与视图宽度
- (void) updateRenderingPrimitives;//更新的渲染原语   更新绘制图元
@end
