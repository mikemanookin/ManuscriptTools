# ManuscriptTools

```python
from figure_utils import axis_to_igor

# This is an example using the main plot functionality in matplotlib.
for idx in range(len(u_types)):
    if ('good' in u_types[idx]):
        plt.plot(u_constants, rate_mean[idx,:], label=u_types[idx].replace('good ','')+'_M')
        plt.plot(u_constants, rate_error[idx,:], label=u_types[idx].replace('good ','')+'_E')
plt.xlabel('correlation length constant (um)')
plt.ylabel('normalized response')
plt.legend(bbox_to_anchor=(1.05, 1), loc='upper left', borderaxespad=0)
chunk_name = 'chunk3'
axis_to_igor(plt.gca(), filename='OMS_MEA', out_dir=os.path.join(analysis_root,experiment_name,chunk_name,'Figure'))

# Here is an example using a subplot.
# Create a figure with two subplots.
figs,axs = plt.subplots(1,2,figsize=(10,5))

for idx in range(len(u_types)):
    if ('good' in u_types[idx]):
        axs[0].plot(u_constants, rate_mean[idx,:], label=u_types[idx].replace('good ','')+'_M')
        axs[0].plot(u_constants, rate_error[idx,:], label=u_types[idx].replace('good ','')+'_E')
axs[0].set_xlabel('correlation length constant (um)')
axs[0].set_ylabel('spike count / bin')
axs[0].set_title('normalized response')
chunk_name = 'chunk3'
axis_to_igor(axs[0], filename='OMS_MEA', out_dir=os.path.join(analysis_root,experiment_name,chunk_name,'Figure'))
```