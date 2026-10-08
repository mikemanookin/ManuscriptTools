# ManuscriptTools

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
axis_to_igor(axs[0], filename='OMS_MEA', out_dir=igor_dir)
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
