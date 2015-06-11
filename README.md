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
export PYTHONPATH=$PYTHONPATH:$HOME/JtLib/subfunctions/python
```

Matlab:     
```{bash}
export MATLABPATH=$MATLABPATH:$HOME/JtLib/subfunctions/matlab
```

R:  
```{bash}
export R_LIBS=$R_LIBS:$HOME/JtLib/subfunctions/r
```

> Note: In R you may have to specify each individual library and not only the main directory.

Julia:      
```{bash}
export JULIA_LOAD_PATH=$JULIA_LOAD_PATH:$HOME/JtLib/subfunctions/julia
```

> You need to adapt the above lines in case your local copy of the repository is not your `$HOME` folder or it is named differently!

## Documentation ##

We will use [Sphinx](http://sphinx-doc.org/) to generate documentation of modules. [Sphinx isn't just for Python](http://ericholscher.com/blog/2014/feb/11/sphinx-isnt-just-for-python/), but will be used for all API languages.
