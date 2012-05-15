// Copyright (c) 2012, Marco Muccinelli
// All rights reserved.
// 
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
// * Redistributions of source code must retain the above copyright
// notice, this list of conditions and the following disclaimer.
// * Redistributions in binary form must reproduce the above copyright
// notice, this list of conditions and the following disclaimer in the
// documentation and/or other materials provided with the distribution.
// * Neither the name of the <organization> nor the
// names of its contributors may be used to endorse or promote products
// derived from this software without specific prior written permission.
// 
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
// ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
// DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
// ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import <UIKit/UIKit.h>
#import <MUKMediaGallery/MUKMediaCarouselView.h>

/**
 View controller configured to play nicely with a 
 MUKMediaCarouselView instance.
 
 This view controller is configured to request `fullScreenLayout`.
 */
@interface MUKMediaCarouselViewController : UIViewController
/** @name Properties */
/**
 Carousel view.
 
 It is created in `viewDidLoad` implementation if it is still `nil`.
 */
@property (nonatomic, strong) IBOutlet MUKMediaCarouselView *carouselView;
/**
 Manages status bar and navigation bar transparency automatically.
 
 Default is `YES`.
 */
@property (nonatomic) BOOL managesBarsTransparency;

/** @name Methods */
/**
 Designated initializer.
 
 This initializer is particulary useful if you want to customize
 an automatically loaded carouselView, because completionHandler is
 invoked at bottom of `viewDidLoad` implementation.
 
 @param nibNameOrNil The name of the nib file to associate with the view 
 controller. 
 The nib file name should not contain any leading path information. 
 If you specify nil, the nibName property is set to nil.
 @param nibBundleOrNil The bundle in which to search for the nib file. 
 This method looks for the nib file in the bundle's language-specific 
 project directories first, followed by the Resources directory. 
 If nil, this method looks for the nib file in the main bundle.
 @param completionHandler Completion handler called when view is loaded.
 This handler is released after call, so don't mind to break retain cycles 
 in block.
 @return A newly initialized MUKMediaCarouselViewController object.
 */
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil completion:(void (^)(MUKMediaCarouselViewController *viewController))completionHandler;
/**
 Attaches handlers to carouselView.
 
 This method is called in `viewDidLoad`.
 
 @param carouselView Affected carousel view.
 */
- (void)attachHandlersToCarouselView:(MUKMediaCarouselView *)carouselView;
/**
 Detaches handlers from carouselView.
 
 This method is called in `dealloc`.
 
 You should use this method to clear every handler which has an
 unsafe unretained reference to `self`.
 
 @param carouselView Affected carousel view.
 */
- (void)detachHandlersFromCarouselView:(MUKMediaCarouselView *)carouselView;
/**
 Updates title with current displayed media asset.
 */
- (void)updateTitle;
@end
