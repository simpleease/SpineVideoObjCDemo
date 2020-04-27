/******************************************************************************
 * Spine Runtimes License Agreement
 * Last updated January 1, 2020. Replaces all prior versions.
 *
 * Copyright (c) 2013-2020, Esoteric Software LLC
 *
 * Integration of the Spine Runtimes into software or otherwise creating
 * derivative works of the Spine Runtimes is permitted under the terms and
 * conditions of Section 2 of the Spine Editor License Agreement:
 * http://esotericsoftware.com/spine-editor-license
 *
 * Otherwise, it is permitted to integrate the Spine Runtimes into software
 * or otherwise create derivative works of the Spine Runtimes (collectively,
 * "Products"), provided that each user of the Products must obtain their own
 * Spine Editor license and redistribution of the Products in any form must
 * include this license and copyright notice.
 *
 * THE SPINE RUNTIMES ARE PROVIDED BY ESOTERIC SOFTWARE LLC "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL ESOTERIC SOFTWARE LLC BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES,
 * BUSINESS INTERRUPTION, OR LOSS OF USE, DATA, OR PROFITS) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THE SPINE RUNTIMES, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *****************************************************************************/

#import "GoblinsExample.h"
#import "RaptorExample.h"
#import "CCButton.h"
#import <AVFoundation/AVFoundation.h>


@interface GoblinsExample ()
@property(nonatomic, strong) CCRenderTexture *renderTexture;
@property(nonatomic, strong) SkeletonAnimation *skeleton2;
@property(nonatomic, assign) BOOL cancelled;

@property(nonatomic, copy) NSString *exportRootPath;

@end

@implementation GoblinsExample

+ (CCScene*) scene {
	CCScene *scene = [CCScene node];
	[scene addChild:[GoblinsExample node]];
	return scene;
}

-(id) init {
	self = [super init];
	if (!self) return nil;
    
    CCButton *btn = [CCButton buttonWithTitle:@"重置" fontName:@"HelveticaNeue" fontSize:18];
    [btn setPosition:ccp(40, 220)];
    [btn setTarget:self selector:@selector(onReset:)];
    [btn setBackgroundColor:[CCColor greenColor] forState:CCControlStateNormal];
    [btn setBackgroundColor:[CCColor yellowColor] forState:CCControlStateHighlighted];
    [self addChild:btn];
    
    btn = [CCButton buttonWithTitle:@"离屏图片" fontName:@"HelveticaNeue" fontSize:18];
    [btn setPosition:ccp(40, 180)];
    [btn setTarget:self selector:@selector(onSaveImage:)];
    [self addChild:btn];

    btn = [CCButton buttonWithTitle:@"导出" fontName:@"HelveticaNeue" fontSize:18];
    [btn setPosition:ccp(40, 140)];
    [btn setTarget:self selector:@selector(onExport:)];
    [self addChild:btn];
    
    btn = [CCButton buttonWithTitle:@"取消导出" fontName:@"HelveticaNeue" fontSize:18];
    [btn setPosition:ccp(40, 100)];
    [btn setTarget:self selector:@selector(onCancelExport:)];
    [self addChild:btn];
    
	skeletonNode = [SkeletonAnimation skeletonWithFile:@"goblins-pro.json" atlasFile:@"goblins.atlas" scale:1];
    
    CGSize windowSize = [[CCDirector sharedDirector] viewSize];
    [skeletonNode setPosition:ccp(windowSize.width / 2, 20)];
    [self addChild:skeletonNode];
    self.userInteractionEnabled = YES;
    self.contentSize = windowSize;
    
    _renderTexture = [CCRenderTexture renderTextureWithWidth:windowSize.width height:windowSize.height];
        
    [self initSkins];
    
    [skeletonNode setAnimationForTrack:0 name:@"walk" loop:YES];
    
    self.exportRootPath = [NSHomeDirectory() stringByAppendingPathComponent:@"frame-cap"];
    NSLog(@"export root path: %@", self.exportRootPath);
    [[NSFileManager defaultManager] createDirectoryAtPath:self.exportRootPath withIntermediateDirectories:NO attributes:nil error:nil];
        
	return self;
}

- (void)initSkins {
    
    /// set whole skin
    if(time(0) % 2  == 0) {
        [skeletonNode setSkin:@"goblin"];
    } else {
        [skeletonNode setSkin:@"goblingirl"];
    }
#define ATTACHMENT_SET_TYPE 4
#if ATTACHMENT_SET_TYPE == 1
    /// set exist attachment in the same slot
        [skeletonNode setAttachment:@"left-hand-item" attachmentName:@"dagger"];
#elif ATTACHMENT_SET_TYPE == 2
    /// set exit attachment in other slot
        spAttachment * attachment = [skeletonNode getAttachment:@"right-hand-item2" attachmentName:@"shield"];
        if(attachment) {
            [skeletonNode setAttachment:attachment atSlot:@"left-hand-item"];
        }
#elif ATTACHMENT_SET_TYPE == 3
    /// set attachment from another skeleton
        _skeleton2 = [SkeletonAnimation skeletonWithFile:@"spineboy-pro.json" atlasFile:@"spineboy.atlas" scale:0.4];
        spAttachment * attachment = [_skeleton2 getAttachment:@"gun" attachmentName:@"gun"];
        if(attachment) {
            [skeletonNode setAttachment:attachment atSlot:@"left-hand-item"];
        }
#elif ATTACHMENT_SET_TYPE == 4
    /// set attachment from an image
    [skeletonNode setAttachmentWithImage:@"spineboy-head.png" atSlot:@"head"];
#endif
}

#if ( TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR )
- (void)touchBegan:(UITouch *)touch withEvent:(UIEvent *)event {
    if (!skeletonNode.debugBones)
        skeletonNode.debugBones = true;
    else if (skeletonNode.timeScale == 1) {
        skeletonNode.timeScale = 0.3f;
    }
    else {
        [[CCDirector sharedDirector] replaceScene:[RaptorExample scene]];
    }
}
#endif

- (void)onReset:(CCButton *)sender {
    [skeletonNode setToSetupPose];
//    [skeletonNode setBonesToSetupPose];
    [self initSkins];
}

- (void)onSaveImage:(CCButton *)sender {
    [[CCDirector sharedDirector] pause];
    [[CCDirector sharedDirector] stopAnimation];
    
    
    [_renderTexture begin];
    RaptorExample *raptor = [RaptorExample node];
    [raptor.children.firstObject update:time(0)];
    [raptor visit];
    [_renderTexture end];
    
    UIImage *img = [_renderTexture getUIImage];
    NSString *path = [self.exportRootPath stringByAppendingPathComponent:[NSString stringWithFormat:@"raptor_%ld.jpg", time(0)]];
    [UIImageJPEGRepresentation(img, 1.0) writeToFile:path atomically:YES];
    NSLog(@"%@", NSStringFromCGSize(img.size));
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self onReset:nil];
        [[CCDirector sharedDirector] resume];
        [[CCDirector sharedDirector] startAnimation];
    });
}

- (void)onExport:(CCButton *)sender {
    [[CCDirector sharedDirector] pause];
    [[CCDirector sharedDirector] stopAnimation];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self saveToVideo:^(NSString *videoPath, NSError *error) {
            [self onReset:nil];
            [[CCDirector sharedDirector] resume];
            [[CCDirector sharedDirector] startAnimation];
        }];
    });
}

- (void)onCancelExport:(CCButton *)sender {
    self.cancelled = YES;
}

- (void)saveToVideo:(void (^)(NSString *, NSError *))completion {
    NSLog(@"home directory: %@", NSHomeDirectory());
    self.cancelled = NO;
    NSDate *beginDate = [NSDate date];
    
    CGSize videoSize = [[CCDirector sharedDirector] viewSize];
    GLuint videoWidth = videoSize.width;
    GLuint videoHeight = videoSize.height;
    GLuint pixelWidth = videoSize.width * [[CCDirector sharedDirector] contentScaleFactor];
    GLuint pixelHeight = videoSize.height * [[CCDirector sharedDirector] contentScaleFactor];
    NSString *videoOutPath = [self.exportRootPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%tu.mp4", (NSUInteger)([[NSDate date] timeIntervalSince1970] * 1000)]];
    NSError *error = nil;
    AVAssetWriter *videoWriter = [AVAssetWriter assetWriterWithURL:[NSURL fileURLWithPath:videoOutPath] fileType:AVFileTypeMPEG4 error:&error];
    
    // video
    NSDictionary *compressionProperties =@{
        AVVideoAverageBitRateKey:[NSNumber numberWithDouble:2000 * 1000],
    };
    NSDictionary *videoSettings = @{
        AVVideoCompressionPropertiesKey : compressionProperties,
        AVVideoCodecKey                 : AVVideoCodecH264,
        AVVideoWidthKey                 : @(pixelWidth),
        AVVideoHeightKey                : @(pixelHeight)
    };
    AVAssetWriterInput *videoWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
    videoWriterInput.expectsMediaDataInRealTime = YES;
    if ([videoWriter canAddInput:videoWriterInput]) {
        [videoWriter addInput:videoWriterInput];
    }
    else {
        completion(nil, error);
        return;
    }
    
    NSDictionary *pixelBufferAttributes = @{
        (__bridge id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA),
        (__bridge id)kCVPixelBufferWidthKey: @(pixelWidth),
        (__bridge id)kCVPixelBufferHeightKey: @(pixelHeight),
//        (__bridge id)kCVPixelBufferCGImageCompatibilityKey: @(YES),
//        (__bridge id)kCVPixelBufferCGBitmapContextCompatibilityKey: @(YES),
    };
    AVAssetWriterInputPixelBufferAdaptor *writerPixelBufferInput = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:videoWriterInput sourcePixelBufferAttributes:pixelBufferAttributes];
    
    [videoWriter startWriting];
    [videoWriter startSessionAtSourceTime:kCMTimeZero];
    
    __block GoblinsExample *scene = nil;
    [self runSynchronouslyOnDrawThread: ^{
        scene = [GoblinsExample node];
    }];
    
    CCTime duration = 30;
    CCTime dt = 1.0 / 15;
    CCTime curTime = 0;
    while(curTime < duration) {
        if(videoWriter.status != AVAssetWriterStatusWriting) {
            break;
        }
        
        /// 此处应该复用buffer，提高性能
        CVPixelBufferRef pixel_buffer = NULL;
        CVReturn status = CVPixelBufferPoolCreatePixelBuffer (NULL, [writerPixelBufferInput pixelBufferPool], &pixel_buffer);
        if ((pixel_buffer == NULL) || (status != kCVReturnSuccess))
        {
            CVPixelBufferRelease(pixel_buffer);
            break;
        }
        else
        {
            CVPixelBufferLockBaseAddress(pixel_buffer, 0);
            GLubyte *pixelBufferData = (GLubyte *)CVPixelBufferGetBaseAddress(pixel_buffer);
    
            __block BOOL needsFlip = YES;
            [self runSynchronouslyOnDrawThread: ^{
                CCRenderTexture *renderTexture = [CCRenderTexture renderTextureWithWidth:videoWidth height:videoHeight];
                [renderTexture begin];
                [scene->skeletonNode update:dt];
                [scene visit];
                [renderTexture end];
#if 1
                needsFlip = YES;
                CCRenderer *renderer = [renderTexture begin];
                [renderer enqueueBlock:^{
                    glReadPixels(0,0, pixelWidth, pixelHeight, GL_RGBA, GL_UNSIGNED_BYTE, pixelBufferData);
                } globalSortOrder:NSIntegerMax debugLabel:@"CCRenderTexture reading pixels for new image" threadSafe:NO];
                [renderTexture end];
#else
                needsFlip = NO;
                memset(pixelBufferData, 0, CVPixelBufferGetDataSize(pixel_buffer));
                CGImageRef imgRef = [renderTexture newCGImage];
                CGFloat imgWidth = CGImageGetWidth(imgRef);
                CGFloat imgHeight = CGImageGetHeight(imgRef);
                CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
                CGContextRef context = CGBitmapContextCreate(pixelBufferData, pixelWidth, pixelHeight, 8, CVPixelBufferGetBytesPerRow(pixel_buffer),rgbColorSpace,(CGBitmapInfo)kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
                CGContextDrawImage(context, CGRectMake(0, 0, imgWidth, imgHeight), imgRef);
                CGColorSpaceRelease(rgbColorSpace);
                CGContextRelease(context);
                CFRelease(imgRef);
#endif
            }];

            
            if(needsFlip) {
                // swap red and blue
                size_t pixelCount = pixelWidth * pixelHeight;
                for (GLuint i=0; i < pixelCount; ++i) {
                    GLuint startIdx = i * 4;
                    GLubyte b_red = pixelBufferData[startIdx];
                    pixelBufferData[startIdx] = pixelBufferData[startIdx+2];
                    pixelBufferData[startIdx+2] = b_red;
                }
                
                // flip the buffer data
                GLuint lineLength = pixelWidth * 4;
                GLubyte *lineBuf = calloc(lineLength, 1);
                for (GLuint i=0; i < (GLuint)pixelHeight / 2; ++i){
                    GLubyte *topBuf = pixelBufferData + i * lineLength;
                    GLubyte *bottomBuf = pixelBufferData + (pixelHeight - i - 1) * lineLength;
                    memcpy(lineBuf, topBuf, lineLength);
                    memcpy(topBuf, bottomBuf, lineLength);
                    memcpy(bottomBuf, lineBuf, lineLength);
                }
                free(lineBuf);
            }
            
            while(!videoWriterInput.readyForMoreMediaData && !self.cancelled) {
                NSDate *maxDate = [NSDate dateWithTimeIntervalSinceNow:0.1];
                [[NSRunLoop currentRunLoop] runUntilDate:maxDate];
            }
            
            if(self.cancelled) {
                break;
            }
            
            CMTime frameTime = CMTimeMake((int64_t)(curTime * 1000), 1000);
            if (![writerPixelBufferInput appendPixelBuffer:pixel_buffer withPresentationTime:frameTime]) {
                NSLog(@"Problem appending pixel buffer at time: %@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, frameTime)));
            }
            
            CVPixelBufferUnlockBaseAddress(pixel_buffer, 0);
            CVPixelBufferRelease(pixel_buffer);
        }
        
        curTime += dt;
    }
    
    if(!self.cancelled) {
        [videoWriterInput markAsFinished];
        [videoWriter finishWritingWithCompletionHandler:^{
            NSLog(@"ExportFinish (%.3f) -- %@", [[NSDate date] timeIntervalSinceDate:beginDate], videoOutPath);
             dispatch_async(dispatch_get_main_queue(), ^{
                 completion(videoOutPath, error);
             });
        }];
    } else {
        NSLog(@"export sesstion cancelled");
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [[NSFileManager defaultManager] removeItemAtPath:videoOutPath error:nil];
        });
    }
}

- (void)runSynchronouslyOnDrawThread:(void (^)(void))block {
    NSThread *ccThread = [[CCDirector sharedDirector] runningThread];
    if([NSThread currentThread] == ccThread) {
        block();
    } else {
        [self performSelector:@selector(blockRunner:) onThread:ccThread withObject:block waitUntilDone:YES];
    }
}

- (void)blockRunner:(void(^)(void))block {
    block();
}

@end
