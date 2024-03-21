#!bin/bash

#to run:
#bash <this_file.sh> hap1.fa[.gz] hap2.fa[.gz] <num. threads> <genome size in Mb>
#all arguments are positional
#requires jellyfish, pigz, and bbduk/bbmap

for VARIABLE in $1 $2
do
jellyfish count -m 28 -s $4\M -t $3 <(pigz -dc $VARIABLE\.gz) -o $VARIABLE\.counts.jf
jellyfish dump $VARIABLE\.counts.jf | pigz -c --best > $VARIABLE\.k28.counts.dumps.fa.gz
rm $VARIABLE\.counts.jf
done

#HAP1
#jellyfish count -m 28 -s 2000M -t $3 <(pigz -dc $1\.gz) -o $1\.counts.jf
#jellyfish dump $1\.counts.jf | pigz -c --best > $1\.k28.counts.dumps.fa.gz
#rm $1\.counts.jf
#
##HAP2
#jellyfish count -m 28 -s 2000M -t $3 <(pigz -dc $2\.gz) -o $2\.counts.jf
#jellyfish dump $2\.counts.jf | pigz -c --best > $2\.k28.counts.dumps.fa.gz
#rm $2\.counts.jf

#compare and contrast HAPs
bbduk.sh -Xmx300g threads=4 in=$1\.k28.counts.dumps.fa.gz out=$1\_HAP1-only_28mers.fa.gz ref=$2\.k28.counts.dumps.fa.gz k=28 hdist=0 
bbduk.sh -Xmx300g threads=4 in=$2\.k28.counts.dumps.fa.gz out=$2\_HAP2-only_28mers.fa.gz ref=$1\.k28.counts.dumps.fa.gz k=28 hdist=0 
