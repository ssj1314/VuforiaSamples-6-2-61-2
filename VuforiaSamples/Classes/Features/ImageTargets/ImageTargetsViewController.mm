/*===============================================================================
Copyright (c) 2016 PTC Inc. All Rights Reserved.

Copyright (c) 2012-2015 Qualcomm Connected Experiences, Inc. All Rights Reserved.

Vuforia is a trademark of PTC Inc., registered in the United States and other 
countries.
===============================================================================*/

#import "ImageTargetsViewController.h"
#import "VuforiaSamplesAppDelegate.h"
#import <Vuforia/Vuforia.h>
#import <Vuforia/TrackerManager.h>
#import <Vuforia/ObjectTracker.h>
#import <Vuforia/Trackable.h>
#import <Vuforia/DataSet.h>
#import <Vuforia/CameraDevice.h>
/******/
#import <Vuforia/TrackableResult.h>
#import "GWLARViewController.h"

#import "UnwindMenuSegue.h"
#import "PresentMenuSegue.h"
#import "SampleAppMenuViewController.h"

@interface ImageTargetsViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *ARViewPlaceholder;//AR视图位置
@property(nonatomic,strong)NSString *GWLstring;
@property(nonatomic,strong)NSTimer *rssisTimer;
@property(nonatomic,strong)NSString *GWLNameID;
@end

@implementation ImageTargetsViewController

@synthesize tapGestureRecognizer, vapp, eaglView;//点击手势识别器

#warning 00002
- (CGRect)getCurrentARViewFrame
{
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    CGRect viewFrame = screenBounds;
    
    // If this device has a retina display, scale the view bound
    // for the AR (OpenGL) view
    if (YES == vapp.isRetinaDisplay) {
        viewFrame.size.width *= [UIScreen mainScreen].nativeScale;
        viewFrame.size.height *= [UIScreen mainScreen].nativeScale;
    }
    return viewFrame;
}
#warning 启动所走0001
- (void)loadView//加载视图
{
    
    NSLog(@"启动所走0001");
    // Custom initialization 自定义初始化
    self.title = @"Image Targets";//图像目标
    
    if (self.ARViewPlaceholder != nil) {//ARView 站位
        [self.ARViewPlaceholder removeFromSuperview];
        self.ARViewPlaceholder = nil;
    }
    
    extendedTrackingEnabled = NO;//跟踪功能的开启
    continuousAutofocusEnabled = YES;//连续自动对焦功能开启
    flashEnabled = NO;//闪光灯启用
    frontCameraEnabled = NO;//前置摄像头的开启
    //我们保持实例的引用来实现的vuforia回调
    vapp = [[SampleApplicationSession alloc] initWithDelegate:self];
    
    CGRect viewFrame = [self getCurrentARViewFrame];
    
    eaglView = [[ImageTargetsEAGLView alloc] initWithFrame:viewFrame appSession:vapp];
    [self setView:eaglView];
    VuforiaSamplesAppDelegate *appDelegate = (VuforiaSamplesAppDelegate*)[[UIApplication sharedApplication] delegate];//Vuforia的样本代理
    appDelegate.glResourceHandler = eaglView;//资源处理器
    
    // double tap used to also trigger the menu
    //双击出发事件
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget: self action:@selector(doubleTapGestureAction:)];
    doubleTap.numberOfTapsRequired = 2;
    [self.view addGestureRecognizer:doubleTap];
    
    // a single tap will trigger a single autofocus operation
    //单击是对焦操作
    tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(autofocus:)];
    if (doubleTap != NULL) {
        [tapGestureRecognizer requireGestureRecognizerToFail:doubleTap];
    }
    
    UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeGestureAction:)];
    [swipeRight setDirection:UISwipeGestureRecognizerDirectionRight];
    [self.view addGestureRecognizer:swipeRight];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(dismissARViewController)
                                                 name:@"kDismissARViewController"
                                               object:nil];
    
    // we use the iOS notification to pause/resume the AR when the application goes (or come back from) background
    //我们使用iOS通知暂停/ AR应用程序时，会恢复（或返回）的背景
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(pauseAR)
     name:UIApplicationWillResignActiveNotification
     object:nil];//暂停AR
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(resumeAR)//恢复AR
     name:UIApplicationDidBecomeActiveNotification
     object:nil];
    
    // initialize AR 初始化AR
    [vapp initAR:Vuforia::GL_20 orientation:self.interfaceOrientation];

    // show loading animation while AR is being initialized
    //显示加载动画，而AR正在初始化
    [self showLoadingAnimation];
}
//暂停AR
- (void) pauseAR {
    NSError * error = nil;
    if (![vapp pauseAR:&error]) {
        NSLog(@"Error pausing暂停 AR:%@", [error description]);
    }
}
//恢复AR
- (void) resumeAR {
    NSError * error = nil;
    if(! [vapp resumeAR:&error]) {
        NSLog(@"Error resuming 恢复 AR:%@", [error description]);
    }
    [eaglView updateRenderingPrimitives];//更新渲染数据
    // on resume, we reset the flash在简历中，我们重置闪光灯
    Vuforia::CameraDevice::getInstance().setFlashTorchMode(false);
    flashEnabled = NO;
}

#warning 00008
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.showingMenu = NO;//显示菜单
    
    // Do any additional setup after loading the view.
    //加载视图后再做任何附加设置。
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    [self.view addGestureRecognizer:tapGestureRecognizer];
    NSLog(@" : %s", self.navigationController.navigationBarHidden ? "Yes" : "No");
    //三目运算符如果self.navigationController.navigationBarHidden成立的话就取冒号前面的反之就取后面
}
//视图将要消失的时候
#warning 222203
- (void)viewWillDisappear:(BOOL)animated
{
    NSLog(@"界面要消失了");
    [_rssisTimer setFireDate:[NSDate distantFuture]];
    // on iOS 7, viewWillDisappear may be called when the menu is shown
    // but we don't want to stop the AR view in that case
    //在iOS 7，viewwilldisappear堪称当菜单显示但我们不想停下来，在这种情况下，AR视图
    if (self.showingMenu) {
        return;
    }
    
   // [vapp stopAR:nil];
    
    // Be a good OpenGL ES citizen: now that Vuforia is paused and the render
    // thread is not executing, inform the root view controller that the
    // EAGLView should finish any OpenGL ES commands
    //是一个很好的OpenGL ES的市民：现在vuforia暂停和渲染线程不执行，通知根视图控制器，eaglview应该完成任何OpenGL ES的命令
    [self finishOpenGLESCommands];//结束打开的OpenGL
    
    VuforiaSamplesAppDelegate *appDelegate = (VuforiaSamplesAppDelegate*)[[UIApplication sharedApplication] delegate];
    appDelegate.glResourceHandler = nil;
    
    [super viewWillDisappear:animated];
}
//界面将要出现
-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.GWLstring = @"2";
    _rssisTimer = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(rssis2S) userInfo:nil repeats:YES];
    [_rssisTimer fire];

        NSError *error = [[NSError alloc]init];
    [vapp startAR:Vuforia::CameraDevice::CAMERA_DIRECTION_BACK error:&error];

}
- (void)dealloc//释放内存
{//用户选择了跟踪模式识别Extended Tracking调用
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)finishOpenGLESCommands//结束OpenGLES命令
{
    // Called in response to applicationWillResignActive.  Inform the EAGLView
    //电话响应applicationwillresignactive。通知eaglview

    [eaglView finishOpenGLESCommands];
}

- (void)freeOpenGLESResources//免费开放的OpenGLES资源
{
    // Called in response to applicationDidEnterBackground.  Inform the EAGLView
    //电话响应applicationDidEnterBackground有。通知eaglview
    [eaglView freeOpenGLESResources];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - loading animation//加载动画
#warning 00007
- (void) showLoadingAnimation {
    CGRect indicatorBounds;//指标的界限
    CGRect mainBounds = [[UIScreen mainScreen] bounds];
    int smallerBoundsSize = MIN(mainBounds.size.width, mainBounds.size.height);
    int largerBoundsSize = MAX(mainBounds.size.width, mainBounds.size.height);
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown ) {
        indicatorBounds = CGRectMake(smallerBoundsSize / 2 - 12,
                                     largerBoundsSize / 2 - 12, 24, 24);
    }
    else {
        indicatorBounds = CGRectMake(largerBoundsSize / 2 - 12,
                                     smallerBoundsSize / 2 - 12, 24, 24);
    }
    
    UIActivityIndicatorView *loadingIndicator = [[UIActivityIndicatorView alloc]
                                                  initWithFrame:indicatorBounds];
    
    loadingIndicator.tag  = 1;
    loadingIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
    [eaglView addSubview:loadingIndicator];
    [loadingIndicator startAnimating];
}

- (void) hideLoadingAnimation {//隐藏加载动画
    UIActivityIndicatorView *loadingIndicator = (UIActivityIndicatorView *)[eaglView viewWithTag:1];
    [loadingIndicator removeFromSuperview];
}


#pragma mark - SampleApplicationControl示例应用程序控制

// Initialize the application trackers初始化应用程序跟踪
#warning 00010
- (bool) doInitTrackers {//做初始化跟踪器
    // Initialize the object tracker初始化对象跟踪器
    Vuforia::TrackerManager& trackerManager = Vuforia::TrackerManager::getInstance();// trackerManager跟踪管理   getInstance得到实例
    Vuforia::Tracker* trackerBase = trackerManager.initTracker(Vuforia::ObjectTracker::getClassType());//trackerBase追踪基地 initTracker 初始化跟踪器  ObjectTracker对象跟踪 getClassType得到类
    if (trackerBase == NULL)
    {
        NSLog(@"Failed to initialize ObjectTracker.初始化失败，ObjectTracker。");
        return false;
    }
    return true;
}

// load the data associated to the trackers 负荷跟踪的相关数据
#warning 000012
- (bool) doLoadTrackersData {//做负载跟踪数据
    //dataSetStonesAndChips = [self loadObjectTrackerDataSet:@"StonesAndChips.xml"];
    dataSetStonesAndChips = [self loadObjectTrackerDataSet:@"shaimobao.xml"];//加载对象跟踪数据集
    dataSetTarmac = [self loadObjectTrackerDataSet:@"Tarmac.xml"];
    
    if ((dataSetStonesAndChips == NULL) || (dataSetTarmac == NULL)) {////数据集加载
        NSLog(@"Failed to load datasets加载数据集失败.xml255");
        return NO;
    }
    if (! [self activateDataSet:dataSetStonesAndChips]) {//激活数据集：加载数据集
        NSLog(@"Failed to activate dataset激活数据集失败.xml259");
        return NO;
    }
    
    
    return YES;
}

// start the application trackers 启动应用程序跟踪
#warning 00019
- (bool) doStartTrackers {//开始追踪
    Vuforia::TrackerManager& trackerManager = Vuforia::TrackerManager::getInstance();//TrackerManager  跟踪管理  getInstance  得到的实例
    Vuforia::Tracker* tracker = trackerManager.getTracker(Vuforia::ObjectTracker::getClassType());//Tracker  跟踪器  getTracker  得到跟踪器   ObjectTracker  目标跟踪 getClassType  得到的类类型
    if(tracker == 0) {//如果跟踪器为空那么就返回假，负责就返回开始跟踪返回真
        return false;
    }
    tracker->start();
    return true;
}

// callback called when the initailization of the AR is done  时调用的回调initailization AR完成
#warning 00016
//- (void) onInitARDone:(NSError *)initError {//onInitARDone 对AR进行初始化
//    UIActivityIndicatorView *loadingIndicator = (UIActivityIndicatorView *)[eaglView viewWithTag:1];//加载指示器
//    [loadingIndicator removeFromSuperview];//取消加载指示器
//
//    
//    if (initError == nil) {//如果没有初始化错误就执行以下代码
//        NSError * error = nil;
//        [vapp startAR:Vuforia::CameraDevice::CAMERA_DIRECTION_BACK error:&error];//CameraDevice 相机设备   CAMERA_DIRECTION_BACK 选取相机的方向为正常
//        
//        [eaglView updateRenderingPrimitives];//更新绘制图元
//
//        // by default, we try to set the continuous auto focus mode
//        //默认情况下，我们尝试设置连续自动对焦模式
//        continuousAutofocusEnabled = Vuforia::CameraDevice::getInstance().setFocusMode(Vuforia::CameraDevice::FOCUS_MODE_CONTINUOUSAUTO);
//        //continuousAutofocusEnabled  连续自动对焦功能 setFocusMode 设置对焦模式
//
//        //[eaglView configureBackground];
//
//    } else {//如果初始化有错误就执行以下代码  getInstance  得到的实例  setFocusMode 设置对焦模式 连续自动对焦模式
//        NSLog(@"Error initializing AR初始化AR失败298:%@", [initError description]);
//        dispatch_async( dispatch_get_main_queue(), ^{
//            
//            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
//                                                            message:[initError localizedDescription]
//                                                           delegate:self
//                                                  cancelButtonTitle:@"OK"
//                                                  otherButtonTitles:nil];
//            [alert show];
//        });
//    }
//}
- (void) onInitARDone:(NSError *)initError {
    UIActivityIndicatorView *loadingIndicator = (UIActivityIndicatorView *)[eaglView viewWithTag:1];//加载指示器
    [loadingIndicator removeFromSuperview];
    
    
    if (initError == nil) {
        NSError * error = nil;
        [vapp startAR:Vuforia::CameraDevice::CAMERA_DIRECTION_BACK error:&error];
        
        [eaglView updateRenderingPrimitives];
        
        // by default, we try to set the continuous auto focus mode
        continuousAutofocusEnabled = Vuforia::CameraDevice::getInstance().setFocusMode(Vuforia::CameraDevice::FOCUS_MODE_CONTINUOUSAUTO);
        //continuousAutofocusEnabled
        //[eaglView configureBackground];
        
    } else {
        NSLog(@"Error initializing AR初始化AR失败298:%@", [initError description]);
        dispatch_async( dispatch_get_main_queue(), ^{
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                            message:[initError localizedDescription]
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        });
    }
}

#pragma mark - UIAlertViewDelegate警告狂代理

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    //返回 ARViewController
    [[NSNotificationCenter defaultCenter] postNotificationName:@"kDismissARViewController" object:nil];
}
//返回ARViewController
- (void)dismissARViewController
{
    [self.navigationController setNavigationBarHidden:NO animated:YES];//隐藏导航栏
    [self.navigationController popToRootViewControllerAnimated:NO];//返回不要动画
}
//应用程序必须处理的视频背景配置
#warning 00017
- (void)configureVideoBackgroundWithViewWidth:(float)viewWidth andHeight:(float)viewHeight//配置视频背景与视图宽度和高度 eaglView
{
    [eaglView configureVideoBackgroundWithViewWidth:(float)viewWidth andHeight:(float)viewHeight];
}
//对vuforia更新
#warning 00020
- (void) onVuforiaUpdate: (Vuforia::State *) state
{
    self.GWLstring = @"q";
    //NSLog(@"更新");
    #warning 00024
    #warning 00027
    #warning 00027程序一直在走
    if (switchToTarmac) {
        [self activateDataSet:dataSetTarmac];
        switchToTarmac = NO;
    }
    if (switchToStonesAndChips) {
        [self activateDataSet:dataSetStonesAndChips];
        switchToStonesAndChips = NO;
    }
    //////**********/////
    for (int i = 0; i < state->getNumTrackableResults(); ++i) {//把Num跟踪结果
        // Get the trackable 得到的跟踪
        const Vuforia::TrackableResult* result = state->getTrackableResult(i);//TrackableResult跟踪的结果    state .得到追踪结果
        NSLog(@"state%d",state->getNumTrackableResults());
        NSLog(@"state是啥%d",state->getNumTrackables());
        
        const Vuforia::Trackable& trackable = result->getTrackable();//可追踪的
        NSLog(@"state %s",trackable.getName());
        self.GWLNameID = [NSString stringWithFormat:@"%s",trackable.getName()];
        NSLog(@"state %d",trackable.getId());
        self.GWLstring = @"y";
    }
    
        NSLog(@"%@",self.GWLstring);
}

#pragma mark - 两秒取一次数据
//创建一个定时器2S取一次信号的最大值
-(void)rssis2S{
    if ([self.GWLstring isEqualToString:@"y"]) {
        [self pauseAR];
        //跳转
        //UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:self];
        GWLARViewController *VC = [[GWLARViewController alloc]initWithNibName:@"GWLARViewController" bundle:nil];
        VC.title = @"详情页面";
        VC.GWLID = self.GWLNameID;
        [self presentViewController:VC animated:YES completion:^{
            
        }];
        //[nav pushViewController:VC animated:YES];
    }else{
        NSLog(@"不能跳");
    }
    
}


// Load the image tracker data set 加载图像跟踪器数据集//dataFile 数据文件
#warning 00013
- (Vuforia::DataSet *)loadObjectTrackerDataSet:(NSString*)dataFile
{//dataFile 数据文件
    NSLog(@"loadObjectTrackerDataSet 加载图像跟踪器数据集345(%@)", dataFile);
    Vuforia::DataSet * dataSet = NULL;
    
    // Get the Vuforia tracker manager image tracker得到vuforia图像跟踪器跟踪管理
    Vuforia::TrackerManager& trackerManager = Vuforia::TrackerManager::getInstance();//trackerManager 跟踪管理    得到的实例
    Vuforia::ObjectTracker* objectTracker = static_cast<Vuforia::ObjectTracker*>(trackerManager.getTracker(Vuforia::ObjectTracker::getClassType()));//跟踪对象 getTracker获取跟踪  getClassType 获得类类型
    
    if (NULL == objectTracker) {// 跟踪对象
        NSLog(@"ERROR: failed to get the ObjectTracker from the tracker manager错误：无法从跟踪经理得到ObjectTracker353");
        return NULL;
    } else {
        dataSet = objectTracker->createDataSet();
        //createDataSet创建数据集
        
        if (NULL != dataSet) {
            NSLog(@"INFO: successfully loaded data set 信息：成功地加载数据集360");
            
            // Load the data set from the app's resources location从应用程序的资源位置加载数据集
            if (!dataSet->load([dataFile cStringUsingEncoding:NSASCIIStringEncoding], Vuforia::STORAGE_APPRESOURCE)) {////STORAGE_APPRESOURCE存储应用程序资源
                NSLog(@"ERROR: failed to load data set错误：加载数据集失败364");
                objectTracker->destroyDataSet(dataSet);//破坏数据
                dataSet = NULL;
            }
        }
        else {
            NSLog(@"ERROR: failed to create data set错误：未能创建数据集370");
        }
    }
    
    return dataSet;
}

#warning 界面消失停止跟踪222204
- (bool) doStopTrackers {//停止跟踪
    // Stop the tracker停止跟踪
    Vuforia::TrackerManager& trackerManager = Vuforia::TrackerManager::getInstance();//得到的实例
    Vuforia::Tracker* tracker = trackerManager.getTracker(Vuforia::ObjectTracker::getClassType());//获得类类型
    
    if (NULL != tracker) {
        tracker->stop();
        NSLog(@"INFO: successfully stopped tracker成功停止跟踪信息385");
        return YES;
    }
    else {
        NSLog(@"ERROR: failed to get the tracker from the tracker manager错误：未能从跟踪管理器获取跟踪程序389");
        return NO;
    }
}
#warning 界面消失清空跟踪数据2222205
- (bool) doUnloadTrackersData {//卸载跟踪数据
    [self deactivateDataSet: dataSetCurrent];//deactivateDataSet 关闭数据集 dataSetCurrent当前数据集
    dataSetCurrent = nil;//清空当前数据集
    
    // Get the image tracker:获取图像跟踪器
    Vuforia::TrackerManager& trackerManager = Vuforia::TrackerManager::getInstance();
    Vuforia::ObjectTracker* objectTracker = static_cast<Vuforia::ObjectTracker*>(trackerManager.getTracker(Vuforia::ObjectTracker::getClassType()));
    
    // Destroy the data sets:破坏数据集
    if (!objectTracker->destroyDataSet(dataSetTarmac))
    {
        NSLog(@"Failed to destroy data set Tarmac.未能摧毁数据集上405");
    }
    if (!objectTracker->destroyDataSet(dataSetStonesAndChips))
    {
        NSLog(@"Failed to destroy data set Stones and Chips.未能破坏数据集的石头和芯片409");
    }
    
    NSLog(@"datasets destroyed数据销毁");
    return YES;
}
#warning 000014
//激活数据集
- (BOOL)activateDataSet:(Vuforia::DataSet *)theDataSet
{
    // if we've previously recorded an activation, deactivate it
    //如果我们先前记录的激活、关闭它
    if (dataSetCurrent != nil)
    {
        [self deactivateDataSet:dataSetCurrent];
    }
    BOOL success = NO;
    
    // Get the image tracker:获取图像跟踪器
    Vuforia::TrackerManager& trackerManager = Vuforia::TrackerManager::getInstance();
    Vuforia::ObjectTracker* objectTracker = static_cast<Vuforia::ObjectTracker*>(trackerManager.getTracker(Vuforia::ObjectTracker::getClassType()));
    
    if (objectTracker == NULL) {
        NSLog(@"Failed to load tracking data set because the ObjectTracker has not been initialized.未能加载跟踪数据集，因为objecttracker尚未初始化431");
    }
    else
    {
        // Activate the data set:激活数据集
        if (!objectTracker->activateDataSet(theDataSet))
        {
            NSLog(@"Failed to activate data set.激活数据集失败438");
        }
        else
        {
            NSLog(@"Successfully activated data set.成功激活数据集442");
            dataSetCurrent = theDataSet;
            success = YES;
        }
    }
    
    // we set the off target tracking mode to the current state我们将关闭目标跟踪模式设置为当前状态
    if (success) {
        [self setExtendedTrackingForDataSet:dataSetCurrent start:extendedTrackingEnabled];//setExtendedTrackingForDataSet设置扩展的跟踪数据  dataSetCurrent当前数据集   extendedTrackingEnabled跟踪功能的扩展
    }
    
    return success;
}
//deactivateDataSet关闭数据集
#warning 关闭界面消失的时候关闭数据222205
- (BOOL)deactivateDataSet:(Vuforia::DataSet *)theDataSet
{
    if ((dataSetCurrent == nil) || (theDataSet != dataSetCurrent))
    {
        NSLog(@"Invalid request to deactivate data set.关闭数据集无效的请求460");
        return NO;
    }
    
    BOOL success = NO;
    
    // we deactivate the enhanced tracking  我们关闭增强跟踪
    [self setExtendedTrackingForDataSet:theDataSet start:NO];//设置扩展跟踪数据集
    
    // Get the image tracker:获取图像跟踪器
    Vuforia::TrackerManager& trackerManager = Vuforia::TrackerManager::getInstance();
    Vuforia::ObjectTracker* objectTracker = static_cast<Vuforia::ObjectTracker*>(trackerManager.getTracker(Vuforia::ObjectTracker::getClassType()));
    
    if (objectTracker == NULL)
    {
        NSLog(@"Failed to unload tracking data set because the ObjectTracker has not been initialized.未能卸载跟踪数据集，因为objecttracker尚未初始化475");
    }
    else
    {
        // Activate the data set:激活数据集
        if (!objectTracker->deactivateDataSet(theDataSet))
        {
            NSLog(@"Failed to deactivate data set.未能关闭数据集482");
        }
        else
        {
            success = YES;
        }
    }
    
    dataSetCurrent = nil;
    
    return success;
}

//设置扩展跟踪数据集
#warning 00015
- (BOOL) setExtendedTrackingForDataSet:(Vuforia::DataSet *)theDataSet start:(BOOL) start {//设置扩展跟踪数据集
    BOOL result = YES;
    for (int tIdx = 0; tIdx < theDataSet->getNumTrackables(); tIdx++) {
        //getNumTrackables 得到可追踪的数量
        Vuforia::Trackable* trackable = theDataSet->getTrackable(tIdx);
        if (start) {
            if (!trackable->startExtendedTracking())//启动扩展跟踪
            {
                NSLog(@"Failed to start extended tracking on无法开始扩展跟踪503: %s", trackable->getName());
                result = false;//非法
            }
        } else {
            if (!trackable->stopExtendedTracking())//停止扩展跟踪
            {
                NSLog(@"Failed to stop extended tracking on无法停止扩展跟踪509: %s", trackable->getName());
                result = false;//返回错误
            }
        }
    }
    return result;
}

- (bool) doDeinitTrackers {//Deinit(初始化)跟踪器
    Vuforia::TrackerManager& trackerManager = Vuforia::TrackerManager::getInstance();//trackerManager跟踪管理器  getInstance 得到的实例
    trackerManager.deinitTracker(Vuforia::ObjectTracker::getClassType());
    return YES;
}
#warning 手指单击屏幕
- (void)autofocus:(UITapGestureRecognizer *)sender//自动对焦
{
    [self performSelector:@selector(cameraPerformAutoFocus) withObject:nil afterDelay:.4];//0.4秒相机执行自动对焦
}
#warning 手指单击屏幕回调方法
- (void)cameraPerformAutoFocus//0.4秒回调的方法  相机执行自动对焦
{
    Vuforia::CameraDevice::getInstance().setFocusMode(Vuforia::CameraDevice::FOCUS_MODE_TRIGGERAUTO);//setFocusMode 设置对焦模式  FOCUS_MODE_TRIGGERAUTO触发一个自动对焦
    
    // After triggering an autofocus event, 一个事件触发后自动对焦
    // we must restore the previous focus mode我们必须恢复以前的对焦模式
    if (continuousAutofocusEnabled)//连续自动对焦功能
    {
        [self performSelector:@selector(restoreContinuousAutoFocus) withObject:nil afterDelay:2.0];//restoreContinuousAutoFocus恢复的连续自动对焦
    }
}
#warning 对焦之后2秒以后恢复自动对焦模式
- (void)restoreContinuousAutoFocus//恢复连续自动对焦2秒后要执行的方法
{
    NSLog(@"对焦之后2秒以后恢复自动对焦模式");
    Vuforia::CameraDevice::getInstance().setFocusMode(Vuforia::CameraDevice::FOCUS_MODE_CONTINUOUSAUTO);//setFocusMode 设置对焦模式  FOCUS_MODE_TRIGGERAUTO触发一个自动对焦
}
//双点击手势动作
- (void)doubleTapGestureAction:(UITapGestureRecognizer*)theGesture
{
    if (!self.showingMenu) {//显示的菜单
        [self performSegueWithIdentifier: @"PresentMenu" sender: self];//PresentMenu目前的菜单
    }
}
//滑动手势动作
- (void)swipeGestureAction:(UISwipeGestureRecognizer*)gesture
{
    if (!self.showingMenu) {//显示的菜单
        [self performSegueWithIdentifier:@"PresentMenu" sender:self];//PresentMenu目前的菜单
    }
}


#pragma mark - menu delegate protocol implementation菜单委托协议实现
//双击以后要出现的东西列表
- (BOOL) menuProcess:(NSString *)itemName value:(BOOL)value//menuProcess菜单的过程
{
    NSError * error = nil;
    if ([@"Flash" isEqualToString:itemName]) {
        bool result = Vuforia::CameraDevice::getInstance().setFlashTorchMode(value);
        flashEnabled = value && result;
        return result;
    }
    else if ([@"Extended Tracking" isEqualToString:itemName]) {
        //Extended Tracking 扩展目标跟踪
        bool result = [self setExtendedTrackingForDataSet:dataSetCurrent start:value];//setExtendedTrackingForDataSet设置扩展跟踪数据  dataSetCurrent当前数据集
        if (result) {
            [eaglView setOffTargetTrackingMode:value];//设置目标跟踪模式
        }
        extendedTrackingEnabled = value && result;//启用扩展跟踪
        return result;
    }
    else if ([@"Autofocus" isEqualToString:itemName]) {
        int focusMode = value ? Vuforia::CameraDevice::FOCUS_MODE_CONTINUOUSAUTO : Vuforia::CameraDevice::FOCUS_MODE_NORMAL;
        bool result = Vuforia::CameraDevice::getInstance().setFocusMode(focusMode);
        continuousAutofocusEnabled = value && result;
        return result;
    }
    else if ([@"Front" isEqualToString:itemName]) {
        if ([vapp stopCamera:&error]) {
            bool result = [vapp startAR:Vuforia::CameraDevice::CAMERA_DIRECTION_FRONT error:&error];
            frontCameraEnabled = result;
            [eaglView updateRenderingPrimitives];
            if (frontCameraEnabled) {
                // Switch Flash toggle OFF, in case it was previously ON,
                // as the front camera does not support flash
                flashEnabled = NO;
            }
            return result;
        } else {
            return false;
        }
    }
    else if ([@"Rear" isEqualToString:itemName]) {
        if ([vapp stopCamera:&error]) {
            bool result = [vapp startAR:Vuforia::CameraDevice::CAMERA_DIRECTION_BACK error:&error];
            frontCameraEnabled = !result;
            [eaglView updateRenderingPrimitives];
            return result;
        } else {
            return false;
        }
    }
    else if ([@"Tarmac" isEqualToString:itemName]) {
        [self setExtendedTrackingForDataSet:dataSetCurrent start:NO];
        switchToTarmac = YES;
        switchToStonesAndChips = NO;
        return true;
    }
    else if ([@"Stones & Chips" isEqualToString:itemName]) {
        [self setExtendedTrackingForDataSet:dataSetCurrent start:NO];
        switchToTarmac = NO;
        switchToStonesAndChips = YES;
        return true;
    }

    return false;
}
#warning 菜单返回2222202
- (void) menuDidExit//菜单并退出
{
    self.showingMenu = NO;//显示菜单
}


#pragma mark - Navigation  导航
#warning 双击屏幕显示菜单2222201
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue isKindOfClass:[PresentMenuSegue class]]) {
        UIViewController *dest = [segue destinationViewController];
        if ([dest isKindOfClass:[SampleAppMenuViewController class]]) {
            //App菜单控制器
            self.showingMenu = YES;//显示菜单
            
            SampleAppMenuViewController *menuVC = (SampleAppMenuViewController *)dest;
            menuVC.menuDelegate = self;
            menuVC.sampleAppFeatureName = @"Image Targets001";//功能名称
            menuVC.dismissItemName = @"Vuforia Samples";
            menuVC.backSegueId = @"BackToImageTargets";
            
            NSLog(@"Dataset current %@", dataSetCurrent == dataSetTarmac ? @"Tarmac" : @"Stones & Chips");

            // initialize menu item values (ON / OFF)初始化菜单项值（开/关）
            [menuVC setValue:extendedTrackingEnabled forMenuItem:@"Extended Tracking"];
            [menuVC setValue:continuousAutofocusEnabled forMenuItem:@"Autofocus"];
            [menuVC setValue:flashEnabled forMenuItem:@"Flash"];
            [menuVC setValue:frontCameraEnabled forMenuItem:@"Front"];
            [menuVC setValue:!frontCameraEnabled forMenuItem:@"Rear"];
            if (dataSetCurrent == dataSetStonesAndChips) {
                [menuVC setValue:YES forMenuItem:@"Stones & Chips"];
                [menuVC setValue:NO forMenuItem:@"Tarmac"];
            }
            else {
                [menuVC setValue:YES forMenuItem:@"Tarmac"];
                [menuVC setValue:NO forMenuItem:@"Stones & Chips"];
            }
        }
    }
}

@end
