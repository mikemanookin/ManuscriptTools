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




Lab tools for building manuscript figures: plots are made in MATLAB or
Python, exported as HDF5, and drawn and formatted in Igor Pro, where the
final panels are saved as PDF for Illustrator.

```
MATLAB  makeAxisStruct(gca, 'name', 'basedir', dir)   ─┐
                                                       ├─ name.h5 ─▶ Igor: MakeFig("name") / MakeImageFig("name") ─▶ PDF
Python  axis_to_igor(ax, 'name', out_dir) / image_to_igor(...) ─┘
```

## Documentation

| Document | Covers |
|---|---|
| [docs/Installation.md](docs/Installation.md) | Igor procedure aliases, HDF5 XOP, MATLAB path, `pip install` |
| [docs/MatlabToIgor.md](docs/MatlabToIgor.md) | `makeAxisStruct` and friends; what each dataset means; every Igor command (`MakeFig`, `SetYError`, `RefreshAllData`, `SaveAllGraphs`, …) |
| [docs/PythonToIgor.md](docs/PythonToIgor.md) | `figure_utils.axis_to_igor` and `image_to_igor`; `MakeImageFig`; contour fills |
| [docs/IgorPolarPlots.md](docs/IgorPolarPlots.md) | polar tuning plots: `polarWaves` + `PolarPlots.ipf` (shading, round-number rings, rescaling), and Igor's native Polar Graphs package |
| [docs/ElectricalImages.md](docs/ElectricalImages.md) | MEA electrical images: `EI_*.h5` export, `MakeEIGraph` (circle area ∝ trough depth), waveform panel |
| [docs/RfMosaics.md](docs/RfMosaics.md) | receptive-field mosaics: `PopulationRF_*.h5` export (contour or Gaussian ellipse at a fraction of the peak, merges), `MakeMosaicGraph`, `FormatRfContour` fills |
| [docs/CHANGELOG.md](docs/CHANGELOG.md) | what changed, newest first — loaders, refresh, polar plots, EI, mosaics |

Worked examples: `Tutorials/matlab_tutorial.m`, `Tutorials/python_tutorial.py`,
`Tutorials/python_image_tutorial.py`.

## Quick example (Python)

```python
from figure_utils import axis_to_igor

# One call per axis; every line needs a label, which becomes the Igor wave name.
for idx in range(len(u_types)):
    if ('good' in u_types[idx]):
        plt.plot(u_constants, rate_mean[idx,:], label=u_types[idx].replace('good ','')+'_M')
        plt.plot(u_constants, rate_error[idx,:], label=u_types[idx].replace('good ','')+'_E')
plt.xlabel('correlation length constant (um)')
plt.ylabel('normalized response')
axis_to_igor(plt.gca(), filename='OMS_MEA', out_dir=os.path.join(analysis_root, experiment_name, 'Figure'))

# With subplots, pass each Axes separately.
figs, axs = plt.subplots(1, 2, figsize=(10, 5))
axs[0].plot(u_constants, rate_mean[0,:], label='A1_M')
axs[0].plot(u_constants, rate_error[0,:], label='A1_E')
axs[0].set_xlabel('correlation length constant (um)')
axs[0].set_ylabel('spike count / bin')
axs[0].set_title('normalized response')
chunk_name = 'chunk3'
axis_to_igor(axs[0], filename='OMS_MEA', out_dir=os.path.join(analysis_root,experiment_name,chunk_name,'Figure'))
```

Then in Igor, with `OMS_MEA.h5` next to the saved experiment:
`MakeFig("OMS_MEA")`, `SetYError("OMS_MEA")`, `SaveAllGraphs()`.

## Layout

| Folder | Contents |
|---|---|
| `Igor/` | procedure files: `ManookinLabIgorProcedures.ipf`, `DisplayFigFromMatlab.ipf`, `DisplayImageFromPython.ipf`, `PolarPlots.ipf`, `RfContourFill.ipf`, `ElectricalImages.ipf`, `RfMosaics.ipf`, `SnapIt.ipf`; `ManuscriptFigure.pxp` template |
| `Matlab/MatlabToIgorTools/` | `makeAxisStruct.m`, `exportStructToHDF5.m`, `addLineToAxis.m`, `polarWaves.m`, helpers |
| `Python/` | the `figure_utils` package |
| `Tutorials/` | runnable examples |
| `Illustrator/`, `LaTex/` | figure template (`ManuscriptFigure.ai`) and article class |
