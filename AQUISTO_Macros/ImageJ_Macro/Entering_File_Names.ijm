// Macro to enter file names into the file database from slide headers, label images and previews
// Friederike Kessel (2019) as part of "AQUISTO"

argument=getArgument();
argument=split(argument, "*")
path=argument[0];
files=Array.slice(argument, 1, argument.length);

//entering data
files=Array.sort(files);
Array.show(files);
for(a=0;a<files.length;a++){
	images=getFileList(path+"\\File_Header\\"+files[a]+"\\");
	print(files[a]);
	images=Array.sort(images);
	Array.show(images);
	for(b=0; b<images.length; b++){
		open(path+"\\File_Header\\"+files[a]+"\\"+images[b]);
		getDimensions(width, height, channels, slices, frames);
		print(channels);
		run("Enhance Contrast...", "saturated=0.3");
		for(c=1; c<slices-1; c++){
			run("Next Slice [>]");
			run("Enhance Contrast...", "saturated=0.3");
		}
		for(c=1; c<channels; c++){
			run("Next Slice [>]");
			run("Enhance Contrast...", "saturated=0.3");
		}
		if(b==0){
			setLocation(0,500,500,500);
		}else{
			if(b==1){
				setLocation(0,0,1000,1000);
			}else{
				setLocation(1000,0,750,750);
			}
		}
	}	
	for(b=2; b<images.length; b++){
		images[b]=images[b];
		selectWindow("\\File_Header\\"+files[a]+"\\"+images[b]);
		waitForUser("Scene "+b-1+" enter information about focus and biopsy number");
		close();
	}
	close();
	close();	
}
run("Quit")