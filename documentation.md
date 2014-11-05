# PORT
## RNA-Seq Normalization & Quantification
**PORT** offers two types of normalization: <br>__GENE Normalization__ and __EXON-INTRON-JUNCTION Normalization__.

===========================================================================================================================================================

### 1. NORMALIZATION STEPS
#### [PART1 - both Gene and Exon-Intron-Junction Normalization]
#### 1) Preprocess
##### A. Mapping Statistics
* **Get total number of reads from input fasta or fastq files**

         perl get_total_num_reads.pl <sample dirs> <loc> <file of input forward fa/fq files> [options]

	 * &lt;sample dirs> : a file with the names of the sample directories
	 * &lt;loc> : full path of the directory with the sample directories (`READS`)
	 * &lt;file of input forward fa/fq files> :  a file with the full path of input forward fa or forward fq files
	 * option : <br>
	  **-fa** : set this if the input files are in fasta format <br>
	  **-fq** : set this if the input files are in fastq format <br>
	  **-gz** : set this if the input files are compressed<br>
	  **-lsf** : set this if you want to submit batch jobs to LSF<br>
	  **-sge** :  set this if you want to submit batch jobs to Sun Grid Engine<br>
	  **-other "&lt;submit>, &lt;jobname_option>, &lt;status>"** : set this if you're not on LSF or SGE cluster <br>
	  **-max_jobs &lt;n>** : set this if you want to control the number of jobs submitted. by default it will submit 200 jobs at a time<br>

 This will output a file called `total_num_reads.txt` to the `STUDY/STATS` directory.

* **Mapping statistics**

         perl runall_sam2mappingstats.pl <sample dirs> <loc> <sam file name> <total_num_reads?> [options]

       * &lt;sample dirs> : a file with the names of the sample directories
       * &lt;loc> : full path of the directory with the sample directories (`READS`)
       * &lt;sam file name> : the name of sam file (e.g. RUM.sam, Aligned.out.sam)
       * &lt;total_num_reads?> : if you have the total_num_reads.txt file, use "true" If not, use "false"
       * option : <br>
         **-lsf** : set this if you want to submit batch jobs to LSF<br>
         **-sge** :  set this if you want to submit batch jobs to Sun Grid Engine<br>
	 **-other "&lt;submit>, &lt;jobname_option>, &lt;request_memory_option>, &lt;queue_name_for_30G>, &lt;status>"** : set this if you're not on LSF or SGE cluster<br>
	 **-mem &lt;s>** : set this if your job requires more memory. &lt;s> is the queue name for required mem (Default: 30G)<br>
	 ** If you have > 150,000,000 reads, use -mem option to request 45G mem.<br>
	 ** If you have > 200,000,000 reads, use -mem option to request 60G mem.<br>
         **-max_jobs &lt;n>** : set this if you want to control the number of jobs submitted. by default it will submit 200 jobs at a time<br>
 
 This will output `*mappingstats.txt` file of all samples to each sample directory. The following script will parse the `*mappingstats.txt` files and output a table with summary info across all samples.

__[NORMALIZATION FACTORS] Mapping stats summary__

     perl getstats.pl <sample dirs> <loc>

* &lt;sample dirs> : a file with the names of the sample directories
* &lt;loc> : full path of the directory with the sample directories (`READS`)
      	  
This will output `mappingstats_summary.txt` file to `STUDY/STATS` directory. This file contains the following normalization factors: 

 1. Total number of reads 
 2. Percent mitochondrial 
 3. Percent non-unique mappers 
 4. Percent of forward and reverse reads that overlap

##### B. BLAST

      perl runall_runblast.pl <sample dirs> <loc> <samfile name> <blast dir> <db> [options]

> `runblast.pl` available for running one sample at a time

* &lt;sample dirs> : a file with the names of the sample directories
* &lt;loc> : full path of the directory with the sample directories (`READS`)
* &lt;samfile name> : the name of sam file (e.g. RUM.sam, Aligned.out.sam)
* &lt;blast dir> : full path of the blast directory

> BLAST is at : `Normalization/norm_scripts/ncbi-blast-2.2.27+/`

* &lt;db> : full path of the database

> ribomouse db is available : `Normalization/norm_scripts/ncbi-blast-2.2.27+/ribomouse`

* option : <br>
  **-lsf** : set this if you want to submit batch jobs to LSF<br>
  **-sge** :  set this if you want to submit batch jobs to Sun Grid Engine<br>
  **-other "&lt;submit>, &lt;jobname_option>, &lt;request_memory_option>, &lt;queue_name_for_6G>, &lt;status>"** : set this if you're not on LSF or SGE cluster <br>
  **-mem &lt;s>** : set this if your job requires more memory. &lt;s> is the queue name for required mem (Default: 6G)<br>
  **-max_jobs &lt;n>** : set this if you want to control the number of jobs submitted. by default it will submit 200 jobs at a time<br>

This outputs `*ribosomalids.txt` of samples to each sample directory (`STUDY/READS/Sample*/`).

__[NORMALIZATION FACTOR] Ribo percents__

     perl runall_get_ribo_percents.pl <sample dirs> <loc> [options]

* &lt;sample dirs> : a file with the names of the sample directories 
* &lt;loc> : full path of the directory with the sample directories (`READS`)
* option : <br>
  **-lsf** : set this if you want to submit batch jobs to LSF<br>
  **-sge** :  set this if you want to submit batch jobs to Sun Grid Engine<br>
  **-other "&lt;submit>, &lt;jobname_option>, &lt;request_memory_option>, &lt;queue_name_for_10G>, &lt;status>"** : set this if you're not on LSF or SGE cluster<br>
  **-mem &lt;s>** : set this if your job requires more memory. &lt;s> is the queue name for required mem (Default: 10G)<br>
  **-max_jobs &lt;n>**  :  set this if you want to control the number of jobs submitted. by default it will submit 200 jobs at a time.<br>

It assumes there are files of ribosomal ids output from runblast.pl each with suffix "ribosomalids.txt" in each sample directory. This will output `ribosomal_counts.txt` and `ribo_percents.txt` to `STUDY/STATS` directory.

#### [PART1 - Gene Normalization]
#### 1) Run Filter
This step removes all rows from input sam file except those that satisfy all of the following:

  1. Unique mapper / Non-Unique mapper
  2. Both forward and reverse map consistently
  3. id not in the `*ribosomalids.txt` file
  4. Only on a numbered chromosome, X or Y

Run the following command. By default it will return both unique and non-unique mappers.

    perl runall_filter_gnorm.pl <sample dirs> <loc> <sam file name> [options]

> `filter_sam_gnorm.pl` available for running one sample at a time

* &lt;sample dirs> : a file with the names of the sample directories
* &lt;loc> : full path of the directory with the sample directories (`READS`)
* &lt;sam file name> : the name of sam file (e.g. RUM.sam, Aligned.out.sam)
* option:<br>
  **-u** : set this if you want to return only unique mappers<br>
  **-nu** :  set this if you want to return only non-unique mappers<br>
  **-se** :  set this if the data are single end, otherwise by default it will assume it's a paired end data <br>
  **-lsf** : set this if you want to submit batch jobs to LSF<br>
  **-sge** :  set this if you want to submit batch jobs to Sun Grid Engine<br>
  **-other "&lt;submit>, &lt;jobname_option>, &lt;request_memory_option>, &lt;queue_name_for_4G>, &lt;status>"** : set this if you're not on LSF or SGE cluster<br>
  **-mem &lt;s>** : set this if your job requires more memory. &lt;s> is the queue name for required mem (Default: 4G)<br>
  **-max_jobs &lt;n>** : set this if you want to control the number of jobs submitted. by default it will submit 200 jobs at a time<br>

This creates directories called `STUDY/READS/Sample*/GNORM/Unique` and/or `STUDY/READS/Sample*/GNORM/NU` and outputs `filtered.sam` files of all samples to the directories created.

__[NORMALIZATION FACTOR] Percent chromosome stats__

Run the following with **-GENE** option.

     perl runall_get_percent_numchr.pl <sample dirs> <loc> [options]

* &lt;sample dirs> : a file with the names of the sample directories
* &lt;loc> : full path of the directory with the sample directories (`READS`)
* option : <br>
  **-GENE** : set this if you're running GENE normalization<br>
  **-EIJ** : set this if you're running EXON-INTRON-JUNCTION normalization<br>
  **-lsf** : set this if you want to submit batch jobs to LSF<br>
  **-sge** :  set this if you want to submit batch jobs to Sun Grid Engine<br>
  **-other "&lt;submit>, &lt;jobname_option>, &lt;status>"** : set this if you're not on LSF or SGE cluster<br>
  **-max_jobs &lt;n>**  :  set this if you want to control the number of jobs submitted. by default it will submit 200 jobs at a time.<br>

This will output `*numchr_count.txt` to `STUDY/READS/Sample*/GNORM/Unique` and/or `STUDY/READS/Sample*/GNORM/NU` directory.

Then, run this with **-GENE** option:

     perl get_chr_stats.pl <sample dirs> <loc> [options]

* &lt;sample dirs> : a file with the names of the sample directories
* &lt;loc> : full path of the directory with the sample directories (`READS`)
* option : <br>
  **-GENE** : set this if you're running GENE normalization<br>
  **-EIJ** : set this if you're running EXON-INTRON-JUNCTION normalization<br>

This will output `percent_reads_chr_gnorm.txt` to `STUDY/STATS/GENE` directory.

#### 2) Quantify Genes
##### A. Create Master List of Genes
Get master list of genes from a Ensembl Genes file.

    perl get_master_list_of_genes.pl <gene info file> <loc>

* &lt;ensGene file> : ensembl table must contain columns with the following suffixes: name, chrom, txStart, txEnd, exonStarts, exonEnds, name2, ensemblToGeneName.value<br>
* &lt;loc> : full path of the directory with the sample directories (`READS`)

This outputs a file called `master_list_of_ensGenes.txt` to the `READS` directory. 

##### B. Run sam2genes

    perl runall_sam2genes_gnorm.pl <sample dirs> <loc> <ensGene file> [options]

> `sam2genes.pl` available for running one sample at a time

* &lt;sample dirs> : a file with the names of the sample directories
* &lt;loc> : full path of the directory with the sample directories (`READS`)
* &lt;ensGene file> : ensembl table must contain columns with the following suffixes: name, chrom, txStart, txEnd, exonStarts, exonEnds, name2, ensemblToGeneName.value

* option:<br>
  **-se** : set this if the data are single end, otherwise by default it will assume it's a paired end data.<br>
  **-str_f** : set this if the data are strand-specific AND forward read is in the same orientation as the transcripts/genes.<br>
  **-str_r** : set this if the data are strand-specific AND reverse read is in the same orientation as the transcripts/genes.<br>
  **-u**  :  set this if you are using unique mappers only, otherwise by default it will use both unique and non-unique mappers. <br>
  **-nu** :  set this if you are using non-unique mappers only, otherwise by default it will use both unique and non-unique mappers. <br>
  **-norm** : set this to get genes file for the gene-normalized sam files.<br>
  **-lsf** : set this if you want to submit batch jobs to LSF<br>
  **-sge** :  set this if you want to submit batch jobs to Sun Grid Engine<br>
  **-other "&lt;submit>, &lt;jobname_option>, &lt;status>"** : set this if you're not on LSF or SGE cluster<br>
  **-max_jobs &lt;n>** : set this if you want to control the number of jobs submitted. by default it will submit 200 jobs at a time<br>

This outputs `*genes.txt` file to `STUDY/READS/Sample*/GNORM/Unique` and/or `STUDY/READS/Sample*/GNORM/NU` directory.

##### C. Run genefilter

    perl runall_genefilter.pl <sample dirs> <loc> [options]

> `genefilter.pl` available for running one sample at a time

* &lt;sample dirs> : a file with the names of the sample directories
* &lt;loc> : full path of the directory with the sample directories (`READS`)

* option:<br>
  **-u**  :  set this if you are using unique mappers only, otherwise by default it will use both unique and non-unique mappers. <br>
  **-nu** :  set this if you are using non-unique mappers only, otherwise by default it will use both unique and non-unique mappers. <br>
  **-se** : set this if the data are single end, otherwise by default it will assume it's a paired end data.<br>
  **-filter_highexp** : use this if you want to filter high expressors. <br>
  **-lsf** : set this if you want to submit batch jobs to LSF<br>
  **-sge** :  set this if you want to submit batch jobs to Sun Grid Engine<br>
  **-other "&lt;submit>,&lt;jobname_option>,&lt;request_memory_option>, &lt;queue_name_for_10G>,&lt;status>""** : set this if you're not on LSF or SGE cluster<br>
  **-max_jobs &lt;n>** : set this if you want to control the number of jobs submitted. by default it will submit 200 jobs at a time<br>

This outputs `filtered_u_genes.sam` file to `STUDY/READS/Sample*/GNORM/Unique` and/or `STUDY/READS/Sample*/GNORM/NU` directory.

##### D. Run Quantify Genes

    perl runall_quantify_genes_gnorm.pl <sample dirs> <loc> <genes>

> `quantify_genes.pl` available for running one sample at a time

* &lt;sample dirs> : a file with the names of the sample directories
* &lt;loc> : full path of the directory with the sample directories (`READS`)
* &lt;genes> : master list of genes file

* option:<br>
  **-u**  :  set this if you are using unique mappers only, otherwise by default it will use both unique and non-unique mappers. <br>
  **-nu** :  set this if you are using non-unique mappers only, otherwise by default it will use both unique and non-unique mappers. <br>
  **-se** : set this if the data are single end, otherwise by default it will assume it's a paired end data.<br>
  **-norm** : set this to quantify normalized sam. <br>
  **-lsf** : set this if you want to submit batch jobs to LSF<br>
  **-sge** :  set this if you want to submit batch jobs to Sun Grid Engine<br>
  **-other "&lt;submit>, &lt;jobname_option>, &lt;request_memory_option>, &lt;queue_name_for_10G>,&lt;status>"** : set this if you're not on LSF or SGE cluster<br>
  **-mem &lt;s>** : set this if your job requires more memory. &lt;s> is the queue name for required mem (Default: 10G)<br>
  **-max_jobs &lt;n>** : set this if you want to control the number of jobs submitted. by default it will submit 200 jobs at a time<br>

This outputs `genequants` file to `STUDY/READS/Sample*/GNORM/Unique` and/or `STUDY/READS/Sample*/GNORM/NU` directory.

__[NORMALIZATION FACTOR] Percent of genemappers__

    perl get_percent_genemappers.pl  <sample dirs> <loc> [options]

* &lt;sample dirs> : a file with the names of the sample directories
* &lt;loc> : full path of the directory with the sample directories (`READS`)
* option:<br>
 **-u** : set this if you want to return only unique stats, otherwise by default it will return both unique and non-uniqe stats<br>
 **-nu** :  set this if you want to return only non-unique stats, otherwise by default it will return both unique and non-uniqe stats

This will output `percent_genemappers_Unique.txt` and/or `percent_genemappers_NU.txt` depending on the option provided to `STUDY/STATS/GENE/` directory.

##### E. [optional step] : Filter High Expressors
This is an extra filter step that removes highly expressed genes.

I. Get High Expressors

    perl runall_get_high_genes.pl <sample dirs> <loc> <cutoff> [options]

* &lt;sample dirs> : a file with the names of the sample directories
* &lt;loc> : full path of the directory with the sample directories (`READS`)
* &lt;cutoff> : cutoff % value

* option:<br>
  **-nu** :  set this if you want to return only non-unique genepercents, otherwise by default it will return only unique genepercents.<br>
  **-lsf** : set this if you want to submit batch jobs to LSF<br>
  **-sge** :  set this if you want to submit batch jobs to Sun Grid Engine<br>
  **-other "&lt;submit>, &lt;jobname_option>, &lt;request_memory_option>, &lt;queue_name_for_6G>, &lt;status>"** : set this if you're not on LSF or SGE cluster<br>
  **-mem &lt;s>** : set this if your job requires more memory. &lt;s> is the queue name for required mem (Default: 6G)<br>
  **-max_jobs &lt;n>** : set this if you want to control the number of jobs submitted. by default it will submit 200 jobs at a time<br>

This will output `*genepercents.txt` and `*high_expressors_gene.txt` files of all samples to each sample directory. 

II. Filter High Expressors

     perl filter_high_expressors_gnorm.pl <sample dirs> <loc> <genes> [options]

* &lt;sample dirs> : a file with the names of the sample directories
* &lt;loc> : full path of the directory with the sample directories (`READS`)
* &lt;genes> : master list of genes file

* option:<br>
  **-nu** :  set this if you're only using non-unique genepercent, otherwise by default it will only unique genepercents.<br>
  **-se** : set this if your data are single end.<br>

This will output a text file called `filtered_master_list_of_ensGenes.txt` to `STUDY/READS` directory and filter out the reads that map to high expressors from `genes.txt` file and create `genes2.txt` in each sample directory `STUDY/READS/Sample*/GNORM/Unique` and/or `STUDY/READS/Sample*/GNORM/NU`.

III. Run Genefilter
Run the following with **-filter_highexp** option.

    perl runall_genefilter.pl <sample dirs> <loc> [options]

> `genefilter.pl` available for running one sample at a time

* &lt;sample dirs> : a file with the names of the sample directories
* &lt;loc> : full path of the directory with the sample directories (`READS`)

* option:<br>
  **-u**  :  set this if you are using unique mappers only, otherwise by default it will use both unique and non-unique mappers. <br>
  **-nu** :  set this if you are using non-unique mappers only, otherwise by default it will use both unique and non-unique mappers. <br>
  **-se** : set this if the data are single end, otherwise by default it will assume it's a paired end data.<br>
  **-filter_highexp** : use this if you want to filter high expressors. <br>
  **-lsf** : set this if you want to submit batch jobs to LSF<br>
  **-sge** :  set this if you want to submit batch jobs to Sun Grid Engine<br>
  **-other "&lt;submit>,&lt;jobname_option>,&lt;request_memory_option>, &lt;queue_name_for_10G>,&lt;status>""** : set this if you're not on LSF or SGE cluster<br>
  **-max_jobs &lt;n>** : set this if you want to control the number of jobs submitted. by default it will submit 200 jobs at a time<br>

This outputs `filtered_u_genes.sam` file to `STUDY/READS/Sample*/GNORM/Unique` and/or `STUDY/READS/Sample*/GNORM/NU` directory.

__[NORMALIZATION FACTOR] Highly expressed genes__

     perl get_percent_high_exprermsso_gnor.pl <sample dirs> <loc> [options]

* &lt;sample dirs> : a file with the names of the sample directories
* &lt;loc> : full path of the directory with the sample directories (`READS`)
* option:<br>
 **-nu** :  set this if you want to return only non-unique stats, otherwise by default it will return only unique stats

This will output `percent_high_expressor_gene_Unique.txt` or `percent_high_expressor_NU.txt` depending on the option provided to `STUDY/STATS/GENE/` directory.

#### 3) Predict Number of Reads

      perl predict_num_reads_gnorm.pl <sample dirs> <loc> [option]

* &lt;sample dirs> : a file with the names of the sample directories
* &lt;loc> : full path of the directory with the sample directories (`READS`)
* option : <br>
 **-se** :  set this if the data are single end, otherwise by default it will assume it's a paired end data <br>
 **-u** : set this if you want to return number of unique reads only, otherwise by default it will return number of unique and non-unique reads <br>
 **-nu** : set this if you want to return number of non-unique reads only, otherwise by default it will return number of unique and non-unique reads <br>

This will provide number of reads you'll have after normalization in `STUDY/STATS/GENE/expected_num_reads_gnorm.txt`. 

#### [PART1 - Exon-Intron-Junction Normalization]
#### 1) Run Filter
This step removes all rows from input sam file except those that satisfy all of the following:

  1. Unique mapper / Non-Unique mapper
  2. Both forward and reverse map consistently
  3. id not in the `*ribosomalids.txt` file
  4. Only on a numbered chromosome, X or Y
  5. Is a forward mapper (script outputs forward mappers only)

Run the following command. By default it will return both unique and non-unique mappers.

    perl runall_filter.pl <sample dirs> <loc> <sam file name> [options]

> `filter_sam.pl` available for running one sample at a time

* &lt;sample dirs> : a file with the names of the sample directories 
* &lt;loc> : full path of the directory with the sample directories (`READS`)
* &lt;sam file name> : the name of sam file (e.g. RUM.sam, Aligned.out.sam)
* option:<br>
  **-u** : set this if you want to return only unique mappers<br>
  **-nu** :  set this if you want to return only non-unique mappers<br>
  **-se** :  set this if the data are single end, otherwise by default it will assume it's a paired end data <br>
  **-lsf** : set this if you want to submit batch jobs to LSF<br>
  **-sge** :  set this if you want to submit batch jobs to Sun Grid Engine<br>
  **-other "&lt;submit>, &lt;jobname_option>, &lt;request_memory_option>, &lt;queue_name_for_4G>, &lt;status>"** : set this if you're not on LSF or SGE cluster<br>
  **-mem &lt;s>** : set this if your job requires more memory. &lt;s> is the queue name for required mem (Default: 4G)<br>
  **-max_jobs &lt;n>** : set this if you want to control the number of jobs submitted. by default it will submit 200 jobs at a time<br>

This creates directories called `STUDY/READS/Sample*/EIJ/Unique` and/or `STUDY/READS/EIJ/Sample*/NU` and outputs `filtered.sam` files of all samples to the directories created. 

__[NORMALIZATION FACTOR] Percent chromosome stats__
Run the following with **-EIJ** option.

     perl runall_get_percent_numchr.pl <sample dirs> <loc> [options]

* &lt;sample dirs> : a file with the names of the sample directories
* &lt;loc> : full path of the directory with the sample directories (`READS`)
* option : <br>
  **-GENE** : set this if you're running GENE normalization<br>
  **-EIJ** : set this if you're running EXON-INTRON-JUNCTION normalization<br>
  **-lsf** : set this if you want to submit batch jobs to LSF<br>
  **-sge** :  set this if you want to submit batch jobs to Sun Grid Engine<br>
  **-other "&lt;submit>, &lt;jobname_option>, &lt;status>"** : set this if you're not on LSF or SGE cluster<br>
  **-max_jobs &lt;n>**  :  set this if you want to control the number of jobs submitted. by default it will submit 200 jobs at a time.<br>

This will output `*numchr_count.txt` to `STUDY/READS/Sample*/EIJ/Unique` and/or `STUDY/READS/Sample*/EIJ/NU` directory.

Then, run this with **-EIJ** option:

     perl get_chr_stats.pl <sample dirs> <loc> [options]

* &lt;sample dirs> : a file with the names of the sample directories
* &lt;loc> : full path of the directory with the sample directories (`READS`)
* option : <br>
  **-GENE** : set this if you're running GENE normalization<br>
  **-EIJ** : set this if you're running EXON-INTRON-JUNCTION normalization<br>

This will output `percent_reads_chr_gnorm.txt` to `STUDY/STATS/EXON_INTRON_JUNCTION` directory.

#### 2) Quantify Exons
##### A. Create Master List of Exons
Get master list of exons from a UCSC gene info file.

    perl get_master_list_of_exons_from_geneinfofile.pl <gene info file> <loc>

* &lt;gene info file> : a UCSC gene annotation file including chrom, strand, txStrand, txEnd, exonCount, exonStarts, exonEnds, and name.
* &lt;loc> : full path of the directory with the sample directories (`READS`)

This outputs a file called `master_list_of_exons.txt` to the `READS` directory.

##### B. Get Novel Exons
Create a study-specific master list of exons by adding novel exons from the study to the `master_list_of_exons.txt` file.

* **Make Junctions Files**

 Run the following command with option **-samfilename &lt;sam file name>**.

         perl runall_sam2junctions.pl <sample dirs> <loc> <genes> <genome> [options]

    * &lt;sample dirs> : a file with the names of the sample directories
    * &lt;loc> : full path of the directory with the sample directories (`READS`)
    * &lt;genes> : gene information file
    * &lt;genome> : genome sequence one-line fasta file
    * option : <br>
      **-samfilename &lt;s>** : set this to create junctions files using unfiltered aligned samfile. &lt;s> is the name of aligned sam file (e.g. RUM.sam, Aligned.out.sam) and all sam files in each sample directory should have the same name<br>
      **-u**  :  set this if you want to return only unique junctions files, otherwise by default it will return merged(unique+non-unique) junctions files<br>
      **-nu** :  set this if you want to return only non-unique files, otherwise by default it will return merged(unique+non-unique) junctions files<br>
      **-lsf** : set this if you want to submit batch jobs to LSF<br>
      **-sge** :  set this if you want to submit batch jobs to Sun Grid Engine<br>
      **-other "&lt;submit>, &lt;jobname_option>, &lt;request_memory_option>, &lt;queue_name_for_6G>, &lt;status>"** : set this if you're not on LSF or SGE cluster<br>
      **-mem &lt;s>** : set this if your job requires more memory. &lt;s> is the queue name for required mem (Default: 6G)<br>
      **-max_jobs &lt;n>** : set this if you want to control the number of jobs submitted. by default it will submit 200 jobs at a time<br>

 This will output `*junctions_hq.bed`, `*junctions_all.bed` and `*junctions_all.rum` to `Sample*` directory of all samples.

* **Get Novel Exons**

 This takes `*junctions_all.rum` files as input.

         perl runall_get_novel_exons.pl <sample dirs> <loc> <sam file name> <gene info file> [options]

    * &lt;sample dirs> : a file with the names of the sample directories
    * &lt;loc> : full path of the directory with the sample directories (`READS`)
    * &lt;sam file name> : the name of sam file (e.g. RUM.sam, Aligned.out.sam)
    * &lt;gene info file> : a UCSC gene annotation file including chrom, strand, txStrand, txEnd, exonCount, exonStarts, exonEnds, and name
    * options : <br>
     **-min &lt;n>** : size of inferred exon, min is set at 10 by default<br>
     **-max &lt;n>** : size of inferred exon, max is set at 1200 by default

 This outputs `*list_of_inferred_exons.txt` file of all samples to each sample directory. It also outputs `master_list_of_exons.*STUDY*.txt` file to `READS` directory.

##### C. [optional step] : Filter Other High Expressors
This is an extra filter step that removes highly expressed exons.

I. Run Quantify exons

Run the following command with **&lt;output sam?> = false**. By default this will return unique exonmappers. Use -NU-only to get non-unique exonmappers:

    perl runall_quantify_exons.pl <sample dirs> <loc> <exons> <output sam?> [options]

> `quantify_exons.pl` available for running one sample at a time

* &lt;sample dirs> : a file with the names of the sample directories
* &lt;loc> : full path of the directory with the sample directories (`READS`)
* &lt;exons> : `master_list_of_exons.*STUDY*.txt` file
* &lt;output sam?> : false
* option:<br>
  **-NU-only** : set this for non-unique mappers<br>
  **-se** :  set this if the data are single end, otherwise by default it will assume it's a paired end data <br>
  **-filter_highexp** : set this if you want to filter reads that map to highly expressed exons<br>
  **-lsf** : set this if you want to submit batch jobs to LSF<br>
  **-sge** :  set this if you want to submit batch jobs to Sun Grid Engine<br>
  **-other "&lt;submit>, &lt;jobname_option>, &lt;request_memory_option>, &lt;queue_name_for_4G>, &lt;status>"** : set this if you're not on LSF or SGE cluster<br>
  **-mem &lt;s>** : set this if your job requires more memory. &lt;s> is the queue name for required mem (Default: 4G)<br>
  **-max_jobs &lt;n>** : set this if you want to control the number of jobs submitted. by default it will submit 200 jobs at a time<br>

This will output `exonquants` file of all samples to `STUDY/READS/Sample*/EIJ/Unique` and/or `STUDY/READS/Sample*/EIJ/NU`.


II. Get High Expressors

    perl runall_get_high_expressors.pl <sample dirs> <loc> <cutoff> <annotation file> <exons> [options]

* &lt;sample dirs> : a file with the names of the sample directories
* &lt;loc> : full path of the directory with the sample directories (`READS`)
* &lt;cutoff> : cutoff % value 
* &lt;annotation file> : should be downloaded from UCSC known-gene track including at minimum the following suffixes: name (this should correspond to your main identifier, typically some kind of transcript id), chrom, exonStarts, exonEnds; and, optionally, the suffix
es: geneSymbol, and description.

> annotation file for mm9 and hg19 available: `Normalization/norm_scripts/ucsc_known_hg19` and `Normalization/norm_scripts/ucsc_known_hg19`

* &lt;exons> : `master_list_of_exons.*STUDY*.txt` file
* option:<br>
  **-u**  :  set this if you want to return only unique exonpercents, otherwise by default it will return both unique and non-unique exonpercents.<br>
  **-nu** :  set this if you want to return only non-unique exonpercents, otherwise by default it will return both unique and non-unique exonpercents.<br>
  **-lsf** : set this if you want to submit batch jobs to LSF<br>
  **-sge** :  set this if you want to submit batch jobs to Sun Grid Engine<br>
  **-other "&lt;submit>, &lt;jobname_option>, &lt;request_memory_option>, &lt;queue_name_for_15G>, &lt;status>"** : set this if you're not on LSF or SGE cluster<br>
  **-mem &lt;s>** : set this if your job requires more memory. &lt;s> is the queue name for required mem (Default: 15G)<br>
  **-max_jobs &lt;n>** : set this if you want to control the number of jobs submitted. by default it will submit 200 jobs at a time<br>

This will output `*exonpercents.txt` and `*high_expressors_annot.txt` files to `STUDY/READS/Sample*/EIJ/Unique` and/or `STUDY/READS/Sample*/EIJ/NU`. It will also output `annotated_master_list_of_exons.*STUDY*.txt` to `STUDY/READS` directory.

III. Filter High Expressors

     perl filter_high_expressors.pl <sample dirs> <loc> <exons> [options]

* &lt;sample dirs> : a file with the names of the sample directories
* &lt;loc> : full path of the directory with the sample directories (`READS`)
* &lt;exons> : `master_list_of_exons.*STUDY*.txt` file
* option:<br>
  **-u**  :  set this if you're only using unique exonpercents, otherwise by default it will use both unique and non-unique exonpercents.<br>
  **-nu** :  set this if you're only using non-unique exonpercent, otherwise by default it will use both unique and non-unique exonpercents.<br>

This will output a text file called `filtered_master_list_of_exons.*STUDY*.txt` to `STUDY/READS` directory.

__[NORMALIZATION FACTOR] High expressor exonpercent__

     perl get_percent_high_expressor.pl <sample dirs> <loc> [options]

* &lt;sample dirs> : a file with the names of the sample directories 
* &lt;loc> : full path of the directory with the sample directories (`READS`)
* option:<br>
 **-nu** :  set this if you want to return only non-unique stats, otherwise by default it will return only unique stats

This will output `percent_high_expressor_exon_Unique.txt` or `percent_high_expressor_NU.txt` depending on the option provided to `STUDY/STATS/EXON_INTRON_JUNCTION/` directory.

##### D. Run quantify exons

This step takes filtered sam files and splits them into 1, 2, 3 ... n exonmappers and notexonmappers (n = 20 if you don't use the -depth option).

Run the following command with **&lt;output sam?> = true** and **-filter_highexp** option. By default this will return unique exonmappers. Use -NU-only to get non-unique exonmappers:

    perl runall_quantify_exons.pl <sample dirs> <loc> <exons> <output sam?> [options]

> `quantify_exons.pl` and `quantify_exons_filterhighexp.pl available for running one sample at a time

* &lt;sample dirs> : a file with the names of the sample directories 
* &lt;loc> : full path of the directory with the sample directories (`READS`)
* &lt;exons> : the `filtered_master_list_of_exons.*STUDY*.txt` (or `master_list_of_exons.*STUDY*.txt` if you skipped step 3B)
* &lt;output sam?> : true
* option:<br>
  **-depth &lt;n>** : by default, it will output 20 exonmappers<br>
  **-NU-only** : set this for non-unique mappers<br>
  **-se** :  set this if the data are single end, otherwise by default it will assume it's a paired end data <br>
  **-filter_highexp** : set this if you want to filter reads that map to highly expressed exons<br>
  **-lsf** : set this if you want to submit batch jobs to LSF<br>
  **-sge** :  set this if you want to submit batch jobs to Sun Grid Engine<br>
  **-other "&lt;submit>, &lt;jobname_option>, &lt;request_memory_option>, &lt;queue_name_for_4G>, &lt;status>"** : set this if you're not on LSF or SGE cluster<br>
  **-mem &lt;s>** : set this if your job requires more memory. &lt;s> is the queue name for required mem (Default: 4G)<br>
  **-max_jobs &lt;n>** : set this if you want to control the number of jobs submitted. by default it will submit 200 jobs at a time<br>

This outputs multiple files of all samples: `exonmappers.(1, 2, 3, 4, ... n).sam`, `notexonmappers.sam`, and `exonquants` file to `EIJ/Unique` / `EIJ/NU` directory inside each sample directory. 

__[NORMALIZATION FACTOR] Exon to nonexon signal__

     perl get_exon2nonexon_signal_stats.pl <sample dirs> <loc> [options]

* &lt;sample dirs> : a file with the names of the sample directories 
* &lt;loc> : full path of the directory with the sample directories (`READS`)
* option:<br>
 **-u** : set this if you want to return only unique stats, otherwise by default it will return both unique and non-uniqe stats<br>
 **-nu** :  set this if you want to return only non-unique stats, otherwise by default it will return both unique and non-uniqe stats

This will output `exon2nonexon_signal_stats_Unique.txt` and/or `exon2nonexon_signal_stats_NU.txt` depending on the option provided to `STUDY/STATS/EXON_INTRON_JUNCTION/` directory.


__[NORMALIZATION FACTOR] One exon vs multi exons__

    perl get_1exon_vs_multi_exon_stats.pl  <sample dirs> <loc> [options]

* &lt;sample dirs> : a file with the names of the sample directories
* &lt;loc> : full path of the directory with the sample directories (`READS`)
* option:<br>
 **-u** : set this if you want to return only unique stats, otherwise by default it will return both unique and non-uniqe stats<br>
 **-nu** :  set this if you want to return only non-unique stats, otherwise by default it will return both unique and non-uniqe stats

This will output `1exon_vs_multi_exon_stats_Unique.txt` and/or `1exon_vs_multi_exon_stats_NU.txt` depending on the option provided to `STUDY/STATS/EXON_INTRON_JUNCTION/` directory.

#### 3) Quantify Introns
##### A. Create Master List of Introns

    perl get_master_list_of_introns_from_geneinfofile.pl <gene info file> <loc>

* &lt;gene info file> : a UCSC gene annotation file including chrom, strand, txStrand, txEnd, exonCount, exonStarts, exonEnds, and name.
* &lt;loc> : full path of the directory with the sample directories (`READS`)

This outputs a txt file called `master_list_of_introns.txt` to `READS` directory.

##### B. Run quantify introns

This step takes `notexonmappers.sam` files and splits them into 1, 2, 3 ... n intronmappers and intergenicmappers files (n = 10 if you don't use the -depth option). 

Run the following command with **&lt;output sam?> = true**. By default this will return unique intronmappers. Use -NU-only to get non-unique intronmappers:

    perl runall_quantify_introns.pl <sample dirs> <loc> <introns> <output sam?> [options]

> `quantify_introns.pl` available for running one sample at a time

* &lt;sample dirs> : a file with the names of the sample directories 
* &lt;loc> : full path of the directory with the sample directories (`READS`)
* &lt;introns> : the `master_list_of_introns.txt` file (with full path)
* &lt;output sam?> : true
* option : <br>
  **-depth &lt;n>** : by default, it will output 10 intronmappers<br>
  **-NU-only** : set this for non-unique mappers<br>
  **-lsf** : set this if you want to submit batch jobs to LSF<br>
  **-sge** :  set this if you want to submit batch jobs to Sun Grid Engine<br>
  **-other "&lt;submit>, &lt;jobname_option>, &lt;request_memory_option>, &lt;queue_name_for_4G>, &lt;status>"** : set this if you're not on LSF or SGE cluster<br>
  **-mem &lt;s>** : set this if your job requires more memory. &lt;s> is the queue name for required mem (Default: 4G)<br>
  **-max_jobs &lt;n>** : set this if you want to control the number of jobs submitted. by default it will submit 200 jobs at a time<br>
 
This outputs multiple files of all samples: `intronmappers.(1, 2, 3, ... n).sam`, `intergenicmappers.sam`, and `intronquants` file to `Unique` / `NU` directory in each sample directory.

__[NORMALIZATION FACTOR] Percent of non-exonic signal that is intergenic (as opposed to intronic)__

    perl get_percent_intergenic.pl  <sample dirs> <loc> [options]

* &lt;sample dirs> : a file with the names of the sample directories
* &lt;loc> : full path of the directory with the sample directories (`READS`)
* option:<br>
 **-u** : set this if you want to return only unique stats, otherwise by default it will return both unique and non-uniqe stats<br>
 **-nu** :  set this if you want to return only non-unique stats, otherwise by default it will return both unique and non-uniqe stats

This will output `percent_intergenic_Unique.txt` and/or `percent_intergenic_NU.txt` depending on the option provided to `STUDY/STATS/EXON_INTRON_JUNCTION/` directory.

#### 4) Predict Number of Reads

      perl predict_num_reads.pl <sample dirs> <loc> [option]

* &lt;sample dirs> : a file with the names of the sample directories
* &lt;loc> : full path of the directory with the sample directories (`READS`)
* option : <br>
 **-u** : set this if you want to return number of unique reads only, otherwise by default it will return number of unique and non-unique reads <br>
 **-nu** : set this if you want to return number of non-unique reads only, otherwise by default it will return number of unique and non-unique reads <br>
 **-depthE &lt;n>** : This is the number of exonmappers file used for normalization. (By default, &lt;n> = 20)<br>
 **-depthI &lt;n>** : This is the number of intronmappers file used for normalization. (By default, &lt;n> = 10)

This will provide a rough estimate of number of reads you'll have after normalization in `STUDY/STATS/EXON_INTRON_JUNCTION/expected_num_reads.txt`. Based on this information, samples can be added/removed by modifying `sample_dirs` file.

#### [PART2]

#### [PART2 - Gene Normalization]
#### 1) Downsample

      perl runall_shuf_gnorm.pl <sample dirs> <loc> [options]

* &lt;sample dirs> : a file with the names of the sample directories
* &lt;loc> : full path of the directory with the sample directories (`READS`)
* option : <br>
  **-u** : set this if you want to return only unique mappers, otherwise by default it will return both unique and non-uniqe mappers<br>
  **-nu** :  set this if you want to return only non-unique mappers, otherwise by default it will return both unique and non-uniqe mappers<br>
  **-se** : set this if the data are single end, otherwise by default it will assume it's a paired end data.<br>
  **-max_jobs &lt;n>** : set this if you want to control the number of jobs submitted. by default it will submit 200 jobs at a time<br>
  **-lsf** : set this if you want to submit batch jobs to LSF<br>
  **-sge** :  set this if you want to submit batch jobs to Sun Grid Engine<br>
  **-other "&lt;submit>, &lt;jobname_option>, &lt;request_memory_option>, &lt;queue_name_for_6G>, &lt;status>"** : set this if you're not on LSF or SGE cluster<br>
  **-mem &lt;s>** : set this if your job requires more memory. &lt;s> is the queue name for required mem (Default: 6G)<br>
  ** If the maximum line count in `STUDY/READS/sample*/GNORM/*/*linecounts*txt` is > 50,000,000, use -mem option (6G for 60 million lines, 7G for 70 million lines, 8G for 80 million lines, etc).

This will output the same number of rows from each file in `STUDY/READS/Sample*/GNORM/Unique` (same for NU) to `NORMALIZED_DATA/GENE/Unique` (and NU).

#### 2) Concatenate downsampled files

      perl cat_gnorm_Unique_NU.pl <sample dirs> <loc> <samfilename>

* &lt;sample dirs> : a file with the names of the sample directories
* &lt;loc> : full path of the directory with the sample directories (`READS`)
* &lt;samfilename> : name of the original samfile

This will create `STUDY/NORMALIZED_DATA/GENE/MERGED` directory, concatenate normalized unique and non-unique reads and output to the directory created.

#### 3) Run sam2genes
Run the following with **-norm** option.

    perl runall_sam2genes_gnorm.pl <sample dirs> <loc> <ensGene file> [options]

> `sam2genes.pl` available for running one sample at a time

* &lt;sample dirs> : a file with the names of the sample directories
* &lt;loc> : full path of the directory with the sample directories (`READS`)
* &lt;ensGene file> : ensembl table must contain columns with the following suffixes: name, chrom, txStart, txEnd, exonStarts, exonEnds, name2, ensemblToGeneName.value

* option:<br>
  **-se** : set this if the data are single end, otherwise by default it will assume it's a paired end data.<br>
  **-str_f** : set this if the data are strand-specific AND forward read is in the same orientation as the transcripts/genes.<br>
  **-str_r** : set this if the data are strand-specific AND reverse read is in the same orientation as the transcripts/genes.<br>
  **-u**  :  set this if you are using unique mappers only, otherwise by default it will use both unique and non-unique mappers. <br>
  **-nu** :  set this if you are using non-unique mappers only, otherwise by default it will use both unique and non-unique mappers. <br>
  **-norm** : set this to get genes file for the gene-normalized sam files.<br>
  **-lsf** : set this if you want to submit batch jobs to LSF<br>
  **-sge** :  set this if you want to submit batch jobs to Sun Grid Engine<br>
  **-other "&lt;submit>, &lt;jobname_option>, &lt;status>"** : set this if you're not on LSF or SGE cluster<br>
  **-max_jobs &lt;n>** : set this if you want to control the number of jobs submitted. by default it will submit 200 jobs at a time<br>

This outputs `*genes.txt` file to `STUDY/NORMALIZED_DATA/GENE/MERGED`, `STUDY/NORMALIZED_DATA/GENE/Unique`, or `STUDY/NORMALIZED_DATA/GENE/NU`.

#### 4) Run Quantify Genes
Run the following with **-norm** option.

    perl runall_quantify_genes_gnorm.pl <sample dirs> <loc> <genes>

> `quantify_genes.pl` available for running one sample at a time

* &lt;sample dirs> : a file with the names of the sample directories
* &lt;loc> : full path of the directory with the sample directories (`READS`)
* &lt;genes> : master list of genes file

* option:<br>
  **-u**  :  set this if you are using unique mappers only, otherwise by default it will use both unique and non-unique mappers. <br>
  **-nu** :  set this if you are using non-unique mappers only, otherwise by default it will use both unique and non-unique mappers. <br>
  **-se** : set this if the data are single end, otherwise by default it will assume it's a paired end data.<br>
  **-norm** : set this to quantify normalized sam. <br>
  **-lsf** : set this if you want to submit batch jobs to LSF<br>
  **-sge** :  set this if you want to submit batch jobs to Sun Grid Engine<br>
  **-other "&lt;submit>, &lt;jobname_option>, &lt;request_memory_option>, &lt;queue_name_for_10G>,&lt;status>"** : set this if you're not on LSF or SGE cluster<br>
  **-mem &lt;s>** : set this if your job requires more memory. &lt;s> is the queue name for required mem (Default: 10G)<br>
  **-max_jobs &lt;n>** : set this if you want to control the number of jobs submitted. by default it will submit 200 jobs at a time<br>

This outputs `genequants` file to `STUDY/NORMALIZED_DATA/GENE/MERGED`, `STUDY/NORMALIZED_DATA/GENE/Unique`, or `STUDY/NORMALIZED_DATA/GENE/NU`.

#### 5) Run sam2junctions
Run the following with **-gnorm** option.

    perl runall_sam2junctions.pl <sample dirs> <loc> <genes> <genome> [options]

* &lt;sample dirs> : a file with the names of the sample directories
* &lt;loc> : full path of the directory with the sample directories (`READS`)
* &lt;genes> :the RUM gene info file
* &lt;genome> : the RUM genome sequene one-line fasta file
* option:<br>
  **-samfilename &lt;s> : set this to create junctions files using unfiltered aligned samfile. &lt;s> is the name of aligned sam file (e.g. RUM.sam, Aligned.out.sam) and all sam files in each sample directory should have the same name.<br>
  **-u**  :  set this if you want to return only unique junctions files, otherwise by default it will return merged(unique+non-unique) junctions files.<br>
  **-nu** :  set this if you want to return only non-unique files, otherwise by default it will return merged(unique+non-unique) junctions files.<br>
  **-gnorm** : set this to create junctions files for gene normalization output.
  **-lsf** : set this if you want to submit batch jobs to LSF<br>
  **-sge** :  set this if you want to submit batch jobs to Sun Grid Engine<br>
  **-other "&lt;submit>, &lt;jobname_option>, &lt;request_memory_option>, &lt;queue_name_for_6G>, &lt;status>"** : set this if you're not on LSF or SGE cluster<br>
  **-mem &lt;s>** : set this if your job requires more memory. &lt;s> is the queue name for required mem (Default: 6G)<br>
  **-max_jobs &lt;n>** : set this if you want to control the number of jobs submitted. by default it will submit 200 jobs at a time<br>

This will create `STUDY/NORMALIZED_DATA/GENE/JUNCTIONS` directory and output `junctions_hq.bed`, `junctions_all.bed` and `junctions_all.rum` files of all samples.

#### 6) Make Final Spreadsheets
Run the following with &lt;type of quants file> = **genequants**.

     perl quants2spreadsheet_min_max.pl <sample dirs> <loc> <type of quants file>

* &lt;sample dirs> : a file with the names of the sample directories
* &lt;loc> : full path of the directory with the sample directories (`READS`)
* &lt;type of quants file> : exonquants, intronquants, genequants

This will create `STUDY/NORMALIZED_DATA/GENE/SPREADSHEETS` directory and output `master_list_of_genes_counts` files.

#### 7) Filter low expressors

    perl runall_filter_low_expressors.pl <file of quants files> <number_of_samples> <cutoff> <loc>

* &lt;file of quants files> : a file with the names of the quants file

         e.g. the <file of quants files> file should look like this:
              master_list_of_genes_counts_MIN.STUDY.txt
              master_list_of_genes_counts_MAX.STUDY.txt

* &lt;number_of_samples> : number of samples
* &lt;cutoff> : cutoff value
* &lt;loc> : full path of the directory with the sample directories (`READS`)

This will output `FINAL_master_list_of_genes_counts` to `STUDY/NORMALIZED_DATA/GENE/SPREADSHEETS`.

#### [PART2 - Exon-Intron-Junction Normalization]
#### 1) Downsample

##### A. Downsample by type
This identifies minimum line count of each type of exonmappers/intronmappers/intergenicmappers and downsamples each file by taking the minimum line count of rows from each file.
      
      perl runall_shuf.pl <sample dirs> <loc> [options]

* &lt;sample dirs> : a file with the names of the sample directories 
* &lt;loc> : full path of the directory with the sample directories (`READS`)
* option : <br>
  **-depthE &lt;n>** : set the exonmapper depth (by default, n = 20). set this to 0 if you only want to return intronmappers and intergenic mappers<br>
  **-depthI &lt;n>** : set the intronmapper depth (by default, n = 10). set this to 0 if you only want to return exonmappers<br>
  **-u** : set this if you want to return only unique mappers, otherwise by default it will return both unique and non-uniqe mappers<br>
  **-nu** :  set this if you want to return only non-unique mappers, otherwise by default it will return both unique and non-uniqe mappers<br>
  **-max_jobs &lt;n>** : set this if you want to control the number of jobs submitted. by default it will submit 200 jobs at a time<br>
  **-lsf** : set this if you want to submit batch jobs to LSF<br>
  **-sge** :  set this if you want to submit batch jobs to Sun Grid Engine<br>
  **-other "&lt;submit>, &lt;jobname_option>, &lt;request_memory_option>, &lt;queue_name_for_6G>, &lt;status>"** : set this if you're not on LSF or SGE cluster<br>
  **-mem &lt;s>** : set this if your job requires more memory. &lt;s> is the queue name for required mem (Default: 6G)<br>
  ** If the maximum line count in `STUDY/READS/sample*/EIJ/*/*linecounts*txt` is > 50,000,000, use -mem option (6G for 60 million lines, 7G for 70 million lines, 8G for 80 million lines, etc).

This will output the same number of rows from each file in each `sample_dir/EIJ/Unique` and/or `sample_dir/EIJ/NU` directory of the same type.

##### B. Concatenate downsampled files

      perl cat_shuffiles.pl <sample dirs> <loc> [options]

* &lt;sample dirs> : a file with the names of the sample directories 
* &lt;loc> : full path of the directory with the sample directories (`READS`)
* option:<br>
  **-u**  :  set this if you want to return only unique mappers, otherwise by default
         it will return both unique and non-unique mappers.<br>
  **-nu** :  set this if you want to return only non-unique mappers, otherwise by default
         it will return both unique and non-unique mappers.

This will create `STUDY/NORMALIZED_DATA/EXON_INTRON_JUNCTION`, `STUDY/NORMALIZED_DATA/EXON_INTRON_JUNCTION/exonmappers`, and `STUDY/NORMALIZED_DATA/EXON_INTRON_JUNCTION/notexonmappers` directories and output normalized exonmappers, intronmappers and intergenic mappers of all samples to the directories created.

##### C. Merge normalized SAM files

      perl make_final_samfile.pl <sample dirs> <loc> <sam file name> [options]

* &lt;sample dirs> : a file with the names of the sample directories 
* &lt;loc> : full path of the directory with the sample directories (`READS`)
* &lt;sam file name> : the name of sam file (e.g. RUM.sam, Aligned.out.sam)
* option:<br>
  **-u**  :  set this if you want to return only unique mappers, otherwise by default
         it will return merged final sam.<br>
  **-nu** :  set this if you want to return only non-unique mappers, otherwise by default
         it will return merged final sam.

This will create `STUDY/NORMALIZED_DATA/EXON_INTRON_JUNCTION/FINAL_SAM`. Then, depending on the option given, it will make `FINAL_SAM/Unique`, `FINAL_SAM/NU`, or `FINAL_SAM/MERGED` directory and output final sam files to the directories created. A tag will be added to each sequence indicating its type (XT:A:E for exonmappers, XT:A:I for intronmapper, and XT:A:G for intergenicmappers).

#### 7) Run sam2junctions
 
    perl runall_sam2junctions.pl <sample dirs> <loc> <genes> <genome> [options]

* &lt;sample dirs> : a file with the names of the sample directories 
* &lt;loc> : full path of the directory with the sample directories (`READS`)
* &lt;genes> :the RUM gene info file 
* &lt;genome> : the RUM genome sequene one-line fasta file 
* option:<br>
  **-samfilename &lt;s> : set this to create junctions files using unfiltered aligned samfile. &lt;s> is the name of aligned sam file (e.g. RUM.sam, Aligned.out.sam) and all sam files in each sample directory should have the same name.<br>
  **-u**  :  set this if you want to return only unique junctions files, otherwise by default it will return merged(unique+non-unique) junctions files.<br>
  **-nu** :  set this if you want to return only non-unique files, otherwise by default it will return merged(unique+non-unique) junctions files.<br>
  **-gnorm** : set this to create junctions files for gene normalization output.
  **-lsf** : set this if you want to submit batch jobs to LSF<br>
  **-sge** :  set this if you want to submit batch jobs to Sun Grid Engine<br>
  **-other "&lt;submit>, &lt;jobname_option>, &lt;request_memory_option>, &lt;queue_name_for_6G>, &lt;status>"** : set this if you're not on LSF or SGE cluster<br>
  **-mem &lt;s>** : set this if your job requires more memory. &lt;s> is the queue name for required mem (Default: 6G)<br>
  **-max_jobs &lt;n>** : set this if you want to control the number of jobs submitted. by default it will submit 200 jobs at a time<br>
 
This will create `STUDY/NORMALIZED_DATA/EXON_INTRON_JUNCTION/JUNCTIONS` directory and output `junctions_hq.bed`, `junctions_all.bed` and `junctions_all.rum` files of all samples.

#### 8) Master table of features counts
#####A. Get Exonquants 
**a. Concatenate unique and non-unique normalized exonmappers**

If you want to quantify both Unique and Non-unique normalized exonmappers run this. If you're only interested in either Unique or Non-Unique exonmappers, go to step b.:

    perl cat_exonmappers_Unique_NU.pl <sample dirs> <loc>

* &lt;sample dirs> : a file with the names of the sample directories
* &lt;loc> : full path of the directory with the sample directories (`READS`)

This will create `NORMALIZED_DATA/EXON_INTRON_JUNCTION/exonmappers/MERGED` directory and output concatenated `exonmappers.norm.sam` file of all samples to the directory created.

**b. Run Quantify exons**

Run the following command with **&lt;output sam?> = false** and **-norm** option. This will output merged exonquants by default. If merged exonmappers do not exist, it will output unique exonquants. Use -NU-only to get non-unique exonquants:

    perl runall_quantify_exons.pl <sample dirs> <loc> <exons> <output sam?> [options]

> `quantify_exons.pl` available for running one sample at a time

* &lt;sample dirs> : a file with the names of the sample directories 
* &lt;loc> : full path of the directory with the sample directories (`READS`)
* &lt;exons> : the `filtered_master_list_of_exons.*STUDY*.txt` (or `master_list_of_exons.*STUDY*.txt` file if you skipped step 3B)
* &lt;output sam?> : false
* option:<br>
  **-NU-only** : set this for non-unique mappers<br>
  **-se** :  set this if the data are single end, otherwise by default it will assume it's a paired end data <br>
  **-norm** : set this if you want to quantify the normalized sam files<br>
  **-lsf** : set this if you want to submit batch jobs to LSF<br>
  **-sge** :  set this if you want to submit batch jobs to Sun Grid Engine<br>
  **-other "&lt;submit>, &lt;jobname_option>, &lt;request_memory_option>, &lt;queue_name_for_4G>, &lt;status>"** : set this if you're not on LSF or SGE cluster<br>
  **-mem &lt;s>** : set this if your job requires more memory. &lt;s> is the queue name for required mem (Default: 4G)<br>
  **-max_jobs &lt;n>** : set this if you want to control the number of jobs submitted. by default it will submit 200 jobs at a time<br>
  			  
This outputs `exonquants` file of all samples to `NORMALIZED_DATA/EXON_INTRON_JUNCTION/exonmappers/MERGED` (or `NORMALIZED_DATA/EXON_INTRON_JUNCTION/exonmappers/Unique` or `NORMALIZED_DATA/EXON_INTRON_JUNCTION/exonmappers/NU`).

#####B. Get Intronquants

Run the following command with **&lt;output sam?> = false**. By default this will return unique intronquants. Use -NU-only to get non-unique intronquants:

    perl runall_quantify_introns.pl <sample dirs> <loc> <introns> <output sam?> [options]

> `quantify_introns.pl` available for running one sample at a time

* &lt;sample dirs> : a file with the names of the sample directories 
* &lt;loc> : full path of the directory with the sample directories (`READS`)
* &lt;introns> : the `master_list_of_introns.txt` file 
* &lt;output sam?> : false
* option:<br>
  **-NU-only** : set this for non-unique mappers<br>
  **-lsf** : set this if you want to submit batch jobs to LSF<br>
  **-sge** :  set this if you want to submit batch jobs to Sun Grid Engine<br>
  **-other "&lt;submit>, &lt;jobname_option>, &lt;request_memory_option>, &lt;queue_name_for_4G>, &lt;status>"** : set this if you're not on LSF or SGE cluster<br>
  **-mem &lt;s>** : set this if your job requires more memory. &lt;s> is the queue name for required mem (Default: 4G)<br>
  **-max_jobs &lt;n>** : set this if you want to control the number of jobs submitted. by default it will submit 200 jobs at a time<br>

This outputs `intronquants` file of all samples to `NORMALIZED_DATA/EXON_INTRON_JUNCTION/notexonmappers/Unique` or `NORMALIZED_DATA/EXON_INTRON_JUNCTION/notexonmappers/NU`.

#####D. Make Final Spreadsheets
**a. Run quants2spreadsheet and juncs2spreadsheet**

     perl make_final_spreadsheets.pl <sample dirs> <loc> [options]

> `quants2spreadsheet.1.pl`, `quants2spreadsheet_min_max.pl`, `juncs2spreadsheet.1.pl`, `juncs2spreadsheet_min_max.pl` available for running separately.

* &lt;sample dirs> : a file with the names of the sample directories 
* &lt;loc> : full path of the directory with the sample directories (`READS`)
* option:<br>
  **-u**  :  set this if you want to return only unique, otherwise by default it will return min and max spreadsheets.<br>
  **-nu** :  set this if you want to return only non-unique, otherwise by default it will return min and max spreadsheets.<br>
  **-lsf** : set this if you want to submit batch jobs to LSF<br>
  **-sge** :  set this if you want to submit batch jobs to Sun Grid Engine<br>
  **-other "&lt;submit>, &lt;jobname_option>, &lt;request_memory_option>, &lt;queue_name_for_6G>, &lt;queue_name_for_10G>,&lt;status>"** : set this if you're not on LSF or SGE cluster<br>
  **-mem &lt;s>** : set this if your job requires more memory. &lt;s> is the queue name for required mem (Default: 6G, 10G)<br>
  **-max_jobs &lt;n>** : set this if you want to control the number of jobs submitted. by default it will submit 200 jobs at a time<br>

This will output `master_list_of_exons_counts`, `master_list_of_introns_counts`, and `master_list_of_junctions_counts` files to `STUDY/NORMALIZED_DATA/EXON_INTRON_JUNCTION/SPREADSHEETS` directory. 

**b. Annotate `list_of_exons_counts`**
     
     perl run_annotate.pl <file of features files> <annotation file> <loc> [options]

> `annotate.pl` available for running one sample at a time

* &lt;file of features files> : a file with the names of the features files to be annotated

       	   e.g. the <file of feature files> file should look like this:
           	 master_list_of_exons_counts_MIN.STUDY.txt
	    	 master_list_of_exons_counts_MAX.STUDY.txt
           	 master_list_of_introns_counts_MIN.STUDY.txt
	    	 master_list_of_introns_counts_MAX.STUDY.txt
           	 master_list_of_junctions_counts_MIN.STUDY.txt
	    	 master_list_of_junctions_counts_MAX.STUDY.txt
	
* &lt;annotation file> : should be downloaded from UCSC known-gene track including at minimum the following suffixes: name (this should correspond to your main identifier, typically some kind of transcript id), chrom, exonStarts, exonEnds; and, optionally, the suffix
es: geneSymbol, and description.
> annotation file for mm9 and hg19 available: `Normalization/norm_scripts/ucsc_known_hg19` and `Normalization/norm_scripts/ucsc_known_hg19`
* &lt;loc> : full path of the directory with the sample directories (`READS`)
* option : <br>
  **-lsf** : set this if you want to submit batch jobs to LSF<br>
  **-sge** :  set this if you want to submit batch jobs to Sun Grid Engine<br>
  **-other "&lt;submit>, &lt;jobname_option>, &lt;request_memory_option>, &lt;queue_name_for_15G>, &lt;status>"** :  set this if you're not on LSF or SGE cluster<br>
  **-mem &lt;s>** : set this if your job requires more memory. &lt;s> is the queue name for required mem (Default: 15G)<br>
  **-max_jobs &lt;n>** : set this if you want to control the number of jobs submitted. by default it will submit 200 jobs at a time<br>

This will output `annotated_master_list_of_*` to `STUDY/NORMALIZED_DATA/EXON_INTRON_JUNCTION/SPREADSHEETS`.

**c. Filter low expressors**

     perl runall_filter_low_expressors.pl <file of quants files> <number_of_samples> <cutoff> <loc>

* &lt;file of quants files> : a file with the names of the quants file

         e.g. the <file of quants files> file should look like this:
	      annotated_master_list_of_exons_counts_MIN.STUDY.txt
	      annotated_master_list_of_exons_counts_MAX.STUDY.txt
	      annotated_master_list_of_introns_counts_MIN.STUDY.txt
	      annotated_master_list_of_introns_counts_MAX.STUDY.txt
	      annotated_master_list_of_junctions_counts_MIN.STUDY.txt
	      annotated_master_list_of_junctions_counts_MAX.STUDY.txt

* &lt;number_of_samples> : number of samples
* &lt;cutoff> : cutoff value
* &lt;loc> : full path of the directory with the sample directories (`READS`)

This will output `FINAL_master_list_of_genes_counts`, `FINAL_master_list_of_exons_counts`, `FINAL_master_list_of_introns_counts`, `FINAL_master_list_of_junctions_counts` to `STUDY/NORMALIZED_DATA/EXON_INTRON_JUNCTION/SPREADSHEETS`.

#### [PART2 - both Gene and Exon-Intron-Junction Normalization]
#### 1) Normalization Factor Statistics

     perl get_normfactors_table.pl <sample dirs> <loc>

* &lt;sample dirs> : a file with the names of the sample directories
* &lt;loc> : full path of the directory with the sample directories (`READS`)

This will output `exon-intron-junction_normalization_factors.txt` and/or `gene_normalization_factors.txt` file to `STUDY/STATS` directory which will give you summary of your normalization factors stats.

#### 2) Data Visualization

Use sam2cov to create coverage files and upload them to a Genome Browser. Currently, sam2cov only supports reads aligned with RUM or STAR.

#####A. Install [sam2cov](https://github.com/khayer/sam2cov/)

     git clone https://github.com/khayer/sam2cov.git
     cd sam2cov
     make

#####B. Create Coverage Files
I. Gene Normalization

     perl runall_sam2cov_gnorm.pl <sample dirs> <loc> <fai file> <sam2cov> [options]

* &lt;sample dirs> : a file with the names of the sample directories
* &lt;loc> : full path of the directory with the sample directories (`READS`)
* &lt;fai file> : full path of fai file
* &lt;sam2cov> : full path of sam2cov 
* option : <br>
  **-str** : set this if your library is strand-specific<br>
  **-se** : set this if the data are single end, otherwise by default it will assume it's a paired end data.<br>
  **-u** : set this if you want to use only unique mappers to generate coverage files, otherwise by default it will use merged(unique+non-unique) mappers<br>
  **-nu** : set this if you want to use only non-unique mappers to generate coverage files, otherwise by default it will use merged(unique+non-unique) mappers<br>
  **-rum** : set this if you used RUM to align your reads<br>
  **-star** : set this if you used STAR to align your reads<br>
  **-lsf** : set this if you want to submit batch jobs to LSF<br>
  **-sge** :  set this if you want to submit batch jobs to Sun Grid Engine<br>
  **-other "&lt;submit>, &lt;jobname_option>, &lt;request_memory_option>, &lt;queue_name_for_15G>, &lt;status>"** : set this if you're not on LSF or SGE cluster<br>
  **-mem &lt;s>** : set this if your job requires more memory. &lt;s> is the queue name for required mem (Default: 15G)<br>
  **-max_jobs &lt;n>** : set this if you want to control the number of jobs submitted. by default it will submit 200 jobs at a time<br>

This will output `*Unique.cov` and `*NU.cov` files of all samples to `STUDY/NORMALIZED_DATA/GENE/COV`.

I. Exon-Intron-Junction Normalization

     perl runall_sam2cov.pl <sample dirs> <loc> <fai file> <sam2cov> [options]

* &lt;sample dirs> : a file with the names of the sample directories
* &lt;loc> : full path of the directory with the sample directories (`READS`)
* &lt;fai file> : full path of fai file
* &lt;sam2cov> : full path of sam2cov
* option : <br>
  **-str** : set this if your library is strand-specific<br>
  **-u** : set this if you want to use only unique mappers to generate coverage files, otherwise by default it will use merged(unique+non-unique) mappers<br>
  **-nu** : set this if you want to use only non-unique mappers to generate coverage files, otherwise by default it will use merged(unique+non-unique) mappers<br>
  **-rum** : set this if you used RUM to align your reads<br>
  **-star** : set this if you used STAR to align your reads<br>
  **-lsf** : set this if you want to submit batch jobs to LSF<br>
  **-sge** :  set this if you want to submit batch jobs to Sun Grid Engine<br>
  **-other "&lt;submit>, &lt;jobname_option>, &lt;request_memory_option>, &lt;queue_name_for_15G>, &lt;status>"** : set this if you're not on LSF or SGE cluster<br>
  **-mem &lt;s>** : set this if your job requires more memory. &lt;s> is the queue name for required mem (Default: 15G)<br>
  **-max_jobs &lt;n>** : set this if you want to control the number of jobs submitted. by default it will submit 200 jobs at a time<br>

This will output `*Unique.cov` and `*NU.cov` files of all samples to `STUDY/NORMALIZED_DATA/EXON_INTRON_JUNCTION/COV`.

#### 3) Clean Up
#####A. Delete Intermediate SAM Files

     perl cleanup.pl <sample dirs> <loc>

* &lt;sample dirs> : a file with the names of the sample directories 
* &lt;loc> : full path of the directory with the sample directories (`READS`)

This will delete intermediate files.

#####B. Compress Files

     perl runall_compress.pl <sample dirs> <loc> <sam file name> <fai file> [options]

* &lt;sample dirs> : a file with the names of the sample directories 
* &lt;loc> : full path of the directory with the sample directories (`READS`)
* &lt;sam file name> : name of the alignment sam file (e.g. RUM.sam, Aligned.out.sam)
* &lt;fai file> : full path of fai file 
* option : <br>
  **-dont_cov** : set this if you DO NOT want to gzip the coverage files (By default, it will gzip the coverage files) <br>
  **-dont_bam** : set this if you DO NOT want to convert SAM to bam (By default, it will conver sam to bam) <br>
  **-lsf** : set this if you want to submit batch jobs to LSF<br>
  **-sge** :  set this if you want to submit batch jobs to Sun Grid Engine<br>
  **-other "&lt;submit>, &lt;jobname_option>, &lt;request_memory_option>, &lt;queue_name_for_6G>, &lt;status>"** : set this if you're not on LSF or SGE cluster<br>
  **-mem &lt;s>** : set this if your job requires more memory. &lt;s> is the queue name for required mem (Default: 6G)<br>
  **-max_jobs &lt;n>** : set this if you want to control the number of jobs submitted. by default it will submit 200 jobs at a time<br>

This will covert SAM to BAM, delete the SAM, and gzip the coverage files. 
 