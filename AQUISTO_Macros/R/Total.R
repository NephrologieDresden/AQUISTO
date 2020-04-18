
# Graph design ------------------------------------------------------------


mytheme3 <- theme(legend.text = element_text(size = 15), 
                  axis.title = element_text(size = 15),
                  plot.subtitle = element_text(size = 15,hjust=0.5),
                  axis.text = element_text(size = 13), 
                  axis.line = element_line(size = 1,colour = "black"), 
                  axis.ticks = element_line(colour="black",size = rel(3)),
                  panel.background = element_rect(fill = "white", colour="black"), 
                  legend.key = element_rect(fill = "white"),
                  panel.grid.major = element_line(colour="grey"),
                  panel.grid.minor = element_blank(),
                  legend.title = element_blank(),
                  legend.background = element_rect(fill="white",colour="black"),
                  ##legend.title = element_text(size = 20), 
                  plot.title = element_text(face = "bold",
                                            size = 18,hjust=0.5),
                  strip.text.x = element_text(size = 15))


# choose task -------------------------------------------------------------
select_step<-function(){
  stepx<-select.list(c("Preparation",
                      "Manual Selection",
                      "Preprocessing",
                      "Fluorescence Processing",
                      "Brightfield Processing",
                      "Analysis",
                      "Crop minor tissues",
                      "User Manual",
                      "Cancel"), graphics=T)
  assign("stepx", stepx, envir=.GlobalEnv)

}

select_substep<-function(){
  if(stepx=="Preparation"){
    substep<-select.list(c("Get slide headers and previews",
                           "Add file names to list",
                           "Add general information about a new staining",
                           "Sort and rename files",
                           paste("Back to", stepx),
                           "Cancel"), graphics = T)
  }
  if(stepx=="Preprocessing"){
    substep<-select.list(c("Set parameters for tiles",
                           "Create Images/Tiles",
                           "Crop minor tissues",
                           paste("Back to", stepx),
                           "Cancel"), graphics = T)
  }
  if(stepx=="Manual Selection"){
    substep<-select.list(c("Major tissue selection",
                           "Minor tissue selection",
                           paste("Back to", stepx),
                           "Cancel"), graphics = T)
  }
  if(stepx=="Fluorescence Processing"){
    substep<-select.list(c("Histogram Analysis",
                           "Choose samples", 
                           "Parameter setting nuclei",
                           "Parameter setting co-channels",
                           "Channel processing",
                           paste("Back to", stepx),
                           "Cancel"), graphics = T)
  }
  if(stepx=="Brightfield Processing"){
    substep<-select.list(c("Histogram Analysis",
                           "Choose samples",
                           "Parameter setting co-channels",
                           "Processing",
                           paste("Back to", stepx),
                           "Cancel"), graphics = T)
  }
  if(stepx=="Analysis"){
    substep<-select.list(c("Standard Analysis",
                           paste("Back to", stepx),
                           "Cancel"), graphics = T)
  }

  if(stepx=="Crop minor tissues"){
    substep<-select.list(c("Crop minor tissues",
                           paste("Back to", stepx),
                           "Cancel"), graphics = T)
  }
  if(stepx=="User Manual"){
    substep<-select.list(c("User Manual",
                           paste("Back to", stepx),
                           "Cancel"), graphics = T)
  }
  
  if(stepx=="Cancel"){
    substep<-"Cancel"
    startx<-"Cancel"
  }
  assign("substep", substep, envir=.GlobalEnv)

}

total_selection<-function(){
  select_step()
  select_substep()
  
  if(!exists("startx")){
    startx<-""
  }
  
  if(!exists("substep")){
    substep<-""
  }
  
  while(substep==paste("Back to", stepx)){
    select_step()
    select_substep()
  }
  
  if(substep!="Cancel"){
    startx<-select.list(c(paste("START:", substep), paste("Back to", stepx)), graphics=T)
  }
  
  while(startx==paste("Back to", stepx)){
    select_step()
    select_substep()
    while(substep==paste("Back to", stepx)){
      select_step()
      select_substep()
    }
    if(substep!="Cancel"){
      startx<-select.list(c(paste("START:", substep), paste("Back to", stepx)), graphics=T)
    }
  }
  assign("startx", startx, envir=.GlobalEnv)
}

# run program -------------------------------------------------------------

total_program<-function(){
  # Preparation -------------------------------------------------------------
  if(stepx=="Preparation"){
    ##Biopsy headers and previews (Fiji macro Header_SplitScenes_Previews.ijm)
    if(startx=="START: Get slide headers and previews"){
      setwd(dirdata)
      system(paste0(dirfiji," -macro ",dirsource,"ImageJ_Macro/Header_SplitScenes_Previews.ijm ", getwd()))
    }else{setwd(dirdata)}
    
    ##fill file names list (R only)
    if(startx=="START: Add file names to list"){
     
      ##updata file.names list
      df1<-read.table("Registration_Tables/File_Names.csv", sep=";", header=T, stringsAsFactors = F)
      czilist<-list.dirs(paste0(getwd(), "/File_Header"),recursive = F, full.names = F)
      for(a in 1:length(czilist)){
        
        #check that the slide isnt listed yet
        df2<-subset(df1, Date==substring(czilist[a], 1, 10))
        df2<-subset(df2, Slide==as.integer(substring(czilist[a], 13,16)))
        
        #get number of scenes
        if(nrow(df2)==0){
          sceneno<-length(list.files(paste0(getwd(), "/File_Header/", czilist[a], "/"), recursive = F, full.names = F, pattern=".czi"))-2
          #add a row for every scene on that slide
          for(b in 1:sceneno){
            c1<-c(substring(czilist[a], 1, 10),
                  as.integer(substring(czilist[a], 13,16)),
                  b, "", "", "", "", "", "", "","")
            df1<-rbind(df1, c1)
          }
        }
      }
      write.table(df1, file=paste0(getwd(),"/Registration_Tables/File_Names.csv"), sep=";", row.names = F)
      
      ##if not completed yet: open file and run
      
      #if(nrow(df2)>0){
        file.show("Registration_Tables/File_Names.csv")
        system(paste0(dirfiji," -macro ",dirsource,"ImageJ_Macro/Entering_File_Names.ijm ", getwd(), "*", paste0(czilist, collapse="*")))
        winDialog(type="ok", "Save the table \"File_Names.csv\" and close it")
      #}else{winDialog(type="ok", "The data table is up to date")}
    }
    
    ##fill general information (R only)
    if(startx=="START: Add general information about a new staining"){
      df1<-read.table("Registration_Tables/File_Names.csv", sep=";", header=T, stringsAsFactors = F)
      df2<-read.table("Registration_Tables/General_Information.csv", sep=";", header=T, stringsAsFactors = F)
      
      ##check for new staining
      for(a in 1:nrow(df1)){
        df3<-subset(df2,Staining==df1$Staining[a]&Experiment==df1$Experiment[a]&Labmember==df1$Labmember[a])
        
        if(nrow(df3)==0){
          winDialog(type="ok", paste0(df1$Staining[a], "\n", df1$Experiment[a],"\n", df1$Labmember[a]))
          
          #open preview to get number of channels
          slide<-paste0(paste0(rep("0", times=4-nchar(df1$Slide[a])), collapse=""),df1$Slide[a], collapse="")
          if(file.exists(paste0(getwd(),"/File_Header/",
                                df1$Date[a],"__", slide, ".czi/",
                                df1$Date[a],"__", slide, ".czi-Scene-1-Preview.tif"))){
            file.show(paste0(getwd(),"/File_Header/",
                             df1$Date[a],"__", slide, ".czi/",
                             df1$Date[a],"__", slide, ".czi-Scene-1-Preview.tif"))
          }
          
          organ<-winDialogString("Which organ did you section", "Kidney")
          tissueNo<-winDialogString("How many distinct tissue compartments do you want to select", "0")
          if(tissueNo>0){
            tissueComp<-winDialogString(paste0("Tissue compartment: 1"), "Medulla")
            for(c in 2:tissueNo){
              tissueComp<-paste0(tissueComp, ", ", winDialogString(paste0("Tissue compartment: ",c), "Medulla"))
            }
          }else{
            tissueComp=""
          }
          subTissueComp<-winDialogString("Tissue compartment to select in tiles", "Glomeruli")
          
          if(nchar(subTissueComp)>0){
            tileNo<-winDialogString("Number of columns and rows for tiles", "5")
            cropSub<-winDialog(type="yesno","Crop tissue compartments from tiles and create array")
          }else{
            tileNo=0
            cropSub<-""
          }
          
          staintype<-select.list(c("Fluorescence", "PAS", "Peroxidase", "Sirius red"), graphics = T, title="Type of staining")
          counterstain<-select.list(c("DAPI", "Hematoxylin","none"), graphics = T, title="Type of counterstaining")
          
          c5<-winDialogString("Number of total scanned channels", "1")
          c6<-c7<-c("")
          for(b in 1:c5){
            c6[b]<-winDialogString(paste("Marker stained in channel", b), "")
            c7[b]<-select.list(c("","Magenta","Red","Green","Yellow","Cyan","Blue","Grays"), graphics = T, title=paste("Pseudocolour for channel",b))
          }
          protein<-c(c6,rep("", times=5-length(c6)))
          pseudocolor<-c(c7,rep("", times=5-length(c7)))
          ctotal<-c(df1$Labmember[a], df1$Experiment[a], df1$Staining[a], staintype, counterstain, organ, tissueComp, tileNo, subTissueComp, cropSub, protein, pseudocolor)
          df2<-rbind(df2, ctotal)
          write.table(df2, "Registration_Tables/General_Information.csv", sep=";", row.names = F)
          df2<-read.table("Registration_Tables/General_Information.csv", sep=";", header=T, stringsAsFactors = F)
        }
      }

    }
    
    ##run sample characterization (R only)
    if(startx=="START: Sort and rename files"){
      source(paste0(dirsource, "R/Sample_Characterization.R"))
    }
  }
  
  # Preprocessing ---------------------------------------------------------
  
  if(stepx=="Preprocessing"|stepx=="Manual Selection"){
    setwd(choose.dir(default=getwd(), caption="Select your EXPERIMENT folder"))
    wd<-getwd()
    # tile characteristics (Fiji macro "Tile_Parameters.ijm")
    if(startx=="START: Set parameters for tiles"){
      
      ##if there is no characteristic set yet
      ##select sections in all previews, save ROI set, then crop sections from the original image to roi and save
      ##select Roi from Tile_Parameters_1 in originally sized image and create Array for one staining after the other
      system(paste0(dirfiji," -macro ",dirsource,"ImageJ_Macro/Tile_Parameters.ijm ",getwd()))
    
      }else{}
    
    # tissue selection (Fiji macro "Tissue_selection.ijm")
    if(startx=="START: Major tissue selection"){
      system(paste0(dirfiji," -macro ",dirsource,"ImageJ_Macro/Tissue_selection.ijm ",getwd()))
    }
    
    # create images and tiles (Fiji macro "Images.ijm")
    if(startx=="START: Create Images/Tiles"){
      stainings<-list.dirs(recursive = F, full.names = F)
      for(a in 1:length(stainings)){
        channelx<-list.dirs(paste0(getwd(),"/", stainings[a],"/Histograms"), recursive = F, full.names = F)
        if(file.exists(paste0(getwd(),"/", stainings[a],"/Tiles"))){
          if(substring(channelx[1],0,1)==1){
            if(file.exists(paste0(getwd(),"/", stainings[a],"/Macros/Tile_Parameters/Tile.txt"))){
              tiles<-read.table(paste0(getwd(),"/", stainings[a],"/Macros/Tile_Parameters/Tile.txt"), header=T, sep="\t")
              wd<-gsub("/", "\\\\", getwd())
              system(paste0(dirfiji," -macro ",dirsource,"ImageJ_Macro/Images.ijm ", dirdata, "*", wd, "\\",stainings[a], "*", tiles[1,3], "*", tiles[2,3], "*", tiles[3,3], "*", tiles[4,3]))
            }
          }else{
            wd<-gsub("/", "\\\\", getwd())
            system(paste0(dirfiji," -macro ",dirsource,"ImageJ_Macro/Images.ijm ",  dirdata, "*",wd, "\\",stainings[a], "*", 1, "*", 2, "*",3, "*", 5))
          }
        }else{
          wd<-gsub("/", "\\\\", getwd())
          system(paste0(dirfiji," -macro ",dirsource,"ImageJ_Macro/Images.ijm ", wd, "\\",stainings[a], "*", 1, "*", 2, "*",3, "*", 5))
        }
      }
    }
    
    # minor tissue selection selection (Fiji macro "Tile_tissue_Selection.ijm")
    if(startx=="START: Minor tissue selection"){
      system(paste0(dirfiji," -macro ",dirsource,"ImageJ_Macro/Tile_tissue_Selection.ijm ", getwd()))
    }
    
    # crop minor tissues
    if(startx=="START: Crop minor tissues"){
      system(paste0(dirfiji," -macro ",dirsource,"ImageJ_Macro/Crop_minor_tissues.ijm "))
    }
      
  }
  

# Fluorescence Processing --------------------------------------------------------------

  if(stepx=="Fluorescence Processing"){
    setwd(choose.dir(default=getwd(), "Select your STAINING folder"))
    
    # histogram analysis (R only)
    if(startx=="START: Histogram Analysis"){
      source(paste0(dirsource,"R/Histogram_Analysis.R"))
    }
    
    if(startx=="START: Choose samples"){
      chosefiles=select.list(list.files(paste0(getwd(),"/Images")), graphics = T, multiple = T, title="Which biopsies for samples")
      chosefiles<-paste0(chosefiles, ".tif")
      system(paste0(dirfiji," -macro ",dirsource,"ImageJ_Macro/Sample_Selection.ijm ", getwd(), "*", paste0(chosefiles, collapse="*")))
    }
    
    # parameter setting (Fiji macros "Channel_Array_xxx.ijm")
    if(startx=="START: Parameter setting co-channels"){
      dir.create(paste0(getwd(), "/Macros/Processing"))
      channelx<-list.dirs(paste0(getwd(), "/Histograms"), full.names = F, recursive = F)
      channelx<-select.list(graphics = T, channelx)
      channelx<-paste0("C",substring(channelx, 1,1))
      system(paste0(dirfiji," -macro ",dirsource,"ImageJ_Macro/Channel_Array.ijm ", getwd(), "*", channelx))
    
    }
    
    if(startx=="START: Parameter setting nuclei"){
      nucleus_method<-select.list(c("Marker controled watershed", "StarDist"), graphics = T, title="Method for nucleus detection")
      if(nucleus_method=="Marker controled watershed"){
        system(paste0(dirfiji," -macro ",dirsource,"ImageJ_Macro/Watershed_Array.ijm ", getwd()))
      }
      if(nucleus_method=="StarDist"){
        system(paste0(dirfiji," --console --run ",dirsource,"ImageJ_Macro/StarDist_Array.py myDir=\'", getwd(), "\'"))
      }
      
    }
    if(startx=="START: Channel processing"){
      ##only if settings for all other channels are present
      channelx<-list.dirs(paste0(getwd(),"/Histograms"), recursive = F, full.names = F)
      #channelx<-channelx[-which(nchar(channelx)<4)]
      channely<-c(unlist(strsplit(channelx, "_")))
      channelz<-""
      for(a in 1:length(channelx)){
        channelz[a]<-paste0(channely[3*a-2], "_", channely[3*a])
      }
      
     
      processchannels<-select.list(channelz,  graphics = T, multiple = T, title="Which channels to process")
      parameterlist<-list.files(paste0(getwd(),"/Macros/Processing/"))
      for(a in 1:length(processchannels)){
        if(file.exists(paste0(getwd(),"/Macros/Processing/", processchannels[a], ".txt"))){
          ## read table with specifications
          df1<-read.table(paste0(getwd(), "/Macros/Processing/", processchannels[a], ".txt"), sep="\t", header=T)
          ##for DAPI Channel
          if(length(grep("DAPI", processchannels))>0){
            #if(grep("DAPI", processchannels)==a){
              system(paste0(dirfiji," -macro ",dirsource,"ImageJ_Macro/Nucleus_Detection.ijm ", getwd(), "*", df1[1,3], "*", df1[2,3], "*", df1[3,3]))
            #}
          }else{ ##for other channels
            ##only if all nuclear ROIs are available
            fileno<-list.files("Images/")
            fileno<-fileno[!fileno=="Thumbs.db"]
            fileno<-length(fileno)
            tissues<-list.files("Results/Nuclear_ROIs")
            roino<-length(list.files(paste0("Results/Nuclear_ROIs/", tissues[1])))
            #if(roino==fileno){
              system(paste0(dirfiji," -macro ",dirsource,"ImageJ_Macro/Channel_Detection.ijm ",
                            getwd(),"*",processchannels[a], "*", paste0(df1[1:10,3], collapse="*")))
           # }
          }
        }else{
          if(length(grep("DAPI", processchannels[a]))>0){
            proc_star<-winDialog(type="yesno", message="Process nuclei with StarDist (1h/section)")
            if(proc_star=="YES"){
              system(paste0(dirfiji," --console --run ",dirsource,"ImageJ_Macro/stardist_script_aquisto.py myDir=\'", getwd(), "\'"))
            }
          }else{
            winDialog(paste("Set parameters for", processchannels[a]))
          }
        }
      }
    }
  }

# Brightfield processing --------------------------------------------------
  if(stepx=="Brightfield Processing"){
    setwd(choose.dir(default=getwd(), "Select your STAINING folder"))
    
    # histogram analysis (R only)
    if(startx=="START: Histogram Analysis"){
      source(paste0(dirsource,"R/Histogram_Analysis.R"))
    }
    
    if(startx=="START: Choose samples"){
      chosefiles=select.list(list.files(paste0(getwd(),"/Preview")), graphics = T, multiple = T, title="Which biopsies for samples")
      system(paste0(dirfiji," -macro ",dirsource,"ImageJ_Macro/Sample_Selection.ijm ", getwd(), "*", paste0(chosefiles, collapse="*")))
    }
    
    # parameter setting (Fiji macros "Channel_Array_xxx.ijm")
    if(startx=="START: Parameter setting co-channels"){
      dir.create(paste0(getwd(), "/Macros/Processing"))
      channelx<-list.dirs(paste0(getwd(), "/Histograms"), full.names = F, recursive = F)
      if(channelx=="PAS"){
        system(paste0(dirfiji," -macro ",dirsource,"ImageJ_Macro/PAS_Array.ijm ", getwd())) 
      }
      if(channelx=="Sirius red"){
        system(paste0(dirfiji," -macro ",dirsource,"ImageJ_Macro/SiriusRed_Array.ijm ", getwd()))
      }
    }
    
    ##process channels
    if(startx=="START: Processing"){
      ##only if settings for all other channels are present
      channelx<-list.dirs(paste0(getwd(),"/Histograms"), recursive = F, full.names = F)

      if(file.exists(paste0(getwd(),"/Macros/Processing/", channelx, ".txt"))){
        ## read table with specifications
        df1<-read.table(paste0(getwd(), "/Macros/Processing/", channelx, ".txt"), sep="\t", header=T)
        
        ##PAS
        if(channelx=="PAS"){
          df1<-read.table(paste0(getwd(), "/Macros/Processing/", channelx, ".txt"), sep="\t", header=T)
          system(paste0(dirfiji," -macro ",dirsource,"ImageJ_Macro/PAS_Detection.ijm ",
                        getwd(),"*",channelx, "*", paste0(df1[1:6,3], collapse="*")))
        }
        
        ##Sirius Red
        if(channelx=="Sirius red"){
          df1<-read.table(paste0(getwd(), "/Macros/Processing/", channelx, ".txt"), sep="\t", header=T)
          system(paste0(dirfiji," -macro ",dirsource,"ImageJ_Macro/SiriusRed_Detection.ijm ",
                        getwd(),"*", paste0(df1[1:5,3], collapse="*")))
          
        }
        
        ##Peroxidase


      }else{winDialog(paste("Set parameters for", channelx))}
    }
  }
  

# Analysis ----------------------------------------------------------------

   
  if(startx=="START: Standard Analysis"){
    setwd(choose.dir(default=getwd(), "Select your STAINING folder"))
    
    source(paste0(dirsource,"R/Slidescan_Analysis.R"))
  }
  

# Crop minor tissues ------------------------------------------------------
  if(startx=="START: Crop minor tissues"){
    setwd(choose.dir(default=getwd(), "Select your EXPERIMENT folder"))
    
    system(paste0(dirfiji," -macro ",dirsource,"ImageJ_Macro/Crop_minor_tissues.ijm ", getwd()))
  }
}


# execute -----------------------------------------------------------------

total_selection()
total_program()
if(stepx=="User Manual"){
  file.show(paste0(dirdata, "Manual.pdf"))
}
while(substep!="Cancel"&stepx!="Cancel"&startx!="Cancel"){
  total_selection()
  total_program()
  graphics.off()
}


