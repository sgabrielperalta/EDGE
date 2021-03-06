#!/usr/bin/env bash
set -e
rootdir=$( cd $(dirname $0) ; pwd -P )
exec >  >(tee install.log)
exec 2>&1

cd $rootdir
cd thirdParty

mkdir -p $rootdir/bin

export PATH=$PATH:$rootdir/bin/

assembly_tools=( idba spades megahit )
annotation_tools=( prokka RATT tRNAscan barrnap BLAST+ blastall phageFinder glimmer aragorn prodigal tbl2asn ShortBRED )
utility_tools=( bedtools R GNU_parallel tabix JBrowse primer3 samtools sratoolkit ea-utils Rpackages)
alignments_tools=( hmmer infernal bowtie2 bwa mummer RAPSearch2 )
taxonomy_tools=( kraken metaphlan kronatools gottcha )
phylogeny_tools=( FastTree RAxML )
perl_modules=( perl_parallel_forkmanager perl_excel_writer perl_archive_zip perl_string_approx perl_pdf_api2 perl_html_template perl_html_parser perl_JSON perl_bio_phylo perl_xml_twig perl_cgi_session )
python_packages=( Anaconda2 Anaconda3 )
all_tools=( "${python_packages[@]}" "${assembly_tools[@]}" "${annotation_tools[@]}" "${utility_tools[@]}" "${alignments_tools[@]}" "${taxonomy_tools[@]}" "${phylogeny_tools[@]}" "${perl_modules[@]}")

### Install functions ###
install_idba()
{
echo "------------------------------------------------------------------------------
                           Compiling IDBA 1.1.1
------------------------------------------------------------------------------
"
tar xvzf idba-1.1.1.tar.gz
cd idba-1.1.1
sed -i.bak 's/kMaxShortSequence = 128/kMaxShortSequence = 351/' src/sequence/short_sequence.h
sed -i.bak 's/kNumUint64 = 4/kNumUint64 = 6/' src/basic/kmer.h
#src/sequence/short_sequence.h:    static const uint32_t kMaxShortSequence = 128
./configure --prefix=$rootdir
make 
make install
cp bin/idba_ud $rootdir/bin/.
cp bin/fq2fa $rootdir/bin/.
cd $rootdir/thirdParty
if [[ "$OSTYPE" == "darwin"* ]]
then
{
      cp -f idba_ud_mac $rootdir/bin/idba_ud
}
fi
echo "
------------------------------------------------------------------------------
                           IDBA compiled
------------------------------------------------------------------------------
"
}


install_spades(){
local VER=3.7.1
echo "------------------------------------------------------------------------------
                           Installing SPAdes $VER
------------------------------------------------------------------------------
"
tar xvzf SPAdes-$VER-Linux.tar.gz 
ln -sf $rootdir/thirdParty/SPAdes-$VER-Linux/bin/spades.py $rootdir/bin/spades.py
cd $rootdir/thirdParty
echo "
------------------------------------------------------------------------------
                           SPAdes $VER installed
------------------------------------------------------------------------------
"
}

install_megahit(){
local VER=1.0.3
## --version MEGAHIT v1.0.3
echo "------------------------------------------------------------------------------
                           Installing megahit $VER
------------------------------------------------------------------------------
"
tar xvzf megahit-v$VER.tar.gz 
cd megahit-$VER
make
cp -f megahit* $rootdir/bin/
cd $rootdir/thirdParty
echo "
------------------------------------------------------------------------------
                           megahit $VER installed
------------------------------------------------------------------------------
"
}

install_tRNAscan()
{
echo "------------------------------------------------------------------------------
                           Installing tRNAscan-SE 1.3.1
------------------------------------------------------------------------------
"
tar xvzf tRNAscan-SE-1.3.1.tar.gz
cd tRNAscan-SE-1.3.1
sed -i.bak 's,home,'"$rootdir"',' Makefile
make
make install
make clean
cd $rootdir/thirdParty
chmod -R +x $rootdir/bin/tRNAscanSE
chmod -R +r $rootdir/bin/tRNAscanSE
echo "
------------------------------------------------------------------------------
                           tRNAscan-SE 1.3.1 installed
------------------------------------------------------------------------------
"
}

install_prokka()
{
echo "------------------------------------------------------------------------------
                           Installing prokka-1.11
------------------------------------------------------------------------------
"
tar xvzf prokka-1.11.tar.gz
cd prokka-1.11
cd $rootdir/thirdParty
ln -sf $rootdir/thirdParty/prokka-1.11/bin/prokka $rootdir/bin/prokka
$rootdir/thirdParty/prokka-1.11/bin/prokka --setupdb
echo "
------------------------------------------------------------------------------
                           prokka-1.11 installed
------------------------------------------------------------------------------
"
}

install_barrnap()
{
echo "------------------------------------------------------------------------------
                           Installing barrnap-0.4.2
------------------------------------------------------------------------------
"
tar xvzf barrnap-0.4.2.tar.gz
cd barrnap-0.4.2
cd $rootdir/thirdParty
ln -sf $rootdir/thirdParty/barrnap-0.4.2/bin/barrnap $rootdir/bin/barrnap
echo "
------------------------------------------------------------------------------
                           barrnap-0.4.2 installed
------------------------------------------------------------------------------
"
}


install_bedtools()
{
echo "------------------------------------------------------------------------------
                           Installing bedtools-2.19.1
------------------------------------------------------------------------------
"
tar xvzf bedtools-2.19.1.tar.gz
cd bedtools2-2.19.1
make 
cp -fR bin/* $rootdir/bin/. 
cd $rootdir/thirdParty
echo "
------------------------------------------------------------------------------
                           bedtools-2.19.1 installed
------------------------------------------------------------------------------
"
}

install_sratoolkit()
{
local VER=2.5.4
echo "------------------------------------------------------------------------------
                           Installing sratoolkit.$VER-linux64
------------------------------------------------------------------------------
"
tar xvzf sratoolkit.$VER-linux64.tgz
cd sratoolkit.$VER-linux64
ln -sf $rootdir/thirdParty/sratoolkit.$VER-linux64/bin/fastq-dump $rootdir/bin/fastq-dump
ln -sf $rootdir/thirdParty/sratoolkit.$VER-linux64/bin/vdb-dump $rootdir/bin/vdb-dump
./bin/vdb-config --restore-defaults
./bin/vdb-config -s /repository/user/default-path=$rootdir/edge_ui/ncbi
./bin/vdb-config -s /repository/user/main/public/root=$rootdir/edge_ui/ncbi/public
if [[ -n ${HTTP_PROXY} ]]; then
	proxy_without_protocol=${HTTP_PROXY#http://}
        ./bin/vdb-config --proxy $proxy_without_protocol
fi
if [[ -n ${http_proxy} ]]; then
	proxy_without_protocol=${http_proxy#http://}
        ./bin/vdb-config --proxy $proxy_without_protocol
fi

cd $rootdir/thirdParty
echo "
------------------------------------------------------------------------------
                           sratoolkit.$VER-linux64 installed
------------------------------------------------------------------------------
"
}

install_ea-utils(){
echo "------------------------------------------------------------------------------
                           Installing ea-utils.1.1.2-537
------------------------------------------------------------------------------
"
tar xvzf ea-utils.1.1.2-537.tar.gz
cd ea-utils.1.1.2-537
PREFIX=$rootdir make install

cd $rootdir/thirdParty
echo "
------------------------------------------------------------------------------
                           ea-utils.1.1.2-537 installed
------------------------------------------------------------------------------
"
}

install_R()
{
local VER=3.3.2
echo "------------------------------------------------------------------------------
                           Compiling R $VER
------------------------------------------------------------------------------
"
tar xvzf R-$VER.tar.gz
cd R-$VER
./configure --prefix=$rootdir
make
make install
cd $rootdir/thirdParty
echo "
------------------------------------------------------------------------------
                           R compiled
------------------------------------------------------------------------------
"
}
install_Rpackages()
{
echo "------------------------------------------------------------------------------
                           installing R packages
------------------------------------------------------------------------------
"
echo "if(\"gridExtra\" %in% rownames(installed.packages()) == FALSE)  {install.packages(c(\"gtable_0.1.2.tar.gz\",\"gridExtra_2.0.0.tar.gz\"), repos = NULL, type=\"source\")}" | $rootdir/bin/Rscript -  
# need internet for following R packages.
echo "if(\"devtools\" %in% rownames(installed.packages()) == FALSE)  {install.packages('devtools',repos='https://cran.rstudio.com/')}" | $rootdir/bin/Rscript -
echo "if(\"phyloseq\" %in% rownames(installed.packages()) == FALSE)  {source('https://bioconductor.org/biocLite.R'); biocLite('phyloseq')} " | $rootdir/bin/Rscript -
echo "library(devtools);  options(unzip='internal'); install_github(repo = 'seninp-bioinfo/MetaComp', ref = 'v1.3');" | $rootdir/bin/Rscript -
echo "
------------------------------------------------------------------------------
                           R packages installed
------------------------------------------------------------------------------
"
}

install_GNU_parallel()
{
echo "------------------------------------------------------------------------------
                           Compiling GNU parallel
------------------------------------------------------------------------------
"
tar xvzf parallel-20140622.tar.gz
cd parallel-20140622
./configure --prefix=$rootdir 
make
make install
cd $rootdir/thirdParty
echo "
------------------------------------------------------------------------------
                           GNU parallel compiled
------------------------------------------------------------------------------
"
}

install_BLAST+()
{
local VER=2.5.0
echo "------------------------------------------------------------------------------
                           Install ncbi-blast-$VER+-x64
------------------------------------------------------------------------------
"
BLAST_ZIP=ncbi-blast-$VER+-x64-linux.tar.gz
if [[ "$OSTYPE" == "darwin"* ]]
then
{
    VER=2.2.29
    BLAST_ZIP=ncbi-blast-$VER+-universal-macosx.tar.gz
}
fi

tar xvzf $BLAST_ZIP
cd ncbi-blast-$VER+
cp -fR bin/* $rootdir/bin/.
cd $rootdir/thirdParty
echo "
------------------------------------------------------------------------------
                           ncbi-blast-$VER+-x64 installed
------------------------------------------------------------------------------
"
}

install_blastall()
{
echo "------------------------------------------------------------------------------
                           Install blast-2.2.26-x64-linux
------------------------------------------------------------------------------
"
BLAST_ZIP=blast-2.2.26-x64-linux.tar.gz
if [[ "$OSTYPE" == "darwin"* ]]
then
{
    BLAST_ZIP=blast-2.2.26-universal-macosx.tar.gz
}
fi

tar xvzf $BLAST_ZIP
cd blast-2.2.26
cp -fR bin/* $rootdir/bin/.
cd $rootdir/thirdParty
echo "
------------------------------------------------------------------------------
                           blast-2.2.26-x64 installed
------------------------------------------------------------------------------
"
}

install_kraken()
{
echo "------------------------------------------------------------------------------
                           Install kraken-0.10.4-beta
------------------------------------------------------------------------------
"
tar xvzf kraken-0.10.4-beta.tgz
cd kraken-0.10.4-beta
./install_kraken.sh $rootdir/bin/

cd $rootdir/thirdParty
echo "
------------------------------------------------------------------------------
                           kraken-0.10.4-beta installed
------------------------------------------------------------------------------
"
}

install_JBrowse()
{
echo "------------------------------------------------------------------------------
                           Installing JBrowse-1.11.6
------------------------------------------------------------------------------
"
tar xvzf JBrowse-1.11.6.tar.gz
if [ -e $rootdir/edge_ui/JBrowse/data ]
then
  mv $rootdir/edge_ui/JBrowse/data $rootdir/edge_ui/JBrowse_olddata
fi
if [ -e $rootdir/edge_ui/JBrowse ]
then
  rm -rf $rootdir/edge_ui/JBrowse
fi

mv JBrowse-1.11.6 $rootdir/edge_ui/JBrowse
cd $rootdir/edge_ui/JBrowse
./setup.sh
if [ -e $rootdir/edge_ui/JBrowse_olddata ]
then
  mv $rootdir/edge_ui/JBrowse_olddata $rootdir/edge_ui/JBrowse/data
else
  mkdir -p -m 775 data
fi

cd $rootdir/thirdParty
#ln -sf $rootdir/thirdParty/JBrowse-1.11.6 $rootdir/edge_ui/JBrowse
echo "
------------------------------------------------------------------------------
                           JBrowse-1.11.6 installed
------------------------------------------------------------------------------
"
}

install_tabix()
{
echo "------------------------------------------------------------------------------
                           Compiling tabix bgzip
------------------------------------------------------------------------------
"
tar xvzf tabix.tgz
cd tabix
make
cp tabix $rootdir/bin/.
cp bgzip $rootdir/bin/.
cd $rootdir/thirdParty
echo "
------------------------------------------------------------------------------
                           tabix bgzip  compiled
------------------------------------------------------------------------------
"
}

install_hmmer()
{
echo "------------------------------------------------------------------------------
                           Compiling hmmer-3.1b1
------------------------------------------------------------------------------
"
tar xvzf hmmer-3.1b1.tar.gz
cd hmmer-3.1b1/
./configure --prefix=$rootdir && make && make install
cd $rootdir/thirdParty
echo "
------------------------------------------------------------------------------
                           hmmer-3.1b1 compiled
------------------------------------------------------------------------------
"
}

install_infernal()
{
echo "------------------------------------------------------------------------------
                           Installing infernal-1.1rc4
------------------------------------------------------------------------------
"
tar xzvf infernal-1.1rc4.tar.gz
cd infernal-1.1rc4/
./configure --prefix=$rootdir && make && make install
cd $rootdir/thirdParty
echo "
------------------------------------------------------------------------------
                           infernal-1.1rc4 installed
------------------------------------------------------------------------------
"
}

install_phageFinder()
{
echo "------------------------------------------------------------------------------
                           Installing phage_finder_v2.1
------------------------------------------------------------------------------
"
tar xvzf phage_finder_v2.1.tar.gz
cd phage_finder_v2.1
cd $rootdir/thirdParty
chmod -R +x phage_finder_v2.1
chmod -R +r phage_finder_v2.1
echo "
------------------------------------------------------------------------------
                           phage_finder_v2.1 installed
------------------------------------------------------------------------------
"
}

install_bowtie2()
{
echo "------------------------------------------------------------------------------
                           Compiling bowtie2 2.2.6
------------------------------------------------------------------------------
"
tar xvzf bowtie2-2.2.6.tar.gz
cd bowtie2-2.2.6
make
cp bowtie2* $rootdir/bin/.
cd $rootdir/thirdParty
echo "
------------------------------------------------------------------------------
                           bowtie2 compiled
------------------------------------------------------------------------------
"
}

install_gottcha()
{
echo "------------------------------------------------------------------------------
                           Compiling gottcha-1.0b
------------------------------------------------------------------------------
"
tar xvzf gottcha.tar.gz
cd gottcha
./INSTALL.sh
ln -sf $PWD/bin/gottcha.pl $rootdir/bin/
cd $rootdir/thirdParty
echo "
------------------------------------------------------------------------------
                           gottcha-1.0b compiled
------------------------------------------------------------------------------
"
}


install_metaphlan()
{
echo "------------------------------------------------------------------------------
                           Compiling metaphlan-1.7.7
------------------------------------------------------------------------------
"
tar xvzf metaphlan-1.7.7.tar.gz
cd metaphlan-1.7.7
cp -fR metaphlan.py $rootdir/bin/.
cd $rootdir/thirdParty
echo "
------------------------------------------------------------------------------
                           metaphlan-1.7.7 compiled
------------------------------------------------------------------------------
"
}

install_RATT()
{
echo "------------------------------------------------------------------------------
                           Installing RATT 
------------------------------------------------------------------------------
"
tar xvzf RATT.tar.gz
cd $rootdir/thirdParty
echo "
------------------------------------------------------------------------------
                           RATT installed 
------------------------------------------------------------------------------
"
}

install_glimmer()
{
echo "------------------------------------------------------------------------------
                           Compiling glimmer 3.02
------------------------------------------------------------------------------
"
tar xvzf glimmer302b.tar.gz
cd glimmer3.02/SimpleMake
make
cp ../bin/* $rootdir/bin/.
cp ../scripts/* $rootdir/scripts/.
for i in $rootdir/scripts/*.csh
do 
 sed -i.bak 's!/fs/szgenefinding/Glimmer3!'$rootdir'!' $i
 sed -i.bak 's!/fs/szgenefinding/Glimmer3!'$rootdir'!' $i
done
cd $rootdir/thirdParty
echo "
------------------------------------------------------------------------------
                           glimmer3.02 compiled
------------------------------------------------------------------------------
"
}

install_aragorn()
{
echo "------------------------------------------------------------------------------
                           Compiling aragorn1.2.36
------------------------------------------------------------------------------
"
tar xvzf aragorn1.2.36.tgz
cd aragorn1.2.36
gcc -O3 -ffast-math -finline-functions -o aragorn aragorn1.2.36.c
cp -fR aragorn $rootdir/bin/.
cd $rootdir/thirdParty
echo "
------------------------------------------------------------------------------
                           aragorn1.2.36 compiled
------------------------------------------------------------------------------
"
}

install_prodigal()
{
echo "------------------------------------------------------------------------------
                           Compiling prodigal.v2_60
------------------------------------------------------------------------------
"
tar xvzf prodigal.v2_60.tar.gz
cd prodigal.v2_60/
make
cp -fR prodigal $rootdir/bin
cd $rootdir/thirdParty
echo "
------------------------------------------------------------------------------
                           prodigal.v2_60 compiled
------------------------------------------------------------------------------
"
}

install_ShortBRED()
{
echo "------------------------------------------------------------------------------
                           Installing ShortBRED
------------------------------------------------------------------------------
"
tar xvzf ShortBRED-0.9.4M.tgz
ln -sf $rootdir/thirdParty/ShortBRED-0.9.4M $rootdir/bin/ShortBRED
echo "
------------------------------------------------------------------------------
                           ShortBRED installed
------------------------------------------------------------------------------
"
}

install_tbl2asn()
{
echo "------------------------------------------------------------------------------
                           Installing NCBI tbl2asn
------------------------------------------------------------------------------
"
if [[ "$OSTYPE" == "darwin"* ]]
then
{
    tar xvzf mac.tbl2asn.tgz
    chmod +x mac.tbl2asn
    ln -sf $rootdir/thirdParty/mac.tbl2asn $rootdir/bin/tbl2asn
}
else
{
    tar xvzf linux64.tbl2asn.tgz
    chmod +x linux64.tbl2asn
    ln -sf $rootdir/thirdParty/linux64.tbl2asn $rootdir/bin/tbl2asn.orig
}
fi

cd $rootdir/thirdParty
echo "
------------------------------------------------------------------------------
                           NCBI tbl2asn installed
------------------------------------------------------------------------------
"
}

install_bwa()
{
echo "------------------------------------------------------------------------------
                           Compiling bwa 0.7.12
------------------------------------------------------------------------------
"
tar xvzf bwa-0.7.12.tar.gz
cd bwa-0.7.12
make clean && make
cp bwa $rootdir/bin/.
cd $rootdir/thirdParty
echo "
------------------------------------------------------------------------------
                           bwa compiled
------------------------------------------------------------------------------
"
}

install_RAPSearch2()
{
local VER=2.23
echo "------------------------------------------------------------------------------
                           Compiling RAPSearch2 $VER
------------------------------------------------------------------------------
"
tar xvzf RAPSearch${VER}_64bits.tar.gz
cd RAPSearch${VER}_64bits
./install
cp bin/rapsearch $rootdir/bin/rapsearch2
cp bin/prerapsearch $rootdir/bin/.
cd $rootdir/thirdParty
echo "
------------------------------------------------------------------------------
                           RAPSearch2 $VER compiled
------------------------------------------------------------------------------
"
}

install_mummer()
{
echo "------------------------------------------------------------------------------
                           Compiling MUMmer3.23 64bit
------------------------------------------------------------------------------
"
tar xvzf MUMmer3.23.tar.gz
cd MUMmer3.23
#for 64bit MUMmer complie
make CPPFLAGS="-O3 -DSIXTYFOURBITS"
cp nucmer $rootdir/bin/.
cp show-coords $rootdir/bin/.
cp show-snps $rootdir/bin/.
cp mgaps $rootdir/bin/.
cp delta-filter $rootdir/bin/.
cd $rootdir/thirdParty
echo "
------------------------------------------------------------------------------
                           MUMmer3.23 compiled
------------------------------------------------------------------------------
"
}

install_primer3()
{
echo "------------------------------------------------------------------------------
                           Compiling primer3 2.3.5
------------------------------------------------------------------------------
"
tar xvzf primer3-2.3.5.tar.gz
cd primer3-2.3.5/src
make
cp primer3_core $rootdir/bin/.
cp oligotm $rootdir/bin/.
cp ntthal $rootdir/bin/.
cp ntdpal $rootdir/bin/.
cp long_seq_tm_test $rootdir/bin/.
cp -R primer3_config $rootdir/lib/.
cd $rootdir/thirdParty
echo "
------------------------------------------------------------------------------
                          primer3-2.3.5 compiled
------------------------------------------------------------------------------
"
}

install_kronatools()
{
echo "------------------------------------------------------------------------------
               Installing KronaTools-2.6
------------------------------------------------------------------------------
"
tar xvzf KronaTools-2.6.tar.gz
cd KronaTools-2.6/KronaTools
perl install.pl --prefix $rootdir --taxonomy $rootdir/database/Krona_taxonomy
#./updateTaxonomy.sh --local
cp $rootdir/scripts/microbial_profiling/script/ImportBWA.pl scripts/
ln -sf $rootdir/thirdParty/KronaTools-2.6/KronaTools/scripts/ImportBWA.pl $rootdir/bin/ktImportBWA 
cd $rootdir/thirdParty
echo "
------------------------------------------------------------------------------
                        KronaTools-2.6 Installed
------------------------------------------------------------------------------
"
}

install_samtools()
{
echo "------------------------------------------------------------------------------
                           Compiling samtools 0.1.19
------------------------------------------------------------------------------
"
tar xvzf samtools-0.1.19.tar.gz
cd samtools-0.1.19
make CFLAGS='-g -fPIC -Wall -O2'
cp samtools $rootdir/bin/.
cp bcftools/bcftools $rootdir/bin/.
cd $rootdir/thirdParty
echo "
------------------------------------------------------------------------------
                           samtools compiled
------------------------------------------------------------------------------
"
}

install_FastTree()
{
echo "------------------------------------------------------------------------------
                           Compiling FastTree
------------------------------------------------------------------------------
"
gcc -DOPENMP -DUSE_DOUBLE -fopenmp -O3 -finline-functions -funroll-loops -Wall -o FastTreeMP FastTree.c -lm
cp -f FastTreeMP $rootdir/bin/.
echo "
------------------------------------------------------------------------------
                           FastTree compiled
------------------------------------------------------------------------------
"
}

install_RAxML()
{
echo "------------------------------------------------------------------------------
                           Compiling RAxML-8.0.26
------------------------------------------------------------------------------
"
tar xvzf RAxML-8.0.26.tar.gz
cd RAxML-8.0.26
make -f Makefile.PTHREADS.gcc
cp -f raxmlHPC-PTHREADS $rootdir/bin/.
cd $rootdir/thirdParty
echo "
------------------------------------------------------------------------------
                           RAxML-8.0.26 compiled
------------------------------------------------------------------------------
"
}


install_perl_parallel_forkmanager()
{
echo "------------------------------------------------------------------------------
               Installing Perl Module Parallel-ForkManager-1.03
------------------------------------------------------------------------------
"
tar xvzf Parallel-ForkManager-1.03.tar.gz
cd Parallel-ForkManager-1.03
perl Makefile.PL
make
cp -fR blib/lib/* $rootdir/lib/
cd $rootdir/thirdParty
echo "
------------------------------------------------------------------------------
                        Parallel-ForkManager-1.03 Installed
------------------------------------------------------------------------------
"
}

install_perl_excel_writer()
{
echo "------------------------------------------------------------------------------
               Installing Perl Module Excel-Writer-XLSX-0.71
------------------------------------------------------------------------------
"
tar xvzf Excel-Writer-XLSX-0.71.tar.gz
cd Excel-Writer-XLSX-0.71
perl Makefile.PL
make
cp -fR blib/lib/* $rootdir/lib/.
cp blib/script/extract_vba $rootdir/bin/.
cd $rootdir/thirdParty
echo "
------------------------------------------------------------------------------
                        Excel-Writer-XLSX-0.71 Installed
------------------------------------------------------------------------------
" 
}

install_perl_archive_zip()
{
echo "------------------------------------------------------------------------------
               Installing Perl Module Archive-Zip-1.37
------------------------------------------------------------------------------
"
tar xvzf Archive-Zip-1.37.tar.gz
cd Archive-Zip-1.37
perl Makefile.PL
make
cp -fR blib/lib/* $rootdir/lib/.
cd $rootdir/thirdParty
echo "
------------------------------------------------------------------------------
                        Archive-Zip-1.37 Installed
------------------------------------------------------------------------------
"
}


install_perl_string_approx()
{
echo "------------------------------------------------------------------------------
                 Installing Perl Module String-Approx-3.27
------------------------------------------------------------------------------
"
tar xvzf String-Approx-3.27.tar.gz
cd String-Approx-3.27
perl Makefile.PL 
make
cp -fR blib/lib/* $rootdir/lib/
mkdir -p $rootdir/lib/auto
mkdir -p $rootdir/lib/auto/String
mkdir -p $rootdir/lib/auto/String/Approx
cp -fR blib/arch/auto/String/Approx/Approx.* $rootdir/lib/auto/String/Approx/
cd $rootdir/thirdParty
echo "
------------------------------------------------------------------------------
                        String-Approx-3.27 Installed
------------------------------------------------------------------------------
"
}

install_perl_pdf_api2()
{
echo "------------------------------------------------------------------------------
                 Installing Perl Module PDF-API2-2.020
------------------------------------------------------------------------------
"
tar xvzf PDF-API2-2.020.tar.gz
cd PDF-API2-2.020
perl Makefile.PL 
make
cp -fR blib/lib/* $rootdir/lib/.
cd $rootdir/thirdParty
echo "
------------------------------------------------------------------------------
                        PDF-API2-2.020 Installed
------------------------------------------------------------------------------
"
}

install_perl_JSON()
{
echo "------------------------------------------------------------------------------
                 Installing Perl Module JSON-2.90
------------------------------------------------------------------------------
"
tar xvzf JSON-2.90.tar.gz
cd JSON-2.90
perl Makefile.PL 
make
cp -fR blib/lib/* $rootdir/lib/.
cd $rootdir/thirdParty
echo "
------------------------------------------------------------------------------
                        JSON-2.90 Installed
------------------------------------------------------------------------------
"
}

install_perl_html_parser()
{
echo "------------------------------------------------------------------------------
                 Installing Perl Module HTML-Parser-3.71
------------------------------------------------------------------------------
"
tar xvzf HTML-Parser-3.71.tar.gz
cd HTML-Parser-3.71
perl Makefile.PL 
make
cp -fR blib/lib/* $rootdir/lib/.
cp -fR blib/arch/auto/* $rootdir/lib/auto/.
cd $rootdir/thirdParty
echo "
------------------------------------------------------------------------------
                        HTML-Parser-3.71 Installed
------------------------------------------------------------------------------
"
}

install_perl_html_template()
{
echo "------------------------------------------------------------------------------
                 Installing Perl Module HTML-Template-2.6
------------------------------------------------------------------------------
"
tar xvzf HTML-Template-2.6.tar.gz
cd HTML-Template-2.6
perl Makefile.PL
make
cp -fR blib/lib/* $rootdir/lib/.
cd $rootdir/thirdParty
echo "
------------------------------------------------------------------------------
                         HTML-Template-2.6 Installed
------------------------------------------------------------------------------
"
}

install_perl_bio_phylo()
{
echo "------------------------------------------------------------------------------
                 Installing Perl Module Bio-Phylo-0.58
------------------------------------------------------------------------------
"
tar xvzf Bio-Phylo-0.58.tar.gz
cd Bio-Phylo-0.58
perl Makefile.PL
make
cp -fR blib/lib/* $rootdir/lib/.
cd $rootdir/thirdParty
echo "
------------------------------------------------------------------------------
                         Bio-Phylo-0.58 Installed
------------------------------------------------------------------------------
"
}

install_perl_xml_twig()
{
echo "------------------------------------------------------------------------------
                 Installing Perl Module XML-Twig-3.48
------------------------------------------------------------------------------
"
tar xvzf XML-Twig-3.48.tar.gz
cd XML-Twig-3.48
perl Makefile.PL -y
make
cp -fR blib/lib/* $rootdir/lib/.
cp -fR blib/script/* $rootdir/bin/.
cd $rootdir/thirdParty
echo "
------------------------------------------------------------------------------
                         XML-Twig-3.48 Installed
------------------------------------------------------------------------------
"
}


install_perl_cgi_session()
{
echo "------------------------------------------------------------------------------
                 Installing Perl Module CGI-Session-4.48
------------------------------------------------------------------------------
"
tar xvzf CGI-Session-4.48.tar.gz
cd CGI-Session-4.48
perl Makefile.PL
make
cp -fR blib/lib/* $rootdir/lib/.
cd $rootdir/thirdParty
echo "
------------------------------------------------------------------------------
                         CGI-Session-4.48 Installed
------------------------------------------------------------------------------
"
}

install_Anaconda2()
{
echo "------------------------------------------------------------------------------
                 Installing Python Anaconda2 4.1.1
------------------------------------------------------------------------------
"
if [ ! -f $rootdir/thirdParty/Anaconda2/bin/python ]; then
    bash Anaconda2-4.1.1-Linux-x86_64.sh -b -p $rootdir/thirdParty/Anaconda2/
fi
anacondabin=$rootdir/thirdParty/Anaconda2/bin/
ln -fs $anacondabin/python $rootdir/bin
ln -fs $anacondabin/pip $rootdir/bin
ln -fs $anacondabin/conda $rootdir/bin
wget -q --spider https://pypi.python.org/
online=$?
if [[ $online -eq 0 ]]; then
	$anacondabin/conda install -y biopython
	$anacondabin/conda install -yc anaconda mysql-connector-python=2.0.3
	$anacondabin/pip install qiime xlsx2csv
	$anacondabin/conda install -y --channel https://conda.anaconda.org/bioconda rgi
	$anacondabin/conda install -y matplotlib=2.0.0
        matplotlibrc=`$anacondabin/python -c 'import matplotlib as m; print m.matplotlib_fname()' 2>&1`
        perl -i.orig -nle 's/(backend\s+:\s+\w+)/\#${1}\nbackend : Agg/; print;' $matplotlibrc
else
    $anacondabin/conda install biopython-1.67-np110py27_0.tar.bz2
    echo "Unable to connect to the internet, not able to install qiime or xlsx2csv"
fi
echo "
------------------------------------------------------------------------------
                         Python Anaconda2 4.1.1 Installed
------------------------------------------------------------------------------
"
}


checkSystemInstallation()
{
    IFS=:
    for d in $PATH; do
      if test -x "$d/$1"; then return 0; fi
    done
    return 1
}

checkLocalInstallation()
{
    IFS=:
    for d in $rootdir/bin; do
      if test -x "$d/$1"; then return 0; fi
    done
    return 1
}

checkPerlModule()
{
   perl -e "use lib \"$rootdir/lib\"; use $1;"
   return $?
}


containsElement () {
  local e
  for e in "${@:2}"; do [[ "$e" == "$1" ]] && return 0; done
  return 1
}

print_usage()
{
cat << EOF
usage: $0 options
    If no options, it will check existing installation and run tools installation for those uninstalled.
    options:
    help            show this help
    list            show available tools for updates
    tools_name      install/update individual tool
    force           force to install all list tools locally
    
    ex: To update bowtie2 only
        $0 bowtie2
    ex: To update bowtie2 and bwa
        $0 bowtie2 bwa
    ex: RE-install Phylogeny tools
        $0 Phylogeny
        
EOF

}

print_tools_list()
{

   
   echo "Available tools for updates/re-install"
   echo -e "\nAssembly"
   for i in "${assembly_tools[@]}"
   do
	   echo "* $i"
   done
   echo -e "\nAnnotation"
   for i in "${annotation_tools[@]}"
   do
	   echo "* $i"
   done
   echo -e "\nAlignment"
   for i in "${alignments_tools[@]}"
   do
	   echo "* $i"
   done
   echo -e "\nTaxonomy"
   for i in "${taxonomy_tools[@]}"
   do
	  echo "* $i"
   done
   echo -e "\nPhylogeny"
   for i in "${phylogeny_tools[@]}"
   do
	   echo "* $i"
   done
   echo -e "\nUtility"
   for i in "${utility_tools[@]}"
   do
	   echo "* $i"
   done
   echo -e "\nPerl_Modules"
   for i in "${perl_modules[@]}"
   do
	   echo "* $i"
   done
   echo -e "\nPython_Packages"
   for i in "${python_packages[@]}"
   do
           echo "* $i"
   done
}


### Main ####
if ( checkSystemInstallation csh )
then
  #echo "csh is found"
  echo -n ""
else
  echo "csh is not found"
  echo "Please Install csh first, then INSTALL the package"
  exit 1
fi

if [ "$#" -ge 1 ]
then
  for f in $@
  do
    case $f in
      help)
        print_usage
        exit 0;;
      list)
        print_tools_list
        exit 0;;
      Assembly)
        for tool in "${assembly_tools[@]}"
        do
            install_$tool
        done
        echo -e "Assembly tools installed.\n"
        exit 0;;  
      Annotation)
        for tool in "${annotation_tools[@]}"
        do
            install_$tool
        done
        echo -e "Annotation tools installed.\n"
        exit 0;;  
      Alignment)
        for tool in "${alignments_tools[@]}"
        do
            install_$tool
        done
        echo -e "Alignment tools installed.\n"
        exit 0;; 
      Taxonomy)
        for tool in "${taxonomy_tools[@]}"
        do
            install_$tool
        done
        echo -e "Taxonomy tools installed.\n"
        exit 0;; 
      Phylogeny)
        for tool in "${phylogeny_tools[@]}"
        do
            install_$tool
        done
        echo -e "Phylogeny tools installed.\n"
        exit 0;; 
      Utility)
        for tool in "${utility_tools[@]}"
        do
            install_$tool
        done
        echo -e "Utility tools installed.\n"
        exit 0;; 
      Perl_Modules)
        for tool in "${perl_modules[@]}"
        do
            install_$tool
        done
        echo -e "Perl_Modules installed.\n"
        exit 0 ;;
      Python_Packages)
        for tool in "${python_packages[@]}"
        do
            install_$tool
        done
        echo -e "Python_Packages installed.\n"
        exit 0 ;;
      force)
        for tool in "${all_tools[@]}"
        do
            install_$tool
        done
        ;;
      *)
        if ( containsElement "$f" "${assembly_tools[@]}" || containsElement "$f" "${annotation_tools[@]}" || containsElement "$f" "${alignments_tools[@]}" || containsElement "$f" "${taxonomy_tools[@]}" || containsElement "$f" "${phylogeny_tools[@]}" || containsElement "$f" "${utility_tools[@]}" || containsElement "$f" "${perl_modules[@]}" || containsElement "$f" "${python_packages[@]}" )
        then
            install_$f
        else
            echo "$f: no this tool in the list"
            print_tools_list
        fi
        exit;;
    esac
  done
fi

if ( checkSystemInstallation inkscape )
then
  echo "inkscape is found"
else
  echo "inkscape is not found"
 # echo "Please Install inkscape, then INSTALL the package"
 # exit 1
fi

if perl -MBio::Root::Version -e 'print $Bio::Root::Version::VERSION,"\n"' >/dev/null 2>&1 
then 
  perl -MBio::Root::Version -e 'print "BioPerl Version ", $Bio::Root::Version::VERSION," is found\n"'
else 
  echo "Cannot find a perl Bioperl Module installed" 1>&2
  echo "Please install Bioperl (http://www.bioperl.org/)"
  exit 1
fi

if $rootdir/bin/python -c 'import Bio; print Bio.__version__' >/dev/null 2>&1
then
  $rootdir/bin/python -c 'import Bio; print "BioPython Version", Bio.__version__, "is found"'
else
  install_Anaconda2
fi

if [[ "$OSTYPE" == "darwin"* ]]
then
{
    if ( checkSystemInstallation R )
    then
    {
        echo "R is found"
    }
    else
    {
        echo "R is not found"
        echo "Please install R from http://cran.r-project.org/bin/macosx/";
        exit 1
    }
    fi
}
else
{
    if ( checkLocalInstallation R )
    then
    {
	R_VER=`$rootdir/bin/R --version | perl -nle 'print $& if m{version \d+\.\d+}'`;
	if  ( echo $R_VER | awk '{if($2>="3.3") exit 0; else exit 1}' )
	then
	{
        	echo "R $R_VER found"
	}
	else
	{
		install_R
	}
	fi
    }
    else
    {
        install_R
    }
    fi
}
fi

install_Rpackages

if ( checkSystemInstallation bedtools )
then
  echo "bedtools is found"
else
  echo "bedtools is not found"
  install_bedtools 
fi

if ( checkSystemInstallation fastq-dump )
then
  sratoolkit_VER=`fastq-dump --version | perl -nle 'print $& if m{\d\.\d\.\d}'`;
  if  ( echo $sratoolkit_VER | awk '{if($1>="2.5.4") exit 0; else exit 1}' )
  then
    echo "sratoolkit $sratoolkit_VER found"
  else
    install_sratoolkit
  fi
else
  echo "sratoolkit is not found"
  install_sratoolkit
fi

if ( checkSystemInstallation fastq-join )
then
  echo "fastq-join is found"
else
  install_ea-utils
fi

if ( checkSystemInstallation parallel )
then
  echo "GNU parallel is found"
else
  echo "GNU parallel is not found"
  install_GNU_parallel
fi

if ( checkSystemInstallation blastn )
then
  BLAST_VER=`blastn -version | grep blastn | perl -nle 'print $& if m{\d\.\d\.\d}'`;
  if ( echo $BLAST_VER | awk '{if($1>="2.4.0") exit 0; else exit 1}' )
  then
    echo "BLAST+ $BLAST_VER found"
  else
    install_BLAST+
  fi
else
  echo "BLAST+ is not found"
  install_BLAST+
fi

if ( checkSystemInstallation blastall )
then
  echo "blastall is found"
else
  echo "blastall is not found"
  install_blastall
fi

if ( checkSystemInstallation tRNAscan-SE )
then
  echo "tRNAscan-SE is found"
else
  echo "tRNAscan-SE is not found"
  install_tRNAscan
fi

if ( checkLocalInstallation ktImportBLAST )
then
  Krona_VER=`$rootdir/bin/ktGetLibPath | perl -nle 'print $& if m{KronaTools-\d\.\d}' | perl -nle 'print $& if m{\d\.\d}'`;
  if  ( echo $Krona_VER | awk '{if($1>="2.6") exit 0; else exit 1}' )
  then
    echo "KronaTools $Krona_VER found"
  else
    install_kronatools
  fi
else
  echo "KronaTools is not found"
  install_kronatools
fi


if ( checkLocalInstallation hmmpress )
then
  echo "hmmer3 is found"
else
  echo "hmmer3 is not found"
  install_hmmer
fi

if ( checkLocalInstallation cmbuild )
then
  echo "infernal-1.1 is found"
else
  echo "infernal-1.1 is not found"
  install_infernal
fi

if ( checkLocalInstallation prokka )
then
  echo "prokka is found"
else
  echo "prokka is not found"
  install_prokka
fi

if [ -x $rootdir/thirdParty/RATT/start.ratt.sh   ]
then
  echo "RATT is found"
else
  echo "RATT is not found"
  install_RATT
fi

if ( checkSystemInstallation barrnap )
then
  echo "barrnap is found"
else
  echo "barrnap is not found"
  install_barrnap
fi

if ( checkSystemInstallation glimmer3 )
then
  echo "glimmer is found"
else
  echo "glimmer is not found"
  install_glimmer
fi

if ( checkSystemInstallation prodigal )
then
  echo "prodigal is found"
else
  echo "prodigal is not found"
  install_prodigal
fi

if ( checkSystemInstallation aragorn )
then
  echo "aragorn is found"
else
  echo "aragorn is not found"
  install_aragorn
fi

if ( checkSystemInstallation tbl2asn.orig )
then
  echo "tbl2asn is found"
else
  echo "tbl2asn is not found"
  install_tbl2asn
fi

if ( checkLocalInstallation ShortBRED/shortbred_quantify.py )
then
  echo "ShortBRED is found"
else
  echo "ShortBRED is not found"
  install_ShortBRED
fi


if ( checkLocalInstallation kraken )
then
  echo "kraken is found"
else
  echo "kraken is not found"
  install_kraken
fi

if ( checkSystemInstallation tabix )
then
  echo "tabix is found"
else
  echo "tabix is not found"
  install_tabix
fi

if ( checkSystemInstallation bgzip )
then
  echo "bgzip is found"
else
  echo "bgzip is not found"
  install_tabix
fi

if ( checkSystemInstallation bowtie2 )
then
  bowtie_VER=`bowtie2 --version | grep bowtie | perl -nle 'print $& if m{version \d+\.\d+\.\d+}'`;
  if  ( echo $bowtie_VER | awk '{if($1>="2.2.4") exit 0; else exit 1}' )
  then 
    echo "bowtie2 $bowtie_VER found"
  else
    install_bowtie2
  fi
else
  echo "bowtie2 is not found"
  install_bowtie2
fi

if ( checkSystemInstallation rapsearch2 )
then
  rapsearch_VER=`rapsearch2 2>&1| grep 'rapsearch v2' | perl -nle 'print $& if m{\d+\.\d+}'`;
  if  ( echo $rapsearch_VER | awk '{if($1>="2.23") exit 0; else exit 1}' )
  then
    echo "RAPSearch2 $rapsearch_VER found"
  else
    install_RAPSearch2
  fi

else
  echo "RAPSearch2 is not found"
  install_RAPSearch2
fi

if ( checkLocalInstallation bwa )
then
  echo "bwa is found"
else
  echo "bwa is not found"
  install_bwa
fi

if ( checkLocalInstallation samtools )
then
  echo "samtools is found"
else
  echo "samtools is not found"
  install_samtools
fi

if ( checkLocalInstallation nucmer )
then
  echo "nucmer is found"
else
  echo "nucmer is not found"
  install_mummer
fi

if ( checkLocalInstallation wigToBigWig )
then
  echo "wigToBigWig is found"
else
  echo "wigToBigWig is not found, intall wigToBigWig"
  if [[ "$OSTYPE" == "darwin"* ]]
  then
  {
      ln -sf $rootdir/thirdParty/wigToBigWig_mac $rootdir/bin/wigToBigWig
  }
  else
  {
      ln -sf $rootdir/thirdParty/wigToBigWig $rootdir/bin/wigToBigWig
  }
  fi
fi

if ( checkLocalInstallation idba_ud )
then
  echo "idba is found"
else
  echo "idba is not found"
  install_idba
fi

if ( checkSystemInstallation spades.py )
then
  spades_VER=`spades.py 2>&1 | perl -nle 'print $& if m{\d\.\d\.\d}'`;
  if ( echo $spades_VER | awk '{if($1>="3.7.1") exit 0; else exit 1}' )
  then
    echo "SPAdes $spades_VER found"
  else
    install_spades
  fi
else
  echo "SPAdes is not found"
  install_spades
fi

if ( checkSystemInstallation megahit  )
then
  ## --version MEGAHIT v1.0.3
  megahit_VER=`megahit --version | perl -nle 'print $& if m{\d\.\d.\d}'`;
  if  ( echo $megahit_VER | awk '{if($1>="1.0.3") exit 0; else exit 1}' )
  then
    echo "megahit $megahit_VER found"
  else
    install_megahit
  fi
else
  echo "megahit is not found"
  install_megahit
fi

if [ -x $rootdir/thirdParty/phage_finder_v2.1/bin/phage_finder_v2.1.sh  ]
then
  echo "phage_finder_v2.1 is found"
else
  echo "phage_finder_v2 is not found"
  install_phageFinder
fi

if ( checkLocalInstallation gottcha.pl  )
then
  echo "gottcha.pl  is found"
else
  echo "gottcha.pl  is not found"
  install_gottcha
fi

if ( checkLocalInstallation metaphlan.py  )
then
  echo "metaphlan  is found"
else
  echo "metaphlan  is not found"
  install_metaphlan
fi

if ( checkLocalInstallation primer3_core  )
then
   echo "primer3  is found"
else
   echo "primer3  is not found"
   install_primer3
fi

if ( checkSystemInstallation FastTreeMP )
then
  FastTree_VER=`FastTreeMP  2>&1 | perl -nle 'print $& if m{version \d+\.\d+\.\d+}'`;
  if  ( echo $FastTree_VER | awk '{if($1>="2.1.8") exit 0; else exit 1}' )
  then
    echo "FastTreeMP is found"
  else
   install_FastTree
  fi
else
  echo "FastTreeMP is not found"
  install_FastTree
fi

if ( checkSystemInstallation raxmlHPC-PTHREADS )
then
  echo "RAxML is found"
else
  echo "RAxML is not found"
  install_RAxML
fi

#if [ -f $rootdir/lib/Parallel/ForkManager.pm ]
if ( checkPerlModule Parallel::ForkManager )
then
  echo "Perl Parallel::ForkManager is found"
else
  echo "Perl Parallel::ForkManager is not found"
  install_perl_parallel_forkmanager
fi

#if [ -f $rootdir/lib/Excel/Writer/XLSX.pm ]
if ( checkPerlModule Excel::Writer::XLSX )
then
  echo "Perl Excel::Writer::XLSX is found"
else
  echo "Perl Excel::Writer::XLSX is not found"
  install_perl_excel_writer
fi

#if [ -f $rootdir/lib/Archive/Zip.pm ]
if ( checkPerlModule Archive::Zip )
then
  echo "Perl Archive::Zip is found"
else
  echo "Perl Archive::Zip is not found"
  install_perl_archive_zip
fi

#if [ -f $rootdir/lib/JSON.pm ]
if ( checkPerlModule JSON )
then
  echo "Perl JSON is found"
else
  echo "Perl JSON is not found"
  install_perl_JSON
fi

#if [ -f $rootdir/lib/HTML/Parser.pm ]
if ( checkPerlModule HTML::Parser )
then
  echo "Perl HTML::Parser is found"
else
  echo "Perl HTML::Parser is not found"
  install_perl_html_parser
fi

#if [ -f $rootdir/lib/String/Approx.pm ]
if ( checkPerlModule String::Approx )
then
  echo "Perl String::Approx is found"
else
  echo "Perl String::Approx is not found"
  install_perl_string_approx
fi

#if [ -f $rootdir/lib/PDF/API2.pm ]
if ( checkPerlModule PDF::API2 )
then
  echo "Perl PDF:API2 is found"
else
  echo "Perl PDF:API2 is not found"
  install_perl_pdf_api2
fi

#if [ -f $rootdir/lib/HTML/Template.pm ]
if ( checkPerlModule HTML::Template )
then
  echo "Perl HTML::Template is found"
else
  echo "Perl HTML::Template is not found"
  install_perl_html_template
fi

if ( checkPerlModule Bio::Phylo )
then
  echo "Perl Bio::Phylo is found"
else
  echo "Perl Bio::Phylo is not found"
  install_perl_bio_phylo
fi

if ( checkPerlModule XML::Twig )
then
  echo "Perl XML::Twig is found"
else
  echo "Perl XML::Twig is not found"
  install_perl_xml_twig
fi

if ( checkPerlModule CGI::Session )
then
  echo "Perl CGI::Session is found"
else
  echo "Perl CGI::Session is not found"
  install_perl_cgi_session
fi

if [ -x $rootdir/edge_ui/JBrowse/bin/prepare-refseqs.pl ]
then
  echo "JBrowse is found"
else
  echo "JBrowse is not found"
  install_JBrowse
fi

if [[ "$OSTYPE" == "darwin"* ]]
then
	  ln -sf $rootdir/thirdParty/gottcha/bin/splitrim $rootdir/scripts/microbial_profiling/script/splitrim
else
	  ln -sf $rootdir/thirdParty/gottcha/bin/splitrim $rootdir/scripts/microbial_profiling/script/splitrim
fi

cd $rootdir

mkdir -p $rootdir/edge_ui/data
perl $rootdir/edge_ui/cgi-bin/edge_build_list.pl $rootdir/edge_ui/data/Host/* > $rootdir/edge_ui/data/host_list.json
perl $rootdir/edge_ui/cgi-bin/edge_build_list.pl -sort_by_size -basename $rootdir/database/NCBI_genomes/  > $rootdir/edge_ui/data/Ref_list.json

echo "Setting up EDGE_input"
if [ -d $rootdir/edge_ui/EDGE_input/ ]
then
    rsync -a $rootdir/deployment/public $rootdir/edge_ui/EDGE_input/
    ln -sf $rootdir/testData $rootdir/edge_ui/EDGE_input/public/data/
else
	mkdir -p $HOME/EDGE_input
	rm -rf $rootdir/edge_ui/EDGE_input
	ln -sf $HOME/EDGE_input $rootdir/edge_ui/EDGE_input
	rsync -a $rootdir/deployment/public $rootdir/edge_ui/EDGE_input/
   	ln -sf $rootdir/testData $rootdir/edge_ui/EDGE_input/public/data/
fi
if [ ! -d $rootdir/edge_ui/EDGE_output/ ]
then
   	echo "Setting up EDGE_output/"
   	mkdir -p $HOME/EDGE_output
	rm -rf $rootdir/edge_ui/EDGE_output
	ln -sf $HOME/EDGE_output $rootdir/edge_ui/EDGE_output
fi


# this may need sudo access
#matplotlibrc=`python -c 'import matplotlib as m; print m.matplotlib_fname()' 2>&1`
#if [ -n $matplotlibrc ]
#then 
 #  echo ""
   #perl -i.orig -nle 's/(backend\s+:\s+\w+)/\#${1}\nbackend : Agg/; print;' $matplotlibrc
#fi

if [ -f $HOME/.bashrc ]
then
{
  echo "#Added by EDGE pipeline installation" >> $HOME/.bashrc
  echo "export EDGE_HOME=$rootdir" >> $HOME/.bashrc
  echo "export EDGE_PATH=$rootdir/bin/:$rootdir/bin/Anaconda2/bin/:$rootdir/scripts" >> $HOME/.bashrc
  echo "export PATH=\$EDGE_PATH:\$PATH:" >> $HOME/.bashrc
}
else
{
  echo "#Added by EDGE pipeline installation" >> $HOME/.bash_profile
  echo "export EDGE_HOME=$rootdir" >> $HOME/.bash_profile
  echo "export EDGE_PATH=$rootdir/bin/:$rootdir/bin/Anaconda2/bin/:$rootdir/scripts" >> $HOME/.bashrc
  echo "export PATH=\$EDGE_PATH:\$PATH:" >> $HOME/.bashrc
}
fi

sed -i.bak 's,%EDGE_HOME%,'"$rootdir"',g' $rootdir/edge_ui/sys.properties
sed -i.bak 's,%EDGE_HOME%,'"$rootdir"',g' $rootdir/edge_ui/apache_conf/edge_apache.conf
sed -i.bak 's,%EDGE_HOME%,'"$rootdir"',g' $rootdir/edge_ui/apache_conf/edge_httpd.conf

TOLCPU=`cat /proc/cpuinfo | grep processor | wc -l`;
if [ $TOLCPU -gt 0 ]
then
{
	sed -i.bak 's,%TOTAL_NUM_CPU%,'"$TOLCPU"',g' $rootdir/edge_ui/sys.properties
	DEFAULT_CPU=`echo -n $((TOLCPU/3))`;
	if [ $DEFAULT_CPU -lt 1 ]
	then
	{
		sed -i.bak 's,%DEFAULT_CPU%,'"1"',g' $rootdir/edge_ui/index.html
	}
	else
	{
		sed -i.bak 's,%DEFAULT_CPU%,'"$DEFAULT_CPU"',g' $rootdir/edge_ui/index.html
	}
	fi
}
fi

# set up a cronjob for project old files clena up
echo "01 00 * * * perl $rootdir/edge_ui/cgi-bin/edge_data_cleanup.pl" | crontab -
(crontab -l ; echo "* * * * * perl $rootdir/edge_ui/cgi-bin/edge_auto_run.pl > /dev/null 2>&1") | crontab -

echo "

All done! Please Restart the Terminal Session.

Run
./runPipeline
for usage.

Read the README
for more information!

Thanks!
"

