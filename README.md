# Manuscript Tools



This has been tested on Igor 7 and Igor 8, but should work on other versions.

Install Igor Pro:
Download: Igor Pro 8 here: https://www.wavemetrics.com/software/

Install HDF5 Browser (required for version <= 8):

Locate Extensions: Choose Help > Show Igor Pro Folder to find the installation directory.
Find XOP: Navigate to More Extensions (64-bit)\File Loaders and locate HDF5-64.xop.
Install XOP: Copy HDF5-64.xop and paste a shortcut into User Files\Igor Extensions (64-bit) (found via Help > Show Igor Pro User Files).
Activate Browser: Similarly, copy HDF5 Browser.ipf from WaveMetrics Procedures\File Input Output in the Pro folder to the Igor Procedures folder in User Files.
Restart: Restart Igor Pro.

Clone the github repository:
git clone https://github.com/mikemanookin/ManuscriptTools.git

Create alias (Mac) or shortcuts (Windows) for the following files in the repo:
./ManuscriptTools/Igor/DisplayFigFromMatlab.ipf
./ManuscriptTools/Igor/ManookinLabIgorProcedures.ipf

Copy the aliases/shortcuts to your Igor Procedures user folder:
'../Documents/WaveMetrics/Igor Pro 8 User Files/Igor Procedures'

This way, any updates in the repo will be immediately available to you after a fresh pull.

The repo contains an example experiment file: ./ManuscriptTools/Igor/ManuscriptFigure.pxp
Copy this fill to where you want to start making figures. You can rename it as you like. I generally have a separate .pxp file for each figure in a grant/manuscript.


Mac (OS15.4.1) and Python (3.11)

Setup

Make sure installed into Applications folder

Manuscript Tools repo here: https://github.com/mikemanookin/ManuscriptTools
Clone and install repo (cd ManuscriptTools/Python -> pip install .)  (I think?)

Create alias for ManookinLabIgorProcedures.ipf  and DisplayFigFromMatlab.ipf in ManuscriptTools and move to Igor Pro 8 Folder/Igor Procedures
In Igor Pro 8 Folder / WaveMetrics Procedures / File Input Output make alias for HDF5Browser.ipf and move to Igor Pro 8 Folder/Igor Procedures




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
