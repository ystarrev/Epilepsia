#include "WLWidgetView.h"

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
#include "vtkDataSetMapper.h"
#include "vtkActor.h"
#include "vtkImageOrthoPlanes.h"
#include "vtkImageReslice.h"
#include "vtkMNIXFMReader.h"
#include "vtkColorTransferFunction.h"
#include "vtkPieceWiseFunction.h"
#include "vtkImageAccumulate.h"
#include "vtkImageCanvasSource2D.h"
#include "vtkImageActor.h"
#include "vtkActor2D.h"
#include "vtkImageMapper.h"
#include "vtkImageEllipsoidSource.h"
#include "vtkPointData.h"
#import "OrthoPlanesView.h"

@implementation WLWidgetView

// ----------------------------------------------------------
- (id)initWithFrame:(NSRect)frame
{
	self = [super initWithFrame:frame];
	
	if (self) 
    {
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
		
		// This is the ONLY place we need to explicitly cast our render window
		// to a vtkCocoaRenderWindow
		vtkCocoaRenderWindow*  cocoaRenWin = dynamic_cast<vtkCocoaRenderWindow*>(m_RenderWindow);
		[self setVTKRenderWindow:cocoaRenWin];
    }
	
	return self;
}

// ----------------------------------------------------------
- (void)drawRect:(NSRect)theRect
{
	// The first time we draw, finish setting up the vtk pipeline
	if (m_RenderWindowInteractor && (m_RenderWindowInteractor->GetInitialized() == NO))
    {
        // set up the clut Menu
        NSFileManager *manager = [NSFileManager defaultManager];
        [clutMenu removeAllItems];
		NSString *resourceDirPath = [[NSBundle mainBundle] resourcePath];
		NSString *clutDirPath = [resourceDirPath stringByAppendingString:@"/CLUTs"];
		NSArray *cluts = [manager directoryContentsAtPath:clutDirPath];
        [clutMenu addItemsWithTitles:cluts];        
        
        // get vtk stuff initialized and set up
		m_RenderWindow->SetWindowId([self window]);
		m_RenderWindow->SetDisplayId(self);
		m_RenderWindowInteractor->Initialize();
	}      
	
	// vtkCocoaGLView does the drawing
	[super drawRect:theRect];
}

- (void)updateView:(NSNotification *)notification
{
    [self setNeedsDisplay:YES]; 
}

// ----------------------------------------------------------
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

//-----------------------------------------------------------
- (void)setMRVolumeWL:(float)window :(float)level
{
    [self setNeedsDisplay:YES]; 
}

//-----------------------------------------------------------
-(void)setColorTransferFunction:(vtkColorTransferFunction *) theColorFunction
{
	colorFunction = theColorFunction;
}

//-----------------------------------------------------------
-(void)setOpacityFunction:(vtkPiecewiseFunction *) theOpacityFunction
{
	opacityFunction = theOpacityFunction;
}


-(void)fixWindowLevel
{
	NSLog(@"WLWidget::fixWindowLevel win=%f lev=%f",windowSetting, levelSetting);
	histoCanvas->SetDrawColor(0,0,0);
	histoCanvas->FillBox(0,255,0,127);
	histoCanvas->SetDrawColor(255,0,0);
	for(int x=0; x<255; x++)
	{
		histoCanvas->DrawSegment(x,0,x,int(histoData->GetScalarComponentAsDouble(x,0,0,0)/scaleFactor));
	}
	double xScale=8.0;
	histoCanvas->SetDrawColor(0,255,0);
	histoCanvas->DrawSegment(0,0,(levelSetting-windowSetting/2)/xScale,0);
	histoCanvas->DrawSegment((levelSetting-windowSetting/2)/xScale,0,
							 (levelSetting+windowSetting/2)/xScale,256);
	histoCanvas->DrawSegment((levelSetting+windowSetting/2)/xScale,255,511,255);
	[self setNeedsDisplay:TRUE];
	
	colorFunction->BuildFunctionFromTable(levelSetting-windowSetting/2.0,
                                          levelSetting+windowSetting/2.0,
                                          255,
                                          (double *) &table);
	colorFunction->Modified();
	
	opacityFunction->RemoveAllPoints();
	opacityFunction->AddPoint(levelSetting-windowSetting/2.0,0.0);
	opacityFunction->AddPoint(levelSetting+windowSetting/2.0,1.0);	
	opacityFunction->Modified();
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateViewNotification" object:nil];
}

- (IBAction) clutMenu:(NSPopUpButton *)sender
{
    NSDictionary *aCLUT;
    NSArray *redArray, *greenArray, *blueArray;
    int i;
    
    
    NSString *shortPath = @"~/Development/miniasp/CLUTs/";
    NSString *clutDirPath = [shortPath stringByExpandingTildeInPath];
    
    NSString *selectedItem = [clutDirPath stringByAppendingString:@"/"];
    selectedItem = [selectedItem stringByAppendingString:[sender titleOfSelectedItem]];
    
    aCLUT = [NSDictionary dictionaryWithContentsOfFile:selectedItem];
    redArray = [aCLUT objectForKey:@"Red"];
    greenArray = [aCLUT objectForKey:@"Green"];
    blueArray = [aCLUT objectForKey:@"Blue"];
    for (i=0; i<256; i++)
    {
        table[i][0]=[[redArray objectAtIndex: i] floatValue]/255.0;
        table[i][1]=[[greenArray objectAtIndex: i] floatValue]/255.0;
        table[i][2]=[[blueArray objectAtIndex: i] floatValue]/255.0;
    }
    
    colorFunction->BuildFunctionFromTable(levelSetting-windowSetting/2.0,
                                          levelSetting+windowSetting/2.0,
                                          255,
                                          (double *) &table);
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateViewNotification" object:nil];

}

- (IBAction)levelSlider:(id)sender
{    
    if ([sender floatValue] != levelSetting)
    {
        levelSetting = [sender floatValue];
        [self fixWindowLevel];
    }
}



- (IBAction)windowSlider:(id)sender
{
    if ([sender floatValue] != windowSetting)
    {
        windowSetting = [sender floatValue];
        [self fixWindowLevel];
    }
}


// ----------------------------------------------------------
- (void)setMRInput:(vtkImageData *) volumeInput
{
    if (volumeInput)
    {
		NSLog(@"WLWidget setMRInput");
		
		double tableRange[2];
		volumeInput->GetScalarRange(tableRange);
		
		NSLog(@"Table range:(%f,%f)",tableRange[0],tableRange[1]);
		
		vtkImageAccumulate *accumulate  = vtkImageAccumulate::New();
		accumulate->SetInput(volumeInput);
		
		accumulate->SetComponentExtent(0,255,0,0,0,0);
		accumulate->SetComponentSpacing(3,1,1);
		accumulate->SetComponentOrigin(0,0,0);
		accumulate->Update();
		
		vtkImageAccumulate *histoaccumulate = vtkImageAccumulate::New();
		histoaccumulate->SetInput(accumulate->GetOutput());
		histoaccumulate->Update();
		
		double hist2Mean[3];
		double hist2SD[3];
		double histMean[3];
		double histSD[3];
		accumulate->GetMean(histMean);
		accumulate->GetStandardDeviation(histSD);
		histoaccumulate->GetMean(hist2Mean);
		histoaccumulate->GetStandardDeviation(hist2SD);
		NSLog(@"HistMean:%f",histMean[0]);
		NSLog(@"HistSD:%f",histSD[0]);
		NSLog(@"Hist2Mean:%f",hist2Mean[0]);
		NSLog(@"Hist2SD:%f",hist2SD[0]);
        
		histoCanvas = vtkImageCanvasSource2D::New();
		histoCanvas->SetNumberOfScalarComponents(3);
		histoCanvas->SetScalarType(3);
		histoCanvas->SetExtent(0,511,0,255,0,0);
		histoCanvas->SetDrawColor(0,0,0);
		histoCanvas->FillBox(0,511,0,255);
		
		histoData = accumulate->GetOutput();
		double maxData = hist2Mean[0]*3;
		scaleFactor = maxData/512;
		
		histoCanvas->SetDrawColor(255,0,0);
		for(int x=0; x<255; x++)
		{
			histoCanvas->DrawSegment(x,0,x,int(histoData->GetScalarComponentAsDouble(x,0,0,0)/scaleFactor));
		}
		
		vtkImageMapper *canvasMapper = vtkImageMapper::New();
		canvasMapper->SetInput(histoCanvas->GetOutput());
		canvasMapper->SetColorWindow(255);
		canvasMapper->SetColorLevel(127);
		
		vtkActor2D *canvasActor = vtkActor2D::New();
		canvasActor->SetMapper(canvasMapper);
		canvasActor->SetPosition(0,0);
		
		m_Renderer->AddActor2D(canvasActor);
        
    }
    
}

@end
