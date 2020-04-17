# @DatasetIOService io
# @CommandService command
# @File (label="Select the staining directory", style="directory") myDir


""" This example runs stardist on all tif files in a folder
Full list of Parameters: 
res = command.run(StarDist2D, False,
			 "input", imp, "modelChoice", "Versatile (fluorescent nuclei)",
			 "modelFile","/path/to/TF_SavedModel.zip",
			 "normalizeInput",True, "percentileBottom",1, "percentileTop",99.8,
			 "probThresh",0.5, "nmsThresh", 0.3, "outputType","Label Image",
			 "nTiles",1, "excludeBoundary",2, "verbose",1, "showCsbdeepProgress",1, "showProbAndDist",0).get();			
"""

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

print(myDir)

rm = RoiManager.getInstance()

if not rm:
	rm = RoiManager()
rm2=RoiManager(False)
rm.reset()
rm2.reset()


# run stardist on all tiff files in <indir> and save the label image to <outdir>
indir   = os.path.expanduser(str(myDir) + "\\Images\\")
outdir  = os.path.expanduser(str(myDir) + "\\Results\\Nuclear_ROIs\\1_Kidney\\")

print(indir)
for e in sorted(glob(os.path.join(indir, "*\\"))):
	print "processing ", e
	biopsyname=str(os.path.basename(os.path.dirname(e)))
	if not os.path.exists(os.path.join(outdir,biopsyname)):
		os.mkdir(os.path.join(outdir,biopsyname))
	
		for f in sorted(glob(os.path.join(e, "*DAPI*.tif"))):
			print "processing ", f
		  	
			filename=str(os.path.basename(f))[0:(len(str(os.path.basename(f)))-4)]
					
			imp = IJ.openImage(f)
			impwidth=imp.getDimensions()[0]
			impheight=imp.getDimensions()[1]
			
			xtrans_times=-int(-impwidth/2000);
			xtrans=impwidth/xtrans_times;
	
			ytrans_times=-int(-impheight/2000);
			ytrans=impheight/ytrans_times;
	
			#xtrans_times=1
			#ytrans_times=1
			d=0
			
			for g in range(xtrans_times):
				for f in range(ytrans_times):
					d=d+1
					imp.setRoi(g*xtrans,f*ytrans, xtrans,ytrans)
					imp2 = imp.crop()
	
					print("Tile "+str(d)+" of "+str(xtrans_times*ytrans_times))
					res = command.run(StarDist2D, False,
					"input", imp2,
					"modelChoice", "Versatile (fluorescent nuclei)",
					"normalizeInput",True,"percentileBottom",1, "percentileTop",99.8,
					"probThresh",0.6, "nmsThresh", 0.2,
					"outputType","Label Image",
					"nTiles",1
					).get()
	
					label = res.getOutput("label")
					io.save(label, os.path.join(indir,"temp.tif"))
					
					label = IJ.openImage(os.path.join(indir,"temp.tif"))
					label2 = label.duplicate()
					label2.show()
					IJ.run("Find Edges", "")
					
					IJ.setRawThreshold(label2, 1, 65535, "Red")
					IJ.run(label2, "Create Selection", "")
					time.sleep(0.5)
					if label2.getRoi():
						rm.addRoi(label2.getRoi())
						label.show()
						time.sleep(0.5)
						rm.select(0)
						IJ.setBackgroundColor(0, 0, 0)
						IJ.run(label, "Clear", "slice")
						
						rm.reset()					
						IJ.setRawThreshold(label, 1, 65535, "Red")
						IJ.run(label, "Create Selection", "")
						
						time.sleep(0.5)
						
						if label.getRoi():
							rm2.addRoi(label.getRoi())
							rm2.select(int(rm2.getCount())-1)
							rm2.translate(g*xtrans,f*ytrans)
			
							#rm.setSelectedIndexes(range(rm.getCount()))
							#rm.runCommand(imp,"Combine");
							#rm.runCommand(imp,"Delete");
							#rm.addRoi(imp.getRoi());
			
							#if os.path.isfile(os.path.join(outdir,biopsyname+"\\DAPI.zip")):				
							#	rm2.runCommand("Open", os.path.join(outdir,biopsyname+"\\DAPI.zip"))
							
							#rm2.runCommand("Save", os.path.join(outdir,biopsyname+"\\DAPI.zip"))
			
							#rm2.reset()
							#rm.reset()
							
					label2.changes = False
					label2.close()
			
					label.changes = False
					label.close()
			
					imp2.changes = False			
					imp2.close()
						
		rm2.setSelectedIndexes(range(rm2.getCount()))
		rm2.runCommand(imp,"Combine");
		rm2.runCommand(imp,"Delete");
		rm2.addRoi(imp.getRoi());
			
		rm2.runCommand("Save", os.path.join(outdir,biopsyname+"\\DAPI.zip"))
	
		rm.reset()
		rm2.reset()
		
if os.path.exists(os.path.join(indir,"temp.tif")):	
	os.remove(os.path.join(indir,"temp.tif"))
from java.lang import System;
System.exit(0);

