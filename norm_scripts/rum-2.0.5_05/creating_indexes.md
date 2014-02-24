How to create indexes for the RUM pipeline
==========================================

These instructions have three parts:

1. Your organism is available on the ucsc genome browser

2. Your organism is available on the ensembl website

3. Your organism is not on either ucsc or ensembl but you have genome
  sequence and optionally gene or transcript models.

**Prerequisites** You need bowtie installed on your system, including
bowtie-build which should come with the default installation. The
bowtie-build executable must be in the system path. If that's not
possible then you can edit the perl scripts where bowtie-build is
called to add the full path.

*NOTE*: Some genome builds contain haplotype copies of the same
chromosome.  You should not include multiple haplotypes in a RUM index
because the pipeline will consider reads mapping to two haplotypes as
non-uniquely determined alignments. Therefore when we built the human
indexes we left out the chromosomes with 'hap' in the name, you should
probably do the same when building your own indexes.

Your organism is available on the ucsc genome browser
-----------------------------------------------------

This first part explains how to get the genome sequence using the
table browser. You can alternatively get it from the downloads page as
follows:

### Downloading the genome sequence from the genome downloads page

The downloads link is on the left of the home page, find the species
and hit the "Full data set" and get the file with the genome sequence,
unmasked, sometimes it's called chromFA.tar.gz, or something like
that. When you unpack it, it may be in many pieces, possibly
distributed into subdirectories. You must concatenate them all
together into one file and name that file NAME_genome.txt (where
"NAME" is defined below). The file name MUST end in 'txt' not
'fa'. After that proceed with the instructions to get the gene models
file(s) using the table browser.

### Downloading the genome sequence using the table browser

If you do not opt to get the fasta files from the download page, then
use the following instructions:

1. Go to UCSC's main page (http://genome.ucsc.edu/), choose the organism and
assembly.

2. Go to Table Browser and set the options as follows:

        group: all tables
        table: chromInfo
        output format: selected fields from primary and related tables
        output file: chromosome_sizes.txt

3. hit "get output" and choose the 'chrom' and 'size' fields.

4. Now remove the header line (if any) from chromosome_sizes.txt and
   add columns so rows look like this:

        chr1    0       249250621     +
        chr2    0       181748087     +
        ....

   in other words, add a column with '0' between the chr and size cols,
   and add a col with '+' at the end

   *The next steps get a FASTA file with the complete genome sequence.*

5.  Submit the file from the previous step to the genome browser as a
    custom track, then go to table browser and set as follows:

        group: custom tracks
        track: User Track
        region: genome
        output format: sequence
        output file: NAME_genome.txt
        file type returned: gzip

    where "NAME" should be replaced by something that identifies your
    name/assembly, eg mm9.  Just use alphanumeric, dashes, periods in
    NAME, do not use underscores.  The scripts below won't work unless
    you follow this naming convention exactly.  Note the suffix must
    be '.txt' not '.fa'

6.  Hit get output, and request all upper case

7.  gunzip the file and run the following steps.

### Making gene info files

Now to make files of gene info and sequence. You can use any of the
annotation tracks as long as they have the five fields you are asked
to select below. The following illustrates using two tracks "UCSC
Known" and "RefSeq". If there are many annotation tracks, such as for
mouse where there are more than ten, you probably shouldn't include
them all. By default we have been using just three of them for mouse:
refseq, ucsc and aceview. Using all tracks would create a transcript
db that is too complex, it's better to let blat map the reads for
transcripts that are not present in the db rather than to expand the
db too much with false transcripts.

1. Set the table browser as follows:

        group: Genes and Gene Prediction Tracks
        track: UCSC Genes (or whatever track you like)
        table: knownGene (or whatever is the corresponding name for the track you chose)
        region: genome
        output format: selected fields from primary and related tables
        output file: ucscknown.txt (keep the name of this file simple, but it must end in '.txt')

2. Hit "get output"

3. Select the following fields from the table: name, chrom, strand, exonStarts, and exonEnds.

4. hit "get output".

5. Now do the same thing but get RefSeq genes, save to file called: refseq.txt. Set 'table' to be "refGene".

6. make a file called "gene_info_files" with one line per gene annotation filename:

        refseq.txt
        ucscknown.txt

### Assembling the index

All the  data files you just downloaded need to be in the same
directory. Now from that directory, run:

    > perl create_indexes_from_ucsc.pl NAME_genome.txt NAME_refseq_ucsc

Note that you will need to supply the full path to the
create_indexes_from_ucsc.pl script, which is available in the 'bin'
directory of the RUM distribution. This is a master script that runs a
bunch of other scripts including bowtie-build. You will need a fair
amount of RAM to do this, 10Gb was sufficient for Human.

This will create a directory called $NAME (where NAME is the prefix of
the files you provided as command line arguments) and put all of the
important index files in there.  Move that directory to where your
other RUM indexes are stored.  For example, if you keep all of your
RUM indexes in ~/rum_indexes, and you have indexes for mouse (mm9) and
human (hg19), you would have the following directory structure:

    ~/
    ~/rum_indexes
    ~/rum_indexes/mm9/
    ~/rum_indexes/mm9/mm9_refseq_ucsc_gene_info.txt
    ...
    ~/rum_indexes/hg19/
    ~/rum_indexes/hg19/hg19_refseq_ucsc_gene_info.txt
    ...

To run RUM with one of these indexes, for example hg19, you would
provide the directory location with the `--index-dir` or `-i`
option:

    rum_runner -i ~/rum_indexes/hg19 ...

Your organism is available on the ensembl website
-------------------------------------------------

Go to ensembl.org and find your species. Note that the default site is
for vertibrates, there are currently five sites for different
kingdoms:

* http://www.ensembl.org/
* http://metazoa.ensembl.org/
* http://fungi.ensembl.org/
* http://plants.ensembl.org/
* http://bacteria.ensembl.org/

Once you found your species, click on the "Downloads" link at the top
of the page (you may have to stretch your browser wide enough to see
it). On the Downloads page scroll down to the section called "FTP
site" and click the "FTP site" link. You should see a table full of
links on the right. Click the "FASTA (DNA)" link for your species, it
should open in a new window.  You want the file that has "toplevel" in
the name and *not* 'rm' (which stands for 'repeat masked'). So for
example for the fungus aspergillus nidulans we would get this file:

    Aspergillus_nidulans.CADRE2.dna.toplevel.fa.gz

gunzip the file and it should be a fasta file of the complete genome.

Rename the file to be: NAME_genome.txt where "NAME" should be replaced
by something that identifies your name/assembly, e.g.mouse-mm9. Just
use alphanumeric, dashes, periods in NAME, do not use underscores. The
scripts below won't work unless you follow this naming convention
exactly. Note the suffix must be '.txt' not '.fa'.

Now go back to the big table of links on the FTP page and click the
"GTF" link for your species.

Download and gunzip the gtf file.

Now make sure all the scripts and the two data files you just
downloaded are in the same directory. Run the following:

    perl create_indexes_from_ensembl.pl NAME_genome.txt <gtf>

Where <gtf> is the name of the gtf file you downloaded, and NAME is the name you
have chosen above.

Note that you will need to supply the full path to the
create_indexes_from_ucsc.pl script, which is available in the 'bin'
directory of the RUM distribution. This is a master script that runs a
bunch of other scripts including bowtie-build. You will need a fair
amount of RAM to do this, 10Gb was sufficient for Human.

This will create a directory called $NAME (where NAME is the prefix of
the files you provided as command line arguments) and put all of the
important index files in there.  Move that directory to where your
other RUM indexes are stored.  For example, if you keep all of your
RUM indexes in ~/rum_indexes, and you have indexes for mouse (mm9) and
human (hg19), you would have the following directory structure:

    ~/
    ~/rum_indexes
    ~/rum_indexes/mm9/
    ~/rum_indexes/mm9/mm9_refseq_ucsc_gene_info.txt
    ...
    ~/rum_indexes/hg19/
    ~/rum_indexes/hg19/hg19_refseq_ucsc_gene_info.txt
    ...

To run RUM with one of these indexes, for example hg19, you would
provide the directory location with the B<--index-dir> or B<-i>
option:

    rum_runner -i ~/rum_indexes/hg19 ...

Not available on UCSC or Ensembl
--------------------------------

Your organism is not on either ucsc or ensembl but you have genome
sequence and optionally gene or transcript models.

If your organism is not available through UCSC, you must create by
hand the files described below, and then run some (supplied) parsing
scripts.Be careful to follow the specifications exactly.

1.  A fasta file of genome sequence with one entry per
    chromosome/contig/scaffold. The fasta def lines should give simple
    chromosome/contig/scaffold names.Stick to alphanumeric characters,
    underscores, periods, dashes.You might get away with other
    characters but definitely do not use colons, quotes or
    whitespace.Use the forward (plus) strand sequence, all bases
    should be upper case A, C, G, T or N.The first base of each entry
    will be considered be cooordinate number 1 of the
    chromosome/contig/scaffold. Call this file NAME_genome.txt, where
    "NAME" should be replaced by something that identifies your
    name/assembly, e.g.mouse-mm9. Just use alphanumeric, dashes,
    periods in NAME, do not use underscores. The scripts below won't
    work unless you follow this naming convention exactly. Note the
    suffix must be '.txt' not '.fa'

2.  A file (or files) of transcript models. Keep the name(s) of these
    files simple, like refseq.txt. A transcript model file has one row for
    each transcript, with each row havin five tab delimited colums:

    **name**: The name of the transcript.Keep it relatively simple,
    use just alphanumeric, underscores, dashes and periods.Names don't
    have to be unique, the parsing scripts will make them unique later
    by adding numbers to ones that are equal.

    **chrom** The name of the chromosome/contig/scaffold the
    transcript is on Names should match those in the genome fasta
    file.

    **strand** The strand, + or -.

    **exonStarts** A comma delimited list (with no whitespace) of exon
    start locations in zero based coordinates.The last character can
    be a comma, but not the first.

    **exonEnds** A comma delimited list (with no whitespace) of exon
    end locations in one based coordinates.The last character can be a
    comma, but not the first.

    Note 1: It is not a typo that we want zero-based coordinates for
    the starts and one-based coordinates for the ends, we are just
    being compliant with UCSC standards.

    Note 2: You can make multiple files of transcripts, the parsing
    scripts will take care of merging them into one consistent
    database of transcripts.If two files have the same transcript,
    even if they have different names, the scripts will merge them
    into one and merge the names.Basically, in your gene models files,
    different transcripts can have the same name and one transcript
    can have serveral different names, even in the same file.All you
    need to worry about is getting each file formatted exactly as
    described above.

3.  Make a file called "gene_info_files" with one line per gene
    annotation filename (even if you have only one). E.g.:

        refseq.txt
        ucscknown.txt

    All the scripts and the data files you just downloaded need to be
    in the same directory. Now run:

        > perl create_indexes_from_ucsc.pl NAME_genome.txt NAME_refseq_ucsc

* NAME is as defined above - make sure there are no underscores in
  NAME

Note that you will need to supply the full path to the
create_indexes_from_ucsc.pl script, which is available in the 'bin'
directory of the RUM distribution. This is a master script that runs a
bunch of other scripts including bowtie-build. You will need a fair
amount of RAM to do this, 10Gb was sufficient for Human.

This will create a directory called $NAME (where NAME is the prefix of
the files you provided as command line arguments) and put all of the
important index files in there.  Move that directory to where your
other RUM indexes are stored.  For example, if you keep all of your
RUM indexes in ~/rum_indexes, and you have indexes for mouse (mm9) and
human (hg19), you would have the following directory structure:

    ~/
    ~/rum_indexes
    ~/rum_indexes/mm9/
    ~/rum_indexes/mm9/mm9_refseq_ucsc_gene_info.txt
    ...
    ~/rum_indexes/hg19/
    ~/rum_indexes/hg19/hg19_refseq_ucsc_gene_info.txt
    ...

To run RUM with one of these indexes, for example hg19, you would
provide the directory location with the B<--index-dir> or B<-i>
option:

    rum_runner -i ~/rum_indexes/hg19 ...
