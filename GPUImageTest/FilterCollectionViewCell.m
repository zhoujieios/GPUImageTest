
#import "FilterCollectionViewCell.h"

@implementation FilterCollectionViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.filterImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.filterImageView.clipsToBounds = YES;
}

@end
