

disp('zalaczanie pompy:')
disp(pompa_do_zalaczenia);
p_2S{bariera}(pompa_do_zalaczenia,1) = 1; % change the matrix of pumps to be switched on with the selected pump in the barrier 
run obliczanie_wydajnosci_bariery_obliczonej.m
