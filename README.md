# JtLib #

A library for [Jterator](https://github.com/HackerMD/Jterator) modules
and pipelines for standard image analysis tasks, such as segmenting objects and taking measurements of these objects. 
    
* **modules**: executables (the actual code)       
* **handles**:  YAML module descriptor files    
* **pipes**: YAML pipeline descriptor files      

Some of the lab's standard CP modules are already implemented in Jterator:

* LoadImages.m -> **LoadImage.py**     
* IlluminationCorrectionPelkmans.m -> **IllumCorrectImage.py**    
* IdentifyPrimItarative.m -> **IdentifyNuclei.m**   
* IdentifySecondaryIterative.m -> **IdentifyCells.m**     
* LoadSegmentedCells.m -> **LoadSegmentation.py**
* MeasureAreaShape.m -> **MeasureAreaShape.py**   
* MeasureObjectIntensity.m & MeasureTexture.m -> **MeasureIntensity.py**

> Note: The measurement modules produce different and more extensive output when compared to the corresponding CP Matlab modules.


## Documentation ##

We will use [Sphinx](http://sphinx-doc.org/) to generate documentation of modules. [Sphinx isn't just for Python](http://ericholscher.com/blog/2014/feb/11/sphinx-isnt-just-for-python/) and will be used for all API languages.
