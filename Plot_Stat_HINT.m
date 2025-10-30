%% Plot and Stats of HINT Data %%

clear; clc;
close all;

addpath('Utils\slanCM\');

%% 1 Data Extraction

% Set datapath
HINT_path = 'C:\Data.xlsx';
HINT = detectImportOptions(HINT_path, 'Sheet', 'AuditoryFunctions');
Excluded_id = {'OHL011', 'OHL020'};

T = readtable(HINT_path, HINT);

if ~isempty(Excluded_id)
    Rows2Excluded = ismember(T.DyadID, Excluded_id);
    T(Rows2Excluded, :) = [];
else
    fprintf('No data to be excluded, skip that.')
end

VarNames = T.Properties.VariableNames;
HINT_cols = VarNames(contains(VarNames, 'HINT'));

Conds = {'Q', 'F', 'L', 'R'}; % Define HINT conditions

for k = 1:length(VarNames)
    CurVarName = VarNames{k};
    if contains(CurVarName, 'HINT_SNR') && iscell(T.(CurVarName)) % Check if the column is a HINT column AND is a cell array
        T.(CurVarName) = str2double(T.(CurVarName));
   end
end

% Initialization
HINT_Data = table(T.DyadID, 'VariableNames', {'DyadID'});
HINT_Data = [HINT_Data, array2table(nan(height(T), length(Conds)), 'VariableNames', Conds)];

% Loop
for i = 1:length(Conds)
    
    Cond = Conds{i};
    trial1_col = sprintf('HINT_SNR_%s_Trial1', Cond);
    trial2_col = sprintf('HINT_SNR_%s_Trial2', Cond);
    trial1re_col = sprintf('HINT_SNR_%s_Trial1_Re', Cond);
    trial2re_col = sprintf('HINT_SNR_%s_Trial2_Re', Cond);
    
    trial1_data = T.(trial1_col);
    trial2_data = T.(trial2_col);
    trial1re_data = T.(trial1re_col);
    trial2re_data = T.(trial2re_col);
    
    % Prioritizing 'Re' over 'Original', as well as 'Trial2' over 'Trial1'
    FinVal = trial1_data;
    Idx_trial2 = ~isnan(trial2_data);
    FinVal(Idx_trial2) = trial2_data(Idx_trial2);
    Idx_trial1_re = ~isnan(trial1re_data);
    FinVal(Idx_trial1_re) = trial1re_data(Idx_trial1_re);  
    Idx_trial2_re = ~isnan(trial2re_data);
    FinVal(Idx_trial2_re) = trial2re_data(Idx_trial2_re);
    
    HINT_Data.(Cond) = FinVal;
    
end

%% 2 Stats

Is_OHL = startsWith(HINT_Data.DyadID, 'OHL');
HINT_Data.Group = repmat(categorical({'ONH'}), height(HINT_Data), 1);
HINT_Data.Group(Is_OHL) = categorical({'OHL'});
HINT_ONH = HINT_Data(~Is_OHL, :);
HINT_OHL = HINT_Data(Is_OHL, :);

%% 2.1 Quiet Condition

Q_ONH = HINT_Data.Q(HINT_Data.Group == 'ONH');
Q_OHL = HINT_Data.Q(HINT_Data.Group == 'OHL');

[~, p_ndONH] = lillietest(Q_ONH); % Check whether data follows a normal distribution
[~, p_ndOHL] = lillietest(Q_OHL);

[~, p_Q, ~, stats_Q] = ttest2(Q_ONH, Q_OHL);

%% 2.2 Noise Conditions

WithinDesign = table(categorical({'F', 'L', 'R'}'), 'VariableNames', {'NoiseCondition'});

RM = fitrm(HINT_Data, 'F-R ~ Group', 'WithinDesign', WithinDesign);

ranova_Res = ranova(RM); % Within-Subjects effects
anova_Res = anova(RM); % Between-Subjects effects
% disp(ranova_res); disp(anova_res);

PostHoc_BS_NoiseCond = multcompare(RM, 'Group', 'By', 'NoiseCondition', 'ComparisonType', 'bonferroni');
PostHoc_WS_NoiseCond = multcompare(RM, 'NoiseCondition', 'By', 'Group', 'ComparisonType', 'bonferroni');

%% 2.3 SRM

Is_OHL = startsWith(HINT_Data.DyadID, 'OHL');
HINT_Data.Group = repmat(categorical({'ONH'}), height(HINT_Data), 1);
HINT_Data.Group(Is_OHL) = categorical({'OHL'});

% Using RM
% HINT_Data.SRM_L = HINT_Data.F - HINT_Data.L;
% HINT_Data.SRM_R = HINT_Data.F - HINT_Data.R;
% 
% WithinDesign = table(categorical({'L', 'R'}'), 'VariableNames', {'Location'});
% rm_SRM = fitrm(HINT_Data, 'SRM_L-SRM_R ~ Group', 'WithinDesign', WithinDesign);
% ranova_SRM_Res = ranova(rm_SRM);
% anova_SRM_Res = anova(rm_SRM);
% 
% PostHoc_SRM_BS = multcompare(rm_SRM, 'Group', 'By', 'Location', 'Compar  isonType', 'bonferroni');
% PostHoc_SRM_WS = multcompare(rm_SRM, 'Location', 'By', 'Group', 'ComparisonType', 'bonferroni');

% Using LME
HINT_Data.SRM_L = HINT_Data.F - HINT_Data.L;
HINT_Data.SRM_R = HINT_Data.F - HINT_Data.R;

SRMData_Wide = HINT_Data(:, {'DyadID', 'Group', 'SRM_L', 'SRM_R'});
SRMData_Long = stack(SRMData_Wide, {'SRM_L', 'SRM_R'}, 'NewDataVariableName', 'SRM', 'IndexVariableName', 'Location');
SRMData_Long.Location = categorical(SRMData_Long.Location, {'SRM_L', 'SRM_R'}, {'L', 'R'});
SRMData_Long.Group = categorical(SRMData_Long.Group);
SRMData_Long.DyadID = categorical(SRMData_Long.DyadID);

LME_Model = fitlme(SRMData_Long, 'SRM ~ Group*Location + (1|DyadID)', 'FitMethod', 'ML');
LME_anova = anova(LME_Model, 'dfmethod', 'satterthwaite');
disp(LME_anova);

%% 3 Plot 

%% 3.1 Quiet Conditions

figure('Position', [100, 100, 500, 700]);
ax1 = gca; hold(ax1, 'on');

ColorONH = [0 0.447 0.741];
ColorOHL = [0.85 0.325 0.098];

X_Center = 1;
BetGrpOffset = 0.2;
WitGrpOffset = 0.1;
JitterWidth = 0.05;

% ONH
ONH_QuietData = HINT_ONH.Q(~isnan(HINT_ONH.Q));
CenterONH = X_Center - BetGrpOffset;
X_scatter = CenterONH - WitGrpOffset + (rand(size(ONH_QuietData))-0.5) * JitterWidth;
h1_ONH = scatter(ax1, X_scatter, ONH_QuietData, 85, ColorONH, 'filled', 'MarkerFaceAlpha', 1);
Mean_ONH_QuietData = mean(ONH_QuietData);
SEM_ONH_QuietData = std(ONH_QuietData) / sqrt(length(ONH_QuietData));
errorbar(ax1, CenterONH + WitGrpOffset, Mean_ONH_QuietData, SEM_ONH_QuietData, 'o', 'Color', ColorONH, ...
    'MarkerFaceColor', ColorONH, 'MarkerSize', 12, 'LineWidth', 2, 'CapSize', 15);

% OHL
OHL_QuietData = HINT_OHL.Q(~isnan(HINT_OHL.Q));
CenterOHL = X_Center + BetGrpOffset;
X_scatter = CenterOHL - WitGrpOffset + (rand(size(OHL_QuietData))-0.5) * JitterWidth;
h1_OHL = scatter(ax1, X_scatter, OHL_QuietData, 85, ColorOHL, 'filled', 'MarkerFaceAlpha', 1);
Mean_OHL_QuietData = mean(OHL_QuietData);
SEM_OHL_QuietData = std(OHL_QuietData) / sqrt(length(OHL_QuietData));
errorbar(ax1, CenterOHL + WitGrpOffset, Mean_OHL_QuietData, SEM_OHL_QuietData, 'o', 'Color', ColorOHL, ...
    'MarkerFaceColor', ColorOHL, 'MarkerSize', 12, 'LineWidth', 2, 'CapSize', 15);

plot_sig_line(CenterONH, CenterOHL, ...
    max([ONH_QuietData; OHL_QuietData], [], 'omitnan') + (80-20)*0.15, ... % Height
    p_Q);

% Other settings
hold(ax1, 'off');
% ax1.XTick = [CenterONH, CenterOHL];
ax1.XTick = 1;
ax1.XTickLabel = {'Quiet'};
ax1.YTick = 30:10:70;
xlim(ax1, [0.5, 1.5]);
ylim(ax1, [20, 80]);
ylabel(ax1, 'SNR');
title(ax1, 'HINT Results: Quiet', 'FontSize', 18);
legend([h1_ONH, h1_OHL], {'ONH', 'OHL'}, 'Location', 'southeast', 'Box', 'off');
set(ax1, 'FontName', 'Arial', 'FontSize', 18, 'Box', 'off', 'LineWidth', 2, 'FontWeight', 'bold');

%% 3.2 Noise Conditions

figure('Position', [150, 150, 800, 700]);
ax2 = gca; hold(ax2, 'on');

ColorONH = [0 0.447 0.741];
ColorOHL = [0.85 0.325 0.098];

NoiseConds = {'F', 'L', 'R'};
BetGrpOffset = 0.2;
WitGrpOffset = 0.1;
JitterWidth = 0.05;

Mean_ONH_NoiseDataFrame = nan(1, length(NoiseConds));
Mean_OHL_NoiseDataFrame = nan(1, length(NoiseConds));

for i = 1:length(NoiseConds)
    
    NoiseCond = NoiseConds{i};
    X_Center = i;
    
    % ONH
    ONH_NoiseData = HINT_ONH.(NoiseCond);
    ONH_NoiseData = ONH_NoiseData(~isnan(ONH_NoiseData));
    CenterONH = X_Center - BetGrpOffset;
    X_scatter = CenterONH - WitGrpOffset + (rand(size(ONH_NoiseData))-0.5) * JitterWidth;
    h2_ONH = scatter(ax2, X_scatter, ONH_NoiseData, 85, ColorONH, 'filled', 'MarkerFaceAlpha', 1); % Scatter
    Mean_ONH_NoiseData = mean(ONH_NoiseData);
    SEM_ONH_NoiseData = std(ONH_NoiseData) / sqrt(length(ONH_NoiseData));
    errorbar(ax2, CenterONH + WitGrpOffset, Mean_ONH_NoiseData, SEM_ONH_NoiseData, 'o', 'Color', ColorONH, ...
        'MarkerFaceColor', ColorONH, 'MarkerSize', 12, 'LineWidth', 2, 'CapSize', 15); % Errorbar
    Mean_ONH_NoiseDataFrame(i) = Mean_ONH_NoiseData;

    % OHL
    OHL_NoiseData = HINT_OHL.(NoiseCond);
    OHL_NoiseData = OHL_NoiseData(~isnan(OHL_NoiseData));
    CenterOHL = X_Center + BetGrpOffset;
    X_scatter = CenterOHL - WitGrpOffset + (rand(size(OHL_NoiseData))-0.5) * JitterWidth;
    h2_OHL = scatter(ax2, X_scatter, OHL_NoiseData, 85, ColorOHL, 'filled', 'MarkerFaceAlpha', 1); % Scatter
    Mean_OHL_NoiseData = mean(OHL_NoiseData);
    SEM_OHL_NoiseData = std(OHL_NoiseData) / sqrt(length(OHL_NoiseData));
    errorbar(ax2, CenterOHL + WitGrpOffset, Mean_OHL_NoiseData, SEM_OHL_NoiseData, 'o', 'Color', ColorOHL, ...
        'MarkerFaceColor', ColorOHL, 'MarkerSize', 12, 'LineWidth', 2, 'CapSize', 15); % Errorbar
    Mean_OHL_NoiseDataFrame(i) = Mean_OHL_NoiseData;

    Y_level_GrpCmp(i) = max([ONH_NoiseData; OHL_NoiseData], [], 'omitnan') + (abs(-20-20))*0.05; % Height

    % Asterisks for group-wise comparison
    plot_sig_line(CenterONH, CenterOHL, ...
         Y_level_GrpCmp(i), ... 
         PostHoc_BS_NoiseCond.pValue(2*i)); 

end

% Asterisks for cond-wise comparison (Only for NL vs. NR)
Y_level_CondCmp = max(Y_level_GrpCmp) + (abs(-20-20))*0.05 * 2;
plot_sig_line(2+BetGrpOffset, 3+BetGrpOffset, Y_level_CondCmp, PostHoc_WS_NoiseCond.pValue(4)); % For ONH
plot_sig_line(2-BetGrpOffset, 3-BetGrpOffset, Y_level_CondCmp*1.5, PostHoc_WS_NoiseCond.pValue(10)); % For OHL

% Other settings
hold(ax2, 'off');
ax2.XTick = 1:length(NoiseConds);
ax2.XTickLabel = {'Noise Front', 'Noise Left', 'Noise Right'};
ax2.YTick = -20:10:20;
xlim(ax2, [0.5, length(NoiseConds) + 0.5]);
ylim(ax2, [-20, 20]);
ylabel(ax2, 'SNR');
title(ax2, 'HINT Results: Noise', 'FontSize', 18);
legend([h2_ONH, h2_OHL], {'ONH', 'OHL'}, 'Location', 'southeast', 'Box', 'off');
set(ax2, 'FontName', 'Arial', 'FontSize', 18, 'Box', 'off', 'LineWidth', 2, 'FontWeight', 'bold');

%% 3.3 Spatial Release From Masking (SRM)

figure('Position', [200, 200, 800, 700]);
ax3 = gca; hold(ax3, 'on');

BetGrpOffset = 0.2;
WitGrpOffset = 0.1;
JitterWidth = 0.05;

ColorONH = [0 0.447 0.741];
ColorOHL = [0.85 0.325 0.098];

SRMConds = {'SRM_L', 'SRM_R'};
SRMLabels = {'SRM (Left)', 'SRM (Right)'};

Mean_ONH_SRMDataFrame = nan(1, length(SRMConds));
Mean_OHL_SRMDataFrame = nan(1, length(SRMConds));

HINT_ONH.SRM_L = HINT_ONH.F - HINT_ONH.L;
HINT_ONH.SRM_R = HINT_ONH.F - HINT_ONH.R;
HINT_OHL.SRM_L = HINT_OHL.F - HINT_OHL.L;
HINT_OHL.SRM_R = HINT_OHL.F - HINT_OHL.R;

for i = 1:length(SRMConds)
    
    SRMCond = SRMConds{i};
    X_Center = i;

    % ONH
    ONH_SRMData = HINT_ONH.(SRMCond);
    ONH_SRMData = ONH_SRMData(~isnan(ONH_SRMData));
    CenterONH = X_Center - BetGrpOffset;
    X_scatter = CenterONH - WitGrpOffset + (rand(size(ONH_SRMData))-0.5) * JitterWidth;
    h3_ONH = scatter(ax3, X_scatter, ONH_SRMData, 85, ColorONH, 'filled', 'MarkerFaceAlpha', 1); % Scatter
    Mean_ONH_SRMData = mean(ONH_SRMData);
    SEM_ONH_SRMData = std(ONH_SRMData) / sqrt(length(ONH_SRMData));
    errorbar(ax3, CenterONH + WitGrpOffset, Mean_ONH_SRMData, SEM_ONH_SRMData, 'o', 'Color', ColorONH, ...
        'MarkerFaceColor', ColorONH, 'MarkerSize', 12, 'LineWidth', 2, 'CapSize', 15); % Errorbar
    Mean_ONH_SRMDataFrame(i) = Mean_ONH_SRMData;

    % OHL
    OHL_SRMData = HINT_OHL.(SRMCond);
    OHL_SRMData = OHL_SRMData(~isnan(OHL_SRMData));
    CenterOHL = X_Center + BetGrpOffset;
    X_scatter = CenterOHL - WitGrpOffset + (rand(size(OHL_SRMData))-0.5) * JitterWidth;
    h3_OHL = scatter(ax3, X_scatter, OHL_SRMData, 85, ColorOHL, 'filled', 'MarkerFaceAlpha', 1); % Scatter
    Mean_OHL_SRMData = mean(OHL_SRMData);
    SEM_OHL_SRMData = std(OHL_SRMData) / sqrt(length(OHL_SRMData));
    errorbar(ax3, CenterOHL + WitGrpOffset, Mean_OHL_SRMData, SEM_OHL_SRMData, 'o', 'Color', ColorOHL, ...
        'MarkerFaceColor', ColorOHL, 'MarkerSize', 12, 'LineWidth', 2, 'CapSize', 15); % Errorbar
    Mean_OHL_SRMDataFrame(i) = Mean_OHL_SRMData;

    % Y_level_GrpCmp(i) = max([ONH_SRMData; OHL_SRMData], [], 'omitnan') + (abs(-10-20))*0.05;

    % plot_sig_line(CenterONH, CenterOHL, ...
    %    Y_level_GrpCmp(i), ...
    %    Res_GroupStats.AdjP(i+4));
    
end

% Asterisks for cond-wise comparison
Y_level_CondCmp = max(Y_level_GrpCmp) + (abs(-10-20))*0.05 * 2.3;
% plot_sig_line(1, 2, Y_level_CondCmp, Res_CondStats.AdjP(10)); % Overall
plot_sig_line(1-BetGrpOffset, 2-BetGrpOffset, Y_level_CondCmp*0.8, 0.0001); % For ONH
plot_sig_line(1+BetGrpOffset, 2+BetGrpOffset, Y_level_CondCmp, 0.0001); % For OHL
plot_sig_line(0.8, 1.2, Y_level_CondCmp*0.5, 0.005);

% Other settings
hold(ax3, 'off');
ax3.XTick = 1:length(SRMConds);
ax3.XTickLabel = SRMLabels;
ax3.YTick = -10:10:20;
xlim(ax3, [0.5, length(SRMConds)+0.5]);
ylim(ax3, [-10, 20]);
ylabel(ax3, 'dB / SNR');
title(ax3, 'HINT Results: Spatial Release Masking (SRM)', 'FontSize', 18);
legend([h3_ONH, h3_OHL], {'ONH', 'OHL'}, 'Location', 'southeast', 'Box', 'off');
set(ax3, 'FontName', 'Arial', 'FontSize', 18, 'Box', 'off', 'LineWidth', 2, 'FontWeight', 'bold');

%% Function

function plot_sig_line(x1, x2, y, Pval)
    
    if Pval < 0.05
        
        ax = gca;
        y_range = diff(ax.YLim);
        h_hook = y_range * 0.02;
        line_x = [x1, x1, x2, x2];
        line_y = [y - h_hook, y, y, y - h_hook];
        plot(line_x, line_y, '-k', 'LineWidth', 2, 'HandleVisibility', 'off');
        text_offset = y_range * 0.01;

        if Pval < 0.001
            Sigtext = '***';
        elseif Pval < 0.01
            Sigtext = '**';
        else
            Sigtext = '*';
        end
        
        text(mean([x1, x2]), y + text_offset, Sigtext, 'FontSize', 25, ...
             'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontWeight', 'bold');

    end
    
end
