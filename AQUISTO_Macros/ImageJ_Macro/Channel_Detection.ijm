// Macro to process Multi-Channel-TIF from slidescanner and analyze DAPI-entitites
	// requires MorphoLibJ (INRA-IJPB Modeling and Digital Imaging lab)
	// potentially requires different plugins for thresholding (adaptive threshold by Qingzong TSENG)
	// requires predefined Tissue ROIs and Glomerular ROIs (created during the image preprocessing, Friederike Kessel)
	// requires predefined folder hierarchy (created according to the experimental characteristics with R, Friederike Kessel)
// creates interface with R analysis of data (Friederike Kessel)
// Friederike Kessel (2019) as part of "AQUISTO"
// Reads Channel structure of secondary markers and analzes All of them

// Define global variables, channel assignment

argument=getArgument();
argument=split(argument, "*");
path=argument[0]+"\\";

//assign variables for channel processing
channel="C"+argument[1];
channelx=argument[1];
histad=argument[2];
background=argument[3];
median=argument[4];
gauss=argument[5];
contrast=argument[6];

method=argument[7];
threshold=argument[8];
exblack=argument[9];
exwhite=argument[10];
dilate=argument[11];

run("Colors...", "foreground=white background=black selection=magenta");
run("Set Measurements...", "redirect=None");
run("ROI Manager...");
if(roiManager("count")>0){roiManager("Deselect"); roiManager("Delete");}		//empty ROIManager
close("*");

setBatchMode(true);
tissues=getFileList(path+ "/Results/Total_Area/");
tissues=Array.sort(tissues);
files=getFileList(path+"Images\\");
files=Array.sort(files);
for (a = 0; a < files.length; a++) {
	files[a]=substring(files[a],0,lengthOf(files[a])-1);
	open(path+"Images\\"+files[a]+"\\"+channel+".tif");
	roiManager("Open", path + "ROIs\\Tissues\\" + files[a] + ".zip" );
	processFile();
	if(roiManager("count")>0){roiManager("Deselect"); roiManager("Delete");}		//empty ROIManager
	close("*");
	run("Clear Results");
	print(files[a] + " "+channel+" -Processing finished");	
}

//local processing
function processFile() {
	print(files[a]);
	rename("Segmented");
	if(histad==1){
		getHistogram(values, counts, 256);
		counts=Array.slice(counts, 1, counts.length);
		Array.getStatistics(counts, min, max, mean, std);
		for(e=0;e<counts.length;e++){
			if(counts[e]==max){
				setMinAndMax(values[e+1], 65535);
				run("Apply LUT");
			}
		}
	}
	
	if(median>0){run("Median...", "radius="+median);}
	if(gauss>0){run("Gaussian Blur...", "sigma="+gauss);}
	if(background>0){run("Subtract Background...", "rolling="+background);}

	if(contrast>=0){
		run("Enhance Contrast...", "saturated="+contrast);
		run("Apply LUT");
	}
	
	run("Set Measurements...", "standard median redirect=None decimal=6");
	run("Duplicate...", "title=Original");
	roiManager("Select",0);		
	List.setMeasurements();
	median=List.getValue("Median");
	sd=List.getValue("StdDev");
	print(median+" "+sd);
	run("Select None");
	
	if(method==0){
		selectWindow("Segmented");
		setThreshold(threshold, 65535);
		run("Create Selection");
		run("Create Mask");
		close("Segmented");
		rename("Segmented");
	}
	if(method==1){
		selectWindow("Segmented");
		setThreshold((sd+median)*threshold, 65535);
		run("Create Selection");
		run("Create Mask");
		close("Segmented");
		rename("Segmented");
	}
	if(dilate==1){run("Dilate");}
	if(dilate==-1){run("Erode");}
	if(exblack>0){run("Remove Outliers...", "radius="+exblack+" threshold=50 which=Dark");}
	if(exwhite>0){run("Remove Outliers...", "radius="+exwhite+" threshold=50 which=Bright");}
	

	print(files[a] + " " + channel + " Processing finished");

// measurement of marker-area, nuclear marker coverage and nuclear marker intensity in the tissue
// Measure marker area, nuclear marker coverage and nuclear marker intensity for single nuclei in Medulla, Cortex and Glomeruli
	//number of tissues
	tissueno=roiManager("count");
	roiManager("Select", 0);
	organname=Roi.getName();

	run("Clear Results");

	//create an image with all the nuclei
	//a) only total area and intensity in tissue compartments (not involving nuclei)
	for(c=0; c<tissueno; c++){
		selectWindow("Segmented");
		roiManager("Select", c);
		tissue = getInfo("roi.name");
		// just marker area
		run("Set Measurements...", "area area_fraction decimal=6"); 
		roiManager("Measure");
		setResult("Tissue", c, tissue);

		selectWindow("Original");
		roiManager("Select", c);
		getStatistics(area, mean, min, max, std);
		setResult("Mean", c, mean);
	}
	saveAs("Results", path + "\\Results\\Total_Area\\" + organname + "\\" + channelx + "\\" + files[a] + ".txt");
	run("Clear Results");
	
	//b) nuclear coverage and intensity for tissue compartments
	if(File.exists(path + "\\Results\\Nuclear_ROIs\\")){

		//load nuclear rois
		roiManager("Open", path + "Results\\Nuclear_ROIs\\" + organname + "\\" + files[a] + ".zip" );

		//create image with nuclei
		selectWindow("Segmented");
		getDimensions(width, height, channels, slices, frames);
		newImage("All Nuclei", "8-bit black", width, height,1);
			
		roiManager("Select", tissueno);
		roiManager("Fill");
		//run("Invert");

		//start processing through all the tissue compartments
		for(c=0; c<tissueno; c++){
			
			
			selectWindow("All Nuclei");
			//run("Duplicate...", "title=Nuclei");

			//get ROIs in the tissue selection
			roiManager("Select", c);
			tissue = getInfo("roi.name");
			//run("Clear Outside");

			//Measure nuclear coverage
			run("Set Measurements...", "area shape area_fraction decimal=6 redirect=Segmented");
			run("Analyze Particles...", "display exclude include");
			saveAs("Results", path + "\\Results\\Nuclear_Coverage\\" + tissue + "\\" + channelx + "\\" + files[a] + ".txt");
			run("Clear Results");
			
			//Measure nuclear coverage
			run("Set Measurements...", "mean decimal=6 redirect=Original");
			run("Analyze Particles...", "display exclude include");
			saveAs("Results", path + "\\Results\\Nuclear_Intensity\\" + tissue + "\\" + channelx + "\\" + files[a] + ".txt");
			run("Clear Results");

			//end
			close("Nuclei");
		}
	}
	print("Measurement in regions finished");

//  for single tissue
// c)measure total areas of marker positivity
	if(File.exists (path + "Tiles\\")){

		//get name of single tissue
		roiManager("Select", tissueno-1);
		singletissue=getInfo("roi.name"); 		//x_subtissue
		singletissuex=split(singletissue, "_");
		singletissuex=singletissuex[1]; 		//subtissue

		//delete tissue rois
		roiManager("Deselect");
		roiManager("Delete");
		
		//open roiset for gloms
		roiManager("Open", path + "ROIs\\"+singletissuex+"\\" + files[a] + ".zip" );
		glomcount=roiManager("count");

		//total area/intensity
		for (c = 0; c < glomcount; c++){
			selectWindow("Segmented");
			roiManager("Select", c);
			glomno = getInfo("roi.name");
			// just marker area
			run("Set Measurements...", "area area_fraction decimal=6 redirect=None");
			roiManager("Measure");
			setResult(singletissuex, c, glomno);

			selectWindow("Original");
			roiManager("Select", c);
			getStatistics(area, mean, min, max, std);
			setResult("Mean", c, mean);
		}
		
		saveAs("Results", path + "\\Results\\Total_Area\\"+tissueno+1+"_Single_"+singletissuex+ "\\" + channelx + "\\" + files[a] + ".txt");
		run("Clear Results");
	
		//nuclear coverage/intensity
		if(File.exists(path + "\\Results\\Nuclear_ROIs\\")){
			File.makeDirectory(path+"Results\\Nuclear_Coverage\\"+tissueno+1+"_Single_"+singletissuex+"\\"+ channelx + "\\"+files[a]);
			File.makeDirectory(path+"Results\\Nuclear_Intensity\\"+tissueno+1+"_Single_"+singletissuex+"\\" + channelx + "\\"+files[a]);
			
			for (c = 0; c < glomcount; c++){				
				//get particles in selection
				selectWindow("All Nuclei");
				//run("Select None");
				//run("Duplicate...", "title=Nuclei");
				roiManager("Select", c);
				glomno = getInfo("roi.name");
				//run("Clear Outside");

				//measure coverage
				run("Set Measurements...", "area shape area_fraction decimal=6 redirect=Segmented");
				run("Analyze Particles...", "  display exclude include");
				saveAs("Results", path+"Results\\Nuclear_Coverage\\"+tissueno+1+"_Single_"+singletissuex+"\\"+ channelx + "\\"+files[a]+"\\"+glomno+".txt");
				run("Clear Results");

						
				//measure intensity
				run("Set Measurements...", "mean decimal=6 redirect=Original");
				run("Analyze Particles...", "  display exclude include");				
				saveAs("Results", path+"Results\\Nuclear_Intensity\\"+tissueno+1+"_Single_"+singletissuex+"\\"+ channelx + "\\"+files[a]+"\\"+glomno+".txt");
				run("Clear Results");

				//close("Nuclei");
			}
		}
	}

// save a downscaled composite image of the segmented channel images
if(roiManager("Count")>0){
	roiManager("Deselect");
	roiManager("Delete");
}


File.makeDirectory(path+"Results\\Processed_Overview\\"+files[a]);
selectImage("Segmented");
setThreshold(1, 255);
run("Create Selection");
type = selectionType();
print(type);
if(type!=-1){
	roiManager("Add");
	roiManager("Save", path+"Results\\Processed_Overview\\"+files[a]+"\\"+channelx+".zip");
}
} // end of function

print("Measurement End");
run("Quit");