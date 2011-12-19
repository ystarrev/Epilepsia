#import "vtkCocoaGLView.h"

class vtkRenderer;
class vtkRenderWindow;
class vtkRenderWindowInteractor;
class vtkImagePlaneWidget;
class vtkCellPicker;
class vtkImageData;
class vtkLookupTable;
class vtkProp;
class vtkColorTransferFunction;
class vtkPiecewiseFunction;
class vtkImageCanvasSource2D;

@interface WLWidgetView : vtkCocoaGLView {
    IBOutlet NSPopUpButton *clutMenu;

    vtkImageData*               mriHeadImageData;
	vtkImageData*				mriBrainImageData;
    vtkRenderer*                m_Renderer;
	vtkRenderWindow*            m_RenderWindow;
	vtkRenderWindowInteractor*  m_RenderWindowInteractor;
	vtkCellPicker*              m_Picker;
	vtkColorTransferFunction* colorFunction;
	vtkPiecewiseFunction* opacityFunction;
	float windowSetting,levelSetting;
	vtkImageCanvasSource2D* histoCanvas;
	vtkImageData* histoData;
	float scaleFactor;
    double table[256][3];
}

- (IBAction)levelSlider:(id)sender;
- (IBAction)windowSlider:(id)sender;

- (IBAction)clutMenu:(NSPopUpButton *)sender;



- (void)setMRInput:(vtkImageData *) volumeInput;
- (void)updateView:(NSNotification *)notification;
- (void)setMRVolumeWL:(float)window :(float)level;
- (void)setColorTransferFunction:(vtkColorTransferFunction *) theColorFunction;
- (void)setOpacityFunction:(vtkPiecewiseFunction *) theOpacityFunction;

@end
