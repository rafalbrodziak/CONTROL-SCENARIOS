
% korekta nastaw pomp w barierach - algorytm korekcji, 
disp('uruchomienie algorytmu korekcji wyboru pomp do uruchomienia')

while warunek_wyjscia_korekta
    if Q_B_obliczone_ujecia<Q_B_zakladane_ujecia-Q_B_zakladane_ujecia*Q_B_dokladnosc_e_U*0.01
        %korekta gdy wydajnosc uzyskana jest mniejsza od wydajnosci zak³adanej
        for bariera=1:length(numery_barier)
            %wskazanie pomp w gotowoœci a nie za³¹czonych dla kazdej bariery
            numerypomp=find(p_2S{bariera}(:,1)==0);
            if numel(numerypomp)>0
                %odcyztanie dla kazdej znalezionej pompy czasu pracy
                czas_pracy_barier{1,bariera}=zeros(numel(numerypomp),2); 
                for element = 1:numel(numerypomp)
                    pompa=numerypomp(element);
                    czas_pracy_barier{1,bariera}(element,1) = pompa;
                    czas_pracy_barier{1,bariera}(element,2)= sys_T{bariera}(pompa);
                    czas_pracy_barier{1,bariera}(element,3)= bariera;
                end 
            end
        end
         %wskazanie pompy z najmniejszym czasem pracy jej numeru oraz z ktorej bariery,  
            czas_pracy_barier_razem=[ czas_pracy_barier{1,1};czas_pracy_barier{1,2};czas_pracy_barier{1,3};czas_pracy_barier{1,4};czas_pracy_barier{1,5};czas_pracy_barier{1,6}]
            [czas_pracy_min,I] = min(czas_pracy_barier_razem(:,2))
            pompa_do_zalaczenia= czas_pracy_barier_razem(I,1); % numer pompy do za³aczania
            bariera = czas_pracy_barier_razem(I,3);% numer barier pompy

        run('obliczanie_barier_zalaczanie_pompy.m');

        Q_B_zakladane_ujecia=sum(cell2mat(Q_B_zakladane));
        Q_B_obliczone_ujecia=sum(cell2mat(Q_B_obliczone));

        % sprawdzanie warunku wyjscia
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
        %koretka, gdy wydajnosc uzyskana jest wieksza od wydajnosci zak³adanej  
            for bariera=1:length(numery_barier)
                %wskazanie pomp wskazanych do za³¹czenia 
                %TRZEBA TEZ UWZGLÊDNIÆ PRIORYETET WYSOKIEGO STANU, NIE
                %MOZNA TAKIEJ POMPY WYLACZYC
                numerypomp_wlaczone=find(p_S{bariera}(:,1)==1);
                numerypomp_not_priorytet1=find(p_1S{bariera}(:,1)==0);
                numerypomp=intersect(numerypomp_wlaczone,numerypomp_not_priorytet1);
                %odcyztanie dla kazdej znalezionej pompy czasu pracy
                czas_pracy_barier{1,bariera}=zeros(numel(numerypomp),2); 
                for element = 1:numel(numerypomp)
                    pompa=numerypomp(element);
                    czas_pracy_barier{1,bariera}(element,1) = pompa;
                    czas_pracy_barier{1,bariera}(element,2)= sys_T{bariera}(pompa);
                    czas_pracy_barier{1,bariera}(element,3)= bariera;
                end
            end
            %wskazanie pompy z najwiêkszym czasem pracy , jej numeru oraz z ktorej bariery,  
            czas_pracy_barier_razem=[ czas_pracy_barier{1,1};czas_pracy_barier{1,2};czas_pracy_barier{1,3};czas_pracy_barier{1,4};czas_pracy_barier{1,5};czas_pracy_barier{1,6}];
            [czas_pracy_max,I] = max(czas_pracy_barier_razem(:,2))
            pompa_do_wylaczenia= czas_pracy_barier_razem(I,1); % numer pompy do za³aczania
            bariera = czas_pracy_barier_razem(I,3);% numer barier pompy

            run('obliczanie_barier_wylaczanie_pompy.m');

            Q_B_zakladane_ujecia=sum(cell2mat(Q_B_zakladane));
            Q_B_obliczone_ujecia=sum(cell2mat(Q_B_obliczone));

            % sprawdzanie warunku wyjscia
            if Q_B_obliczone_ujecia>Q_B_zakladane_ujecia+Q_B_zakladane_ujecia*Q_B_dokladnosc_e_U*0.01
                warunek_wyjscia_korekta=true;
            else 
                warunek_wyjscia_korekta=false;
                disp('osi¹gniêto zak³adan¹ wydajnosc')
                Q_B_obliczone_ujecia
                Q_B_zakladane_ujecia
            end
        else 
            %wydajnosc uzyskana znajduje sie w przedziale wydajnosci zak³adanej 

        end
    end
        
end