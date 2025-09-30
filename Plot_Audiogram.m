%% Plot Audiogram Data %%

clear; clc;
close all;

%% Data Extraction

% Set datapath
AG_path = 'D:\Data.xlsx';
AG = detectImportOptions(AG_path, 'Sheet', 'AuditoryData');
Excluded_id = {'Sub005', 'Suv010'};

T = readtable(AG_path, AG);

if ~isempty(Excluded_id)
    Rows2Excluded = ismember(T.SubjID, Excluded_id);
    T(Rows2Excluded, :) = [];
else
    fprintf('No data to be excluded, skip that.')
end

VarNames = T.Properties.VariableNames;
AG_cols = VarNames(contains(VarNames, 'HT'));

FreqsTokens = regexp(AG_cols, '_(\d+)Hz', 'tokens'); % Get freqs var
Freqs_num = unique(cellfun(@(c) str2double(c{1}), FreqsTokens));

G1_group = startsWith(T.DyadID, 'G1'); G2_group = startsWith(T.DyadID, 'G2'); % Define groups
T_G1 = T(G1_group, :); T_G2 = T(G2_group, :);

Res_T_VarNames = {'G1_L_Mean', 'G1_L_Std', 'G1_R_Mean', 'G1_R_Std',...
                                 'G2_L_Mean', 'G2_L_Std', 'G2_R_Mean', 'G2_R_Std'};
Res = array2table(nan(length(Freqs_num), length(Res_T_VarNames)), ...
    'VariableNames',Res_T_VarNames, ...
    'RowNames', cellstr(string(Freqs_num) + "Hz"));

% Calculation
for i = 1:length(Freqs_num)
    
    F = Freqs_num(i);
    L_col = sprintf('HT_L_%dHz', F); R_col = sprintf('HT_R_%dHz', F);
    G1_L_Avg = mean(T_G1.(L_col)); G1_L_Std = std(T_G1.(L_col), 0);
    G1_R_Avg = mean(T_G1.(R_col)); G1_R_Std = std(T_G1.(R_col), 0);
    G2_L_Avg = mean(T_G2.(L_col)); G2_L_Std = std(T_G2.(L_col), 0);
    G2_R_Avg = mean(T_G2.(R_col)); G2_R_Std = std(T_G2.(R_col), 0);
    
    Res(i, :) = {G1_L_Avg, G1_L_Std, G1_R_Avg, G1_R_Std,...
                     G2_L_Avg, G2_L_Std, G2_R_Avg, G2_R_Std};

end

%%  Plot

figure('Position', [100, 100, 900, 700]); ax = gca; hold on;

% Color settings
c_G1_L = [0.5 0.7 1.0]; % Blue
c_G1_R = [0.5 0.9 0.7]; % Green
c_G2_L = [1.0 0.7 0.5]; % Orange
c_G2_R = [1.0 0.6 0.6]; % Red

% Plot std
FaceAlpha = 0.5;
x_Coor = [Freqs_num, fliplr(Freqs_num)];

y_Fill_G1_L = [Res.G1_L_Mean' - Res.G1_L_Std', fliplr(Res.G1_L_Mean' + Res.G1_L_Std')];
fill(x_Coor, y_Fill_G1_L, c_G1_L, 'FaceAlpha', FaceAlpha, 'EdgeColor', 'none'); hold on;

y_Fill_G1_R = [Res.G1_R_Mean' - Res.G1_R_Std', fliplr(Res.G1_R_Mean' + Res.G1_R_Std')];
fill(x_Coor, y_Fill_G1_R, c_G1_R, 'FaceAlpha', FaceAlpha, 'EdgeColor', 'none'); hold on;

y_Fill_G2_L = [Res.G2_L_Mean' - Res.G2_L_Std', fliplr(Res.G2_L_Mean' + Res.G2_L_Std')];
fill(x_Coor, y_Fill_G2_L, c_G2_L, 'FaceAlpha', FaceAlpha, 'EdgeColor', 'none'); hold on;

y_Fill_G2_R = [Res.G2_R_Mean' - Res.G2_R_Std', fliplr(Res.G2_R_Mean' + Res.G2_R_Std')];
fill(x_Coor, y_Fill_G2_R, c_G2_R, 'FaceAlpha', FaceAlpha, 'EdgeColor', 'none'); hold on;

% Plot stacked lines
h1 = plot(Freqs_num, Res.G1_L_Mean, 'o-', 'Color', c_G1_L*0.6, 'LineWidth', 2, ...
    'MarkerFaceColor', 'w', 'DisplayName', 'G1 Left');
h2 = plot(Freqs_num, Res.G1_R_Mean, 's-', 'Color', c_G1_R*0.6, 'LineWidth', 2, ...
    'MarkerFaceColor', 'w', 'DisplayName', 'G1 Right');
h3 = plot(Freqs_num, Res.G2_L_Mean, 'o--', 'Color', c_G2_L*0.6, 'LineWidth', 2, ...
    'MarkerFaceColor', 'w', 'DisplayName', 'G2 Left');
h4 = plot(Freqs_num, Res.G2_R_Mean, 's--', 'Color', c_G2_R*0.6, 'LineWidth', 2, ...
    'MarkerFaceColor', 'w', 'DisplayName', 'G2 Right');

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
ax.GridAlpha = 0.3;
ax.GridLineStyle = '--';

title('Group Audiogram', 'FontSize', 20, 'FontWeight', 'bold');
xlabel('Frequency (Hz)', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Hearing Level (dB HL)', 'FontSize', 12, 'FontWeight', 'bold');
legend([h1, h2, h3, h4], 'Location', 'southwest', 'FontSize', 10, 'NumColumns', 2);

hold off;
set(ax, 'FontName', 'Arial', 'FontSize', 10, 'Box', 'on', 'LineWidth', 1);
