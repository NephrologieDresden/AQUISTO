// Macro to detect nuclei with marker controled watershed in the tissue section (DAPI Channel)
// and save them as a ROI-set
// Friederike Kessel (2019) as part of "AQUISTO"

argument=getArgument();
argument=split(argument, "*");
path=argument[0]+"\\";

//adjust variables for DAPI-Processing
	dapithreshold = argument[1];
	dapisigma = argument[2];
	dapinoise = argument[3];
	
run("Set Measurements...", "redirect=None");
run("ROI Manager...");
if(roiManager("count")>0){roiManager("Deselect"); roiManager("Delete");}		//empty ROIManager

	
setBatchMode(true);
//get File list
files=getFileList(path+"Images");
files=Array.sort(files);
//get organ name
tissue=getFileList(path+"Results\\Nuclear_ROIs\\");
tissue=Array.sort(tissue);
tissue=tissue[0];

for(a=0; a<files.length; a++){
	
	files[a]=substring(files[a], 0, lengthOf(files[a])-1);
	if(!File.exists(path + "Results\\Nuclear_ROIs\\" + tissue + "\\" + files[a]+".zip")){
		channelx=getFileList(path+"Images\\"+files[a]);
		channelx=Array.sort(channelx);
		//DAPI Channel
		for(b=0; b<channelx.length; b++){
			if(endsWith(channelx[b], "DAPI.tif")){
				open(path+"Images\\"+files[a]+"\\"+channelx[b]);
				watershed();
				roiManager("Deselect");
				roiManager("Delete");
				close("*");
				print(files[a] + " DAPI-Processing finished");
			}
		}
	}
}

function watershed(){
	//get organ name
	roiManager("open", path+"ROIs\\Tissues\\"+files[a]+".zip");
	tissue=call("ij.plugin.frame.RoiManager.getName", 0);
	roiManager("Deselect");
	roiManager("Delete");
	//start processing
	rename("DAPI.tif");
	run("Enhance Contrast", "saturated=0.01");
	run("8-bit");
	run("Select None");
	run("Subtract Background...", "rolling=35 sliding disable");
	run("Duplicate...", "title=Input");
	run("Duplicate...", "title=Maskx");
	run("Duplicate...", "title=Marker");
	close("DAPI.tif");
	
	//Process Edges
	selectWindow("Input");
	run("Median...", "radius=2");
	setThreshold(dapithreshold, 255); //define tresholds
	setOption("BlackBackground", false);
	run("Create Selection");
	run("Create Mask");
	close("Input");
	rename("Input");
	run("Find Edges");

	//Process Seed Points
	selectWindow("Marker");
	run("Gaussian Blur...", "sigma="+ dapisigma);
	run("Find Maxima...", "noise=" + dapinoise + " output=[Single Points]");
	close("Marker");
	selectWindow("Marker Maxima");
	rename("Marker");
		
	//Process Mask
	selectWindow("Maskx");
	run("Median...", "radius=2");
	setThreshold(dapithreshold, 255); //use the same tresholds as for edges
	run("Create Selection");
	run("Create Mask");
	close("Maskx");
	rename("Maskx");
		
	//Watershed
	run("Marker-controlled Watershed", "input=Input marker=Marker mask=Maskx binary calculate use");
	selectWindow("Input-watershed");
	setThreshold(2, 3.4e38);
	setOption("BlackBackground", true);
	run("Create Selection");
	run("Create Mask");
	close("Input-watershed");
	rename("Watershed");
	
	close("Marker");
	close("Input");
	close("Mask");
	rename("DAPI_Watershed.tif");

	run("Create Selection");
	roiManager("Add");

	//run("Analyze Particles...", "  show=Nothing exclude include add");
	roiManager("Save", path + "\\Results\\Nuclear_ROIs\\" + tissue + "\\" + files[a] + ".zip");
}
run("Quit");