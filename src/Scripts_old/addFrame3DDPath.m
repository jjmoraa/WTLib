% Define the path to the frame3dd executable
frame3ddPath = 'C:\Users\josej\Downloads\Frame3DD_20140514+\Frame3DD\windows';

% Get the current system PATH
currentPath = getenv('PATH');

% Add frame3dd path to the system PATH
setenv('PATH', [frame3ddPath ';' currentPath]);

% Verify by calling frame3dd
%[status, cmdout] = system('frame3dd');
%if status == 0
%    disp('frame3dd is successfully recognized.');
%else
%    disp('There was an issue recognizing frame3dd:');
%    disp(cmdout);
%end