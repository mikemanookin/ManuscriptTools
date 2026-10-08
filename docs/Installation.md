# Installation

Clone the repository, e.g. to `~/Documents/GitRepos/Manookin-Lab/ManuscriptTools`.

## Igor Pro

1. Install Igor Pro (8 or later).
2. Make sure HDF5 support is active: Igor 8 — put a shortcut to
   `Igor Pro 8 Folder/More Extensions/File Loaders/HDF5.xop` in the
   `Igor Extensions` folder of your user files; Igor 9 and later — built in.
3. Create aliases/shortcuts (not copies) for the procedure files you use:

   `ManookinLabIgorProcedures.ipf` (required: `MakeFig`, `SetYError`, saving)
   `DisplayFigFromMatlab.ipf` (required: draws the traces)
   `DisplayImageFromPython.ipf` (images from `image_to_igor`)
   `PolarPlots.ipf` (polar tuning plots)
   `RfContourFill.ipf` (filled contours)
   `ElectricalImages.ipf` (MEA electrical images)
   `RfMosaics.ipf` (receptive-field mosaics)

4. Move the aliases to the Igor Procedures folder in your user files,
   e.g. `~/Documents/WaveMetrics/Igor Pro 9 User Files/Igor Procedures`.
   Aliases mean a `git pull` updates every experiment; keep only one copy
   of each file loaded ("Function … already defined" means there are two).
5. Start Igor Pro. Save a new experiment before the first `MakeFig` — the
   `.h5` files are looked for next to the `.pxp`.

## MATLAB

Add `Matlab/MatlabToIgorTools` to the path (`addpath` in `startup.m`, or
Set Path). Requires the built-in `hdf5write`; no toolboxes. See
`docs/MatlabToIgor.md`.

## Python

```bash
pip install -e ~/Documents/GitRepos/Manookin-Lab/ManuscriptTools/Python
```

Dependencies: `h5py`, `numpy`, `matplotlib`, `seaborn`. See
`docs/PythonToIgor.md`.
