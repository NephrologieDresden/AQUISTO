// Macro to extract size reduced previews from every scene in a .czi-file, and macro and label image of the slide
// Friederike Kessel (2019) as part of "AQUISTO"

run("Bio-Formats Macro Extensions");
path=getArgument();

files=getFileList(path+"\\RAW_DATA-new");
files=Array.sort(files);
Array.show(files);
File.makeDirectory(path+"\\File_Header\\");

setBatchMode(true);
for(a=0;a<files.length;a++){		
		//not for the pt1.czi
	if(!File.exists(path+"\\File_Header\\"+files[a])){
	  print("Current file: "+files[a]);
		if(lengthOf(files[a])==20){

			File.makeDirectory(path+"\\File_Header\\"+files[a]);	
			//get number of series
			
			id=path+"\\RAW_DATA-new\\"+files[a];
			Ext.setId(id);
			Ext.getSeriesCount(seriesCount);
	    
			//get number of series
			seriesnumber=seriesCount;
			//get the size for every image in the series
			Ysize=newArray(seriesnumber-2);
			Xsize=newArray(seriesnumber-2);
			for(b=0; b<seriesnumber-2;b++){
				Ext.setSeries(b);
				Ext.getSizeY(sizeY);
				Ysize[b]=sizeY;
			}			
			//get the channel number
			Ext.getSizeC(sizeC);
			channelno=sizeC;
			
			//get series numbers for full size images for every scene (pyramid 1), open and save to export
			//get preview, save in File_Names

			run("Bio-Formats Importer", "open="+path+"\\RAW_DATA-new\\"+files[a]+" color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT series_4");
			run("Scale...", "x=0.5 y=0.5 interpolation=Bilinear average create");
			saveAs("TIFF", path+"\\File_Header\\"+files[a]+"\\"+files[a]+"-Scene-1-Preview");
			close();
			close();
			count=1;
			for(b=1; b<Ysize.length; b++){
				if(Ysize[b]>Ysize[b-1]){
				if(Ysize[b]>Ysize[b+1]){
					count=count+1;
					//previews
					run("Bio-Formats Importer", "open="+path+"\\RAW_DATA-new\\"+files[a]+" color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT series_"+b+4);
					run("Scale...", "x=0.5 y=0.5 interpolation=Bilinear average create");
					saveAs("TIFF", path+"\\File_Header\\"+files[a]+"\\"+files[a]+"-Scene-"+count+"-Preview");
					close();
					close();
				}}
			}
		
			
			Ext.setId(id);		
			//save label and overview
			File.makeDirectory(path+"\\File_Header\\"+files[a]);
			seriesopen=" series_"+seriesnumber+" series_"+seriesnumber-1;
			print("label and macro image: "+seriesopen);
			run("Bio-Formats Importer", "open="+path+"\\RAW_DATA-new\\"+files[a]+" color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT"+seriesopen);
			imagelist=getList("image.titles");
			for(b=0; b<imagelist.length;b++){
				selectWindow(imagelist[b]);
				saveAs("TIFF", path+"\\File_Header\\"+files[a]+"\\"+imagelist[b]);
				close();
			}		
		}
	}
}
run("Quit")
