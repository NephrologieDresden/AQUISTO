// Macro for manual selection of glomeruli in the tiles of a whole kidney section
// Friederike Kessel (2018)
// as part of "AQUISTO"

path=getArgument();
path=path+"\\";

roiManager("Show All with labels");
roiManager("Associate", "true");
roiManager("Centered", "false");
roiManager("UseNames", "false");
//liste aller Stainings
stainings=getFileList(path);
setTool(3);
stainings=Array.sort(stainings);

//for all stainings
for(j=0; j<stainings.length; j++){
	stainings[j]=substring(stainings[j], 0, lengthOf(stainings[j])-1);

	print(stainings[j]);

	//only if tiles are present
	if(File.exists(path+stainings[j]+"\\Tiles")==1){

		//List of all biopsy numbers in "Tiles"
		files=getFileList(path+stainings[j]+"\\Tiles");
		files=Array.sort(files);

		//tissue name
		tissues=getFileList(path+stainings[j]+"\\ROIs");
		tissues=Array.sort(tissues);
		Array.show(tissues);
		for(a=0; a<tissues.length; a++){
			if(startsWith(tissues[a], "Tiles_")){
				tissuesx=tissues[a];
				tissuesx=split(tissuesx, "_");
				tissuesx=tissuesx[1];
			}			
		}
		tissues=substring(tissuesx, 0, lengthOf(tissuesx)-1);
		
		for(i=0; i<files.length; i++){

			files[i]=substring(files[i], 0, lengthOf(files[i])-1);
			print(files[i]+" i="+i);
			if(File.exists(path+stainings[j]+"\\ROIs\\Tiles_"+tissues+"\\"+files[i]+".zip")==0){
			if(File.exists(path+stainings[j]+"\\ROIs\\"+tissues+"\\"+files[i]+".zip")==0){
			
				//open tiles as virtual stack		
				dir = getDirectory("temp")+files[i]+".txt";
				f = File.open(dir);
				index = 0;
				list = getFileList(path+stainings[j]+"\\Tiles\\"+files[i]);
				list=Array.sort(list);
				for (m=0; m<list.length; m++){      
				print(f, path+stainings[j]+"\\Tiles\\"+files[i]+"\\"+list[m]);
				}
				File.close(f);
				run("Stack From List...", "open="+dir+" use");

				//Manual selection of all glomeruli and user interaction
				waitForUser(tissues+" Selection", "Select all "+tissues+", then press OK");
	
				//Saving the ROI-Set
				roiManager("Save", path+stainings[j]+"\\ROIs\\Tiles_"+tissues+"\\"+files[i]+".zip");
				getDimensions(width, height, channels, slices, frames);
				ntiles=sqrt(slices);
				close();
				newImage("New", "8-bit black", width, height, 1);
				//recalculating ROI-set and saving
				for (k=0; k<roiManager("count"); ++k){
							roiManager("Select", k);
							roiname=Roi.getName;
							roiname=substring(roiname, 0, 4);
							roiname=parseInt(roiname);
							for(m=0; m<ntiles; ++m){
								for(n=0; n<ntiles; ++n){
									if(roiname==(ntiles*n)+m+1){
										roiManager("translate", n*width, m*height);
									}
								}
							}
							roiManager("Remove Slice Info");
							//Rename all ROIs
							roiManager("Select", k);
							roiManager("Rename", tissues+"_"+k+1);
				}
				roiManager("Save", path+stainings[j]+"\\ROIs\\"+tissues+"\\"+files[i]+".zip");
				
				//add to tissues if it hasnt been done yet
				count=roiManager("count"); 
				array=newArray(count); 
				for(x=0; x<count;x++) { 
					array[x] = x; 
				} 
				roiManager("Select", array); 
				roiManager("Combine");
				roiManager("Delete");
				roiManager("Open", path+stainings[j]+"\\ROIs\\Tissues\\"+files[i]+".zip");
				roiManager("Add");

				roiManager("Select", roiManager("count")-1);
				roiname=Roi.getName;
				if(!endsWith(roiname, tissues)){
					print("true");
					roiManager("Rename", roiManager("count")+"_"+tissues);
					roiManager("Save", path+stainings[j]+"\\ROIs\\Tissues\\"+files[i]+".zip");
				}		
				roiManager("Deselect");
				roiManager("Delete");

				close();
			}}
		}
	}
}
run("Quit");