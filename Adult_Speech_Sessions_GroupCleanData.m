%% Data Cleaning for Adult Speech Sessions %%
%
% NOTE:
% 1. Requires the function ReadLogFile.m

clear; clc; close all;
addpath('Utils\');

% Path settings
Root = 'C:\Users\Downloads\Presentation\';
OutputPath = 'C:\Users\Downloads\';
Conds = {'Quiet', 'Noise'};

Subjfolders = dir(fullfile(Root, 'O*'));

All_Res = table();

% Loop subjects
for s = 1:length(Subjfolders)

    SubjID = Subjfolders(s).name;
    A_Subjfolder = fullfile(Root, SubjID);

    All_conds_tables = {};
    
    % Loop conds
    for i = 1:length(Conds)
    
        CurCond = Conds{i};
        
        % Read .log and save .csv
        LogFilename = sprintf('%s-Adult_%s_Speech_Session.log', SubjID, CurCond);
        LogPath = fullfile(A_Subjfolder, LogFilename);

        CsvFilename = strrep(LogFilename, '.log', '.csv');
        CsvPath = fullfile(A_Subjfolder, CsvFilename);
        
        All_conds_tables{i} = ReadLogFile(LogPath, CsvPath);
    
    end
    
    Quiet_T = All_conds_tables{1};
    Noise_T = All_conds_tables{2};
    
    % For the old data (before revising code)
    if any(strcmp(Noise_T.Code, 'Quiet'))
        Need2Rep = strcmp(Noise_T.Code, 'Quiet');
        Noise_T.Code(Need2Rep) = {'Loud Noise'};
    else
        fprintf('The code of behavioral data has revised, no need to change. Skip the revising step. \n')
    end
    
    Combined_T = [Quiet_T; Noise_T];
    
    % Stats
    Hit_idx = find(strcmp(Combined_T.('Stim Type'), 'hit'));
    Code_idx = Hit_idx - 1; Code_idx(Code_idx < 1) = [];
    Code = Combined_T.Code(Code_idx);
    
    QuietCounts = sum(strcmp(Code, 'Quiet')); % Counts
    SoftnoiseCounts = sum(strcmp(Code, 'Soft Noise'));
    LoudnoiseCounts = sum(strcmp(Code, 'Loud Noise'));
    
    QuietAcc = QuietCounts / 3; % Acc
    SoftnoiseAcc = SoftnoiseCounts / 2;
    LoudnoiseAcc = LoudnoiseCounts / 3;
    
    Res = table(string(SubjID), QuietCounts, SoftnoiseCounts, LoudnoiseCounts, ...
                         QuietAcc, SoftnoiseAcc, LoudnoiseAcc, ...
                         'VariableNames', ...
                         ["SubjID", "Quiet QCounts", "Soft Noise QCounts", "Loud Noise QCounts", ...
                         "Quiet QAcc", "Soft Noise QAcc", "Loud Noise QAcc"]);

    All_Res = [All_Res; Res];

end

% Save
writetable(All_Res, [OutputPath 'Adult_Speech_Sessions_Behavior.xlsx']);
