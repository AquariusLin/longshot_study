from matplotlib import pyplot as plt
import pickle
import os
import gzip
import argparse


def parseargs():

    parser = argparse.ArgumentParser(description='this tool is meant to make precision-recall curves from RTGtools vcfeval data, that are prettier than those from RTGtools rocplot function.')
    parser.add_argument('-i', '--input_dirs', nargs='+', type = str, help='list of directories generated by RTGtools vcfeval tool', default=None)
    parser.add_argument('-l', '--labels', nargs='+', type = str, help='list of labels to associate to input_dirs', default=None)
    parser.add_argument('-o', '--output_file', nargs='?', type = str, help='PNG file to write plot to.', default=None)
    parser.add_argument('-t', '--title', nargs='?', type = str, help='title for plot', default=None)

    args = parser.parse_args()
    return args

colors = ['r','#ccccff','#9999ff','#8080ff','#6666ff','#3333ff']

def plot_vcfeval(dirlist, labels, output_file, title):

    plt.figure();
    plt.title(title)

    if len(dirlist) == len(colors):
        print("need to define larger color pallet to plot this many datasets.")
        exit(1)

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

                    TPb = el[1]
                    TPc = el[3]
                    FN = total_baseline - el[1]
                    FP = el[2]

                    precisions.append(TPc/(TPc+FP))
                    recalls.append(TPb/(TPb+FN))

        plt.plot(recalls, precisions, color=color,label=label)

    plt.xlim((0.5,1.0))
    plt.ylim((0.95,1.0))
    plt.xlabel('Recall')
    plt.ylabel('Precision')
    plt.legend()
    plt.tight_layout()
    plt.savefig(output_file)

if __name__ == '__main__':
    args = parseargs()
    plot_vcfeval(args.input_dirs, args.labels, args.output_file, args.title)
