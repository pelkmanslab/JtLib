JtLib
=====

A set of custom tools for **Jterator** (https://github.com/HackerMD/Jterator).
It should serve as a code repository for common image processing tasks, such as segmenting objects and taking measurements of segmented objects. 
    
* **modules**: executables       
* **handles**:  YAML module descriptor files    
* **pipes**: YAML pipeline descriptor files     
* **subfunctions**: functions, which are required by modules  

Some of the lab's standard CP modules are already implemented in Jterator:

* *LoadImages.m* -> **PrimeRawData.py**     
* *NYB_IlluminationCorrection.m* -> **IllumCorr.py**    
* *IdentifyPrimary.m* & *SeparatePrimaryTissue.m* -> **IdentifyNuclei.m**   
* *IdentifySecondaryIterative.m* -> **IdentifyCells.m**     
* *MeasureObjectIntensity.m* & *MeasureAreaShape* -> **MeasureObjects.py**  
    
