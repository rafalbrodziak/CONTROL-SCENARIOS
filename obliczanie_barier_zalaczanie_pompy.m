

disp('zalaczanie pompy:')
disp(pompa_do_zalaczenia);
p_2S{bariera}(pompa_do_zalaczenia,1) = 1; % zmien macierz pomp do za��czenia o wybran� pomp� w barierze
run obliczanie_wydajnosci_bariery_obliczonej.m