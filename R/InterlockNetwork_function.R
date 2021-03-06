#' @title Interlocking Directorates Network
#'
#' @description This function creates an interlocking directorates network from a list of company number
#' @param coynoLIST list of company numbers
#' @param mkey Authorisation key
#' @param start Start Year
#' @param end End Year
#' @export
#' @return Two-Mode Interlocking Directorates Network - igraph object
InterlockNetwork<-function(coynoLIST,mkey,start,end){
  DATA<-list()
  for (i in 1:length(coynoLIST)){
    DATA[[i]]<-company_ExtractDirectorsData(coynoLIST[i],mkey)
  }
  Rdata<-plyr::ldply(DATA,data.frame)

  #HH<-cbind(as.character(Rdata$id),as.character(Rdata$directors))
  Rdata2<-dplyr::filter(Rdata,role=="director")

  HIST<-dplyr::filter(Rdata2,!is.na(end.date))
  CUR<-dplyr::filter(Rdata2,is.na(end.date))
  CUR$end.date<-CUR$download.date

  DATA<-dplyr::bind_rows(HIST,CUR)

  REMAIN<-dplyr::filter(DATA,!is.na(start.date))

  START_NA<-dplyr::filter(DATA,is.na(start.date))

  START_NA$start.date<-START_NA$end.date

  DATA2<-dplyr::bind_rows(START_NA,REMAIN)

  YEAR_LIST<-start:end

  DATA3<-DATA2
  #DATA_YEAR_LIST<-list()
  for (i in 1:length(DATA3$director.id)){
    YEARS<-substr(seq(DATA3$start.date[[i]], DATA3$end.date[[i]],
                      "years"), 1, 4)
    CHECK<-dplyr::intersect(YEARS,YEAR_LIST)
    CT<-length(CHECK)>0
    DATA3$CHECK[[i]]<-CT
  }

  DATA4<-dplyr::filter(DATA3,CHECK==TRUE)
  DATA4<-dplyr::select(DATA4,-c(CHECK))

  HH<-dplyr::select(DATA4,company.id,director.id)

  colnames(HH)<-c("CompanyID","Director")
  HH2<-unique(HH)
  HH2[is.na(HH2)] <- "na"
  HH2<-as.data.frame(HH2)
  HH3<-dplyr::filter(HH2,HH2$Director!="na")

  INTERLOCK<- igraph::graph.data.frame(HH3)

  igraph::V(INTERLOCK)$type <- igraph::V(INTERLOCK)$name %in% HH3$Director

  return(INTERLOCK)

}

