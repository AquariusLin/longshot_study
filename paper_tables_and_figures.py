import matplotlib as mpl
mpl.use('Agg')
from matplotlib import pyplot as plt
import pickle
import os
import gzip
import argparse
import numpy as np
import re
from collections import namedtuple


mpl.rc('legend', fontsize=9)
mpl.rc('xtick', labelsize=9)
mpl.rc('ytick', labelsize=9)
mpl.rc('axes', labelsize=9)
mpl.rc('axes', labelsize=9)
mpl.rcParams.update({'font.size': 9})
mpl.rc('lines', linewidth=1.5)
mpl.rc('mathtext',default='regular')

def parseargs():

    parser = argparse.ArgumentParser(description='this tool is meant to make precision-recall curves from RTGtools vcfeval data, that are prettier than those from RTGtools rocplot function.')
    parser.add_argument('-i', '--input_dirs', nargs='+', type = str, help='list of directories generated by RTGtools vcfeval tool', default=None)
    parser.add_argument('-l', '--labels', nargs='+', type = str, help='list of labels to associate to input_dirs', default=None)
    parser.add_argument('-o', '--output_file', nargs='?', type = str, help='PNG file to write plot to.', default=None)
    parser.add_argument('-t', '--title', nargs='?', type = str, help='title for plot', default=None)

    args = parser.parse_args()
    return args

def plot_vcfeval(dirlist, labels, output_file, title, colors=['r','#3333ff','#ccccff','#9999ff','#8080ff','#6666ff'], xlim=(0.6,1.0), ylim=(0.95,1.0), legendloc='lower left'):


    # add a small amount of padding to the xlim and ylim so that grid lines show up on the borders
    xpad = (xlim[1] - xlim[0])/100
    ypad = (ylim[1] - ylim[0])/100
    xlim = (xlim[0]-xpad, xlim[1]+xpad)
    ylim = (ylim[0]-ypad, ylim[1]+ypad)

    plt.figure();
    ax1 = plt.subplot(111);
    plt.title(title)

    if len(dirlist) > len(colors):
        print("need to define larger color pallet to plot this many datasets.")
        exit(1)

    print("LABEL QUAL F1 PREC RECALL")

    for color, path, label in zip(colors, dirlist,labels):

        total_baseline = None
        score = []
        recalls = []
        precisions = []

        with gzip.open(os.path.join(path,'snp_roc.tsv.gz'),mode='rt') as inf:

            for line in inf:
                if line[0] == '#':
                    if '#total baseline variants:' in line:
                        total_baseline = float(line.strip().split()[3])
                    continue
                else:
                    el = [float(x) for x in line.strip().split()]
                    assert(len(el) == 4)

                    score.append(el[0])
                    #assert(el[1] == el[3])

                    qual = el[0]
                    TPb = el[1]
                    TPc = el[3]
                    FN = total_baseline - el[1]
                    FP = el[2]

                    prec = TPc/(TPc+FP)
                    rec = TPb/(TPb+FN)
                    precisions.append(prec)
                    recalls.append(rec)

                    f1_score = 2.0 * ((prec * rec) / (prec + rec))

                    print("{} {} {} {} {}".format(label, qual, f1_score, prec, rec))



        plt.plot(recalls, precisions, color=color,label=label,linewidth=3,alpha=0.75)

    plt.grid(True,color='grey',linestyle='--',alpha=0.5)

    ax1.spines["top"].set_visible(False)
    ax1.spines["right"].set_visible(False)
    ax1.spines["bottom"].set_visible(False)
    ax1.spines["left"].set_visible(False)
    plt.tick_params(axis="both", which="both", bottom="off", top="off",
                labelbottom="on", left="off", right="off", labelleft="on")

    plt.xlim(xlim)
    plt.ylim(ylim)
    plt.xlabel('Recall')
    plt.ylabel('Precision')
    plt.legend(loc=legendloc)
    plt.tight_layout()
    ax1.set_axisbelow(True)
    plt.savefig(output_file)


# input:
# vcfeval_dir: directory containing vcfeval output
# gq_cutoff: a Genotype Quality value to set as the cutoff for variants e.g. 30 or 50
# output:
# (precision, recall) : the precision and recall values for variants above the GQ cutoff
def get_precision_recall(vcfeval_dir, gq_cutoff):

    total_baseline = None
    score = []
    recall = None
    precision = None
    qual = None

    with gzip.open(os.path.join(vcfeval_dir,'snp_roc.tsv.gz'),mode='rt') as inf:

        for line in inf:
            if line[0] == '#':
                if '#total baseline variants:' in line:
                    total_baseline = float(line.strip().split()[3])
                continue
            else:
                el = [float(x) for x in line.strip().split()]
                assert(len(el) == 4)

                score.append(el[0])

                new_qual = float(el[0])
                TPb = el[1]
                TPc = el[3]
                FN = total_baseline - el[1]
                FP = el[2]

                if new_qual < gq_cutoff:
                    break

                qual = new_qual
                precision = TPc/(TPc+FP)
                recall = TPb/(TPb+FN)

    # this should be true for large enough datasets, like we will look at,
    # and it's a nice sanity check
    assert(qual - gq_cutoff >= 0)
    assert(qual - gq_cutoff < 1.0)
    assert(precision != None)
    assert(recall != None)

    return (precision, recall)

def plot_precision_recall_bars_simulation(pacbio_dirlist_genome, illumina_dirlist_genome, pacbio_dirlist_segdup, illumina_dirlist_segdup, gq_cutoff, labels, output_file):

    plt.figure(figsize=(7,5))
    #mpl.rcParams['axes.titlepad'] = 50

    width = 0.15
    alpha1 = 0.6


    def make_subplot(ax, ind, pacbio_vals, illumina_vals, lab_pacbio=None, lab_illumina=None, fc='#ffffff'):

        plt.bar(ind+width, pacbio_vals, color='#2200ff',
                ecolor='black', # black error bar color
                alpha=alpha1,      # transparency
                width=width,      # smaller bar width
                align='center',
                label=lab_pacbio)
        plt.bar(ind+2*width, illumina_vals, color='#ff1900',
                ecolor='black', # black error bar color
                alpha=alpha1,      # transparency
                width=width,      # smaller bar width
                align='center',
                label=lab_illumina)
        # add some text for labels, title and axes ticks
        #plt.xlim(-0.5,6)


    def prettify_plot():

        ax.yaxis.grid(True,color='grey', alpha=0.5, linestyle='--')
        ax.spines["top"].set_visible(False)
        ax.spines["right"].set_visible(False)
        ax.spines["bottom"].set_visible(False)
        ax.spines["left"].set_visible(False)
        plt.tick_params(axis="both", which="both", bottom=False, top=False,
                    labelbottom=True, left=False, right=False, labelleft=True)


    ind1 = [0,0.5,1,1.5]
    ind2 = [2.25,2.75,3.25,3.75]
    ind = ind1 + ind2

    pacbio_precisions_genome, pacbio_recalls_genome = zip(*[get_precision_recall(d, gq_cutoff) for d in pacbio_dirlist_genome])
    illumina_precisions_genome, illumina_recalls_genome = zip(*[get_precision_recall(d, gq_cutoff) for d in illumina_dirlist_genome])
    pacbio_precisions_segdup, pacbio_recalls_segdup = zip(*[get_precision_recall(d, gq_cutoff) for d in pacbio_dirlist_segdup])
    illumina_precisions_segdup, illumina_recalls_segdup = zip(*[get_precision_recall(d, gq_cutoff) for d in illumina_dirlist_segdup])

    ax = plt.subplot(211)
    make_subplot(ax,np.array(ind1), pacbio_precisions_genome, illumina_precisions_genome, lab_pacbio='PacBio + Reaper', lab_illumina='Illumina + Freebayes',fc='#e0e1e2')
    make_subplot(ax, np.array(ind2), pacbio_precisions_segdup, illumina_precisions_segdup,fc='#dddddd')
    ax.legend(loc='center left', bbox_to_anchor=(0.25,1.13),ncol=2)

    plt.ylabel("Precision")
    plt.ylim(0.99,1.0)
    prettify_plot()
    ax.set_xticks([])
    ax.set_xticklabels([])

    ax = plt.subplot(212)
    plt.ylabel("Recall\n")
    make_subplot(ax, np.array(ind1), pacbio_recalls_genome, illumina_recalls_genome,fc='#e0e1e2')
    make_subplot(ax, np.array(ind2), pacbio_recalls_segdup, illumina_recalls_segdup,fc='#dddddd')
    prettify_plot()
    ax.set_xticks(np.array(ind)+1.5*width)
    ax.set_xticklabels(labels+labels)

    #ax.set_yscale('log')
    #plt.xlim(())
    #plt.ylim((0,1.0))
    #plt.legend(loc='upper left')
    plt.xlabel(" ",labelpad=10)

    plt.tight_layout()
    plt.subplots_adjust(top=0.90)
    #t = plt.suptitle(title)

    ax.set_axisbelow(True)

    ticklabelpad = mpl.rcParams['xtick.major.pad']

    ax.annotate('coverage', xy=(-0.1,-0.03), xytext=(5, -ticklabelpad), ha='left', va='top',
                xycoords='axes fraction', textcoords='offset points')
    ax.annotate('Whole Genome', xy=(0.16,-0.15), xytext=(5, -ticklabelpad), ha='left', va='top',
                xycoords='axes fraction', textcoords='offset points')
    ax.annotate('Segmental Duplications Only', xy=(0.58,-0.15), xytext=(5, -ticklabelpad), ha='left', va='top',
                xycoords='axes fraction', textcoords='offset points')

    # credit to https://stackoverflow.com/questions/4700614/how-to-put-the-legend-out-of-the-plot
    # Shrink current axis by 20%
    box = ax.get_position()
    #ax.set_position([box.x0, box.y0, box.width * 0.85, box.height])
    # Put a legend to the right of the current axis
    #ax.legend(loc='center left', bbox_to_anchor=(1, 0.5))

    #plt.show()
    plt.savefig(output_file)

genomes_table_files = namedtuple('genomes_table_files', ['vcfeval_dir', 'vcfstats_genome', 'vcfstats_outside_GIAB', 'runtime'])
genomes_table_entry = namedtuple('genomes_table_entry', ['SNVs_called', 'precision', 'recall', 'outside_GIAB', 'runtime'])

def get_snp_count(vcfstats_file):
    snps_re = re.compile("\nSNPs\s+: (\d+)\n")
    with open(vcfstats_file,'r') as inf:
        fstr = inf.read()
        return int(snps_re.findall(fstr)[0])

def make_table_4_genomes(NA12878_table_files, NA24385_table_files,
                         NA24149_table_files, NA24143_table_files, gq_cutoff):

    def generate_table_line(table_files):

        precision, recall = get_precision_recall(table_files.vcfeval_dir, gq_cutoff)
        with open(table_files.runtime,'r') as inf:
            hh, mm, ss = inf.readline().strip().split(':')
        runtime = hh + ':' + mm

        snvs_total = get_snp_count(table_files.vcfstats_genome)
        snvs_outside_giab = get_snp_count(table_files.vcfstats_outside_GIAB)

        return genomes_table_entry(SNVs_called=snvs_total, precision=precision, recall=recall,
                                   outside_GIAB=snvs_outside_GIAB, runtime=runtime)

    NA12878 = generate_table_line(NA12878_table_files)
    NA24385 = generate_table_line(NA24385_table_files)
    NA24149 = generate_table_line(NA24149_table_files)
    NA24143 = generate_table_line(NA24143_table_files)

    s = '''
\begin{{table}}[htbp]
\centering
\begin{{tabular}}{{lrrrrr}}
\hline
Genome      & SNVs    & Precision     & Recall    & Outside GIAB  & Run time  \\
            & called    &    &  & high-confidence       & (hours)          \\
 \hline
NA12878   & {} & {:.3f} & {:.3f} & {} & {} \\
AJ son    & {} & {:.3f} & {:.3f} & {} & {} \\
AJ father & {} & {:.3f} & {:.3f} & {} & {} \\
AJ mother & {} & {:.3f} & {:.3f} & {} & {} \\
\hline
\end{{tabular}}
\caption{{{{\bf Summary of variants called on GIAB genomes.}}}}
\label{{tab:stats}}
\end{{table}}
'''.format(table.NA12878.SNVs_called, table.NA12878.precision, table.NA12878.recall, table.NA12878.outside_GIAB, table.NA12878.runtime,
           table.NA24385.SNVs_called, table.NA24385.precision, table.NA24385.recall, table.NA24385.outside_GIAB, table.NA24385.runtime,
           table.NA24149.SNVs_called, table.NA24149.precision, table.NA24149.recall, table.NA24149.outside_GIAB, table.NA24149.runtime,
           table.NA24143.SNVs_called, table.NA24143.precision, table.NA24143.recall, table.NA24143.outside_GIAB, table.NA24143.runtime)

    with open(outfile,'w') as outf:
        print(s, file=outf)

if __name__ == '__main__':
    args = parseargs()
    plot_vcfeval(args.input_dirs, args.labels, args.output_file, args.title)
