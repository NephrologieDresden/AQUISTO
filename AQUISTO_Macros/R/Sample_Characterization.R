sample_characterization<-function(){
###Load FileNames.csv
df1<-data.frame(read.table("Registration_Tables/File_Names.csv", sep=";", header=T), stringsAsFactors = F)

###Get info from unsorted converted Files (List of all files)
filenames<-list.dirs("File_Header",full.names = F, recursive = F)
pb <- winProgressBar("Setup", "Setting up experiment folders and sorting previews", 0, length(filenames), 0)
for(a in 1:length(filenames)){
  
  #get list of previews for every slide
  imgnames<-list.files(paste0("File_Header/", filenames[a]),full.names = F, recursive = F, pattern="Preview")

  ###Sort files according to labmember, experiment, staining, date, slide, scene
  ###Create necessary mandatory subfolders
    for(j in 1:length(imgnames)){
  
      date<-substring(imgnames[j], 1, 10)
      slide<-as.integer(substring(imgnames[j], 13, 16))
      scene<-substring(imgnames[j],28,28)
  
      v1<-subset(df1, Slide==slide&Scene==scene&Date==date&Focus=="yes")
      df1$Converted<-as.character(df1$Converted)
      
      if(nrow(v1)==1){
        ##Paste "yes" into converted column
        for(x in 1:nrow(df1)){
          if(df1$Date[x]==date&!is.na(df1$Date[x])){
          if(df1$Slide[x]==slide&!is.na(df1$Slide[x])){
          if(df1$Scene[x]==scene&!is.na(df1$Scene[x])){
            df1$Converted[x]<-"Yes"
          }}}
        }
        
        if(!dir.exists(paste0("Experiments/",v1$Labmember))){dir.create(paste0("Experiments/",v1$Labmember))}
        if(!dir.exists(paste0("Experiments/",v1$Labmember,"/",v1$Experiment))){dir.create(paste0("Experiments/",v1$Labmember,"/",v1$Experiment))}
        if(!dir.exists(paste0("Experiments/",v1$Labmember,"/",v1$Experiment,"/",v1$Staining))){
          dir.create(paste0("Experiments/",v1$Labmember,"/",v1$Experiment,"/",v1$Staining))
          dir.create(paste0("Experiments/",v1$Labmember,"/",v1$Experiment,"/",v1$Staining,"/Raw_Images"))
          dir.create(paste0("Experiments/",v1$Labmember,"/",v1$Experiment,"/",v1$Staining,"/Images"))
          dir.create(paste0("Experiments/",v1$Labmember,"/",v1$Experiment,"/",v1$Staining,"/Preview"))
          dir.create(paste0("Experiments/",v1$Labmember,"/",v1$Experiment,"/",v1$Staining,"/ROIs"))
          dir.create(paste0("Experiments/",v1$Labmember,"/",v1$Experiment,"/",v1$Staining,"/Results"))
          dir.create(paste0("Experiments/",v1$Labmember,"/",v1$Experiment,"/",v1$Staining,"/Results/Processed_Overview"))
          dir.create(paste0("Experiments/",v1$Labmember,"/",v1$Experiment,"/",v1$Staining,"/Macros"))
          dir.create(paste0("Experiments/",v1$Labmember,"/",v1$Experiment,"/",v1$Staining,"/Results/Total_Area"))
          dir.create(paste0("Experiments/",v1$Labmember,"/",v1$Experiment,"/",v1$Staining,"/Histograms"))
        }
        
        ##copy preview
        if(!file.exists(paste0("Experiments/",v1$Labmember,"/",v1$Experiment,"/",v1$Staining,"/Preview/",v1$Biopsy, ".tif"))){
          file.rename(paste0("File_Header/",filenames[a],"/",imgnames[j]), paste0("Experiments/",v1$Labmember,"/",v1$Experiment,"/",v1$Staining,"/Preview/",v1$Biopsy, ".tif"))
          slide<-paste0(c(rep("0",times=4-nchar(slide)), slide), collapse="")
          dir.create(paste0("Experiments/",v1$Labmember,"/",v1$Experiment,"/",v1$Staining,"/Raw_Images/",date,"-",slide,"-", scene,"-",v1$Biopsy))
        }
      }
    }
  setWinProgressBar(pb, a)
}
close(pb)
##update file_names
write.table(df1, file=paste0("Registration_Tables/File_Names.csv"),row.names = F, sep=";")
rm(list=ls())

####GeneralInformation------------------------------------------------------------

###Load GeneralInformation.csv 
df2<-read.table("Registration_Tables/General_Information.csv",sep=";", header=T, stringsAsFactors = F)

###create subfolders according to the specification
labmember<-list.dirs("Experiments",recursive = F, full.names=F)

##if desired assign labmember for subfolder generation
for(i in 1:length(labmember)){
  experiment<-list.dirs(paste0("Experiments/",labmember[i]),recursive = F, full.names=F)
  for(j in 1:length(experiment)){
    stainings<-list.dirs(paste0("Experiments/",labmember[i],"/",experiment[j]), full.names = F, recursive = F)
    for(k in 1:length(stainings)){
      ##only run if it hasnt run before
      if(!file.exists(paste0("Experiments/",labmember[i],"/",experiment[j],"/",stainings[k], "/Analysis"))){
      if(file.exists(paste0("Experiments/",labmember[i],"/",experiment[j],"/",stainings[k], "/Results"))){
        ###Get row for specific staining from table
        c2<-subset(df2,df2$Labmember==labmember[i]&df2$Experiment==experiment[j]&df2$Staining==stainings[k])
        c1<-which(df2$Labmember==labmember[i]&df2$Experiment==experiment[j]&df2$Staining==stainings[k])
        if(nrow(c2)==1){
          c1<-df2[c1,]
          c1[is.na(c1)]<-""
          ##if counterstaining==DAPI
          if(c1[1,5]=="DAPI"){
            dir.create(paste0("Experiments/",labmember[i],"/",experiment[j],"/",stainings[k],"/Results/Nuclear_ROIs"))
            dir.create(paste0("Experiments/",labmember[i],"/",experiment[j],"/",stainings[k],"/Results/Nuclear_Coverage"))
            dir.create(paste0("Experiments/",labmember[i],"/",experiment[j],"/",stainings[k],"/Results/Nuclear_Intensity"))
          }
          
          ###Define tissues for Analysis:
              tissues<-paste0("1_",unlist(as.character(c1[1,6])))
              if(nchar(as.character(c1[1,7]))>0){
                subtissues<-unlist(strsplit(as.character(c1[1,7]), ", "))
                tissues<-c(tissues, paste0(2:(length(subtissues)+1), "_", subtissues))
              }
              dir.create(paste0("Experiments/",labmember[i],"/",experiment[j],"/",stainings[k],"/ROIs/Tissues"))
              dir.create(paste0("Experiments/",labmember[i],"/",experiment[j],"/",stainings[k],"/ROIs/Original_Tissues"))
  
          
            ##Glomeruli
            if(nchar(as.character(c1[1,9]))>0){
              dir.create(paste0("Experiments/",labmember[i],"/",experiment[j],"/",stainings[k],"/Tiles"))
              dir.create(paste0("Experiments/",labmember[i],"/",experiment[j],"/",stainings[k],"/ROIs/",c1[1,9]))
              dir.create(paste0("Experiments/",labmember[i],"/",experiment[j],"/",stainings[k],"/ROIs/Tiles_", c1[1,9]))
              tissues<-c(tissues, paste0(length(subtissues)+2, "_", as.character(c1[1,9])), paste0(length(subtissues)+3, "_Single_",c1[1,9]))
            }
          
            ##Cropped Glomeruli
            if(c1[1,10]=="YES"){
              dir.create(paste0("Experiments/",labmember[i],"/",experiment[j],"/",stainings[k],"/Cropped_", c1[1,9]))
            }
               
          ###Adding all results directories for desired tissues
          
          for(l in 1:length(tissues)){
            dir.create(paste0("Experiments/",labmember[i],"/",experiment[j],"/",stainings[k],"/Results/Total_Area/", tissues[l]))
             
            if(dir.exists(paste0("Experiments/",labmember[i],"/",experiment[j],"/",stainings[k],"/Results/Nuclear_ROIs/"))){
              dir.create(paste0("Experiments/",labmember[i],"/",experiment[j],"/",stainings[k],"/Results/Nuclear_Coverage/", tissues[l]))
              dir.create(paste0("Experiments/",labmember[i],"/",experiment[j],"/",stainings[k],"/Results/Nuclear_Intensity/", tissues[l]))
              dir.create(paste0("Experiments/",labmember[i],"/",experiment[j],"/",stainings[k],"/Results/Nuclear_ROIs/", tissues[l]))
            }
         }
      
          ##for IF-Stainings
          if(c1[1,4]=="Fluorescence"){
            for(l in 15:11){
              for(m in 1:length(tissues)){
              
                channel<-(l-10)
                marker<-c1[1,l]
                colour<-c1[1,l+5]
                
                if(m==1){
                  if(marker!=""){
                    ##for channel/marker and pseudocolour recognition: save Folders with channel specs in Macros (to be deleted by imagej after preprocessing)
                    dir.create(paste0("Experiments/",labmember[i],"/",experiment[j],"/", stainings[k],"/Histograms/",channel,"_",colour,"_",marker))
                  }else{
                    if(length(list.dirs(paste0("Experiments/",labmember[i],"/",experiment[j],"/", stainings[k],"/Histograms/"), recursive = F))>0){
                      dir.create(paste0("Experiments/",labmember[i],"/",experiment[j],"/", stainings[k],"/Histograms/",channel,"_",colour,"_",marker))
                    }
                  }
                }
                
                if(nchar(as.character(c1[1,l]))>0){
                  if(marker!="DAPI"){
                  if(marker!="Brightfield"){
                    dir.create(paste0("Experiments/",labmember[i],"/",experiment[j],"/", stainings[k],"/Results/Nuclear_Coverage/",tissues[m],"/",channel, "_", marker))
                    dir.create(paste0("Experiments/",labmember[i],"/",experiment[j],"/", stainings[k],"/Results/Nuclear_Intensity/",tissues[m],"/",channel, "_", marker))
                    dir.create(paste0("Experiments/",labmember[i],"/",experiment[j],"/", stainings[k],"/Results/Total_Area/",tissues[m],"/",channel, "_",marker))
                  }}               
                }
              }
            }
          }
          
          ##For IP-Stainings
          if(c1[4]=="Peroxidase"){
            marker<-c1[11]
            dir.create(paste0("Experiments/",labmember[i],"/",experiment[j],"/", stainings[k],"/Histograms/",marker))
            for(m in 1:length(tissues)){
              dir.create(paste0("Experiments/",labmember[i],"/",experiment[j],"/", stainings[k],"/Results/Total_Area/", tissues[m], "/", marker))
            }
          }
          
          ###For PAS-Staining
          if(c1[4]=="PAS"){
            marker<-"PAS"
            dir.create(paste0("Experiments/",labmember[i],"/",experiment[j],"/", stainings[k],"/Histograms/", marker))
            for(m in 1:length(tissues)){
              dir.create(paste0("Experiments/",labmember[i],"/",experiment[j],"/", stainings[k],"/Results/Total_Area/", tissues[m], "/", marker))
            }
          }
          
          ##for sirius red staining
          if(c1[4]=="Sirius red"){
            marker<-"Sirius red"
            dir.create(paste0("Experiments/",labmember[i],"/",experiment[j],"/", stainings[k],"/Histograms/", marker))
              for(m in 1:length(tissues)){
                dir.create(paste0("Experiments/",labmember[i],"/",experiment[j],"/", stainings[k],"/Results/Total_Area/", tissues[m], "/", marker))
            }
          }   
          
          ##Add table for groups
          dir.create(paste0("Experiments/",labmember[i],"/",experiment[j],"/", stainings[k],"/Analysis"))
          biop<-list.files(paste0("Experiments/",labmember[i],"/",experiment[j],"/", stainings[k],"/Preview"),recursive = F, pattern=".tif")
          biop<-substring(biop, 0, nchar(biop)-4)
          groups<-data.frame(c("Biopsy",biop),c("Group",rep("",times=length(biop))))
          write.table(groups, paste0("Experiments/", labmember[i],"/", experiment[j],"/", stainings[k],"/Analysis/Groups.csv"), col.names = F,row.names = F,sep=";")
          
        }
      }
    }}
  }
}
}
sample_characterization()
