package RUM::Script::MergeBowtieAndBlat;

no warnings;

use RUM::Usage;
use RUM::Logging;
use RUM::Common qw(addJunctionsToSeq spansTotalLength);
use Getopt::Long;

our $log = RUM::Logging->get_logger();

$|=1;

sub main {

    GetOptions(
        "bowtie-unique-in=s"     => \(my $bowtie_unique_in),
        "blat-unique-in=s"       => \(my $blat_unique_in),
        "bowtie-non-unique-in=s" => \(my $bowtie_non_unique_in),
        "blat-non-unique-in=s"   => \(my $blat_non_unique_in),
        "unique-out=s"           => \(my $unique_out),
        "non-unique-out=s"       => \(my $non_unique_out),
        "single"                 => \(my $single),
        "paired"                 => \(my $paired),
        "max-pair-dist=s" => \(my $max_distance_between_paired_reads = 500000),
        "read-length"     => \(my $readlength = 0),
        "min-overlap=i"   => \(my $user_min_overlap),
        "help|h"    => sub { RUM::Usage->help },
        "verbose|v" => sub { $log->more_logging(1) },
        "quiet|q"   => sub { $log->less_logging(1) }
    );

    # Input files
    $bowtie_unique_in or RUM::Usage->bad(
        "Please provide unique bowtie mappers with --bowtie-unique-in");
    $blat_unique_in or RUM::Usage->bad(
        "Please provide unique blat mappers with --blat-unique-in");
    $bowtie_non_unique_in or RUM::Usage->bad(
        "Please provide non-unique bowtie mappers with --bowtie-non-unique-in");
    $blat_non_unique_in or RUM::Usage->bad(
        "Please provide non-unique blat mappers with --blat-non-unique-in");

    # Output files
    $unique_out or RUM::Usage->bad(
        "Please specify output file for unique mappers with --unique-out");
    $non_unique_out or RUM::Usage->bad(
        "Please specify output file for non-unique mappers with --non-unique-out");
    
    ($single xor $paired) or RUM::Usage->bad(
        "Please specify exactly one of --single or --paired");

    if (defined($user_min_overlap)) {
        if ($user_min_overlap < 5) {
            RUM::Usage->bad(
                "If you provide --min-overlap it must be an integer > 4");
        }
    }
    else {
        $user_min_overlap = 0;
    }


    # get readlength from bowtie unique/nu, if both empty then get max
    # in blat unique/nu

    open(INFILE, $bowtie_unique_in) 
        or die "Can't open $bowtie_unique_in for reading: $!";

    
    if ($readlength == 0) {
        $log->info("Trying to figure out read length");
        $cnt = 0;
        while ($line = <INFILE>) {
            $length = 0;
            if ($line =~ /seq.\d+a/ || $line =~ /seq.\d+b/) {
                chomp($line);
                @a = split(/\t/,$line);
                $span = $a[2];
                @SPANS = split(/, /, $span);
                $cnt++;
                for ($i=0; $i<@SPANS; $i++) {
                    @b = split(/-/,$SPANS[$i]);
                    $length = $length + $b[1] - $b[0] + 1;
                }
                if ($length > $readlength) {
                    $readlength = $length;
                    $cnt = 0;
                }
                if ($cnt > 50000) { # it checked 50,000 lines without finding anything larger than the last time
                    # readlength was changed, so it's most certainly found the max.
                    # Went through this to avoid the user having to input the readlength.
                    last;
                }
            }
        }
        close(INFILE);
        open(INFILE, $blat_unique_in) 
            or die "Can't open $blat_unique_in for reading: $!";
        $cnt = 0;
        while ($line = <INFILE>) {
            $length = 0;
            if ($line =~ /seq.\d+a/ || $line =~ /seq.\d+b/) {
                chomp($line);
                @a = split(/\t/,$line);
                $span = $a[2];
                @SPANS = split(/, /, $span);
                $cnt++;
                for ($i=0; $i<@SPANS; $i++) {
                    @b = split(/-/,$SPANS[$i]);
                    $length = $length + $b[1] - $b[0] + 1;
                }
                if ($length > $readlength) {
                    $readlength = $length;
                    $cnt = 0;
                }
                if ($cnt > 50000) {
                    last;
                }
            }
        }
        close(INFILE);
    
        open(INFILE, $bowtie_non_unique_in) 
            or die "Can't open $bowtie_non_unique_in for reading: $!";
        $cnt = 0;
        while ($line = <INFILE>) {
            $length = 0;
            if ($line =~ /seq.\d+a/ || $line =~ /seq.\d+b/) {
                chomp($line);
                @a = split(/\t/,$line);
                $span = $a[2];
                @SPANS = split(/, /, $span);
                $cnt++;
                for ($i=0; $i<@SPANS; $i++) {
                    @b = split(/-/,$SPANS[$i]);
                    $length = $length + $b[1] - $b[0] + 1;
                }
                if ($length > $readlength) {
                    $readlength = $length;
                    $cnt = 0;
                }
                if ($cnt > 50000) {
                    last;
                }
            }
        }
        close(INFILE);
        open(INFILE, $blat_non_unique_in) 
            or die "Can't open $blat_non_unique_in for reading: $!";
        $cnt = 0;
        while ($line = <INFILE>) {
            $length = 0;
            if ($line =~ /seq.\d+a/ || $line =~ /seq.\d+b/) {
                chomp($line);
                @a = split(/\t/,$line);
                $span = $a[2];
                @SPANS = split(/, /, $span);
                $cnt++;
                for ($i=0; $i<@SPANS; $i++) {
                    @b = split(/-/,$SPANS[$i]);
                    $length = $length + $b[1] - $b[0] + 1;
                }
                if ($length > $readlength) {
                    $readlength = $length;
                    $cnt = 0;
                }
                if ($cnt > 50000) {
                    last;
                }
            }
        }
        close(INFILE);
    }

    if ($readlength == 0) { # Couldn't determine the read length so going to fall back
        # on the strategy used for variable length reads.
        $readlength = "v";
    }
    if (!($readlength eq "v")) {
        if ($readlength < 80) {
            $min_overlap = 35;
        } else {
            $min_overlap = 45;
        }
        if ($min_overlap >= .8 * $readlength) {
            $min_overlap = int(.6 * $readlength);
        }
    }
    if ($user_min_overlap > 0) {
        $min_overlap = $user_min_overlap;
    }

    $f0 = $blat_non_unique_in;
    open(INFILE, $f0)
        or die "Can't open $f0 for reading: $!";

    $log->info("Reading blat non-unique mappers");
    while ($line = <INFILE>) {
        $line =~ /^seq.(\d+)/;
        $id = $1;
        if ($line =~ /seq.\d+a/) {
            $blat_ambiguous_mappers_a{$id}++;
        }
        if ($line =~ /seq.\d+b/) {
            $blat_ambiguous_mappers_b{$id}++;
        }
        if (!($line =~ /(seq.\d+a|seq.\d+b)/)) {
            $blat_ambiguous_mappers_a{$id}++;
            $blat_ambiguous_mappers_b{$id}++;
        }
    }
    close(INFILE);

    open(OUTFILE2, ">>$f0") 
        or die "Can't open $f0 for appending: $!";

    # The only things we're going to add to BlatNU.chunk are the reads that
    # are single direction only mappers in BowtieUnique that are also single
    # direction only mappers in BlatNU, but the two mappings disagree.
    # Also, do not write these to RUM_Unique.
    $f1 = $bowtie_non_unique_in;
    open(INFILE, $f1) 
        or die "Can't open $1 for reading";
    while ($line = <INFILE>) {
        if ($line =~ /^seq.(\d+)/) {
            $bowtie_ambiguous_mappers{$1}++;
        }
    }
    close(INFILE);
    $f2 = $bowtie_unique_in;
    open(INFILE1, $f2) 
        or die "Can't open $f2 for reading: $!";
    $f3 = $blat_unique_in;
    open(INFILE2, $f3) 
        or die "Can't open $f3 for reading: $!";
    $f4 = $unique_out;
    open(OUTFILE1, ">$f4") 
        or die "Can't open $f4 for writing: $!";

    $max_distance_between_paired_reads = 500000;
    $num_lines_at_once = 10000;
    $linecount = 0;
    $FLAG = 1;
    $FLAG2 = 1;
    $line_prev = <INFILE2>;
    chomp($line_prev);
    $last_id = 10**14;
    while ($FLAG == 1 || $FLAG2 == 1) {
        undef %hash1;
        undef %hash2;
        undef %allids;
        $linecount = 0;
        # get the bowtie output into hash1 for a bunch of ids
        until ($linecount == $num_lines_at_once) {
            $line=<INFILE1>;
            if (!($line =~ /\S/)) {
                $FLAG = 0;
                $linecount = $num_lines_at_once;
            } else {
                chomp($line);
                @a = split(/\t/,$line);
                $a[0] =~ /seq.(\d+)/;
                $id = $1;
                $last_id = $id;
                $allids{$id}++;
                if ($a[0] =~ /a$/ || $a[0] =~ /b$/) {
                    $hash1{$id}[0]++;
                    $hash1{$id}[$hash1{$id}[0]]=$line;
                } else {
                    $hash1{$id}[0]=-1;
                    $hash1{$id}[1]=$line;
                }
                if ($paired) {
                    # this makes sure we have read in both a and b reads, this approach might cause a problem
                    # if no, or very few, b reads mapped at all.
                    if ( (($linecount == ($num_lines_at_once - 1)) && !($a[0] =~ /a$/)) || ($linecount < ($num_lines_at_once - 1)) ) {
                        $linecount++;
                    }
                } else {
                    if ( ($linecount == ($num_lines_at_once - 1)) || ($linecount < ($num_lines_at_once - 1)) ) {
                        $linecount++;
                    }
                }
            }
        }
        $line = $line_prev;
        @a = split(/\t/,$line);
        $a[0] =~ /seq.(\d+)/;
        $prev_id = $id;
        $id = $1;
        if ($prev_id eq $id) {
            $FLAG3++;
            if ($FLAG3 > 1) {
                $FLAG2=0;
            }
        }
        # now get the blat output for this bunch of ids, that goes in hash2
        until ($id > $last_id || $FLAG3 > 1 || $id eq '') {
            $allids{$id}++;
            if ($a[0] =~ /a$/ || $a[0] =~ /b$/) {
                $hash2{$id}[0]++;
                $hash2{$id}[$hash2{$id}[0]]=$line;
            } else {
                $hash2{$id}[0]=-1;
                $hash2{$id}[1]=$line;
            }
            $line=<INFILE2>;
            chomp($line);
            if (!($line =~ /\S/)) {
                $FLAG2 = 0;
                $FLAG3 = 2;
            } else {
                @a = split(/\t/,$line);
                $a[0] =~ /seq.(\d+)/;
                $id = $1;
            }
        }
        if ($FLAG2 == 1) {
            $line_prev = $line;
        }
        if ($FLAG2 == 0) {
            $line_prev = "";
        }

        # now parse for this bunch of ids:

        foreach $id (sort {$a <=> $b} keys %allids) {
            if ($bowtie_ambiguous_mappers{$id}+0 > 0) {
                next;
            }
            if ($blat_ambiguous_mappers_a{$id}+0 > 0 && $blat_ambiguous_mappers_b{$id}+0 > 0) {
                next;
            }
            $hash1{$id}[0] = $hash1{$id}[0] + 0;
            $hash2{$id}[0] = $hash2{$id}[0] + 0;
            if (($blat_ambiguous_mappers_a{$id}+0 > 0) && ($hash1{$id}[0]+0 == 1) && ($hash1{$id}[1] =~ /seq.\d+b/)) {
                # ambiguous forward in in BlatNU, single reverse in BowtieUnique.  See if there is
                # a consistent pairing so we can keep the pair, otherwise this read is considered unmappable
                # (not to be confused with ambiguous)
                $line1 = $hash1{$id}[1];
                $str = $id . "a";
                $x = `grep $str $f0`;
                chomp($x);
                @a3 = split(/\n/,$x);
                $numjoined=0;
                for ($ii=0; $ii<@a3; $ii++) {
                    $line2 = $a3[$ii];
                    if ($line1 =~ /\-$/) { # check the strand
                        $joined = joinifpossible($line1, $line2); # this is not backwards, line1 is the reverse read
                    } else {
                        $joined = joinifpossible($line2, $line1);
                    }
                    if ($joined =~ /\S/) {
                        $numjoined++;
                        $joinedsave = $joined;
                    }
                }
                if ($numjoined == 1) { # if numjoined > 1 should probably intersect them to see if there's a 
                    # salvagable intersection
                    print OUTFILE1 "$joinedsave";
                }
                $remove_from_BlatNU{$id}++;
                next;
            }
            if (($blat_ambiguous_mappers_b{$id}+0 > 0) && ($hash1{$id}[0]+0 == 1) && ($hash1{$id}[1] =~ /seq.\d+a/)) {
                # ambiguous reverse in in BlatNU, single forward in BowtieUnique.  See if there is
                # a consistent pairing so we can keep the pair, otherwise this read is considered unmappable
                # (not to be confused with ambiguous)
                $line1 = $hash1{$id}[1];
                $str = $id . "b";
                $x = `grep $str $f0`;
                chomp($x);
                @a3 = split(/\n/,$x);
                $numjoined=0;
                for ($ii=0; $ii<@a3; $ii++) {
                    $line2 = $a3[$ii];
                    if ($line1 =~ /-$/) {
                        $joined = joinifpossible($line2, $line1);
                    } else {
                        $joined = joinifpossible($line1, $line2);
                    }
                    if ($joined =~ /\S/) {
                        $numjoined++;
                        $joinedsave = $joined;
                    }
                }
                if ($numjoined == 1) { # if numjoined > 1 should probably intersect them to see if there's a 
                    # salvagable intersection
                    print OUTFILE1 "$joinedsave";
                }
                $remove_from_BlatNU{$id}++;
                next;
            }

            # Kept for debugging
            #	print "hash1{$id}[0]=$hash1{$id}[0]\n";
            #	print "hash2{$id}[0]=$hash2{$id}[0]\n";

            # %hash1 is bowtie
            # %hash2 is blat
            # These can have values -1, 0, 1, 2
            # All combinations possible except (0,0), so 15 total:
            # case -1: both forward and reverse reads mapped, consistently, and overlapped so were joined
            # case  0: neither read mapped
            # case  1: only one of the forward or reverse mapped
            # case  2: both forward and reverse reads mapped, consistently, but did not overlap so were not joined

            # THREE CASES:
            if ($hash1{$id}[0] == 0) {
                if ($hash2{$id}[0] == -1) {
                    print OUTFILE1 "$hash2{$id}[1]\n";
                } else {
                    for ($i=0; $i<$hash2{$id}[0]; $i++) { # this is in BlatUnique and not in BowtieUnique
                        # don't need to check if this is in BlatNU since
                        # it can't be in both BlatNU and BlatUnique
                        print OUTFILE1 "$hash2{$id}[$i+1]\n";
                    }
                }
            }
            # THREE CASES:
            if ($hash2{$id}[0] == 0) {
                if ($hash1{$id}[0] == -1) {
                    print OUTFILE1 "$hash1{$id}[1]\n";
                }
                if ($hash1{$id}[0] == 2) {
                    for ($i=0; $i<$hash1{$id}[0]; $i++) {
                        print OUTFILE1 "$hash1{$id}[$i+1]\n";
                    }
                }
                if ($hash1{$id}[0] == 1) { # this is a one-direction only mapper in BowtieUnique and
                    # nothing in BlatUnique, so much check it's not in BlatNU
                    if ($blat_ambiguous_mappers_a{$id}+0 == 0 && $hash1{$id}[1] =~ /seq.\d+a/) {
                        print OUTFILE1 "$hash1{$id}[1]\n";
                    }
                    if ($blat_ambiguous_mappers_b{$id}+0 == 0 && $hash1{$id}[1] =~ /seq.\d+b/) {
                        print OUTFILE1 "$hash1{$id}[1]\n";
                    }
                }
            }
            # ONE CASE:
            if ($hash1{$id}[0] == -1 && $hash2{$id}[0] == -1) { # Preference the bowtie mapping.
                print OUTFILE1 "$hash1{$id}[1]\n"; # This case should actually not happen because we
                # should only send to blat those things which didn't
                # have consistent bowtie maps.
            }
            # ONE CASE:
            if ($hash1{$id}[0] == 1 && $hash2{$id}[0] == 1) {
                if ((($hash1{$id}[1] =~ /seq.\d+a/) && ($hash2{$id}[1] =~ /seq.\d+a/)) || (($hash1{$id}[1] =~ /seq.\d+b/) && ($hash2{$id}[1] =~ /seq.\d+b/))) {
                    # If single-end then this is the only case where $hash1{$id}[0] != 0 and $hash2{$id}[0] != 0
                    undef @spans;
                    @a1 = split(/\t/,$hash1{$id}[1]);
                    @a2 = split(/\t/,$hash2{$id}[1]);
                    $spans[0] = $a1[2];
                    $spans[1] = $a2[2];
                    $l1 = spansTotalLength($spans[0]);
                    $l2 = spansTotalLength($spans[1]);
                    $F=0;
                    if ($l1 > $l2+3) {
                        print OUTFILE1 "$hash1{$id}[1]\n"; # preference bowtie
                        $F=1;
                    }
                    if ($l2 > $l1+3) {
                        print OUTFILE1 "$hash2{$id}[1]\n"; # preference blat
                        $F=1;
                    }
                    $str = intersect(\@spans, $a1[3]);
                    $str =~ /^(\d+)/;
                    $length_overlap = $1;
                    if ($F == 0) {

                        if ($readlength eq "v") {
                            $readlength_temp = length($a1[3]);
                            if (length($a2[3]) < $readlength_temp) {
                                $readlength_temp = length($a2[3]);
                            }
                            if ($readlength_temp < 80) {
                                $min_overlap = 35;
                            } else {
                                $min_overlap = 45;
                            }
                            if ($min_overlap >= .8 * $readlength_temp) {
                                $min_overlap = int(.6 * $readlength_temp);
                            }
                        }
                        if ($user_min_overlap > 0) {
                            $min_overlap = $user_min_overlap;
                        }

                        if (($length_overlap > $min_overlap) && ($a1[1] eq $a2[1])) {
                            print OUTFILE1 "$hash1{$id}[1]\n"; # preference bowtie (so no worries about insertions)
                        } else {
                            # AMBIGUOUS, OUTPUT TO NU FILE
                            if (($hash1{$id}[1] =~ /\S/) && ($hash2{$id}[1] =~ /\S/)) {
                                print OUTFILE2 "$hash1{$id}[1]\n";
                                print OUTFILE2 "$hash2{$id}[1]\n";
                            }
                        }
                    }
                }
                if ((($hash1{$id}[1] =~ /seq.\d+a/) && ($hash2{$id}[1] =~ /seq.\d+b/)) || (($hash1{$id}[1] =~ /seq.\d+b/) && ($hash2{$id}[1] =~ /seq.\d+a/))) {
                    # This is the tricky case where there's a unique forward bowtie mapper and a unique reverse
                    # blat mapper, or convsersely.  Must check for consistency.  This cannot be in BlatNU so don't
                    # have to worry about that here.
                    if ($hash1{$id}[1] =~ /seq.\d+a/) {
                        $atype = "a";
                    } else {
                        $atype = "b";
                    }
                    @a = split(/\t/,$hash1{$id}[1]);
                    $aspans = $a[2];
                    $a[2] =~ /^(\d+)[^\d]/;
                    $astart = $1;
                    $a[2] =~ /[^\d](\d+)$/;
                    $aend = $1;
                    $chra = $a[1];
                    $aseq = $a[3];
                    $Astrand = $a[4];
                    $seqnum = $a[0];
                    $seqnum =~ s/a$//;
                    $seqnum =~ s/b$//;
                    @a = split(/\t/,$hash2{$id}[1]);
                    $bspans = $a[2];
                    $a[2] =~ /^(\d+)[^\d]/;
                    $bstart = $1;
                    $a[2] =~ /[^\d](\d+)$/;
                    $bend = $1;
                    $chrb = $a[1];
                    $bseq = $a[3];
                    $Bstrand = $a[4];
                    if ( (($atype eq "a") && ($Astrand eq "+")) || ((($atype eq "b") && ($Astrand eq "-"))) ) {
                        if (($Astrand eq $Bstrand) && ($chra eq $chrb) && ($aend < $bstart-1) && ($bstart - $aend < $max_distance_between_paired_reads)) {
                            if ($hash1{$id}[1] =~ /a\t/) {
                                print OUTFILE1 "$hash1{$id}[1]\n$hash2{$id}[1]\n";
                            } else {
                                print OUTFILE1 "$hash2{$id}[1]\n$hash1{$id}[1]\n";
                            }
                        }
                    }
                    if ( (($atype eq "a") && ($Astrand eq "-")) || ((($atype eq "b") && ($Astrand eq "+"))) ) {
                        if (($Astrand eq $Bstrand) && ($chra eq $chrb) && ($bend < $astart-1) && ($astart - $bend < $max_distance_between_paired_reads)) {
                            if ($hash1{$id}[1] =~ /a\t/) {
                                print OUTFILE1 "$hash1{$id}[1]\n$hash2{$id}[1]\n";
                            } else {
                                print OUTFILE1 "$hash2{$id}[1]\n$hash1{$id}[1]\n";
                            }
                        }
                    }
                    # if they overlap, can't merge properly if there's an insertion, so chop it out,
                    # save it and put it back in before printing the next two if's do the chopping...
                    $aseq=~ s/://g;
                    if ($aseq =~ /\+/) {
                        $aseq =~ /(.*)(\+.*\+)(.*)/; # THIS IS ONLY GOING TO WORK IF THERE IS ONE INSERTION
                        # as is guaranteed, seach for "comment.1" in parse_blat_out.pl
                        # This limitation should probably be fixed at some point...
                        $astem = $1;
                        $a_insertion = $2;
                        $apost = $3;
                        $aseq =~ s/\+.*\+//;
                        if (!($a_insertion =~ /\S/)) {
                            print STDERR "ERROR: in script merge_Bowtie_and_Blat.pl: Something is wrong here, possible bug: code_id 0001\n";
                        }
                    }
                    $bseq=~ s/://g;
                    if ($bseq =~ /\+/) {
                        $bseq =~ /(.*)(\+.*\+)(.*)/; # SAME COMMENT AS ABOVE
                        $bstem = $1;
                        $b_insertion = $2;
                        $bpost = $3;
                        $bseq =~ s/\+.*\+//;
                        if (!($b_insertion =~ /\S/)) {
                            print STDERR "ERROR: in script merge_Bowtie_and_Blat.pl: Something is wrong here, possible bug: code_id 0002\n";
                        }
                    }
                    $dflag = 0;
                    if ( (($atype eq "a") && ($Astrand eq "+")) || ((($atype eq "b") && ($Astrand eq "-"))) ) {
                        if (($Astrand eq $Bstrand) && ($chra eq $chrb) && ($aend >= $bstart-1) && ($astart <= $bstart) && ($aend <= $bend)) {
                            # they overlap
                            $spans_merged = merge($aspans,$bspans);
                            $merged_length = spansTotalLength($spans_merged);
                            $aseq =~ s/://g;
                            $seq_merged = $aseq;
                            @s = split(//,$aseq);
                            $bsize = $merged_length - @s;
                            $bseq =~ s/://g;
                            @s = split(//,$bseq);
                            $add = "";
                            for ($i=@s-1; $i>=@s-$bsize; $i--) {
                                $add = $s[$i] . $add;
                            }
                            $seq_merged = $seq_merged . $add;
                            if ($a_insertion =~ /\S/) { # put back the insertions, if any...
                                $seq_merged =~ s/^$astem/$astem$a_insertion/;
                            }
                            if ($b_insertion =~ /\S/) {
                                $str_temp = $b_insertion;
                                $str_temp =~ s/\+/\\+/g;
                                if (!($seq_merged =~ /$str_temp$bpost$/)) {
                                    $seq_merged =~ s/$bpost$/$b_insertion$bpost/;
                                }
                            }
                            $seq_j = addJunctionsToSeq($seq_merged, $spans_merged);
                            print OUTFILE1 "$seqnum\t$chra\t$spans_merged\t$seq_j\t$Astrand\n";
                            $dflag = 1;
                        }
                    }
                    if ( (($atype eq "a") && ($Astrand eq "-")) || ((($atype eq "b") && ($Astrand eq "+"))) ) {
                        if (($Astrand eq $Bstrand) && ($chra eq $chrb) && ($bend >= $astart-1) && ($bstart <= $astart) && ($bend <= $aend) && ($dflag == 0)) {
                            # they overlap
                            $spans_merged = merge($bspans,$aspans);
                            $merged_length = spansTotalLength($spans_merged);
                            $bseq =~ s/://g;
                            $seq_merged = $bseq;
                            @s = split(//,$bseq);
                            $asize = $merged_length - @s;
                            $aseq =~ s/://g;
                            @s = split(//,$aseq);
                            $add = "";
                            for ($i=@s-1; $i>=@s-$asize; $i--) {
                                $add = $s[$i] . $add;
                            }
                            $seq_merged = $seq_merged . $add;
                            if ($a_insertion =~ /\S/) { # put back the insertions, if any...
                                $seq_merged =~ s/$apost$/$a_insertion$apost/;
                            }
                            if ($b_insertion =~ /\S/) {
                                $str_temp = $b_insertion;
                                $str_temp =~ s/\+/\\+/g;
                                if (!($seq_merged =~ /^$bstem$str_temp/)) {
                                    $seq_merged =~ s/^$bstem/$bstem$b_insertion/;
                                }
                            }
                            $seq_j = addJunctionsToSeq($seq_merged, $spans_merged);
                            print OUTFILE1 "$seqnum\t$chra\t$spans_merged\t$seq_j\t$Astrand\n";
                        }
                    }
                }
            }
            # ONE CASE
            if ($hash1{$id}[0] == 2 && $hash2{$id}[0] == 2) { # preference bowtie
                print OUTFILE1 "$hash1{$id}[1]\n";
                print OUTFILE1 "$hash1{$id}[2]\n";
            }	
            # NINE CASES DONE
            # ONE CASE
            if ($hash1{$id}[0] == -1 && $hash2{$id}[0] == 2) { # preference bowtie
                print OUTFILE1 "$hash1{$id}[1]\n";
            }
            # ONE CASE
            if ($hash1{$id}[0] == 2 && $hash2{$id}[0] == -1) { # preference bowtie
                print OUTFILE1 "$hash1{$id}[1]\n";
                print OUTFILE1 "$hash1{$id}[2]\n";
            }
            # ELEVEN CASES DONE
            if ($hash1{$id}[0] == 1 && $hash2{$id}[0] == 2) {
                print OUTFILE1 "$hash2{$id}[1]\n";
                print OUTFILE1 "$hash2{$id}[2]\n";
            }	
            if ($hash1{$id}[0] == 2 && $hash2{$id}[0] == 1) {
                print OUTFILE1 "$hash1{$id}[1]\n";
                print OUTFILE1 "$hash1{$id}[2]\n";
            }	
            if ($hash1{$id}[0] == -1 && $hash2{$id}[0] == 1) {
                print OUTFILE1 "$hash1{$id}[1]\n";
            }
            if ($hash1{$id}[0] == 1 && $hash2{$id}[0] == -1) {
                print OUTFILE1 "$hash2{$id}[1]\n";
            }
            # ALL FIFTEEN CASES DONE
        }
    }
    close(INFILE1);
    close(INFILE2);
    close(OUTFILE1);
    close(OUTFILE2);

    # now need to remove the stuff in %remove_from_BlatNU from BlatNU
    $filename = $non_unique_out;
    open(INFILE, $f0)
        or die "Can't open $f0 for reading: $!";
    open(OUTFILE, ">$filename") 
        or die "Can't open $filename for writing: $!";
    while ($line = <INFILE>) {
        $line =~ /seq.(\d+)/;
        if ($remove_from_BlatNU{$1}+0==0) {
            print OUTFILE $line;
        }
    }
    close(INFILE);
    open(INFILE, $f1) or die "\nError: in script merge_Bowtie_and_Blat.pl: unable to open file '$f1' for reading\n\n";
    # now append BowtieNU to get the full NU file
    while ($line = <INFILE>) {
        print OUTFILE $line;
    }
    close(INFILE);
    close(OUTFILE);

}

sub joinifpossible () {
    ($LINE1, $LINE2) = @_;
    @a_p = split(/\t/,$LINE1);
    $aspans_p = $a_p[2];
    $a_p[2] =~ /^(\d+)[^\d]/;
    $astart_p = $1;
    $a_p[2] =~ /[^\d](\d+)$/;
    $aend_p = $1;
    $chra_p = $a_p[1];
    $aseq_p = $a_p[3];
    $astrand_p = $a_p[4];
    $seqnum_p = $a_p[0];
    $seqnum_p =~ s/a$//;
    $seqnum_p =~ s/b$//;
    @a_p = split(/\t/,$LINE2);
    $bspans_p = $a_p[2];
    $a_p[2] =~ /^(\d+)[^\d]/;
    $bstart_p = $1;
    $a_p[2] =~ /[^\d](\d+)$/;
    $bend_p = $1;
    $chrb_p = $a_p[1];
    $bseq_p = $a_p[3];
    $bstrand_p = $a_p[4];
    $returnstring = "";
    if ($astrand_p ne $bstrand_p) {
	return "";
    }
    if (($chra_p eq $chrb_p) && ($astrand_p eq $bstrand_p) && ($aend_p < $bstart_p-1) && ($bstart_p - $aend_p < $max_distance_between_paired_reads)) {
	if ($LINE1 =~ /a\t/) {
	    $returnstring = $returnstring . "$LINE1\n$LINE2\n";
	} else {
	    $returnstring = $returnstring . "$LINE2\n$LINE1\n";
	}
    }
    # if they overlap, can't merge properly if there's an insertion, so chop it out,
    # save it and put it back in before printing the next two if's do the chopping...
    $aseq_p =~ s/://g;
    if ($aseq_p =~ /\+/) {
	$aseq_p =~ /(.*)(\+.*\+)(.*)/; # Only going to work if there is at most one insertion, search on "comment.1"
	$astem = $1;
	$a_insertion = $2;
	$apost = $3;
	$aseq_p =~ s/\+.*\+//;
	if (!($a_insertion =~ /\S/)) {
	    $returnstring = $returnstring . "Something is wrong, here 1.07\n";
	}
    }
    $bseq_p =~ s/://g;
    if ($bseq_p =~ /\+/) {
	$bseq_p =~ /(.*)(\+.*\+)(.*)/; # Only going to work if there is at most one insertion, search on "comment.1"
	$bstem = $1;
	$b_insertion = $2;
	$bpost = $3;
	$bseq_p =~ s/\+.*\+//;
	if (!($b_insertion =~ /\S/)) {
	    $returnstring = $returnstring . "Something is wrong, here 1.21\n";
	}
    }
    $dflag = 0;
    if (($chra_p eq $chrb_p) && ($aend_p >= $bstart_p-1) && ($astart_p <= $bstart_p) && ($aend_p <= $bend_p) && ($astrand_p eq $bstrand_p)) {
	# they overlap
	$spans_merged_p = merge($aspans_p,$bspans_p);
	$merged_length = spansTotalLength($spans_merged_p);
	$aseq_p =~ s/://g;
	$seq_merged_p = $aseq_p;
	@s = split(//,$aseq_p);
	$bsize = $merged_length - @s;
	$bseq_p =~ s/://g;
	@s = split(//,$bseq_p);
	$add = "";
	for ($i=@s-1; $i>=@s-$bsize; $i--) {
	    $add = $s[$i] . $add;
	}
	$seq_merged_p = $seq_merged_p . $add;
	if ($a_insertion =~ /\S/) { # put back the insertions, if any...
	    $seq_merged_p =~ s/^$astem/$astem$a_insertion/;
	}
	if ($b_insertion =~ /\S/) {
	    $str_temp = $b_insertion;
	    $str_temp =~ s/\+/\\+/g;
	    if (!($seq_merged_p =~ /$str_temp$bpost$/)) {
		$seq_merged_p =~ s/$bpost$/$b_insertion$bpost/;
	    }
	}
	$seq_p = addJunctionsToSeq($seq_merged_p, $spans_merged_p);
	$returnstring = $returnstring . "$seqnum_p\t$chra_p\t$spans_merged_p\t$seq_p\t$astrand_p\n";
	$dflag = 1;
    }

    return $returnstring;
}

sub merge () {
    ($aspans2, $bspans2) = @_;
    undef @astarts2;
    undef @aends2;
    undef @bstarts2;
    undef @bends2;
    @a = split(/, /, $aspans2);
    for ($i=0; $i<@a; $i++) {
	@b = split(/-/,$a[$i]);
	$astarts2[$i] = $b[0];
	$aends2[$i] = $b[1];
    }
    @a = split(/, /, $bspans2);
    for ($i=0; $i<@a; $i++) {
	@b = split(/-/,$a[$i]);
	$bstarts2[$i] = $b[0];
	$bends2[$i] = $b[1];
    }
    if ($aends2[@aends2-1] + 1 < $bstarts2[0]) {
	$merged_spans = $aspans2 . ", " . $bspans2;
    }
    if ($aends2[@aends2-1] + 1 == $bstarts2[0]) {
	$aspans2 =~ s/-\d+$//;
	$bspans2 =~ s/^\d+-//;
	$merged_spans = $aspans2 . "-" . $bspans2;
    }
    if ($aends2[@aends2-1] + 1 > $bstarts2[0]) {
	$merged_spans = $aspans2;
	for ($i=0; $i<@bstarts2; $i++) {
	    if ($aends2[@aends2-1] >= $bstarts2[$i] && ($aends2[@aends2-1] <= $bstarts2[$i+1] || $i == @bstarts2-1)) {
		$merged_spans =~ s/-\d+$//;
		$merged_spans = $merged_spans . "-" . $bends2[$i];
		for ($j=$i+1; $j<@bstarts2; $j++) {
		    $merged_spans = $merged_spans . ", $bstarts2[$j]-$bends2[$j]";
		}
	    }
	}
    }
    return $merged_spans;
}

sub intersect () {
    ($spans_ref, $seq) = @_;
    @spans = @{$spans_ref};
    $num_i = @spans;
    undef %chash;
    for ($s_i=0; $s_i<$num_i; $s_i++) {
	@a_i = split(/, /,$spans[$s_i]);
	for ($i_i=0;$i_i<@a_i;$i_i++) {
	    @b_i = split(/-/,$a_i[$i_i]);
	    for ($j_i=$b_i[0];$j_i<=$b_i[1];$j_i++) {
		$chash{$j_i}++;
	    }
	}
    }
    $spanlength = 0;
    $flag_i = 0;
    $maxspanlength = 0;
    $maxspan_start = 0;
    $maxspan_end = 0;
    $prevkey = 0;
    for $key_i (sort {$a <=> $b} keys %chash) {
	if ($chash{$key_i} == $num_i) {
	    if ($flag_i == 0) {
		$flag_i = 1;
		$span_start = $key_i;
	    }
	    $spanlength++;
	} else {
	    if ($flag_i == 1) {
		$flag_i = 0;
		if ($spanlength > $maxspanlength) {
		    $maxspanlength = $spanlength;
		    $maxspan_start = $span_start;
		    $maxspan_end = $prevkey;
		}
		$spanlength = 0;
	    }
	}
	$prevkey = $key_i;
    }
    if ($flag_i == 1) {
	if ($spanlength > $maxspanlength) {
	    $maxspanlength = $spanlength;
	    $maxspan_start = $span_start;
	    $maxspan_end = $prevkey;
	}
    }
    if ($maxspanlength > 0) {
	@a_i = split(/, /,$spans[0]);
	@b_i = split(/-/,$a_i[0]);
	$i_i=0;
	until ($b_i[1] >= $maxspan_start) {
	    $i_i++;
	    @b_i = split(/-/,$a_i[$i_i]);
	}
	$prefix_size = $maxspan_start - $b_i[0]; # the size of the part removed from spans[0]
	for ($j_i=0; $j_i<$i_i; $j_i++) {
	    @b_i = split(/-/,$a_i[$j_i]);
	    $prefix_size = $prefix_size + $b_i[1] - $b_i[0] + 1;
	}
	@s_i = split(//,$seq);
	$newseq = "";
	for ($i_i=$prefix_size; $i_i<$prefix_size + $maxspanlength; $i_i++) {
	    $newseq = $newseq . $s_i[$i_i];
	}
	$flag_i = 0;
	$i_i=0;
	@b_i = split(/-/,$a_i[0]);
	until ($b_i[1] >= $maxspan_start) {
	    $i_i++;
	    @b_i = split(/-/,$a_i[$i_i]);
	}
	$newspans = $maxspan_start;
	until ($b_i[1] >= $maxspan_end) {
	    $newspans = $newspans . "-$b_i[1]";
	    $i_i++;
	    @b_i = split(/-/,$a_i[$i_i]);
	    $newspans = $newspans . ", $b_i[0]";
	}
	$newspans = $newspans . "-$maxspan_end";
	$off = "";
	for ($i_i=0; $i_i<$prefix_size; $i_i++) {
	    $off = $off . " ";
	}
	return "$maxspanlength\t$newspans\t$newseq";
    } else {
	return "0";
    }
}


