# JtLib #

A library for custom [Jterator](https://github.com/HackerMD/Jterator) tools.
It should serve as a code repository for common image processing tasks, such as segmenting objects and taking measurements of segmented objects. 
    
* **modules**: executables (the actual code)       
* **handles**:  YAML module descriptor files    
* **pipes**: YAML pipeline descriptor files     
* **subfunctions**: functions, which are required by modules (see TODO below)   

Some of the lab's standard CP modules are already implemented in Jterator:

* LoadImages.m -> **LoadImage.py**     
* NYB_IlluminationCorrection.m -> **IlluminationCorrection.py**    
* IdentifyPrimaryItarative.m -> **IdentifyNuclei.m**   
* IdentifySecondaryIterative.m -> **IdentifyCells.m**     
* LoadSegmentedCells.m -> **LoadSegmentation.py**
* MeasureAreaShape.m -> **MeasureAreaShape.py**   
* MeasureObjectIntensity.m -> **MeasureIntensity.py**
    
There are also tools available for job submission on Brutus:    
* **precluster.py** submits a single job (the first job in the joblist) to test the pipeline. You will receive an email once the job is finished.    
* **jtcluster.py** checks the results file of the precluster step and submits all other jobs if the precluster step completed successfully. 


## Usage ##

Obviously, you need to have Jterator installed.

Currently, the user is responsible for making the *subfunctions* available to the modules. This can be achieved by setting environment variables for each language, which point to the location where the corresponding "packages", "modules" or "libraries" (language-specific syntax) can be found:    

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

Note: In R you may have to specify each individual library and not only the main directory.

Julia:      
```{bash}
export JULIA_LOAD_PATH=$JULIA_LOAD_PATH:$HOME/jtlib/subfunctions/julia
```

Optimally, *Jterator* would also take care of this. This could be included in the pipeline descriptor file.
