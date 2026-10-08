import h5py
import os
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns


def _unique_label(label, used):
    ''' Return a label that has not been used yet, appending a numeric suffix
    to duplicates (e.g., plotting a 2D array creates several lines that all
    share one label, which would otherwise collide in the HDF5 file). '''
    if label not in used:
        used[label] = 0
        return label
    used[label] += 1
    return label + str(used[label])

def axis_to_igor(ax, filename: str, out_dir: str=None):
    ''' Save the data from a matplotlib axis to an hdf5 file that can be read by Igor.

    Parameters:
        ax: The axis to save.
        filename: The name of the file to save.
        out_dir: The directory to save the file to.
    '''
    # Create the base hdf5 file.
    with h5py.File(os.path.join(out_dir,filename + '.h5'), 'w') as hf:

        xlabel = plt.getp(ax.xaxis.get_label(), 'text')
        ylabel = plt.getp(ax.yaxis.get_label(), 'text')

        # Save axis labels.
        hf.create_dataset(filename + '/Xlabel', data=xlabel)
        hf.create_dataset(filename + '/Ylabel', data=ylabel)

        lines = plt.getp(ax, 'lines')
        usedLabels = dict()
        for line in lines:
            lineLabel = _unique_label(plt.getp(line, 'label'), usedLabels)
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


def image_to_igor(ax, filename: str, out_dir: str=None):
    ''' Save the image(s) from a matplotlib axis (ax.imshow) to an hdf5 file
    that can be read by Igor Pro (load with the MakeImageFig macro in
    DisplayImageFromPython.ipf).

    The rendered RGB values are exported (so colormapped scalar images come
    across exactly as displayed), as an (nx, ny, 3) unsigned-byte array that
    Igor treats as a direct-color RGB image wave. Any lines on the axis are
    exported as well, using the same conventions as axis_to_igor.

    Parameters:
        ax: The axis to save.
        filename: The name of the file to save.
        out_dir: The directory to save the file to.
    '''
    # Create the base hdf5 file.
    with h5py.File(os.path.join(out_dir, filename + '.h5'), 'w') as hf:

        xlabel = plt.getp(ax.xaxis.get_label(), 'text')
        ylabel = plt.getp(ax.yaxis.get_label(), 'text')

        # Save axis labels.
        hf.create_dataset(filename + '/Xlabel', data=xlabel)
        hf.create_dataset(filename + '/Ylabel', data=ylabel)

        # Save axis direction (imshow normally inverts the y axis).
        hf.create_dataset(filename + '/XReversed', data=int(ax.xaxis_inverted()))
        hf.create_dataset(filename + '/YReversed', data=int(ax.yaxis_inverted()))

        # Save the images.
        images = ax.get_images()
        for count, im in enumerate(images):
            imgLabel = plt.getp(im, 'label')
            if (not imgLabel) or imgLabel.startswith('_'):
                imgLabel = 'image' if len(images) == 1 else 'image' + str(count)

            # Rendered RGBA as displayed (applies colormap/norm if the data
            # were scalar; passes RGB(A) arrays through). uint8, 0-255.
            rgba = im.to_rgba(im.get_array(), bytes=True)
            rgb = rgba[..., :3]                      # (nrows, ncols, 3), drop alpha
            nrows, ncols = rgb.shape[0], rgb.shape[1]

            # Igor image waves are (x, y, RGB): rows -> x, columns -> y.
            igor_img = np.ascontiguousarray(np.transpose(rgb, (1, 0, 2)))

            # Pixel-center coordinates for Igor's SetScale/I, from the extent
            # (left, right, bottom, top). Row 0 sits at the top edge for
            # origin='upper' and at the bottom edge for origin='lower'.
            left, right, bottom, top = im.get_extent()
            if im.origin == 'upper':
                y_first, y_last = top, bottom
            else:
                y_first, y_last = bottom, top
            dx = (right - left) / ncols
            dy = (y_last - y_first) / nrows
            scale = np.array([left + dx/2, right - dx/2,
                              y_first + dy/2, y_last - dy/2], dtype=float)

            hf.create_dataset(filename + '/' + imgLabel + '_img', data=igor_img)
            hf.create_dataset(filename + '/' + imgLabel + '_scale', data=scale)

        # Save any lines on the axis (same conventions as axis_to_igor) so
        # overlays (contours, traces, markers) carry over.
        lines = plt.getp(ax, 'lines')
        usedLabels = dict()
        for line in lines:
            lineLabel = _unique_label(plt.getp(line, 'label'), usedLabels)
            xdata = plt.getp(line, 'xdata')
            ydata = plt.getp(line, 'ydata')
            linestyle = plt.getp(line, 'linestyle')
            # Convert to a numeric (r, g, b) triplet in 0-1, which is what the
            # Igor display code expects, however the color was specified in
            # matplotlib ('r', '#1f77b4', (0.2, 0.4, 0.6), ...).
            color = np.array(plt.matplotlib.colors.to_rgb(plt.getp(line, 'color')))
            markerSize = plt.getp(line, 'markersize')
            hf.create_dataset(filename + '/' + lineLabel + '_X', data=xdata)
            hf.create_dataset(filename + '/' + lineLabel + '_Y', data=ydata)
            hf.create_dataset(filename + '/' + lineLabel + '_color', data=color)
            hf.create_dataset(filename + '/' + lineLabel + '_linestyle', data=linestyle)
            hf.create_dataset(filename + '/' + lineLabel + '_markerSize', data=markerSize)



# def axis_to_igor(ax, filename: str, out_dir: str=None):
#     ''' Save the data from a matplotlib axis to an hdf5 file that can be read by Igor.

#     Parameters:
#         ax: The axis to save.
#         filename: The name of the file to save.
#         out_dir: The directory to save the file to.
#     '''
#     # Create the base hdf5 file.
#     hf = h5py.File(os.path.join(out_dir,filename + '.h5'), 'w')

#     xlabel = plt.getp(ax.xaxis.get_label(), 'text')
#     ylabel = plt.getp(ax.yaxis.get_label(), 'text')

#     # Save axis labels.
#     hf.create_dataset(filename + '/Xlabel', data=xlabel)
#     hf.create_dataset(filename + '/Ylabel', data=ylabel)

#     lines = plt.getp(ax, 'lines')
#     for line in lines:
#         lineLabel = plt.getp(line, 'label')
#         xdata = plt.getp(line,'xdata')
#         ydata = plt.getp(line, 'ydata')
#         linestyle = plt.getp(line, 'linestyle')
#         color = plt.getp(line, 'color')
#         markerSize = plt.getp(line, 'markersize')
#         hf.create_dataset(filename + '/' + lineLabel + '_X', data=xdata)
#         hf.create_dataset(filename + '/' + lineLabel + '_Y', data=ydata)
#         hf.create_dataset(filename + '/' + lineLabel + '_color', data=color)
#         hf.create_dataset(filename + '/' + lineLabel + '_linestyle', data=linestyle)
#         hf.create_dataset(filename + '/' + lineLabel + '_markerSize', data=markerSize)
#     # Close the hdf5 file.
#     hf.close()