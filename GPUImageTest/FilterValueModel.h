
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface FilterValueModel : NSObject

@property (nonatomic, assign) NSInteger filterIndex; // 滤镜的索引
@property (nonatomic, assign) CGFloat brightness; // 亮度
@property (nonatomic, assign) CGFloat contrast; // 对比度
@property (nonatomic, assign) CGFloat sharpness; // 锐化
@property (nonatomic, assign) CGFloat saturation; // 饱和度
@property (nonatomic, assign) CGFloat tint; // 色温

@end
