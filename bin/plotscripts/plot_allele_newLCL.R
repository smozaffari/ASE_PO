
#install.packages("ggplot2")
#library(ggplot2)
require(ggplot2)
#install.packages("grid.arrange")
library(gridExtra)
require(gridExtra)

args <- commandArgs(trailingOnly=TRUE)

gene <- args[1]
chr <- args[2]
bp <- args[3]

maternal <- read.table("/group/ober-resources/users/smozaffari/ASE/data/expression/Maternal_gene_normalized_v19nologques.txt", check.names = F)
paternal <- read.table("/group/ober-resources/users/smozaffari/ASE/data/expression/Paternal_gene_normalized_v19nologques.txt", check.names = F)
genes <- rownames(maternal)
unknown <- read.table("/group/ober-resources/users/smozaffari/ASE/data/expression/Unknown_gene_normalized_v19nologques.txt", check.names = F)
total <- read.table("/group/ober-resources/users/smozaffari/ASE/data/expression/Total_gene_normalized_v19nologques.txt", check.names = F)										  							

system(paste("plink --bfile /group/ober-resources/users/smozaffari/ASE/data/plinkfiles/paternal_expressionfindivs_2017-05-05 --chr ",
              chr ," --from-bp ",
              bp, " --to-bp ", bp,
              " --recode --out ", chr, "_snppat", bp, sep=""))

system(paste("plink --bfile /group/ober-resources/users/smozaffari/ASE/data/plinkfiles/maternal_expressionfindivs_2017-05-05 --chr ",
              chr ," --from-bp ",
             bp, " --to-bp ", bp,
              " --recode --out ", chr, "_snpmat", bp, sep=""))

pat <- read.table(paste(chr, "_snppat", bp, ".ped" , sep=""))
mat <- read.table(paste(chr, "_snpmat", bp, ".ped" , sep=""))
Findiv <- substr(as.numeric(mat$V2), 1, nchar(mat$V2)-1)
gtype <- cbind(Findiv, as.character(pat$V7), as.character(mat$V7))
colnames(gtype) <- c("Findiv", "Pat", "Mat")
removedgt <- which(!Findiv%in%colnames(maternal))
if (length(removedgt)>0) {
   gtype2 <- as.data.frame(gtype[-c(removedgt),])
} else {
  gtype2 <- as.data.frame(gtype)
}
gtype3 <- gtype2[match(colnames(maternal),as.character(gtype2$Findiv)),]
gtype3$GG <- paste(gtype3$Pat, gtype3$Mat, sep=":")
gtype3$GG[which(gtype3$GG=="NA:NA")] <- "0:0"


num <- grep(gene, genes)
if (length(num) >1) {
    print(genes[grep(gene, genes)])
}

maternal2 <- as.matrix(maternal)
paternal2 <- as.matrix(paternal)

for (i in num) {
  print(i)
  new <- as.data.frame(cbind(maternal2[i,], paternal2[i,]))
  new[is.na(new)] <- 0
  colnames(new) <- c("Mat", "Pat")

t <- table(gtype3$GG)


p <-   ggplot(new, aes(Mat, Pat, col=gtype3$GG)) + 
  	      geom_point( size=2.5)+
	      scale_colour_manual("Parental Genotype\n Paternal: Maternal", values=c("#762a83", "#af8dc3", "#bababa", "#7fbf7b", "#1b7837"),
	      				    breaks=names(t),
					    labels=c(paste(names(t), " N=", t))) +
 	      theme(axis.title=element_text(size=12), 
             axis.text=element_text(size=10), 
        plot.title=element_text(size=15), 
        legend.title=element_text(size=10),
        legend.text=element_text(size=10),
        legend.key=element_rect(size=5))+ 
  labs(title="All Genotypes",  x= "Maternal", y="Paternal")

  name=paste(genes[i],"_Maternal_Paternal_", chr,"_", bp, "_", i, ".pdf", sep="")


  if (length(levels(gtype3$Mat)< 3)) {
         if (length(levels(gtype3$Pat) ==3 )) {
	         gtype3$Mat <- factor(gtype3$Mat, levels=levels(gtype3$Pat))
		       }
		           }
			       if (length(levels(gtype3$Pat) < 3)) {
			             if (length(levels(gtype3$Mat) ==3)) {
				             gtype3$Pat <- factor(gtype3$Pat, levels=levels(gtype3$Mat))
					           }
						       }
  gtype4 <- gtype3[which(gtype3$Mat!=gtype3$Pat),]
  hetfindivs <- gtype4$Findiv

  hetexpfindivs <- which(rownames(new)%in%hetfindivs)

  new2 <- new[hetexpfindivs,]

print("beforeq")

t2 <- table(gtype4$GG)
q <- ggplot(new2, aes(Mat, Pat, col=gtype4$GG)) + 
  geom_point( size=2.5)+
  scale_colour_manual("Heterozygotes\n Paternal:Maternal", values=c("#bababa", "#7fbf7b"),
                      breaks=names(t2),
                      labels=c(paste(names(t2), " N=", t2))) +
  theme(axis.title=element_text(size=12), 
        axis.text=element_text(size=10), 
        plot.title=element_text(size=15), 
        legend.title=element_text(size=10),
        legend.text=element_text(size=10),
        legend.key=element_rect(size=5))+ 
  labs(title="Reciprocal Heterozygotes", x= "Maternal", y="Paternal")


  hom <- unknown[i,]
  tot <- total[i,]
  all <- rbind(total[i,], unknown[i,], maternal2[i,], paternal2[i,], gtype3$GG)
  all1 <- t(all)
  all2 <- as.data.frame(all1)
  all2[which(all2$GG=="NA:NA"),"GG"] <- "0:0"
  head(all2)
  colnames(all2) <- c("total", "hom", "mat", "pat", "GG")
  
print("beforeA")
  
  a <- ggplot(all2, aes(as.factor(GG), as.numeric(as.character(total))))+
    geom_boxplot(aes(fill=GG))+
    
    scale_fill_manual("Parental Genotype\n Paternal: Maternal", 
                        values=c("#762a83", "#af8dc3", "#bababa", "#7fbf7b", "#1b7837"),
                        breaks=names(t),
                        labels=c(paste(names(t), " N=",t))) +
    theme(axis.title=element_text(size=12), 
          axis.text=element_text(size=10), 
          plot.title=element_text(size=15), 
          legend.title=element_text(size=10),
          legend.text=element_text(size=10),
          legend.key=element_rect(size=5))+ 
    labs(title="Total expression" , 
         y= "Gene Expression", x = "Genotype")

print("beforeb")

  b <- ggplot(all2, aes(as.factor(GG), as.numeric(as.character(hom))))+
    geom_boxplot(aes(fill=GG))+
    
    scale_fill_manual("Parental Genotype\n Paternal: Maternal", 
                      values=c("#762a83", "#af8dc3", "#bababa",  "#7fbf7b", "#1b7837"),
                      breaks=names(t),
                      labels=c(paste(names(t), " N=",t))) +
    theme(axis.title=element_text(size=12), 
          axis.text=element_text(size=10), 
          plot.title=element_text(size=15), 
          legend.title=element_text(size=10),
          legend.text=element_text(size=10),
          legend.key=element_rect(size=5))+ 
    labs(title=paste("Y_u expression: ", sep=""), 
         y= "Gene Expression", x = "Genotype")



    print(name)
    g <- arrangeGrob(p,q,a,b, ncol=2, nrow=2, top = paste(genes[i], " by SNP: chr", chr, ":", bp, sep=""))
    ggsave(name, g, width=11, height=8, units="in", title=paste(genes[i], " by SNP: chr", chr, ":", bp, sep=""))


    m <- ggplot(all2, aes(as.factor(GG), as.numeric(as.character(maternal2[i,]))))+
  geom_boxplot(aes(fill=GG))+
  
  scale_fill_manual("Parental Genotype\n Paternal: Maternal", 
                    values=c("#762a83", "#af8dc3", "#bababa",  "#7fbf7b", "#1b7837"),
                    breaks=names(t),
                    labels=c(paste(names(t), " N=",t))) +
  theme(axis.title=element_text(size=12), 
        axis.text=element_text(size=10), 
        plot.title=element_text(size=15), 
        legend.title=element_text(size=10),
        legend.text=element_text(size=10),
        legend.key=element_rect(size=5))+ 
  labs(title=paste("Y_m expression: ", sep=""), 
       y= "Gene Expression", x = "Genotype")



p <- ggplot(all2, aes(as.factor(GG), as.numeric(as.character(paternal2[i,]))))+
  geom_boxplot(aes(fill=GG))+
  
  scale_fill_manual("Parental Genotype\n Paternal: Maternal", 
                    values=c("#762a83", "#af8dc3", "#bababa",  "#7fbf7b", "#1b7837"),
                    breaks=names(t),
                    labels=c(paste(names(t), " N=",t))) +
  theme(axis.title=element_text(size=12), 
        axis.text=element_text(size=10), 
        plot.title=element_text(size=15), 
        legend.title=element_text(size=10),
        legend.text=element_text(size=10),
        legend.key=element_rect(size=5))+ 
  labs(title=paste("Y_p expression: ", sep=""), 
       y= "Gene Expression", x = "Genotype")

name2=paste(genes[i],"_Maternal_Paternal_Unkn_", chr,"_", bp, "_", i, ".pdf", sep="")


g <- arrangeGrob(m,p,b,a, ncol=2, nrow=2, top = paste(genes[i], " by SNP: chr", chr, ":", bp, sep=""))
ggsave(name2, g, width=11, height=8, units="in", title=paste(genes[i], " by SNP: chr", chr, ":", bp, sep=""))

}

sessionInfo()