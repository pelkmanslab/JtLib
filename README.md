# JtLib #

A library for custom [Jterator](https://github.com/HackerMD/Jterator) tools.
It should serve as a code repository for common image processing tasks, such as segmenting objects and taking measurements of these objects. 
    
* **modules**: executables (the actual code)       
* **handles**:  YAML module descriptor files    
* **pipes**: YAML pipeline descriptor files     
* **subfunctions**: code that is called by modules (see below)   

Some of the lab's standard CP modules are already implemented in Jterator:

* LoadImages.m -> **LoadImage.py**     
* IlluminationCorrectionPelkmans.m -> **IllumCorrectImage.py**    
* IdentifyPrimItarative.m -> **IdentifyNuclei.m**   
* IdentifySecondaryIterative.m -> **IdentifyCells.m**     
* LoadSegmentedCells.m -> **LoadSegmentation.py**
* MeasureAreaShape.m -> **MeasureAreaShape.py**   
* MeasureObjectIntensity.m & MeasureTexture.m -> **MeasureIntensity.py**

> Note: The measurement modules produce different and more extensive output when compared to the CP matlab implementations.


## Usage ##

The user is responsible for making the *subfunctions* available to the modules. This can be achieved by setting environment variables for each language, which point to the location where the corresponding "packages", "modules" or "libraries" (language-specific syntax) can be found:    

Python:  
```{bash}
export PYTHONPATH=$PYTHONPATH:$HOME/jtlib/subfunctions/python
```

Matlab:     
```{bash}
export MATLABPATH=$MATLABPATH:$HOME/jtlib/subfunctions/matlab
```

R:  
```{bash}
export R_LIBS=$R_LIBS:$HOME/jtlib/subfunctions/r
```

> Note: In R you may have to specify each individual library and not only the main directory.

Julia:      
```{bash}
export JULIA_LOAD_PATH=$JULIA_LOAD_PATH:$HOME/jtlib/subfunctions/julia
```

## Documentation ##

We will use [Sphinx](http://sphinx-doc.org/) to generate documentation of modules. [Sphinx isn't just for Python](http://ericholscher.com/blog/2014/feb/11/sphinx-isnt-just-for-python/), but will be used for all API languages.
