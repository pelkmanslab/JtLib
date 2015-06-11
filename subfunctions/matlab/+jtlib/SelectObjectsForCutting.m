function [SelectedObjects, Objects2Cut, ObjectsNot2Cut] = SelectObjectsForCutting(Objects, MaxSolidity, MinFormFactor, MaxArea, MinArea)

    import jtlib.rplabel;
    import jtlib.GetObjectSelectionFeatures;

    [Area, Solidity, FormFactor] = GetObjectSelectionFeatures(Objects);

    % Select objects based on these features (user defined thresholds)
    obj2cut = Solidity < MaxSolidity & FormFactor > MinFormFactor & ...
                  Area < MaxArea     &       Area > MinArea;
    objNot2cut = ~obj2cut;
                
    objSelected = zeros(size(obj2cut));
    objSelected(obj2cut) = 1;
    objSelected(objNot2cut) = 2;
    SelectedObjects = rplabel(logical(Objects),[],objSelected);

    % Create mask image with objects selected for cutting
    Objects2Cut = zeros(size(Objects));
    Objects2Cut(SelectedObjects==1) = 1;

    % Store remaining objects that are omitted from cutting
    tmp = zeros(size(Objects));
    tmp(SelectedObjects==2) = 1;
    ObjectsNot2Cut = logical(tmp);

end
