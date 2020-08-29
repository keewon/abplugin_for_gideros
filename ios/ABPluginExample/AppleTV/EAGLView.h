//
//  EAGLView.h
//
//  Copyright 2012 Gideros Mobile. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import "Metal/Metal.h"
extern id<MTLDevice> metalDevice;
extern MTLRenderPassDescriptor *metalFramebuffer;

// This class wraps the CAEAGLLayer from CoreAnimation into a convenient UIView subclass.
// The view content is basically an EAGL surface you render your OpenGL scene into.
// Note that setting the view non-opaque will only work if the EAGL surface has an alpha channel.
@interface EAGLView : UIView <UIKeyInput>
{
@private
    EAGLContext *context;
    
    // The pixel dimensions of the CAEAGLLayer.
    GLint framebufferWidth;
    GLint framebufferHeight;
    
    // The OpenGL ES names for the framebuffer and renderbuffer used to render to this view.
    GLuint defaultFramebuffer, colorRenderbuffer;

	BOOL framebufferDirty;
	BOOL retinaDisplay;
	CAEAGLLayer *eaglLayer;
    CAMetalLayer *metalLayer;
    id<CAMetalDrawable> metalDrawable;
    CGRect safeArea;
    id<MTLTexture> metalDepth;
    id<MTLTexture> metalStencil;
}

@property (nonatomic, retain) EAGLContext *context;
@property (nonatomic, readonly) BOOL hasText;
@property (nonatomic) UITextAutocorrectionType autocorrectionType;         // default is UITextAutocorrectionTypeDefault

- (void)setFramebuffer;
- (BOOL)presentFramebuffer;
- (void)enableRetinaDisplay:(BOOL)enable;
- (void) setup;
- (void) tearDown;

@end
