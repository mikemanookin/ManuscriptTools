import h5py
import os
import matplotlib.pyplot as plt
import seaborn as sns

def axis_to_igor(ax, filename: str, out_dir: str=None):
    ''' Save the data from a matplotlib axis to an hdf5 file that can be read by Igor.

    Parameters:
        ax: The axis to save.
        filename: The name of the file to save.
        out_dir: The directory to save the file to.
    '''
    # Create the base hdf5 file.
    hf = h5py.File(os.path.join(out_dir,filename + '.h5'), 'w')

    xlabel = plt.getp(ax.xaxis.get_label(), 'text')
    ylabel = plt.getp(ax.yaxis.get_label(), 'text')

    # Save axis labels.
    hf.create_dataset(filename + '/Xlabel', data=xlabel)
    hf.create_dataset(filename + '/Ylabel', data=ylabel)

    lines = plt.getp(ax, 'lines')
    for line in lines:
        lineLabel = plt.getp(line, 'label')
        xdata = plt.getp(line,'xdata')
        ydata = plt.getp(line, 'ydata')
        linestyle = plt.getp(line, 'linestyle')
        color = plt.getp(line, 'color')
        markerSize = plt.getp(line, 'markersize')
        hf.create_dataset(filename + '/' + lineLabel + '_X', data=xdata)
        hf.create_dataset(filename + '/' + lineLabel + '_Y', data=ydata)
        hf.create_dataset(filename + '/' + lineLabel + '_color', data=color)
        hf.create_dataset(filename + '/' + lineLabel + '_linestyle', data=linestyle)
        hf.create_dataset(filename + '/' + lineLabel + '_markerSize', data=markerSize)
    # Close the hdf5 file.
    hf.close()