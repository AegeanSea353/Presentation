%% Plot and Stats of HINT Data  %%

clear; clc;
close all;

%% Data Extraction

% Set datapath
HINT_path = 'C:\Users\Data.xlsx';
HINT = detectImportOptions(HINT_path, 'Sheet', 'AuditoryData');

T = readtable(HINT_path, HINT);

VarNames = T.Properties.VariableNames;
HINT_cols = VarNames(contains(VarNames, 'HINT'));

Conds = {'Q', 'F', 'L', 'R'}; % Define HINT conditions

% Initialization
HINT_Data = table(T.DyadID, 'VariableNames', {'DyadID'});
HINT_Data = [HINT_Data, array2table(nan(height(T), length(Conds)), 'VariableNames', Conds)];

% Loop
for i = 1:length(Conds)
    
    Cond = Conds{i};
    trial1_col = sprintf('HINT_SNR_%s_Trial1', Cond);
    trial2_col = sprintf('HINT_SNR_%s_Trial2', Cond);
    
    trial1_data = T.(trial1_col);
    trial2_data = T.(trial2_col);
    
    % Trial1 first then Trial2
    FinVal = trial1_data;
    Idx_trial2 = ~isnan(trial2_data);
    FinVal(Idx_trial2) = trial2_data(Idx_trial2);
    
    HINT_Data.(Cond) = FinVal;
    
end

%% Plot Quiet Conditions

figure('Position', [100, 100, 500, 700]);
ax1 = gca;
hold(ax1, 'on');

ColorQuiet = [0.5 0.7 1.0]; % Light blue

QuietData = HINT_Data.Q(~isnan(HINT_Data.Q)); % Remove NaNs

% Jittered scatter plot
JitterAmount = 0.25;
X_jitter = 1 + (rand(size(QuietData)) - 0.5) * JitterAmount;
scatter(ax1, X_jitter, QuietData, 50, ColorQuiet, 'filled', 'MarkerFaceAlpha', 0.6);

% Box chart plot
boxchart(ax1, ones(size(QuietData)), QuietData, ...
    'BoxWidth', 0.5, 'BoxFaceColor', ColorQuiet, 'BoxFaceAlpha', 0.4, ...
    'WhiskerLineColor', ColorQuiet*0.6, 'MarkerStyle', 'none', ...
    'JitterOutliers','off');

% Other settings
hold(ax1, 'off');
ax1.XTick = 1;
ax1.XTickLabel = {'Quiet'};
xlim(ax1, [0.5, 1.5]);
ylim(ax1, [20, 80]); % Custom
ylabel(ax1, 'SNR (dB)', 'FontWeight', 'bold');
title(ax1, 'HINT Results: Quiet', 'FontSize', 16, 'FontWeight', 'bold');
% grid(ax1, 'on');
% ax1.GridLineStyle = '--';
% ax1.YGrid = 'on';
% ax1.XGrid = 'off';
set(ax1, 'FontName', 'Arial', 'FontSize', 10, 'Box', 'on', 'LineWidth', 1);

%% Plot Noise Conditions

figure('Position', [150, 150, 800, 700]);
ax2 = gca;
hold(ax2, 'on');

Noise_Conds = {'F', 'L', 'R'};
ColorNoise = {[1.0 0.7 0.5], ...   % Light Orange
                 [0.5 0.9 0.7], ...   % Light Green
                 [1.0 0.6 0.6]};     % Light Red

% Loop 
for i = 1:length(Noise_Conds)
    
    NCond = Noise_Conds{i};
    NData = HINT_Data.(NCond);
    NData = NData(~isnan(NData));
    
    % Jittered scatter plot
    X_jitter = i + (rand(size(NData)) - 0.5) * JitterAmount;
    scatter(ax2, X_jitter, NData, 50, ColorNoise{i}, 'filled', 'MarkerFaceAlpha', 0.6);
    
    % Box chart plot
    boxchart(ax2, repmat(i, size(NData)), NData, ...
        'BoxWidth', 0.5, 'BoxFaceColor', ColorNoise{i}, 'BoxFaceAlpha', 0.4, ...
        'WhiskerLineColor', ColorNoise{i}*0.6, 'MarkerStyle', 'none', ...
        'JitterOutliers','off');

end

% Other settings
hold(ax2, 'off');
ax2.XTick = 1:length(Noise_Conds);
ax2.XTickLabel = replace(Noise_Conds, '_', ' ');
xlim(ax2, [0.5, length(Noise_Conds) + 0.5]);
ylim(ax2, [-20, 30]); % Custom
ylabel(ax2, 'SNR (dB)', 'FontWeight', 'bold');
title(ax2, 'HINT Results: Noise', 'FontSize', 16, 'FontWeight', 'bold');
% grid(ax2, 'on');
% ax2.GridLineStyle = '--';
% ax2.YGrid = 'on';
% ax2.XGrid = 'off';
set(ax2, 'FontName', 'Arial', 'FontSize', 10, 'Box', 'on', 'LineWidth', 1);

%% Stats

Res_CondStats = table('Size', [0,4], ...
    'VariableTypes', {'string', 'double', 'double', 'double'}, ...
    'VariableNames', {'Cond', 'T', 'P', 'AdjP'});

% Section 1: Paired t-test for Noise Left vs. Noise Right vs. Noise Front
[~, p_NL_NR, ~, stats_NL_NR] = ttest(HINT_Data.L, HINT_Data.R);
[~, p_NF_NL, ~, stats_NF_NL] = ttest(HINT_Data.F, HINT_Data.L);
[~, p_NF_NR, ~, stats_NF_NR] = ttest(HINT_Data.F, HINT_Data.R);

Stat_row1 = {"NL vs. NR", stats_NL_NR.tstat, p_NL_NR};
Stat_row2 = {"NF vs. NL", stats_NF_NL.tstat, p_NF_NL};
Stat_row3 = {"NF vs. NR", stats_NF_NR.tstat, p_NF_NR};

Res_CondStats = [Stat_row1; Stat_row2; Stat_row3];

% Section 2: Paired t-test for SRM
HINT_Data.SRM_FL = HINT_Data.F - HINT_Data.L;
HINT_Data.SRM_FR = HINT_Data.F - HINT_Data.R;

[~, p_SRM, ~, stats_SRM] = ttest(HINT_Data.SRM_FL, HINT_Data.SRM_FR);

Stat_row4 = {"SRM", stats_SRM.tstat, p_SRM};
Res_CondStats = [Res_CondStats; Stat_row4];

% Section 3: Independent t-tests between groups
Is_G2 = startsWith(HINT_Data.DyadID, 'G2');
HINT_G1 = HINT_Data(~Is_G2, :);
HINT_G2 = HINT_Data(Is_G2, :);

AddSRM_Conds = {'Q', 'F', 'L', 'R', 'SRM_FL', 'SRM_FR'};

Res_GroupStats = table('size', [0,3], ...
    'VariableTypes', {'string', 'double', 'double'}, ...
    'VariableNames', {'Cond', 'T', 'P'});

for j = 1:length(AddSRM_Conds)
    
    GCond = AddSRM_Conds{j};
    G1_data = HINT_G1.(GCond);
    G2_data = HINT_G2.(GCond);
    
    [~, p_Group, ~, stats_Group] = ttest2(G1_data, G2_data);
    
    Stat_row5 = {GCond, stats_Group.tstat, p_Group};
    Res_GroupStats = [Res_GroupStats; Stat_row5];

    % Apply Benjamini-Hochberg FDR
    RawP = Res_GroupStats.P;
    AdjP = mafdr(RawP, 'BHFDR', true);
    Res_GroupStats.AdjP = AdjP;

end
