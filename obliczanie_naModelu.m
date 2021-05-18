
%%ustawianie stanu pracy pomp w barierach w modelu
for bariera=1:length(numery_barier)
    obliczana_bariera=numery_barier{bariera}
    bariera_biezaca=eval(['bariera_' numery_barier{bariera}]);
    id_pomp_w_barierze=cell2mat(bariera_biezaca(: , 1));
    
    przelyw_przewodow = sys.getLinkInitialStatus;
    nowe_statusy_pomp=transpose(p_S{bariera});
    przelyw_przewodow(id_pomp_w_barierze) = nowe_statusy_pomp; 
    sys.setLinkInitialStatus(przelyw_przewodow)
end


sys.solveCompleteHydraulics
% status_przewodow_nowy = sys.getLinkInitialStatus; % ustawienie statusow
% pomp w modelu dzia³a. 

%%sprawdzenie otrzymanej wydajnosci pomp w barierze
%%aktualizacja zmiennych stanu modelu obliczonych sys

for bariera=1:length(numery_barier)
    obliczana_bariera=numery_barier{bariera};
    bariera_biezaca=eval(['bariera_' numery_barier{bariera}]);
    id_pomp_w_barierze=cell2mat(bariera_biezaca(: , 1));
    
    przelyw_przewodow = sys.getLinkFlows;
    uzyskana_wydajnosc_pomp= przelyw_przewodow(id_pomp_w_barierze); 
    
    Q_B_uzyskane{bariera} = sum(uzyskana_wydajnosc_pomp);
    Q_B_uzyskane_ujecia=sum(cell2mat(Q_B_uzyskane));
    
    %aktualizacja wydajnoœci pracujacych pomp
    for each = 1:numel(sys_Q_sr{bariera})
        if uzyskana_wydajnosc_pomp(each)~=0 
            sys_Q_sr{bariera}(each)=uzyskana_wydajnosc_pomp(each);
        end
    end
    
    %aktualizacja czasu pracy pomp
    for each = 1:numel(sys_T{bariera})
        if uzyskana_wydajnosc_pomp(each)>0 
            sys_T{bariera}(each) = sys_T{bariera}(each)+sys.getTimeSimulationDuration;
        end
    end
    
    %aktualizacja wysokoœci lustra wody w studni
    id_studni_w_barierze=cell2mat(bariera_biezaca(: , 3));
    wysokosc_wezlow=sys.getNodeElevations;
    wysokosc_w_studni=wysokosc_wezlow(id_studni_w_barierze);
    for each = 1:numel(id_studni_w_barierze)
       sys_H{bariera}(each) =wysokosc_w_studni(each);
    end
    
    save('sys_informacje_o_ujeciu.mat','sys_Q_sr','sys_T','-append') % zapis zaaktualizowanych zmiennych stanu obiektu
end

Q_B_uzyskane_ujecia

