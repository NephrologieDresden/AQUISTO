# INSTRUCTIONS: -----------------------------------------------------------
# a) set the working directory by selection the "..." at the bottom right of the screen, choosing your experiment folder and pressing okay
#     then press the "More" button and select "Set as working directory"
# b) Make sure you have the table Groups.csv filled out before starting the analysis
# c) Start the program by running it from source with echo (Ctrl-Shift-Enter) or by clicking the little arrow on the right next to source and
#     select "Source with Echo"
# d) Define your group order (wait for the line in the Console, enter the numbers of the groups in the order you want for the graphs, press enter and confirm
#     with "y"+Enter)
# e) Setting of the parameters:
#     Area: recommended 6-45 µm²
#     Circularity: recommended 0.5-1
#     marker coverage and intensity depending on the staining intensity and type of staining
# f) If you want to change the settings/parameters: Delete the File "Parameters.csv" and run the program again or change the values in the table

# General Settings --------------------------------------------------------
wd<-getwd()
##Set all data characteristics

tissues<-list.dirs("Results/Total_Area",recursive = F, full.names = F)
single_tissues<-list.files("Results/Total_Area", recursive = F, full.names = F, pattern="Single")
single_tissuesx<-unlist(strsplit(single_tissues, "_"))
single_tissuesx<-single_tissuesx[3]
tissues<-tissues[!tissues%in%single_tissues]
markers<-list.dirs(paste0("Results/Total_Area/",tissues[1]),recursive = F, full.names = F)
if(substring(markers[1],1,1)!=1){mark<-markers}else{mark<-substring(markers,3,nchar(markers))}
biopsies<-list.files(paste0("Results/Total_Area/", tissues[1], "/", markers[1]))
biop<-substring(biopsies, 1,nchar(biopsies)-4)

##create output folders
if(!dir.exists("Analysis/Total_Area")){
  dir.create("Analysis")
  dir.create(paste0("Analysis/Total_Area/"))
  if(length(single_tissues)>0){
    dir.create(paste0("Analysis/Total_Area/Single_", single_tissuesx))
  }
}

###group order
if(!file.exists("Analysis/Groups.csv")){
  group<-data.frame(biop,rep("",times=length(biop)))
  colnames(group)<-c("Biopsy","Group")
  write.table(group, "Analysis/Groups.csv", col.names = T, row.names = F, sep=";")
  file.show("Analysis/Groups.csv")
  winDialog(type="ok", "Fill in the missing information, save the file, then click \"OK\"")
}
group<-data.frame(read.table("Analysis/Groups.csv",header=T,sep=";"))
group[,2]<-as.factor(group[,2])
grouporder<-c("")
grouplevelsx<-levels(group[,2])
for(a in 1:length(levels(group[,2]))){
  grouporder[a]<-select.list(grouplevelsx, graphics=T, title=paste0("Group number ",a))
  grouplevelsx<-grouplevelsx[!grouplevelsx%in%grouporder]
}


#while(x!="y"){
#  x<-readline(prompt=paste("Is this the right order? ", paste(grouporder, collapse="; "), " y/n "))
#  grouporder<-c("")
#  grouplevelsx<-levels(group[,2])
#  for(a in 1:length(levels(group[,2]))){
#    grouporder[a]<-select.list(grouplevelsx, graphics=T, title=paste0("Group number ",a))
#    grouplevelsx<-grouplevelsx[!grouplevelsx%in%grouporder]
#  }
#}

##breaks for histogram
areabreaks<-seq(from=0,to=100,by=5)
circbreaks<-seq(from=0,to=1,by=0.05)

# Permutation tables for markers
perm<-data.frame(rep("",times=3^length(mark)))

for(a in 1:length(mark)){
  perm[,a]<-rep(c("pos.","neg.","-"),each=3^(length(mark)-a),times=3^(a-1))
}
perm<-perm[1:(nrow(perm))-1,]

if(length(markers)==1){
  perm<-data.frame(c("pos.","neg."))
  colnames(perm)<-mark
}

#column names for permutations of marker
coln<-""
for(a in 1:nrow(perm)){
  c1<-paste(mark,perm[a,])
  c1<-paste(c1, collapse="/")
  c1<-paste(c1,"[%]")
  coln<-c(coln,c1)
}
coln<-coln[2:length(coln)]

# Set Theme for graphs with ggplot------------------------------------------------------------------

mytheme3 <- theme(legend.text = element_text(face = "italic",size = rel(1)), 
                  axis.title = element_text(size = rel(1.2)), 
                  axis.text = element_text(size = rel(1.0)), 
                  axis.line = element_line(size = 1,colour = "black"), 
                  axis.ticks = element_line(colour="black",size = rel(2)),
                  panel.background = element_rect(fill = "white", colour="black"), 
                  legend.box.background = element_rect(fill="white", colour="white"),
                  panel.grid.minor = element_line(colour="grey"),
                  panel.grid.major = element_line(colour="grey"),
                  legend.title = element_text(size = rel(1.5)), 
                  plot.title = element_text(face = "bold",
                                            size = rel(1.7),hjust=0.5),
                  axis.text.x = element_text(angle = 90, hjust = 0.5))



# Total Area Single tissues---------------------------------------------
single_tissue_area<-function(){
  for(c in 1:length(biop)){
      ##Setting up the dataframe
      df1<-c(paste0(single_tissuesx, "-Number"),"Area [µm²]", paste(rep(mark, each=2), rep(c("positive Area [%]","Intensity"), times=length(mark))))
     
      ##load data
      for (b in 1:length(markers)){
        df2<-data.frame(read.table(paste0("Results/Total_Area/", single_tissues,"/",markers[b],"/",biopsies[c]),sep="\t", header=T))
       
        ##for the first marker also add selection area
        if(b==1){
          glomname<-as.character(df2[,5])
          v1<-cbind(glomname,df2$Area, df2$X.Area, df2$Mean)
        }else{v1<-cbind(v1, df2$X.Area, df2$Mean)}
      }
      df1<-rbind(df1,v1)
      write.table(df1,paste0("Analysis/Total_Area/Single_", single_tissuesx,"/",biop[c],".csv"),sep=";",row.names = F,col.names = F)
  }
}

##statistics for total area in glomeruli and vicinity

single_tissue_area_summary<-function(){
  ##set dataframe
  df1<-c("Biopsy","Group",paste("Mean", single_tissuesx, "Area [µm²]"), "SD", "n", "Minimum", "Maximum")

  for (a in 1:length(biop)){
    df2<-data.frame(read.table(paste0("Analysis/Total_Area/Single_", single_tissuesx,"/",biop[a],".csv"), header=T, sep=";",stringsAsFactors = F))
    v1<-c(biop[a], as.character(group[group[,1]==biop[a],2]))
    meanvalue<-mean(df2$"Area..µm².")
    sdvalue<-sd(df2$"Area..µm².")
    nvalue<-length(df2$"Area..µm².")
    minvalue<-min(df2$"Area..µm².")
    maxvalue<-max(df2$"Area..µm².")
    v1<-c(v1,meanvalue,sdvalue,nvalue,minvalue,maxvalue)
    
    df1<-rbind(df1, v1)
  }
  write.table(df1,paste0("Analysis/Total_Area/Single_", single_tissuesx,"_Area.csv"),sep=";",row.names=F,col.names=F)
  
  ##for markers
  for (a in 1:length(mark)){
    df1<-c("Biopsy","Group",paste("Mean positive area [%] in", single_tissuesx),"SD","n","Minimum","Maximum", paste("Mean intensity in", single_tissuesx),"SD","Minimum","Maximum")

    for(b in 1:length(biop)){

      v1<-c(biop[b], as.character(group[group[,1]==biop[b],2]))
      df2<-data.frame(read.table(paste0("Analysis/Total_Area/Single_", single_tissuesx,"/",biop[b],".csv"), header=T, sep=";"))
        

      meanvalue<-mean(df2[,3+(a-1)*2])
      sdvalue<-sd(df2[,3+(a-1)*2])
      nvalue<-length(df2[,3+(a-1)*2])
      minvalue<-min(df2[,3+(a-1)*2])
      maxvalue<-max(df2[,3+(a-1)*2])
      v1<-c(v1,meanvalue,sdvalue,nvalue,minvalue,maxvalue)
      meanvalue<-mean(df2[,4+(a-1)*2])
      sdvalue<-sd(df2[,4+(a-1)*2])
      minvalue<-min(df2[,4+(a-1)*2])
      maxvalue<-max(df2[,4+(a-1)*2])
      v1<-c(v1,meanvalue,sdvalue,minvalue,maxvalue)
      
      df1<-rbind(df1,v1)
    }
    write.table(df1,paste0("Analysis/Total_Area/Single_", single_tissuesx, "_",mark[a],".csv"),sep=";",row.names=F,col.names=F)
  }
}

if(length(single_tissues)>0){
  single_tissue_area()
  single_tissue_area_summary()
}

# Total Area Tissues ------------------------------------------------------

total_area_tissues<-function(){
  ##setting dataframe
  df1<-data.frame()

  ##read tables and combine to one table (every marker, tissue and biopsy)
  for(d in 1:length(biop)){
    groupx<-as.character(group[group[,1]==biop[d],2])
    v3<-data.frame(rep(biop[d], times=length(tissues)), rep(groupx, times=length(tissues)), stringsAsFactors = F)
    for(b in 1:length(markers)){
      df2<-data.frame(read.table(paste0("Results/Total_Area/",tissues[1],"/",markers[b],"/",biopsies[d]),header=T, sep="\t"), stringsAsFactors = F)
        ##for the first marker also add selection area
      if(b==1){
        v3<-cbind(v3,df2[,5], df2[,2], df2[,4], df2[,3])
      }else{
        v3<-cbind(v3, df2[,4], df2[,3])
      }
    }
    df1<-rbind(df1,v3)
  }
  colnames(df1)<-c("Biopsy","Group","Tissue","Area [µm²]", paste0(rep(mark, each=2), c("-positive Area [%]", "-Intensity")))
  write.table(df1,"Analysis/Total_Area/Tissue_Summary.csv", row.names = F,col.names = T, sep=";")
}
  
total_area_tissues()

# Nuclear Coverage Setup -----------------------------------

##Distribution for size, circularity and marker positivity for parameter setting
distributiontables<-function(){
  ##get maximum intensity for all markers
  markmax<-rep(65535,times=length(markers))
  biopmax<-0
  
  #for(a in 1:length(mark)){
   # for(b in 1:length(biop)){
    #  df1<-read.table(paste0("Results/Nuclear_Intensity/",tissues[1],"/",markers[a],"/",biop[b],".txt"), sep="\t", header=T)
     # biopmax1<-max(df1$Mean, na.rm=T)
      #if(biopmax1>biopmax){
       # biopmax<-biopmax1
      #}
    #}
  #  markmax[a]<-biopmax
  #}

  
  ###dataframes setup
  progresscount<-0
  for(a in 1:length(mark)){
    pb<-winProgressBar(title="Distribution tables", min=0, max=(length(biop)*length(tissues)*length(mark)))
    ##breaks for intensities
    intensbreaks<-seq(from=0,to=markmax[a],by=as.numeric(markmax[a])/20)
    if(a==1){
      area<-c("Biopsy","Group","Tissue","Mean Area [µm²]","SD","n",paste("% cells with an Area of <", areabreaks[2],"µm²"),areabreaks[3:length(areabreaks)])
      circ<-c("Biopsy","Group","Tissue","Mean Circularity","SD","n",paste("% cells with a Circularity of <", circbreaks[2]),circbreaks[3:length(circbreaks)])
    }
    dfmarkcov<-c("Biopsy","Group","Tissue",paste("Mean",mark[a],"Coverage [%]"),"SD","n",paste("% cells with a coverage of <", areabreaks[2],"%"),areabreaks[3:length(areabreaks)])
    #dfmarkint<-c("Biopsy","Group","Tissue",paste("Mean",mark[a],"Intensity"),"SD","n",paste("% cells with an intensity of <", intensbreaks[2]),intensbreaks[3:length(intensbreaks)])
    
    ##start
    for(b in 1:length(tissues)){
      for(c in 1:length(biop)){
        progresscount<-progresscount+1
        if(file.size(paste0("Results/Nuclear_Coverage/",tissues[b],"/",markers[a],"/",biop[c],".txt"))>0){
          df1<-data.frame(read.table(paste0("Results/Nuclear_Coverage/",tissues[b],"/",markers[a],"/",biop[c],".txt"),header=T,sep="\t"))
          #df2<-data.frame(read.table(paste0("Results/Nuclear_Intensity/",tissues[b],"/",markers[a],"/",biop[c],".txt"),header=T,sep="\t"))
          if(a==1){
            v1<-(df1$Area)<=100
            v1<-df1$Area[v1]
            histarea<-hist(v1, breaks=areabreaks)
            varea<-histarea$counts/nrow(df1)*100
            area<-rbind(area,c(biop[c],as.character(group[group[,1]==biop[c],2]),tissues[b],mean(df1$Area),sd(df1$Area),nrow(df1),varea))
            
            histcirc<-hist(df1$Circ, breaks=circbreaks)
            vcirc<-histcirc$counts/nrow(df1)*100
            circ<-rbind(circ,c(biop[c],as.character(group[group[,1]==biop[c],2]),tissues[b],mean(as.numeric(df1$Circ.)),sd(as.numeric(df1$Circ.)),nrow(df1),vcirc))
          }
          if(nrow(df1)>0){
            histmarkcov<-hist(df1$X.Area, breaks=areabreaks)
            vmarkcov<-histmarkcov$counts/nrow(df1)*100
            dfmarkcov<-rbind(dfmarkcov,c(biop[c],as.character(group[group[,1]==biop[c],2]),tissues[b],mean(df1$X.Area),sd(df1$X.Area),nrow(df1),vmarkcov))
          }else{
            vmarkcov<-rep(0,times=20)
            dfmarkcov<-rbind(dfmarkcov,c(biop[c],as.character(group[group[,1]==biop[c],2]),tissues[b],0,0,nrow(df1),vmarkcov))
          }
          
          #if(nrow(df2)>0){
          #  histmarkint<-hist(df2$Mean, breaks=intensbreaks)
          #  vmarkint<-histmarkint$counts/nrow(df2)*100
          #  dfmarkint<-rbind(dfmarkint,c(biop[c],as.character(group[group[,1]==biop[c],2]),tissues[b],mean(df2$Mean),sd(df2$Mean),nrow(df2),vmarkint))
          #}else{
          #  vmarkint<-rep(0,times=20)
          #  dfmarkint<-rbind(dfmarkint,c(biop[c],as.character(group[group[,1]==biop[c],2]),tissues[b],0,0,nrow(df2),vmarkint))
          #}
        }
        setWinProgressBar(pb, progresscount)
      }
    }
    ##save data.frames
    if(a==1){
      write.table(area,"Analysis/Nuclear_Coverage/Distribution/Area.csv",row.names = F,col.names = F,sep=";")
      write.table(circ,"Analysis/Nuclear_Coverage/Distribution/Circularity.csv",row.names = F,col.names = F,sep=";")
    }
    write.table(dfmarkcov,paste0("Analysis/Nuclear_Coverage/Distribution/Coverage_",mark[a],".csv"),row.names = F,col.names = F,sep=";")
    #write.table(dfmarkint,paste0("Analysis/Nuclear_Coverage/Distribution/Intensity_",mark[a],".csv"),row.names = F,col.names = F,sep=";")
  }
}

coveragehistograms<-function(){
  for(a in 1:length(mark)){
    ##coverage
    df1<-read.table(paste0("Analysis/Nuclear_Coverage/Distribution/Coverage_",mark[a],".csv"), header=T, sep=";")
    maxcov<-max(df1[,8:ncol(df1)], na.rm=T)
    df1<-df1[,c(1,2,3,8:ncol(df1))]
    colnames(df1)<-c("Biopsy","Group","Tissue",areabreaks[3:length(areabreaks)])
    df1<-melt(df1, id.vars=c("Biopsy","Group","Tissue"))
    df1[,4]<-as.numeric(as.character(df1[,4]))
    df1$Group<-factor(df1$Group, grouporder)

    p<-ggplot(df1, aes(x=variable,y=value, colour=Group))+
      mytheme3+
      facet_wrap(~Tissue, scales = "free_y", nrow=3)+
      stat_summary(fun.y=mean, geom="line",
                   size=1,show.legend = T,alpha=0.8)+
      stat_summary(fun.ymin = function(x) mean(x) - sd(x), 
                   fun.ymax = function(x) mean(x) + sd(x), 
                   geom = 'errorbar', aes(group = Group), width=0.3, show.legend = F,size=0.7)+
      ggtitle(paste0("Nuclear ",mark[a],"-Coverage in Tissues"))+
      labs(x=paste0(mark[a],"-Coverage"),y="Fraction of cells [%]")+
      scale_x_continuous(limits=c(10,100), breaks=seq(0,100,10))+
      scale_y_continuous(limits=c(0,maxcov))
      
    windows(height=300, width=400)
    print(p)
    savePlot(filename=paste0(wd,"/Analysis/Nuclear_Coverage/Distribution/Group_Histogram_",mark[a],"_Coverage_Tissues"),type="png",device=dev.cur())
    
    ##intensity
    #df1<-read.table(paste0("Analysis/Nuclear_Coverage/Distribution/Intensity_",mark[a],".csv"), header=T, sep=";")
    #markmax<-colnames(df1)[length(colnames(df1))]
    #markmax_x<-as.numeric(substring(markmax, 2,nchar(markmax)))
    #markmax_y<-max(df1[,8:ncol(df1)], na.rm=T)
    #intensbreaks<-seq(from=0,to=65535,by=as.numeric(66000)/20)
    
    #df1<-df1[,c(1,2,3,7:ncol(df1))]
    #colnames(df1)<-c("Biopsy","Group","Tissue",intensbreaks[3:length(intensbreaks)])
    #df1<-melt(df1, id.vars=c("Biopsy","Group","Tissue"))
    #df1[,4]<-as.numeric(as.character(df1[,4]))
    #df1$Group<-factor(df1$Group, grouporder)
    
    #p<-ggplot(df1, aes(x=variable,y=value, color=Group))+
     # mytheme3+
     # facet_wrap(~Tissue, scales = "free_y", nrow=3)+
     # stat_summary(fun.y=mean, geom="line",
     #              size=1,show.legend = T,alpha=0.8)+
     # stat_summary(fun.ymin = function(x) mean(x) - sd(x), 
     #              fun.ymax = function(x) mean(x) + sd(x), 
     #              geom = 'errorbar', aes(group = Group), width=0.3, show.legend = F,size=0.7)+
     # ggtitle(paste0("Nuclear ",mark[a],"-Intensity in Tissues"))+
     # labs(x=paste0(mark[a],"-Intensity"),y="Fraction of cells [%]")+
     # scale_x_continuous(limits=c(intensbreaks[3],intensbreaks[20]), breaks=intensbreaks)+
     # scale_y_continuous(limits=c(0,markmax_y))
    
    #windows(height=300, width=400)
    #print(p)
    #savePlot(filename=paste0(wd,"/Analysis/Nuclear_Coverage/Distribution/Group_Histogram_",mark[a],"_Intensity_Tissues"),type="png",device=dev.cur())
   
  }
  ##histograms for area and circularity
  area<-data.frame(read.table("Analysis/Nuclear_Coverage/Distribution/Area.csv",header=T,sep=";"))
  area<-area[,c(1,2,3,7:ncol(area))]
  colnames(area)<-c("Biopsy","Group","Tissue",areabreaks[1:(length(areabreaks)-1)])
  area<-melt(area, id.vars=c("Biopsy","Group","Tissue"))
  area[,4]<-as.numeric(as.character(area[,4]))
  area$Group<-factor(area$Group, grouporder)
  p<-ggplot(area, aes(x=variable,y=value, color=Group))+
    mytheme3+
    facet_wrap(~Tissue, scales = "free_y", nrow=3)+
    stat_summary(fun.y=mean, geom="line",
                 size=1,show.legend = T,alpha=0.8)+
    stat_summary(fun.ymin = function(x) mean(x) - sd(x), 
                 fun.ymax = function(x) mean(x) + sd(x), 
                 geom = 'errorbar', aes(group = Group), width=0.3, show.legend = F,size=0.7)+
    ggtitle(paste0("Nuclear area in Tissues"))+
    labs(x=paste0("Nuclear area [µm²]"),y="Fraction of cells [%]")+
    scale_x_continuous(limits=c(0,100), breaks=seq(0,100,10))+
    geom_vline(xintercept=6)+
    geom_vline(xintercept=45)
  
  windows(height=300, width=400)
  print(p)
  savePlot(filename=paste0(wd,"/Analysis/Nuclear_Coverage/Distribution/Group_Histogram_Area_Tissues"),type="png",device=dev.cur())
  
  
  circ<-data.frame(read.table("Analysis/Nuclear_Coverage/Distribution/Circularity.csv",header=T,sep=";"))
  circ<-circ[,c(1,2,3,7:ncol(circ))]
  colnames(circ)<-c("Biopsy","Group","Tissue",circbreaks[2:length(circbreaks)])
  circ<-melt(circ, id.vars=c("Biopsy","Group","Tissue"))
  circ[,4]<-as.numeric(as.character(circ[,4]))
  circ$Group<-factor(circ$Group, grouporder)
  p<-ggplot(circ, aes(x=variable,y=value, color=Group))+
    mytheme3+
    facet_wrap(~Tissue, scales = "free_y", nrow=3)+
    stat_summary(fun.y=mean, geom="line",
                 size=1,show.legend = T,alpha=0.8)+
    stat_summary(fun.ymin = function(x) mean(x) - sd(x), 
                 fun.ymax = function(x) mean(x) + sd(x), 
                 geom = 'errorbar', aes(group = Group), width=0.03, show.legend = F,size=0.7)+
    ggtitle(paste0("Nuclear circularity in Tissues"))+
    labs(x=paste0("Nuclear circularity"),y="Fraction of cells [%]")+
    scale_x_continuous(limits=c(0,1), breaks=seq(0,1,0.1))+
    geom_vline(xintercept=0.5)+
    geom_vline(xintercept=1)
  
  windows(height=300, width=400)
  print(p)
  savePlot(filename=paste0(wd,"/Analysis/Nuclear_Coverage/Distribution/Group_Histogram_circularity_Tissues"),type="png",device=dev.cur())
}

##settings
if(dir.exists("Results/Nuclear_Coverage")){
  if(!dir.exists("Analysis/Nuclear_Coverage")){
    dir.create("Analysis/Nuclear_Coverage")
    dir.create("Analysis/Nuclear_Coverage/Distribution")
  }
  distributiontables()
  coveragehistograms()
}


##set parameters
parameters<-function(){
  minmark<-""
  minarea<-readline(prompt="Minimum nuclear area [µm²] (0...100): ")
  minarea<-as.numeric(minarea)
  maxarea<-readline(prompt="Maximum nuclear area [µm²] (0...100): ")
  maxarea<-as.numeric(maxarea)
  mincirc<-readline(prompt="Minimum Circularity (0...1): ")
  mincirc<-as.numeric(mincirc)
  maxcirc<-readline(prompt="Maximum Circularity (0...1): ")
  maxcirc<-as.numeric(maxcirc)
  for(a in 1:length(mark)){
    minmarkinput<-readline(prompt=paste("Minimum",mark[a],"Coverage [%] (0...100): "))
    minmarkinput<-as.numeric(minmarkinput)
    minmark<-c(minmark,minmarkinput)
  }
  for(a in 1:length(mark)){
    minmarkinput<-readline(prompt=paste("Minimum",mark[a],"Intensity (0...65535): "))
    minmarkinput<-as.numeric(minmarkinput)
    minmark<-c(minmark,minmarkinput)
  }
  parameters<-data.frame(c("Minimum nuclear area [µm²]","Minimum nuclear area [µm²]",
                           "Minimum Circularity","Maximum Circularity",
                           paste("Minimum",mark, "Coverage [%]"),
                          paste("Minimum",mark, "Intensity")),
                         c(minarea,maxarea,mincirc,maxcirc,minmark[2:length(minmark)]))
  write.table(parameters,file="Analysis/Parameters.csv",sep=";",row.names = F,col.names = F)
}

if(!file.exists("Analysis/Parameters.csv")&file.exists("Results/Nuclear_ROIs")){parameters()}

graphics.off()

if(file.exists("Results/Nuclear_ROIs")){
  parameters<-data.frame(read.table("Analysis/Parameters.csv", header=F,  sep=";"))
  para<-parameters[,2]
}
# Nuclear Coverage in single glomeruli and vicinity -----------------------

##define positive and negative for every nucleus for size, circularity and marker coverage in single glomeruli

inclusion_vectors_gloms<-function(){
  progresscount=0
  ##output folder
  if(!dir.exists(paste0("Analysis/Nuclear_Coverage/Single_", single_tissuesx))){
    dir.create(paste0("Analysis/Nuclear_Coverage/Single_", single_tissuesx))
    dir.create(paste0("Analysis/Nuclear_Coverage/Single_", single_tissuesx,"/Inclusion_Positivity"))
    dir.create(paste0("Analysis/Nuclear_Coverage/Single_", single_tissuesx,"/Relative_Positivity"))
  }
  pb<-winProgressBar(title="Inclusion vectors for single tissues", min=0, max=(length(biop)))
  for(a in 1:length(biop)){
    
    
    ##Setup dataframe
    df2<-c("Glomerulus","total nucleus count","which excluded",c(paste("which", mark,"positive")))
    progresscount=progresscount+1
    glomlist<-list.files(paste0("Results/Nuclear_Coverage/", single_tissues,"/",markers[1],"/",biop[a]))
    for(c in 1:length(glomlist)){
      gvminmark<-""
      for(b in 1:length(mark)){
        if(file.size(paste0("Results/Nuclear_Coverage/", single_tissues,"/",markers[b],"/",biop[a],"/",glomlist[c]))>0){
          ##read data
          dfglom<-data.frame(read.table(paste0("Results/Nuclear_Coverage/", single_tissues,"/",markers[b],"/",biop[a],"/",glomlist[c]),sep="\t",header=T,stringsAsFactors = F))
         
          if(b==1){
            ##for glomeruli
            gmaxarea<-which(dfglom$Area<=para[2])
            gminarea<-which(dfglom$Area>=para[1])
            gmaxcirc<-which(dfglom$Circ.<=para[4])
            gmincirc<-which(dfglom$Circ.>=para[3])
            ginclarea<-intersect(gmaxarea,gminarea)
            ginclcirc<-intersect(gmaxcirc,gmincirc)
            gincl<-intersect(ginclarea,ginclcirc)
            gtota<-1:nrow(dfglom)
            gexcluded<-paste0(gtota[!gtota%in%gincl],collapse="-")
          }
          ##glom marker
          gminmark<-intersect(which(dfglom$X.Area>=para[b+4]),gincl)
          gvminmark<-c(gvminmark,paste0(gminmark,collapse="-"))
        }
          setWinProgressBar(pb, progresscount)
      }
      v1<-c(substr(glomlist[c],0,nchar(glomlist[c])-4),nrow(dfglom), gexcluded,gvminmark[2:length(gvminmark)])
      df2<-rbind(df2,v1)
    }
    write.table(df2,file=paste0("Analysis/Nuclear_Coverage/Single_", single_tissuesx,"/Inclusion_Positivity/",biop[a],".csv"),row.names = F,col.names = F,sep=";")
    
  }
  close(pb)
}

##relative count for single glomeruli and vicinity
relative_numbers_gloms<-function(){
  pb<-winProgressBar(title="Positive nuclei for single tissues", min=0, max=length(biop))
  progresscount<-0
  ##reading data
  for (a in 1:length(biop)){
    progresscount=progresscount+1
    df2<-c("Glomerulus","Total particle count","Included","Included [%] of total count", "Excluded [%]",coln)
    
    df1<-read.table(paste0("Analysis/Nuclear_Coverage/Single_",single_tissuesx,"/Inclusion_Positivity/",biop[a],".csv"),header=T,sep=";")

    #start
    for(b in 1:nrow(df1)){

      ##for glomeruli
      vtotal<-1:as.numeric(df1[b,2])
      excluded<-as.character(df1[b,3])
      excluded<-unlist(strsplit(excluded,"-"))
      included<-vtotal[!vtotal%in%excluded]
      ntot<-as.numeric(df1[b,2])
      nin<-length(included)
      perin<-nin/ntot*100
      perout<-100-perin
      v2<-c(df1[b,1],ntot,nin,perin,perout)

      ##getting values for marker combination

      for(d in 1:nrow(perm)){
        v3<-included
        for(e in 1:ncol(perm)){
          vmark<-as.vector(unlist(strsplit(as.character(df1[b,e+3]),"-")))
          if(perm[d,e]=="pos."){v3<-intersect(v3,vmark)}
          if(perm[d,e]=="neg."){v3<-intersect(v3,included[!included%in%vmark])}else{v3<-v3}
        }
        v2<-c(v2, length(v3)/nin*100)
      }
      df2<-rbind(df2,v2)
    }
    write.table(df2,paste0("Analysis/Nuclear_Coverage/Single_", single_tissuesx,"/Relative_Positivity/",biop[a],".csv"),sep=";",row.names = F,col.names = F)
    setWinProgressBar(pb, progresscount)
  }
  close(pb)
}

##relative count for single glomeruli and vicinity

relative_numbers_gloms_summary<-function(){

  #set up dataframe
  coln2<-""
  for(a in 1:length(coln)){
    coln2<-c(coln2,coln[a],"SD","n")
  }
  coln2<-coln2[2:length(coln2)]
  df2<-c("Biopsy","Group","Total Particle Count","Included [%] of total","Excluded [%]","Number of nuclei","","",coln2)
  
  #start
  for(a in 1:length(biop)){
  
    ##read data
    df1<-data.frame(read.table(paste0("Analysis/Nuclear_Coverage/Single_", single_tissuesx,"/Relative_Positivity/",biop[a],".csv"),header=T,sep=";",stringsAsFactors = F))
    ncol3<-(ncol(df1)-5)
    ##for glomeruli
    meantot<-mean(df1[,2], na.rm = T)
    meanperin<-mean(df1[,4], na.rm = T)
    meanperout<-mean(df1[,5], na.rm = T)
    nin<-sum(df1[,3], na.rm = T)
    meanin<-mean(df1[,3], na.rm = T)
    sdin<-sd(df1[,3], na.rm = T)
    v1<-c(biop[a],as.character(group[group[,1]==biop[a],2]),meantot,meanperin,meanperout,meanin,sdin,nin)
    for(b in 6:(ncol3+5)){
      meanmark<-mean(df1[,b], na.rm=T)
      sdmark<-sd(df1[,b], na.rm=T)
      v1<-c(v1,meanmark,sdmark,nin)
    }
    df2<-rbind(df2,v1)
  }  
  write.table(df2,paste0("Analysis/Nuclear_Coverage/Single_", single_tissuesx,"/Summary_", single_tissuesx,".csv"),sep=";",col.names = F,row.names = F)
}

# Nuclear Coverage for Tissues --------------------------------------------

##define positive and negative for every nucleus for size, circularity and marker coverage/intensity in tissues
inclusion_vectors_tissues<-function(){
  pb<-winProgressBar(title="Inclusion vectors for tissues", min=0, max=(length(biop)*length(tissues)))
  df2<-c("Biopsy","Group","Tissue","total","which excluded",paste("which", mark,"positive")) ##coverage
  #df3<-c("Biopsy","Group","Tissue","total","which excluded",paste("which", mark,"positive")) ##intensity
  progresscount=0
  for(a in 1:length(tissues)){
    for(b in 1:length(biop)){
      progresscount=progresscount+1
      vmincov<-""
      #vminint<-""
      for(c in 1:length(markers)){
        dfcov<-read.table(paste0("Results/Nuclear_Coverage/",tissues[a],"/",markers[c],"/",biop[b],".txt"),header=T,sep="\t")
        #dfint<-read.table(paste0("Results/Nuclear_Intensity/",tissues[a],"/",markers[c],"/",biop[b],".txt"),header=T,sep="\t")
        if(c==1){
          maxarea<-which(dfcov$Area<=para[2])
          minarea<-which(dfcov$Area>=para[1])
          maxcirc<-which(dfcov$Circ.<=para[4])
          mincirc<-which(dfcov$Circ.>=para[3])
          inclarea<-intersect(maxarea,minarea)
          inclcirc<-intersect(maxcirc,mincirc)
          incl<-intersect(inclarea,inclcirc)
          tota<-1:nrow(dfcov)
          excluded<-paste0(tota[!tota%in%incl],collapse="-")
        }
        mincov<-intersect(which(dfcov$X.Area>=para[c+4]),incl)
        vmincov<-c(vmincov,paste0(mincov,collapse="-"))
        
        #minint<-intersect(which(dfint$Mean>=para[c+4+length(mark)]), incl)
        #vminint<-c(vminint,(paste0(minint, collapse="-")))
      }
      df2<-rbind(df2,c(biop[b],as.character(group[group[,1]==biop[b],2]),tissues[a],
                       nrow(dfcov), excluded,vmincov[2:length(vmincov)]))
      #df3<-rbind(df3,c(biop[b],as.character(group[group[,1]==biop[b],2]),tissues[a],
      #                 nrow(dfint), excluded,vminint[2:length(vminint)]))
      setWinProgressBar(pb, progresscount)
    }
    
  }
  close(pb)
  write.table(df2,file="Analysis/Nuclear_Coverage/Inclusion_Positivity_Coverage.csv",row.names = F,col.names = F,sep=";")
  #write.table(df3,file="Analysis/Nuclear_Coverage/Inclusion_Positivity_Intensity.csv",row.names = F,col.names = F,sep=";")
}

##getting relative counts for included and positive nuclei (all combinations)
relative_numbers_tissues<-function(){
  pb<-winProgressBar(title="Positive nuclei for tissues", min=0, max=(length(biop)*length(tissues)))
  progresscount=0
  #setting the data frame
  coln<-""
  for(a in 1:nrow(perm)){
    c1<-paste(mark,perm[a,])
    c1<-paste(c1, collapse="/")
    c1<-paste(c1,"[%]")
    coln<-c(coln,c1)
  }
  coln<-coln[2:length(coln)]
  
  df2<-c("Biopsy","Group","Tissue",
         "Total particle count","Included","Included [%] of total count", "Excluded [%]",coln)
  #df3<-c("Biopsy","Group","Tissue",
  #       "Total particle count","Included","Included [%] of total count", "Excluded [%]",coln)
  
  ##reading data
  dfcov<-data.frame(read.table("Analysis/Nuclear_Coverage/Inclusion_Positivity_Coverage.csv",header=F,sep=";",colClasses = "character"))
  #dfint<-data.frame(read.table("Analysis/Nuclear_Coverage/Inclusion_Positivity_Intensity.csv",header=F,sep=";",colClasses = "character"))
  
  #start
  for(a in 1:length(tissues)){
    for(b in 1:length(biop)){
      progresscount=progresscount+1
      v1<-subset(dfcov,dfcov[,1]==biop[b]&dfcov[,3]==tissues[a])
      #v2<-subset(dfint,dfint[,1]==biop[b]&dfint[,3]==tissues[a])
      vtotal<-1:as.numeric(v1[4])
      excluded<-as.character(v1[5])
      excluded<-unlist(strsplit(excluded,"-"))
      included<-vtotal[!vtotal%in%excluded]
      ntot<-as.numeric(v1[4])
      nin<-length(included)
      perin<-nin/ntot*100
      perout<-100-perin
      vcov<-c(biop[b],as.character(group[group[,1]==biop[b],2]),tissues[a],ntot,nin,perin,perout)
      #vint<-vcov
      
      ##getting values for marker combination
      for(d in 1:nrow(perm)){
        v3<-v4<-included
        for(e in 1:ncol(perm)){
          vmarkcov<-as.vector(unlist(strsplit(as.character(v1[e+5]),"-")))
          #vmarkint<-as.vector(unlist(strsplit(as.character(v2[e+5]),"-")))
          if(perm[d,e]=="pos."){
            v3<-intersect(v3,vmarkcov)
            #v4<-intersect(v4,vmarkint)
          }
          if(perm[d,e]=="neg."){
            v3<-intersect(v3,included[!included%in%vmarkcov])
            #v4<-intersect(v4,included[!included%in%vmarkint])
          }else{
            v3<-v3
            #v4<-v4
          }
        }
        vcov<-c(vcov, length(v3)/nin*100)
        #vint<-c(vint, length(v4)/nin*100)
      }
      df2<-rbind(df2,vcov)
      #df3<-rbind(df3, vint)
      setWinProgressBar(pb, progresscount)
    }
  }
  write.table(df2,file="Analysis/Nuclear_Coverage/Relative_Positivity_Coverage.csv",row.names = F,col.names = F,sep=";")
  #write.table(df3,file="Analysis/Nuclear_Coverage/Relative_Positivity_Intensity.csv",row.names = F,col.names = F,sep=";")
  close(pb)
}

## Run
if(file.exists("Results/Nuclear_Coverage")){
  if(length(single_tissues)>0){
    inclusion_vectors_gloms()
    relative_numbers_gloms() 
    relative_numbers_gloms_summary()
  }
  inclusion_vectors_tissues()
  relative_numbers_tissues()
}


# SINGLE GLOM TABLES -------------------------

if(length(single_tissues)>0){
  dir.create("Analysis/Other")
  ##max glom number in experiment
  df1<-read.table(paste0("Analysis/Total_Area/Single_", single_tissuesx, "_Area.csv"),sep=";",header=T, stringsAsFactors = F)
  maxglom<-max(as.numeric(df1[1:nrow(df1),5]))
  
  ##area
  #setup data.frame
  df1<-c("Biopsy","Group",paste0("Number ", 1:maxglom," [µm²]"))
  for (a in 1:length(biop)){
    df2<-read.table(paste0("Analysis/Total_Area/Single_", single_tissuesx, "/",biop[a],".csv"), header=F,sep=";", stringsAsFactors = F)
    glomarea<-as.numeric(df2[2:(nrow(df2)),2])
    df1<-rbind(df1, 
               c(biop[a],as.character(group[,2][group[,1]==biop[a]]), glomarea, rep("",times=maxglom-length(glomarea))))

  }
  write.table(df1,paste0("Analysis/Other/all_", single_tissuesx, "_area.csv"), sep=";", row.names = F, col.names = F)
  
  ##marker coverage [%]
  dir.create(paste0("Analysis/Total_Area/Single_", single_tissuesx, "_Summary"))
  for(a in 1:length(mark)){
    #setup data.frame
    dfglom<-c("Biopsy","Group",paste0("Number ", 1:maxglom," [%]"))
    for (b in 1:length(biop)){
      df2<-read.table(paste0("Analysis/Total_Area/Single_", single_tissuesx, "/",biop[b],".csv"), header=F,sep=";", stringsAsFactors = F)
      glompos<-as.numeric(df2[2:(nrow(df2)),5+3*(a-1)])
      dfglom<-rbind(dfglom, 
                    c(biop[b],as.character(group[,2][group[,1]==biop[a]]), glompos, rep("",times=maxglom-length(glompos))))
    }
    write.table(dfglom,paste0("Analysis/Total_Area/Single_", single_tissuesx, "_Summary/",mark[a],"_Coverage_", single_tissuesx, ".csv"), sep=";", row.names = F, col.names = F)
  }
  
  if(file.exists("Results/Nuclear_Coverage")){
    #nuclear density
    glomdens<-c("Biopsy","Group",paste0("Number ", 1:maxglom," [cells per µm²]"))
    for (a in 1:length(biop)){
      df2<-read.table(paste0("Analysis/Total_Area/Single_", single_tissuesx, "/",biop[a],".csv"), header=T,sep=";", stringsAsFactors = F)
      df3<-read.table(paste0("Analysis/Nuclear_Coverage/Single_", single_tissuesx, "/Relative_Positivity/",biop[a],".csv"), header=T,sep=";", stringsAsFactors = F)
      nomnuclei<-df3$Included
      glomarea<-df2$"Area..µm²."
      nucleidens<-nomnuclei/glomarea
      
      glomdens<-rbind(glomdens,
                      c(biop[a],as.character(group[,2][group[,1]==biop[a]]),
                        nucleidens, rep("",times=maxglom-length(glomarea))))

    }
    write.table(glomdens,paste0("Analysis/Other/all_", single_tissuesx, "_nuclear_density.csv"), sep=";", row.names = F, col.names = F)
    
    ##nuclear coverage for all combinations
    dir.create(paste0("Analysis/Nuclear_Coverage/Single_", single_tissuesx, "/Summary"))
    coln1<-substring(coln,1,nchar(coln)-4)
    coln1<-gsub("/","_",coln1)
    coln1<-gsub("pos.","pos",coln1)
    coln1<-gsub("neg.","neg",coln1)
    
    for(a in 1:length(coln)){
      #setup dataframe
      df2<-c("Biopsy","Group",paste0("Number ", 1:maxglom," [%-cells]"))
      
      for(b in 1:length(biop)){
        df1<-read.table(paste0("Analysis/Nuclear_Coverage/Single_", single_tissuesx, "/Relative_Positivity/", biop[b],".csv"), header=T, sep=";",stringsAsFactors = F)
        dfglom<-df1[,6:ncol(df1)]
        dfglom<-dfglom[,a]
        df2<-rbind(df2, 
                   c(biop[b],as.character(group[,2][group[,1]==biop[b]]), dfglom, rep("",times=maxglom-length(dfglom))))
        
      }
      write.table(df2, paste0("Analysis/Nuclear_Coverage/Single_", single_tissuesx, "/Summary/", single_tissuesx, "_",coln1[a],".csv"), sep=";", col.names = F, row.names = F)
    }
  }
}

# GRAPHS ------------------------------------------------------------------
# total area of marker positivity in every tissue for groups --------------
##only with 6 tissues

  df1<-data.frame(read.table("Analysis/Total_Area/Tissue_Summary.csv",sep=";",header=T))
  df1$Tissue<-as.factor(df1$Tissue)
  df1$Group<-as.factor(df1$Group)
  
  ##sort groups and tissues
  df1[,2]<-factor(df1[,2],grouporder)
  windows(height=50,width=80)
  
  for(a in 1:length(mark)){
    
    ##area
    df2<-df1[,c(1:3, 5+((a-1)*2))]
    df3<-melt(df2,id.vars=c("Biopsy","Group","Tissue"))
    
    p<-ggplot(df3, aes(x=Group,y=value))+
      geom_jitter(size=3,alpha=0.4,position=position_jitter(width=0.1, height=0))+
      mytheme3+
      facet_wrap(~Tissue,scales="free_y")+
      stat_summary(fun.y=mean, geom="point", shape=18,
                   size=4, color="red",show.legend = F,alpha=0.8)+
      stat_summary(fun.ymin = function(x) mean(x) - sd(x), 
                   fun.ymax = function(x) mean(x) + sd(x), 
                   geom = 'errorbar', aes(group = Group),color="red", width=0.3, show.legend = F,size=0.7)+
      stat_summary(fun.y = median, fun.ymin = median, fun.ymax = median,
                   geom = "crossbar", width = 0.5,color="darkred",alpha=0.6, size=.3)+
      ggtitle(paste0("Total ",mark[a],"-Coverage in Tissues"))+
      labs(y=paste0(mark[a],"-Coverage [%]"),x="")
      
  
    print(p)
    savePlot(filename=paste0(wd,"/Analysis/Total_Area/Total_",mark[a],"_Area_Tissues"),type="png",device=dev.cur())
    
    ##intensity
    df2<-df1[,c(1:3, 6+((a-1)*2))]
    df3<-melt(df2,id.vars=c("Biopsy","Group","Tissue"))
    p<-ggplot(df3, aes(x=Group,y=value))+
      geom_jitter(size=3,alpha=0.4,position=position_jitter(width=0.1, height=0))+
      mytheme3+
      facet_wrap(~Tissue,scales="free_y")+
      stat_summary(fun.y=mean, geom="point", shape=18,
                   size=4, color="red",show.legend = F,alpha=0.8)+
      stat_summary(fun.ymin = function(x) mean(x) - sd(x), 
                   fun.ymax = function(x) mean(x) + sd(x), 
                   geom = 'errorbar', aes(group = Group),color="red", width=0.3, show.legend = F,size=0.7)+
      stat_summary(fun.y = median, fun.ymin = median, fun.ymax = median,
                   geom = "crossbar", width = 0.5,color="darkred",alpha=0.6, size=.3)+
      ggtitle(paste0("Total ",mark[a],"-Intensity in Tissues"))+
      labs(y=paste0(mark[a],"-Intensity"),x="")
    
    
    print(p)
    savePlot(filename=paste0(wd,"/Analysis/Total_Area/Total_",mark[a],"_Intensity_Tissues"),type="png",device=dev.cur())
  }
  
  if(file.exists("Results/Nuclear_Coverage")){
    # Nuclear coverage tissues ------------------------------------------------
    
    df1<-read.table("Analysis/Nuclear_Coverage/Relative_Positivity_Coverage.csv",sep=";",header=T)
    df1$Tissue<-as.factor(df1$Tissue)
    df1$Group<-as.factor(df1$Group)
    
    df1[,2]<-factor(df1[,2],grouporder)

    coln1<-substring(coln,1,nchar(coln)-4)
    coln1<-gsub("/","_",coln1)
    coln1<-gsub("pos.","pos",coln1)
    coln1<-gsub("neg.","neg",coln1)
    
    for(a in 8:ncol(df1)){
      df2<-df1[,c(1:3,a)]
      colnames(df2)<-c("Biopsy","Group","Tissue","value")
      p<-ggplot(df2, aes(x=Group,y=value))+
        geom_jitter(size=3,alpha=0.4,position=position_jitter(width=0.1, height=0))+
        mytheme3+
        facet_wrap(~Tissue,scales="free_y")+
        stat_summary(fun.y=mean, geom="point", shape=18,
                     size=4, color="red",show.legend = F,alpha=0.8)+
        stat_summary(fun.ymin = function(x) mean(x) - sd(x), 
                     fun.ymax = function(x) mean(x) + sd(x), 
                     geom = 'errorbar', aes(group = Group),color="red", width=0.3, show.legend = F,size=0.7)+
        stat_summary(fun.y = median, fun.ymin = median, fun.ymax = median,
                     geom = "crossbar", width = 0.5,color="darkred",alpha=0.6, size=.3)+
        ggtitle(paste0(coln[a-7]," - of cells"))+
        labs(y=paste0("Fraction of cells [%]"),x="")
      print(p)
      savePlot(filename=paste0(wd,"/Analysis/Nuclear_Coverage/Fraction_of_",coln1[a-7],"_Coverage"),type="png",device=dev.cur())
    }
  
  
    # Nuclear Intensity tissues ------------------------------------------------
    
    #df1<-read.table("Analysis/Nuclear_Coverage/Relative_Positivity_Intensity.csv",sep=";",header=T)
    #df1$Tissue<-as.factor(df1$Tissue)
    #df1$Group<-as.factor(df1$Group)
    
    #df1[,2]<-factor(df1[,2],grouporder)
    
    #coln1<-substring(coln,1,nchar(coln)-4)
    #coln1<-gsub("/","_",coln1)
    #coln1<-gsub("pos.","pos",coln1)
    #coln1<-gsub("neg.","neg",coln1)
    
    #for(a in 8:ncol(df1)){
    #  df2<-df1[,c(1:3,a)]
    #  colnames(df2)<-c("Biopsy","Group","Tissue","value")
    #  p<-ggplot(df2, aes(x=Group,y=value))+
    #    geom_jitter(size=3,alpha=0.4,position=position_jitter(width=0.1, height=0))+
    #    mytheme3+
    #    facet_wrap(~Tissue,scales="free_y")+
    #    stat_summary(fun.y=mean, geom="point", shape=18,
    #                 size=4, color="red",show.legend = F,alpha=0.8)+
    #    stat_summary(fun.ymin = function(x) mean(x) - sd(x), 
    #                 fun.ymax = function(x) mean(x) + sd(x), 
    #                 geom = 'errorbar', aes(group = Group),color="red", width=0.3, show.legend = F,size=0.7)+
    #    stat_summary(fun.y = median, fun.ymin = median, fun.ymax = median,
    #                 geom = "crossbar", width = 0.5,color="darkred",alpha=0.6, size=.3)+
    #    ggtitle(paste0(coln[a-7]," - of cells"))+
    #    labs(y=paste0("Fraction of cells [%]"),x="")
    #  print(p)
    #  savePlot(filename=paste0(wd,"/Analysis/Nuclear_Coverage/Fraction_of_",coln1[a-7],"_Intensity"),type="png",device=dev.cur())
    #}
  }

if(length(single_tissues>0)){
  # Area marker coverage for glomeruli+vicinity and glom area --------
  tables<-c(paste0("Single_", single_tissuesx, "_",c("Area",mark)))
  
  for(a in 1:length(tables)){
    df1<-data.frame(read.table(paste0("Analysis/Total_Area/",tables[a],".csv"),header=T,sep=";", stringsAsFactors = F))
    df1[,2]<-factor(df1[,2])
    df1[,2]<-factor(df1[,2],grouporder)
    df1<-with(df1,df1[order(df1[,2]),])

    if(a==1){
      ##for glomerular area
      ##for 90% percentile
      df2<-df1[,1:3]
      colnames(df2)<-c("Biopsy","Group","Value")
      
      p<-ggplot(df2, aes(x=Group,y=Value))+
        geom_jitter(size=2,alpha=0.4,aes(x=Group,y=Value),position=position_jitter(width=0.1, height=0))+
        mytheme3+
        stat_summary(fun.y=mean, geom="point", shape=18,
                     size=4, color="red",show.legend = F,alpha=0.5)+
        stat_summary(fun.ymin = function(x) mean(x) - sd(x), 
                     fun.ymax = function(x) mean(x) + sd(x), 
                     geom = 'errorbar', aes(group = Group),color="red", width=0.3, show.legend = F,size=0.5)+
        stat_summary(fun.y = median, fun.ymin = median, fun.ymax = median,
                     geom = "crossbar", width = 0.5,color="darkred",alpha=0.6, size=.3)+
        ggtitle(paste0("Glomerular Area"))+
        labs(y=paste0("Glomerular Area [µm²]"),x="")
      print(p)
      savePlot(filename=paste0(wd,"/Analysis/Total_Area/Area_Single_", single_tissuesx),type="png",device=dev.cur())
    }else{
      df2<-df1[,1:3]
      colnames(df2)<-c("Biopsy","Group","Value")
      p<-ggplot(df2, aes(x=Group,y=Value))+
        geom_jitter(size=2,alpha=0.4,aes(x=Group,y=Value),position=position_jitter(width=0.1, height=0))+
        mytheme3+
        stat_summary(fun.y=mean, geom="point", shape=18,
                     size=4,show.legend = F,alpha=0.5)+
        stat_summary(fun.ymin = function(x) mean(x) - sd(x), 
                     fun.ymax = function(x) mean(x) + sd(x), 
                     geom = 'errorbar', width=0.3, show.legend = F,size=0.5)+
        stat_summary(fun.y = median, fun.ymin = median, fun.ymax = median,
                     geom = "crossbar", width = 0.5,alpha=0.6, size=.3)+
        ggtitle(paste0(mark[a-1],"-Coverage"))+
        labs(y=paste0(mark[a-1],"-Coverage [%]"),x="")+
        theme(legend.position = "right",
              legend.key=element_rect(fill="transparent"))
      print(p)
      savePlot(filename=paste0(wd,"/Analysis/Total_Area/",mark[a-1],"_Single_", single_tissuesx),type="png",device=dev.cur())
    }
  }
  
  
  
  if(file.exists("Results/Nuclear_Coverage")){
    # Nuclear Density in Gloms---------------------------------------------------------
    df2<-read.table(paste0("Analysis/Total_Area/Single_", single_tissuesx, "_Area.csv"),stringsAsFactors = F,sep=";", header=T)
    df3<-read.table(paste0("Analysis/Nuclear_Coverage/Single_", single_tissuesx, "/Summary_", single_tissuesx, ".csv"),stringsAsFactors = F,sep=";", header=T)

    df4<-df2[,1:3]
    v1<-df3[,3]*df3[,5]/100
    df4<-cbind(df4,v1)
    df4$density<-df4[,4]/df4[,3]
    df4[,2]<-as.factor(df4[,2])
    
    df4[,2]<-factor(df4[,2],grouporder)
    df4<-with(df4,df4[order(df4[,2]),])  
    
    p<-ggplot(df4, aes(x=Group,y=density))+
      geom_jitter(size=2,alpha=0.4,aes(x=Group,y=density),position=position_jitter(width=0.1, height=0))+
      mytheme3+
      stat_summary(fun.y=mean, geom="point", shape=18,
                   size=4, color="red",show.legend = F,alpha=0.5)+
      stat_summary(fun.ymin = function(x) mean(x) - sd(x), 
                   fun.ymax = function(x) mean(x) + sd(x), 
                   geom = 'errorbar', aes(group = Group),color="red", width=0.3, show.legend = F,size=0.5)+
      stat_summary(fun.y = median, fun.ymin = median, fun.ymax = median,
                   geom = "crossbar", width = 0.5,color="darkred",alpha=0.6, size=.3)+
      ggtitle(paste0("Nuclear density in ", single_tissuesx))+
      labs(y=paste0("Cells per µm²"),x="")
    print(p)
    savePlot(filename=paste0(wd,"/Analysis/Nuclear_Coverage/Nuclear_density_in_", single_tissuesx),type="png",device=dev.cur())
    
    # Nuclear Numbers in Gloms ------------------------------------------------
    df3<-read.table(paste0("Analysis/Nuclear_Coverage/Single_", single_tissuesx, "/Summary_", single_tissuesx, ".csv"),stringsAsFactors = F,sep=";", header=T)
    
    df4<-df3[,c(1,2,6)]
    colnames(df4)<-c("Biopsy","Group","Nuclei")
    
    df4[,2]<-as.factor(df4[,2])
    df4[,2]<-factor(df4[,2],grouporder)
    
    p<-ggplot(df4, aes(x=Group,y=Nuclei))+
      geom_jitter(size=2,alpha=0.4,aes(x=Group,y=Nuclei),position=position_jitter(width=0.1, height=0))+
      mytheme3+
      stat_summary(fun.y=mean, geom="point", shape=18,
                   size=4, color="red",show.legend = F,alpha=0.5)+
      stat_summary(fun.ymin = function(x) mean(x) - sd(x), 
                   fun.ymax = function(x) mean(x) + sd(x), 
                   geom = 'errorbar', aes(group = Group),color="red", width=0.3, show.legend = F,size=0.5)+
      stat_summary(fun.y = median, fun.ymin = median, fun.ymax = median,
                   geom = "crossbar", width = 0.5,color="darkred",alpha=0.6, size=.3)+
      ggtitle(paste0("Nuclear number in ", single_tissuesx))+
      labs(y=paste0("Cells per Glomerulus"),x="")
    print(p)
    savePlot(filename=paste0(wd,"/Analysis/Nuclear_Coverage/Nuclear_number_in_", single_tissuesx),type="png",device=dev.cur())
       
  }
}

# Single Glom Graphs ------------------------------------------------------
if(length(single_tissues>0)){
  # For single biopsies, all glomeruli, sorted by groups-----------------------------------------------------
  
  mytheme3 <- theme(legend.text = element_text(face = "italic",size = rel(1)), 
                    axis.title = element_text(size = rel(1.2)), 
                    axis.text = element_text(size = rel(1.0)), 
                    axis.line = element_line(size = 1,colour = "black"), 
                    axis.ticks = element_line(colour="black",size = rel(2)),
                    panel.background = element_rect(fill = "white", colour="black"), 
                    legend.key = element_rect(fill = "gray4"),
                    panel.grid.minor = element_line(colour="grey"),
                    panel.grid.major = element_line(colour="grey"),
                    legend.title = element_text(size = rel(1.5)), 
                    plot.title = element_text(face = "bold",
                                              size = rel(1.7),hjust=0.5),
                    axis.text.x = element_text(angle = 90, hjust = 1))
  
  # Total Area of marker coverage
  ###Glomerular Area
  #set up data frame
  df2<-data.frame("","","","", stringsAsFactors = F)
  colnames(df2)<-c("Biopsy","Group", "Glomerulus","Area")
  
  for(a in 1:length(biop)){
    df1<-read.table(paste0("Analysis/Total_Area/Single_", single_tissuesx, "/",biop[a],".csv"),stringsAsFactors = F,sep=";")
    df3<-cbind(rep(biop[a],times=nrow(df1)),
               rep(as.character(group[,2][group[,1]==biop[a]],times=nrow(df1))),
               1:(nrow(df1)),
               as.numeric(df1[,2][3:(nrow(df1))]))
    colnames(df3)<-c("Biopsy","Group", "Glomerulus","Area")
    df2<-rbind(df2,df3)
  }
  df2<-df2[2:nrow(df2),]
  df2[,4]<-as.numeric(df2[,4])
  
  #sort data.frame
  
  df2$Group<-as.factor(df2$Group)
  df2$Biopsy<-as.factor(df2$Biopsy)
  df2[,2]<-factor(df2[,2],grouporder)
  df2<-with(df2,df2[order(df2[,2]),])
  
  p<-ggplot(df2, aes(x=Group,y=Area, group=Biopsy))+
    geom_jitter(size=2,alpha=0.4,aes(x=Group,y=Area),position=position_dodge(width=0.7))+
    mytheme3+
    stat_summary(fun.y=mean, geom="point", shape=18,
                 size=4, color="black",show.legend = F,alpha=0.5,
                 position=position_dodge(width=0.7), aes(group = Biopsy))+
    stat_summary(fun.ymin = function(x) mean(x) - sd(x), 
                 fun.ymax = function(x) mean(x) + sd(x), 
                 geom = 'errorbar', aes(group = Biopsy),position=position_dodge(width=0.7),
                 color="black", width=0.3, show.legend = F,size=0.5)+
    stat_summary(fun.y = median, fun.ymin = median, fun.ymax = median,aes(group = Biopsy),
                 position=position_dodge(width=0.7),
                 geom = "crossbar", width = 0.5,color="darkred",alpha=0.6, size=.3)+
    ggtitle(paste0(single_tissuesx," Area"))+
    labs(y=paste0(single_tissuesx," Area [µm²]"),x="", fill="Groups")+
    theme(legend.position = "none")+
    geom_text(position = position_dodge(width = 1), aes(y=0.9*max(df2$Area), label=Biopsy), angle=90)
  
  print(p)
  
  dir.create(paste0("Analysis/Total_Area/Single_", single_tissuesx, "_Graphs"))
  savePlot(filename=paste0(wd,"/Analysis/Total_Area/Single_", single_tissuesx, "_Graphs/", single_tissuesx, "_Area"),type="png",device=dev.cur())
  
  ##marker coverage
  for(b in 1:length(mark)){
    df2<-data.frame("","","","", stringsAsFactors = F)
    colnames(df2)<-c("Biopsy","Group", "Glomerulus","Marker")
    
    for(a in 1:length(biop)){
      df1<-read.table(paste0("Analysis/Total_Area/Single_", single_tissuesx, "/",biop[a],".csv"),stringsAsFactors = F,sep=";", header=T)
      df3<-cbind(rep(biop[a],times=nrow(df1)),
                 rep(as.character(group[,2][group[,1]==biop[a]]),times=nrow(df1)),
                 1:nrow(df1),
                 as.numeric(df1[,1+b*2]))
      colnames(df3)<-c("Biopsy","Group", "Glomerulus","Marker")
      df2<-rbind(df2,df3)
    }
    df2$Marker<-as.numeric(df2$Marker)
    #sort data.frame
    df2$Group<-as.factor(df2$Group)
    
    df2[,2]<-factor(df2[,2],grouporder)
    df2<-with(df2,df2[order(df2[,2]),])
    
    df2$Biopsy<-as.factor(df2$Biopsy)
    
    p<-ggplot(df2, aes(x=Group,y=Marker, group=Biopsy))+
      geom_point(size=2,alpha=0.4,aes(x=Group,y=Marker),position=position_dodge(width=0.7))+
      mytheme3+
      stat_summary(fun.y=mean, geom="point", shape=18,
                   size=4, color="black",show.legend = F,alpha=0.5,
                   position=position_dodge(width=0.7), aes(group = Biopsy))+
      stat_summary(fun.ymin = function(x) mean(x) - sd(x), 
                   fun.ymax = function(x) mean(x) + sd(x), 
                   geom = 'errorbar', aes(group = Biopsy),position=position_dodge(width=0.7),
                   color="black", width=0.3, show.legend = F,size=0.5)+
      stat_summary(fun.y = median, fun.ymin = median, fun.ymax = median,aes(group = Biopsy),
                   position=position_dodge(width=0.7),
                   geom = "crossbar", width = 0.5,color="darkred",alpha=0.6, size=.3)+
      theme(legend.position = "none")+
      geom_text(position = position_dodge(width = 1), aes(y=0.9*max(df2$Marker, na.rm=T), label=Biopsy), angle=90)+
      ggtitle(paste0(mark[b],"-Coverage"))+
      labs(y=paste0(mark[b],"-positive Area [%]"),x="", fill="Groups")
    
    print(p)
    
    savePlot(filename=paste0(wd,"/Analysis/Total_Area/Single_", single_tissuesx, "_Graphs/Total_Area_",mark[b]),type="png",device=dev.cur())
    
  }
  
  if(file.exists("Results/Nuclear_Coverage")){
    ##Nuclear Density
    
    df2<-data.frame("","","","", stringsAsFactors = F)
    colnames(df2)<-c("Biopsy","Group", "Glomerulus","Density")
    
    for(a in 1:length(biop)){
      
      glomarea<-read.table(paste0("Analysis/Total_Area/Single_", single_tissuesx, "/",biop[a],".csv"),stringsAsFactors = F,sep=";")
      glomnuc<-read.table(paste0("Analysis/Nuclear_Coverage/Single_", single_tissuesx, "/Relative_Positivity/",biop[a],".csv"),stringsAsFactors = F,sep=";")
      
      glomdens<-as.numeric(glomnuc[3:(nrow(glomnuc)),3])/as.numeric(glomarea[3:(nrow(glomarea)),2])
      
      df3<-cbind(rep(biop[a],times=nrow(glomarea)),
                 rep(as.character(group[,2][group[,1]==biop[a]],times=nrow(glomarea))),
                 1:(nrow(glomarea)),
                 as.numeric(glomdens))
      colnames(df3)<-c("Biopsy","Group", "Glomerulus","Density")
      df2<-rbind(df2,df3)
    }
    
    df2<-df2[2:nrow(df2),]
    df2[,4]<-as.numeric(df2[,4])
    
    #sort data.frame
    df2$Group<-as.factor(df2$Group)
    df2[,2]<-factor(df2[,2],grouporder)
    df2<-with(df2,df2[order(df2[,2]),])
    
    df2$Biopsy<-as.factor(df2$Biopsy)
    
    p<-ggplot(df2, aes(x=Group,y=Density, group=Biopsy))+
      geom_jitter(size=2,alpha=0.4,position=position_dodge(width=0.7))+
      mytheme3+
      stat_summary(fun.y=mean, geom="point", shape=18,
                   size=4, color="black",show.legend = F,alpha=0.5,
                   position=position_dodge(width=0.7), aes(group = Biopsy))+
      stat_summary(fun.ymin = function(x) mean(x) - sd(x), 
                   fun.ymax = function(x) mean(x) + sd(x), 
                   geom = 'errorbar', aes(group = Biopsy),position=position_dodge(width=0.7),
                   color="black", width=0.3, show.legend = F,size=0.5)+
      stat_summary(fun.y = median, fun.ymin = median, fun.ymax = median,aes(group = Biopsy),
                   position=position_dodge(width=0.7),
                   geom = "crossbar", width = 0.5,color="darkred",alpha=0.6, size=.3)+
      theme(legend.position = "none")+
      geom_text(position = position_dodge(width = 1), aes(y=0.9*max(df2$Density), label=Biopsy), angle=90)+      ggtitle(paste0(mark[b],"-Coverage"))+
      ggtitle(paste0("Cellular Density"))+
      labs(y=paste0("Cells per µm²"),x="", fill="Groups")
    
    print(p)
    
    savePlot(filename=paste0(wd,"/Analysis/Total_Area/Single_", single_tissuesx, "_Graphs/Cellular_Density"),type="png",device=dev.cur())
    
    ##Fraction of marker-positive cells (all combinations)
    coln1<-substring(coln,1,nchar(coln)-4)
    coln1<-gsub("/","_",coln1)
    coln1<-gsub("pos.","pos",coln1)
    coln1<-gsub("neg.","neg",coln1)
    
    for(a in 1:length(coln1)){
      dfglom<-read.table(paste0("Analysis/Nuclear_Coverage/Single_", single_tissuesx, "/Summary/", single_tissuesx, "_",coln1[a],".csv"), header=T, stringsAsFactors = F, sep=";")
      #dfvic<-read.table(paste0("Analysis/Nuclear_Coverage/Single_Glomeruli/Summary/Vicinity_",coln1[a],".csv"), header=T, stringsAsFactors = F, sep=";")
      
      dfglom<-melt(dfglom,id.vars=c("Biopsy","Group"))
      #dfvic<-melt(dfvic,id.vars=c("Biopsy","Group"))
      
      dfglom$Group<-as.factor(dfglom$Group)
      dfglom$Biopsy<-as.factor(dfglom$Biopsy)
      dfglom[,2]<-factor(dfglom[,2], grouporder)
      dfglom<-with(dfglom,dfglom[order(dfglom[,2]),])
      dfglom$Loc<-rep(single_tissuesx,times=nrow(dfglom))
      
      #dfvic$Group<-as.factor(dfvic$Group)
      #dfvic$Biopsy<-as.factor(dfvic$Biopsy)
      #dfvic[,2]<-factor(dfvic[,2],grouporder)
      #dfvic[,1]<-factor(dfvic[,1],levels(dfvic[,1])[bioporder])
      #dfvic<-with(dfvic,dfvic[order(dfvic[,2]),])
      #dfvic$Loc<-rep("Vicinity",times=nrow(dfvic))
      
      #df2<-rbind(dfvic, dfglom)
      df2<-dfglom
      p<-ggplot(df2, aes(x=Group,y=value, group=Biopsy))+
        geom_jitter(size=2,alpha=0.4,position=position_dodge(width=0.7))+
        mytheme3+
        stat_summary(fun.y=mean, geom="point", shape=18,
                     size=4, color="black",show.legend = F,alpha=0.5,
                     position=position_dodge(width=0.7), aes(group = Biopsy))+
        stat_summary(fun.ymin = function(x) mean(x) - sd(x), 
                     fun.ymax = function(x) mean(x) + sd(x), 
                     geom = 'errorbar', aes(group = Biopsy),position=position_dodge(width=0.7),
                     color="black", width=0.3, show.legend = F,size=0.5)+
        stat_summary(fun.y = median, fun.ymin = median, fun.ymax = median,aes(group = Biopsy),
                     position=position_dodge(width=0.7),
                     geom = "crossbar", width = 0.5,color="darkred",alpha=0.6, size=.3)+
        theme(legend.position = "none")+
        geom_text(position = position_dodge(width = 1), aes(y=0.9*max(df2$value), label=Biopsy), angle=90)+      ggtitle(paste0(mark[b],"-Coverage"))+
        ggtitle(paste0("Fraction of ", coln[a],"- Cells in ", single_tissuesx))+
        labs(y=paste0("% cells"),x="", fill="Groups")
      
      print(p)
      
      savePlot(filename=paste0(wd,"/Analysis/Nuclear_Coverage/Single_", single_tissuesx, "/Summary/Fraction_of_",coln1[a]),type="png",device=dev.cur())
    }
  }
  
}









