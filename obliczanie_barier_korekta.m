
% correction of pump settings in barriers - correction algorithm,  
disp('uruchomienie algorytmu korekcji wyboru pomp do uruchomienia')

while warunek_wyjscia_korekta
    if Q_B_obliczone_ujecia<Q_B_zakladane_ujecia-Q_B_zakladane_ujecia*Q_B_dokladnosc_e_U*0.01
        % correction when the efficiency obtained is lower than the assumed capacity 
        for bariera=1:length(numery_barier)
          % indication of pumps on standby and not on for each barrier 
            numerypomp=find(p_2S{bariera}(:,1)==0);
            if numel(numerypomp)>0
               % reading for each running time pump found 
                czas_pracy_barier{1,bariera}=zeros(numel(numerypomp),2); 
                for element = 1:numel(numerypomp)
                    pompa=numerypomp(element);
                    czas_pracy_barier{1,bariera}(element,1) = pompa;
                    czas_pracy_barier{1,bariera}(element,2)= sys_T{bariera}(pompa);
                    czas_pracy_barier{1,bariera}(element,3)= bariera;
                end 
            end
        end
         % indication of the pump with the lowest operating time of its number and from which barrier,  
            czas_pracy_barier_razem=[ czas_pracy_barier{1,1};czas_pracy_barier{1,2};czas_pracy_barier{1,3};czas_pracy_barier{1,4};czas_pracy_barier{1,5};czas_pracy_barier{1,6}]
            [czas_pracy_min,I] = min(czas_pracy_barier_razem(:,2))
            pompa_do_zalaczenia= czas_pracy_barier_razem(I,1); % pump number to be switched on 
            bariera = czas_pracy_barier_razem(I,3);% pump barriers number 

        run('obliczanie_barier_zalaczanie_pompy.m');

        Q_B_zakladane_ujecia=sum(cell2mat(Q_B_zakladane));
        Q_B_obliczone_ujecia=sum(cell2mat(Q_B_obliczone));

        % checking exit condition 
        if Q_B_obliczone_ujecia<Q_B_zakladane_ujecia-Q_B_zakladane_ujecia*Q_B_dokladnosc_e_U*0.01
            warunek_wyjscia_korekta=true;
        else 
            warunek_wyjscia_korekta=false;
            disp('osi¹gniêto zak³adan¹ wydajnosc')
            Q_B_obliczone_ujecia
            Q_B_zakladane_ujecia
        end

    else
        if Q_B_obliczone_ujecia>Q_B_zakladane_ujecia+Q_B_zakladane_ujecia*Q_B_dokladnosc_e_U*0.01
        % correction, when the efficiency obtained is higher than the assumed capacity 
            for bariera=1:length(numery_barier)
                % selection of pumps indicated for turn on - TAKING INTO ACCOUNT HIGH WATER TABLE IN WELL PRIORITY, SUCH PUMP CANNOT BE TURNED OFF 
                numerypomp_wlaczone=find(p_S{bariera}(:,1)==1);
                numerypomp_not_priorytet1=find(p_1S{bariera}(:,1)==0);
                numerypomp=intersect(numerypomp_wlaczone,numerypomp_not_priorytet1);
                % reading for each running time pump found
                czas_pracy_barier{1,bariera}=zeros(numel(numerypomp),2); 
                for element = 1:numel(numerypomp)
                    pompa=numerypomp(element);
                    czas_pracy_barier{1,bariera}(element,1) = pompa;
                    czas_pracy_barier{1,bariera}(element,2)= sys_T{bariera}(pompa);
                    czas_pracy_barier{1,bariera}(element,3)= bariera;
                end
            end
            % indication of the pump with the highest operating time, its number and from which barrier,  
            czas_pracy_barier_razem=[ czas_pracy_barier{1,1};czas_pracy_barier{1,2};czas_pracy_barier{1,3};czas_pracy_barier{1,4};czas_pracy_barier{1,5};czas_pracy_barier{1,6}];
            [czas_pracy_max,I] = max(czas_pracy_barier_razem(:,2))
            pompa_do_wylaczenia= czas_pracy_barier_razem(I,1); % pump number to be switched on 
            bariera = czas_pracy_barier_razem(I,3);% pump/wells barrier number 

            run('obliczanie_barier_wylaczanie_pompy.m');

            Q_B_zakladane_ujecia=sum(cell2mat(Q_B_zakladane));
            Q_B_obliczone_ujecia=sum(cell2mat(Q_B_obliczone));

            % checking exit condition 
            if Q_B_obliczone_ujecia>Q_B_zakladane_ujecia+Q_B_zakladane_ujecia*Q_B_dokladnosc_e_U*0.01
                warunek_wyjscia_korekta=true;
            else 
                warunek_wyjscia_korekta=false;
                disp('osi¹gniêto zak³adan¹ wydajnosc')
                Q_B_obliczone_ujecia
                Q_B_zakladane_ujecia
            end
        else 
            % efficiency obtained is within the range of the assumed efficiency 

        end
    end
        
end