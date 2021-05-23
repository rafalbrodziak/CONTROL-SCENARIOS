%generating a state vector P_S, and the calculation performance barriers 
p_S{bariera} = p_2S{bariera};
for each=1:numel(p_S{bariera}) 
    if p_S{bariera}(each,1)==-1
       p_S{bariera}(each,1)=0;
    end
end

% update of calculated barrier performance 
wydajnosc_zalaczonych_pomp = p_S{bariera} .* sys_Q_sr{bariera};
Q_B_obliczone{bariera} = sum(wydajnosc_zalaczonych_pomp);