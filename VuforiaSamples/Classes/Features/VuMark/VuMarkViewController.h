/*===============================================================================
Copyright (c) 2016 PTC Inc. All Rights Reserved.

Copyright (c) 2012-2015 Qualcomm Connected Experiences, Inc. All Rights Reserved.

Vuforia is a trademark of PTC Inc., registered in the United States and other 
countries.
===============================================================================*/

#import <UIKit/UIKit.h>
#import "VuMarkEAGLView.h"
#import "SampleApplicationSession.h"
#import "SampleAppMenuViewController.h"
#import <Vuforia/DataSet.h>

@interface VuMarkViewController : UIViewController <SampleApplicationControl, SampleAppMenuDelegate> {
    
    Vuforia::DataSet*  dataSetCurrent;//当前数据集
    Vuforia::DataSet*  dataSetLoaded;//加载数据集
    
    // menu options菜单选项
    BOOL extendedTrackingEnabled;//跟踪功能的扩展
    BOOL continuousAutofocusEnabled;//连续自动对焦功能
    BOOL frontCameraEnabled;//前置摄像头功能
}

@property (nonatomic, strong) VuMarkEAGLView* eaglView;
@property (nonatomic, strong) UITapGestureRecognizer * tapGestureRecognizer;//点击手势识别器
@property (nonatomic, strong) SampleApplicationSession * vapp;

@property (nonatomic, readwrite) BOOL showingMenu;//显示菜单

@end
