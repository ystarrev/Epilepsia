#import "OrthoPlanesView.h"

// VTK
#include "vtkRenderer.h"
#include "vtkRenderWindow.h"
#include "vtkRenderWindowInteractor.h"
#include "vtkInteractorStyleTrackballCamera.h"
#include "vtkCocoaRenderWindow.h"
#include "vtkImageData.h"
#include "vtkImageGaussianSource.h"
#include "vtkImageChangeInformation.h"
#include "vtkImagePlaneWidget.h"
#include "vtkProperty.h"
#include "vtkCellPicker.h"
#include "vtkLookupTable.h"
#include "vtkMINCImageReader.h"
#include "vtkContourFilter.h"
#include "vtkTriangleFilter.h"
#include "vtkDecimatePro.h"
#include "vtkPolyDataMapper.h"
#include "vtkActor.h"
#include "vtkImageOrthoPlanes.h"
#include "vtkImageReslice.h"
#include "vtkMNIXFMReader.h"
#include "vtkColorTransferFunction.h"
#include "vtkPiecewiseFunction.h"
#include "vtkVolumeProperty.h"
#include "vtkFixedPointVolumeRayCastMapper.h"
#include "vtkPolyDataReader.h"
#include "vtkAtamaiPolyDataToImageStencil2.h"
#include "vtkImageStencil.h"
#include "vtkCamera.h"
#include "vtkClippingCubeWidget.h"
#include "vtkClippingCubeRepresentation.h"
#include "vtkAnnotatedCubeActor.h"
#include "vtkOrientationMarkerWidget.h"
#include "vtkAtamaiOpenGLVolumeTextureMapper3D.h"
#include "vtkAtamaiMRIBrainExtractor.h"
#include "vtkPolyDataToImageStencil.h"
#include "vtkImageStencil.h"
#include "vtkImplicitVolume.h"
#include "vtkClipPolyData.h"
#include "vtkStripper.h"
#include "vtkImagePlaneWidget.h"
#include "vtkImageClippingCube.h"
#include "vtkMNIOBJReader.h"

@implementation OrthoPlanesView

// ----------------------------------------------------------
- (id)initWithFrame:(NSRect)frame
{
	self = [super initWithFrame:frame];
	
	if (self) 
    {
        NSLog(@"OrthoPlanesView::frame!");

	// Setup the basic rendering pipeline
	m_Renderer = vtkRenderer::New();
	m_RenderWindow = vtkRenderWindow::New();
	m_RenderWindowInteractor = vtkRenderWindowInteractor::New();
	vtkInteractorStyleTrackballCamera *style = vtkInteractorStyleTrackballCamera::New();
	m_RenderWindowInteractor->SetInteractorStyle(style);
	m_Picker = vtkCellPicker::New();
	
	// Connect the vtkRendererWindow
	m_RenderWindow->AddRenderer(m_Renderer);
	
	// Connect the vtkRenderWindowInteractor
	m_RenderWindowInteractor->SetRenderWindow(m_RenderWindow);
	
	// Setup the picker
	m_Picker->SetTolerance(0.005);
        
        vtkAnnotatedCubeActor* cube = vtkAnnotatedCubeActor::New();
        cube->SetXPlusFaceText ("R" );
        cube->SetXMinusFaceText("L" );
        cube->SetYPlusFaceText ("A" );
        cube->SetYMinusFaceText("P" );
        cube->SetZPlusFaceText ("S" );
        cube->SetZMinusFaceText("I" );
        cube->SetFaceTextScale(0.8 );
        
        vtkProperty* property = cube->GetXPlusFaceProperty();
        property->SetColor(0, 0, 1);
        property = cube->GetXMinusFaceProperty();
        property->SetColor(0, 0, 1);
        property = cube->GetYPlusFaceProperty();
        property->SetColor(0, 1, 0);
        property = cube->GetYMinusFaceProperty();
        property->SetColor(0, 1, 0);
        property = cube->GetZPlusFaceProperty();
        property->SetColor(1, 0, 0);
        property = cube->GetZMinusFaceProperty();
        property->SetColor(1, 0, 0);
        
        vtkProperty* propertyEdges = cube->GetTextEdgesProperty();
        propertyEdges->SetColor(0.5, 0.5, 0.5);
        //cube->CubeOn();
        //cube->FaceTextOn();
        
        
        orientationWidget = vtkOrientationMarkerWidget::New();
        orientationWidget->SetOrientationMarker( cube );
        orientationWidget->SetInteractor( m_RenderWindowInteractor );
        orientationWidget->SetViewport( .9,.9, 1, 1);
		orientationWidget->SetKeyPressActivation(0);
        
        cube->Delete();
        
		
		// This is the ONLY place we need to explicitly cast our render window
		// to a vtkCocoaRenderWindow
		vtkCocoaRenderWindow*  cocoaRenWin = dynamic_cast<vtkCocoaRenderWindow*>(m_RenderWindow);
		[self setVTKRenderWindow:cocoaRenWin];
		
		// Register for update notifications
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateView:) name:@"UpdateViewNotification" object:nil];
        
		// Create clipping cube widget
		clippingCubeRep = vtkClippingCubeRepresentation::New();
		//clippingCubeRep->GetOutlineProperty()->SetColor(0.5, 0.5, 0.5);
		clippingCubeRep->GetOutlineProperty()->SetColor(0.1843,0.3098,0.3098);
		clippingCubeRep->SetPlaceFactor(1.0);
		clippingCubeRep->GetOutlineProperty()->SetLineWidth(2.0);
		clippingCubeRep->GetSelectedEdgeOutlineProperty()->SetColor(1.0, 0.0, 0.0);
		clippingCubeRep->GetSelectedFaceOutlineProperty()->SetColor(0.0, 1.0, 0.0);
		
		clippingCubeWidget = vtkClippingCubeWidget::New();
		clippingCubeWidget->SetRepresentation(clippingCubeRep);
		
		// Add The ImagePlaneWidgets
		m_ImagePlanes[0] = vtkImagePlaneWidget::New();
		m_ImagePlanes[1] = vtkImagePlaneWidget::New();
		m_ImagePlanes[2] = vtkImagePlaneWidget::New();
		m_ImagePlanes[3] = vtkImagePlaneWidget::New();
		m_ImagePlanes[4] = vtkImagePlaneWidget::New();
		m_ImagePlanes[5] = vtkImagePlaneWidget::New();
		
		m_ImagePlanes[0]->GetPlaneProperty()->SetOpacity(0);
		m_ImagePlanes[1]->GetPlaneProperty()->SetOpacity(0);
		m_ImagePlanes[2]->GetPlaneProperty()->SetOpacity(0);
		m_ImagePlanes[3]->GetPlaneProperty()->SetOpacity(0);
		m_ImagePlanes[4]->GetPlaneProperty()->SetOpacity(0);
		m_ImagePlanes[5]->GetPlaneProperty()->SetOpacity(0);
		
		m_ImagePlanes[0]->SetPriority(0.0);
		m_ImagePlanes[1]->SetPriority(0.0);
		m_ImagePlanes[2]->SetPriority(0.0);
		m_ImagePlanes[3]->SetPriority(0.0);
		m_ImagePlanes[4]->SetPriority(0.0);
		m_ImagePlanes[5]->SetPriority(0.0);

		m_ImagePlanes[0]->RestrictPlaneToVolumeOff();
		m_ImagePlanes[1]->RestrictPlaneToVolumeOff();
		m_ImagePlanes[2]->RestrictPlaneToVolumeOff();
		m_ImagePlanes[3]->RestrictPlaneToVolumeOff();
		m_ImagePlanes[4]->RestrictPlaneToVolumeOff();
		m_ImagePlanes[5]->RestrictPlaneToVolumeOff();
		
		// Add ImageClippingCube
		
		imageClippingCube = vtkImageClippingCube::New();
		
		//imageClippingCube->SetPlane(0, m_ImagePlanes[0]);
		//imageClippingCube->SetPlane(1, m_ImagePlanes[1]);
		//imageClippingCube->SetPlane(2, m_ImagePlanes[2]);
		//imageClippingCube->SetPlane(3, m_ImagePlanes[3]);
		//imageClippingCube->SetPlane(4, m_ImagePlanes[4]);
		//imageClippingCube->SetPlane(5, m_ImagePlanes[5]);
    }
	
	return self;
}

-(void)awakeFromNib
{
    [[self window] setAcceptsMouseMovedEvents:YES];
}

-(vtkRenderWindow*)getRenderWindow
{
    return m_RenderWindow;
}
- (vtkRenderWindowInteractor*)getRenderWindowInteractor
{
    return m_RenderWindowInteractor;
}
// ----------------------------------------------------------
- (void)drawRect:(NSRect)theRect
{
	// The first time we draw, finish setting up the vtk pipeline
	if (m_RenderWindowInteractor && (m_RenderWindowInteractor->GetInitialized() == NO))
    {
        
        NSLog(@"OrthoPlanesView::drawRect first time!");
		m_RenderWindow->SetWindowId([self window]);
		m_RenderWindow->SetDisplayId(self);
		m_RenderWindowInteractor->Initialize();
		
		m_Renderer->GetActiveCamera()->ParallelProjectionOn();
        m_Renderer->ResetCamera();
		
        clippingCubeWidget->SetInteractor(m_RenderWindowInteractor);
        clippingCubeWidget->SetEnabled(1);

	m_ImagePlanes[0]->SetCurrentRenderer(m_Renderer);
	m_ImagePlanes[1]->SetCurrentRenderer(m_Renderer);
	m_ImagePlanes[2]->SetCurrentRenderer(m_Renderer);
	m_ImagePlanes[3]->SetCurrentRenderer(m_Renderer);
	m_ImagePlanes[4]->SetCurrentRenderer(m_Renderer);
	m_ImagePlanes[5]->SetCurrentRenderer(m_Renderer);

	m_ImagePlanes[0]->SetInteractor(m_RenderWindow->GetInteractor());
	m_ImagePlanes[1]->SetInteractor(m_RenderWindow->GetInteractor());
	m_ImagePlanes[2]->SetInteractor(m_RenderWindow->GetInteractor());
	m_ImagePlanes[3]->SetInteractor(m_RenderWindow->GetInteractor());
	m_ImagePlanes[4]->SetInteractor(m_RenderWindow->GetInteractor());
	m_ImagePlanes[5]->SetInteractor(m_RenderWindow->GetInteractor());
  
	m_ImagePlanes[0]->PlaceWidget();
	m_ImagePlanes[1]->PlaceWidget();
	m_ImagePlanes[2]->PlaceWidget();
	m_ImagePlanes[3]->PlaceWidget();
	m_ImagePlanes[4]->PlaceWidget();
	m_ImagePlanes[5]->PlaceWidget();

	m_ImagePlanes[0]->On();
	m_ImagePlanes[1]->On();
	m_ImagePlanes[2]->On();
	m_ImagePlanes[3]->On();
	m_ImagePlanes[4]->On();
	m_ImagePlanes[5]->On();

	m_ImagePlanes[0]->SetInteraction(0);
	m_ImagePlanes[1]->SetInteraction(0);
	m_ImagePlanes[2]->SetInteraction(0);
	m_ImagePlanes[3]->SetInteraction(0);
	m_ImagePlanes[4]->SetInteraction(0);
	m_ImagePlanes[5]->SetInteraction(0);

	imageClippingCube->SetClippingCube(clippingCubeWidget);
        
        clippingCubeRep->PlaceWidget(mriHeadImageData->GetBounds());
        
        volumeMapper->SetClippingPlanes(clippingCubeRep->GetPlanes());   
        
        orientationWidget->InteractiveOff();
        orientationWidget->SetEnabled(1);
        
		
    }
	
	// vtkCocoaGLView does the drawing
	[super drawRect:theRect];
}

- (void)updateView:(NSNotification *)notification
{
    [self setNeedsDisplay:YES]; 
}


// Need this, or the window gets dragged around indiscriminately!
- (BOOL)mouseDownCanMoveWindow
{
	return NO;
}


// ----------------------------------------------------------
- (void)dealloc
{
	// vtkRenderer
	if (m_Renderer)
    {
		m_Renderer->Delete();
    }
	
	// vtkRenderWindow
	if (m_RenderWindow)
    {
		m_RenderWindow->Delete();
    }
	
	// vtkRenderWindowInteractor
	if (m_RenderWindowInteractor)
    {
		m_RenderWindowInteractor->Delete();
    }
	
	[super dealloc];
}

// Delegate method to find out when the tabview is changing
- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    if ([[tabViewItem identifier] isEqual:@"Brain"])
    {
        m_Renderer->RemoveActor(brainMeshActor); 
        m_Renderer->AddVolume(volume);
		electrodeContourFilter->SetInput(ctStencilledWithBrain->GetOutput());
    }
    
    else if ([[tabViewItem identifier] isEqual:@"Electrodes"])
    {
//        m_Renderer->AddActor(brainMeshActor); 
        m_Renderer->RemoveVolume(volume);
		electrodeContourFilter->SetInput(ctImageData);
    }
    
    else if ([[tabViewItem identifier] isEqual:@"Registration"])
    {
        m_Renderer->RemoveActor(brainMeshActor); 
    }    
    [self setNeedsDisplay:YES]; 
	
}



// ----------------------------------------------------------
- (void)setCTInput:(vtkImageData *) volumeInput
{
    if (volumeInput)
    {
        ctImageData = volumeInput;
    }    
}    


// ----------------------------------------------------------
- (void)setMRBrainInput:(vtkImageData *) volumeInput
{
    if (volumeInput)
    {
        NSLog(@"OrthoPlanesView::setMRBrainInput");
        mriBrainImageData = volumeInput;
		
	m_ImagePlanes[0]->SetInput(mriBrainImageData);
	m_ImagePlanes[1]->SetInput(mriBrainImageData);
	m_ImagePlanes[2]->SetInput(mriBrainImageData);
	m_ImagePlanes[3]->SetInput(mriBrainImageData);
	m_ImagePlanes[4]->SetInput(mriBrainImageData);
	m_ImagePlanes[5]->SetInput(mriBrainImageData);

	// Make a lookup table that switches from transparent to opaque
	vtkLookupTable *lookupTable = vtkLookupTable::New();//m_ImagePlanes[0]->GetLookupTable();
// 	lookupTable->Build();
// 	for (int i = 0; i < 80; i++)
// 	  {
// 	    double val = i/255.0;
// 	    lookupTable->SetTableValue(i, val, val, val, 0.0);
// 	  }
// 	for (int i = 81; i < 255; i++)
// 	  {
// 	    double val = i/255.0;
// 	    lookupTable->SetTableValue(i, val, val, val, 1.0);
// 	  }

	lookupTable->SetNumberOfColors(1024);
	lookupTable->SetSaturationRange(0.0,0.0);
	lookupTable->SetHueRange(0.00,0.00);
	lookupTable->SetValueRange(0.0,1.0);
	lookupTable->SetAlphaRange(1.0, 1.0);
	lookupTable->Build();

	for (int i = 0; i < 50 ; i++)
	  {
	    double val = i/1024.0;
	    lookupTable->SetTableValue(i, val, val, val, 0.0);
	  }
	

// 	double range[0];
// 	//mriBrainImageData->GetScalarRange(range);  // crash in Release mode
// 	range[0] = 0.0;
// 	range[1] = 4095.0;
// 	lookupTable->SetTableRange(range[0], range[1]);

	m_ImagePlanes[0]->SetLookupTable(lookupTable);
	m_ImagePlanes[1]->SetLookupTable(lookupTable);
	m_ImagePlanes[2]->SetLookupTable(lookupTable);
	m_ImagePlanes[3]->SetLookupTable(lookupTable);
	m_ImagePlanes[4]->SetLookupTable(lookupTable);
	m_ImagePlanes[5]->SetLookupTable(lookupTable);
    }
}


// ----------------------------------------------------------
- (void)setMRHeadInput:(vtkImageData *) volumeInput
{
    if (volumeInput)
    {
        NSLog(@"OrthoPlanesView::setMRHeadInput");

        mriHeadImageData = volumeInput;  
		
	double tableRange[2];
	tableRange[0] = 50.0;
	tableRange[1] = 2509.0;
        
        volumeOpacityFunction = vtkPiecewiseFunction::New();
        volumeOpacityFunction->ClampingOff(); // zero outside of table range
        volumeOpacityFunction->AddSegment(tableRange[0], 0, tableRange[1], 0.7);
        
        volumeColorFunction = vtkColorTransferFunction::New();
	//volumeColorFunction->AddHSVPoint(tableRange[0], 0.0, 0.0, 0.0);
	//volumeColorFunction->AddHSVPoint(tableRange[1], 0.0, 0.0, 1.0); 
	volumeColorFunction->SetColorSpaceToHSV();
	volumeColorFunction->AddHSVPoint( tableRange[0], .05, 0.6, 0.3);
	volumeColorFunction->AddHSVPoint( tableRange[1], .05, 0.1, 0.9);
        
	// pass opactiy and color functions to wlWidget
        [wlWidget setColorTransferFunction:volumeColorFunction];
        [wlWidget setOpacityFunction:volumeOpacityFunction];
                
        vtkVolumeProperty *volumeProperty = vtkVolumeProperty::New();
        volumeProperty->SetColor(volumeColorFunction);
        volumeProperty->SetScalarOpacity(volumeOpacityFunction);
        volumeProperty->SetInterpolationTypeToLinear();
        volumeProperty->ShadeOn();
        volumeProperty->SetAmbient(1.0);
        volumeProperty->SetDiffuse(0.7);
        volumeProperty->SetSpecular(0.5);
        volumeProperty->SetSpecularPower(50);
        
        //volumeMapper = vtkAtamaiOpenGLVolumeTextureMapper3D::New();
        volumeMapper = vtkFixedPointVolumeRayCastMapper::New();
        //volumeMapper = vtkVolumeGLSLRayCastMapper::New();
        volumeMapper->SetInput(mriBrainImageData);
        //volumeMapper->SetSampleDistance(0.5);
        //volumeMapper->SetMaximumSampleDistance(0.7);
        
        volume = vtkVolume::New();
        volume->SetMapper(volumeMapper);
        volume->SetProperty(volumeProperty);
        
        m_Renderer->AddVolume(volume);
        
        // Epilepsy-Case tuned skull stripper
        stripper = vtkAtamaiMRIBrainExtractor::New();
        stripper->SetInput(mriHeadImageData);
        
        brainMesh = vtkPolyData::New();
        stripper->GetOutput()->Update();
	brainMesh->DeepCopy(stripper->GetOutput());
        stripper->ScaledBrainMesh(brainMesh, 1.05);
		
	vtkAtamaiPolyDataToImageStencil2 *meshStencil = vtkAtamaiPolyDataToImageStencil2::New();
	meshStencil->SetInput(brainMesh);
		
	ctStencilledWithBrain = vtkImageStencil::New();
	ctStencilledWithBrain->SetInput(ctImageData);
	ctStencilledWithBrain->SetStencil(meshStencil->GetOutput());
	
	electrodeContourFilter = vtkContourFilter::New();
	electrodeContourFilter->SetInput(ctStencilledWithBrain->GetOutput());
	electrodeContourFilter->SetValue(0,2900);
	electrodeContourFilter->Update();
	
	electrodeTriangles = vtkTriangleFilter::New();
	electrodeTriangles->SetInput(electrodeContourFilter->GetOutput());
	electrodeTriangles->Update();
	
	electrodeStripper = vtkStripper::New();
	electrodeStripper->SetInput(electrodeTriangles->GetOutput());
	
	electrodeMapper = vtkPolyDataMapper::New();
	electrodeMapper->SetInput(electrodeStripper->GetOutput());
	electrodeMapper->SetScalarVisibility(0);
	
	
	
	vtkActor *electrodeActor = vtkActor::New();
	electrodeActor->SetMapper(electrodeMapper);
	electrodeActor->GetProperty()->SetColor(0,0,255);
	
	//m_Renderer->AddActor(electrodeActor); 
	
	
	
	vtkPolyDataMapper *brainMeshMapper = vtkPolyDataMapper::New();
	brainMeshMapper->SetInput(brainMesh);
	brainMeshMapper->SetScalarVisibility(0);
	
	brainMeshActor = vtkActor::New();
	brainMeshActor->SetMapper(brainMeshMapper);
	brainMeshActor->GetProperty()->SetColor(255,0,0);
	
	m_Renderer->RemoveActor(brainMeshActor); 
	
	
	electrodeMapper->SetClippingPlanes(clippingCubeRep->GetPlanes());
    }
}

- (IBAction)setCTElectrodeThreshold:(id)sender
{
	electrodeContourFilter->SetValue(0, [sender floatValue]);
    [self setNeedsDisplay:YES]; 
}


- (IBAction)setBrainMeshScale:(id)sender
{
    stripper->ScaledBrainMesh(brainMesh, [sender floatValue]);
    [self setNeedsDisplay:YES]; 
	
}


// ----------------------------------------------------------
- (void)setVolume:(vtkVolume *) theVolume
{
	if (theVolume)
	{
		NSLog(@"setVolume");
		
		
		
	}
	
}

@end
