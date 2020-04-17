histogram_analysis<-function(){
wd<-getwd()

# get experiment characteristics ------------------------------------------
markers<-list.dirs(paste0("Histograms/"),recursive = F, full.names = F)

mark<-markers
for(a in 1:length(markers)){
  mark[a]<-unlist(strsplit(markers[a],"_"))[3]
}

mark<-mark[!is.na(mark)]
if(substring(markers[1], 1,1)=="1"){
  markers<-markers[!nchar(markers)==3]
}

biopsies<-list.files(paste0("Histograms/",markers[1]),recursive = F, full.names = F)
biop<-substring(biopsies,0,nchar(biopsies)-4)

if(length(biop)>0){
  ##for brightfield (PAS/IP)
  if(substring(markers[1], 1,1)!="1"){
    mark<-markers
  }
  
  mark<-mark[!is.na(mark)]
  if(substring(markers[1], 1,1)=="1"){
    markers<-markers[!nchar(markers)==3]
  }
  # Set Theme------------------------------------------------------------------
  
  is_outlier <- function(x) {
    return(x < quantile(x, 0.25) - 1.5 * IQR(x) | x > quantile(x, 0.75) + 1.5 * IQR(x))
  }
  
  localMaxima <- function(x) {
    # Use -Inf instead if x is numeric (non-integer)
    y <- diff(c(-Inf, x)) > 0L
    rle(y)$lengths
    y <- cumsum(rle(y)$lengths)
    y <- y[seq.int(1L, length(y), 2L)]
    if (x[[1]] == x[[2]]) {
      y <- y[-1]
    }
    y
  }
  
  localMinima <- function(x) {
    # Use -Inf instead if x is numeric (non-integer)
    y <- diff(c(Inf, x)) < 0L
    rle(y)$lengths
    y <- cumsum(rle(y)$lengths)
    y <- y[seq.int(1L, length(y), 2L)]
    if (x[[1]] == x[[2]]) {
      y <- y[-1]
    }
    y
  }
  
  mytheme3 <- theme(legend.text = element_text(face = "italic",size = rel(1)), 
                    axis.title = element_text(size = rel(1.2)), 
                    axis.text = element_text(size = rel(1.0)), 
                    axis.line = element_line(size = 1,colour = "black"), 
                    axis.ticks = element_line(colour="black",size = rel(2)),
                    panel.background = element_rect(fill = "white", colour="black"), 
                    #legend.key = element_rect(fill = "gray4", colour="transparent"),
                    panel.grid.minor = element_line(colour="grey"),
                    panel.grid.major = element_line(colour="grey"),
                    legend.title = element_text(size = rel(1.5)), 
                    plot.title = element_text(face = "bold",
                                              size = rel(1.7),hjust=0.5),
                    #axis.text.x = element_text(angle = 90, hjust = 1),
                    legend.position = "none")
  windows(height=10,width=20)
  for(a in 1:length(mark)){
    for(b in 1:length(biop)){
  
      df1<-read.table(paste0("Histograms/",markers[a],"/",biopsies[b]), header=T, sep="\t")
      
      npx<-sum(df1$Count)
      if(b==1){
        df2<-c(df1$Value[seq(1,256,8)])
      }
      v1<-sum(df1$Value[1:32])/npx
      for(c in 2:32){
        v1<-c(v1,sum(df1$Value[(c-1)*8+(1:8)])/npx)
      }
      df2<-cbind(df2,v1)
    }
    df2<-data.frame(df2)
    colnames(df2)<-c("Intensity",biop)
    df3<-melt(df2,id.vars="Intensity")
    
    ##get data table for outliers
    v3<-is_outlier(as.numeric(df2[1,2:ncol(df2)]))
    for(c in 2:nrow(df2)){
      v3<-rbind(v3,is_outlier(as.numeric(df2[c,2:ncol(df2)])))
    }
    colnames(v3)<-biop
    v3<-melt(v3)
    df3<-cbind(df3,v3[,3])
    colnames(df3)<-c("Intensity","variable","value","v3")
    df4<-subset(df3, v3==T)
  
    ##plot
    
    p<-ggplot(df3, aes(x=Intensity,y=value, group=variable))+
      #geom_boxplot()+
      geom_line()+
      #stat_summary(fun.y=mean, geom="point", shape=18,
      #             size=4, color="red",show.legend = F,alpha=0.8)+
      geom_text(data=df4,aes(label=variable, y=value, x=Intensity), size=3)+
      mytheme3+
      scale_y_log10()+
      ggtitle(markers[a])
    print(p)
    savePlot(filename=paste0(wd,"/Histograms/", markers[a]),type="png",device=dev.cur())
  }
  graphics.off()
}
}
histogram_analysis()
