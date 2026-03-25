function addNumadPaths() % add path for NuMAD source and optional toolbocxes
global numadPath
global ansysPath
global bmodesPath
global precompPath
global fastPath
global crunchPath
global adamsPath  
global turbsimPath
global iecwindPath
global mbcPath

numadPath = 'C:\Users\josej\work\mdo_dev\NuMAD-3.0\source';
ansysPath = 'C:\Program Files\ANSYS Inc\v201\ansys\bin\winx64\ANSYS201.exe';
precompPath = 'C:\Users\josej\work\mdo_dev\Wind_Turbines\Design_codes\PreComp.exe';
bmodesPath = 'C:\Users\josej\work\mdo_dev\Wind_Turbines\Design_codes\BModes.exe';
fastPath = 'C:\DesignCodes\FAST_v7.02.00d\FAST.exe';
crunchPath = 'C:\DesignCodes\Crunch_v3.00.00\Crunch.exe';
turbsimPath='C:\DesignCodes\TurbSim_v1.50\TurbSim.exe';
iecwindPath='C:\DesignCodes\IECWind\IECWind.exe';
mbcPath='C:\DesignCodes\MBC_v1.00.00a\Source';

addpath(genpath(numadPath))

disp('NuMAD and Design Code path setup complete.')