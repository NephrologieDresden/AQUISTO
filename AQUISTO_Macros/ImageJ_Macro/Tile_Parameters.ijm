// Macro to set the parameters for tile creation for the selection of minor tissue compartments
// Friederike Kessel (2019)
// as part of "AQUISTO"

path=getArgument()+"\\";
datapath=split(path, "/");
datapath=Array.slice(datapath, 0, datapath.length-3); 

datapathx="";
for(a=0; a<datapath.length; a++){
	datapathx=datapathx+datapath[a]+"/";
}
datapath=datapathx;
//datapath=datapath[0]+"/";
print(datapath);
if(roiManager("count")>0){roiManager("Deselect"); roiManager("Delete");}

stainings=getFileList(path);
stainings=Array.sort(stainings);

Array.show(stainings);

for(j=0; j<stainings.length; j++){
	if(File.exists(path+stainings[j]+"\\Images")==1){
	//if it hasnt run before
	if(!File.exists(path+stainings[j]+"\\Macros\\Tile_Parameters\\")){
	print("Staining: "+stainings[j]);
	
		setTool(0);
	
	
		//only for fluorescent images
		channelsx=getFileList(path+stainings[j]+"\\Histograms");
		channelsx=Array.sort(channelsx);
		Array.show(channelsx);
		if(substring(channelsx[0],0,1)==1){
	
			imagefiles=getFileList(path+stainings[j]+"\\Raw_Images");
			imagefiles=Array.sort(imagefiles);
			date=substring(imagefiles[0], 0,10);
			slide=substring(imagefiles[0], 11,15);
			scene=substring(imagefiles[0], 16,17);
			biopsy=substring(imagefiles[0], 18,lengthOf(imagefiles[0])-1);
			file=date+"__"+slide+".czi";
	
			//get selection in preview
			open(path+stainings[j]+"\\Preview\\"+biopsy+".tif");
			run("Make Composite");
			for(a=1;a<channelsx.length; a++){
				run("Enhance Contrast...", "saturated=0.3");
				run("Next Slice [>]");
			}
			makeRectangle(200, 200, 125, 125);
			waitForUser("Select a rectangle of 125x125 px");
			roiManager("Add");
			
			roiManager("Select", 0);
			run("Scale... ", "x=16 y=16");
			roiManager("Add");
			
		File.makeDirectory(path+stainings[j]+"\\Macros\\Tile_Parameters\\");

		roiManager("Save", path+stainings[j]+"\\Macros\\Tile_Parameters\\ROIs.zip");
			roiManager("Deselect");
			roiManager("Delete");
			close();
		}
	}	
}}
setBatchMode(true);
//for one staining after the other open the corresponding .czi file and scene (1), crop the image to tile selection and save.
for(j=0; j<stainings.length; j++){
	if(File.exists(path+stainings[j]+"\\Images")==1){
	//only for fluorescent images
	channelsx=getFileList(path+stainings[j]+"\\Histograms");
	channelsx=Array.sort(channelsx);
	Array.show(channelsx);
	if(substring(channelsx[0],0,1)==1){


		imagefiles=getFileList(path+stainings[j]+"\\Raw_Images");
		imagefiles=Array.sort(imagefiles);
		date=substring(imagefiles[0], 0,10);
		slide=substring(imagefiles[0], 11,15);
		biopsy=substring(imagefiles[0], 18,lengthOf(imagefiles[0])-1);
		file=date+"__"+slide+".czi";
	
		if(!File.exists(path+stainings[j]+"\\Macros\\Tile_Parameters\\Tile.tif")){
		if(File.exists(path+stainings[j]+"\\Macros\\Tile_Parameters\\ROIs.zip")){
			run("Bio-Formats Importer", "open="+datapath+"RAW_DATA-new\\"+file+" color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT series_1");
			roiManager("open", path+stainings[j]+"\\Macros\\Tile_Parameters\\ROIs.zip");
			roiManager("Select",1);
			run("Crop");
			saveAs("TIFF",path+stainings[j]+"\\Macros\\Tile_Parameters\\Tile"); 
			roiManager("deselect");
			roiManager("delete");
			close("*");
		}}
	}
}}
setBatchMode(false);

//for one staining after the other create tile arrays and set the parameters
for(j=0; j<stainings.length; j++){
if(File.exists(path+stainings[j]+"\\Images")==1){
	//only for fluorescent images
//only for fluorescent images
	channelsx=getFileList(path+stainings[j]+"\\Histograms");
	channelsx=Array.sort(channelsx);
	Array.show(channelsx);
	if(substring(channelsx[0],0,1)==1){

		if(!File.exists(path+stainings[j]+"\\Macros\\Tile_Parameters\\Tile.txt")){
		if(File.exists(path+stainings[j]+"\\Macros\\Tile_Parameters\\Tile.tif")){	
			//open image
			open(path+stainings[j]+"Macros\\Tile_Parameters\\Tile.tif");
			run("Make Composite", "display=Composite");
			run("Split Channels");
			
			//start parameter testing
			imagelist=getList("image.titles");
			imagelist=Array.sort(imagelist);
			for(a=0; a<imagelist.length;a++){
				selectWindow(imagelist[a]);
				rename("Original");
	
				width=getWidth();
				height=getHeight();
				run("Canvas Size...", "width="+width+50+" height="+height+50+" position=Center");
				widthx=getWidth();
				heightx=getHeight();
	
				newImage("TileParameters_Channel"+a+1, "RGB black", 10*widthx, 5*heightx,1);
				
				//possible LUTS
				LUTS=newArray("Red", "Green", "Magenta", "Yellow", "Cyan", "Fire", "Blue", "Spectrum", "Ice", "Grays");
	
				for(b=0; b<5; b++){
					for(c=0; c<10; c++){
						selectWindow("Original");
						run("Duplicate...", "duplicate");
						setMinAndMax(0, 3000*(b+1));
						
						run(LUTS[c]);
						run("Apply LUT");
						run("RGB Color");
						rename("Source");
						run("Insert...", "source=Source destination=TileParameters_Channel"+a+1+" x="+c*widthx+" y="+b*heightx);
						close("Source");
						if(b==0){
							selectWindow("TileParameters_Channel"+a+1);
							setFont("SansSerif", 200);
							setColor("black");
							drawString("LUT="+LUTS[c], (c+0.3)*widthx, 300, "white");
						}
						selectWindow("Original");
					}
					selectWindow("TileParameters_Channel"+a+1);
					drawString("Max="+3000*(b+1), 10, (b+0.5)*heightx, "white");
				}
				close("Original");
			}
			run("Clear Results");
			waitForUser("Choose the channel, maximum value and LUT");
			fijichannel=getString("Choose the channel", 1);
			fijimax=getString("Choose the maximum value", 3000);
			fijilut=getString("Choose the LUT", "Fire");
			tileno=getString("Into how many columns/rows should the image be devided", "5");
			parameter=newArray("Channel", "Maximum", "LUT", "Tile Number");
			value=newArray(fijichannel, fijimax, fijilut, tileno);
			for(a=0; a<parameter.length; a++){
				setResult("Parameter", a, parameter[a]);
				setResult("Value", a, value[a]);
			}
			saveAs("Results", path+stainings[j]+"\\Macros\\Tile_Parameters\\Tile.txt");
			close("*");
		}}
	}
}}
run("Quit")