JtLib
=====

A set of custom tools for [Jterator](https://github.com/HackerMD/Jterator).
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


TODO
----

Currently, the user is responsible for making the *subfunctions* available to the modules.
This can be done by setting environment variables for each language, which point the location where "packages", "modules" or "libraries" can be found:       
Python:  
```{bash}
export PYTHONPATH=$PYTHONPATH:/path/to/subfunction/folder
```

Matlab:     
```{bash}
export MATLABPATH=$MATLABPATH:/path/to/subfunction/folder
```

R:  
```{bash}
export R_LIBS=$R_LIBS:/path/to/subfunction/folder
```

Julia:      
```{bash}
export JULIA_LOAD_PATH=$JULIA_LOAD_PATH:/path/to/subfunction/folder
```

Optimally, *Jterator* would also take care of this. This could be included in the pipeline descriptor file.
