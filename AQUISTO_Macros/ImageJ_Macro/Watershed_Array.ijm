// Macro  to set parameters for the detection and separation of DAPI stained nuclei
// Friederike Kessel (2019) as part of "AQUISTO"

argument=getArgument();
path=argument+"\\";
File.makeDirectory(path+"Macros\\Processing\\");
files=getFileList(path+"Macros\\Samples\\Channels\\");
files=Array.sort(files);
File.makeDirectory(path+"Macros\\Watershed\\");

//get an array for the first image
function firstRun(){
	count=0;
	//only for dapi channels
	for(a=0; a<files.length; a++){
	  filex=split(files[a],"_");
	  filex=filex[1]+filex[2];
	  print(filex);
	  if(startsWith(filex, "DAPI")){
		count=count+1;
		if(count==1){
			open(path+"Macros\\Samples\\Channels\\"+files[a]);
			makeRectangle(1000, 1000, 500, 500);
			run("Duplicate...", " ");
			close(files[a]);
			
			//DAPI Processing
			run("Colors...", "foreground=black background=black selection=black");
		
			rename("Original");
			run("Canvas Size...", "width="+550+" height="+550+" position=Center");
			widthx=getWidth();
			heightx=getHeight();
		
			selectImage("Original");
			run("Enhance Contrast", "saturated=0.01");
			run("8-bit");
			run("Subtract Background...", "rolling=35 sliding disable");
			
			for(b=3; b<10; b++){ //threshold

				newImage("Watershed_Threshold="+(b*2)+10, "RGB black", 5*550, 5*550,1);
				//setBatchMode(true);
					for(c=0; c<5; c++){ //noise
						for(d=0; d<5; d++){ //sigma
			
							//WATERSHED
							selectImage("Original");
							run("Duplicate...", "title=Input");
							run("Duplicate...", "title=Maskx");
							run("Duplicate...", "title=Marker");
							
			
							//Process Seed Points
							selectWindow("Marker");
							run("Gaussian Blur...", "sigma="+(d+1)); //sigma 1-5
							run("Find Maxima...", "noise="+(c+1)*2+" output=[Single Points]"); //noise 2-10
							close("Marker");
							selectWindow("Marker Maxima");
							rename("Marker");
						
							//Process Edges
							selectWindow("Input");
							run("Median...", "radius=2");
							setThreshold((b*2)+10, 255); //threshold 10-28 
							setOption("BlackBackground", false);
							run("Create Selection");
						    run("Create Mask");
						    close("Input");
						    rename("Input");
							run("Find Edges");
	
							//Process Mask
							selectWindow("Maskx");
							run("Median...", "radius=2");
							setThreshold((b*2)+10, 255); //threshold 10-28 
							run("Create Selection");
						    run("Create Mask");
						    close("Maskx");
						    rename("Mask");
						
							//Watershed
							run("Marker-controlled Watershed", "input=Input marker=Marker mask=Mask binary calculate use");
							selectWindow("Input-watershed");
							setThreshold(2, 3.4e38);
							setOption("BlackBackground", true);
							run("Convert to Mask");
						
							close("Marker");
							close("Input");
							close("Mask");
							rename("Watershed");
							selectWindow("Original");
							run("Duplicate...", " ");
							//END WATERSHED
							
							//Insert into canvas
							selectWindow("Watershed");
			 				run("Analyze Particles...", "  show=[Bare Outlines] exclude include");
			 				run("Magenta");
							run("Invert");
							rename("Watershed-1");
							run("Merge Channels...", "c1=Original-1 c2=Watershed-1 create");
							run("RGB Color");
							close("Watershed");
							close("Composite");
							rename("Watershed");
							
							run("Insert...", "source=Watershed destination=Watershed_Threshold="+(b*2)+10+" x="+d*550+" y="+c*550);
							
							setFont("SansSerif", 30, "bold");
							setColor("black");
							if(c==0){
								selectWindow("Watershed_Threshold="+(b*2)+10);
								setFont("SansSerif", 50);
								setColor("black");
								drawString("sigma="+d+1, (d+0.4)*550, 100, "white");
							}				
							close("Watershed");
						}
						drawString("noise="+(c+1)*2, 10, (c+0.5)*550, "white");
					}
					//setBatchMode(false);
			}
			close("Original");
			run("Images to Stack", "method=[Copy (center)] name=Stack title=[] use");
			imgtitles=getList("image.titles");
			Array.show(imgtitles);		
		}
	}
}
}

//apply chosen parameters to second run
function 
secondRun(){
	count=0;
	for(a=0; a<files.length; a++){
		 filex=split(files[a],"_");
		 filex=filex[1]+filex[2];
		 print(filex);
		 if(startsWith(filex, "DAPI")){
		 	count=count+1;
		 }
	}
	piccount=count;
	print(piccount);
	count=0;


	//Apply these settings to all other images in samples
	for(a=0; a<files.length; a++){
		filex=split(files[a],"_");
		 filex=filex[1]+filex[2];
		 print(filex);
		 if(startsWith(filex, "DAPI")){
			count=count+1;
			if(count==1){
				newImage("Segmented", "RGB black", piccount*2050, 2000,1);
			}		
			open(path+"Macros\\Samples\\Channels\\"+files[a]);
			run("Enhance Contrast", "saturated=0.01");
			run("8-bit");
			run("Subtract Background...", "rolling=35 sliding disable");

			rename("Source");
			print("First general run");

			run("Canvas Size...", "width=2050 height=2050 position=Center");

			setFont("SansSerif", 50, "bold");
			setColor("black");

//start watershed ------------------------------------------------------------------------------
			selectImage("Source");
			run("Duplicate...", "title=Input");
			run("Duplicate...", "title=Maskx");
			run("Duplicate...", "title=Marker");
						
		
			//Process Seed Points
			selectWindow("Marker");
			run("Gaussian Blur...", "sigma="+dapisigma);
			run("Find Maxima...", "noise="+dapinoise+" output=[Single Points]");
			close("Marker");
			selectWindow("Marker Maxima");
			rename("Marker");
					
			//Process Edges
			selectWindow("Input");
			run("Median...", "radius=2");
			setThreshold(dapits, 255); //threshold 10-28 
			setOption("BlackBackground", false);
			run("Create Selection");
			run("Create Mask");
			close("Input");
			rename("Input");
			run("Find Edges");

			//Process Mask
			selectWindow("Maskx");
			run("Median...", "radius=2");
			setThreshold(dapits, 255); //threshold 10-28 
			run("Create Selection");
			run("Create Mask");
			close("Maskx");
			rename("Mask");
					
			//Watershed
			run("Marker-controlled Watershed", "input=Input marker=Marker mask=Mask binary calculate use");
			selectWindow("Input-watershed");
			setThreshold(2, 3.4e38);
			setOption("BlackBackground", true);
			run("Convert to Mask");
					
			close("Marker");
			close("Input");
			close("Mask");
			rename("Watershed");
			//END WATERSHED
						
			//Insert into canvas
			selectWindow("Watershed");
		 	run("Analyze Particles...", "  show=[Bare Outlines] exclude include");
		 	run("Magenta");
			run("Invert");
			rename("Watershed-1");
			run("Merge Channels...", "c1=Source c2=Watershed-1 create");
			run("RGB Color");
			close("Watershed");
			close("Composite");
			rename("Watershed");

			run("Insert...", "source=Watershed destination=Segmented x="+(count-1)*2050+" y=0");
			close("Source");
			close("Watershed");
}
}
}
newImage("New", "8-bit black", 100, 100, 1);
first=getBoolean("Create an array for first image");
if(first==1){
	firstRun();
}else{
waitForUser("Choose: Threshold, Sigma and noise tolerance");
	dapits=getNumber("Which threshold", 20);
	dapisigma=getNumber("Which sigma for gaussian filter", 1);
	dapinoise=getNumber("Which noise tolerance", 5);

	secondRun();
}
close("New");
	waitForUser("Check the results");	
	second=getBoolean("Processing successful?");
	close("Segmented");
//repeat
while(second==0){
	close("Segmented");
	first=getBoolean("Create an array for first image");
	if(first==1){
		firstRun();
		waitForUser("Check the results");	
	}
	dapits=getNumber("Which threshold", 20);
	dapisigma=getNumber("Which sigma for gaussian filter", 1);
	dapinoise=getNumber("Which noise tolerance", 5);
	secondRun();
	waitForUser("Check the results");	
	second=getBoolean("Processing successful?");
	close("Segmented");
}

close("*");

for(a=0; a<files.length; a++){
	  filey=split(files[a],"_");
	  filex=filey[1]+filey[2];
	  print(filex);
	  if(startsWith(filex, "DAPI")){
	  	channelx=filey[0]+"_"+filey[1];
	  }
}

//write parameter table
if(second==1){
	run("Clear Results");
	parameters=newArray("Threshold", "Sigma", "Noise");
	values=newArray(dapits, dapisigma, dapinoise);
	for(a=0; a<parameters.length; a++){
		setResult("Parameters", a, parameters[a]);
		setResult("Values", a, values[a]);
	}
	channelx=substring(channelx, 1,lengthOf(channelx));
	saveAs("Results", path+"Macros\\Processing\\"+channelx+".txt");
}



run("Quit");
