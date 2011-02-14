#include "vtkVersion.h"
#include "vtkMINCImageReader.h"
#include "vtkDICOMImageReader.h"
#include "vtkLookupTable.h"
#include "vtkImageData.h"
#include "vtkImageReslice.h"
#include "vtkPolyData.h"
#include "vtkPolyDataReader.h"
#include "vtkAtamaiPolyDataToImageStencil2.h"
#include "vtkImageStencil.h"
#include "vtkMNIXFMReader.h"
#include "vtkVolumeProperty.h"
#include "vtkVolume.h"
#include "vtkColorTransferFunction.h"
#include "vtkPiecewiseFunction.h"
#include "vtkClippingCubeRepresentation.h"
#include "vtkClippingCubeWidget.h"
#include "vtkProperty.h"

#import "MainController.h"

@implementation MainController


- (IBAction)fileNew:(id)sender
{
}

- (IBAction)fileOpen:(id)sender
{
    NSLog(@"open a file!");
}


- (void) setupPipeline
{
    NSString *shortPath = @"~/AtamaiDemoData/anonymous";
	NSString *absolutePath = [shortPath stringByExpandingTildeInPath];
	NSString *mrFileName = [absolutePath stringByAppendingString:@"/patient_MR.mnc"];
	NSString *ctFileName = [absolutePath stringByAppendingString:@"/patient_CT.mnc"]; 
    NSString *meshFileName = [absolutePath stringByAppendingString:@"/patient_MR_mesh.vtk"]; 
    NSString *xfmFileName = [absolutePath stringByAppendingString:@"/MRI2CT.xfm"]; 
  
    /*NSString *shortPath = @"~/Desktop/JENNINGS";
	NSString *absolutePath = [shortPath stringByExpandingTildeInPath];
	NSString *mrFileName = [absolutePath stringByAppendingString:@"/JENNINGS_MR.mnc"];
	NSString *ctFileName = [absolutePath stringByAppendingString:@"/JENNINGS_CT.mnc"]; 
    NSString *meshFileName = [absolutePath stringByAppendingString:@"/JENNINGS_MR_mesh.vtk"]; 
    NSString *xfmFileName = [absolutePath stringByAppendingString:@"/MRI2CT.xfm"]; */

	char *buffer = new char[512];
    
    vtkMINCImageReader *mrReader = vtkMINCImageReader::New();
	[mrFileName getCString:buffer];
	mrReader->SetFileName( buffer );
	mrReader->Update();
	mrImageData = mrReader->GetOutput();
	mrImageData->Update();
	mrImageData->Register(NULL);
	mrReader->Delete();
	
	
    vtkMINCImageReader *ctReader = vtkMINCImageReader::New();
	[ctFileName getCString:buffer];
	ctReader->SetFileName( buffer );
    ctReader->Update();
	ctImageData = ctReader->GetOutput();
	ctImageData->Update();
	ctImageData->Register(NULL);
	ctReader->Delete();
    
    vtkPolyDataReader *meshReader = vtkPolyDataReader::New();
    [meshFileName getCString:buffer];
    meshReader->SetFileName( buffer );
    
    vtkPolyData *meshData = meshReader->GetOutput();
    meshData->Update();
    
    meshData->Register(NULL);
    meshReader->Delete();
    
    vtkAtamaiPolyDataToImageStencil2 *stencilFunction = vtkAtamaiPolyDataToImageStencil2::New();
    stencilFunction->SetInput(meshData);
    
    vtkImageStencil *stencil = vtkImageStencil::New();
    stencil->SetInput(mrImageData);
    stencil->SetStencil( stencilFunction->GetOutput() );
    
    vtkImageData *stencilData = stencil->GetOutput();
    stencilData->Update();
    
    stencilData->Register(NULL);
    stencilFunction->Delete();
    stencil->Delete();
    
    
    vtkMNIXFMReader *xfmReader = vtkMNIXFMReader::New();
    [xfmFileName getCString:buffer];
    xfmReader->SetFileName(buffer);
    
    reslice = vtkImageReslice::New();
    reslice->SetResliceTransform(xfmReader->GetTransform());
    reslice->SetInput(stencilData);
    if (ctImageData)
    {
        reslice->SetInformationInput(ctImageData);
    }
    reslice->Update();
    mriBrainImageData = vtkImageData::New();
    mriBrainImageData->DeepCopy(reslice->GetOutput());
    
    reslice->SetInput(mrImageData);
    reslice->Update();
    mriHeadImageData = reslice->GetOutput();
    mriHeadImageData->Register(NULL);
    
    double tableRange[2];
    mriHeadImageData->GetScalarRange(tableRange);
}

+ (void) initialize
{
    // Let the world know what vtk we are using...
    vtkVersion *vers = vtkVersion::New();
    NSString *versText = [[NSString alloc] initWithCString:vers->GetVTKSourceVersion()];
    NSLog(versText);
    vers->Delete();
    [versText release];
}

- (void) applicationWillFinishLaunching:(NSNotification *)aNotification
{
    NSLog(@"MainController-applicationWillFinishLaunching");
}

- (void) awakeFromNib
{
    [self setupPipeline];

    
    NSLog(@"MainController-awakeFromNib");

    [orthoPlanesView setCTInput:ctImageData]; // do ct first since mri resliced to match
    [orthoPlanesView setMRBrainInput:mriBrainImageData];
    [orthoPlanesView setMRHeadInput:mriHeadImageData];
	[wlWidget setMRInput:mrImageData];
}
@end
