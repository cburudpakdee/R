library(GenomicRanges)
library(TxDb.Mmusculus.UCSC.mm39.refGene)
library(TxDb.Mmusculus.UCSC.mm39.knownGene)
library(ChIPseeker)
library(clusterProfiler)
library(org.Mm.eg.db)
library(enrichplot)
library(ReactomePA)
library(plyranges)
library(BRGenomics)
library(ggplot2)
library(UpSetR)
library(ChIPpeakAnno)
library(pathview)
setwd('/home/em_b/work_stuff/FCCC/chipseq/comb/macs/D1/plots')
txdb<-TxDb.Mmusculus.UCSC.mm39.refGene
peak <- readPeakFile('/home/em_b/work_stuff/FCCC/chipseq/comb/macs/D1/D1_A1_peaks.narrowPeak')
table(seqnames(peak))
peak
peak<-tidyChromosomes(peak,
                keep.X=FALSE,
                keep.Y=FALSE,
                keep.M = FALSE,
                keep.nonstandard = FALSE,
                genome = 'mm39')
table(seqnames(peak))
covplot(peak, weightCol="V5")
summary(peak$V5)
#covplot(peak, weightCol="V5", chrs=c("chr1", "chr19"))
gc()
plotAvgProf2(peak, TxDb=txdb, upstream=3000, downstream=3000,
             xlab="Genomic Region (5'->3')", ylab = "Read Count Frequency",
             conf = 0.95)
plotPeakProf2(peak = peak, upstream = 3000, downstream = 3000,
              conf = 0.95, by = "gene", type = "body", nbin = 800,
              TxDb = txdb, weightCol = "V5",ignore_strand = F)
gc()
macsPeaks <- '/home/em_b/work_stuff/FCCC/chipseq/comb/macs/D1/D1_A1_peaks.xls'
htmapdf <- read.delim(macsPeaks,comment.char="#")
summary(htmapdf$X.log10.qvalue.)
#df<-subset(df,X.log10.qvalue.>84)
htmapdf<-GRanges(htmapdf)
htmapdf<-tidyChromosomes(htmapdf,
                    keep.X=FALSE,
                    keep.Y=FALSE,
                    keep.M = FALSE,
                    keep.nonstandard = FALSE)
table(htmapdf@seqnames)
#peakHeatmap(htmapdf,
#            TxDb = TxDb.Mmusculus.UCSC.mm39.knownGene,
#            nbin = 800,
#            upstream=3000,
#            downstream=3000)
peakHeatmap(peak = htmapdf,
            TxDb = txdb,
            upstream = rel(0.2),
            downstream = rel(0.2),
            by = "gene",
            type = "body",
            nbin = 800)+
  scale_fill_distiller(palette = 'Greys')
df <- read.delim(macsPeaks,comment.char="#")
table(df$chr)
list<-c('chr1','chr2','chr3','chr4','chr5','chr6','chr7','chr8','chr9','chr10',
        'chr11','chr12','chr13','chr14','chr15','chr16','chr17','chr18','chr19')
macsPeaks_DF<-subset(df, subset = chr %in% list)
table(macsPeaks_DF$chr)
macsPeaks_GR <- GRanges(seqnames=macsPeaks_DF[,"chr"],
                        IRanges(macsPeaks_DF[,"start"],macsPeaks_DF[,"end"]))
mcols(macsPeaks_GR) <- macsPeaks_DF[,c("abs_summit", "fold_enrichment")]
macsPeaks_GR[1:5,]
peakAnno <- annotatePeak(macsPeaks_GR, tssRegion=c(-1000, 1000), 
                         TxDb=txdb, 
                         annoDb="org.Mm.eg.db")
peakAnno
plotAnnoPie(peakAnno)
#plotAnnoBar(peakAnno)
vennpie(peakAnno)
res <- genomicElementUpSetR(peak,
                            TxDb.Mmusculus.UCSC.mm39.knownGene)
upset(res[["plotData"]], 
      nsets = length(colnames(res$plotData)), 
      nintersects = NA)
plotDistToTSS(peakAnno,
              title="Distribution of transcription factor-binding loci\nrelative to TSS")
#------Reactome pathway 
cat('Reactome is for all peaks general output')
gene <- seq2gene(peak, tssRegion = c(-1000, 1000), flankDistance = 3000, TxDb=txdb)
gene
reactome <- enrichPathway(gene,
                          organism = 'mouse')
dotplot(reactome)
reactome<-data.frame(reactome)
#write.csv(pathway,file='reactome_pathway.csv')
#-------------------------------------------------------------------------------
cat('KEGG is for all peaks general output')
kegg<-data.frame(peakAnno)
#kegg <- kegg[kegg$annotation == "Promoter",]
kegg_genes<-kegg$fold_enrichment
names(kegg_genes)<-kegg$geneId
kegg_genes
pathview(gene.data = kegg_genes,
               pathway.id = '04919',
               species = 'mmu',
               out.suffix='mmu_test')
pathview(gene.data = kegg,
               pathway.id = '04722',
               species = 'mmu',
               out.suffix='mmu_test')
#-------------------------------------------------------------------------------
annotatedPeaksGR <- as.GRanges(peakAnno)
annotatedPeaksDF <- as.data.frame(peakAnno)
annotatedPeaksDF
annotatedPeaksGR$annotation
annotatedPeaksGR_TSS <- annotatedPeaksGR[annotatedPeaksGR$annotation == "Promoter",]
annotatedPeaksGR_TSS
#duplicated(annotatedPeaksGR_TSS$geneId)
genesWithPeakInTSS <- unique(annotatedPeaksGR_TSS$geneId)
genesWithPeakInTSS
allGeneGR <- genes(TxDb.Mmusculus.UCSC.mm39.refGene)
allGeneGR[1:2, ]
#-----Gene ontology enrichment
genesWithPeakInTSS
cat('GO is refined to only the selected regions (promoter,distal-intergenic)')
GO_result <- enrichGO(gene = genesWithPeakInTSS,
                      #universe = allGeneIDs,
                      OrgDb = org.Mm.eg.db,
                      ont = "BP")
GO_result
GO_result_df <- data.frame(GO_result)
GO_result_df[1:2, ]
GO_result_df<-GO_result_df[order(GO_result_df$Count, decreasing=TRUE),]
GO_result_plot <- pairwise_termsim(GO_result)
emapplot(GO_result_plot, showCategory = 50)
write.csv(annotatedPeaksDF,file = 'all_annotated_peaks.csv')
write.csv(reactome,file = 'reactome.csv')
write.csv(GO_result_df,file = 'GO.csv')
break 
