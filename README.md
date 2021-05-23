# CONTROL-SCENARIOS
OPERATIONAL CONTROL SCENARIOS FOR A WATER INTAKE SYSTEM WITH AN ARTIFICIAL RECHARGE 

## Table of contents
* [General info](#general-info)
* [Technologies](#technologies)
* [Setup](#setup)

## General info
This project implement algorythm proposed in work "OPERATIONAL CONTROL SCENARIOS FOR A WATER INTAKE SYSTEM WITH AN ARTIFICIAL RECHARGE" 
	
## Technologies
Project was created with:
* MATLAB version: R2015a
* EPANET version: 2.00.12
* EPANET-Matlab-Toolkit library : dev 2.1 

## Files structure

- `LIBRARIES\` - EPANET-Matlab-Toolkit library
- `NETWORKS\`  - network model description in INP EPANET format.
- `RESULTS\` - matlabs results temp path
- `epanet.m`  - EPANET-Matlab Class
- `obliczanie_barier.m`  -  START script - the main file of algorithm for scenarios synthesis 
- `obliczanie_barier_korekta.m`  -  algorytm script of finetuning of the vector Si (correction algorithm)
- `obliczanie_barier_zalaczanie_pompy.m`  -   script for confirming selection of the pump.
- `obliczanie_naModelu.m`  - simulation script of the created hydraulic scenario
- `obliczanie_wydajnosci_bariery_obliczonej.m`  - calculation and update performance barriers  
- `obliczenie_nominalnych_wydajnosci.m`  - algorytm for calculating nominal water intake volume
- `sys_ID_NAZWY_bariery.mat`  - workspace variables with description of the structure of wells  for the analyzed example - mapping pumps nodes ID to wells grups 
- `sys_informacje_o_ujeciu - baza_przyklad.mat`  - workspace variables with information about the initial state of the objects: sys_G, sys_H, sys_Q_sr, sys_T, sys_uH

