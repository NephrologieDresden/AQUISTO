// Macro to set the parameters for the processing and thresholding of immunofluorescent sections
// Friederike Kessel (2019) as part of "AQUISTO"

argument=getArgument();
argument=split(argument, "*");

path=argument[0]+"\\";
channel=argument[1];

print(channel);
setTool("line");
files=getFileList(path+"Macros\\Samples\\Channels\\");
files=Array.sort(files);
Array.show(files);

	first=getBoolean("Go back to creating an array for the first image");
	if(first==1){
		firstRun();	
	}
	waitForUser("Choose: Background, Median or Gauss, Threshold, Particles to be excluded");
	if(first==1){
		close("Original");
	}
	histad=getNumber("Adapt histogram, (0=no, 1=yes)", 0);
	background=getNumber("Which radius for background substraction (0 for none)", 50);
	median=getNumber("Which radius for median filter (0 for none)", 0);
	gauss=getNumber("Which sigma for gaussian filter (0 for none)", 0);
	contrast=getNumber("Which setting for enhanced contrast (-1 for none)", 0);
	method=getNumber("Which method for thresholding (0=fixed, 1=adaptive via median)", 0);
	if(method==0){
		threshold=getNumber("Which fixed threshold", 5000);
	}
	if(method==1){
		threshold=getNumber("Which factor for median and sd", 3);
	}
	dilated=getNumber("Should the signal be dilated (1 for yes, 0 for no, -1 for erode)", 0);
	excludedark=getNumber("Exclude black outliers (0 for none, 10 recommended)",0);
	excludebright=getNumber("Exclude white outliers (0 for none, 10 recommended)",0);
	

	secondRun();
	
	waitForUser("Check the results");	
	second=getBoolean("Processing successful?");

//repeat
while(second==0){
	close("Original");
	close("Segmented");
	close("Processed");

	first=getBoolean("Go back to creating an array for the first image");
	if(first==1){
		firstRun();
	}
	histad=getNumber("Adapt histogram, (0=no, 1=yes)",0);
	background=getNumber("Which radius for background substraction (0 for none)", 50);
	median=getNumber("Which radius for median filter (0 for none)", 0);
	gauss=getNumber("Which sigma for gaussian filter (0 for none)", 0);
	contrast=getNumber("Which setting for enhanced contrast (-1 for none)", 0);
	method=getNumber("Which method for thresholding (0=fixed, 1=adaptive via median)", 0);
	if(method==0){
		threshold=getNumber("Which fixed threshold", 5000);
	}
	if(method==1){
		threshold=getNumber("Which factor for median and sd", 3);
	}
	dilated=getNumber("Should the signal be dilated (1 for yes, 0 for no, -1 for erode)", 0);
	excludedark=getNumber("Exclude black outliers (0 for none, 10 recommended)",0);
	excludebright=getNumber("Exclude white outliers (0 for none, 10 recommended)",0);
	

	secondRun();
	waitForUser("Check the results");	
	second=getBoolean("Processing successful?");
}
close("*");

//write parameter table
if(second==1){
	run("Clear Results");
	parameters=newArray("HistAd","Background", "Median", "Gauss", "Contrast", "Method", "Threshold", "Excludedark", "Excludebright", "Dilate");
	values=newArray(histad, background, median, gauss,contrast,  method, threshold, excludedark, excludebright, dilated);
	for(a=0; a<parameters.length; a++){
		setResult("Parameters", a, parameters[a]);
		setResult("Values", a, values[a]);
	}
	for(a=0; a<files.length; a++){ 
		count=0;
		if(startsWith(files[a], channel)){
		if(!endsWith(files[a], ".zip")){
			count=count+1;
			if(count==1){
				channely=split(files[a],"_");
				channelz=channely[0]+"_"+channely[1];
				channelz=substring(channelz,1,lengthOf(channelz));
			}
		}}
	}
	print(channelz);
	updateResults();
	selectWindow("Results");

	saveAs("Results", path+"Macros\\Processing\\"+channelz+".txt");
}

//array of different parameter settings for one image
function firstRun(){
	count=0;
	for(a=0; a<files.length; a++){
		if(startsWith(files[a], channel)){
		if(!endsWith(files[a], ".zip")){

			count=count+1;
			if(count==1){
			  channelx=substring(files[a],0,lengthOf(files[a])-4);
			  channelx=split(files[a], "_");
			  channelx=channelx[0]+"_"+channelx[1];
			  
				open(path+"Macros\\Samples\\Channels\\"+files[a]);
				print("First general run");
				rename("Original");
				width=getWidth();
				height=getHeight();
				run("Canvas Size...", "width="+width+50+" height="+height+50+" position=Center");
				widthx=getWidth();
				heightx=getHeight();
								
				threshold_method=newArray("Fixed", "Global median adaptive", "Fixed with histogram adaption", "Global median adaptive with histogram adaption");

				for(d=0; d<4; d++){ //different thresholding methods and adaption of histogram in beginning
					newImage("First Run "+threshold_method[d], "8-bit black", 9*widthx, 9*heightx,1);
					for(b=0; b<9; b++){	//different preprocessing steps
						selectWindow("Original");

						for(c=0; c<9; c++){		//different thresholds
							selectWindow("Original");
							run("Duplicate...", " ");

							if(d>1){	//histogram adaption
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
									
							if(b==0){string="None";};
							if(b==1){run("Gaussian Blur...", "sigma=2"); string="Sigma=2";};
							if(b==2){run("Median...", "radius=2"); string="Median=2";};
							if(b==3){run("Subtract Background...", "rolling=20"); string="Background=20";};
							if(b==4){run("Subtract Background...", "rolling=20"); run("Gaussian Blur...", "sigma=2"); string="Background=20, Sigma=2";};
							if(b==5){run("Subtract Background...", "rolling=20"); run("Median...", "radius=2"); string="Background=20, Median=2";};
							if(b==6){run("Subtract Background...", "rolling=50"); string="Background=50";};
							if(b==7){run("Subtract Background...", "rolling=50"); run("Gaussian Blur...", "sigma=2"); string="Background=50, Sigma=2";};
							if(b==8){run("Subtract Background...", "rolling=50"); run("Median...", "radius=2"); string="Background=50, Median=2";};
								
							rename("Done");
							print(string);
							if(c==0){
								//get 50th percentile for threshold
								run("Set Measurements...", "median standard"); 
								List.setMeasurements();
								percentile=List.getValue("Median");
								sd=List.getValue("StdDev");								
								median=percentile;
							}

							if(d==0){	//for fixed threshold
								if(c>0){percentile=percentile+0.25*percentile;}
							
								setThreshold(percentile, 65535);
								run("Create Selection");
								run("Create Mask");
								close("Done");
							
								rename("Done");
							}
							if(d==2){								
								if(c>0){percentile=percentile+0.25*percentile;}
								setThreshold(percentile, 65535);
								run("Create Selection");
								run("Create Mask");
								close("Done");							
								rename("Done");
							}

							if(d==1){	//threshold adapted to median and sd
								threshold=(median+sd)*(0.5*c+1);
								setThreshold(threshold, 65535);
								run("Create Selection");
								run("Create Mask");
								close("Done");							
								rename("Done");
							}
							if(d==3){	//threshold adapted to median and sd
								threshold=(median+sd)*(0.5*c+1);
								setThreshold(threshold, 65535);
								run("Create Selection");
								run("Create Mask");
								close("Done");							
								rename("Done");
							}

							if(d==4){ //local adaptive threshold
								
							}
							
							run("Insert...", "source=Done destination=[First Run "+threshold_method[d]+"] x="+c*widthx+" y="+b*heightx);
							setFont("SansSerif", 100, "bold");
							setColor("black");
							if(b==0){
								selectWindow("First Run "+threshold_method[d]);
								setFont("SansSerif", 100);
								setColor("black");
								if(d==0){ //fixed TS
									drawString("Threshold="+percentile, (c+0.2)*widthx, 100, "white");
								}
								if(d==2){ //fixed TS
									drawString("Threshold="+percentile, (c+0.2)*widthx, 100, "white");
								}								
								if(d==1){ //adaptive median+sd
									drawString("Threshold=(Median+SD)*"+(0.5*c+1), (c+0.2)*widthx, 100, "white");
								}
								if(d==3){ //adaptive median+sd
									drawString("Threshold=(Median+SD)*"+(0.5*c+1), (c+0.2)*widthx, 100, "white");
								}							
							}
								
							close("Done");
							if(c==0){
								selectWindow("First Run "+threshold_method[d]);
								setFont("SansSerif", 100, "bold");
								setColor("black");
								drawString(string, 100, (b+0.2)*heightx, "white");
							}
						}
						
					}
				}
			}
		}}
	}
}

//apply chosen parameters to all images of the channel
function secondRun(){
	count=0;
	for(a=0; a<files.length; a++){
		if(startsWith(files[a], channel)){
		if(!endsWith(files[a], ".zip")){
			count=count+1;
		}}
	}
	piccount=count;
	print(piccount);
	count=0;
	
	//Apply these settings to all other images in samples
	for(a=0; a<files.length; a++){
		if(startsWith(files[a], channel)){
		if(!endsWith(files[a], ".zip")){
			count=count+1;
			if(count==1){
				newImage("Original", "16-bit black", piccount*2050, 2000,1);
				newImage("Processed", "16-bit black", piccount*2050, 2000,1);
				newImage("Segmented", "8-bit black", piccount*2050, 2000,1);
				channelx=substring(files[a],0,lengthOf(files[a])-4);
				channelx=split(files[a], "_");
				channelx=channelx[0]+"_"+channelx[1];
			}

			run("Set Measurements...", "median standard"); 
			open(path+"Macros\\Samples\\Channels\\"+files[a]);
			rename("OriginalImage");
			print("First general run");
			makeRectangle(0,0,2000,2000);
			run("Crop");
			run("Canvas Size...", "width=2050 height=2050 position=Center");

			setFont("SansSerif", 50, "bold");
			setColor("black");

			//measure median+sd in original image
			List.setMeasurements();
			medianoriginal=List.getValue("Median");
			sdoriginal=List.getValue("StdDev");
			run("Duplicate...", "title=ProcessedImage");


			//First part, processing steps--------------------------------------------------------------------------------------------
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
			

			if(contrast>=0){run("Enhance Contrast...", "saturated="+contrast); run("Apply LUT");}

			//End first part--------------------------------------------------------------------------------------------	
			//median+sd in processed image
			List.setMeasurements();
			medianprocessed=List.getValue("Median");
			sdprocessed=List.getValue("StdDev");
				
			run("Duplicate...", "title=SegmentedImage");

			//Second part processing steps--------------------------------------------------------------------------------------------
			if(method==0){
				selectWindow("SegmentedImage");
				
				setThreshold(threshold, 65535);
				run("Create Selection");
				run("Create Mask");
				close("SegmentedImage");
				rename("SegmentedImage");
			}
			if(method==1){
				selectWindow("SegmentedImage");
				setThreshold((sdprocessed+medianprocessed)*threshold, 65535);
				run("Create Selection");
				run("Create Mask");
				close("SegmentedImage");
				rename("SegmentedImage");
			}
			
			if(excludedark>0){run("Remove Outliers...", "radius="+excludedark+" threshold=50 which=Dark");}
			if(excludebright>0){run("Remove Outliers...", "radius="+excludebright+" threshold=50 which=Bright");}
			if(dilated==1){run("Dilate");}
			if(dilated==-1){run("Erode");}

			//End second part--------------------------------------------------------------------------------------------
			//insert into arrays

			//original
			selectWindow("OriginalImage");
			drawString("Median="+medianoriginal+", Std="+sdoriginal, 100, 100, "white");
			run("Insert...", "source=OriginalImage destination=Original x="+(count-1)*2050+" y=0");

			selectWindow("SegmentedImage");
			run("Insert...", "source=SegmentedImage destination=Segmented x="+(count-1)*2050+" y=0");
			
			selectWindow("ProcessedImage");
			drawString("Median="+medianprocessed+", Std="+sdprocessed, 100, 100, "white");
			run("Insert...", "source=ProcessedImage destination=Processed x="+(count-1)*2050+" y=0");

			close("ProcessedImage");
			close("SegmentedImage");
			close("OriginalImage");
		}}
	}
}


run("Quit");
