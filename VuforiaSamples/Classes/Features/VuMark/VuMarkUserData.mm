/*===============================================================================
 Copyright (c) 2016 PTC Inc. All Rights Reserved.
 
 Copyright (c) 2012-2015 Qualcomm Connected Experiences, Inc. All Rights Reserved.
 
 Vuforia is a trademark of PTC Inc., registered in the United States and other
 countries.
 ===============================================================================*/
#import "VuMarkUserData.h"
#define NANOSVG_IMPLEMENTATION 1//nanosvg的实施
#import "nanosvg.h"
#import "SampleApplicationUtils.h"

@interface UserDataPoint : NSObject  //用户数据点
@property (nonatomic, readwrite) CGFloat x;
@property (nonatomic, readwrite) CGFloat y;
@end

@implementation UserDataPoint ///用户数据点
@end


@interface UserDataSegment : NSObject   //用户数据段
@property (nonatomic, readwrite) UserDataPoint * p0;//用户数据点p0
@property (nonatomic, readwrite) UserDataPoint * p1;//用户数据点p1
@property (nonatomic, readwrite) UserDataPoint * center;//用户数据点 中心center
@property (nonatomic, readwrite) CGFloat angle;//角度
@property (nonatomic, readwrite) CGFloat length;//长度

- (void) prepare;//准备工作
@end

@implementation UserDataSegment //用户数据段

- (void) prepare {//准备工作（相当于初始化）
    UserDataPoint * center = [[UserDataPoint alloc]init];
    center.x = (self.p1.x + self.p0.x) / 2;
    center.y = (self.p1.y + self.p0.y) / 2;
    self.center = center;//用户数据点中心数据初始化计算
    
    self.angle = atan2f(self.p1.y - self.p0.y, self.p1.x - self.p0.x);
    self.angle = self.angle / M_PI * 180.0;//角度的计算
    
    CGFloat xDist = (self.p1.x - self.p0.x);
    CGFloat yDist = (self.p1.y - self.p0.y);
    self.length= sqrt((xDist * xDist) + (yDist * yDist));//长度
    
//    self.length = hypotf(self.p1.x - self.p0.x, self.p1.y - self.p0.y);
}

@end


@interface VuMarkUserData ()//VnMark用户数据

@property (nonatomic, readwrite) NSMutableArray * segments;//用户数据段数组

@end


@implementation VuMarkUserData //VnMark用户数据

//初始化用户数据
- (id)initWithUserData:(const char *) userData vuMarkSize:(CGSize) size {
    self = [super init];
    
    NSLog(@"userData:用户数据67VUD%s\n", userData);
    /*
     <?xml version='1.0' encoding='UTF-8'?>
     <svg xmlns="http://www.w3.org/2000/svg" style="enable-background:new 0 0 115.571 55.79;" version="1.1" viewBox="0 0 115.571 55.79" x="0px" y="0px" xml:space="preserve">
     <g id="VuMark-UserData">
     <polygon points="98.092,27.78 112.062,52.29    3.512,52.29 17.483,27.78 3.502,3.5 112.072,3.5  " style="fill:none;stroke:#EF4136;stroke-width:0.2;stroke-miterlimit:10;" />
     </g>
     </svg>
     */
    
    if (self) {
        _segments = [[NSMutableArray alloc]init];
        
        NSVGimage * image;//svg的图片
        NSVGshape* shape;//svg的形状
        NSVGpath* path;//svg的路径
        
        image = nsvgParse((char *)userData, "px", 96);// Parse解析
        NSLog(@"size大小svgInage的宽与高85VUD: %f x %f\n", image->width, image->height);
        //size: 115.570999 x 55.790001
        
        for (shape = image->shapes; shape != NULL; shape = shape->next) {
            //shape 形状等于Image形状  且形状不等于空   shape->next，如果最后一个元素为null那么指向下一个形状的指针
            for (path = shape->paths; path != NULL; path = path->next) {
                //shape->paths图像中路径的链接列表。 且路径不为空 如果最后一个元素为null那么指向下一个形状的指针
                for (int i = 0; i < path->npts  - 1; i += 3) {
                    //npts贝塞尔点总数
                    float* p = &path->pts[i*2];
                    // NSLog(@"(%d) p[%d] %7.2f, %7.2f, %7.2f, %7.2f, %7.2f, %7.2f, %7.2f, %7.2f",path->closed, i, p[0],p[1], p[2],p[3], p[4],p[5], p[6],p[7]);
                    
                    UserDataPoint * p0 = [self mkUserDataPointWithP0:p[0] P1:p[1] inImage:image vuMarkSize:size];//用户数据点po的数值
                    UserDataPoint * p1 = [self mkUserDataPointWithP0:p[6] P1:p[7] inImage:image vuMarkSize:size];//用户数据点p1的数值

                    UserDataSegment * segment = [[UserDataSegment alloc]init];//用户数据段
                    segment.p0 = p0;
                    segment.p1 = p1;
                    [segment prepare];//调此方法之后每个segment里面的p0 p1 center length就会有值
                    [_segments addObject:segment];//再将每一个segment存到数组-segments中
                }
            }
        }
        nsvgDelete(image);//完事后删除，初始化完成
    }
    return self;
}

- (UserDataPoint *) mkUserDataPointWithP0:(float) p0 P1:(float) p1 inImage:(NSVGimage *) image vuMarkSize:(CGSize) size{//mkUserDataPointWithP0 P0用户数据点
    float x = p0 - (image->width / 2.0);
    float y = (image->height /2.0)- p1;
    
    UserDataPoint * point = [[UserDataPoint alloc]init];
    point.x = (x / image->width) * size.width;
    point.y = (y / image->height) * size.height;
    
    return point;//掉此方法可以获取到point的两个点
}

- (NSUInteger) nbSegments {
    return [_segments count];
}

// we build the model view matric for the segment (streched square)
//我们建立的模型视图矩阵的段（拉伸平方）

- (void) modelViewMatrix:(Vuforia::Matrix44F &) modelViewMatrix forSegmentIdx:(int) idx width:(float) width{//模型视图矩阵 forSegmentIdx编号
    
    UserDataSegment * segment = (UserDataSegment *)[_segments objectAtIndex:idx];//根据编号去取模型在数组-segments
    
    UserDataPoint * point = segment.center;
    
    SampleApplicationUtils::translatePoseMatrix(point.x, point.y, 0.0,
                                                &modelViewMatrix.data[0]);//ApplicationUtils App定位工具  translatePoseMatrix翻译姿态矩阵
    
    SampleApplicationUtils::rotatePoseMatrix(segment.angle, 0.0, 0.0, 1.0,
                                             &modelViewMatrix.data[0]);//rotatePoseMatrix旋转(角度)姿态矩阵
    
    SampleApplicationUtils::scalePoseMatrix(segment.length, width, width,
                         &modelViewMatrix.data[0]);//scalePoseMatrix规模（长度）的位姿矩阵
}

// we build the model view matrix for the starting point of the segment (sphere)
//我们建立模型视图矩阵的起点段（球）
- (void) modelViewMatrix:(Vuforia::Matrix44F &) modelViewMatrix forSegmentStart:(int) idx width:(float) width{//modelViewMatrix 模型视图矩阵  forSegmentStart 段的开始
    UserDataSegment * segment = (UserDataSegment *)[_segments objectAtIndex:idx];
    UserDataPoint * point = segment.p0;
    
    SampleApplicationUtils::translatePoseMatrix(point.x, point.y, 0.0,
                                                &modelViewMatrix.data[0]);//translatePoseMatrix翻译姿态矩阵
    SampleApplicationUtils::scalePoseMatrix(width, width, width,
                                            &modelViewMatrix.data[0]);//scalePoseMatrix规模（长度）的位姿矩阵
    
}

@end


