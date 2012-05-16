MUKMediaGallery
===============
MUKMediaGallery is a simple, block-based, ARC-enabled, iOS 4+ library built to provide you a component which replicates Photos app functionalities.

Requirements
------------
* ARC enabled compiler
* Deployment target: iOS 4 or greater
* Base SDK: iOS 5 or greater
* Xcode 4 or greater

Usage
-----
See sample project to see usage.

This framework basically contains five classes:
* `MUKImageFetcher`, a class you can use in order to load and cache images (also in a `UITableView`).
* `MUKMediaThumbnailsView`, a view which displays a grid of thumbnails.
* `MUKMediaCarouselView`, a view which display a paginated list of photos, videos and audios.
* `MUKMediaThumbnailsViewController`, a view controller which manages a `MUKMediaThumbnailsView` instance.
* `MUKMediaCarouselViewController`, a view controller which manages a `MUKMediaCarouselView` instance.

Below you could see a couple of screenshots of `MUKMediaThumbnailsViewController` and `MUKMediaCarouselViewController` in action:

<img src="http://i.imgur.com/0Q5e6.png" />  <img src="http://i.imgur.com/ZVxE5.png" />

<img src="http://i.imgur.com/l60aJ.png" />

<img src="http://i.imgur.com/MvGRV.png" />

Installation
------------
*Thanks to [jverkoey iOS Framework]*.

#### Step 0: clone project from GitHub recursively, in order to get also submodules

    git clone --recursive git://github.com/muccy/MUKMediaGallery.git

#### Step 1: add MUKMediaGallery to your project
Drag or *Add To Files...* `MUKMediaGallery.xcodeproj` to your project.

<img src="http://i.imgur.com/97FcV.png" />

Please remember not to create a copy of files while adding project: you only need a reference to it.

<img src="http://i.imgur.com/pCUIQ.png" />


#### Step 2: make your project dependent
Click on your project and, then, your app target:

<img src="http://i.imgur.com/WQeZZ.png" />

Add dependency clicking on + button in *Target Dependencies* pane, choosing static library target (`MUKMediaGallery`) and resources bundle target (`MUKMediaGaleryResources`):

<img src="http://i.imgur.com/3fdiP.png" />

Link your project clicking on + button in *Link binary with Libraries* pane and choosing static library product (`libMUKMediaGallery.a`). Link also submodule dependencies (`libMUKNetworking.a`, `MUKObjectCache.a`, `libMUKScrolling.a` and `libMUKToolkit.a`):

<img src="http://i.imgur.com/8qmWK.png" />

#### Step 3: link required frameworks
You need to link those frameworks:

* `Foundation`
* `UIKit`
* `CoreGraphics`
* `Security`
* `MediaPlayer`

To do so you only need to click on + button in *Link binary with Libraries* pane and you can choose them. Tipically you only need to add `Security` and `MediaPlayer`:

<img src="http://i.imgur.com/q0SUB.png" />

<img src="http://i.imgur.com/p9XZh.png" />

#### Step 4: add required files
You need to add great [PSYouTubeExtractor] (*thanks to steipete for this*), because media gallery carousel uses it in order to display YouTube videos in a native movie player.

Just drag `PSYouTubeExtractor` folder from added `MUKMediaGallery.xcodeproj` to your project:

<img src="http://i.imgur.com/LxJb9.png" />

You also need a resources bundle: drag it from `Products` folder in added `MUKMediaGallery.xcodeproj` to `Copy Bundle Resources` build phase of your project target:

<img src="http://i.imgur.com/AHuge.png" />

#### Step 5: load categories
In order to load every method in `MUKToolkit` dependency you need to insert `-ObjC` flag to `Other Linker Flags` in *Build Settings* of your project.

<img src="http://i.imgur.com/PWWOs.png" /> 


#### Step 6: import headers
You only need to write `#import <MUKMediaGallery/MUKMediaGallery.h>` when you need headers.
You can also import `MUKMediaGallery` headers in your `pch` file:

<img src="http://i.imgur.com/8UA1Y.png" />


Documentation
-------------
Build `MUKMediaGalleryDocumentation` target in order to install documentation in Xcode.

*Requirement*: [appledoc] awesome project.

*TODO*: online documentation.



License
-------
Copyright (c) 2012, Marco Muccinelli
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright
notice, this list of conditions and the following disclaimer.
* Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.
* Neither the name of the <organization> nor the
names of its contributors may be used to endorse or promote products
derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


[PSYouTubeExtractor]: https://github.com/steipete/PSYouTubeExtractor
[jverkoey iOS Framework]: https://github.com/jverkoey/iOS-Framework
[appledoc]: https://github.com/tomaz/appledoc

