
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, FilterType) {
    FilterTypeBrightness   = 0,  // 亮度
    FilterTypeContrast     = 1,  // 对比度
    FilterTypeSharpen      = 2,  // 锐化
    FilterTypeSaturation   = 3,  // 饱和度
    FilterTypeWhiteBalance = 4,  // 色温
    FilterTypeIndex        = 5   // 滤镜索引
};

@interface FilterViewController : UIViewController

// 图片数组
@property(nonatomic, strong) NSMutableArray *imageArray;

// 滤镜参数数组
@property (nonatomic, strong) NSMutableArray *filterValueArray;

// 当前照片的索引
@property (nonatomic, assign) NSInteger imageIndex;

@end
