## Automatic quantification of whole histological sections AQUISTO
#   programmed by Friederike Kessel (2019) in the Department of Internal Medicine III,
#   Workgroup of Experimental Nephrology AG Hugo
#   Carl Gustav Carus University Dresden
#   EMail: friederike.kessel@ukdd.de

#   cite the following publication for reference
#   "New automatic quantification method of immunofluorescence and histochemistry in whole histological sections."
#   doi: 10.1016/j.cellsig.2019.05.020. [Epub ahead of print], Cellular Signaling 2019


script_location<-dirname(sys.frame(1)$ofile)

##setting basic directories upon first run
if(!file.exists(paste0(script_location, "/AQUISTO_Setup.RData"))){
  dirfiji<-choose.files(default=script_location, caption="Select FIJI.exe")
}else{
  load(paste0(script_location, "/AQUISTO_Setup.RData"))
}

# check if fiji.exe exists in the given location, or ask again
while(!file.exists(dirfiji)){
  dirfiji<-choose.files(default=script_location, caption="Select FIJI.exe")
}

script_location<-dirname(sys.frame(1)$ofile)
save.image(paste0(script_location, "/AQUISTO_Setup.RData"))

# directories based on script location
dirtotal<-unlist(strsplit(script_location, "/"))
dirdata<-dirtotal[1:(length(dirtotal)-2)]
dirdata<-paste0(paste0(dirdata, collapse="/"),"/")
dirsource<-paste0(dirdata, "AQUISTO_Macros/")

##create folder hierarchy
folder_list<-paste0("/", c("Experiments", "File_Header", "RAW_DATA-new"))
for(a in folder_list){
  if(!dir.exists(paste0(dirdata, a))){
    dir.create(paste0(dirdata, a))
  }
}

if(!dir.exists(paste0(dirsource, "/R/Packages"))){
  dir.create(paste0(dirsource, "/R/Packages"))
}

# necessary libraries
.libPaths(paste0(dirsource, "/R/Packages"))
req_pack<-c("ggplot2", "reshape2")
inst_pack<-data.frame(installed.packages())
inst_pack<-inst_pack$Package

if(length(req_pack[!is.element(req_pack, inst_pack)])>0){
  install.packages(req_pack[!is.element(req_pack, inst_pack)],lib = paste0(dirsource, "/R/Packages"))
}

library(ggplot2)
library(reshape2)

#run the frame program
source(paste0(dirsource, "R/Total.R"))

