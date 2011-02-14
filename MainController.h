/* MainController */

class vtkImageData;

#import <Cocoa/Cocoa.h>
#import "OrthoPlanesView.h"
#import "WLWidgetView.h"

@interface MainController : NSObject
{
    IBOutlet OrthoPlanesView *orthoPlanesView;
	IBOutlet WLWidgetView *wlWidget;

vtkImageReslice *reslice;
vtkImageData *mrImageData;
vtkImageData *ctImageData;
vtkImageData *mriBrainImageData;
vtkImageData *mriHeadImageData;
}


-(void) setupPipeline;

- (IBAction)fileNew:(id)sender;
- (IBAction)fileOpen:(id)sender;

@end
