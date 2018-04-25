import plot_vcfeval_precision_recall as plot_vcfeval

include: "simulation.snakefile"
include: "NA12878.snakefile"
include: "NA24385.snakefile" # AJ Son
include: "NA24143.snakefile" # AJ Mother
include: "NA24149.snakefile" # AJ Father

# DATA URLs
HG19_URL     = 'http://hgdownload.cse.ucsc.edu/goldenpath/hg19/bigZips/hg19.2bit'
HS37D5_URL     = 'ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/technical/reference/phase2_reference_assembly_sequence/hs37d5.fa.gz'
HG19_SDF_URL   = 'https://s3.amazonaws.com/rtg-datasets/references/hg19.sdf.zip'
TG_v37_SDF_URL = 'https://s3.amazonaws.com/rtg-datasets/references/1000g_v37_phase2.sdf.zip'

# PATHS TO TOOLS
FASTQUTILS = '/home/pedge/installed/ngsutils/bin/fastqutils'
TWOBITTOFASTA = 'twoBitToFa' # can be downloaded from 'http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/twoBitToFa'
SAMTOOLS       = '/opt/biotools/samtools/1.3/bin/samtools' # v1.3
MINIMAP2       = '/home/pedge/installed/minimap2/minimap2' #2.8-r703-dirty
FASTQ_DUMP     = 'fastq-dump' # v2.5.2
REAPER         = '../target/release/reaper' # v0.1
RTGTOOLS       = '/home/pedge/installed/rtg-tools-3.8.4/rtg' # v3.8.4, https://www.realtimegenomics.com/products/rtg-tools
BGZIP = 'bgzip'
TABIX = 'tabix'
FREEBAYES      = '/home/pedge/git/freebayes/bin/freebayes'

# PARAMS
chroms = ['{}'.format(i) for i in range(1,23)] + ['X']

# DEFAULT

rule all:
    input:
        'data/plots/NA24385_prec_recall_all.png',
        'data/plots/NA24143_prec_recall_all.png',
        'data/plots/NA24149_prec_recall_all.png',
        'data/plots/NA12878_prec_recall_all.png',
        'data/plots/simulation_prec_recall_all.png'

# NOTE!!! we are filtering out indels but also MNPs which we may call as multiple SNVs
# therefore this isn't totally correct and it'd probably be better to use ROC with indels+SNVs VCF.
rule vcfeval_rtgtools:
    params: job_name = 'vcfeval_rtgtools.{dataset}.{calls_name}.{chrom}',
            region_arg = lambda wildcards: '--region={}'.format(wildcards.chrom) if wildcards.chrom != 'all' else ''
    input:  calls_vcf = 'data/{dataset}/variants/{calls_name}/{chrom}.vcf.gz',
            calls_ix = 'data/{dataset}/variants/{calls_name}/{chrom}.vcf.gz.tbi',
            ground_truth = 'data/{dataset}/variants/ground_truth/ground_truth.SNVs_ONLY.vcf.gz',
            ground_truth_ix = 'data/{dataset}/variants/ground_truth/ground_truth.SNVs_ONLY.vcf.gz.tbi',
            region_filter ='data/{dataset}/variants/ground_truth/region_filter.bed',
            tg_sdf = 'data/genomes/1000g_v37_phase2.sdf'
    output: done = 'data/{dataset}/vcfeval/{calls_name}/{chrom}.done'
    shell:
        '''
        {RTGTOOLS} RTG_MEM=12g vcfeval \
        {params.region_arg} \
        -c {input.calls_vcf} \
        -b {input.ground_truth} \
        -e {input.region_filter} \
        -t {input.tg_sdf} \
        -o data/{wildcards.dataset}/vcfeval/{wildcards.calls_name}/{wildcards.chrom};
        cp data/{wildcards.dataset}/vcfeval/{wildcards.calls_name}/{wildcards.chrom}/done {output.done};
        '''

rule generate_coverage_bed:
    params: job_name = ,
    job_name = lambda wildcards: 'generate_coverage_bed.{}.cov_greater_than_{}'.format(str(wildcards.x).replace("/", "."), str(wildcards.cov))
    input:  '{x}.bam'
    output: '{x}.cov_greater_than_{cov, d+}.bed',
    shell:
        '''
        {SAMTOOLS} view -q 30 {input} -hb | \
        {BEDTOOLS} genomecov -bga -ibam - | \
        awk '$4 > 20' | \
        {BEDTOOLS} merge -i - > {output}
        '''

# NOTE!!! we are filtering out indels but also MNPs which we may call as multiple SNVs
# therefore this isn't totally correct and it'd probably be better to use ROC with indels+SNVs VCF.
rule rtg_filter_SNVs_ground_truth:
    params: job_name = 'rtg_filter_SNVs_ground_truth.{dataset}',
    input:  vcfgz = 'data/{dataset}/variants/ground_truth/ground_truth.vcf.gz'
    output: vcfgz = 'data/{dataset}/variants/ground_truth/ground_truth.SNVs_ONLY.vcf.gz',
    shell: '{RTGTOOLS} RTG_MEM=12g vcffilter --snps-only --no-index -i {input.vcfgz} -o {output.vcfgz}'

from filter_SNVs import filter_SNVs
rule filter_illumina_SNVs:
    params: job_name = 'filter_SNVs_illumina.{dataset}.chr{chrom}',
    input:  vcf = 'data/{dataset}/variants/illumina_{cov}x/{chrom}.vcf'
    output: vcf = 'data/{dataset}/variants/illumina_{cov}x.filtered/{chrom}.vcf'
    run:
        cov_filter = int(float(wildcards.cov)*1.75)
        filter_SNVs(input.vcf, output.vcf, cov_filter, density_count=10, density_len=500, density_qual=50)

rule combine_chrom:
    params: job_name = 'combine_chroms.{dataset}.{calls_name}',
    input: expand('data/{{dataset}}/variants/{{calls_name}}/{chrom}.vcf',chrom=chroms)
    output: 'data/{dataset}/variants/{calls_name}/all.vcf'
    shell:
        '''
        grep -P '^#' {input[0]} > {output}; # grep header
        cat {input} | grep -Pv '^#' >> {output}; # cat files, removing the headers.
        '''

hg19_chroms = set(['chr{}'.format(i) for i in range(1,23)] + ['chrX'])
hs37d5_chroms = set([str(i) for i in range(1,23)] + ['X'])
def remove_chr_from_vcf(in_vcf, out_vcf):
    with open(in_vcf, 'r') as inf, open(out_vcf, 'w') as outf:
        for line in inf:
            if line[0] == '#':
                print(line.strip(),file=outf)
                continue
            el = line.strip().split('\t')
            assert(el[0] in hg19_chroms)
            el[0] = el[0][3:]
            assert(el[0] in hs37d5_chroms)
            print("\t".join(el),file=outf)

rule run_reaper:
    params: job_name = 'reaper.pacbio.{aligner}.{dataset}.cov{cov}.{options}.chr{chrom}',
    input:  bam = 'data/{dataset}/aligned_reads/pacbio/pacbio.{aligner}.{chrom}.{cov}x.bam',
            bai = 'data/{dataset}/aligned_reads/pacbio/pacbio.{aligner}.{chrom}.{cov}x.bam.bai',
            hg19    = 'data/genomes/hg19.fa',
            hg19_ix = 'data/genomes/hg19.fa.fai',
            hs37d5    = 'data/genomes/hs37d5.fa',
            hs37d5_ix = 'data/genomes/hs37d5.fa.fai'
    output: vcf = 'data/{dataset}/variants/reaper.pacbio.{aligner}.{cov,\d+}x.{options}/{chrom}.vcf',
            debug = 'data/{dataset}/variants/reaper.pacbio.{aligner}.{cov,\d+}x.{options}/{chrom}.debug'
    run:
        options_str = wildcards.options.replace('_',' ')
        if wildcards.dataset == 'NA12878':
            shell('{REAPER} -r chr{wildcards.chrom} -F -d {output.debug} {options_str} --bam {input.bam} --ref {input.hg19} --out {output.vcf}.tmp')
            # remove 'chr' from reference name in vcf
            remove_chr_from_vcf(output.vcf+'.tmp',output.vcf)
        else:
            shell('{REAPER} -r {wildcards.chrom} -F -d {output.debug} {options_str} --bam {input.bam} --ref {input.hs37d5} --out {output.vcf}')

# Call 30x Illumina variants
rule call_variants_Illumina:
    params: job_name = 'call_illumina.{dataset}.{cov}x',
    input: bam = 'data/{dataset}/aligned_reads/illumina/illumina.{cov}x.bam',
            bai = 'data/{dataset}/aligned_reads/illumina/illumina.{cov}x.bam.bai',
            hs37d5 = 'data/genomes/hs37d5.fa',
            hs37d5_ix = 'data/genomes/hs37d5.fa.fai'
    output: vcf = 'data/{dataset}/variants/illumina_{cov}x/{chrom}.vcf'
    shell:
        '''
        {FREEBAYES} -f {input.hs37d5} \
        --standard-filters \
        --region {wildcards.chrom} \
         --genotype-qualities \
         {input.bam} \
          > {output.vcf}
        '''

# download hg19 reference, for the aligned pacbio reads
rule download_hg19:
    params: job_name = 'download_hg19',
            url      = HG19_URL
    output: 'data/genomes/hg19.fa'
    shell:
        '''
        wget {params.url} -O {output}.2bit
        {TWOBITTOFASTA} {output}.2bit {output}
        '''

# download hg19 reference, for the aligned pacbio reads
rule download_hg19_sdf:
    params: job_name = 'download_hg19_sdf',
    output: 'data/genomes/hg19.sdf'
    shell:
        '''
        wget {HG19_SDF_URL} -O {output}.zip;
        unzip {output}.zip -d data/genomes
        '''

# download 1000g_v37_phase2 sdf, for the aligned pacbio reads
rule download_1000g_v37_phase2_sdf:
    params: job_name = 'download_1000g_v37_phase2_sdf',
    output: 'data/genomes/1000g_v37_phase2.sdf'
    shell:
        '''
        wget {TG_v37_SDF_URL} -O {output}.zip;
        unzip {output}.zip -d data/genomes
        '''

rule download_HS37D5:
    params: job_name = 'download_hs37d',
    output: 'data/genomes/hs37d5.fa'
    shell: 'wget {HS37D5_URL} -O {output}.gz; gunzip {output}.gz'

rule index_vcf:
    params: job_name = lambda wildcards: 'tabix_vcf.{}'.format(str(wildcards.x).replace("/", "."))
    input:  '{x}.vcf.gz'
    output: '{x}.vcf.gz.tbi'
    shell:  '{TABIX} -p vcf {input}'

# bgzip vcf
rule bgzip_vcf_calls:
    params: job_name = 'bgzip_vcf_calls.{dataset}.{calls_name}.{chrom}'
    input:  'data/{dataset}/variants/{calls_name}/{chrom}.vcf'
    output: 'data/{dataset}/variants/{calls_name}/{chrom,(all|X|\d+)}.vcf.gz'
    shell:  '{BGZIP} -c {input} > {output}'

# bgzip vcf
rule bgzip_ground_truth:
    params: job_name = 'bgzip_ground_truth.{dataset}'
    input:  'data/{dataset}/variants/ground_truth/ground_truth.vcf'
    output: 'data/{dataset}/variants/ground_truth/ground_truth.vcf.gz'
    shell:  '{BGZIP} -c {input} > {output}'

# gunzip fastq
rule gunzip_fastq:
    params: job_name = lambda wildcards: 'gunzip_fastq.{}'.format(str(wildcards.x).replace("/", "."))
    input:  '{x}.fastq.gz'
    output: '{x}.fastq'
    shell:  'gunzip {input}'

# index fasta reference
rule index_fasta:
    params: job_name = lambda wildcards: 'index_fa.{}'.format(str(wildcards.x).replace("/", "."))
    input:  fa  = '{x}.fa'
    output: fai = '{x}.fa.fai'
    shell:  '{SAMTOOLS} faidx {input.fa}'

rule index_bam:
    params: job_name = lambda wildcards: 'index_bam.{}'.format(str(wildcards.x).replace("/", "."))
    input:  bam = '{x}.bam'
    output: bai = '{x}.bam.bai'
    shell:  '{SAMTOOLS} index {input.bam} {output.bai}'

# BWA index
rule bwa_index_fasta:
    params: job_name = lambda wildcards: 'bwa_index_fasta.{}'.format(str(wildcards.x).replace("/", "."))
    input:  '{x}.fa'
    output: '{x}.fa.bwt'
    shell: '{BWA} index {input}'

rule backup_reaper_run:
    shell:
        '''
        rm -rf data/BAK
        mkdir data/BAK

        mkdir -p data/BAK/NA12878/variants
        mkdir -p data/BAK/NA12878/vcfeval
        mv data/NA12878/variants/reaper* data/BAK/NA12878/variants
        mv data/NA12878/vcfeval/reaper* data/BAK/NA12878/vcfeval

        mkdir -p data/BAK/NA24143/variants
        mkdir -p data/BAK/NA24143/vcfeval
        mv data/NA24143/variants/reaper* data/BAK/NA24143/variants
        mv data/NA24143/vcfeval/reaper* data/BAK/NA24143/vcfeval

        mkdir -p data/BAK/NA24149/variants
        mkdir -p data/BAK/NA24149/vcfeval
        mv data/NA24149/variants/reaper* data/BAK/NA24149/variants
        mv data/NA24149/vcfeval/reaper* data/BAK/NA24149/vcfeval

        mkdir -p data/BAK/NA24385/variants
        mkdir -p data/BAK/NA24385/vcfeval
        mv data/NA24385/variants/reaper* data/BAK/NA24385/variants
        mv data/NA24385/vcfeval/reaper* data/BAK/NA24385/vcfeval

        mkdir data/BAK/plots
        mv data/plots data/BAK/plots
        '''
