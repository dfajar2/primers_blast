#!/bin/bash
echo $_ > command_line
set -eo pipefail
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:${PATH}
export PATH=/media/software/samtools/1.9/bin:${PATH}
export PATH=/media/software/bedtools/2.27.1/bin:${PATH}
export PATH=/media/software/bedops/2.4.35/bin:${PATH}
export PATH=/media/data/diego/scripts:${PATH}
export PATH=/usr/games:${PATH}

echo Running pipeline; echo ==================
start=`date +%s`
echo $start

usage="

A short script to extract the first n bases from mapped sequenced reads and 
blast them against the primers db.

USAGE:
    $ /path/to/script.sh OPTIONS
        Required:
        [ -a Full path to alignments directory ]
	 or 
	[ -r Full path to Raw reads  ]
	
	[ -d --NOT FUNCTIONAL YET!!!-- primers blast-db name  ]
	[ -f primers sequence (fasta format)  ]
        [ -o output directory  ]
	
	Optional:
	[ -n number of bases (>=15) to extract from reads. Default: 18bases  ]
	[ -u To check only R1. Default check both, R1 and R2. ]

        
"
alignm=0
raw=0 
db=0
fas=0
n=18
SE=0
while getopts "a:r:d:f:n:o:u" options; do
        case "${options}" in
                a)
                        a=${OPTARG} 
			alignm=1 ;;
                d)
                        d=${OPTARG}
		       	db=1 ;;
                r)
                        r=${OPTARG}
		       	raw=1 ;;
                f)
                        f=${OPTARG} 
			fas=1 ;;
		n)
			n=${OPTARG} ;;
		o)
			o=${OPTARG} ;;
		u)
			SE=1 ;;
                *)
                        echo ${usage}
                        exit 1 ;;
        esac
done


echo "Log file: " | tee ${o}_primers_blast.log
echo Script used: $(cat command_line) | tee ${o}_primers_blast.log
rm command_line
echo $start | tee -a ${o}_primers_blast.log


shift $((OPTIND-1))

#Input checks
if [ ${alignm} -eq 0 ] && [ ${raw} -eq 0 ] ;then
	echo ; echo "ERROR - Missing arguments. No alignments nor Raw reads folder." | tee -a ${o}_primers_blast.log ; echo "$usage" | tee -a ${o}_primers_blast.log; exit 1
elif [ ${fas} -eq 0 ] && [ ${db} -eq 0 ];then
	echo ; echo "ERROR - Missing arguments. No fasta primers or blast DB." | tee -a ${o}_primers_blast.log ; echo "$usage" | tee -a ${o}_primers_blast.log; exit 1
elif [ ${fas} -eq 1 ] && [ ${alignm} -eq 1 ]; then
	if [ -z "${f}" ] || [ -z "${a}" ] || [ -z "${o}" ] ; then
		echo ; echo "ERROR - Missing arguments. -a -f -o " | tee -a ${o}_primers_blast.log ; echo "$usage" | tee -a ${o}_primers_blast.log; exit 1
	fi
elif [ ${db} -eq 1 ] && [ ${alignm} -eq 1 ]; then
	if [ -z "${d}" ] || [ -z "${a}" ] || [ -z "${o}" ] ; then
		echo ; echo "ERROR - Missing arguments. -a -d -o " | tee -a ${o}_primers_blast.log ; echo "$usage" | tee -a ${o}_primers_blast.log; exit 1
	fi
elif [ ${fas} -eq 1 ] && [ ${raw} -eq 1 ]; then
	if [ -z "${f}" ] || [ -z "${r}" ] || [ -z "${o}" ] ; then
		echo ; echo "ERROR - Missing arguments. -r -f -o " | tee -a ${o}_primers_blast.log ; echo "$usage" | tee -a ${o}_primers_blast.log; exit 1
	fi
elif [ ${db} -eq 1 ] && [ ${raw} -eq 1 ]; then
	if [ -z "${d}" ] || [ -z "${f}" ] || [ -z "${o}" ] ; then
		echo ; echo "ERROR - Missing arguments. -r -d -o " | tee -a ${o}_primers_blast.log ; echo "$usage" | tee -a ${o}_primers_blast.log; exit 1
	fi
fi

#Check paths
#if [ ! -d ${a} ] || [ ! -f ${d}*nhr ] || [ ! -f ${f} ] ;
if [ ${alignm} -eq 1 ]; then
	if [ ! -d ${a} ] || [ ! -f ${f} ] ;then
		echo ----- | tee -a ${o}_primers_blast.log; echo ERROR !!! File or Alignments Directory do not exist. Check files and paths. | tee -a ${o}_primers_blast.log ; exit 1
	fi
elif [ ${raw} -eq 1 ]; then
	if [ ! -d ${r} ] || [ ! -f ${f} ] ;then
                echo ----- | tee -a ${o}_primers_blast.log; echo ERROR !!! File or Raw Reads Directory do not exist. Check files and paths. | tee -a ${o}_primers_blast.log ; exit 1
        fi
fi

#Check n value
if [ ${n} -lt 15 ]; then 
	echo Invalid n value!!  | tee -a ${o}_primers_blast.log; 
	echo ${usage}  | tee -a ${o}_primers_blast.log; exit 1
fi


if [ $db -eq 1 ] ; then 
	echo Blast database : ${d} | tee -a ${o}_primers_blast.log
elif [ $fas -eq 1  ]; then
	echo Primers file :  ${f} | tee -a ${o}_primers_blast.log
fi

# if SE or PE
if [ $SE -eq 0 ]; then
	u="R"
elif [ $SE -eq 1 ]; then
	u="R1"
fi

echo Output directory: ${o} | tee -a ${o}_primers_blast.log
echo ============ | tee -a ${o}_primers_blast.log

if [ ${alignm} -eq 1 ]; then
	echo
	echo Alignments directory : ${a} | tee -a ${o}_primers_blast.log
	echo Alignment files
	ls ${a}/*bam
elif [ ${raw} -eq 1 ]; then
       echo
       echo Raw reads directory : ${r} | tee -a ${o}_primers_blast.log
       echo Read files 
       ls ${r}/*${u}*gz
fi


#Safe stop
echo --------------- | tee -a ${o}_primers_blast.log
echo Check files and paths | tee -a ${o}_primers_blast.log
echo Press Y to continue, any other key to exit. | tee -a ${o}_primers_blast.log
echo --------------- | tee -a ${o}_primers_blast.log
read input

if [ "$input" != "Y" ] && [ "$input" != "y" ]; 
then
	echo Exiting...  | tee -a ${o}_primers_blast.log; 
	echo | tee -a ${o}_primers_blast.log
	exit 0
fi

if [ -d ${o} ]
then
echo ; echo --------------- | tee -a ${o}_primers_blast.log; echo WARNING | tee -a ${o}_primers_blast.log; echo | tee -a ${o}_primers_blast.log; echo ${o} folder already exist!! | tee -a ${o}_primers_blast.log
echo Do you want to delete the ${o} folder and run the analysis again? \<Type Y to continue\> | tee -a ${o}_primers_blast.log
read input2
if [ "$input2" != "Y" ] && [ "$input2" != "y" ];
then
	echo Exiting... | tee -a ${o}_primers_blast.log
	exit 1 | tee -a ${o}_primers_blast.log
else
	#DEGUG comment echo Uncomment line below to remove Directory
	#
	rm -r ${o}
fi
fi



mkdir ${o}
cd ${o}
mv ../${o}_primers_blast.log .

if [ $fas -eq 1 ]; then 
	echo Copying primers file | tee -a ${o}_primers_blast.log
	cp ../${f} . 
	#ln -s ${f} .
	echo Creating blast DB | tee -a ${o}_primers_blast.log
	makeblastdb -in ${f} -dbtype nucl
	d=${f}
fi


function alignments(){
echo Linking alignments | tee -a ${o}_primers_blast.log

for w in `ls ${a}/*.bam` ; do ln -s $w . ; done
 
echo | tee -a ${o}_primers_blast.log
echo Extracting ${n} bases from mapped reads | tee -a ${o}_primers_blast.log
for f in `ls *bam | awk -F. '{print $1}'`; do echo $f; \
	samtools bam2fq -F4 ${f}.bam | \
	awk '{if ($1~/^@M/) print "START"$0 ; else print $0}' | \
	tr '\n' '\t' | \
	sed 's/START/\n/g' | \
	grep -v ^$| \
	sed 's/^@M/M/g' | \
	awk '{print ">"$1"\n"$2}' | \
	awk -v num=$n '{if ($0!~/^>/) print substr($1,0,num); else print $0}' | \
        awk -v min=$n 'BEGIN {RS = ">" ; ORS = ""} length($2) >= min {print ">"$0}' > ${f}_trimmed_mapped_reads.fasta; 
done
}


function rawreads(){
echo Linking Raw reads | tee -a ${o}_primers_blast.log

for w in `ls ${r}/*.gz | grep -v Undet ` ; do ln -s $w . ; done

echo | tee -a ${o}_primers_blast.log
echo Extracting ${n} bases from raw reads | tee -a ${o}_primers_blast.log
for g in `ls *${u}*gz | awk -F".fastq.gz" '{print $1}'`; do echo $g; \
        zcat ${g}.fastq.gz | \
	/media/software/fastx_toolkit/0.0.14/bin/fastq_to_fasta \
        awk -v num=$n '{if ($0!~/^>/) print substr($1,0,num); else print $0}' | \
        awk -v min=$n 'BEGIN {RS = ">" ; ORS = ""} length($2) >= min {print ">"$0}' > ${g}_trimmed_mapped_reads.fasta;
done
} 

if [ ${alignm} -eq 1 ]; then
	alignments
elif [ ${raw} -eq 1 ]; then
	rawreads
fi



#Blast  if SE or PE
# if SE or PE
if [ $SE -eq 0 ]; then
	echo | tee -a ${o}_primers_blast.log
	echo Blast trimmed reads against primers DB | tee -a ${o}_primers_blast.log
	for q in `ls *_trimmed_mapped_reads.fasta | awk -F".fasta" '{print $1}'` ; \
		do \
			echo $q ; \
			blastn -db ${d} -query ${q}.fasta -outfmt "6 std qlen slen" -num_threads=36 -task=blastn > ${q}_blast_temp.out ; \
	done
	for blasts in `ls *_blast_temp.out | awk -F"_blast_temp.out" '{print $1}'` ; \
		do \
			echo $blasts ; \
			cat ${blasts}_blast_temp.out | grep -v ^$ > ${blasts}_blast.out ; \
	done
	# rm *_blast_temp.out
elif [ $SE -eq 1 ]; then
	echo | tee -a ${o}_primers_blast.log
	echo Blast trimmed reads against primers DB | tee -a ${o}_primers_blast.log
	for q in `ls *_trimmed_mapped_reads.fasta | awk -F".fasta" '{print $1}'` ; \
		do \
			echo $q ; \
			blastn -db ${d} -query ${q}.fasta -outfmt "6 std qlen slen" -num_threads=36 -task=blastn > ${q}_blast.out ; \
	done
fi


echo | tee -a ${o}_primers_blast.log
echo Counting most problematic primers | tee -a ${o}_primers_blast.log
for b in `ls *blast.out | awk -F"_blast.out" '{print $1}'`; do echo $b ; cut -f2 ${b}_blast.out | sort | uniq -c | sort -k1nr > ${b}_worst_primers.txt ; done

mkdir intermediate_files
mv *.* intermediate_files
mv intermediate_files/*_worst_primers.txt .
mv intermediate_files/${o}_primers_blast.log .


echo Complete | cowsay | tee -a ${o}_primers_blast.log
echo | tee -a ${o}_primers_blast.log
