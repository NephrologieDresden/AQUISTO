//Macro for preparing the czi-file images acquired by Axioscan Slidescan for Automatic Processing
//Friederike Kessel (2019) as part of "AQUISTO"

//Setting the experiment folder
path=getDirectory("Select the experiment folder");
close("*");
if(roiManager("count")>0){roiManager("Deselect"); roiManager("Delete");}

//list of all stainings
stainings=getFileList(path);
stainings=Array.sort(stainings);
Array.show(stainings);
setBatchMode(true);

//for all stainings

for(j=0; j<stainings.length; j++){
	stainings[j]=substring(stainings[j], 0, lengthOf(stainings[j])-1);
	print(stainings[j]);
	
	//list of all biopsy numbers in Raw_Images
	files=getFileList(path+stainings[j]+"\\Preview");
	files=Array.sort(files);
	Array.show(files);
	if(File.exists(path+stainings[j]+"\\Tiles\\")){
	
		//get title of single tissue
		tissues=getFileList(path+stainings[j]+"\\ROIs\\");
		for(a=0; a<tissues.length; a++){
			if(startsWith(tissues[a], "Tiles")){
				tissuesy=tissues[a];
				tissuesy=substring(tissuesy, 0, lengthOf(tissuesy)-1);
			}
		}
		tissues=split(tissuesy, "_");
		tissues=tissues[1];
		print(tissues);
		if(File.exists(path+stainings[j]+"\\Cropped_"+tissues)){
			File.makeDirectory(path+stainings[j]+"\\Cropped_"+tissues);
			File.makeDirectory(path+stainings[j]+"\\Cropped_"+tissues+"\\"+tissues+"_Collection");
		
			channelx=getFileList(path+stainings[j]+"\\Histograms");
			channelx=Array.sort(channelx);
			//start loop for all files
			for(i=0; i<files.length; i++){
				print(files[i]);
				print(i);
				if(startsWith(channelx[0], "1")){
					files[i]=substring(files[i], 0, lengthOf(files[i])-4);	//Fluorescent images in folder
				}else{
					files[i]=substring(files[i], 0, lengthOf(files[i])-4);	//BF images as .tifs
				}
				
			if(File.exists(path+stainings[j]+"\\Cropped_"+tissues+"\\"+files[i]+"\\")==0){
					
					
					if(File.exists(path+stainings[j]+"\\ROIs\\"+tissues+"\\"+files[i]+".zip")==1){
						File.makeDirectory(path+stainings[j]+"\\Cropped_"+tissues+"\\"+files[i]);

						print("Crop: i="+i+" "+files[i]);
		
						if(startsWith(channelx[0], "1")){						
							images=getFileList(path+stainings[j]+"\\Images\\"+files[i]);
							images=Array.sort(images);						
							channels="";
							for(a=0; a<images.length; a++){
								open(path+stainings[j]+"\\Images\\"+files[i]+"\\"+images[a]);
								rename(images[a]);
								if(a==0){
									channels="c"+a+1+"="+images[a];
								}else{
									channels=channels+" c"+a+1+"="+images[a];
								}
							}
							print(channels);
							run("Merge Channels...", channels+" create");					
						}else{						
							open(path+stainings[j]+"\\Images\\"+files[i]+".tif");
						}
						
						roiManager("Open", path+stainings[j]+"\\ROIs\\"+tissues+"\\"+files[i]+".zip");
						
						for (k=0; k<roiManager("count"); ++k) {
							roiManager("Select", k);
							roiname=getInfo("roi.name");
							getSelectionBounds(x, y, width, height);
							makeRectangle(x-(350-width/2), y-(350-height/2), 700, 700);
							run("Duplicate...", "duplicate");
							saveAs("Tiff", path+stainings[j]+"\\Cropped_"+tissues+"\\"+files[i]+"\\"+roiname+".tif");
							close();
						}
						roiManager("Deselect");
						roiManager("Delete");

						//array of cropped images
						run("Colors...", "foreground=black background=black selection=black");
		
						images=getFileList(path+stainings[j]+"\\Cropped_"+tissues+"\\"+files[i]+"\\");
						images=Array.sort(images);
		
						rows=-floor(-sqrt(images.length));
						columns=-floor(-images.length/rows);

						if(images.length>rows*columns){
							rows=rows+1;
						}

						print("Rows: "+rows);
						print("Columns: "+columns);
						print(images.length);
		
						for(b=0; b<images.length; b++){
							open(path+stainings[j]+"\\Cropped_"+tissues+"\\"+files[i]+"\\"+images[b]);
							run("Canvas Size...", "width=720 height=720 position=Center");
							rename(b);
					
							if(b==0){
								rename("dest");
								if(images.length>rows*columns){
									run("Canvas Size...", "width="+columns*720+" height="+(rows)*720+" position=Top-Left");
								}else{
									run("Canvas Size...", "width="+columns*720+" height="+(rows)*720+" position=Top-Left");
								}									
							}else{
								columnsx=floor(b/(rows)); //works
								rowsx=b-columnsx*(rows);								
								
								rename("source");
								run("Insert...", "source=source destination=dest x="+columnsx*720+" y="+rowsx*720);
								close("source");
							}				
						}
						print(i);
						saveAs("TIFF", path+stainings[j]+"\\Cropped_"+tissues+"\\"+tissues+"_Collection\\"+files[i]+".tif");
						close("*");
						
					}
				}
			}
		}
	}
}
run("Quit");
