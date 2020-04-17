// Macro to choose represantative sample details for subsequent setting of processing parameters
// Friederike Kessel (2019) as part of "AQUISTO"

argument=getArgument();
argument=split(argument, "*");

path=argument[0]+"\\";
files=Array.slice(argument, 1, argument.length);
channelx=getFileList(path+"\\Histograms");
channelx=Array.sort(channelx);

File.makeDirectory(path+"Macros\\Samples\\");
File.makeDirectory(path+"Macros\\Samples\\Channels\\");
if(roiManager("count")>0){roiManager("deselect"); roiManager("delete");}
//Make selections in Previews, scale selection to original image
if(!File.exists(path+"Macros\\Samples\\ROIs.zip")){
	for(a=0; a<files.length; a++){
		open(path+"Preview\\"+files[a]);
		if(substring(channelx[0],0,1)==1){	
			run("Make Composite");
		}
		run("Enhance Contrast...", "saturated=0.01");
		if(substring(channelx[0],0,1)==1){				
			for(x=1; x<channelx.length; x++){
				run("Next Slice [>]");
				run("Enhance Contrast...", "saturated=0.01");					
			}
		}
		biopsy=substring(files[a], 0, lengthOf(files[a])-4);
		roiManager("Open", path+"ROIs\\Original_Tissues\\"+biopsy+".zip");
		newImage("Untitled", "8-bit black", 20000, 20000, 1);
		roiManager("Select", 0);
		if(substring(channelx[0],0,1)==1){	
			run("Scale... ", "x=0.0625 y=0.0625");
		}else{
			run("Scale... ", "x=0.125 y=0.125");
		}
		roiManager("update");
		
		close();
		roiManager("Select", 0);
		run("Clear Outside");
		roiManager("Select", 0);
		run("Crop");
		
		
		roiManager("Deselect");
		roiManager("Delete");
		
		if(File.exists(path+"Macros\\Samples\\ROIs.zip")){roiManager("Open", path+"Macros\\Samples\\ROIs.zip");}
		makeRectangle(200, 200, 125, 125);
		waitForUser("Select a representative area to set the parameters in the main image");
		
		getDimensions(width, height, channels, slices, frames);
		if(substring(channelx[0],0,1)==1){	
			run("Scale... ", "x=16 y=16");
			print("TRUE");
		}else{
			//run("Scale... ", "x=16 y=16");
			run("Scale... ", "x=8 y=8");
		}
		roiManager("Add");
		roiManager("Select", a);
		roiManager("Rename", biopsy);
		roiManager("Save", path+"Macros\\Samples\\ROIs.zip");
		roiManager("Deselect");
		roiManager("Delete");
		close("*");
	}
}

setBatchMode(true);
roiManager("Open", path+"Macros\\Samples\\ROIs.zip");
for(a=0; a<files.length; a++){
	biopsy=substring(files[a], 0, lengthOf(files[a])-4);

	//for fluorescent images
	if(substring(channelx[0], 0,1)==1){
		channellist=getFileList(path+"Images\\"+biopsy);
		channellist=Array.sort(channellist);
		for(b=0; b<channellist.length; b++){
			open(path+"Images\\"+biopsy+"\\"+channellist[b]);
			channellist[b]=substring(channellist[b], 0, lengthOf(channellist[b])-4);
			roiManager("Select", a);
			//run("Scale... ", "x=0.5 y=0.5");
			run("Crop");
			saveAs(path+"Macros\\Samples\\Channels\\"+channellist[b]+"_"+biopsy);
			close();
		}
	//brightfield
	}else{
		open(path+"Images\\"+biopsy+".tif");
		roiManager("Select", a);
		run("Crop");
		saveAs("TIFF", path+"Macros\\Samples\\Channels\\"+biopsy);
		close();
	}
}
roiManager("Deselect");
roiManager("Delete");
run("Quit");
