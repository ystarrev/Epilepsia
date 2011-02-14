#import "vtkCocoaGLView.h"
#import "WLWidgetView.h"
#import "vtkVolumeGLSLRayCastMapper.h"
#import "vtkFixedPointVolumeRayCastMapper.h"
#import "vtkVolumeTextureMapper3D.h"

class vtkRenderer;
class vtkRenderWindow;
class vtkRenderWindowInteractor;
class vtkImagePlaneWidget;
class vtkCellPicker;
class vtkImageData;
class vtkLookupTable;
class vtkProp;
class vtkColorTransferFunction;
class vtkClippingCubeWidget;
class vtkClippingCubeRepresentation;
class vtkOrientationMarkerWidget;
class vtkAtamaiOpenGLVolumeTextureMapper3D;
class vtkActor;
class vtkPolyDataMapper;
class vtkPolyData;
class vtkAtamaiMRIBrainExtractor;
class vtkTriangleFilter;
class vtkStripper;
class vtkContourFilter;
class vtkImageStencil;
class vtkImagePlaneWidget;
class vtkImageClippingCube;


@interface OrthoPlanesView : vtkCocoaGLView
{
    IBOutlet WLWidgetView *wlWidget;
	
	
	
    vtkImageData*               mriHeadImageData;
	vtkImageData*				mriBrainImageData;
    vtkImageData*               ctImageData;
    vtkRenderer*                m_Renderer;
	vtkRenderWindow*            m_RenderWindow;
	vtkRenderWindowInteractor*  m_RenderWindowInteractor;
	vtkCellPicker*              m_Picker;
	vtkImagePlaneWidget*        m_ImagePlanes[6];
    
    
    
    //vtkVolumeGLSLRayCastMapper* volumeMapper;
	//vtkAtamaiOpenGLVolumeTextureMapper3D* volumeMapper;
    vtkFixedPointVolumeRayCastMapper* volumeMapper;
    vtkVolume *volume;
    vtkColorTransferFunction *volumeColorFunction;
    vtkPiecewiseFunction *volumeOpacityFunction;
	
	vtkContourFilter *electrodeContourFilter;
	vtkTriangleFilter *electrodeTriangles;
	vtkStripper *electrodeStripper;
	vtkPolyDataMapper *electrodeMapper;
	vtkImageStencil *ctStencilledWithBrain;
    
    vtkClippingCubeRepresentation *clippingCubeRep;
    vtkClippingCubeWidget *clippingCubeWidget;
	vtkImageClippingCube *imageClippingCube;
    
    vtkOrientationMarkerWidget *orientationWidget;
    
    vtkAtamaiMRIBrainExtractor *stripper;
    vtkPolyData *brainMesh;
    vtkActor *brainMeshActor;
    
}
- (vtkRenderWindow*)getRenderWindow;
- (vtkRenderWindowInteractor*)getRenderWindowInteractor;

- (void)setMRHeadInput:(vtkImageData *) volumeInput;
- (void)setMRBrainInput:(vtkImageData *) volumeInput;
- (void)setCTInput:(vtkImageData *) volumeInput;
- (void)updateView:(NSNotification *)notification;
-(void)setVolume:(vtkVolume *) theVolume;

- (IBAction)setBrainMeshScale:(id)sender;
- (IBAction)setCTElectrodeThreshold:(id)sender;

	// delegate method
- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem;


@end


