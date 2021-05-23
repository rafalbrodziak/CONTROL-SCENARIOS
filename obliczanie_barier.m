sys = epanet('bydgoszcz.inp');%loading hydraulic model of water intake 
load('sys_informacje_o_ujeciu - baza_przyklad.mat'); % information about the state of wells 
load('sys_ID_NAZWY_bariery.mat'); %description of the structure of well barriers 
fclose all;

numery_barier={'L1','L2','L5','L6','L7','L8'};
p_0S = cell(1,length(numery_barier));
Q_B_zakladane = {760,280,360,280,630,900}; % assumed performance of barriers 

Q_B_dokladnosc_e_U=2;    % assumed accuracy

Q_B_obliczone = {0,0,0,0,0,0};
Q_B_nominalne = {0,0,0,0,0,0};
Q_B_braku_gotowosci = {0,0,0,0,0,0};

for bariera=1:length(numery_barier)
    obliczana_bariera=numery_barier{bariera}
    ilosc_pomp_w_barierze=size(eval(['bariera_' numery_barier{bariera}]),1);
    warunek_wyjscia=true;  

    %% taking into account the priority 0, marking excluded pumps -1 
    p_0S{bariera} = zeros(ilosc_pomp_w_barierze,1);
    for each=1:numel(p_0S{bariera}) 
        if sys_H{bariera}(each,1) < sys_uH{bariera}(each,1) || sys_G{bariera}(each,1)==0
            p_0S{bariera}(each,1) = -1;
        else 
            p_0S{bariera}(each,1) = 0;
        end
    end

       %% consideration of priority 1, marking selected  pumps to operation 1
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

        %% taking into account the 2nd and 3rd priority - switching the pumps on until the assumed  performance of wells is achieved 
        p_2S{bariera} = p_1S{bariera};
        run obliczenie_nominalnych_wydajnosci.m;
        run obliczanie_wydajnosci_bariery_obliczonej.m
        
    if Q_B_obliczone{bariera} >= Q_B_zakladane{bariera}
        warunek_wyjscia = false;
    else
        warunek_wyjscia = true; 
    end

    while warunek_wyjscia % switching on the pumps until the assumed barrier efficiency is achieved 
        suma_sasiedztwa = zeros(ilosc_pomp_w_barierze,ilosc_pomp_w_barierze);
        stopnie_wszystkie = 0;
        ile_wylaczonych_pomp_obok_siebie = 0;
        for each=1:numel(p_2S{bariera})%determining the degree of the coefficient of the sum of the neighborhood 
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
        %determining the coefficient of the sum of the neighborhood (if degree is greater than 0 )
        if stopien_sasiedztwa>0
        for each=1:numel(p_2S{bariera}) 
            if p_2S{bariera}(each,1)==1 || p_2S{bariera}(each,1)==-1
            suma_sasiedztwa(each,1)= 0;

            else
                for stopien=1:stopien_sasiedztwa
                    try % preceding pump 
                        if p_2S{bariera}(each-stopien,1)==1
                            pp = 0;% is turn on
                        elseif p_2S{bariera}(each-stopien,1)==0
                            pp = 1;%is turn off
                        elseif p_2S{bariera}(each-stopien,1)==-1
                            pp = 1.5;%cannot be turned on 
                        end
                    catch 
                           pp = 0.5; % does not exist 
                    end

                    try%next pump 
                        if p_2S{bariera}(each+stopien,1)==1 
                            np = 0; % is turn on
                        elseif p_2S{bariera}(each+stopien,1)==0
                            np = 1;%is turn off
                        elseif p_2S{bariera}(each+stopien,1)==-1
                            np = 1.5;%cannot be turned on
                        end
                    catch
                        pp=0.5;%% does not exist 
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
            
            % selecting the pump to be switched on %%%%%%%%%%%%%%%%%%%%%%%%%%
            % indication of the pump numbers for which  neighborhood sum have highest value 
     if stopien_sasiedztwa>0       
     najwiekszy_StS = max(suma_sasiedztwa(:,stopien_sasiedztwa));
         if najwiekszy_StS >0
            numery_pomp_najwiekszy_StS = find(suma_sasiedztwa(:,stopien_sasiedztwa)==najwiekszy_StS);

			% if the two coefficients are the same, check the sum of the lower coefficient
             % indicated pumps that occur with the highest neighborhood_neighborhood in both of the above cases - pump / pumps candidates for activation 
                if numel(numery_pomp_najwiekszy_StS)>1 && stopien_sasiedztwa>1 
                    pompy_z_najwiekszymStS = suma_sasiedztwa(:,stopien_sasiedztwa)==najwiekszy_StS;
                    suma_sasiedztwa_drugi_wybor = suma_sasiedztwa(:,stopien_sasiedztwa-1) .* pompy_z_najwiekszymStS;
                    numerypomp = find((suma_sasiedztwa_drugi_wybor)==max(suma_sasiedztwa_drugi_wybor));

                    if numel(numerypomp)>1 % if several pumps have the same highest value, make your selection based on the runtime of the pumps 
                        czas_pracy=zeros(numel(numerypomp),2);
                        for element = 1:numel(numerypomp)
                            pompa=numerypomp(element);
                            czas_pracy(element,1) = pompa;
                            czas_pracy(element,2)= sys_T{bariera}(pompa);
                            %indication of a pump with a shorter running time 
                            [czas_pracy_max,I] = min(czas_pracy(:,2));
                            [I_row, I_col] = ind2sub(size(czas_pracy),I);
                            pompa_do_zalaczenia = czas_pracy(I_row,1);
                        end

                    else
                        pompa_do_zalaczenia=numerypomp;
                    end
                %if there is one pump with the highest STS 
                elseif numel(numery_pomp_najwiekszy_StS)==1 && stopien_sasiedztwa>=1
                    pompa_do_zalaczenia=numery_pomp_najwiekszy_StS;
                
                % if several pumps have the same value at stage 1, make your selection based on the runtime of the pumps                         
                elseif numel(numery_pomp_najwiekszy_StS)>1 && stopien_sasiedztwa==1    
                        numerypomp=numery_pomp_najwiekszy_StS;
                        czas_pracy=zeros(numel(numerypomp),2); 
                        for element = 1:numel(numerypomp)
                            pompa=numerypomp(element);
                            czas_pracy(element,1) = pompa;
                            czas_pracy(element,2)= sys_T{bariera}(pompa);
                            % indicating of a pump with a shorter running time 
                            [czas_pracy_max,I] = min(czas_pracy(:,2));
                            [I_row, I_col] = ind2sub(size(czas_pracy),I);
                            pompa_do_zalaczenia = czas_pracy(I_row,1);
                        end
                
                else

                    numerypomp=find(p_2S{bariera}(:,1)==0);
                    czas_pracy=zeros(numel(numerypomp),2); 
                    for element = 1:numel(numerypomp)
                        pompa=numerypomp(element);
                        czas_pracy(element,1) = pompa;
                        czas_pracy(element,2)= sys_T{bariera}(pompa);
                        % Indicating pump with less working time 
                        [czas_pracy_max,I] = min(czas_pracy(:,2));
                        [I_row, I_col] = ind2sub(size(czas_pracy),I);
                        pompa_do_zalaczenia = czas_pracy(I_row,1);
                    end
                end

         % Unable to calculate / neighborhood degree = 0 
         end
     end 
     if stopien_sasiedztwa==0
        numerypomp=find(p_2S{bariera}(:,1)==0);
        czas_pracy=zeros(numel(numerypomp),2); 
            for element = 1:numel(numerypomp)
            pompa=numerypomp(element);
            czas_pracy(element,1) = pompa;
            czas_pracy(element,2)= sys_T{bariera}(pompa);
            %indication of a pump with a shorter running time 
            [czas_pracy_max,I] = min(czas_pracy(:,2));
            [I_row, I_col] = ind2sub(size(czas_pracy),I);
            pompa_do_zalaczenia = czas_pracy(I_row,1);
            end
          
     end
  
     % starting the selected pump 
     run obliczanie_barier_zalaczanie_pompy;


        %checking exit conditions 
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

% checking whether the assumed efficiency of the sum of the barriers, i.e. the entire shot, has been achieved against the assumed efficiency and the assumed accuracy
% if not, activation of the algorithm correcting pump vectors to be switched on 
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



%% verification of the pump operation scenario on the model 
run obliczanie_naModelu.m;