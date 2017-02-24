//
//  ARMarkerTracker.m
//  ARGame
//
//  Created by James Rogers on 21/02/2017.
//  Copyright © 2017 James Rogers. All rights reserved.
//


#import "ARHandler.h"

#define VIEW_DISTANCE_MIN        5.0f          // Objects closer to the camera than this will not be displayed.
#define VIEW_DISTANCE_MAX        2000.0f        // Objects further away from the camera than this will not be displayed.


@implementation ARHandler
{
    // Loop handlers
    BOOL            running;
    BOOL            videoPaused;
    
    // Video acquisition
    AR2VideoParamT *gVid;
    
    // Marker detection.
    ARHandle       *gARHandle;
    ARPattHandle   *gARPattHandle;
    long            gCallCountMarkerDetect;
    
    // Transformation matrix retrieval.
    AR3DHandle     *gAR3DHandle;
    
    // Markers.
    NSMutableArray *markers;
    
    // Camera
    ARParamLT      *gCparamLT;
    GLsizei         camWidth;
    GLsizei         camHeight;
}

@synthesize camProjection;
@synthesize camBuffer;
@synthesize camBufferTexture;


- (void) onViewLoad
{
    // Loop handlers
    running = FALSE;
    videoPaused = FALSE;
    
    // Video
    gVid = NULL;
    
    // Marker detection
    gARHandle = NULL;
    gARPattHandle = NULL;
    gCallCountMarkerDetect = 0;
    
    // Transform matrix
    gAR3DHandle = NULL;
    
    // Markers
    markers = nil;
    
    // Camera
    gCparamLT = NULL;
    camWidth = 0;
    camHeight = 0;
    camBuffer = 0;
    camBufferTexture = 0;
    
    // Start ARToolKit
    [self start];
}

- (void) startRunLoop
{
    if (!running) {
        // After starting the video, new frames will invoke cameraVideoTookPicture:userData:.
        if (ar2VideoCapStart(gVid) != 0) {
            NSLog(@"Error: Unable to begin camera data capture.\n");
            [self stop];
            return;
        }
        running = TRUE;
    }
}

- (void) stopRunLoop
{
    if (running) {
        ar2VideoCapStop(gVid);
        running = FALSE;
    }
}

- (BOOL) isPaused
{
    if (!running) return (NO);
    
    return (videoPaused);
}

- (void) setPaused:(BOOL)paused
{
    if (!running) return;
    
    if (videoPaused != paused)
    {
        if (paused)
            ar2VideoCapStop(gVid);
        else
            ar2VideoCapStart(gVid);
        
        videoPaused = paused;
#  ifdef DEBUG
        NSLog(@"Run loop was %s.\n", (paused ? "PAUSED" : "UNPAUSED"));
#  endif
    }
}

static void startCallback(void *userData);

- (void)start
{
    // Open the video path.
    char *vconf = "";
    if (!(gVid = ar2VideoOpenAsync(vconf, startCallback, (__bridge void *)(self)))) {
        NSLog(@"Error: Unable to open connection to camera.\n");
        [self stop];
        return;
    }
}

static void startCallback(void *userData)
{
    ARHandler *vc = (__bridge ARHandler *)userData;
    
    [vc start2];
}

- (void) start2
{
    // Find the size of the window.
    int xsize, ysize;
    if (ar2VideoGetSize(gVid, &xsize, &ysize) < 0) {
        NSLog(@"Error: ar2VideoGetSize.\n");
        [self stop];
        return;
    }
    
    // Get the format in which the camera is returning pixels.
    AR_PIXEL_FORMAT pixFormat = ar2VideoGetPixelFormat(gVid);
    if (pixFormat == AR_PIXEL_FORMAT_INVALID) {
        NSLog(@"Error: Camera is using unsupported pixel format.\n");
        [self stop];
        return;
    }
    
    // Work out if the front camera is being used. If it is, flip the viewing frustum for
    // 3D drawing.
    BOOL flipV = FALSE;
    int frontCamera;
    if (ar2VideoGetParami(gVid, AR_VIDEO_PARAM_IOS_CAMERA_POSITION, &frontCamera) >= 0) {
        if (frontCamera == AR_VIDEO_IOS_CAMERA_POSITION_FRONT) flipV = TRUE;
    }
    
    // Tell arVideo what the typical focal distance will be. Note that this does NOT
    // change the actual focus, but on devices with non-fixed focus, it lets arVideo
    // choose a better set of camera parameters.
    ar2VideoSetParami(gVid, AR_VIDEO_PARAM_IOS_FOCUS, AR_VIDEO_IOS_FOCUS_0_3M); // Default is 0.3 metres. See <AR/sys/videoiPhone.h> for allowable values.
    
    // Load the camera parameters, resize for the window and init.
    ARParam cparam;
    if (ar2VideoGetCParam(gVid, &cparam) < 0) {
        NSString *filename = [[NSBundle mainBundle] pathForResource:@"camera_para" ofType:@"dat"];
        
        NSLog(@"Unable to automatically determine camera parameters. Using default.\n");
        if (arParamLoad([filename cStringUsingEncoding:1], 1, &cparam) < 0) {
            NSLog(@"Error: Unable to load parameter file %@ for camera.\n", filename);
            [self stop];
            return;
        }
    }
    
    if (cparam.xsize != xsize || cparam.ysize != ysize) {
#ifdef DEBUG
        fprintf(stdout, "*** Camera Parameter resized from %d, %d. ***\n", cparam.xsize, cparam.ysize);
#endif
        arParamChangeSize(&cparam, xsize, ysize, &cparam);
    }
#ifdef DEBUG
    fprintf(stdout, "*** Camera Parameter ***\n");
    arParamDisp(&cparam);
#endif
    if ((gCparamLT = arParamLTCreate(&cparam, AR_PARAM_LT_DEFAULT_OFFSET)) == NULL) {
        NSLog(@"Error: arParamLTCreate.\n");
        [self stop];
        return;
    }
    
    // AR init.
    if ((gARHandle = arCreateHandle(gCparamLT)) == NULL) {
        NSLog(@"Error: arCreateHandle.\n");
        [self stop];
        return;
    }
    if (arSetPixelFormat(gARHandle, pixFormat) < 0) {
        NSLog(@"Error: arSetPixelFormat.\n");
        [self stop];
        return;
    }
    if ((gAR3DHandle = ar3DCreateHandle(&gCparamLT->param)) == NULL) {
        NSLog(@"Error: ar3DCreateHandle.\n");
        [self stop];
        return;
    }
    
    // libARvideo on iPhone uses an underlying class called CameraVideo. Here, we
    // access the instance of this class to get/set some special types of information.
    CameraVideo *cameraVideo = ar2VideoGetNativeVideoInstanceiPhone(gVid->device.iPhone);
    if (!cameraVideo) {
        NSLog(@"Error: Unable to set up AR camera: missing CameraVideo instance.\n");
        [self stop];
        return;
    }
    
    // The camera will be started by -startRunLoop.
    [cameraVideo setTookPictureDelegate:self];
    [cameraVideo setTookPictureDelegateUserData:NULL];
    
    // Allocate the camBuffer
    ////////////////////////// Not here?
    
    // Set camera projection matrix from calibrated camera paramters
    GLfloat frustum[16];
    arglCameraFrustumRHf(&gCparamLT->param, VIEW_DISTANCE_MIN, VIEW_DISTANCE_MAX, frustum);
    camProjection = GLKMatrix4Make(frustum[0], frustum[1], frustum[2], frustum[3], frustum[4], frustum[5], frustum[6], frustum[7], frustum[8], frustum[9], frustum[10], frustum[11], frustum[12], frustum[13], frustum[14], frustum[15]);
    
    //camProjection = GLKMatrix4Make(frustum[0], frustum[4], frustum[8], frustum[12], frustum[1], frustum[5], frustum[9], frustum[13], frustum[2], frustum[6], frustum[10], frustum[14], frustum[3], frustum[7], frustum[11], frustum[15]);
    
    // Set camera size
    camWidth = gARHandle->xsize;
    camHeight = gARHandle->ysize;
    
    // Start run loop
    [self startRunLoop];
}

- (void) cameraVideoTookPicture:(id)sender userData:(void *)data
{
    AR2VideoBufferT *buffer = ar2VideoGetImage(gVid);
    if (buffer)
        [self processFrame:buffer];
}

- (void) processFrame:(AR2VideoBufferT *)buffer
{
    if (buffer) {
        
        //camBuffer = buffer->buff;
        //camBuffer = [NSData dataWithBytesNoCopy:buffer->buff length:(camWidth * camHeight * 4) freeWhenDone:YES];
        camBuffer = [NSData dataWithBytes:buffer->buff length:(camWidth*camHeight*4)];
        // Bind camera buff to GL texture
        
        //glGenTextures(1, &camBufferTexture);
        //glBindTexture(GL_TEXTURE_2D, camBufferTexture);
        
        //    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
            //glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, camWidth, camHeight, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, buffer->buff);
        //    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, camWidth, camHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, buffer->buff);
        
        //glBindTexture(GL_TEXTURE_2D, 0);
        
       // if(camBufferTexture == 0)
       // {
       //     return;
       // }
        
        // Detect the markers in the video frame.
        if (arDetectMarker(gARHandle, buffer->buff) < 0)
            return;
        
        //int markerNum = arGetMarkerNum(gARHandle);
        //ARMarkerInfo *markerInfo = arGetMarker(gARHandle);
        
        // The display has changed.
        // NEED TO MODIFY THIS
        //[glView drawView:self];
    }
}

- (void)stop
{
    [self stopRunLoop];
    
    if (gARHandle)
        arPattDetach(gARHandle);
    
    if (gARPattHandle)
    {
        arPattDeleteHandle(gARPattHandle);
        gARPattHandle = NULL;
    }
    
    if (gAR3DHandle)
        ar3DDeleteHandle(&gAR3DHandle);
    
    if (gARHandle)
    {
        arDeleteHandle(gARHandle);
        gARHandle = NULL;
    }
    
    arParamLTFree(&gCparamLT);
    
    if (gVid)
    {
        ar2VideoClose(gVid);
        gVid = NULL;
    }
}

@end