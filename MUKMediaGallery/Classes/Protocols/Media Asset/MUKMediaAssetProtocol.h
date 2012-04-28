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

#import <Foundation/Foundation.h>

typedef enum {
    MUKMediaAssetKindImage = 0,
    MUKMediaAssetKindVideo,
    MUKMediaAssetKindYouTubeVideo,
    MUKMediaAssetKindAudio
} MUKMediaAssetKind;

/**
 Protocol whih marks a media asset.
 */
@protocol MUKMediaAsset <NSObject>
/**
 Media kind.
 
 Kind could be:
 * `MUKMediaAssetKindImage`, for an image.
 * `MUKMediaAssetKindVideo`, for a video.
 * `MUKMediaAssetKindYouTubeVideo`, for a YouTube video.
 * `MUKMediaAssetKindAudio`, for audio.
 
 @return Kind of the media.
 */
- (MUKMediaAssetKind)mediaKind;
/**
 URL (remote URL or file URL) of the thumbnail.
 @return URL of media thumbnail.
 */
- (NSURL *)thumbnailURL;
/**
 URL (remote URL or file URL) of the full media to show.
 @return URL of media.
 */
- (NSURL *)mediaURL;
@end
