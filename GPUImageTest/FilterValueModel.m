

#import "FilterValueModel.h"

@implementation FilterValueModel

- (instancetype)init {
    self = [super init];
    if (self) {
        _filterIndex = 0;
        _brightness = 0.0;
        _contrast = 1.0;
        _sharpness = 0.0;
        _saturation = 1.0;
        _tint = 0.0;
    }
    
    return self;
}

@end
