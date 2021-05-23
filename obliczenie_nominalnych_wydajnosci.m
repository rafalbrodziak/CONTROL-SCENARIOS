%% calculation of the nominal capacities in the current operating situation 
Q_B_nominalne{bariera}=0;
Q_B_braku_gotowosci{bariera}=0;
for each=1:numel(p_0S{bariera})
        if p_0S{bariera}(each,1)==0 
           Q_B_nominalne{bariera} = Q_B_nominalne{bariera}+ sys_Q_sr{bariera}(each);
        else
            Q_B_braku_gotowosci{bariera}= Q_B_braku_gotowosci{bariera}+ sys_Q_sr{bariera}(each);
        end
end