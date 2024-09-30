#!bin/bash

time meryl count k=28 memory=16 threads=12 output $1\.meryl $1
time meryl count k=28 memory=16 threads=12 output $2\.meryl $2

time meryl difference $1\.meryl $2\.meryl output hap1-minus-hap2.meryl
time meryl difference $2\.meryl $1\.meryl output hap2-minus-hap1.meryl

time meryl-lookup -sequence $1 -mers hap1-minus-hap2.meryl/ -bed -output hap1-minus-hap2.bed
time meryl-lookup -sequence $2 -mers hap2-minus-hap1.meryl/ -bed -output hap2-minus-hap1.bed

cut -f1 hap1-minus-hap2.bed | uniq > hap1-minus-hap2.txt
cat hap1-minus-hap2.txt | while read line
do
grep "$line" hap1-minus-hap2.bed | wc -l >> hap1-minus-hap2.out 
done
paste hap1-minus-hap2.txt  hap1-minus-hap2.out 

cut -f1 hap2-minus-hap1.bed | uniq > hap2-minus-hap1.txt
cat hap2-minus-hap1.txt | while read line
do
grep "$line" hap2-minus-hap1.bed | wc -l >> hap2-minus-hap1.out 
done
paste hap2-minus-hap1.txt  hap2-minus-hap1.out 

