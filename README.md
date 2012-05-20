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

Now add `MUKToolkit.xcodeproj`, `MUKObjectCache.xcodeproj`, `MUKNetworking.xcodeproj` and `MUKScrolling.xcodeproj` by choosing those projects from `Submodules/MUKToolkit`. With this step you are adding `MUKMediaGallery` dependencies. If your project already contains dependencies please take care to use updated libraries.

Please add also [PSYouTubeExtractor] required files (thanks steipete for you great job).

<img src="http://i.imgur.com/xojf5.png" />

#### Step 2: make your project dependent
Click on your project and, then, your app target:

<img src="http://i.imgur.com/J10tA.png" />

Add dependency clicking on + button in *Target Dependencies* pane and choosing static library target (`MUKMediaGallery`), resources bundle target (`MUKMediaGalleryResources`) and its dependencies (`MUKToolkit`, `MUKObjectCache`, `MUKNetworking` and `MUKScrolling`):

<img src="http://i.imgur.com/oaXaS.png" />

Link your project clicking on + button in *Link binary with Libraries* pane and choosing static library product (`libMUKMediaGallery.a`). Link also submodule dependencies (`libMUKNetworking.a`, `MUKObjectCache.a`, `libMUKScrolling.a`):

<img src="http://i.imgur.com/7xpw9.png" />

To link the correct `libMUKToolkit.a` disclose the imported `MUKToolkit.xcodeproj` and drag `libMUKToolkit.a` in `Products` folder:

<img src="http://i.imgur.com/gy7ZC.png" />

#### Step 3: link required frameworks
You need to link those frameworks:

* `Foundation`
* `UIKit`
* `CoreGraphics`
* `Security`
* `MediaPlayer`

To do so you only need to click on + button in *Link binary with Libraries* pane and you can choose them. Tipically you only need to add `Security` and `MediaPlayer`:

<img src="http://i.imgur.com/q0SUB.png" /> <img src="http://i.imgur.com/p9XZh.png" />

#### Step 4: add required files

You need a resources bundle: drag it from `Products` folder in added `MUKMediaGallery.xcodeproj` to `Copy Bundle Resources` build phase of your project target:

<img src="http://i.imgur.com/cKSbf.png" />

#### Step 5: load categories
In order to load every method in `MUKToolkit` dependency you need to insert `-ObjC` flag to `Other Linker Flags` in *Build Settings* of your project.

<img src="http://i.imgur.com/u9OUD.png" /> 


#### Step 6: import headers
You only need to write `#import <MUKMediaGallery/MUKMediaGallery.h>` when you need headers.
You can also import `MUKMediaGallery` headers in your `pch` file:

<img src="http://i.imgur.com/8UA1Y.png?1" />


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

