from figure_utils import axis_to_igor
import numpy as np
import matplotlib.pyplot as plt
import os

out_dir = '/Users/michaelmanookin/Documents/Tutorials/'

num_cells = 10
num_contrasts = 6

contrasts = np.linspace(0.0, 1.0, num_contrasts)
data = np.random.rand(num_cells, num_contrasts) # Simulated data: 10 cells, 6 contrasts, 100 trials each.


figs,axs = plt.subplots(1,2,figsize=(10,5))

axs[0].plot(contrasts, np.mean(data, axis=0), label='dataM')
axs[0].plot(contrasts, np.std(data, axis=0), label='dataE')
axs[0].set_xlabel('contrast')
axs[0].set_ylabel('spikes / s')
axs[0].set_title('normalized response')

axis_to_igor(axs[0], filename='TestCRF2', out_dir=out_dir)


axs[1].plot(contrasts, np.mean(data, axis=0), label='dataM')
axs[1].plot(contrasts, np.std(data, axis=0), label='dataE')
axs[1].set_xlabel('contrast')
axs[1].set_ylabel('spikes / s')
axs[1].set_title('normalized response')
axis_to_igor(axs[1], filename='TestCRF3', out_dir=out_dir)


scatter_data = np.random.rand(num_cells, num_cells)
axs[1].plot(scatter_data[:,0], scatter_data[:,1], label='data')
axs[1].plot(np.mean(scatter_data, axis=0), np.mean(scatter_data, axis=1), label='dataM')
axs[1].plot(np.std(scatter_data, axis=0), np.std(scatter_data, axis=1), label='dataE')
axs[1].set_xlabel('axis 1')
axs[1].set_ylabel('axis 2')
axs[1].set_title('normalized response')
axis_to_igor(axs[1], filename='TestScatter', out_dir=out_dir)