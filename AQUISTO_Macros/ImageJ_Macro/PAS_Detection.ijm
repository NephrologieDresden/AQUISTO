// Macro for the processing, thresholding and measurement of PAS stained sections
// Friederike Kessel (2019) as part of "AQUISTO"

argument=getArgument();
//argument="x*1*50*0*0*0*50";
argument=split(argument, "*");
path=argument[0]+"\\";
//path=getDirectory("");


//assign variables for channel processing
histad=argument[2];
background=argument[3];
median=argument[4];
gauss=argument[5];
method=argument[6];
threshold=argument[7];

print(path+"Images\\");
channelx="PAS";
print(method);
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
Array.show(files);
for (a = 0; a < files.length; a++) {
	print(files[a]);
	files[a]=substring(files[a],0,lengthOf(files[a])-4);
	open(path+"Images\\"+files[a]+".tif");
	run("Select None");
	//colour deconvolution
	rename("Original");
	run("Subtract Background...", "rolling=50 light");
	run("Colour Deconvolution", "vectors=[H PAS]");
	
	close("Original-(Colour_3)");
	close("Original-(Colour_1)");
	close("Colour Deconvolution");
	run("Set Scale...", "distance=1 known=0.442 pixel=1 unit=µm");
	roiManager("Open", path + "ROIs\\Tissues\\" + files[a] + ".zip" );
	processFile();
	roiManager("Deselect");
	roiManager("Delete");
	close("*");
	run("Clear Results");
	print(files[a] + "-Processing finished");	
}

//local processing
function processFile() {
	print(files[a]);
	rename("Segmented");
	run("Invert");
	if(histad==1){
		roiManager("Select", 0);
		getHistogram(values, counts, 256);
		counts=Array.slice(counts, 1, counts.length);
		Array.getStatistics(counts, min, max, mean, std);
		for(e=0;e<counts.length;e++){
			if(counts[e]==max){
				setMinAndMax(values[e+1], 255);
				run("Apply LUT");
				print(values[e+1]);
			}
		}
	}
	if(background>0){run("Subtract Background...", "rolling="+background+" dark");}

	if(median>0){run("Median...", "radius="+median);}
	if(gauss>0){run("Gaussian Blur...", "sigma="+gauss);}
	
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
		setThreshold(threshold, 255);
		run("Create Selection");
		run("Create Mask");
		close("Segmented");
		rename("Segmented");
	}
	if(method==1){
		selectWindow("Segmented");
		setThreshold((sd+median)*threshold, 255);
		run("Create Selection");
		run("Create Mask");
		close("Segmented");
		rename("Segmented");
	}

	print(files[a] + "Processing finished");

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

	print("Measurement in regions finished");

//  for single tissue
// b)measure total areas of marker positivity
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

	}

// save a downscaled composite image of the segmented channel images
roiManager("Deselect");
roiManager("Delete");

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