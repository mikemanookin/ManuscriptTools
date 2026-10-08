from figure_utils import image_to_igor
import numpy as np
import matplotlib.pyplot as plt

out_dir = '/Users/michaelmanookin/Documents/Tutorials/'

# ------------------------------------------------------------------
# Example 1: A true RGB image (e.g., an RGB spatiotemporal RF).
# ------------------------------------------------------------------
ny, nx = 64, 96
yy, xx = np.mgrid[0:ny, 0:nx]
rgb = np.zeros((ny, nx, 3))
rgb[..., 0] = np.exp(-((xx - 30)**2 + (yy - 32)**2) / (2 * 8**2))   # red blob
rgb[..., 2] = np.exp(-((xx - 65)**2 + (yy - 32)**2) / (2 * 8**2))   # blue blob
rgb[..., 1] = 0.25

fig, ax = plt.subplots(figsize=(5, 4))
ax.imshow(rgb, label='rfImage')
ax.set_xlabel('x (pixels)')
ax.set_ylabel('y (pixels)')

image_to_igor(ax, filename='TestImageRGB', out_dir=out_dir)

# ------------------------------------------------------------------
# Example 2: A scalar image through a colormap; the rendered RGB
# values are exported, so Igor shows exactly what matplotlib shows.
# An overlaid line is exported along with the image.
# ------------------------------------------------------------------
data = np.sin(xx / 8.0) * np.cos(yy / 8.0)

fig, ax = plt.subplots(figsize=(5, 4))
ax.imshow(data, cmap='viridis', extent=(0, 400, 0, 300),
          origin='lower', label='heatmap')
theta = np.linspace(0, 2 * np.pi, 100)
ax.plot(200 + 80 * np.cos(theta), 150 + 60 * np.sin(theta),
        color='w', label='rfContour')
ax.set_xlabel('x (microns)')
ax.set_ylabel('y (microns)')

image_to_igor(ax, filename='TestImageMap', out_dir=out_dir)

# In Igor (with DisplayImageFromPython.ipf loaded and the .h5 files in the
# experiment's home folder):
#   MakeImageFig("TestImageRGB")
#   MakeImageFig("TestImageMap")
