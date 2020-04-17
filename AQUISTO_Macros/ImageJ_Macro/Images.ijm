// Macro to extract original size images from every scene of a .czi-file, crop them to the actual tissue area, exclude previously selected artifacts and create tiles if necessary
// Friederike Kessel (2019) as part of "AQUISTO"

argument=getArgument();
argument=split(argument, "*");
scaling=0.325;

datapath=argument[0]+"\\";
path=argument[1]+"\\";
CHANNEL=argument[2];
MAX=argument[3];
LUT=argument[4];
ntiles=argument[5];

run("Bio-Formats Macro Extensions");

setBatchMode(true);
print(path+" "+datapath);
channelsx=getFileList(path+"\\Histograms\\");
channelsx=Array.sort(channelsx);

if(roiManager("count")>0){roiManager("Deselect"); roiManager("Delete");}
		
	//list all files in  raw_images
	files=getFileList(path+"Raw_Images\\");
	files=Array.sort(files);

	//start loop for all files in raw_images
	for(i=0; i<files.length; i++){
	
	if(substring("["+files[i]+"]", lengthOf(files[i])-4, lengthOf(files[i]))!=".tif"){
		date=substring(files[i], 0,10);
		slide=substring(files[i], 11,15);
		scene=substring(files[i], 16,17);
		file=date+"__"+slide+".czi";
		
		biopsy=substring(files[i], 18,lengthOf(files[i])-1);


		if(File.exists(datapath+"RAW_DATA-new\\"+file)==1){
		if(File.exists(path+"Images\\"+biopsy)==0){
		print(i);
		
		id=datapath+"\\RAW_DATA-new\\"+file;
		Ext.setId(id);
		Ext.getSeriesCount(seriesCount);
	    
		//get number of series
		seriesnumber=seriesCount;
		//get the size for every image in the series
		Ysize=newArray(seriesnumber-2);		
		for(b=0; b<seriesnumber-2;b++){
			Ext.setSeries(b);
			Ext.getSizeY(sizeY);
			Ysize[b]=sizeY;
		}

		seriesone=newArray("1");
		//get the indices for the full sized images within this slide file	
		for(b=1; b<Ysize.length; b++){
			if(Ysize[b]>Ysize[b-1]){
			if(Ysize[b]>Ysize[b+1]){
				seriesone=Array.concat(seriesone, b+1);
			}}
		}
		Array.show(seriesone);

		//biopsy numbers on that slide

		biopsyArray=newArray(seriesone.length);
		for(b=0; b<seriesone.length; b++){			
			for(c=0; c<files.length; c++){
				datey=substring(files[c], 0,10);
				slidey=substring(files[c], 11,15);
				sceney=substring(files[c], 16,17);
				biopsy=substring(files[c], 18,lengthOf(files[c])-1);
				
				if(datey==date){
				if(slidey==slide){
				if(sceney==b+1){
					biopsyArray[b]=biopsy;
				}}}
			}
		}
		Array.show(biopsyArray);
				
		//start opening and saving the images
		for(b=0; b<seriesone.length; b++){
			
			biopsy=biopsyArray[b];
			
			if(biopsy!=0){
			if(File.exists(path+"Images\\"+biopsy)==0){
			if(File.exists(path+"Images\\"+biopsy+".tif")==0){
				seriestwo=parseInt(seriesone[b])+1;
				print(seriestwo);
				//brightfield
				if(substring(channelsx[0],0,1)!=1){
					run("Bio-Formats Importer", "open="+datapath+"\\RAW_DATA-new\\"+file+" color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT series_"+seriestwo);
				}else{
					run("Bio-Formats Importer", "open="+datapath+"\\RAW_DATA-new\\"+file+" color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT series_"+seriesone[b]);
				}
				
				imagelist=getList("image.titles");
				
				//Part 2:
				//a) If Medulla and Cortex Selection are available: Scale, Create Composites, Crop the Image (Delete Raw_Images file)
				//b) if Glomerular Selection is desired: Create Tiles (RGB Tiles for Immunofluorescence)
	
				if(File.exists(path+"\\ROIs\\Original_Tissues\\"+biopsy+".zip")==1){
					print("Create Images: i="+i+" Slide "+slide+" Scene "+scene);
					roiManager("Open", path+"\\ROIs\\Original_Tissues\\"+biopsy+".zip");
					print("series "+seriesone[b]+" biopsy "+biopsy);
					process_image();
				}
				if(roiManager("count")>0){roiManager("Deselect"); roiManager("Delete");}

				close("*");
			}}}
		}
	}}}
}



function process_image(){							
							//process image----------------------------------------------------------------------------------------------------------------------------------------------
							if(substring(channelsx[0],0,1)==1){
								run("Set Scale...", "distance=1 known="+scaling+" pixel=1 unit=µm");
							}else{
								run("Set Scale...", "distance=1 known=0.442 pixel=1 unit=µm");
							}
											
							//brightfield
							if(substring(channelsx[0],0,1)!=1){
								run("Stack to RGB");
								
								setBackgroundColor(255,255,255);
								roiManager("Select", 0);
								run("Clear Outside");	
								run("Crop");

								//save histogram 
								run("Clear Results");
								getStatistics(area, mean, min, max, std, hist);
							
								for(y=0; y<256; y++){
									setResult("Value",y,max/256*y);
									setResult("Count",y,hist[y]);
								}
								setOption("ShowRowNumbers", false);
								updateResults;  							
								selectWindow("Results");
								saveAs("Results", path+"\\Histograms\\"+channelsx[0]+"\\"+biopsy+".txt");

								saveAs("TIFF", path+"\\Images\\"+biopsy+".zip");


							}else{
															
							//for fluorescent images
								File.makeDirectory(path+"\\Images\\"+biopsy);
								setBackgroundColor(0,0,0);
								roiManager("Select", 0);
								run("Clear Outside", "stack");					
								run("Crop");
								
								stainchar=getFileList(path+"Histograms");
								stainchar=Array.sort(stainchar);
								if(stainchar.length>1){
									run("Stack to Images");
								}
								imagelist=getList("image.titles");
								Array.show(imagelist);
								
								//Renaming images according to information in macros
								for(x=0; x<stainchar.length; x++){
									run("Clear Results");
									stainchar[x]=substring(stainchar[x], 0, lengthOf(stainchar[x])-1);
									stains=split(stainchar[x], "_");
									n=stains[0];
									selectWindow(imagelist[n-1]);
									rename("Image"+stains[0]);

									if(lengthOf(stainchar[x])>3){
										
										run(stains[1]);
										if(stains[2]!="Brightfield"){
										
										//save histogram for all channels except brightfield
										getStatistics(area, mean, min, max, std, hist);
										
										for(y=0; y<256; y++){
											setResult("Value",y,max/256*y);
											setResult("Count "+stains[2],y,hist[y]);
										}
										setOption("ShowRowNumbers", false);
			  							updateResults; 
			  							selectWindow("Results");
			  							saveAs("Results", path+"\\Histograms\\"+stainchar[x]+"\\"+biopsy+".txt");
			  							saveAs("TIFF", path+"\\Images\\"+biopsy+"\\C"+stains[0]+"_"+stains[2]);
			  							rename("Image"+stains[0]);
			  							}
						
									}
								}		
							}

							if(File.exists(path+"\\Tiles\\"+biopsy)==0){
							if(File.exists(path+"\\Tiles\\")==1){
							
								File.makeDirectory(path+"\\Tiles\\"+biopsy);
								print("Create Tiles: i="+i+" "+biopsy);
								imagelist=getList("image.titles");


								if(substring(channelsx[0],0,1)==1){

									if(imagelist.length==0){
										open(path+"\\Images\\"+biopsy+"\\C"+CHANNEL+"_"+biopsy+".tif");
										rename("Image"+CHANNEL);
									}

									selectWindow("Image"+CHANNEL);
									run(LUT);
									setMinAndMax(0, MAX);
									run("Apply LUT");
									run("8-bit");

								}else{
									if(imagelist.length==0){
										open(path+"\\Images\\"+biopsy+".tif");
									}
								}

								n=ntiles;
								width = getWidth(); 
								height = getHeight(); 
								tileWidth = width / n; 
								tileHeight = height / n; 
								for (y = 0; y < n; y++) { 
									offsetY = y * height / n; 
									for (x = 0; x < n; x++) { 
										offsetX = x * width / n; 
										tileTitle = "Tile_"+ x + "x" + y; 
							 			makeRectangle(offsetX, offsetY, tileWidth, tileHeight);
										run("Duplicate...", "duplicate");
										saveAs("TIFF", path+"\\Tiles\\"+biopsy+"\\"+tileTitle);
							 			close();
									} 
								}
							
							//-----------------------------------------------------------------------------------------------------------------------------------------------------------
							}}
							close("*");

}


//run("Quit");