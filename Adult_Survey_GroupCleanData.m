%% Data Cleaning for Adult Survey %%
%
% This script reads all "Adult_Survey" .log files to extracts survey
% scores, then saves them into a single CSV file.

clear; clc;

% Path settings
Root = 'C:\Users\';
CsvPath = 'C:\Users\';

SearchPattern = fullfile(Root,'*', '*_Adult_Survey_*.log'); % Get all relevant log file
LogFiles = dir(SearchPattern);

Res = table('Size', [length(LogFiles), 8], ...
                     'VariableTypes', {'string', 'string', 'double', 'double', 'double', 'double', 'double', 'double'}, ...
                     'VariableNames', {'SubjID', 'Conds', 'Q1', 'Q2', 'Q3', 'Q4', 'Q5', 'Q6'});

for i = 1:length(LogFiles)
    
    CurFile = fullfile(LogFiles(i).folder, LogFiles(i).name);
    
    % Extract subjID and conds
    [~, FileName, ~] = fileparts(LogFiles(i).name);
    Parts = split(FileName, '_');
    SubjID = Parts{1}; Cond = Parts{4};
    
    % Extract scores
    Fid = fopen(CurFile, 'r');
    Scores = nan(1, 6); % Initialization
    LineContent = fgetl(Fid);
    
    while ischar(LineContent)
        
        Match = regexp(LineContent, '^(\d+):.*?(\d+)$', 'tokens'); % Find 1: , 2: , ...

        if ~isempty(Match)
            Q_num = str2double(Match{1}{1});
            S = str2double(Match{1}{2});
            if Q_num >= 1 && Q_num <= 6
                Scores(Q_num) = S;
            end
        end
        
        LineContent = fgetl(Fid);

    end

    fclose(Fid);
    Res(i, :) = {SubjID, Cond, ...
        Scores(1), Scores(2), Scores(3), ...
        Scores(4), Scores(5), Scores(6)}; % Write in
    
end

% Save
writetable(Res, [CsvPath 'Adult_Survey_Behavior.xlsx']);
