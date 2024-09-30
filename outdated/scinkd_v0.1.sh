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

#compare and contrast HAPs
bbduk.sh -Xmx300g threads=4 in=$1\.k28.counts.dumps.fa.gz out=$1\_HAP1-only_28mers.fa.gz ref=$2\.k28.counts.dumps.fa.gz k=28 hdist=0 
bbduk.sh -Xmx300g threads=4 in=$2\.k28.counts.dumps.fa.gz out=$2\_HAP2-only_28mers.fa.gz ref=$1\.k28.counts.dumps.fa.gz k=28 hdist=0 
