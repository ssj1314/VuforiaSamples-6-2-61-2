/*===============================================================================
 Copyright (c) 2016 PTC Inc. All Rights Reserved.
 
 Copyright (c) 2012-2015 Qualcomm Connected Experiences, Inc. All Rights Reserved.
 
 Vuforia is a trademark of PTC Inc., registered in the United States and other
 countries.

 ===============================================================================*/
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Vuforia/Vuforia.h>
#import <Vuforia/Matrices.h>
//VuMark用户数据
@interface VuMarkUserData : NSObject
//用户数据初始化  vuMarkSize vumark尺寸
- (id)initWithUserData:(const char *) userData vuMarkSize:(CGSize) size;

- (NSUInteger) nbSegments;//nb分段

//modelViewMatrix模型视图矩阵   Matrix44F 4X4矩阵  modelViewMatrix 模型视图矩阵 forSegmentIdx 分段ID width 宽度
- (void) modelViewMatrix:(Vuforia::Matrix44F&) modelViewMatrix forSegmentIdx:(int) idx width:(float) width;


//modelViewMatrix模型视图矩阵   Matrix44F 4X4矩阵  modelViewMatrix 模型视图矩阵 forSegmentStart分段的开始 width 宽度
- (void) modelViewMatrix:(Vuforia::Matrix44F &) modelViewMatrix forSegmentStart:(int) idx width:(float) width;

@end
