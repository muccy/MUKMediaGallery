MUKMediaGallery
===============
MUKMediaGallery is a simple iOS 6+ library built to provide you a component which replicates Photos app functionalities. Classes provided by this project give you a fast path to show medias (photos, videos, audios) in you iOS app.
This version is 2.0, a complete rewrite from previous version, which now can take benefit of `UICollectionView` and `UIPageViewController`.

![Thumbnails Grid](http://cl.ly/image/2R3m2R3H2w2w/thumbs_grid.jpg "Thumbnails Grid") ![Carousel](http://cl.ly/image/242k1o013i0q/carousel.jpg "Carousel") ![Video Playback](http://cl.ly/image/3N0b441P2n3J/video.jpg "Video Playback")

Requirements
------------
* ARC enabled compiler
* Deployment target: iOS 6 or greater
* Base SDK: iOS 7 or greater
* Xcode 5 or greater

Usage
-----
See sample project to see usage.

This framework basically contains two classes:

* `MUKMediaThumbnailsViewController`, a view controller displaying a grid of thumbnails.
* `MUKMediaCarouselViewController`, a view controller displaying a paginated list of photos, videos and audios.

Installation
------------
Use Cocoapods. Really.

	pod 'MUKMediaGallery', '~> 2.0'

Otherwise you need to:

1. add `MUKMediaGallery` folder to your project
2. add `MUKMediaGalleryResources.bundle`
3. link against `QuartzCore` and `MediaPlayer` frameworks
4. install `MUKToolkit` and `LBYouTubeView` libraries
