
#import "FilterViewController.h"
#import "GPUImage.h"
#import "FilterValueModel.h"
#import "FilterCollectionViewCell.h"

const CGFloat inset_space = 15;

#define kFilterViewHeight (kWidth*1.6/5.0)
#define kScrollViewHeight (kHeight - 64 - 45 - kFilterViewHeight)
#define kFilterCellPadding 10
#define kFilterCellWith (kFilterCellHeight - 30)
#define kFilterCellHeight (kFilterViewHeight - 2*kFilterCellPadding)

#define kWidth   [UIScreen mainScreen].bounds.size.width
#define kHeight  [UIScreen mainScreen].bounds.size.height
#define kRGBColor(r,g,b) [UIColor colorWithRed:(r)/255.0f green:(g)/255.0f blue:(b)/255.0f alpha:1]

#define kFilterName @[@"原图", @"阳光", @"幽暗", @"灰白", @"怀旧"]

@interface FilterViewController () <UIScrollViewDelegate,UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (weak, nonatomic) IBOutlet UIView *buttomSegmentView;
@property (strong, nonatomic) UIView *redLineView;
@property (weak, nonatomic) IBOutlet UIButton *filterButton;
@property (weak, nonatomic) IBOutlet UIButton *beautifierButton;
@property (weak, nonatomic) IBOutlet UISlider *slider;
@property (weak, nonatomic) IBOutlet UIImageView *imageView1;
@property (weak, nonatomic) IBOutlet UILabel *label1;
@property (weak, nonatomic) IBOutlet UIImageView *imageView2;
@property (weak, nonatomic) IBOutlet UILabel *label2;
@property (weak, nonatomic) IBOutlet UIImageView *imageView3;
@property (weak, nonatomic) IBOutlet UILabel *label3;
@property (weak, nonatomic) IBOutlet UIImageView *imageView4;
@property (weak, nonatomic) IBOutlet UILabel *label4;
@property (weak, nonatomic) IBOutlet UIImageView *imageView5;
@property (weak, nonatomic) IBOutlet UILabel *label5;
@property (weak, nonatomic) IBOutlet UIView *fiterView;
@property (weak, nonatomic) IBOutlet UIView *beautifierView;

// 显示图片的view
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, assign) NSInteger beautifierIndex; // 美化所选择的索引

@property (nonatomic, strong) GPUImagePicture *stillImageSource;

@property (nonatomic, strong) GPUImageHazeFilter *hazeFilterBrighter; // 滤镜 —— 阳光
@property (nonatomic, strong) GPUImageHazeFilter *hazeFilterDarker; // 滤镜 —— 幽暗
@property (nonatomic, strong) GPUImageGrayscaleFilter *grayFilter; // 滤镜 —— 灰白
@property (nonatomic, strong) GPUImageSepiaFilter *sepiaFilter; // 滤镜 —— 怀旧

@property (nonatomic,strong) GPUImageFilterGroup    *filterGroup;     // 美化组合组合
@property (nonatomic, strong) GPUImageBrightnessFilter *brightnessFilter; // 亮度
@property (nonatomic, strong) GPUImageContrastFilter *contrastFilter;     // 对比度
@property (nonatomic, strong) GPUImageSharpenFilter *sharpenFilter;       // 锐度
@property (nonatomic, strong) GPUImageSaturationFilter *saturationFilter; // 饱和度
@property (nonatomic, strong) GPUImageWhiteBalanceFilter *whiteBalanceFilter; // 色温

@property (nonatomic, strong) NSMutableArray *imageViewArray; // 浏览图片的imageview数组
@property (nonatomic, strong) NSMutableArray *pictureArray; // GPUImagePicture数组
@property (nonatomic, strong) NSMutableArray *filteredArray; // 滤镜处理的数组
@property (weak, nonatomic) IBOutlet UICollectionView *filterCollectionView;

@end

@implementation FilterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configureUI];
    [self setTitle];
    [self initFilters];
    
    self.scrollView.contentOffset = CGPointMake(self.imageIndex * kWidth, 0);
    [self refreshAfterIndexChange];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(editPhoto:) name:@"editPhoto" object:nil];
}

- (NSMutableArray *)imageArray {
    if (!_imageArray) {
        _imageArray = [[NSMutableArray alloc] init];
    }
    
    return _imageArray;
}

- (NSMutableArray *)filterValueArray {
    if (!_filterValueArray) {
        _filterValueArray = [[NSMutableArray alloc] init];
    }
    
    return _filterValueArray;
}


- (void)setTitle {
    self.navigationItem.title = [NSString stringWithFormat:@"编辑(%ld/%ld)",self.imageIndex+1, self.imageArray.count];
}

- (void)initFilters {
    self.hazeFilterBrighter = [[GPUImageHazeFilter alloc] init];
    self.hazeFilterBrighter.distance = -0.3;
    self.hazeFilterDarker = [[GPUImageHazeFilter alloc] init];
    self.hazeFilterDarker.distance = 0.3;
    self.grayFilter = [[GPUImageGrayscaleFilter alloc] init];
    self.sepiaFilter = [[GPUImageSepiaFilter alloc] init];
    
    self.filterGroup = [[GPUImageFilterGroup alloc] init];
    self.brightnessFilter = [[GPUImageBrightnessFilter alloc] init];
    self.contrastFilter = [[GPUImageContrastFilter alloc] init];
    self.sharpenFilter = [[GPUImageSharpenFilter alloc] init];
    self.saturationFilter = [[GPUImageSaturationFilter alloc] init];
    self.whiteBalanceFilter = [[GPUImageWhiteBalanceFilter alloc] init];
    
    [self addGPUImageFilter:self.brightnessFilter];
    [self addGPUImageFilter:self.contrastFilter];
    [self addGPUImageFilter:self.sharpenFilter];
    [self addGPUImageFilter:self.saturationFilter];
    [self addGPUImageFilter:self.whiteBalanceFilter];
    for (int i = 0; i < self.pictureArray.count; i++) {
        GPUImagePicture *pic = self.pictureArray[i];
        //[pic addTarget:self.filterGroup];
        [pic addTarget:self.hazeFilterBrighter];
        [pic addTarget:self.hazeFilterDarker];
        [pic addTarget:self.grayFilter];
        [pic addTarget:self.sepiaFilter];
    }
    
    [self loadCollectionView];
    [self button5Action:nil];
}

- (void)loadCollectionView {
    [self.filteredArray removeAllObjects];
    [self.filteredArray addObject:self.imageArray[self.imageIndex]];

    GPUImagePicture *pic = self.pictureArray[self.imageIndex];
    [pic processImage];

    [self.hazeFilterBrighter useNextFrameForImageCapture];
    [self.hazeFilterDarker useNextFrameForImageCapture];
    [self.grayFilter useNextFrameForImageCapture];
    [self.sepiaFilter useNextFrameForImageCapture];

    [self.filteredArray addObject:[self.hazeFilterBrighter imageFromCurrentFramebuffer]];
    [self.filteredArray addObject:[self.hazeFilterDarker imageFromCurrentFramebuffer]];
    [self.filteredArray addObject:[self.grayFilter imageFromCurrentFramebuffer]];
    [self.filteredArray addObject:[self.sepiaFilter imageFromCurrentFramebuffer]];
    
    FilterValueModel *model = self.filterValueArray[self.imageIndex];
    UIImageView *imageView = self.imageViewArray[self.imageIndex];
    imageView.image = self.filteredArray[model.filterIndex];
}

- (void)addGPUImageFilter:(GPUImageOutput<GPUImageInput> *)filter {
    [self.filterGroup addFilter:filter];
    
    GPUImageOutput<GPUImageInput> *newTerminalFilter = filter;
    
    NSInteger count = self.filterGroup.filterCount;
    
    if (count == 1)
    {
        self.filterGroup.initialFilters = @[newTerminalFilter];
        self.filterGroup.terminalFilter = newTerminalFilter;
        
    } else
    {
        GPUImageOutput<GPUImageInput> *terminalFilter    = self.filterGroup.terminalFilter;
        NSArray *initialFilters                          = self.filterGroup.initialFilters;
        
        [terminalFilter addTarget:newTerminalFilter];
        
        self.filterGroup.initialFilters = @[initialFilters[0]];
        self.filterGroup.terminalFilter = newTerminalFilter;
    }
}

- (void)configureUI {
    self.automaticallyAdjustsScrollViewInsets = NO;
    [self.buttomSegmentView addSubview:self.redLineView];
    [self.slider setThumbImage:[UIImage imageNamed:@"sliderbutton"] forState:UIControlStateNormal];
    
    self.fiterView.hidden = NO;
    self.beautifierView.hidden = YES;
    
    [self.view addSubview:self.scrollView];
    
    [self loadImageArray];
    [self configCollectionView];
}

- (void)configCollectionView {
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    self.filterCollectionView.collectionViewLayout = layout;
    self.filterCollectionView.backgroundColor = [UIColor whiteColor];
    self.filterCollectionView.scrollEnabled = YES;
    self.filterCollectionView.showsVerticalScrollIndicator = NO;
    self.filterCollectionView.showsHorizontalScrollIndicator = NO;
    [self.filterCollectionView registerNib:[UINib nibWithNibName:@"FilterCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:@"FilterCollectionViewCell"];
}

- (UIScrollView *)scrollView {
    if (!_scrollView) {
        _scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 64, kWidth, kScrollViewHeight)];
        _scrollView.pagingEnabled = YES;
        _scrollView.userInteractionEnabled = YES;
        _scrollView.showsHorizontalScrollIndicator = NO;
        
        _scrollView.contentSize = CGSizeMake(self.imageArray.count*kWidth, kScrollViewHeight);
        _scrollView.delegate = self;
        _scrollView.contentOffset = CGPointMake(0, 0);
    }
    
    return _scrollView;
}

- (NSMutableArray *)imageViewArray {
    if (!_imageViewArray) {
        _imageViewArray = [[NSMutableArray alloc] init];
    }
    
    return _imageViewArray;
}

- (NSMutableArray *)pictureArray {
    if (!_pictureArray) {
        _pictureArray = [[NSMutableArray alloc] init];
    }
    
    return _pictureArray;
}

- (NSMutableArray *)filteredArray {
    if (!_filteredArray) {
        _filteredArray = [[NSMutableArray alloc] init];
    }
    
    return _filteredArray;
}

- (void)loadImageArray{
    for (int i = 0; i < self.imageArray.count; i++) {
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(i*kWidth, 0, kWidth, kScrollViewHeight)];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView.backgroundColor = kRGBColor(238, 238, 238);
        imageView.image = self.imageArray[i];
        [self.scrollView addSubview:imageView];
        [self.imageViewArray addObject:imageView];
        
        GPUImagePicture *pic = [[GPUImagePicture alloc] initWithImage:self.imageArray[i]];
        [self.pictureArray addObject:pic];
    }
}

- (UIView *)redLineView {
    if (!_redLineView) {
        _redLineView = [[UIView alloc] initWithFrame:CGRectMake(0, 42, kWidth/2, 2)];
        _redLineView.backgroundColor = [UIColor redColor];
    }
    
    return _redLineView;
}


- (IBAction)filterButtonAction:(id)sender {
    [self.filterButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [self.beautifierButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    
    [UIView animateWithDuration:0.3 animations:^{
        self.redLineView.frame = CGRectMake(0, 42, kWidth/2, 2);
    }];
    
    self.fiterView.hidden = NO;
    self.beautifierView.hidden = YES;
}

- (IBAction)beautifierButtonAction:(id)sender {
    [self.filterButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.beautifierButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [UIView animateWithDuration:0.3 animations:^{
        self.redLineView.frame = CGRectMake(kWidth/2, 42, kWidth/2, 2);
    }];
    
    self.fiterView.hidden = YES;
    self.beautifierView.hidden = NO;
}

- (IBAction)button1Action:(id)sender {
    self.label1.textColor = [UIColor redColor];
    self.label2.textColor = [UIColor blackColor];
    self.label3.textColor = [UIColor blackColor];
    self.label4.textColor = [UIColor blackColor];
    self.label5.textColor = [UIColor blackColor];
    
    self.imageView1.image = [UIImage imageNamed:@"brightnessHilighted"];
    self.imageView2.image = [UIImage imageNamed:@"contrast"];
    self.imageView3.image = [UIImage imageNamed:@"sharp"];
    self.imageView4.image = [UIImage imageNamed:@"saturation"];
    self.imageView5.image = [UIImage imageNamed:@"whiteBalance"];
    
    self.beautifierIndex = 0;
    [self setSliderRange:FilterTypeBrightness];
    self.slider.value = [self getCurrentValue:FilterTypeBrightness];
    self.brightnessFilter.brightness = [self getCurrentValue:FilterTypeBrightness];
}

- (IBAction)button2Action:(id)sender {
    self.label1.textColor = [UIColor blackColor];
    self.label2.textColor = [UIColor redColor];
    self.label3.textColor = [UIColor blackColor];
    self.label4.textColor = [UIColor blackColor];
    self.label5.textColor = [UIColor blackColor];
    
    self.imageView1.image = [UIImage imageNamed:@"brightness"];
    self.imageView2.image = [UIImage imageNamed:@"contrastHilighted"];
    self.imageView3.image = [UIImage imageNamed:@"sharp"];
    self.imageView4.image = [UIImage imageNamed:@"saturation"];
    self.imageView5.image = [UIImage imageNamed:@"whiteBalance"];
    
    self.beautifierIndex = 1;
    [self setSliderRange:FilterTypeContrast];
    self.slider.value = [self getCurrentValue:FilterTypeContrast];
    self.contrastFilter.contrast = [self getCurrentValue:FilterTypeContrast];
}

- (IBAction)button3Action:(id)sender {
    self.label1.textColor = [UIColor blackColor];
    self.label2.textColor = [UIColor blackColor];
    self.label3.textColor = [UIColor redColor];
    self.label4.textColor = [UIColor blackColor];
    self.label5.textColor = [UIColor blackColor];
    
    self.imageView1.image = [UIImage imageNamed:@"brightness"];
    self.imageView2.image = [UIImage imageNamed:@"contrast"];
    self.imageView3.image = [UIImage imageNamed:@"sharpHilighted"];
    self.imageView4.image = [UIImage imageNamed:@"saturation"];
    self.imageView5.image = [UIImage imageNamed:@"whiteBalance"];
    
    self.beautifierIndex = 2;
    [self setSliderRange:FilterTypeSharpen];
    self.slider.value = [self getCurrentValue:FilterTypeSharpen];
    self.sharpenFilter.sharpness = [self getCurrentValue:FilterTypeContrast];
}

- (IBAction)button4Action:(id)sender {
    self.label1.textColor = [UIColor blackColor];
    self.label2.textColor = [UIColor blackColor];
    self.label3.textColor = [UIColor blackColor];
    self.label4.textColor = [UIColor redColor];
    self.label5.textColor = [UIColor blackColor];
    
    self.imageView1.image = [UIImage imageNamed:@"brightness"];
    self.imageView2.image = [UIImage imageNamed:@"contrast"];
    self.imageView3.image = [UIImage imageNamed:@"sharp"];
    self.imageView4.image = [UIImage imageNamed:@"saturationHilighted"];
    self.imageView5.image = [UIImage imageNamed:@"whiteBalance"];
    
    self.beautifierIndex = 3;
    [self setSliderRange:FilterTypeSaturation];
    self.slider.value = [self getCurrentValue:FilterTypeSaturation];
    self.saturationFilter.saturation = [self getCurrentValue:FilterTypeContrast];
}

- (IBAction)button5Action:(id)sender {
    self.label1.textColor = [UIColor blackColor];
    self.label2.textColor = [UIColor blackColor];
    self.label3.textColor = [UIColor blackColor];
    self.label4.textColor = [UIColor blackColor];
    self.label5.textColor = [UIColor redColor];
    
    self.imageView1.image = [UIImage imageNamed:@"brightness"];
    self.imageView2.image = [UIImage imageNamed:@"contrast"];
    self.imageView3.image = [UIImage imageNamed:@"sharp"];
    self.imageView4.image = [UIImage imageNamed:@"saturation"];
    self.imageView5.image = [UIImage imageNamed:@"whiteBalanceHilighted"];
    
    self.beautifierIndex = 4;
    [self setSliderRange:FilterTypeWhiteBalance];
    self.slider.value = [self getCurrentValue:FilterTypeWhiteBalance];
    self.whiteBalanceFilter.tint = [self getCurrentValue:FilterTypeContrast];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (scrollView == self.scrollView) {
        CGFloat x = self.scrollView.contentOffset.x;
        NSInteger index = x / kWidth;
        NSLog(@"index = %ld", index);
        if (self.imageIndex == index) {
            return;
        }
        self.imageIndex = index;
        [self refreshAfterIndexChange];
    }
}

- (IBAction)sliderValueChanged:(id)sender {
    CGFloat newValue = [(UISlider *)sender value];
    switch (self.beautifierIndex) {
        case 0: {
            self.brightnessFilter.brightness = newValue;
            [self setCurrentValue:newValue filterType:FilterTypeBrightness];
            break;
        }
        case 1: {
            self.contrastFilter.contrast = newValue;
            [self setCurrentValue:newValue filterType:FilterTypeContrast];
            break;
        }
        case 2: {
            self.sharpenFilter.sharpness = newValue;
            [self setCurrentValue:newValue filterType:FilterTypeSharpen];
            break;
        }
        case 3: {
            self.saturationFilter.saturation = newValue;
            [self setCurrentValue:newValue filterType:FilterTypeSaturation];
            break;
        }
        case 4: {
            self.whiteBalanceFilter.tint = newValue;
            [self setCurrentValue:newValue filterType:FilterTypeWhiteBalance];
            break;
        }
        default:
            break;
    }
    
    [self processImage];
}

- (void)processImage {
    FilterValueModel *model = self.filterValueArray[self.imageIndex];
    UIImage *filterImage = self.filteredArray[model.filterIndex];
    GPUImagePicture *pic = [[GPUImagePicture alloc]initWithImage:filterImage];
    self.brightnessFilter.brightness = model.brightness;
    self.contrastFilter.contrast = model.contrast;
    self.sharpenFilter.sharpness = model.sharpness;
    self.saturationFilter.saturation = model.saturation;
    self.whiteBalanceFilter.tint = model.tint;
    [pic addTarget:self.filterGroup];
    [pic processImage];
    [self.filterGroup useNextFrameForImageCapture];
    
    UIImageView *imageView = self.imageViewArray[self.imageIndex];
    UIImage *image = [self.filterGroup imageFromCurrentFramebuffer];
    imageView.image = image;
}

- (void)setSliderRange:(FilterType)type {
    switch (type) {
        case FilterTypeBrightness: {
            self.slider.minimumValue = -1.0;
            self.slider.maximumValue = 1.0;
            break;
        }
        case FilterTypeContrast: {
            self.slider.minimumValue = 0.0;
            self.slider.maximumValue = 4.0;
            break;
        }
        case FilterTypeSharpen: {
            self.slider.minimumValue = -4.0;
            self.slider.maximumValue = 4.0;
            break;
        }
        case FilterTypeSaturation: {
            self.slider.minimumValue = 0.0;
            self.slider.maximumValue = 2.0;
            break;
        }
        case FilterTypeWhiteBalance: {
            self.slider.minimumValue = -200.0;
            self.slider.maximumValue = 200.0;
            break;
        }
        default:
            break;
    }
}

- (CGFloat)getCurrentValue:(FilterType)type {
    FilterValueModel *model = self.filterValueArray[self.imageIndex];
    switch (type) {
        case FilterTypeBrightness: {
            return model.brightness;
            break;
        }
        case FilterTypeContrast: {
            return model.contrast;
            break;
        }
        case FilterTypeSharpen: {
            return model.sharpness;
            break;
        }
        case FilterTypeSaturation: {
            return model.saturation;
            break;
        }
        case FilterTypeWhiteBalance: {
            return model.tint;
            break;
        }
        case FilterTypeIndex: {
            return model.filterIndex;
            break;
        }
        default:
            break;
    }
}

- (void)setCurrentValue:(CGFloat)newValue filterType:(FilterType)type {
    FilterValueModel *model = self.filterValueArray[self.imageIndex];
    switch (type) {
        case FilterTypeBrightness: {
            model.brightness = newValue;
            break;
        }
        case FilterTypeContrast: {
            model.contrast = newValue;
            break;
        }
        case FilterTypeSharpen: {
            model.sharpness = newValue;
            break;
        }
        case FilterTypeSaturation: {
            model.saturation = newValue;
            break;
        }
        case FilterTypeWhiteBalance: {
            model.tint = newValue;
            break;
        }
        case FilterTypeIndex: {
            model.filterIndex = (NSInteger)newValue;
            break;
        }
        default:
            break;
    }
}

#pragma mark -
#pragma mark UICollectionViewDataSource
//定义展示的UICollectionViewCell的个数
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.filteredArray.count;
}

//每个UICollectionView展示的内容
-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    static NSString * CellIdentifier = @"FilterCollectionViewCell";
    FilterCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    switch (indexPath.row) {
        case 0:
            cell.filterImageView.image = [UIImage imageNamed:@"filtered_original"];
            break;
        case 1:
            cell.filterImageView.image = [UIImage imageNamed:@"filtered_brighter"];
            break;
        case 2:
            cell.filterImageView.image = [UIImage imageNamed:@"filtered_darker"];
            break;
        case 3:
            cell.filterImageView.image = [UIImage imageNamed:@"filtered_black"];
            break;
        case 4:
            cell.filterImageView.image = [UIImage imageNamed:@"filtered_sepia"];
            break;
            
        default:
            break;
    }
    
    cell.filterLabel.text = kFilterName[indexPath.row];
    FilterValueModel *model = self.filterValueArray[self.imageIndex];
    if (model.filterIndex == indexPath.row) {
        cell.filterImageView.layer.borderColor = kRGBColor(235, 117, 117).CGColor;
        cell.filterImageView.layer.borderWidth = 2.0;
    }else {
        cell.filterImageView.layer.borderWidth = 0;
    }
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    FilterValueModel *model = self.filterValueArray[self.imageIndex];
    // 当前已经选中，不需要再次处理，直接退出
    if (model.filterIndex == indexPath.row) {
        return;
    }
    model.filterIndex = indexPath.row;
    [self.filterCollectionView reloadData];
    [self processImage];
}

#pragma mark -
#pragma mark UICollectionViewDelegateFlowLayout
//定义每个UICollectionView 的大小
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(kFilterCellWith, kFilterCellHeight);
}
//定义每个UICollectionView 的 margin
-(UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(kFilterCellPadding, kFilterCellPadding, kFilterCellPadding, kFilterCellPadding);
}
//返回行间距, 可根据不同分区设置
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section{
    return kFilterCellPadding;
}

//返回列间距, 可根据不同分区设置
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return kFilterCellPadding;
}

- (void)editPhoto:(NSNotification *)sender {
    NSDictionary *dic = sender.userInfo;
    self.imageIndex = [dic[@"photoIndex"] integerValue];
    self.scrollView.contentOffset = CGPointMake(self.imageIndex * kWidth, 0);
    
    [self refreshAfterIndexChange];
}

- (void)refreshAfterIndexChange {
    [self setTitle];
    [self loadCollectionView];
    
    [self filterButtonAction:nil];
    [self button5Action:nil];
    
    [self processImage];
}

- (void)dealloc {
    [[GPUImageContext sharedImageProcessingContext].framebufferCache purgeAllUnassignedFramebuffers];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
