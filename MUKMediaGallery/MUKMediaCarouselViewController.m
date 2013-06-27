#import "MUKMediaCarouselViewController.h"

@interface MUKMediaCarouselViewController ()

@end

@implementation MUKMediaCarouselViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        CommonInitialization(self, [[self class] newCarouselLayout]);
    }
    
    return self;
}

- (id)initWithCollectionViewLayout:(UICollectionViewLayout *)layout {
    layout = [[self class] newCarouselLayout];
    self = [super initWithCollectionViewLayout:layout];
    if (self) {
        CommonInitialization(self, nil);
    }
    
    return self;
}

- (id)init {
    return [self initWithCollectionViewLayout:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.collectionView.backgroundColor = [UIColor blackColor];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Private

static void CommonInitialization(MUKMediaCarouselViewController *viewController, UICollectionViewLayout *layout)
{
    // TODO
    
    if (layout) {
        viewController.collectionView.collectionViewLayout = layout;
    }
}

#pragma mark - Private — Layout

+ (UICollectionViewLayout *)newCarouselLayout {
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    // TODO
    return layout;
}

@end
