%% Data Cleaning for Child Inhibitory Control Task %%
%
% NOTE:
% 1. Requires the function Log2Csv.m

clear; clc; close all;

% Path settings
Root = 'C:\Users\'; 
SubjID  = 'Sub01';                  
Conds = {'Cond1', 'Cond2'};

Subjfolder = fullfile(Root, SubjID);

All_conds_tables = {};

% Loop conds
for i = 1:length(Conds)
    
    Curr_cond = Conds{i};

    % Presentation log file / conds list & Conversion csv file & Output path
    Log1_path = fullfile(Subjfolder, sprintf('%s-IC_%s.log', SubjID, Curr_cond));
    Log2_path = fullfile(Subjfolder, sprintf('%s_IC_%s.log', SubjID, Curr_cond));
    ConverCsv_path = fullfile(Subjfolder, sprintf('%s_IC_%s.csv', SubjID, Curr_cond));
    Output_path = fullfile(Subjfolder, sprintf('%s_IC_%s_cleaned.csv', SubjID, Curr_cond));

    % Csv conversion
    Conv = Log2Csv(Log1_path, ConverCsv_path);
    
    % Find valid data lines
    All_lines = readlines(ConverCsv_path);
    Header_row_ind = find(startsWith(All_lines, 'Subject,', 'IgnoreCase', true));
    End_row_ind = find(startsWith(All_lines, 'Visual picture detection failed'));

    if isempty(End_row_ind)
        End_row_ind = find(contains(All_lines, '}'));
        if isempty(End_row_ind)
            End_row_ind = numel(All_lines) + 1;
        end
    end

    Valid_data_lines = All_lines(Header_row_ind : End_row_ind - 1);
    
    % Temporally importing
    Temp_filename = 'temp_IC.csv';
    writelines(Valid_data_lines, Temp_filename);
    Opts = detectImportOptions(Temp_filename, 'Delimiter', ',', 'VariableNamesLine', 1);
    Opts = setvartype(Opts, {'Code', 'StimType'}, 'string'); % Definition
    Log1Table = readtable(Temp_filename, Opts);
    delete(Temp_filename);
    
    % Delete not interested columns
    Col2rm = {'Uncertainty', 'Duration', 'Uncertainty_1', 'ReqTime', 'ReqDur', 'PairIndex'};
    Exist_Col2rm = intersect(Col2rm, Log1Table.Properties.VariableNames);
    if ~isempty(Exist_Col2rm)
        Log1Table = removevars(Log1Table, Exist_Col2rm);
    end
    
    % For initial event deletion
    Init_ind = find(strcmp(Log1Table.EventType, 'Sound'), 1, 'first');
    if ~isempty(Init_ind) && Init_ind > 1
        Log1Table = Log1Table(Init_ind:end, :);
    end
    
    % For redundant response after missing InCong, delete all of them
    Rows2keep = true(height(Log1Table), 1);
    for j = 1:height(Log1Table)
        Is_incong_code = (strcmp(Log1Table.Code(j), 'InCong_trial1') || strcmp(Log1Table.Code(j), 'InCong_trial2')) && strcmp(Log1Table.StimType(j), 'miss');
        if Is_incong_code
            for k = (j+1):height(Log1Table)
                Is_next_trial_start = contains(Log1Table.Code(k), '_trial');
                if Is_next_trial_start
                    break
                end
                if strcmp(Log1Table.EventType(k), 'Response')
                    Rows2keep(k) = false;
                end
            end
        end
     end
    Log1Table = Log1Table(Rows2keep,:);

    % For missing InCong and missing Cong, add a blank row
    VarTypes = varfun(@class, Log1Table, 'OutputFormat','cell');
    BlankRow = table('Size',[1 width(Log1Table)],'VariableTypes', ...
        VarTypes,'VariableNames',Log1Table.Properties.VariableNames);
    for j = height(Log1Table):-1:1 
        Is_incong = strcmp(Log1Table.Code(j), 'InCong_trial1') || strcmp(Log1Table.Code(j), 'InCong_trial2');
        Is_cong = strcmp(Log1Table.Code(j), 'Cong_trial1');
        Is_miss = strcmp(Log1Table.StimType(j), 'miss');
        if Is_incong && Is_miss % For missing InCong
            Log1Table = [Log1Table(1:j, :); BlankRow; Log1Table(j+1:end, :)];
        end
        if Is_cong && Is_miss % For missing Cong
           Log1Table = [Log1Table(1:j, :); BlankRow; Log1Table(j+1:end, :)];
        end
    end 

    % For redundant response after Cong, delete them and keep the first one
    Rows2keep = false(height(Log1Table), 1);
    for j = 1:height(Log1Table)
        if ~strcmp(Log1Table.EventType(j), 'Response')
            Rows2keep(j) = true;
            if j < height(Log1Table) && strcmp(Log1Table.EventType(j+1), 'Response')
                Rows2keep(j+1) = true;
            end
        end
    end
    Log1Table = Log1Table(Rows2keep, :);
    
    % For redundant response after missing Cong
    Rows2keep = true(height(Log1Table), 1);
    for j = 1:(height(Log1Table)-2)
        Is_resp_CongMiss_row = (Log1Table.Code(j) == "Cong_trial1") && (Log1Table.StimType(j) == "miss");
        if Is_resp_CongMiss_row
            if Log1Table.EventType(j+2) == "Response" % Because of blank row
                Rows2keep(j+2) = false;
            end
        end
    end
    Log1Table = Log1Table(Rows2keep, :);
    
    % For picture stim deletion
    Rows2keep = true(height(Log1Table), 1); 
    for j = 1:height(Log1Table)
        if strcmp(Log1Table.EventType(j), 'Picture')
            Rows2keep(j) = false;
            Next_idx = j+1;
            while Next_idx <= height(Log1Table)
                if strcmp(Log1Table.EventType(Next_idx), 'Response') % Response of picture stim
                Rows2keep(Next_idx) = false;
                Next_idx = Next_idx+1;
                else
                    break
                end
            end
        end
    end
    Log1Table = Log1Table(Rows2keep, :);
    
    % Calculating RT, then delete TT time
    Log1Table.RT = NaN(height(Log1Table), 1);
    for j = 1:2:height(Log1Table)
        if j+1 <= height(Log1Table) && ...
           strcmp(Log1Table.EventType(j), 'Sound') && ...
           strcmp(Log1Table.EventType(j+1), 'Response')
           RT = Log1Table.Time(j+1) - Log1Table.Time(j);
           Log1Table.RT(j) = RT;
        end
    end
    Log1Table.TTime = [];
    
    % Row of response deletion
    Rows2keep = strcmp(Log1Table.EventType, 'Sound'); % Keep row of sound
    DataTable_fin = Log1Table(Rows2keep, :);
    DataTable_fin.EventType = [];
    
    % Import Log2 data
    Log2_rawdata = readtable(Log2_path, 'FileType', 'text', 'ReadVariableNames', false);
    Log2_rawdata.Properties.VariableNames = {'StimBlock_raw', 'Trial_raw', 'Conds', 'CondsList'};
    StimBlockCol = str2double(erase(Log2_rawdata.StimBlock_raw, "Block"));
    
    Evt_per_block = 6; % Settings based on IC task
    EvtCol = repmat((1:Evt_per_block)', ceil(height(Log2_rawdata)/Evt_per_block), 1);
    EvtCol = EvtCol(1:height(Log2_rawdata));
    CondsCol = Log2_rawdata.Conds;
    CondsListCol = Log2_rawdata.CondsList;
    
    Log2Table = table(StimBlockCol, EvtCol, CondsCol, CondsListCol, ...
        'VariableNames', {'StimBlock', 'Events', 'Conds', 'CondsList'});
    Log2Table.Conds = string(Log2Table.Conds);
    Log2Table.CondsList = string(Log2Table.CondsList);
    
    MergedTable = [Log2Table, DataTable_fin]; % Merge

    % Add session column
    if strcmp(Curr_cond, 'postNoise')
        session_name = "PostNoise";
    elseif strcmp(Curr_cond, 'postQuiet')
        session_name = "PostQuiet";
    else
        session_name = "Unknown"; % Backup
    end
    MergedTable = addvars(MergedTable, ...
        repmat(session_name, height(MergedTable), 1), ...
        'Before', 1, 'NewVariableNames', 'Session');
    
    % Almost done, save it first
    writetable(MergedTable, Output_path);

    % For conds category, 'Cong or InCong' for the block
    Blocks_num = max(MergedTable.StimBlock);
    
    for b = 1:Blocks_num

        Block_rows_idx = (MergedTable.StimBlock == b);
        if ~any(Block_rows_idx), continue; end
        
        Condslist_in_block = MergedTable.CondsList(Block_rows_idx);
        Has_incong = any(strcmp(Condslist_in_block, 'InCong'));
        
        if Has_incong
            MergedTable.Conds(Block_rows_idx) = "InCg";
        else
            MergedTable.Conds(Block_rows_idx) = "Cong";
        end

    end
    
    % Trial and time column deletion, save it eventually
    MergedTable.Trial = [];
    MergedTable.Time = [];
    
    writetable(MergedTable, Output_path);

    All_conds_tables{end+1} = MergedTable;  % Prepare merging postquiet and postnoise data

end

% Merging postquiet and postnoise data
if ~isempty(All_conds_tables)
    Mergedtable_fin = vertcat(All_conds_tables{:});
    Mergedtable_fin_filename = fullfile(Subjfolder, sprintf('%s_ChildIC_Merged.csv', SubjID)); % Merged csv name
    writetable(Mergedtable_fin, Mergedtable_fin_filename); % Save
else
    fprintf('No data collected, thus merging is unavailable. \n');
end
