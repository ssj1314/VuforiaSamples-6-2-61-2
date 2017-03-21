/*===============================================================================
Copyright (c) 2016 PTC Inc. All Rights Reserved.

Copyright (c) 2012-2015 Qualcomm Connected Experiences, Inc. All Rights Reserved.

Vuforia is a trademark of PTC Inc., registered in the United States and other 
countries.
===============================================================================*/

#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <sys/time.h>

#import <Vuforia/Vuforia.h>
#import <Vuforia/State.h>
#import <Vuforia/Tool.h>
#import <Vuforia/Renderer.h>
#import <Vuforia/TrackableResult.h>
#import <Vuforia/VideoBackgroundConfig.h>

#import <Vuforia/VuMarkTemplate.h>
#import <Vuforia/VuMarkTarget.h>
#import <Vuforia/VuMarkTargetResult.h>

#import "VuMarkEAGLView.h"
#import "Texture.h"
#import "SampleApplicationUtils.h"
#import "SampleApplicationShaderUtils.h"
#import "Teapot.h"
#import "VuMarkUserData.h"

//******************************************************************************
// *** OpenGL ES thread safety  OpenGL ES的线程安全性***
//
// OpenGL ES on iOS is not thread safe.  We ensure thread safety by following
// this procedure:
//OpenGL ES在iOS不是线程安全的。我们确保线程安全遵循这个程序：
// 1) Create the OpenGL ES context on the main thread.
//1创建OpenGL ES上下文在主线程

// 2) Start the Vuforia camera, which causes Vuforia to locate our EAGLView and start
//    the render thread.
//2开始vuforia相机，使vuforia定位我们的eaglview开始渲染线程。

// 3) Vuforia calls our renderFrameVuforia method periodically on the render thread.
//    The first time this happens, the defaultFramebuffer does not exist, so it
//    is created with a call to createFramebuffer.  createFramebuffer is called
//    on the main thread in order to safely allocate the OpenGL ES storage,
//    which is shared with the drawable layer.  The render (background) thread
//    is blocked during the call to createFramebuffer, thus ensuring no
//    concurrent use of the OpenGL ES context.
//3vuforia称我们的renderframevuforia法定期在渲染线程。第一次出现这种情况，该defaultframebuffer并不存在，所以它是一个叫createFramebuffer的创造。createFramebuffer呼吁为主线的安全配置OpenGL ES的存储，这与冲层共享。渲染（背景）的线程调用createFramebuffer在受阻，从而确保没有同时使用OpenGL ES上下文。
//******************************************************************************


namespace {
    // --- Data private to this unit 这私人数据单元 ---

    // Teapot texture filenames 茶壶纹理文件名
    const char* textureFilenames[] = {//纹理文件名
        "vumark_texture.png"
    };
    
    // --- Data private to this unit 这私人数据单元 ---
    double t0 = -1.0f;
    
    float vumarkBorderSize;//VuMark的边界尺寸
    
    const int NUM_OBJECT_INDEX=6; //2 triangles Num的对象索引//三角形
    
    static const float frameVertices[4 * 3] =//frame的顶点
    {
        -0.5f,-0.5f,0.f,
        0.5f,-0.5f,0.f,
        0.5f,0.5f,0.f,
        -0.5f,0.5f,0.f,
    };
    
    static const unsigned short frameIndices[NUM_OBJECT_INDEX] =//frame的索引NUM_OBJECT_INDEX为6
    {
        0,1,2, 2,3,0
    };
    
    static const int CIRCLE_NB_VERTICES = 18; //圈状物体NB的最高顶点
    static float circleVertices[CIRCLE_NB_VERTICES * 3] = {};//界的顶点
    
    
    static UIColor * COLOR_LABEL = [UIColor colorWithRed:170.0f/255.0f green:170.0f/255.0f blue:170.0f/255.0f alpha:1.0f];//颜色标签
    static UIColor * COLOR_ID = [UIColor colorWithRed:74.0f/255.0f green:74.0f/255.0f blue:74.0f/255.0f alpha:1.0f];//颜色ID
    static UIColor * GREEN_COLOR = [UIColor colorWithRed:0.0f/255.0f green:255.0f/255.0f blue:255.0f/255.0f alpha:0.8f];//绿色颜色
    
    static VuMarkUserData * userData;//用户数据
    
}


@interface VuMarkEAGLView (PrivateMethods)//私有方法

- (void)initShaders;//初始化着色器
- (void)createFramebuffer;//创建帧缓存
- (void)deleteFramebuffer;//删除帧缓冲
- (void)setFramebuffer;//设置帧缓冲
- (BOOL)presentFramebuffer;//当前帧缓冲
- (void)createReticleOverlayView;//创建掩膜覆盖视图
- (void)createCardOverlayView;//创建Card卡片覆盖视图
//将实例ID转换为十六进制字符串
- (NSString *) convertInstanceIdToHexString:(const Vuforia::InstanceId&) vuMarkId;

@end


@implementation VuMarkEAGLView

@synthesize vapp = vapp;

// You must implement this method, which ensures the view's underlying layer is
// of type CAEAGLLayer 你必须实现这个方法，使视图的基础层是caeagllayer型
+ (Class)layerClass//层类
{
    return [CAEAGLLayer class];
}

#define DEGREES_TO_RADIANS(x) (M_PI * x / 180.0)//角度

- (void) prepareCircleVertices {//准备届顶点
    float angleDelta = 360.0 / CIRCLE_NB_VERTICES;//角的三角 CIRCLE_NB_VERTICES = 18; //圈状物体NB的最高顶点
    
    for (int index = 0; index < CIRCLE_NB_VERTICES; index ++) {
        int i = index * 3;
        circleVertices[i]   = (cos(DEGREES_TO_RADIANS(index * angleDelta)) * 0.5);//界的顶点
        circleVertices[i+1] = (sin(DEGREES_TO_RADIANS(index * angleDelta)) * 0.5);
        circleVertices[i+2] = 0.0f;
        //static float circleVertices[CIRCLE_NB_VERTICES * 3] = {};//界的顶点   添加值
    }
}
//------------------------------------------------------------------------------
#pragma mark - Lifecycle 生命周期
//初始化应用程序回话
- (id)initWithFrame:(CGRect)frame appSession:(SampleApplicationSession *) app
{
    self = [super initWithFrame:frame];
    
    if (self) {
        vapp = app;
        // Enable retina mode if available on this device 启用视网膜模式，如果此设备上可用
        if (YES == [vapp isRetinaDisplay]) {//视网膜显示
            [self setContentScaleFactor:[UIScreen mainScreen].nativeScale];
        }
        
        // Load the augmentation textures 加载增强纹理
        for (int i = 0; i < kNumAugmentationTextures; ++i) {//#define kNumAugmentationTextures 1   //Num增强纹理

            augmentationTexture[i] = [[Texture alloc] initWithImageFile:[NSString stringWithCString:textureFilenames[i] encoding:NSASCIIStringEncoding]];//增强的纹理
        }

        // Create the OpenGL ES context 创建OpenGLES语境
        context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        
        // The EAGLContext must be set for each thread that wishes to use it.
        // Set it the first time this method is called (on the main thread)
        //创建代表上下文的第一次调用这个方法（在主线程）

        if (context != [EAGLContext currentContext]) {
            [EAGLContext setCurrentContext:context];//设置当前上下文
        }
        
        sampleAppRenderer = [[SampleAppRenderer alloc] initWithSampleAppRendererControl:self deviceMode:Vuforia::Device::MODE_AR stereo:false nearPlane:.01 farPlane:100.0];//App渲染器
        
        // Generate the OpenGL ES texture and upload the texture data for use
        // when rendering the augmentation生成OpenGL ES纹理和上传数据时使用的渲染纹理增强
        for (int i = 0; i < kNumAugmentationTextures; ++i) {//#define kNumAugmentationTextures 1   //Num增强纹理
            GLuint textureID;//纹理的ID
            glGenTextures(1, &textureID);//格伦纹理的材质ID 纹理ID
            [augmentationTexture[i] setTextureID:textureID];//增强的纹理 Texture* augmentationTexture[kNumAugmentationTextures];//增强的纹理    设置纹理ID
            glBindTexture(GL_TEXTURE_2D, textureID);//绑定的纹理
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, [augmentationTexture[i] width], [augmentationTexture[i] height], 0, GL_RGBA, GL_UNSIGNED_BYTE, (GLvoid*)[augmentationTexture[i] pngData]);//
        }

        offTargetTrackingEnabled = NO;// BOOL offTargetTrackingEnabled;//启用目标跟踪
        
        [self initShaders];//初始化着色器
        
        [self createReticleOverlayView];//创建掩膜覆盖视图
        [self createCardOverlayView];////创建卡覆盖视图
        [self prepareCircleVertices];//准备届顶点
        cardViewVisible = false;//card在视图中可见
        currentVumarkIdOnCard = nil;//NSString * currentVumarkIdOnCard;//在当前vumark ID卡
        
        [sampleAppRenderer initRendering];//初始化渲染
    }
    
    return self;
}

//释放内存
- (void)dealloc
{
    [self deleteFramebuffer];
    
    // Tear down context 拆掉上下文
    if ([EAGLContext currentContext] == context) {
        [EAGLContext setCurrentContext:nil];
    }

    for (int i = 0; i < kNumAugmentationTextures; ++i) {
        augmentationTexture[i] = nil;
    }

    userData = nil;
}


- (void)finishOpenGLESCommands//完成OpenGLES的命令
{
    // Called in response to applicationWillResignActive.  The render loop has
    // been stopped, so we now make sure all OpenGL ES commands complete before
    // we (potentially) go into the background
    //电话响应applicationwillresignactive。渲染循环已经停止，所以我们现在要确保所有的OpenGL ES的命令完成之前，我们（潜在）进入后台
    if (context) {
        [EAGLContext setCurrentContext:context];//设置当前上下文
        glFinish();//结束
    }
}


- (void)freeOpenGLESResources //免费的OpenGLES资源
{
    // Called in response to applicationDidEnterBackground.  Free easily
    // recreated OpenGL ES resources
    //电话响应applicationDidEnterBackground有。自由轻松地创建OpenGL ES的资源
    [self deleteFramebuffer];//删除帧缓冲区
    glFinish();//结束
}

- (void) setOffTargetTrackingMode:(BOOL) enabled {//设置目标跟踪模式
    offTargetTrackingEnabled = enabled;//是否启用目标跟踪
}

- (double) getCurrentTime {//获取当前时间
    static struct timeval tv;
    gettimeofday(&tv, NULL);
    double t = tv.tv_sec + tv.tv_usec/1000000.0;
    return t;
}
//不知道这个是在干啥
- (float) blinkVumark:(bool) reset {//闪烁vumark
    if (reset || t0 < 0.0f) {
        t0 = [self getCurrentTime];
    }
    if (reset) {
        return 0.0f;
    }
    double time = [self getCurrentTime];
    double delta = (time-t0);
    
    if (delta > 1.0) {
        return 1.0;
    }
    
    if ((delta < 0.3) || ((delta > 0.5) && (delta < 0.8))) {
        return 1.0;
    }
    
    return 0.0;
}


- (void) updateRenderingPrimitives//更新绘制图元
{
    [sampleAppRenderer updateRenderingPrimitives];//示例应用程序的渲染
}


//------------------------------------------------------------------------------
#pragma mark - UIGLViewProtocol methods UIGLView协议的方法

// Draw the current frame using OpenGL
//
// This method is called by Vuforia when it wishes to render the current frame to
// the screen.
//绘制当前帧使用OpenGL调用此方法时，它希望通过vuforia渲染到屏幕的当前帧。


// *** Vuforia will call this method periodically on a background thread  vuforia将调用此方法，定期在后台线程***
- (void)renderFrameVuforia//渲染帧Vuforia
{
    if (! vapp.cameraIsStarted) {//App的摄像头开始
        return;
    }
    
    [sampleAppRenderer renderFrameVuforia];//vuforia渲染
}

//渲染帧状态    projectMatrix项目矩阵
- (void)renderFrameWithState:(const Vuforia::State &)state projectMatrix:(Vuforia::Matrix44F &)projectionMatrix
{
    [self setFramebuffer];//设置帧缓冲
    
    // Clear colour and depth buffers 清除颜色和深度缓冲
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);//系统的
    
    // Render video background and retrieve tracking state
    //渲染视频背景并检索跟踪状态
    
    [sampleAppRenderer renderVideoBackground];//渲染视频背景
    
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);//混合功能
    
    // We disable depth testing for rendering translucent augmentations;
    // note: for opaque 3D object rendering, depth testing should typically be enabled.
    //我们禁用深度测试渲染半透明的扩增；注：不透明物体的渲染，通常应该启用深度测试。
    glDisable(GL_DEPTH_TEST);
    glEnable(GL_CULL_FACE);
    glCullFace(GL_BACK);
    
    
    int indexVuMarkToDisplay = -1;//显示索引vumark
    
    if (state.getNumTrackableResults() > 1) {//把Num跟踪结果
        CGFloat minimumDistance = FLT_MAX;//最小距离
        const Vuforia::CameraCalibration& cameraCalibration = Vuforia::CameraDevice::getInstance().getCameraCalibration();//CameraCalibration摄像机标定     getCameraCalibration得到的摄像机标定
        const Vuforia::Vec2F screenSize = cameraCalibration.getSize();//screenSize屏幕尺寸  getSize得到的大小
        const Vuforia::Vec2F screenCenter = Vuforia::Vec2F(screenSize.data[0] / 2.0f, screenSize.data[1] / 2.0f);//screenCenter屏幕中心
        
        for (int i = 0; i < state.getNumTrackableResults(); ++i) {//把Num跟踪结果
            // Get the trackable 得到的跟踪
            const Vuforia::TrackableResult* result = state.getTrackableResult(i);//TrackableResult跟踪的结果    state .得到追踪结果
            
            if (result->isOfType(Vuforia::VuMarkTargetResult::getClassType()))//vumark目标结果 getClassType获得类类型
            {
                Vuforia::Vec3F point = Vuforia::Vec3F(0.0, 0.0, 0.0);
                
                Vuforia::Vec2F projection = Vuforia::Tool::projectPoint(cameraCalibration, result->getPose(), point);//projection 投影 projectPoint工程项目点    cameraCalibration摄像机标定   getPose获得的姿势
                
                CGFloat distance = [self distanceSquared:projection to:screenCenter];//距离  distanceSquared 距离平方   投影到屏幕中心
                
                if (distance < minimumDistance) {//距离大于最小距离
                    minimumDistance = distance;
                    indexVuMarkToDisplay = i;//显示下标
                }
            }
        }
        
    }

    bool gotVuMark = false;//得到了VuMark是假的
    
    for (int i = 0; i < state.getNumTrackableResults(); ++i) {//把Num跟踪结果(跟踪结果数)
        // Get the trackable 得到的跟踪
        const Vuforia::TrackableResult* result = state.getTrackableResult(i);//TrackableResult 跟踪的结果     getTrackableResult得到追踪结果
        
        if (result->isOfType(Vuforia::VuMarkTargetResult::getClassType()))//vumark目标结果 getClassType获得类类型
        {
            // this boolean teels if the current VuMrk is the 'main' one i.w the one closest to the center or the only one
            //这个布尔告诉如果当前vumrk是'主'一i.w最接近中心还是只有一个
            bool isMainVumark = ((indexVuMarkToDisplay < 0) || (indexVuMarkToDisplay == i));//isMainVumark是主要的vumark   indexVuMarkToDisplay 显示下标数
            
            const Vuforia::VuMarkTargetResult* vmtResult = static_cast< const Vuforia::VuMarkTargetResult*>(result);// VuMarkTargetResult vumark目标结果
            const Vuforia::VuMarkTarget& vmtar = vmtResult->getTrackable();//Target 目标 getTrackable 获取跟踪
            const Vuforia::VuMarkTemplate& vmtmp = vmtar.getTemplate();//Template模板  getTemplate得到模板
            const Vuforia::InstanceId& instanceId = vmtar.getInstanceId();//Instance实例   得到实例ID
            
            // we initialize the user data structure with this first VuMark
            //我们初始化用户数据结构的第一vumark
            if (! userData) {
                CGFloat width = vmtar.getSize().data[0];//跟踪的目标的宽度
                CGFloat height = vmtar.getSize().data[1];//跟踪的目标的高度
                vumarkBorderSize = width / 32.0;//vumark边框大小
                userData = [[VuMarkUserData alloc]initWithUserData:vmtmp.getVuMarkUserData() vuMarkSize:CGSizeMake(width, height)];// initWithUserData用初始化列表  getVuMarkUserData 获取用户数据vumark
            }
            /********以上代码个人感觉比较重要*********/
            gotVuMark = true;
            
            if (isMainVumark) {//主要vumark
                NSString * vumarkIdValue = [self convertInstanceIdToString:instanceId];//vumark ID值  convertInstanceIdToString将实例ID转换为字符串
                NSString * vumarkIdType = [self getInstanceIdType:instanceId];//vumark ID型   获取实例Id Type
                
                NSLog(@"vumark ID值[%@] : vumark ID型382%@", vumarkIdType, vumarkIdValue);
                
                // if the vumark has changed, we hide the card
                //如果vumark已经改变，我们隐藏的卡
                // and reset the animation 并重置动画
                //如果vumark已经改变，我们隐藏卡和重置动画
                if (! [vumarkIdValue isEqualToString:currentVumarkIdOnCard]) {//在当前vumark身份卡
                    [self blinkVumark:true];//VuMark的闪光灯
                    [self hideCard];//隐藏的卡片
                }
                const Vuforia::Image & instanceImage = vmtar.getInstanceImage();//instanceImage实例图片    getInstanceImage获得实例图片
                [self updateVumarkID:vumarkIdValue andType:vumarkIdType andImage:&instanceImage];// updateVumarkID 更新vumark ID  类型  图片
            }
            Vuforia::Matrix44F poseMatrix = Vuforia::Tool::convertPose2GLMatrix(result->getPose());//构成矩阵   convertPose2GLMatrix 2gl矩阵转换姿势
            
            // OpenGL 2
            Vuforia::Matrix44F modelViewProjection;//模型视图投影
            
            glUseProgram(shaderProgramID);//着色程序的ID、、、GL使用的程序
            
            if (userData) {//用户数据
                
                // Step 1: we draw the segments of the contour by stretching a square
                //步骤1：通过拉伸正方形绘制轮廓的段
                glVertexAttribPointer(vertexHandle, 3, GL_FLOAT, GL_FALSE, 0,
                                      (const GLvoid*) &frameVertices[0]);//GL顶点的属性指针 frameVertices 框架的顶点
                
                glEnableVertexAttribArray(vertexHandle);//GL启用顶点的属性数组  vertexHandle顶点处理
                
                for(int idx = 0; idx < [userData nbSegments]; idx++) {//NB段
                    Vuforia::Matrix44F modelViewMatrix = poseMatrix;//modelViewMatrix模型视图矩阵         poseMatrix构成矩阵
                    
                    [userData modelViewMatrix:modelViewMatrix forSegmentIdx:idx width:vumarkBorderSize];//modelViewMatrix 模型视图矩阵  forSegmentIdx 对于段编号    vumarkBorderSize vumark边界尺寸
                    
                    SampleApplicationUtils::multiplyMatrix(&projectionMatrix.data[0], &modelViewMatrix.data[0], &modelViewProjection.data[0]);//SampleApplicationUtils示例应用程序定位工具    multiplyMatrix乘以一个矩阵  projectionMatrix投影矩阵  modelViewProjection 模型视图投影

                    glUniformMatrix4fv(mvpMatrixHandle, 1, GL_FALSE,
                                       (const GLfloat*)&modelViewProjection.data[0]);
                    // mvpMatrixHandle图矩阵处理    modelViewProjection模型视图投影
                    glUniform1f(calphaHandle, isMainVumark ? [self blinkVumark:false] : 1.0);
                    //isMainVumark是主要的vumark    闪烁vumark
                    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_SHORT,
                                   (const GLvoid*) &frameIndices[0]);//帧索引
                    
                }
                glDisableVertexAttribArray(vertexHandle);//GL禁用顶点数组属性  顶点处理
                
                // Step 2: we draw a plain circle at the beginning of each segment
                //步骤2：我们在每个段的开头画一个简单的圆
                glVertexAttribPointer(vertexHandle, 3, GL_FLOAT, GL_FALSE, 0,
                                      (const GLvoid*) &circleVertices[0]);
                //GL顶点属性指向   circleVertices 圆的顶点
                
                glEnableVertexAttribArray(vertexHandle);//GL的顶点属性阵列  顶点处理
                
                
                // Add a translation to recenter the augmentation
                ///添加一个翻译来唤醒隆
                // on the VuMark center, w.r.t. the origin
                //在vumark中心，关于起源   添加一个翻译来唤醒隆在vumark中心关于原点
                Vuforia::Vec2F origin = vmtmp.getOrigin(); //getOrigin得到的原点
                float translX = -origin.data[0];
                float translY = -origin.data[1];
                SampleApplicationUtils::translatePoseMatrix(translX, translY, 0.0, &poseMatrix.data[0]);// 定位工具  translatePoseMatrix 翻译姿态矩阵  构成矩阵
                
                for(int idx = 0; idx < [userData nbSegments]; idx++) {//NB段的个数
                    Vuforia::Matrix44F modelViewMatrix = poseMatrix;//模型视图矩阵等于构成矩阵
                    [userData modelViewMatrix:modelViewMatrix forSegmentStart:idx width:vumarkBorderSize];
                    //认为核心 用户数据 调用模型矩阵得到数据
                    SampleApplicationUtils::multiplyMatrix(&projectionMatrix.data[0], &modelViewMatrix.data[0], &modelViewProjection.data[0]);
                    //示例应用程序的工具   乘矩阵   投影矩阵   模型视图投影
                    glUniformMatrix4fv(mvpMatrixHandle, 1, GL_FALSE,
                                       (const GLfloat*)&modelViewProjection.data[0]);
                    glUniform1f(calphaHandle, isMainVumark ? [self blinkVumark:false] : 1.0);
                    
                    glDrawArrays(GL_TRIANGLE_FAN, 0, CIRCLE_NB_VERTICES);
                    
                }
                glDisableVertexAttribArray(vertexHandle);
            }

            SampleApplicationUtils::checkGlError("EAGLView renderFrameVuforia");//vuforia eaglview帧渲染  checkGlError检查Gl Error
        }
    }

    if(gotVuMark) {
        // if we have a detection, let's make sure
        //如果我们有一个检测，让我们确定
        // the card is visible
        //这张卡片是可见的
        [self showCard];/**************检测到东西了卡片显示************/
    } else {
        // we reset the state of the animation so that
        //我们重置动画的状态，以便
        // it triggers next time a vumark is detected
        //它触发下一次vumark检测
        //如果我们有一个检测，让我们确保卡是可见的
        [self blinkVumark:true];
        // we also reset the value of the current value of the vumark on card
        //我们的vumark复位电流值在卡的价值
        // so that we hide and show the mumark if we redetect the same vumark
        //让我们隐藏和显示mumark如果我们redetect相同的vumark
        //我们也重新vumark的当前值在卡使我们隐藏，如果我们redetect相同的vumark显示mumark
        currentVumarkIdOnCard = nil;//在当前vumark ID卡
    }
    
    glDisable(GL_BLEND);//关闭
    glDisable(GL_DEPTH_TEST);
    glDisable(GL_CULL_FACE);
    
    [self presentFramebuffer]; //目前的帧缓冲区
}
//距离的平方
- (CGFloat) distanceSquared:(Vuforia::Vec2F) p1 to:(Vuforia::Vec2F) p2 {
    
    return (CGFloat) (pow(p1.data[0] - p2.data[0], 2.0) + pow(p1.data[1] - p2.data[1], 2.0));
}
//配置视频背景与视图宽度和高度
- (void)configureVideoBackgroundWithViewWidth:(float)viewWidth andHeight:(float)viewHeight
{
    //sampleAppRenderer示例应用程序的渲染   配置视频背景与视图宽度
    [sampleAppRenderer configureVideoBackgroundWithViewWidth:viewWidth andHeight:viewHeight];
}

//------------------------------------------------------------------------------
#pragma mark - OpenGL ES management  OpenGL ES管理

- (void)initShaders//初始化着色器
{
    shaderProgramID = [SampleApplicationShaderUtils createProgramWithVertexShaderFileName:@"Simple.vertsh"
                                                   fragmentShaderFileName:@"SimpleWithColor.fragsh"];
    //shaderProgramID着色器程序ID   示例应用程序着色器工具   createProgramWithVertexShaderFileName 用顶点着色器文件名创建程序   fragmentShaderFileName片段着色器文件名

    if (0 < shaderProgramID) {//if 着色器程序ID大于0
        
        vertexHandle = glGetAttribLocation(shaderProgramID, "vertexPosition");//顶点处理
        normalHandle = glGetAttribLocation(shaderProgramID, "vertexNormal");//正常处理
        textureCoordHandle = glGetAttribLocation(shaderProgramID, "vertexTexCoord");//纹理坐标处理
        mvpMatrixHandle = glGetUniformLocation(shaderProgramID, "modelViewProjectionMatrix");//图矩阵处理
        texSampler2DHandle  = glGetUniformLocation(shaderProgramID,"texSampler2D");//二维特展开行动
        calphaHandle  = glGetUniformLocation(shaderProgramID,"calpha");
        NSLog(@"着色器初始化成功位置：VEGLV523");
    }
    else {
        NSLog(@"Could not initialise augmentation shader 无法初始化增强着色失败525");
    }
}


- (void)createFramebuffer///创建帧缓冲区
{
    if (context) {//环境上下文
        
        // Create default framebuffer object
        //创建默认的帧缓存对象
        glGenFramebuffers(1, &defaultFramebuffer);//默认的帧缓冲区
        glBindFramebuffer(GL_FRAMEBUFFER, defaultFramebuffer);
        
        // Create colour renderbuffer and allocate backing store
        //创建颜色渲染和分配存储备份
        glGenRenderbuffers(1, &colorRenderbuffer);//色彩渲染缓冲区
        glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);//色彩渲染缓冲区
        
        // Allocate the renderbuffer's storage (shared with the drawable object)
        //配置缓存的存储（与可画的对象共享）
        [context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer*)self.layer];//渲染缓冲存储器
        GLint framebufferWidth;//帧缓冲区的宽度
        GLint framebufferHeight;//高度
        glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &framebufferWidth);
        glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &framebufferHeight);
        
        // Create the depth render buffer and allocate storage
        //创建深度渲染缓冲区和分配存储
        glGenRenderbuffers(1, &depthRenderbuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, depthRenderbuffer);
        glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, framebufferWidth, framebufferHeight);
        
        // Attach colour and depth render buffers to the frame buffer
        //附加颜色和深度渲染缓冲区到帧缓冲区
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, colorRenderbuffer);
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, depthRenderbuffer);
        
        // Leave the colour render buffer bound so future rendering operations will act on it
        //将颜色渲染缓冲区绑定，以便将来呈现操作将对其起作用.
        glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
    }
}


- (void)deleteFramebuffer//删除帧缓冲
{
    if (context) {//上下文
        [EAGLContext setCurrentContext:context];//设置当前上下文
        
        if (defaultFramebuffer) {//默认的帧缓存
            glDeleteFramebuffers(1, &defaultFramebuffer);//删除
            defaultFramebuffer = 0;//默认
        }
        
        if (colorRenderbuffer) {//色彩渲染缓冲区
            glDeleteRenderbuffers(1, &colorRenderbuffer);//删除
            colorRenderbuffer = 0;//默认
        }
        
        if (depthRenderbuffer) {//深度缓冲区
            glDeleteRenderbuffers(1, &depthRenderbuffer);
            depthRenderbuffer = 0;
        }
    }
}


- (void)setFramebuffer//设置缓冲区
{
    // The EAGLContext must be set for each thread that wishes to use it.  Set
    //的eaglcontext必须设置为每个线程，希望使用它。集
    // it the first time this method is called (on the render thread)
    //这个方法第一次被调用（在渲染线程上）
    //的eaglcontext必须设置为每个线程，希望使用它。第一次调用这个方法（在渲染线程上）
    if (context != [EAGLContext currentContext]) {//当前上下文
        
        [EAGLContext setCurrentContext:context];
    }
    
    if (!defaultFramebuffer) {//默认的帧缓冲区
        // Perform on the main thread to ensure safe memory allocation for the
        //在主线程上执行，以确保安全的内存分配
        // shared buffer.  Block until the operation is complete to prevent
        //共享缓冲区。直到操作完成才能阻止
        // simultaneous access to the OpenGL context
        //同时访问OpenGL上下文
        [self performSelectorOnMainThread:@selector(createFramebuffer) withObject:self waitUntilDone:YES];//创建帧缓存
    }
    
    glBindFramebuffer(GL_FRAMEBUFFER, defaultFramebuffer);
}


- (BOOL)presentFramebuffer//目前
{
    // setFramebuffer must have been called before presentFramebuffer, therefore
    //setframebuffer必须被称为前presentframebuffer，因此
    // we know the context is valid and has been set for this (render) thread
    //我们知道上下文是有效的，并且已经为这个（渲染）线程设置
    
    // Bind the colour render buffer and present it
    
    //绑定颜色渲染缓冲区并呈现它
    glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
    
    return [context presentRenderbuffer:GL_RENDERBUFFER];
}
//将实例ID转换为字符串   instanceId实例ID
- (NSString *) convertInstanceIdToString:(const Vuforia::InstanceId&) instanceId {
    switch(instanceId.getDataType()) {//得到的数据类型
        case Vuforia::InstanceId::BYTES://字节
            return [self convertInstanceIdForBytes:instanceId];//转换实例ID为字节
        case Vuforia::InstanceId::STRING://字符串
            return [self convertInstanceIdForString:instanceId];//转换实例ID字符串
        case Vuforia::InstanceId::NUMERIC://数字
            return [self convertInstanceIdForNumeric:instanceId];//转换实例ID为数字
        default:
            return @"Unknown";//未知
    }
    
}
//转换实例ID为字节
- (NSString *) convertInstanceIdForBytes:(const Vuforia::InstanceId&) instanceId//将实例ID转换为字节
{
    const size_t MAXLEN = 100;
    char buf[MAXLEN];
    const char * src = instanceId.getBuffer();
    size_t len = instanceId.getLength();
    
    static const char* hexTable = "0123456789abcdef";
    
    if (len * 2 + 1 > MAXLEN) {
        len = (MAXLEN - 1) / 2;
    }
    
    // Go in reverse so the string is readable left-to-right.
    //反向运行，使字符串可读到左到右
    size_t bufIdx = 0;
    for (int i = (int)(len - 1); i >= 0; i--)
    {
        char upper = hexTable[(src[i] >> 4) & 0xf];
        char lower = hexTable[(src[i] & 0xf)];
        buf[bufIdx++] = upper;
        buf[bufIdx++] = lower;
    }
    
    // null terminate the string.
    //终止字符串。
    buf[bufIdx] = 0;
    
    return [NSString stringWithCString:buf encoding:NSUTF8StringEncoding];
}
//转换实例ID字符串
- (NSString *) convertInstanceIdForString:(const Vuforia::InstanceId&) instanceId//转换字符串的实例ID
{
    const char * src = instanceId.getBuffer();
    return [NSString stringWithUTF8String:src];
}
//转换实例ID为数字
- (NSString *) convertInstanceIdForNumeric:(const Vuforia::InstanceId&) instanceId//将实例ID转换为数字
{
    unsigned long long value = instanceId.getNumericValue();
    return[NSString stringWithFormat:@"%ld", value];
}
//获得IDT型实例
- (NSString *) getInstanceIdType:(const Vuforia::InstanceId&) instanceId
{//获取实例Id类型
    switch(instanceId.getDataType()) {
        case Vuforia::InstanceId::BYTES:
            return @"Bytes";//字节
        case Vuforia::InstanceId::STRING:
            return @"String";//字符串
        case Vuforia::InstanceId::NUMERIC:
            return @"Numeric";//数字
        default:
            return @"Unknown";//未知
    }
}


- (void)createReticleOverlayView//光罩覆盖视图创建
{
    CGRect myframe = [[UIScreen mainScreen] applicationFrame];//我的框架
    
    CGFloat dimRecticle = myframe.size.width / 2;
    CGFloat deltaX = dimRecticle / 2;
    CGFloat deltaY = (myframe.size.height - dimRecticle) / 2;
    
    myframe.origin.x += deltaX;
    myframe.origin.y += deltaY;
    myframe.size.height = dimRecticle;
    myframe.size.width = dimRecticle;
    
    //白色框线图片
    UIImage* image = [UIImage imageNamed:@"reticle"];
    
    UIImageView * iv = [[UIImageView alloc] initWithFrame: myframe];
    iv.image = image;
    NSLog(@"有一张图片被加载了");
    [self addSubview:iv];
}
/***********************相机检测到东西显示在屏幕上的控件*******************************/
- (void)createCardOverlayView///创建卡覆盖视图
{
    NSLog( @"Card创建卡覆盖视图调用了731");
    CGRect myframe = [[UIScreen mainScreen] applicationFrame];
    
    padding = 10.0f;
    
    CGFloat cardHeight = 120.0f;
    CGFloat cardWidth = myframe.size.width - (2.0 * padding);
    textLabelHeight = 32.0;
    
    
    // we keep the frames to display/hide
    //我们保持框架显示/隐藏
    // the card 卡
    cardFrameVisible = myframe;//card框架可见
    cardFrameVisible.origin.x = padding;//填充
    cardFrameVisible.origin.y = myframe.size.height - cardHeight - padding;
    
    cardFrameVisible.size.height = cardHeight;
    cardFrameVisible.size.width = cardWidth;
    
    cardFrameHidden = cardFrameVisible;//卡架可见
    cardFrameHidden.origin.y += cardHeight + padding;
    
    cardView = [[UIView  alloc] initWithFrame:cardFrameHidden];
    [cardView setBackgroundColor:[UIColor whiteColor]];
    // rounded cornners  圆形的角设置圆角
    cardView.layer.masksToBounds = YES;
    cardView.layer.cornerRadius = 8;
    cardView.userInteractionEnabled = YES;
    [cardView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapCard:)]];
    
    [self addSubview:cardView];
    
    UIImage* image = [UIImage imageNamed:@"card_info"];
    CGFloat imgHeight = image.size.height;
    CGFloat imgWidth = image.size.width;
    CGFloat maxImgHeight = cardHeight - 2.0 * padding;
    if (imgHeight > maxImgHeight){
        imgWidth *= maxImgHeight / imgHeight;
        imgHeight = maxImgHeight;
    }
    
    vuMarkImage = [[UIImageView alloc] initWithFrame: CGRectMake(padding, (cardHeight - imgHeight) / 2.0, imgWidth, imgHeight)];
    vuMarkImage.contentMode = UIViewContentModeScaleAspectFit;
    vuMarkImage.image = image;
    [cardView addSubview:vuMarkImage];//将image添加到cardView
    
    CGFloat startX = imgWidth + (2.0 * padding);//填充区

    // dimension of the box in which we want to display the text
    //要显示文本的框的尺寸
    textBoxWidth = cardWidth - startX - padding;
    textBoxHeight = cardHeight - 2.0 * padding;
    
    // the dimension & position of the following frames are
    // not relevant at that time as they will depend on the text actually displayed
    // (see method: updateVumarkID:(NSString *)vuMarkId andType:(NSString *) vuMarkType )
    //下列框的尺寸和位置是不相关的，因为他们将取决于实际显示的文本（见法：updatevumarkid：（NSString *）vumarkid和：（NSString *）vumarktype）
    ///*******************************重要的部分***************************************/
    cardTypeLabel = [[UILabel alloc] initWithFrame:CGRectMake(startX, 10 , textBoxWidth, textLabelHeight)];
    cardTypeLabel.numberOfLines = 0;
    cardTypeLabel.textColor = COLOR_LABEL;
    cardTypeLabel.text = @"";
    
    [cardView addSubview:cardTypeLabel];
    
    cardIdLabel = [[UILabel alloc] initWithFrame:CGRectMake(startX, 40, textBoxWidth, textLabelHeight)];
    cardIdLabel.numberOfLines = 0;
    cardIdLabel.textColor = COLOR_ID;
    cardIdLabel.text = @"";
    
    [cardView addSubview:cardIdLabel];
}
/*********扫描到东西之后要更新数据的方法**********/
//更新vumark ID
- (void) updateVumarkID:(NSString *)vuMarkId andType:(NSString *) vuMarkType andImage:(const Vuforia::Image *) instanceImage {//查一下这个方法在哪里调用了
    // we don;t update right away the value of the vumark as
    // the card will be first dismissed. The show card method
    // will get the value and display it only at the end of the animation
    // so that the disappearing card keeps the old value
    //我们不更新了的vumark价值为卡将先免职。显示卡的方法将得到的值，并显示它只在动画结束，使消失卡保留旧值
    currentVumarkIdOnCard = [vuMarkId copy];
    
    cardTypeLabel.text = vuMarkType;
    //调用此方法对文本框进行调整adjustLabelForText
    CGFloat label1Height = [self adjustLabelForText:vuMarkType withWidth:textBoxWidth inLabel:cardTypeLabel]; // cardTypeLabel.frame.size.height;
    CGFloat label2Height = [self adjustLabelForText:vuMarkId withWidth:textBoxWidth inLabel:cardIdLabel];
    
    CGFloat topY = padding + (textBoxHeight - (label1Height + label2Height)) / 2;
    
    CGRect frame = cardTypeLabel.frame;
    frame.origin.y = topY;
    cardTypeLabel.frame = frame;
    
    frame = cardIdLabel.frame;
    frame.origin.y = topY + label1Height;
    cardIdLabel.frame = frame;
    
    vuMarkImage.image = [self createUIImage:instanceImage];
}
//label的设置与计算
- (CGFloat) adjustLabelForText:(NSString *)text withWidth:(CGFloat) width inLabel:(UILabel *) label
{
    CGSize maxLabelSize = CGSizeMake(width, FLT_MAX);
    
    CGRect rect = [text boundingRectWithSize:maxLabelSize
                                     options:NSStringDrawingUsesLineFragmentOrigin| NSStringDrawingUsesFontLeading
                                  attributes:@{NSFontAttributeName:label.font}
                                     context:nil];
    
    //adjust the label the the new height. 调整标签的新高度。
    CGRect updatedFrame = label.frame;
    updatedFrame.size.height = rect.size.height;
    label.frame = updatedFrame;
    return rect.size.height;
}


- (void) onTapCard:(UITapGestureRecognizer *)sender {
    NSLog(@"这是哪个点击手势onTapCard？？？？850");
    [self hideCard];//单机手势隐藏card
}

// show the card显示card
- (void) showCard {//刷新界面了
    
    if (cardViewVisible) {
        NSLog(@"如果已经有了就return");
        return;
    }
    NSString * value = currentVumarkIdOnCard;
    [UIView animateWithDuration:0.2
                          delay:0.0
                        options: UIViewAnimationCurveEaseIn
                     animations:^{
                         cardView.frame = cardFrameVisible;
                     }
                     completion:^(BOOL finished){
                         cardViewVisible = true;
                         cardIdLabel.text = value;
                     }];//推出动画将卡片从底部动画推出
}

- (void) hideCard {//隐藏
    if (! cardViewVisible) {
        return;
    }
    [UIView animateWithDuration:0.2
                          delay:0.0
                        options: UIViewAnimationCurveEaseIn
                     animations:^{
                         cardView.frame = cardFrameHidden;
                     }
                     completion:^(BOOL finished){
                          cardViewVisible = false;
                     }];//动画隐藏
}
//当前扫到的图片
- (UIImage *)createUIImage:(const Vuforia::Image *)vuforiaImage
{
    int width = vuforiaImage->getWidth();
    int height = vuforiaImage->getHeight();
    //位组件
    int bitsPerComponent = 8;
    //每像素的位数
    int bitsPerPixel = Vuforia::getBitsPerPixel(Vuforia::RGBA8888);// getBitsPerPixel得到的每像素位数   RGBA8888使用8位存储在32位的彩色像素
    
    //每行的字节数   getBufferWidth得到缓冲区的宽度
    int bytesPerRow = vuforiaImage->getBufferWidth() * bitsPerPixel / bitsPerComponent;
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, vuforiaImage->getPixels(), Vuforia::getBufferSize(width, height, Vuforia::RGBA8888), NULL);
    
    CGImageRef imageRef = CGImageCreate(width, height, bitsPerComponent, bitsPerPixel, bytesPerRow, colorSpaceRef, bitmapInfo, provider, NULL, NO, renderingIntent);
    UIImage *image = [UIImage imageWithCGImage:imageRef];
    
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpaceRef);
    CGImageRelease(imageRef);
    
    return image;//根据扫描到的数据生成图片
}


@end
/***
 新的一轮研究开始了  
*/
