%% Audiogram Data Plot and Stats %%

clear; clc;
close all;

%% Data Extraction

% Set datapath
AG_path = 'C:\Users\Downloads\Data.xlsx';
AG = detectImportOptions(AG_path, 'Sheet', 'AuditoryFunctions');
Excluded_id = {'OHL011', 'OHL012', 'OHL020', 'OHL027', 'OHL035'};

T = readtable(AG_path, AG);

if ~isempty(Excluded_id)
    Rows2Excluded = ismember(T.DyadID, Excluded_id);
    T(Rows2Excluded, :) = [];
else
    fprintf('No data to be excluded, skip that.')
end

VarNames = T.Properties.VariableNames;
AG_cols = VarNames(contains(VarNames, 'HT'));

FreqsTokens = regexp(AG_cols, '_(\d+)Hz', 'tokens'); % Get freqs var
Freqs_num = unique(cellfun(@(c) str2double(c{1}), FreqsTokens));

ONH_group = startsWith(T.DyadID, 'ONH'); OHL_group = startsWith(T.DyadID, 'OHL'); % Define groups
T_ONH = T(ONH_group, :); T_OHL = T(OHL_group, :);

Res_T_VarNames = {'ONH_L_Mean', 'ONH_L_Std', 'ONH_R_Mean', 'ONH_R_Std',...
                                 'OHL_L_Mean', 'OHL_L_Std', 'OHL_R_Mean', 'OHL_R_Std'};
Res = array2table(nan(length(Freqs_num), length(Res_T_VarNames)), ...
    'VariableNames',Res_T_VarNames, ...
    'RowNames', cellstr(string(Freqs_num) + "Hz"));

% Calculation
for i = 1:length(Freqs_num)
    
    F = Freqs_num(i);
    L_col = sprintf('HT_L_%dHz', F); R_col = sprintf('HT_R_%dHz', F);
    ONH_L_Avg = mean(T_ONH.(L_col)); ONH_L_Std = std(T_ONH.(L_col), 0);
    ONH_R_Avg = mean(T_ONH.(R_col)); ONH_R_Std = std(T_ONH.(R_col), 0);
    OHL_L_Avg = mean(T_OHL.(L_col)); OHL_L_Std = std(T_OHL.(L_col), 0);
    OHL_R_Avg = mean(T_OHL.(R_col)); OHL_R_Std = std(T_OHL.(R_col), 0);
    Res(i, :) = {ONH_L_Avg, ONH_L_Std, ONH_R_Avg, ONH_R_Std,...
                     OHL_L_Avg, OHL_L_Std, OHL_R_Avg, OHL_R_Std};

end

%%  Plot

figure('Position', [100, 100, 900, 700]); ax = gca; hold on;

% Color settings
c_ONH_L = [0.301 0.745 0.933]; 
c_ONH_R = [0.93 0.65 0.53]; 
c_OHL_L = [0 0.4470 0.7410]; 
c_OHL_R = [0.85 0.325 0.098]; 

% Plot std
FaceAlpha = 0.3;
x_Coor = [Freqs_num, fliplr(Freqs_num)];

y_Fill_ONH_L = [Res.ONH_L_Mean' - Res.ONH_L_Std', fliplr(Res.ONH_L_Mean' + Res.ONH_L_Std')];
fill(x_Coor, y_Fill_ONH_L, c_ONH_L, 'FaceAlpha', FaceAlpha, 'EdgeColor', 'none'); hold on;

y_Fill_ONH_R = [Res.ONH_R_Mean' - Res.ONH_R_Std', fliplr(Res.ONH_R_Mean' + Res.ONH_R_Std')];
fill(x_Coor, y_Fill_ONH_R, c_ONH_R, 'FaceAlpha', FaceAlpha, 'EdgeColor', 'none'); hold on;

y_Fill_OHL_L = [Res.OHL_L_Mean' - Res.OHL_L_Std', fliplr(Res.OHL_L_Mean' + Res.OHL_L_Std')];
fill(x_Coor, y_Fill_OHL_L, c_OHL_L, 'FaceAlpha', FaceAlpha, 'EdgeColor', 'none'); hold on;

y_Fill_OHL_R = [Res.OHL_R_Mean' - Res.OHL_R_Std', fliplr(Res.OHL_R_Mean' + Res.OHL_R_Std')];
fill(x_Coor, y_Fill_OHL_R, c_OHL_R, 'FaceAlpha', FaceAlpha, 'EdgeColor', 'none'); hold on;

% Plot stacked lines
h1 = plot(Freqs_num, Res.ONH_R_Mean, 'o-', 'MarkerSize', 10, 'Color', c_ONH_R, 'LineWidth', 1.5, ...
    'MarkerFaceColor', 'w', 'DisplayName', 'ONH Right');
h3 = plot(Freqs_num, Res.OHL_R_Mean, 'o--', 'MarkerSize', 10, 'Color', c_OHL_R, 'LineWidth', 1.5, ...
    'MarkerFaceColor', 'w', 'DisplayName', 'OHL Right');
h2 = plot(Freqs_num, Res.ONH_L_Mean, 'x-', 'MarkerSize', 10, 'Color', c_ONH_L, 'LineWidth', 1.5, ...
    'MarkerFaceColor', 'w', 'DisplayName', 'ONH Left');
h4 = plot(Freqs_num, Res.OHL_L_Mean, 'x--', 'MarkerSize', 10, 'Color', c_OHL_L, 'LineWidth', 1.5, ...
    'MarkerFaceColor', 'w', 'DisplayName', 'OHL Left');

% Other settings
set(ax, 'XScale', 'log');
set(ax, 'TickDir', 'none');
set(ax, 'XAxisLocation', 'top'); 
set(ax, 'YDir', 'reverse');

xlim([min(Freqs_num)*0.8, max(Freqs_num)*1.2]); % Custom
ylim([-10, 120]);
xticks(Freqs_num);
yticks(-10:10:120);

grid on;
ax.GridColor = [0.5 0.5 0.5]; % Grey grid
ax.GridAlpha = 0.2;
ax.GridLineStyle = ':';

title('Group Audiogram', 'FontSize', 20, 'FontWeight', 'bold');
xlabel('Frequency (Hz)', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Hearing Level (dB HL)', 'FontSize', 12, 'FontWeight', 'bold');
legend([h1, h2, h3, h4], 'Location', 'southwest', 'FontSize', 10, 'NumColumns', 2);

hold off;
set(ax, 'FontName', 'Arial', 'FontSize', 10, 'Box', 'on', 'LineWidth', 2);

%% Stats

Res_Stats = table('Size', [0,4], ...
    'VariableTypes', {'string', 'double', 'double', 'double'}, ...
    'VariableNames', {'Group', 'Frequency', 'T', 'P'});

for g = 1:2

    if g == 1
       gGroups = "ONH"; gT = T_ONH;
    else
       gGroups = "OHL"; gT = T_OHL;
    end

    for k = 1:length(Freqs_num)

        F = Freqs_num(k);
        hL_col = sprintf('HT_L_%dHz', F);
        hR_col = sprintf('HT_R_%dHz', F);

        hL_data = gT.(hL_col);
        hR_data = gT.(hR_col);

        [h, p, ci, stats] = ttest(hL_data, hR_data); % Paired t-test
        t_stat = stats.tstat;

        Stat_row = {gGroups, F, t_stat, p};
        Res_Stats = [Res_Stats; Stat_row];

    end

end
