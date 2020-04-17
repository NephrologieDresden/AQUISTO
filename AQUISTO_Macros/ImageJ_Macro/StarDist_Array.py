# @DatasetIOService io
# @CommandService command
# @File (label="Select the staining directory", style="directory") myDir

print(myDir)
from de.csbdresden.stardist import StarDist2D 
from glob import glob
import os
import ij
import ij.plugin.PlugIn
import time

from ij import IJ
from ij.plugin.frame import RoiManager
from ij.gui import Roi
from ij import IJ, Prefs
from loci.plugins import BF

rm = RoiManager.getInstance()
IJ.run("Colors...", "foreground=white background=black selection=magenta");
IJ.run("Close All", "");

if not rm:
	rm = RoiManager()
rm.reset()


# run stardist on all tiff files in <indir> and save the label image to <outdir>
indir   = os.path.expanduser(str(myDir) + "\\Macros\\Samples\\Channels\\")
#outdir  = os.path.expanduser(str(myDir) + "\\Results\\Nuclear_ROIs\\1_Kidney\\")

print(indir)
for e in sorted(glob(os.path.join(indir, "*DAPI*.tif"))):
	print "processing ", e
	
	filename=str(os.path.basename(e))[0:(len(str(os.path.basename(e)))-4)]
					
	imp = IJ.openImage(e)

	impwidth=imp.getDimensions()[0]
	impheight=imp.getDimensions()[1]
			
	res = command.run(StarDist2D, False,
	"input", imp,
	"modelChoice", "Versatile (fluorescent nuclei)",
	"normalizeInput",True,"percentileBottom",1, "percentileTop",99.8,
	"probThresh",0.6, "nmsThresh", 0.2,
	"outputType","ROI Manager",
	"nTiles",1
	).get()
	
	rm.runCommand(imp,"Show All without labels");
	IJ.run(imp, "Enhance Contrast", "saturated=0.35");
	imp2 = imp.flatten();
	imp2.show();
	imp.close()

	rm.reset()

from ij.gui import WaitForUserDialog

myWait = WaitForUserDialog ("Check", "Did the model work?")
myWait.show()
IJ.run("Close All", "");

from java.lang import System;
System.exit(0);

