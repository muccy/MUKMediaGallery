#import "MUKMediaCarouselFlowLayout.h"

@implementation MUKMediaCarouselFlowLayout

- (id)init {
    self = [super init];
    if (self) {
        self.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    }
    
    return self;
}

#pragma mark - Overrides

// I need this method because standard UIScrollView pagination is buggy: when
// a photo is zoomed, sometimes it snaps to a wrong location (bouncing back).
// Setting target manually both resolves this problem and simplify the process
// of putting gaps between pages
- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset withScrollingVelocity:(CGPoint)velocity
{
    CGPoint targetOffset = [super targetContentOffsetForProposedContentOffset:proposedContentOffset withScrollingVelocity:velocity];
    
    CGFloat pageWidth = self.collectionView.frame.size.width + self.minimumLineSpacing;
    NSInteger minPage = self.collectionView.contentOffset.x/pageWidth;

    NSInteger targetPage;
    
    // Slow dragging not lifting finger
    if (velocity.x == 0.0f) {
        CGFloat normalizedCurrentXOffset = fmodf(self.collectionView.contentOffset.x, pageWidth);
        
        if (normalizedCurrentXOffset > pageWidth/2.0f) {
            // Go to next page
            targetPage = minPage + 1;
        }
        else {
            // Stay to current page
            targetPage = minPage;
        }
    }
    
    // Fast dragging
    else {        
        // Going back
        if (velocity.x < 0.0f) {
            targetPage = minPage;
        }
        
        // Going forward
        else {
            targetPage = minPage + 1;
        }
    }
    
    CGFloat targetX = pageWidth * targetPage;
    if (targetX < 0.0f) {
        targetX = 0.0f;
    }
    else if (targetX > self.collectionViewContentSize.width)
    {
        targetX = self.collectionViewContentSize.width - self.collectionView.frame.size.width;
    }
    
    targetOffset.x = targetX;
    return targetOffset;
}

@end
