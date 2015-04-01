function [Parents, Children] = RelateObjects(ParentLabelMatrix, ChildLabelMatrix)

    ChildParentList = sortrows(unique([ChildLabelMatrix(:) ParentLabelMatrix(:)],'rows'),1);

    ParentList = ChildParentList(:,2);
    %%% This gets rid of all parent values which have no corresponding children
    %%% values (where children = 0 but parent = 1).
    for i = 1:max(ChildParentList(:,1))
        ParentValue = max(ParentList(ChildParentList(:,1) == i));
        if isempty(ParentValue)
            ParentValue = NaN;%hack: 2014/02/07 [MH] changed from 0 to NaN
        end
        FinalParentList(i,1) = ParentValue;
    end

    for i = 1:max(ParentList)
        if exist('FinalParentList', 'var')
            ChildList(i,1) = length(FinalParentList(FinalParentList == i));
        else
            ChildList(i,1) = 0;
        end
    end

    if ~exist('FinalParentList', 'var')
        FinalParentList = 0;    
    end

    Parents = FinalParentList;
    Children = ChildList;
    
end
