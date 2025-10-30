%% Plot and Stats of Audiogram Data  %%

clear; clc;
close all;

%% Data Extraction

% Set datapath
AG_path = 'C:\Data.xlsx';
AG = detectImportOptions(AG_path, 'Sheet', 'AuditoryFunctions');
Excluded_id = {'OHL011', 'OHL020'};

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
N_ONH = height(T_ONH); N_OHL = height(T_OHL); 

Res_T_VarNames = {'ONH_L_Mean', 'ONH_L_Std', 'ONH_L_SEM', 'ONH_R_Mean', 'ONH_R_Std', 'ONH_R_SEM'...
                                 'OHL_L_Mean', 'OHL_L_Std', 'OHL_L_SEM', 'OHL_R_Mean', 'OHL_R_Std', 'OHL_R_SEM'};
Res = array2table(nan(length(Freqs_num), length(Res_T_VarNames)), ...
    'VariableNames', Res_T_VarNames, ...
    'RowNames', cellstr(string(Freqs_num) + "Hz"));

% Calculation
for i = 1:length(Freqs_num)
    
    F = Freqs_num(i);
    L_col = sprintf('HT_L_%dHz', F); R_col = sprintf('HT_R_%dHz', F);

    ONH_L_Avg = mean(T_ONH.(L_col)); 
    ONH_L_Std = std(T_ONH.(L_col), 0); 
    ONH_L_SEM = ONH_L_Std / sqrt(N_ONH);
    ONH_R_Avg = mean(T_ONH.(R_col)); 
    ONH_R_Std = std(T_ONH.(R_col), 0); 
    ONH_R_SEM = ONH_R_Std / sqrt(N_ONH);
    OHL_L_Avg = mean(T_OHL.(L_col)); 
    OHL_L_Std = std(T_OHL.(L_col), 0); 
    OHL_L_SEM = OHL_L_Std / sqrt(N_OHL);
    OHL_R_Avg = mean(T_OHL.(R_col)); 
    OHL_R_Std = std(T_OHL.(R_col), 0); 
    OHL_R_SEM = OHL_R_Std / sqrt(N_OHL);

    Res(i, :) = {ONH_L_Avg, ONH_L_Std, ONH_L_SEM, ...
                    ONH_R_Avg, ONH_R_Std, ONH_R_SEM, ...
                    OHL_L_Avg, OHL_L_Std, OHL_L_SEM, ...
                    OHL_R_Avg, OHL_R_Std, OHL_R_SEM};

end

%%  Plot

figure('Position', [100, 100, 900, 700]); ax = gca; hold on;

% Define background settings
Def_HearLevels = [-10, 25; 25, 40; 40, 55; 55, 70; 70, 90; 90, 120];
Def_HearLevelsLabels = {'Normal', 'Mild', 'Moderate', 'Moderate-Severe', 'Severe', 'Profound'};
GrayColors = linspace(0.95, 0.5, 6)'; GrayColors = repmat(GrayColors, 1, 3);

X_lim = [min(Freqs_num)*0.8, max(Freqs_num)*1.2];
X_fill = [X_lim(1), X_lim(2), X_lim(2), X_lim(1)];

for i = 1:size(Def_HearLevels, 1)
    
    Y_fill = [Def_HearLevels(i,1), Def_HearLevels(i,1), Def_HearLevels(i,2), Def_HearLevels(i,2)];
    fill(X_fill, Y_fill, GrayColors(i,:), 'EdgeColor', 'none', 'FaceAlpha', 0.5, 'HandleVisibility', 'off');
    text(X_lim(1)*1.05, mean(Def_HearLevels(i,:)), Def_HearLevelsLabels{i}, ...
        'HorizontalAlignment', 'left', 'VerticalAlignment', 'middle', ...
        'FontSize', 11, 'Color', [0.3 0.3 0.3], 'FontWeight', 'bold');

end

% Color settings
c_ONH_L = [0.301 0.745 0.933]; 
c_ONH_R = [0.93 0.65 0.53]; 
c_OHL_L = [0 0.4470 0.7410]; 
c_OHL_R = [0.85 0.325 0.098]; 

% Plot std (Shaded)
% FaceAlpha = 0.3;
% x_Coor = [Freqs_num, fliplr(Freqs_num)];
% 
% y_Fill_ONH_L = [Res.ONH_L_Mean' - Res.ONH_L_Std', fliplr(Res.ONH_L_Mean' + Res.ONH_L_Std')];
% fill(x_Coor, y_Fill_ONH_L, c_ONH_L, 'FaceAlpha', FaceAlpha, 'EdgeColor', 'none'); hold on;
% 
% y_Fill_ONH_R = [Res.ONH_R_Mean' - Res.ONH_R_Std', fliplr(Res.ONH_R_Mean' + Res.ONH_R_Std')];
% fill(x_Coor, y_Fill_ONH_R, c_ONH_R, 'FaceAlpha', FaceAlpha, 'EdgeColor', 'none'); hold on;
% 
% y_Fill_OHL_L = [Res.OHL_L_Mean' - Res.OHL_L_Std', fliplr(Res.OHL_L_Mean' + Res.OHL_L_Std')];
% fill(x_Coor, y_Fill_OHL_L, c_OHL_L, 'FaceAlpha', FaceAlpha, 'EdgeColor', 'none'); hold on;
% 
% y_Fill_OHL_R = [Res.OHL_R_Mean' - Res.OHL_R_Std', fliplr(Res.OHL_R_Mean' + Res.OHL_R_Std')];
% fill(x_Coor, y_Fill_OHL_R, c_OHL_R, 'FaceAlpha', FaceAlpha, 'EdgeColor', 'none'); hold on;

% Plot stacked lines
h1 = errorbar(Freqs_num, Res.ONH_R_Mean, Res.ONH_R_SEM, 'o-', 'MarkerSize', 8, 'Color', c_ONH_R, 'LineWidth', 1.2, ...
    'MarkerFaceColor', 'w', 'DisplayName', 'ONH Right', 'CapSize', 8);
h3 = errorbar(Freqs_num, Res.OHL_R_Mean, Res.OHL_R_SEM, 'o--', 'MarkerSize', 8, 'Color', c_OHL_R, 'LineWidth', 1.2, ...
    'MarkerFaceColor', 'w', 'DisplayName', 'OHL Right', 'CapSize', 8);
h2 = errorbar(Freqs_num, Res.ONH_L_Mean, Res.ONH_L_SEM, 'x-', 'MarkerSize', 8, 'Color', c_ONH_L, 'LineWidth', 1.2, ...
    'MarkerFaceColor', 'w', 'DisplayName', 'ONH Left', 'CapSize', 8);
h4 = errorbar(Freqs_num, Res.OHL_L_Mean, Res.OHL_L_SEM, 'x--', 'MarkerSize', 8, 'Color', c_OHL_L, 'LineWidth', 1.2, ...
    'MarkerFaceColor', 'w', 'DisplayName', 'OHL Left', 'CapSize', 8);

% Other settings
set(ax, 'XScale', 'log');
set(ax, 'TickDir', 'none');
set(ax, 'XAxisLocation', 'top'); 
set(ax, 'YDir', 'reverse');

xlim([min(Freqs_num)*0.8, max(Freqs_num)*1.2]); % Custom
ylim([-10, 120]);
xticks(Freqs_num);
yticks(-10:10:120);

ax.XGrid = 'off';
ax.YGrid = 'on';
ax.GridColor = [0.5 0.5 0.5]; % Grey grid
ax.GridAlpha = 0.2;
ax.GridLineStyle = ':';

title('Group Audiogram', 'FontSize', 20, 'FontWeight', 'bold');
xlabel('Frequency (Hz)', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Hearing Level (dB HL)', 'FontSize', 12, 'FontWeight', 'bold');
legend([h1, h2, h3, h4], 'Location', 'southeast', 'FontSize', 18, 'NumColumns', 2);

hold off;
set(ax, 'FontName', 'Arial', 'FontSize', 18, 'Box', 'on', 'LineWidth', 2, 'FontWeight', 'bold');

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

Res_Stats.AdjP = mafdr(Res_Stats.P, 'BHFDR', true); % Apply Benjamini-Hochberg FDR
