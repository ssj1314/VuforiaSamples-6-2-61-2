/*===============================================================================
Copyright (c) 2016 PTC Inc. All Rights Reserved.

Copyright (c) 2012-2015 Qualcomm Connected Experiences, Inc. All Rights Reserved.

Vuforia is a trademark of PTC Inc., registered in the United States and other 
countries.
===============================================================================*/

#import <UIKit/UIKit.h>
#import "ImageTargetsEAGLView.h"
#import "SampleApplicationSession.h"
#import "SampleAppMenuViewController.h"
#import <Vuforia/DataSet.h>

@interface ImageTargetsViewController : UIViewController <SampleApplicationControl, SampleAppMenuDelegate> {
    
    Vuforia::DataSet*  dataSetCurrent;//当前数据集
    Vuforia::DataSet*  dataSetTarmac;//数据集上
    Vuforia::DataSet*  dataSetStonesAndChips;//数据集石头和芯片
    
    BOOL switchToTarmac;//切换到停机坪
    BOOL switchToStonesAndChips;//切换到石头和芯片
    
    // menu options菜单选项
    BOOL extendedTrackingEnabled;//跟踪功能的扩展
    BOOL continuousAutofocusEnabled;//连续自动对焦功能
    BOOL flashEnabled;//闪光灯启用
    BOOL frontCameraEnabled;//前置摄像头功能
}

@property (nonatomic, strong) ImageTargetsEAGLView* eaglView;
@property (nonatomic, strong) UITapGestureRecognizer * tapGestureRecognizer;//点击手势识别器
@property (nonatomic, strong) SampleApplicationSession * vapp;

@property (nonatomic, readwrite) BOOL showingMenu;//显示菜单
//qiankakefu480037

@end
