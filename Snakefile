import paper_tables_and_figures as ptf
from analyze_variants import analyze_variants
import time
from replace_empty_gt_with_reference import replace_empty_gt_with_reference

include: "simulation.snakefile"
include: "NA12878.snakefile"
include: "NA24385.snakefile" # AJ Son
include: "NA24143.snakefile" # AJ Mother
include: "NA24149.snakefile" # AJ Father
include: "aj_trio.snakefile" #
include: "paper_tables_and_figures.snakefile"

# DATA URLs
HG19_URL     = 'http://hgdownload.cse.ucsc.edu/goldenpath/hg19/bigZips/hg19.2bit'
HS37D5_URL     = 'ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/technical/reference/phase2_reference_assembly_sequence/hs37d5.fa.gz'
HG19_SDF_URL   = 'https://s3.amazonaws.com/rtg-datasets/references/hg19.sdf.zip'
TG_v37_SDF_URL = 'https://s3.amazonaws.com/rtg-datasets/references/1000g_v37_phase2.sdf.zip'

# PATHS TO TOOLS
FASTQUTILS = '/home/pedge/installed/ngsutils/bin/fastqutils'
TWOBITTOFASTA = 'twoBitToFa' # can be downloaded from 'http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/twoBitToFa'
SAMTOOLS       = 'samtools' # v1.3
FASTQ_DUMP     = 'fastq-dump' # v2.5.2
REAPER         = '../target/release/reaper' # v0.1
RTGTOOLS       = 'rtg' #'/home/pedge/installed/rtg-tools-3.8.4/rtg' # v3.8.4, https://www.realtimegenomics.com/products/rtg-tools
BGZIP = 'bgzip'
TABIX = 'tabix'
FREEBAYES      = '/home/pedge/git/freebayes/bin/freebayes'
SIMLORD = '/home/pedge/installed/opt/python/bin/simlord'
DWGSIM = '/home/pedge/git/DWGSIM/dwgsim'
BWA = '/home/pedge/installed/bwa'
BLASR = 'blasr'
SAWRITER = 'sawriter'
NGMLR = 'ngmlr'
MINIMAP2 = 'minimap2'
BCFTOOLS = '/opt/biotools/bcftools/bin/bcftools'
PYFAIDX = '/home/pedge/installed/opt/python/bin/faidx'
chroms = ['{}'.format(i) for i in range(1,23)] + ['X']
BEDTOOLS = 'bedtools' # v 2.27

# DEFAULT
rule all:
    input:
        'data/plots/NA24385_prec_recall_1.png',
        'data/plots/NA24143_prec_recall_1.png',
        'data/plots/NA24149_prec_recall_1.png',
        'data/plots/NA12878_prec_recall_1.png',
        'data/plots/simulation_prec_recall_1.png',
        'data/plots/simulation_prec_recall_in_segdups_1.png',
        'data/plots/chr1_simulated_60x_pacbio_mismapped_read_distribution.segdup.png',
        'data/plots/chr1_simulated_60x_pacbio_mismapped_read_distribution.png',
        'data/aj_trio/duplicated_regions/trio_shared_variant_sites/mendelian/1.vcf.gz',
        'data/output/four_GIAB_genomes_table.1.GQ50.tex',
        'data/plots/simulation_pr_barplot_genome_vs_segdup.1.GQ50.png',
        'data/plots/effect_of_haplotyping.giab_individuals.prec_recall_1.png',
        'data/plots/PR_curve_3_mappers_AJ_father_chr20.png',
        #'data/plots/compare_mappers_reaper_in_segdups_simulation_1.png'
        'data/plots/compare_mappers_reaper_in_segdups_simulation_1.png',
        'data/plots/simulation_prec_recall_ngmlr_1.png',
        'data/output/variant_analysis_fp_fn__NA12878__reaper.pacbio.blasr.44x.-z__1.tex',
        'data/output/variant_analysis_fp_fn__NA24385__reaper.pacbio.ngmlr.69x.-z__1.tex',
        'data/output/variant_analysis_fp_fn__NA24149__reaper.pacbio.ngmlr.32x.-z__1.tex',
        'data/output/variant_analysis_fp_fn__NA24143__reaper.pacbio.ngmlr.30x.-z__1.tex'
        #'data/NA12878/vcfeval/reaper.pacbio.blasr.30x.-z_-Q_1/1.done',
        #'data/NA12878/vcfeval/reaper.pacbio.blasr.30x.-z_-Q_10/1.done',
        #'data/NA12878/vcfeval/reaper.pacbio.blasr.30x.-z_-Q_20/1.done',
        #'data/NA12878/vcfeval/reaper.pacbio.blasr.30x.-z_-Q_30/1.done',
        #'data/NA12878/vcfeval/reaper.pacbio.blasr.30x.-z_-Q_40/1.done',
        #'data/NA12878/vcfeval/reaper.pacbio.blasr.30x.-z_-Q_50/1.done',
        #'data/NA12878/vcfeval/reaper.pacbio.blasr.20x.-z_-Q_1/1.done',
        #'data/NA12878/vcfeval/reaper.pacbio.blasr.20x.-z_-Q_10/1.done',
        #'data/NA12878/vcfeval/reaper.pacbio.blasr.20x.-z_-Q_20/1.done',
        #'data/NA12878/vcfeval/reaper.pacbio.blasr.20x.-z_-Q_30/1.done',
        #'data/NA12878/vcfeval/reaper.pacbio.blasr.20x.-z_-Q_40/1.done',
        #'data/NA12878/vcfeval/reaper.pacbio.blasr.20x.-z_-Q_50/1.done',
        #'data/NA12878/vcfeval/reaper.pacbio.blasr.10x.-z_-Q_1/1.done',
        #'data/NA12878/vcfeval/reaper.pacbio.blasr.10x.-z_-Q_10/1.done',
        #'data/NA12878/vcfeval/reaper.pacbio.blasr.10x.-z_-Q_20/1.done',
        #'data/NA12878/vcfeval/reaper.pacbio.blasr.10x.-z_-Q_30/1.done',
        #'data/NA12878/vcfeval/reaper.pacbio.blasr.10x.-z_-Q_40/1.done',
        #'data/NA12878/vcfeval/reaper.pacbio.blasr.10x.-z_-Q_50/1.done',
        #'data/NA24149/vcfeval/reaper.pacbio.blasr.32x.-z/1.done',
        #'data/NA24149/vcfeval/reaper.pacbio.blasr.32x.-z/20.done',
        #'data/NA12878/vcfeval/reaper.pacbio.blasr.30x.-z_-p/1.done',
        #'data/NA12878/vcfeval/reaper.pacbio.blasr.44x.-z_-p/1.done',

rule vcfeval_rtgtools_no_haplotype_info:
    params: job_name = 'vcfeval_rtgtools_no_haplotype_info.{dataset}.{calls_name}.{chrom}',
            region_arg = lambda wildcards: '--region={}'.format(wildcards.chrom) if wildcards.chrom != 'all' else ''
    input:  calls_vcf = 'data/{dataset}/variants/{calls_name}/{chrom}.debug/2.0.realigned_genotypes.vcf.gz',
            calls_ix = 'data/{dataset}/variants/{calls_name}/{chrom}.debug/2.0.realigned_genotypes.vcf.gz.tbi',
            ground_truth = 'data/{dataset}/variants/ground_truth/ground_truth.DECOMPOSED.SNVs_ONLY.vcf.gz',
            ground_truth_ix = 'data/{dataset}/variants/ground_truth/ground_truth.DECOMPOSED.SNVs_ONLY.vcf.gz.tbi',
            region_filter ='data/{dataset}/variants/ground_truth/region_filter.bed',
            tg_sdf = 'data/genomes/1000g_v37_phase2.sdf'
    output: done = 'data/{dataset}/vcfeval_no_haps/{calls_name}/{chrom}.done'
    shell:
        '''
        rm -rf data/{wildcards.dataset}/vcfeval_no_haps/{wildcards.calls_name}/{wildcards.chrom}
        {RTGTOOLS} RTG_MEM=12g vcfeval \
        {params.region_arg} \
        -c {input.calls_vcf} \
        -b {input.ground_truth} \
        -e {input.region_filter} \
        -t {input.tg_sdf} \
        -o data/{wildcards.dataset}/vcfeval_no_haps/{wildcards.calls_name}/{wildcards.chrom};
        cp data/{wildcards.dataset}/vcfeval_no_haps/{wildcards.calls_name}/{wildcards.chrom}/done {output.done};
        '''

rule vcfeval_rtgtools:
    params: job_name = 'vcfeval_rtgtools.{dataset}.{calls_name}.{chrom}',
            region_arg = lambda wildcards: '--region={}'.format(wildcards.chrom) if wildcards.chrom != 'all' else ''
    input:  calls_vcf = 'data/{dataset}/variants/{calls_name}/{chrom}.vcf.gz',
            calls_ix = 'data/{dataset}/variants/{calls_name}/{chrom}.vcf.gz.tbi',
            ground_truth = 'data/{dataset}/variants/ground_truth/ground_truth.DECOMPOSED.SNVs_ONLY.vcf.gz',
            ground_truth_ix = 'data/{dataset}/variants/ground_truth/ground_truth.DECOMPOSED.SNVs_ONLY.vcf.gz.tbi',
            region_filter ='data/{dataset}/variants/ground_truth/region_filter.bed',
            tg_sdf = 'data/genomes/1000g_v37_phase2.sdf'
    output: done = 'data/{dataset}/vcfeval/{calls_name}/{chrom}.done'
    shell:
        '''
        rm -rf data/{wildcards.dataset}/vcfeval/{wildcards.calls_name}/{wildcards.chrom}
        {RTGTOOLS} RTG_MEM=12g vcfeval \
        {params.region_arg} \
        -c {input.calls_vcf} \
        -b {input.ground_truth} \
        -e {input.region_filter} \
        -t {input.tg_sdf} \
        -o data/{wildcards.dataset}/vcfeval/{wildcards.calls_name}/{wildcards.chrom};
        cp data/{wildcards.dataset}/vcfeval/{wildcards.calls_name}/{wildcards.chrom}/done {output.done};
        '''

rule rtg_decompose_variants_ground_truth:
    params: job_name = 'rtg_decompose_variants_ground_truth.{dataset}',
    input:  vcfgz = 'data/{dataset}/variants/ground_truth/ground_truth.vcf.gz',
            tbi   = 'data/{dataset}/variants/ground_truth/ground_truth.vcf.gz.tbi'
    output: vcfgz = 'data/{dataset}/variants/ground_truth/ground_truth.DECOMPOSED.vcf.gz',
    shell: '{RTGTOOLS} RTG_MEM=12g vcfdecompose --break-mnps --break-indels -i {input.vcfgz} -o {output.vcfgz}'

rule analyze_variants:
    params: job_name = 'analyze_variants.{dataset}.{chrom}.{calls_name}',
    input:  fp_calls = 'data/{dataset}/vcfeval/{calls_name}/{chrom}/fp.vcf.gz',
            fn_calls = 'data/{dataset}/vcfeval/{calls_name}/{chrom}/fn.vcf.gz',
            ground_truth_vcfgz = 'data/{dataset}/variants/ground_truth/ground_truth.vcf.gz',
            ground_truth_bed = 'data/{dataset}/variants/ground_truth/region_filter.bed.gz',
            ground_truth_bed_ix = 'data/{dataset}/variants/ground_truth/region_filter.bed.gz.tbi',
            str_bed = 'genome_tracks/STRs_1000g.bed.gz',
            str_bed_ix = 'genome_tracks/STRs_1000g.bed.gz.tbi',
            line_bed = 'genome_tracks/LINEs_1000g.bed.gz',
            line_bed_ix = 'genome_tracks/LINEs_1000g.bed.gz.tbi',
            sine_bed = 'genome_tracks/SINEs_1000g.bed.gz',
            sine_bed_ix = 'genome_tracks/SINEs_1000g.bed.gz.tbi',
            ref_fa = 'data/genomes/hs37d5.fa',
            ref_fai = 'data/genomes/hs37d5.fa.fai'
    output: tex = 'data/output/variant_analysis_fp_fn__{dataset}__{calls_name}__{chrom}.tex'
    run:
        analyze_variants(chrom_name = wildcards.chrom,
                         fp_calls_vcfgz = input.fp_calls,
                         fn_calls_vcfgz = input.fn_calls,
                         ground_truth_vcfgz = input.ground_truth_vcfgz,
                         ground_truth_bed_file = input.ground_truth_bed,
                         str_tabix_bed_file = input.str_bed,
                         line_tabix_bed_file = input.line_bed,
                         sine_tabix_bed_file = input.sine_bed,
                         ref_fa = input.ref_fa,
                         output_file = output.tex)

rule rtg_filter_SNVs_ground_truth:
    params: job_name = 'rtg_filter_SNVs_ground_truth.{dataset}',
    input:  vcfgz = 'data/{dataset}/variants/ground_truth/ground_truth.DECOMPOSED.vcf.gz',
            tbi   = 'data/{dataset}/variants/ground_truth/ground_truth.DECOMPOSED.vcf.gz.tbi'
    output: vcfgz = 'data/{dataset}/variants/ground_truth/ground_truth.DECOMPOSED.SNVs_ONLY.vcf.gz',
    shell: '{RTGTOOLS} RTG_MEM=12g vcffilter --snps-only -i {input.vcfgz} -o {output.vcfgz}'

from filter_SNVs import filter_SNVs
rule filter_illumina_SNVs:
    params: job_name = 'filter_SNVs_illumina.{dataset}.chr{chrom}',
    input:  vcf = 'data/{dataset}/variants/illumina_{cov}x/{chrom}.vcf'
    output: vcf = 'data/{dataset}/variants/illumina_{cov}x.filtered/{chrom,(\d+|X|Y)}.vcf'
    run:
        cov_filter = int(float(wildcards.cov)*2)
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

rule add_runtimes:
    params: job_name = 'add_runtimes.{dataset}.{calls_name}',
    input: expand('data/{{dataset}}/variants/{{calls_name}}/{chrom}.vcf.runtime',chrom=chroms)
    output: 'data/{dataset}/variants/{calls_name}/all.vcf.runtime'
    run:
        t = datetime.timedelta(hours=0, minutes=0, seconds=0)
        for f in input:
            with open(f,'r') as inf:
                hh, mm, ss = [float(val) for val in inf.readline().strip().split(':')] # credit to https://stackoverflow.com/questions/19234771/adding-a-timedelta-of-the-type-hh-mm-ss-ms-to-a-datetime-object
                t += datetime.timedelta(hours=hh, minutes=mm, seconds=ss)

        runtime = time.strftime('%H:%M:%S', time.gmtime(t))
        with open(output,'w') as outf:
            print(runtime,file=outf)


rule run_reaper:
    params: job_name = 'reaper.pacbio.{aligner}.{dataset}.cov{cov}.{options}.chr{chrom}',
    input:  bam = 'data/{dataset}/aligned_reads/pacbio/pacbio.{aligner}.{chrom}.{cov}x.bam',
            bai = 'data/{dataset}/aligned_reads/pacbio/pacbio.{aligner}.{chrom}.{cov}x.bam.bai',
            hg19    = 'data/genomes/hg19.fa',
            hg19_ix = 'data/genomes/hg19.fa.fai',
            hs37d5    = 'data/genomes/hs37d5.fa',
            hs37d5_ix = 'data/genomes/hs37d5.fa.fai'
    output: vcf = 'data/{dataset}/variants/reaper.pacbio.{aligner}.{cov,\d+}x.{options}/{chrom,(\d+|X|Y)}.vcf',
            debug = 'data/{dataset}/variants/reaper.pacbio.{aligner}.{cov,\d+}x.{options}/{chrom}.debug',
            no_hap_vcf = 'data/{dataset}/variants/reaper.pacbio.{aligner}.{cov,\d+}x.{options}/{chrom}.debug/2.0.realigned_genotypes.vcf',
            runtime = 'data/{dataset}/variants/reaper.pacbio.{aligner}.{cov,\d+}x.{options}/{chrom,(\d+|X|Y)}.vcf.runtime'
    run:
        options_str = wildcards.options.replace('_',' ')
        if wildcards.dataset == 'NA12878':
            t1 = time.time()
            shell('{REAPER} -r chr{wildcards.chrom} -F -d {output.debug} {options_str} --bam {input.bam} --ref {input.hg19} --out {output.vcf}.tmp')
            t2 = time.time()
            # remove 'chr' from reference name in vcf
            remove_chr_from_vcf(output.vcf+'.tmp',output.vcf)
            # remove 'chr' from no-haplotype version of vcf
            remove_chr_from_vcf(output.no_hap_vcf, output.no_hap_vcf+'.tmp')
            shell('mv {output.no_hap_vcf}.tmp {output.no_hap_vcf}')
        else:
            t1 = time.time()
            shell('{REAPER} -r {wildcards.chrom} -F -d {output.debug} {options_str} -s {wildcards.dataset} --bam {input.bam} --ref {input.hs37d5} --out {output.vcf}')
            t2 = time.time()

        runtime = time.strftime('%H:%M:%S', time.gmtime(t2-t1))
        with open(output.runtime,'w') as outf:
            print(runtime,file=outf)

# Call 30x Illumina variants
rule call_variants_Illumina:
    params: job_name = 'call_illumina.{dataset}.{cov}x',
    input: bam = 'data/{dataset}/aligned_reads/illumina/illumina.{cov}x.bam',
            bai = 'data/{dataset}/aligned_reads/illumina/illumina.{cov}x.bam.bai',
            hs37d5 = 'data/genomes/hs37d5.fa',
            hs37d5_ix = 'data/genomes/hs37d5.fa.fai'
    output: vcf = 'data/{dataset}/variants/illumina_{cov}x/{chrom,(\d+|X|Y)}.vcf',
            runtime = 'data/{dataset}/variants/illumina_{cov}x/{chrom,(\d+|X|Y)}.vcf.runtime'
    run:
        t1 = time.time()
        shell('''
        {FREEBAYES} -f {input.hs37d5} \
        --standard-filters \
        --region {wildcards.chrom} \
         --genotype-qualities \
         {input.bam} \
          > {output.vcf}
        ''')
        t2 = time.time()
        runtime = time.strftime('%H:%M:%S', time.gmtime(t2-t1))
        with open(output.runtime,'w') as outf:
            print(runtime,file=outf)


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
    params: job_name = 'download_hs37d5',
    output: 'data/genomes/hs37d5.fa'
    shell: 'wget {HS37D5_URL} -O {output}.gz; gunzip {output}.gz'

rule convert_genome_track_to_1000g:
    params: job_name = 'convert_genome_track_to_1000g.{track}',
    input: track = 'genome_tracks/{track}_hg19.bed.gz',
           names = 'genome_tracks/names.txt'
    output: track = 'genome_tracks/{track}_1000g.bed.gz'
    shell:
        '''
        gunzip -c {input.track} | \
        python3 filter_bed_chroms.py | \
        {BEDTOOLS} sort -g {input.names} | \
        bgzip -c > {output.track}
        '''

rule tabix_index:
    params: job_name = lambda wildcards: 'tabix_index.{}'.format(str(wildcards.x).replace("/", "."))
    input:  '{x}.{filetype}.gz'
    output: '{x}.{filetype}.gz.tbi'
    shell:  '{TABIX} -f -p {wildcards.filetype} {input}'

# bgzip vcf
rule bgzip_vcf_calls:
    params: job_name = 'bgzip_vcf_calls.{dataset}.{calls_name}.{chrom}'
    input:  'data/{dataset}/variants/{calls_name}/{chrom}.vcf'
    output: 'data/{dataset}/variants/{calls_name}/{chrom,(all|X|\d+)}.vcf.gz'
    shell:  '{BGZIP} -c {input} > {output}'

# bgzip vcf
rule bgzip_debug_vcf_calls:
    params: job_name = 'bgzip_no_hap_vcf_calls.{x}.{dataset}.{calls_name}.{chrom}'
    input:  'data/{dataset}/variants/{calls_name}/{chrom}.debug/{x}.vcf'
    output: 'data/{dataset}/variants/{calls_name}/{chrom,(all|X|\d+)}.debug/{x}.vcf.gz'
    shell:  '{BGZIP} -c {input} > {output}'

# bgzip vcf
rule bgzip_ground_truth:
    params: job_name = 'bgzip_ground_truth.{dataset}'
    input:  'data/{dataset}/variants/ground_truth/ground_truth.vcf'
    output: 'data/{dataset}/variants/ground_truth/ground_truth.vcf.gz'
    shell:  '{BGZIP} -c {input} > {output}'

# bgzip bed
rule bgzip_bed:
    params: job_name = 'bgzip_bed.{dataset}.{calls_name}'
    input: 'data/{dataset}/variants/{calls_name}/region_filter.bed'
    output: 'data/{dataset}/variants/{calls_name}/region_filter.bed.gz'
    shell:  '{BGZIP} -c {input} > {output}'

# gunzip fasta
rule gunzip_fasta:
    params: job_name = lambda wildcards: 'gunzip_fasta.{}'.format(str(wildcards.x).replace("/", "."))
    input:  '{x}.fa.gz'
    output: '{x}.fa'
    shell:  'gunzip {input}'

# gunzip_bed
rule gunzip_bed:
    params: job_name = lambda wildcards: 'gunzip_bed.{}'.format(str(wildcards.x).replace("/", "."))
    input:  '{x}.bed.gz'
    output: '{x}.bed'
    shell:  'gunzip -c {input} > {output}'

# index fasta reference
rule index_fasta:
    params: job_name = lambda wildcards: 'index_fa.{}'.format(str(wildcards.x).replace("/", "."))
    input:  fa  = '{x}.fa'
    output: fai = '{x}.fa.fai'
    shell:  '{SAMTOOLS} faidx {input.fa}'

# index fasta for minimap2
rule index_minimap2:
    params: job_name = lambda wildcards: 'index_minimap2.{}'.format(str(wildcards.x).replace("/", "."))
    input:  fa  = '{x}.fa'
    output: mmi = '{x}.fa.mmi'
    shell:  '{MINIMAP2} -d {output.mmi} {input.fa}'

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
