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

#import "ImageTargetsEAGLView.h"
#import "Texture.h"
#import "SampleApplicationUtils.h"
#import "SampleApplicationShaderUtils.h"
#import "Teapot.h"
#import "tiger1.h"
#import "GWLARViewController.h"

//******************************************************************************
// *** OpenGL ES thread safety ***
//
// OpenGL ES on iOS is not thread safe.  We ensure thread safety by following
// this procedure:
// 1) Create the OpenGL ES context on the main thread.
// 2) Start the Vuforia camera, which causes Vuforia to locate our EAGLView and start
//    the render thread.
// 3) Vuforia calls our renderFrameVuforia method periodically on the render thread.
//    The first time this happens, the defaultFramebuffer does not exist, so it
//    is created with a call to createFramebuffer.  createFramebuffer is called
//    on the main thread in order to safely allocate the OpenGL ES storage,
//    which is shared with the drawable layer.  The render (background) thread
//    is blocked during the call to createFramebuffer, thus ensuring no
//    concurrent use of the OpenGL ES context.
//******************************************************************************


namespace {
    // --- Data private to this unit 这私人数据单元---

    // Teapot texture filenames 茶壶纹理文件名
//    const char* textureFilenames[] = {
//        "TextureTeapotBrass.png",
//        "TextureTeapotBlue.png",
//        "TextureTeapotRed.png",
//        "building_texture.jpeg"
//    };
    const char* textureFilenames[] = {////纹理文件名
        "tiger2.jpg",
        "tiger2.jpg",
        "tiger2.jpg",
        "tiger2.jpeg"
    };
    // Model scale factor 模型比例因子
    //const float kObjectScaleNormal = 0.003f;
    //根据模型的实际尺寸调整参数（单位：米）
    const float kObjectScaleNormal = 0.09f;
    const float kObjectScaleOffTargetTracking = 0.012f;
}


@interface ImageTargetsEAGLView (PrivateMethods)//私有方法

- (void)initShaders;//初始化着色器
- (void)createFramebuffer;//创建帧缓存
- (void)deleteFramebuffer;//删除帧缓冲
- (void)setFramebuffer;//设置帧缓冲
- (BOOL)presentFramebuffer;//设置帧缓冲

@end


@implementation ImageTargetsEAGLView

@synthesize vapp = vapp;

// You must implement this method, which ensures the view's underlying layer is
// of type CAEAGLLayer
//你必须实现这个方法，使视图的基础层是caeagllayer型
#warning 00004
+ (Class)layerClass //层类
{
#warning 00009
    return [CAEAGLLayer class];
}


//------------------------------------------------------------------------------
#pragma mark - Lifecycle 生命周期
#warning 00003
//初始化应用程序回话
- (id)initWithFrame:(CGRect)frame appSession:(SampleApplicationSession *) app
{
    self = [super initWithFrame:frame];
    
    if (self) {
        vapp = app;
        // Enable retina mode if available on this device启用视网膜模式，如果此设备上可用
        if (YES == [vapp isRetinaDisplay]) {
            [self setContentScaleFactor:[UIScreen mainScreen].nativeScale];
        }
        
        // Load the augmentation textures 加载增强纹理
        for (int i = 0; i < kNumAugmentationTextures; ++i) {//#define kNumAugmentationTextures 1   //Num增强纹理
            augmentationTexture[i] = [[Texture alloc] initWithImageFile:[NSString stringWithCString:textureFilenames[i] encoding:NSASCIIStringEncoding]];//增强的纹理
        }

        // Create the OpenGL ES context创建OpenGLES上下文
        context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        
        // The EAGLContext must be set for each thread that wishes to use it.
        // Set it the first time this method is called (on the main thread)
        ////创建代表上下文的第一次调用这个方法（在主线程）
        if (context != [EAGLContext currentContext]) {
            [EAGLContext setCurrentContext:context];//设置当前上下文

        }
        
        // Generate the OpenGL ES texture and upload the texture data for use
        // when rendering the augmentation 生成OpenGL ES纹理和上传数据时使用的渲染纹理增强
        for (int i = 0; i < kNumAugmentationTextures; ++i) {//#define kNumAugmentationTextures 1   //Num增强纹理
            GLuint textureID;//纹理的ID
            glGenTextures(1, &textureID);//格伦纹理的材质ID 纹理ID
            [augmentationTexture[i] setTextureID:textureID];//增强的纹理 Texture* augmentationTexture[kNumAugmentationTextures];//增强的纹理    设置纹理ID
            glBindTexture(GL_TEXTURE_2D, textureID);//绑定的纹理
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, [augmentationTexture[i] width], [augmentationTexture[i] height], 0, GL_RGBA, GL_UNSIGNED_BYTE, (GLvoid*)[augmentationTexture[i] pngData]);
        }

        offTargetTrackingEnabled = NO;// BOOL offTargetTrackingEnabled;//启用目标跟踪
        sampleAppRenderer = [[SampleAppRenderer alloc]initWithSampleAppRendererControl:self deviceMode:Vuforia::Device::MODE_AR stereo:false nearPlane:0.01 farPlane:5];//App渲染器
        
        [self loadBuildingsModel];//负荷的建筑模型
        [self initShaders];//初始化着色器
        
        // we initialize the rendering method of the SampleAppRenderer
        //我们初始化SampleAppRenderer绘制方法
        [sampleAppRenderer initRendering];//初始化渲染
    }
    
    return self;
}


- (CGSize)getCurrentARViewBoundsSize//获取当前arview边界尺寸
{
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    CGSize viewSize = screenBounds.size;
    
    viewSize.width *= [UIScreen mainScreen].nativeScale;
    viewSize.height *= [UIScreen mainScreen].nativeScale;
    return viewSize;
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


- (void)freeOpenGLESResources//免费的OpenGLES资源
{
    // Called in response to applicationDidEnterBackground.  Free easily
    // recreated OpenGL ES resources
    //电话响应applicationDidEnterBackground有。自由轻松地创建OpenGL ES的资源
    [self deleteFramebuffer];//删除帧缓冲区
    glFinish();//结束
}
#warning 用户选择了跟踪模式识别Extended Tracking
- (void) setOffTargetTrackingMode:(BOOL) enabled {//设置目标跟踪模式
    NSLog(@"用户选择了跟踪模式识别Extended Tracking%@",enabled?@"YES":@"NO");
    offTargetTrackingEnabled = enabled;//是否启用目标跟踪
}
#warning 00005
- (void) loadBuildingsModel {//负荷的建筑模型
    buildingModel = [[SampleApplication3DModel alloc] initWithTxtResourceName:@"buildings"];
    [buildingModel read];
}

#warning 00021
- (void) updateRenderingPrimitives//更新绘制图元
{
    [sampleAppRenderer updateRenderingPrimitives];//示例应用程序的渲染
}


//------------------------------------------------------------------------------
#pragma mark - UIGLViewProtocol methods   UIGLView协议的方法

// Draw the current frame using OpenGL
//
// This method is called by Vuforia when it wishes to render the current frame to
// the screen.
////绘制当前帧使用OpenGL调用此方法时，它希望通过vuforia渲染到屏幕的当前帧。
// *** Vuforia will call this method periodically on a background thread   vuforia将调用此方法，定期在后台线程 ***
#warning 00011 程序一直再调取
- (void)renderFrameVuforia//渲染帧Vuforia
{
    //NSLog(@"启动十一000011");
    if (! vapp.cameraIsStarted) {//App的摄像头开始
    NSLog(@"! vapp.cameraIsStarted启动摄像头没有开始");
        return;
    }
    
    [sampleAppRenderer renderFrameVuforia];//vuforia渲染
}
//渲染帧状态    projectMatrix项目矩阵
#warning 00022
#warning 00028
#warning 00028
- (void) renderFrameWithState:(const Vuforia::State&) state projectMatrix:(Vuforia::Matrix44F&) projectionMatrix {
    [self setFramebuffer];//设置帧缓冲
//    NSLog(@"state%@",state.getNumTrackableResults());
//    NSLog(@"state%@",state.getNumTrackables());
//    NSLog(@"state%@",state.getTrackableResult(<#int idx#>));
//    NSLog(@"state%@",state.getNumTrackableResults());
//    NSLog(@"state%@",state.getNumTrackableResults());
    // Clear colour and depth buffers 清除颜色和深度缓冲
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);//系统的
    
    // Render video background and retrieve tracking state
    //渲染视频背景并检索跟踪状态
    [sampleAppRenderer renderVideoBackground];//渲染视频背景
    
    glEnable(GL_DEPTH_TEST);
    // We must detect if background reflection is active and adjust the culling direction.
    // If the reflection is active, this means the pose matrix has been reflected as well,
    // therefore standard counter clockwise face culling will result in "inside out" models.
    //我们必须检测如果背景反射主动调整选择方向。如果反射活跃，这意味着姿态矩阵被反映为好，因此标准逆时针面剔除会造成“由内而外”模型
    if (offTargetTrackingEnabled) {//启用了目标跟踪
        glDisable(GL_CULL_FACE);
        //用户选用了扩展跟踪 Extended Tracking
    } else {
        //没有目标走
        glEnable(GL_CULL_FACE);
    }
    glCullFace(GL_BACK);
    
    for (int i = 0; i < state.getNumTrackableResults(); ++i) {//把Num跟踪结果
        // Get the trackable 得到的跟踪
        const Vuforia::TrackableResult* result = state.getTrackableResult(i);//TrackableResult跟踪的结果    state .得到追踪结果
        //NSLog(@"state%d",state.getNumTrackableResults());
        //NSLog(@"state是啥%d",state.getNumTrackables());
        
        const Vuforia::Trackable& trackable = result->getTrackable();//可追踪的
       // NSLog(@"state %s",trackable.getName());
        //NSLog(@"state %d",trackable.getId());
    
        
        
        
        
        
        
        
        
        
        
/******/
        //const Vuforia::Trackable& trackable = result->getTrackable();
        //Vuforia::Matrix44F modelViewMatrix = Vuforia::Tool::convertPose2GLMatrix(result->getPose());//modelViewMatrix模型视图矩阵
    /******/
        // OpenGL 2
        //Vuforia::Matrix44F modelViewProjection;//模型视图投影
        
        if (offTargetTrackingEnabled) {//启用了目标跟踪
            /******/
            //SampleApplicationUtils::rotatePoseMatrix(90, 1, 0, 0,&modelViewMatrix.data[0]);//rotatePoseMatrix旋转姿态矩阵
            //SampleApplicationUtils::scalePoseMatrix(kObjectScaleOffTargetTracking, kObjectScaleOffTargetTracking, kObjectScaleOffTargetTracking, &modelViewMatrix.data[0]);//scalePoseMatrix 尺度姿态矩阵  （目标距离目标跟踪，）
            NSLog(@"识别0001用户选用了Extended Tracking");
        } else {
            /******/
            //SampleApplicationUtils::translatePoseMatrix(0.0f, 0.0f, kObjectScaleNormal, &modelViewMatrix.data[0]);//翻译姿态矩阵   kObjectScaleNormal对象规模正常
            //SampleApplicationUtils::scalePoseMatrix(kObjectScaleNormal, kObjectScaleNormal, kObjectScaleNormal, &modelViewMatrix.data[0]);//scalePoseMatrix的位姿矩阵 kObjectScaleNormal对象规模正常
            //NSLog(@"识别0001");
        }
        /******/
        //SampleApplicationUtils::multiplyMatrix(&projectionMatrix.data[0], &modelViewMatrix.data[0], &modelViewProjection.data[0]);//多矩阵
        
        glUseProgram(shaderProgramID);//着色器程序ID
        
        if (offTargetTrackingEnabled) {//启用目标跟踪
            glVertexAttribPointer(vertexHandle, 3, GL_FLOAT, GL_FALSE, 0, (const GLvoid*)buildingModel.vertices);//顶点处理  buildingModel 构建模型
            glVertexAttribPointer(normalHandle, 3, GL_FLOAT, GL_FALSE, 0, (const GLvoid*)buildingModel.normals);//v正常的处理
            glVertexAttribPointer(textureCoordHandle, 2, GL_FLOAT, GL_FALSE, 0, (const GLvoid*)buildingModel.texCoords);//纹理坐标处理
            //NSLog(@"识别0002用户选用了Extended Tracking");
        } else {
            
//            glVertexAttribPointer(vertexHandle, 3, GL_FLOAT, GL_FALSE, 0, (const GLvoid*)teapotVertices);
//            glVertexAttribPointer(normalHandle, 3, GL_FLOAT, GL_FALSE, 0, (const GLvoid*)teapotNormals);
//            glVertexAttribPointer(textureCoordHandle, 2, GL_FLOAT, GL_FALSE, 0, (const GLvoid*)teapotTexCoords);
            glVertexAttribPointer(vertexHandle, 3, GL_FLOAT, GL_FALSE, 0, (const GLvoid*)tiger1Verts);
            glVertexAttribPointer(normalHandle, 3, GL_FLOAT, GL_FALSE, 0, (const GLvoid*)tiger1Normals);
            glVertexAttribPointer(textureCoordHandle, 2, GL_FLOAT, GL_FALSE, 0, (const GLvoid*)tiger1TexCoords);
            //NSLog(@"识别0002");
        }
        
        glEnableVertexAttribArray(vertexHandle);//顶点
        glEnableVertexAttribArray(normalHandle);//正常
        glEnableVertexAttribArray(textureCoordHandle);//纹理
        
        // Choose the texture based on the target name根据目标名称选择纹理
        int targetIndex = 0;//目标下标
        // "stones"chips
        //if (!strcmp(trackable.getName(), "chips"))
        
        if (!strcmp(trackable.getName(), "shaimobao"))//trackable可追踪
            targetIndex = 1;
        else if (!strcmp(trackable.getName(), "tarmac"))
            targetIndex = 2;
        
        glActiveTexture(GL_TEXTURE0);//活跃的纹理
        
        if (offTargetTrackingEnabled) {//启用目标跟踪
            glBindTexture(GL_TEXTURE_2D, augmentationTexture[3].textureID);//绑定的纹理   augmentationTexture增强的纹理
            NSLog(@"识别0003用户选用了Extended Tracking");
        } else {
            //NSLog(@"识别0003");
            glBindTexture(GL_TEXTURE_2D, augmentationTexture[targetIndex].textureID);
        }
        /******/
       // glUniformMatrix4fv(mvpMatrixHandle, 1, GL_FALSE, (const GLfloat*)&modelViewProjection.data[0]);
        glUniform1i(texSampler2DHandle, 0 /*GL_TEXTURE0*/);
        
        if (offTargetTrackingEnabled) {
            glDrawArrays(GL_TRIANGLES, 0, (int)buildingModel.numVertices);
            NSLog(@"识别0004用户选用了Extended Tracking");
        } else {
            ////glDrawElements(GL_TRIANGLES, NUM_TEAPOT_OBJECT_INDEX, GL_UNSIGNED_SHORT, (const GLvoid*)teapotIndices);
            //NSLog(@"识别0004");
            //glDrawElements(GL_TRIANGLES, NUM_TEAPOT_OBJECT_INDEX, GL_UNSIGNED_SHORT, (const GLvoid*)teapotIndices);
            //glDrawArrays(GL_TRIANGLES, 0, tiger1NumVerts);
        }
        
        //glDisableVertexAttribArray(vertexHandle);
        //glDisableVertexAttribArray(normalHandle);
        //glDisableVertexAttribArray(textureCoordHandle);
        
        SampleApplicationUtils::checkGlError("EAGLView renderFrameVuforia");//vuforia eaglview帧渲染  checkGlError检查Gl Error
    }
    
    glDisable(GL_DEPTH_TEST);
    glDisable(GL_CULL_FACE);
    
    [self presentFramebuffer];//目前的帧缓冲区
}
//配置视频背景与视图宽度和高度
#warning 00018
- (void)configureVideoBackgroundWithViewWidth:(float)viewWidth andHeight:(float)viewHeight
{
     //sampleAppRenderer示例应用程序的渲染   配置视频背景与视图宽度
    [sampleAppRenderer configureVideoBackgroundWithViewWidth:viewWidth andHeight:viewHeight];
}

//------------------------------------------------------------------------------
#pragma mark - OpenGL ES management   OpenGL ES管理
#warning 00006
- (void)initShaders //初始化着色器
{
    shaderProgramID = [SampleApplicationShaderUtils createProgramWithVertexShaderFileName:@"Simple.vertsh"
                                                   fragmentShaderFileName:@"Simple.fragsh"];
//shaderProgramID着色器程序ID   示例应用程序着色器工具   createProgramWithVertexShaderFileName 用顶点着色器文件名创建程序   fragmentShaderFileName片段着色器文件名
    if (0 < shaderProgramID) {//if 着色器程序ID大于0
        vertexHandle = glGetAttribLocation(shaderProgramID, "vertexPosition");//顶点处理
        normalHandle = glGetAttribLocation(shaderProgramID, "vertexNormal");//正常处理
        textureCoordHandle = glGetAttribLocation(shaderProgramID, "vertexTexCoord");//纹理坐标处理
        mvpMatrixHandle = glGetUniformLocation(shaderProgramID, "modelViewProjectionMatrix");//图矩阵处理
        texSampler2DHandle  = glGetUniformLocation(shaderProgramID,"texSampler2D");//二维特展开行动
        NSLog(@"着色器初始化成功位置：ImageTargetsEAGLView358");
    }
    else {
        NSLog(@"Could not initialise augmentation shader无法初始化增强着色失败361");
    }
}

#warning 00025
- (void)createFramebuffer//创建帧缓冲区
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

#warning 00023
#warning 00029
#warning 00029
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
#warning 没有识别出来走
        [self performSelectorOnMainThread:@selector(createFramebuffer) withObject:self waitUntilDone:YES];//创建帧缓存
    }
    
    glBindFramebuffer(GL_FRAMEBUFFER, defaultFramebuffer);
}

#warning 00026
#warning 00030
#warning 000030presentFramebuffer当前帧缓冲程序一直在调取

- (BOOL)presentFramebuffer//目前
{
    // setFramebuffer must have been called before presentFramebuffer, therefore
    //setframebuffer必须被称为前presentframebuffer，因此

    // we know the context is valid and has been set for this (render) thread
    //我们知道上下文是有效的，并且已经为这个（渲染）线程设置
    // Bind the colour render buffer and present it
    //绑定颜色渲染缓冲区并呈现它
    glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
    //NSLog(@"presentFramebuffer当前帧缓冲");
    return [context presentRenderbuffer:GL_RENDERBUFFER];
}



@end
