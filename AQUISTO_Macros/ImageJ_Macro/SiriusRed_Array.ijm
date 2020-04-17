// Macro to set the parameters for the processing and thresholding of sirius red stained sections
// Friederike Kessel (2019) as part of "AQUISTO"

path=getArgument()+"\\";

setTool("line");
files=getFileList(path+"Macros\\Samples\\Channels\\");
files=Array.sort(files);
Array.show(files);
//array of different parameter settings for one image
function firstRun(){
	a=0;
	open(path+"Macros\\Samples\\Channels\\"+files[a]);
	print("First general run");
	rename("Original");
	
	width=getWidth();
	height=getHeight();
	run("Canvas Size...", "width="+width+50+" height="+height+50+" position=Center");
	widthx=getWidth();
	heightx=getHeight();
	run("Subtract Background...", "rolling=50 light");
	run("Colour Deconvolution", "vectors=[Feulgen Light Green]");

	//close green and blue
	close();
	close();

	rename("Colour_Deconvolution");
	run("Invert");
							
	threshold_method=newArray("Fixed", "Global median adaptive", "Fixed with histogram adaption", "Global median adaptive with histogram adaption");

	for(d=0; d<4; d++){ //different thresholding methods and adaption of histogram in beginning
		newImage("First Run "+threshold_method[d], "8-bit black", 9*widthx, 3*heightx,1);
		for(b=0; b<3; b++){	//different preprocessing steps
			for(c=0; c<9; c++){		//different thresholds
				selectWindow("Colour_Deconvolution");
				run("Duplicate...", " ");
				rename("InProgress");
					
				if(d>1){	//histogram adaption
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
									
				if(b==0){string="None";};
				if(b==1){run("Gaussian Blur...", "sigma=2"); string="Sigma=2";};
				if(b==2){run("Median...", "radius=2"); string="Median=2";};
							
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
					if(c>0){percentile=percentile+0.15*percentile;}							
					setThreshold(percentile, 255);
					run("Create Selection");
					run("Create Mask");
					close("Done");							
					rename("Done");
				}
						
				if(d==2){								
					if(c>0){percentile=percentile+0.15*percentile;}
					setThreshold(percentile, 255);
					run("Create Selection");
					run("Create Mask");
					close("Done");							
					rename("Done");
				}

				if(d==1){	//threshold adapted to median and sd
					threshold=(median+sd)*(0.2*c+0.5);
					setThreshold(threshold, 255);
					run("Create Selection");
					run("Create Mask");
					close("Done");							
					rename("Done");
				}
						
				if(d==3){	//threshold adapted to median and sd
					threshold=(median+sd)*(0.2*c+0.5);
					setThreshold(threshold, 255);
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
						drawString("Threshold=(Median+SD)*"+(0.15*c+0.5), (c+0.2)*widthx, 100, "white");
					}
					if(d==3){ //adaptive median+sd
						drawString("Threshold=(Median+SD)*"+(0.15*c+0.5), (c+0.2)*widthx, 100, "white");
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
	close("Colour_Deconvolution");
}

//apply chosen parameters to all images of the channel
function secondRun(){
	count=files.length;
	
	//Apply these settings to all other images in samples
	for(a=0; a<files.length; a++){
		if(a==0){
			newImage("Original", "RGB black", count*1050, 1000,1);
			newImage("Processed", "8-bit black", count*1050, 1000,1);
			newImage("Segmented", "8-bit black", count*1050, 1000,1);
		}
		run("Set Measurements...", "median standard"); 
		open(path+"Macros\\Samples\\Channels\\"+files[a]);
		rename("OriginalImage");
		print("First general run");
		makeRectangle(0,0,1000,1000);
		run("Crop");
		run("Canvas Size...", "width=1050 height=1050 position=Center");

		setFont("SansSerif", 50, "bold");
		setColor("black");

		//colour deconvolution
		run("Subtract Background...", "rolling=50 light");
		run("Colour Deconvolution", "vectors=[Feulgen Light Green]");
		close("");
		close("OriginalImage-(Colour_3)");
		close("OriginalImage-(Colour_2)");
		run("Invert");
		rename("ProcessedImage");
		
		//measure median+sd in original image
		List.setMeasurements();
		medianoriginal=List.getValue("Median");
		sdoriginal=List.getValue("StdDev");

		//First part, processing steps--------------------------------------------------------------------------------------------
		if(histad==1){
			getHistogram(values, counts, 256);
			counts=Array.slice(counts, 1, counts.length);
			Array.getStatistics(counts, min, max, mean, std);
			for(e=0;e<counts.length;e++){
				if(counts[e]==max){
					setMinAndMax(values[e+1],255);
					run("Apply LUT");
				}
			}
		}
		if(median>0){run("Median...", "radius="+median);}
		if(gauss>0){run("Gaussian Blur...", "sigma="+gauss);}

		//End first part--------------------------------------------------------------------------------------------	
		//median+sd in processed image
		List.setMeasurements();
		medianprocessed=List.getValue("Median");
		sdprocessed=List.getValue("StdDev");
			
		run("Duplicate...", "title=SegmentedImage");

		//Second part processing steps--------------------------------------------------------------------------------------------
		if(method==0){
			selectWindow("SegmentedImage");
			setThreshold(threshold, 255);
			run("Create Selection");
			run("Create Mask");
			close("SegmentedImage");
			rename("SegmentedImage");
		}
		if(method==1){
			selectWindow("SegmentedImage");
			setThreshold((sdprocessed+medianprocessed)*threshold, 255);
			run("Create Selection");
			run("Create Mask");
			close("SegmentedImage");
			rename("SegmentedImage");
		}
			
		//End second part--------------------------------------------------------------------------------------------
		//insert into arrays

		//original
		selectWindow("OriginalImage");
		drawString("Median="+medianoriginal+", Std="+sdoriginal, 100, 100, "white");
		run("Insert...", "source=OriginalImage destination=Original x="+a*1050+" y=0");

		selectWindow("SegmentedImage");
		run("Insert...", "source=SegmentedImage destination=Segmented x="+a*1050+" y=0");
			
		selectWindow("ProcessedImage");
		drawString("Median="+medianprocessed+", Std="+sdprocessed, 100, 100, "white");
		run("Insert...", "source=ProcessedImage destination=Processed x="+a*1050+" y=0");

		close("ProcessedImage");
		close("SegmentedImage");
		close("OriginalImage");		
	}
}

first=getBoolean("Go back to creating an array for the first image");
	if(first==1){
		firstRun();	
	}
	waitForUser("Choose: Background, Median or Gauss, Threshold, Particles to be excluded");
	if(first==1){
		close("Original");
	}
	histad=getNumber("Adapt histogram, (0=no, 1=yes)", 0);
	median=getNumber("Which radius for median filter (0 for none)", 0);
	gauss=getNumber("Which sigma for gaussian filter (0 for none)", 0);
	method=getNumber("Which method for thresholding (0=fixed, 1=adaptive via median)", 0);
	if(method==0){
		threshold=getNumber("Which fixed threshold", 90);
	}
	if(method==1){
		threshold=getNumber("Which factor for median and sd", 1);
	}

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
	median=getNumber("Which radius for median filter (0 for none)", 0);
	gauss=getNumber("Which sigma for gaussian filter (0 for none)", 0);
	method=getNumber("Which method for thresholding (0=fixed, 1=adaptive via median)", 0);
	if(method==0){
		threshold=getNumber("Which fixed threshold", 90);
	}
	if(method==1){
		threshold=getNumber("Which factor for median and sd", 3);
	}

	secondRun();
	waitForUser("Check the results");	
	second=getBoolean("Processing successful?");
}
close("*");

//write parameter table
if(second==1){
	run("Clear Results");
	parameters=newArray("HistAd", "Median", "Gauss", "Method", "Threshold");
	values=newArray(histad,  median, gauss, method, threshold);
	for(a=0; a<parameters.length; a++){
		setResult("Parameters", a, parameters[a]);
		setResult("Values", a, values[a]);
	}
	saveAs("Results", path+"Macros\\Processing\\Sirius red.txt");
}

run("Quit");
