sys = epanet('bydgoszcz.inp');%wczytanie modelu hydraulicznego uj�cia
load('sys_informacje_o_ujeciu - baza_przyklad.mat'); % informacje o stanie obiekt�w
load('sys_ID_NAZWY_bariery.mat'); %opis struktury barier studziennych
fclose all;

numery_barier={'L1','L2','L5','L6','L7','L8'};
p_0S = cell(1,length(numery_barier));
Q_B_zakladane = {760,280,360,280,630,900}; % wektor zak�adanych wydajno�ci barier 

Q_B_dokladnosc_e_U=2;    % zak�adana dok�adno�� wydajno�ci uj�cia 

Q_B_obliczone = {0,0,0,0,0,0};
Q_B_nominalne = {0,0,0,0,0,0};
Q_B_braku_gotowosci = {0,0,0,0,0,0};

for bariera=1:length(numery_barier)
    obliczana_bariera=numery_barier{bariera}
    ilosc_pomp_w_barierze=size(eval(['bariera_' numery_barier{bariera}]),1);
    warunek_wyjscia=true;  

    %% uzgl�dnienie priorytetu 0, oznaczenie pomp wykluczonych z uruchamiania -1
    p_0S{bariera} = zeros(ilosc_pomp_w_barierze,1);
    for each=1:numel(p_0S{bariera}) 
        if sys_H{bariera}(each,1) < sys_uH{bariera}(each,1) || sys_G{bariera}(each,1)==0
            p_0S{bariera}(each,1) = -1;
        else 
            p_0S{bariera}(each,1) = 0;
        end
    end

       %% uzgl�dnienie priorytetu 1, oznaczenie pomp wyznaczonych do uruchomienia 1
    p_1S{bariera} = zeros(ilosc_pomp_w_barierze,1);
        for each=1:numel(p_1S{bariera}) 
            if sys_H{bariera}(each,1) > sys_uH{bariera}(each,2) && p_0S{bariera}(each,1)==0
                p_1S{bariera}(each,1) = 1;
            elseif p_0S{bariera}(each,1)==-1
                p_1S{bariera}(each,1) = -1;
            else
                p_1S{bariera}(each,1) = 0;
            end
        end

        %% uwgl�dnianie drugiego i trzeciego priorytetu - za�aczanie pomp do czasu osi�gni�cia zak�adanej wydajno�ci bariery
        p_2S{bariera} = p_1S{bariera};
        run obliczenie_nominalnych_wydajnosci.m;
        run obliczanie_wydajnosci_bariery_obliczonej.m
        
    if Q_B_obliczone{bariera} >= Q_B_zakladane{bariera}
        warunek_wyjscia = false;
    else
        warunek_wyjscia = true; 
    end

    while warunek_wyjscia % za�aczanie pomp do czasu osi�gni�cia zak�adanej wydajno�ci bariery
        suma_sasiedztwa = zeros(ilosc_pomp_w_barierze,ilosc_pomp_w_barierze);
        stopnie_wszystkie = 0;
        ile_wylaczonych_pomp_obok_siebie = 0;
        for each=1:numel(p_2S{bariera})%wyznaczanie stopnia wsp�czynnika sumy s�siedztwa
            if p_2S{bariera}(each,1)==0 || p_2S{bariera}(each,1)==-1
                ile_wylaczonych_pomp_obok_siebie = ile_wylaczonych_pomp_obok_siebie + 1;
            else
                stopnie_wszystkie(end+1) = ile_wylaczonych_pomp_obok_siebie;
                ile_wylaczonych_pomp_obok_siebie = 0;
            end
        end
        stopnie_wszystkie(end+1) = ile_wylaczonych_pomp_obok_siebie;
        stopien_sasiedztwa= floor(max(stopnie_wszystkie)/2);
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %wyznaczanie wsp�czynnika sumy s�siedztwa, jesli STS wieksze od 0
        if stopien_sasiedztwa>0
        for each=1:numel(p_2S{bariera}) 
            if p_2S{bariera}(each,1)==1 || p_2S{bariera}(each,1)==-1
            suma_sasiedztwa(each,1)= 0;

            else
                for stopien=1:stopien_sasiedztwa
                    try % poprzednia pompa
                        if p_2S{bariera}(each-stopien,1)==1
                            pp = 0;% jest w�aczona
                        elseif p_2S{bariera}(each-stopien,1)==0
                            pp = 1;%jest wy��czona
                        elseif p_2S{bariera}(each-stopien,1)==-1
                            pp = 1.5;%nie mo�e zosta� w�aczona
                        end
                    catch 
                           pp = 0.5; % nie ma
                    end

                    try%nast�pna pompa
                        if p_2S{bariera}(each+stopien,1)==1 
                            np = 0; % jest w�aczona
                        elseif p_2S{bariera}(each+stopien,1)==0
                            np = 1;%jest wy��czona
                        elseif p_2S{bariera}(each+stopien,1)==-1
                            np = 1.5;%nie mo�e zosta� w�aczona
                        end
                    catch
                        pp=0.5;%% nie ma
                    end
                    if stopien == 1
                         suma_sasiedztwa(each,stopien)= suma_sasiedztwa(each,stopien)+ ( pp + np);
                    else
                        suma_sasiedztwa(each,stopien)= suma_sasiedztwa(each,stopien-1)+ ( pp + np);
                    end
                end
            end
        end
        end
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            % dokonanie wyboru pompy do za��czenia %%%%%%%%%%%%%%%%%%%%%%%%%%
            % wskazanie numer�w pompy dla kt�rej osi�gni�to najwy�sz� warto��
            % wsp�czynnika sumy s�siedztwa,
     if stopien_sasiedztwa>0       
     najwiekszy_StS = max(suma_sasiedztwa(:,stopien_sasiedztwa));
         if najwiekszy_StS >0
            numery_pomp_najwiekszy_StS = find(suma_sasiedztwa(:,stopien_sasiedztwa)==najwiekszy_StS);

            %jesli dwa wsp�czynniki takie same, sprawdza sume ni�szego wsp�czynnika
            %wskaz pompy, ktore wyst�puj� z najwy�sz� suma_sasiedztwa s�siedztwa w obu powy�szych
            %przypadkach - kandydaci pompa/pompy do za��czenia
                if numel(numery_pomp_najwiekszy_StS)>1 && stopien_sasiedztwa>1 
                    pompy_z_najwiekszymStS = suma_sasiedztwa(:,stopien_sasiedztwa)==najwiekszy_StS;
                    suma_sasiedztwa_drugi_wybor = suma_sasiedztwa(:,stopien_sasiedztwa-1) .* pompy_z_najwiekszymStS;
                    numerypomp = find((suma_sasiedztwa_drugi_wybor)==max(suma_sasiedztwa_drugi_wybor));

                    if numel(numerypomp)>1 %jesli kilka pomp ma tak� sam� najwieksz� wartosc, dokonaj wyboru na podstawie czasu pracy pomp
                        czas_pracy=zeros(numel(numerypomp),2);
                        for element = 1:numel(numerypomp)
                            pompa=numerypomp(element);
                            czas_pracy(element,1) = pompa;
                            czas_pracy(element,2)= sys_T{bariera}(pompa);
                            %wskazanie pompy o mniejszym czasie pracy
                            [czas_pracy_max,I] = min(czas_pracy(:,2));
                            [I_row, I_col] = ind2sub(size(czas_pracy),I);
                            pompa_do_zalaczenia = czas_pracy(I_row,1);
                        end

                    else
                        pompa_do_zalaczenia=numerypomp;
                    end
                %jesli istnieje jedna pompa z najwy�szym STS
                elseif numel(numery_pomp_najwiekszy_StS)==1 && stopien_sasiedztwa>=1
                    pompa_do_zalaczenia=numery_pomp_najwiekszy_StS;
                
                %jesli kilka pomp ma tak� sam� najwieksz� wartosc 
                % przy stopniu 1 dokonaj wyboru na podstawie czasu pracy pomp                         
                elseif numel(numery_pomp_najwiekszy_StS)>1 && stopien_sasiedztwa==1    
                        numerypomp=numery_pomp_najwiekszy_StS;
                        czas_pracy=zeros(numel(numerypomp),2); 
                        for element = 1:numel(numerypomp)
                            pompa=numerypomp(element);
                            czas_pracy(element,1) = pompa;
                            czas_pracy(element,2)= sys_T{bariera}(pompa);
                            %wskazanie pompy o mniejszym czasie pracy
                            [czas_pracy_max,I] = min(czas_pracy(:,2));
                            [I_row, I_col] = ind2sub(size(czas_pracy),I);
                            pompa_do_zalaczenia = czas_pracy(I_row,1);
                        end
                
                else
                  %by�o:  pompa_do_zalaczenia = numery_pomp_najwiekszy_StS;
                    numerypomp=find(p_2S{bariera}(:,1)==0);
                    czas_pracy=zeros(numel(numerypomp),2); 
                    for element = 1:numel(numerypomp)
                        pompa=numerypomp(element);
                        czas_pracy(element,1) = pompa;
                        czas_pracy(element,2)= sys_T{bariera}(pompa);
                        %wskazanie pompy o mniejszym czasie pracy
                        [czas_pracy_max,I] = min(czas_pracy(:,2));
                        [I_row, I_col] = ind2sub(size(czas_pracy),I);
                        pompa_do_zalaczenia = czas_pracy(I_row,1);
                    end
                end

         %nie mo�na obliczy� sumy wsp�czynnika s�siedztwa = 0   
         end
     end 
     if stopien_sasiedztwa==0
        numerypomp=find(p_2S{bariera}(:,1)==0);
        czas_pracy=zeros(numel(numerypomp),2); 
            for element = 1:numel(numerypomp)
            pompa=numerypomp(element);
            czas_pracy(element,1) = pompa;
            czas_pracy(element,2)= sys_T{bariera}(pompa);
            %wskazanie pompy o mniejszym czasie pracy
            [czas_pracy_max,I] = min(czas_pracy(:,2));
            [I_row, I_col] = ind2sub(size(czas_pracy),I);
            pompa_do_zalaczenia = czas_pracy(I_row,1);
            end
          
     end
  
     % uruchomienie wybranej pompy
     run obliczanie_barier_zalaczanie_pompy;


        %sprawdzanie warunkow wyjscia
        if Q_B_obliczone{bariera} >= Q_B_zakladane{bariera} 
            osiagnieto_zakladana_wydajnosc=true; 
        else
            osiagnieto_zakladana_wydajnosc=false;
        end
        
        ilosc_wylaczonych_pomp=numel(find(p_2S{bariera}(:,1)==0));
        if osiagnieto_zakladana_wydajnosc==true 
            warunek_wyjscia=false;
        elseif osiagnieto_zakladana_wydajnosc==false && ilosc_wylaczonych_pomp ==0
            warunek_wyjscia=false;
        else 
            warunek_wyjscia=true; 
        end
        
    Q_B_zakladane_ujecia=sum(cell2mat(Q_B_zakladane));
    Q_B_obliczone_ujecia=sum(cell2mat(Q_B_obliczone));

    end

end

%sprawdzanie czy osi�gni�to zak�adan� wydajno�� sumy z barier, tj. calego uj�cia,
%wobec zak�adanej wydajnosci i przyj�tej dok�adno�ci
% jesli nie, uruchomienie algorytmu koryguj�cego wektory pomp do za��czenia
warunek_wydajnosci = Q_B_obliczone_ujecia<Q_B_zakladane_ujecia-Q_B_zakladane_ujecia*Q_B_dokladnosc_e_U*0.01 || Q_B_obliczone_ujecia>Q_B_zakladane_ujecia+Q_B_zakladane_ujecia*Q_B_dokladnosc_e_U*0.01;
if warunek_wydajnosci
    warunek_wyjscia_korekta=true;
    run('obliczanie_barier_korekta.m');

else 
    warunek_wyjscia_korekta=false;
    disp('osi�gni�to zak�adan� wydajnosc')
    Q_B_obliczone_ujecia
    Q_B_zakladane_ujecia
end



%%weryfikacja znalezionego scenariusza pracy pomp na modelu
run obliczanie_naModelu.m;