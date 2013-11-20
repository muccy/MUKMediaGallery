MUKMediaGallery
===============
MUKMediaGallery is a simple iOS 6+ library built to provide you a component which replicates Photos app functionalities.
This version is 2.0, a complete rewrite from previous version, which now can take benefit of `UICollectionView` and `UIPageViewController`.

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

Otherwise you need to:

1. add `MUKMediaGallery` folder to your project
2. add `MUKMediaGalleryResources.bundle`
3. link against `QuartzCore` and `MediaPlayer` frameworks
4. install `MUKToolkit` and `LBYouTubeView` libraries
