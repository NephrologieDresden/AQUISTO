// Macro for semiautomatic segmentation of tissue compartments in the kidney (Whole Kidney, Medulla and Cortex) as well as outlier exclusing
// Friederike Kessel (2018) as part of "AQUISTO"

path=getArgument();
path=path+"\\";

if(roiManager("count")>0){roiManager("deselect"); roiManager("delete");}
run("Colors...", "foreground=white background=black selection=green");
//get list of all stainings
stainings=getFileList(path);
stainings=Array.sort(stainings);


//for all stainings
for(j=0; j<stainings.length; j++){
	if(endsWith(stainings[j], "/")){
	stainings[j]=substring(stainings[j], 0, lengthOf(stainings[j])-1);
	}
	//only if the staining is complete
	if(File.exists(path+stainings[j]+"\\Images")==1){
	channels=getFileList(path+stainings[j]+"\\Histograms");
	//channels=newArray("a", "b", "c");
	channels=Array.sort(channels);
	//get list of all tissues, and the single tissue which is not selected in the preview
	tissues=getFileList(path+stainings[j]+"\\Results\\Total_Area\\");
	//tissues=newArray("1_Kidney/", "2_Medulla/", "3_Cortex/", "4_Glomeruli/", "5_Single_Glomeruli/");
	tissues=Array.sort(tissues);

	single_tissue=tissues[tissues.length-1];
	if(startsWith(single_tissue, tissues.length+"_Single_")){
		single_tissue=split(single_tissue, "_");
		single_tissue=single_tissue[2];
		single_tissue=substring(single_tissue, 0, lengthOf(single_tissue)-1);
	}else{single_tissue="none";}
	
	for(a=0; a<tissues.length; a++){
		tissues[a]=substring(tissues[a], 0, lengthOf(tissues[a])-1);
	}
	if(File.exists(path+stainings[j]+"\\Preview")==1){
		//list of all files in preview
		files=getFileList(path+stainings[j]+"\\Preview\\");
		files=Array.sort(files);
		for(i=0; i<files.length; i++){
		
			files[i]=substring(files[i], 0, lengthOf(files[i])-4);			
			print("Manual Tissue Selection: "+files[i]+", i="+i+"stainings: "+stainings[j]);
			
			if(File.exists(path+stainings[j]+"\\ROIs\\Original_Tissues\\"+files[i]+".zip")==0){

				open(path+stainings[j]+"\\Preview\\"+files[i]+".tif");
				setLocation(0,0,1500,1500);
				

				//prepare to select whole section
				if(substring(channels[0], 0,1)!=1){
					setLocation(0,0,1500,1500);
					run("RGB Color");
					

					//run("Invert");
					run("Subtract Background...", "rolling=50 light");
					run("Enhance Contrast...", "saturated=0.3");

					run("8-bit");
					//run("8-bit Color", "number=256");
					setMinAndMax(150, 255);
					run("Mean...", "radius=20");
					getStatistics(area, mean, min, max, std, histogram);
					setThreshold(0,mean);
					
					run("Convert to Mask");
					run("Remove Outliers...", "radius=20 threshold=100 which=Bright");
					setThreshold(1, 255);			
				}else{
					run("Make Composite");
					run("Subtract Background...", "rolling=50");
					run("Enhance Contrast...", "saturated=0.1");
					
					for(x=1; x<channels.length; x++){
						run("Next Slice [>]");
						run("Subtract Background...", "rolling=50");				
						run("Enhance Contrast...", "saturated=0.01");
						if(endsWith(channels[x], "Brightfield/")){
							setMinAndMax(65535,65535);
						}
					}

					//run("Duplicate...", "duplicate");
					setLocation(0,0,1500,1500);
					run("RGB Color");
					run("8-bit");
					run("Brightness/Contrast...");
					setMinAndMax(12, 20);
					run("Mean...", "radius=20");
					getStatistics(area, mean, min, max, std, histogram);
					setThreshold(mean, 255);
					run("Convert to Mask");
					run("Remove Outliers...", "radius=20 threshold=50 which=Dark");
					setThreshold(1, 255);
				}

				run("Create Selection");
				roiManager("Add");
				close();
				setTool("freehand");
				roiManager("Select", 0);

				//remove outliers
				waitForUser("Outliers", "Exclude outliers while pressing 'Alt'");
				if(substring(channels[0], 0,1)!=1){
					run("Scale... ", "x=8 y=8");
				}else{
					run("Scale... ", "x=16 y=16");
				}
				
				roiManager("Add");
				roiManager("Select", 0);
				roiManager("Delete");
				roiManager("Select", 0);

				roiManager("Rename", tissues[0]);
				run("Select None");

				//add additional tissues (except for single tissues
				for(a=1; a<tissues.length; a++){
					if(!endsWith(tissues[a], single_tissue)){
						roiManager("deselect");
						run("Select None");
						waitForUser(tissues[a], "Select the "+tissues[a]);
						if(substring(channels[0], 0,1)!=1){
							run("Scale... ", "x=8 y=8");
						}else{
							run("Scale... ", "x=16 y=16");
						}
						roiManager("Add");
	
						//just the overlap of selection with kidney
						roiManager("Select", newArray(0,a));
						roiManager("AND");
						roiManager("Add");
						roiManager("deselect");
						roiManager("Select", a);
						roiManager("Delete");
						roiManager("Select", a);
						roiManager("Rename", tissues[a]);
						
						//for further selections NOT the overlap with the other compartments
						if(a>1){
							//array of selections without 0
							tissue_ex=newArray(roiManager("count")-1);
							for(b=0; b<roiManager("count")-1; b++){
								tissue_ex[b]=b+1;
							}
							roiManager("Select", tissue_ex);
							roiManager("XOR");
							roiManager("Add");
							roiManager("deselect");
							roiManager("Select", a);
							roiManager("Delete");
							roiManager("Select", a);
							roiManager("Rename", tissues[a]);
						}
					}
				}

				roiManager("Save",path+stainings[j]+"\\ROIs\\Original_Tissues\\"+files[i]+".zip");
			
				//translate selection to cropped image
				newImage("New", "8-bit black", 20000, 20000, 1);
				roicount=newArray(roiManager("count"));
				
				for(a=0; a<roiManager("count"); a++){
					roicount[a]=a+roiManager("count");
				}
				roiManager("Select", 0);
				getSelectionBounds(x, y, width, height);
				for(a=0; a<roicount.length; a++){
					roiManager("Select", a);
					roiManager("translate", -x, -y);
				}
				close();
				
				//roiManager("Select", roicount);
				//roiManager("Delete");
				roiManager("Save",path+stainings[j]+"\\ROIs\\Tissues\\"+files[i]+".zip");
								
				roiManager("Deselect");
				roiManager("Delete");
				close();
			}
		}
	}
}}

run("Quit");