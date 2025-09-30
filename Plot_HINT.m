%% Plot HINT Data %%

clear; clc;
close all;

%% Data Extraction

% Set datapath
HINT_path = 'D:\Data.xlsx';
HINT = detectImportOptions(HINT_path, 'Sheet', 'AuditoryData');

T = readtable(HINT_path, HINT);

VarNames = T.Properties.VariableNames;
HINT_cols = VarNames(contains(VarNames, 'HINT'));

Conds = {'Cond1', 'Cond2', 'Cond3', 'Cond4'}; % Set conds

% Initialization
HINT_Data = table(T.DyadID, 'VariableNames', {'SubjID'});
HINT_Data = [HINT_Data, array2table(nan(height(T), length(Conds)), 'VariableNames', Conds)];

for i = 1:length(Conds)
    
    Cur_cond = Conds{i};
    
    T1_col = sprintf('SNR_%s_Trial1', Cur_cond);
    T2_col = sprintf('SNR_%s_Trial2', Cur_cond);

    T1_data = T.(T1_col); % Extraction
    T2_data = T.(T2_col);
    
    % Logically
    FinVal = T1_data;
    T2_valid_idx = ~isnan(T2_data);
    FinVal(T2_valid_idx) = T2_data(T2_valid_idx);

    HINT_Data.(Cur_cond) = FinVal;
    
end

%% Plot

figure('Position', [100,100,1000,700]);
ax = gca; hold on;

% Color settings
Colors = {[0.5 0.7 1.0], ...   % Blue
           [1.0 0.7 0.5], ...   % Orange
           [0.5 0.9 0.7], ...   % Green
           [1.0 0.6 0.6]};     % Red
       
% Scatter and box plot
for i = 1:length(Conds)

    PlotData = HINT_Data.(Conds{i});
    PlotData = PlotData(~isnan(PlotData));
    
    % Scatter
    Jit_amount = 0.25;
    XJit = i + (rand(size(PlotData))-0.5) * Jit_amount;
    scatter(XJit, PlotData, 50, Colors{i}, 'filled', 'MarkerFaceAlpha', 0.6, 'DisplayName', 'Individual Data');
    
    % Box
    XBox = repmat(i, size(PlotData));
    boxchart(XBox, PlotData, ...
        'BoxWidth', 0.5, ...
        'BoxFaceColor', Colors{i}, ...
        'BoxFaceAlpha', 0.4, ...
        'WhiskerLineColor', Colors{i}*0.6, ...
        'MarkerStyle', 'none');

end

hold off;

% Other settings
ax.XTick = 1:length(Conds);
Xtick_labels = replace(Conds, '_', ' '); 
ax.XTickLabel = Xtick_labels;
xtickangle(0);
xlim([0.5, length(Conds)+0.5]);

ylabel('SNR (dB)', 'FontWeight', 'bold');

title('HINT Speech Reception Results', 'FontSize', 16, 'FontWeight', 'bold');

grid on;
ax.GridLineStyle = '--';
ax.GridAlpha = 0.5;
ax.YGrid = 'on';
ax.XGrid = 'off';

set(ax, 'FontName', 'Arial', 'FontSize', 10, 'Box', 'on', 'LineWidth',1);
