%% Data Cleaning for Adult Speech Sessions %%
%
% NOTE:
% 1. Requires the function Log2Csv.m

clear; clc;

% Path settings
Root = 'C:\Users\Downloads\';
OutputPath = 'C:\Users\Downloads\';
Conds = {'Cond1', 'Cond2'};

Subjfolders = dir(fullfile(Root, 'S*'));

All_Res = table();

% Loop subjects
for s = 1:length(Subjfolders)

    SubjID = Subjfolders(s).name;
    A_Subjfolder = fullfile(Root, SubjID);

    All_conds_table = {};
    
    % Loop conds
    for i = 1:length(Conds)
    
        CurCond = Conds{i};
        
        % Presentation log file & Conversion csv file
        LogFilename = sprintf('%s-Adult_%s_Speech_Session.log', SubjID, CurCond);
        LogPath = fullfile(A_Subjfolder, LogFilename);
        CsvFilename = strrep(LogFilename, '.log', '.csv');
        CsvPath = fullfile(A_Subjfolder, CsvFilename);
        
        % Conversion
        Suc = Log2Csv(LogPath, CsvPath);
        All_conds_tables{i} = readtable(CsvPath, 'PreserveVariableNames', true);
    
    end
    
    Quiet_T = All_conds_tables{1};
    Noise_T = All_conds_tables{2};
    
    % For the old data (before revising code)
    if any(strcmp(Noise_T.Code, 'Quiet'))
        Need2Rep = strcmp(Noise_T.Code, 'Quiet');
        Noise_T.Code(Need2Rep) = {'Loud'};
    else
        fprintf('The code of behavioral data has revised, no need to change. Skip the revising step.')
    end
    
    Combined_T = [Quiet_T; Noise_T];
    
    % Statistics
    Hit_idx = find(strcmp(Combined_T.('Stim Type'), 'hit'));
    Code_idx = Hit_idx - 1; Code_idx(Code_idx < 1) = [];
    Code = Combined_T.Code(Code_idx);
    
    QuietCounts = sum(strcmp(Code, 'Quiet')); % Counts
    SoftnoiseCounts = sum(strcmp(Code, 'Soft'));
    LoudnoiseCounts = sum(strcmp(Code, 'Loud'));
    
    QuietAcc = QuietCounts / 3; % Acc
    SoftnoiseAcc = SoftnoiseCounts / 2;
    LoudnoiseAcc = LoudnoiseCounts / 3;
    
    Res = table(string(SubjID), QuietCounts, SoftnoiseCounts, LoudnoiseCounts, ...
                         QuietAcc, SoftnoiseAcc, LoudnoiseAcc, ...
                         'VariableNames', ...
                         ["SubjID", "Quiet Counts", "Soft Counts", "Loud Counts", ...
                         "Quiet Acc", "Soft Acc", "Loud Acc"]);

    All_Res = [All_Res; Res];

end

% Save
writetable(All_Res, [OutputPath 'Adult_Speech_Sessions_Behavior.xlsx']);
