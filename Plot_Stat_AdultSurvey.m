%% Plot and Stats of Adult Survey Score After Speech Sessions %%

clear; clc;
close all;

addpath('Utils\');

%% 1 Data Extraction

% Set datapath
AS_path = 'C:\Data.xlsx';
AS = detectImportOptions(AS_path, 'Sheet', 'AdultSurvey');

T = readtable(AS_path, AS);

T_PostQuiet = T(strcmp(T.Conds, 'PostQuiet'), :);
T_PostNoise = T(strcmp(T.Conds, 'PostNoise'), :);
T_PostQuiet_ONH = T_PostQuiet(startsWith(T_PostQuiet.DyadID, 'ONH', 'IgnoreCase', true), :);
T_PostQuiet_OHL = T_PostQuiet(startsWith(T_PostQuiet.DyadID, 'OHL', 'IgnoreCase', true), :);
T_PostNoise_ONH = T_PostNoise(startsWith(T_PostNoise.DyadID, 'ONH', 'IgnoreCase', true), :);
T_PostNoise_OHL = T_PostNoise(startsWith(T_PostNoise.DyadID, 'OHL', 'IgnoreCase', true), :);

QuestionsNames = {'Q1', 'Q2', 'Q3', 'Q4', 'Q5', 'Q6'};

%% 2 Stats

%% 2.1 Independent t-test for groupwise comparison

Res_GrpCmp = table('size', [0,4], ...
    'VariableTypes', {'string', 'string', 'double', 'double'}, ...
    'VariableNames', {'Cond', 'Questions', 'T', 'P'});

for Conds = {'PostQuiet', 'PostNoise'}

    Curcond = Conds{1};
    
    if strcmp(Curcond, 'PostQuiet')
        ONH_data = T_PostQuiet_ONH;
        OHL_data = T_PostQuiet_OHL;
    else
        ONH_data = T_PostNoise_ONH;
        OHL_data = T_PostNoise_OHL;
    end
    
    for i = 1:length(QuestionsNames)
        
        Q = QuestionsNames{i};

        [~, p, ~, stats] = ttest2(ONH_data.(Q), OHL_data.(Q));
        Stat_row1 = {Curcond, Q, stats.tstat, p};
        Res_GrpCmp = [Res_GrpCmp; Stat_row1];
        
    end

end

% Apply Benjamini-Hochberg FDR
Res_GrpCmp.AdjP = mafdr(Res_GrpCmp.P, 'BHFDR', true);

%% 2.2 Paired t-test for condwise comparison

Res_CondCmp = table('size', [0,4], ...
    'VariableTypes', {'string', 'string', 'double', 'double'}, ...
    'VariableNames', {'Questions', 'Groups', 'T', 'P'});
    
for i = 1:length(QuestionsNames)
        
        Q = QuestionsNames{i};
        
        [~, p, ~, stats] = ttest(T_PostQuiet.(Q), T_PostNoise.(Q));
        Stat_row2 = {Q, 'Overall', stats.tstat, p};
        [~, p_Eff_ONH, ~, stats_Eff_ONH] = ttest(T_PostQuiet_ONH.(Q), T_PostNoise_ONH.(Q));
        Stat_row3 = {Q, 'ONH', stats_Eff_ONH.tstat, p_Eff_ONH};
        [~, p_Eff_OHL, ~, stats_Eff_OHL] = ttest(T_PostQuiet_OHL.(Q), T_PostNoise_OHL.(Q));
        Stat_row4 = {Q, 'OHL', stats_Eff_OHL.tstat, p_Eff_OHL};

        Res_CondCmp = [Res_CondCmp; Stat_row2; Stat_row3; Stat_row4];

end

% Apply Benjamini-Hochberg FDR
Res_CondCmp.AdjP = mafdr(Res_CondCmp.P, 'BHFDR', true);

%% 2.3 To Test Whether Conds Order Effects Tendency of Survey Scores

Order = detectImportOptions(AS_path, 'Sheet', 'Demographics');
Order.SelectedVariableNames = {'DyadID', 'Visit2SIQSINBalance_0_QuietFirst_1_NoiseFirst_'};
OrderT = readtable(AS_path, Order);

[lia, locb] = ismember(upper(T.DyadID), upper(OrderT.DyadID));
if isnumeric(OrderT.Visit2SIQSINBalance_0_QuietFirst_1_NoiseFirst_)
    T.CondsOrder = NaN(height(T),1);
else
    T.CondsOrder = strings(height(T),1);
end
T.CondsOrder(lia) = OrderT.Visit2SIQSINBalance_0_QuietFirst_1_NoiseFirst_(locb(lia));

T1 = T;

Res_Effect = table('size', [0,4], ...
    'VariableTypes', {'string', 'string', 'double', 'double'}, ...
    'VariableNames', {'Questions', 'Groups', 'T', 'P'});

T1_PostQuiet = T1(strcmp(T1.Conds, 'PostQuiet'), :);
T1_PostNoise = T1(strcmp(T1.Conds, 'PostNoise'), :);
T1_PostQuiet_ONH = T1_PostQuiet(startsWith(T1_PostQuiet.DyadID, 'ONH', 'IgnoreCase', true), :);
T1_PostQuiet_OHL = T1_PostQuiet(startsWith(T1_PostQuiet.DyadID, 'OHL', 'IgnoreCase', true), :);
T1_PostNoise_ONH = T1_PostNoise(startsWith(T1_PostNoise.DyadID, 'ONH', 'IgnoreCase', true), :);
T1_PostNoise_OHL = T1_PostNoise(startsWith(T1_PostNoise.DyadID, 'OHL', 'IgnoreCase', true), :);

Order_Overall = T1_PostQuiet.CondsOrder;
Order_ONH = T1_PostQuiet_ONH.CondsOrder;
Order_OHL = T1_PostQuiet_OHL.CondsOrder;

for i = 1:length(QuestionsNames)
   
    Q = QuestionsNames{i};
    
    Diff_Overall = T1_PostNoise.(Q) - T1_PostQuiet.(Q);
    Diff_ONH = T1_PostNoise_ONH.(Q) - T1_PostQuiet_ONH.(Q);
    Diff_OHL = T1_PostNoise_OHL.(Q) - T1_PostQuiet_OHL.(Q);

    Diff_Overall_Order0 = Diff_Overall(Order_Overall == 0);
    Diff_Overall_Order1 = Diff_Overall(Order_Overall == 1); 
    Diff_ONH_Order0 = Diff_ONH(Order_ONH == 0);
    Diff_ONH_Order1 = Diff_ONH(Order_ONH == 1); 
    Diff_OHL_Order0 = Diff_OHL(Order_OHL == 0);
    Diff_OHL_Order1 = Diff_OHL(Order_OHL == 1);
    
    [~, p_Eff_Overall, ~, stats_Eff_Overall] = ttest2(Diff_Overall_Order0, Diff_Overall_Order1);
    Stat_row_Eff_Overall = {Q, 'Overall', stats_Eff_Overall.tstat, p_Eff_Overall};
    [~, p_Eff_ONH, ~, stats_Eff_ONH] = ttest2(Diff_ONH_Order0, Diff_ONH_Order1);
    Stat_row_Eff_ONH = {Q, 'ONH', stats_Eff_ONH.tstat, p_Eff_ONH};
    [~, p_Eff_OHL, ~, stats_Eff_OHL] = ttest2(Diff_OHL_Order0, Diff_OHL_Order1);
    Stat_row_Eff_OHL = {Q, 'OHL', stats_Eff_OHL.tstat, p_Eff_OHL};

    Res_Effect = [Res_Effect; Stat_row_Eff_Overall; Stat_row_Eff_ONH; Stat_row_Eff_OHL];

end

%% 3 Plot

%% 3.1 Overall

ColorAS = slanCM(177,6);

% Section 1: ONH
figure('Position', [100, 100, 800, 600]);

% Calculate means and SEM
Means_ONH = [mean(T_PostQuiet_ONH{:, QuestionsNames}); 
    mean(T_PostNoise_ONH{:, QuestionsNames})];
SEM_ONH = [std(T_PostQuiet_ONH{:, QuestionsNames})/sqrt(height(T_PostQuiet_ONH)); 
    std(T_PostNoise_ONH{:, QuestionsNames})/sqrt(height(T_PostNoise_ONH))];
Bar_ONH = bar(Means_ONH, 'grouped');
hold on;
for k = 1:length(Bar_ONH) % Apply colors to bars
    Bar_ONH(k).FaceColor = ColorAS(k, :);
end

% Calculate error bar positions
nGroups = size(Means_ONH, 1);
nBars = size(Means_ONH, 2);
GroupWidth = min(0.8, nBars/(nBars + 1.5));
for i = 1:nBars
    x = (1:nGroups) - GroupWidth/2 + (2*i-1) * GroupWidth / (2*nBars);
    errorbar(x, Means_ONH(:,i), SEM_ONH(:,i), 'k', 'linestyle', 'none');
end
hold off;

% Other settings
title('Adult Survey Scores: ONH Group', 'FontSize', 20, 'FontWeight','bold');
ylabel('Score (1-10)', 'FontWeight','bold');
ylim([0 10]);
ax = gca;
ax.XTickLabel = {'PostQuiet', 'PostNoise'};
ax.TickDir = 'none';
legend(QuestionsNames, 'Location', 'northeastoutside', 'NumColumns', 2, 'Color', 'none');
set(ax, 'FontName', 'Arial', 'FontSize', 18, 'Box', 'off', 'LineWidth', 1, 'Color', 'none', 'FontWeight', 'bold');
% grid on;

% Section 2: OHL
figure('Position', [100, 100, 800, 600]);

% Calculate means and SEM
Means_OHL = [mean(T_PostQuiet_OHL{:, QuestionsNames}); 
    mean(T_PostNoise_OHL{:, QuestionsNames})];
SEM_OHL = [std(T_PostQuiet_OHL{:, QuestionsNames})/sqrt(height(T_PostQuiet_OHL)); 
    std(T_PostNoise_OHL{:, QuestionsNames})/sqrt(height(T_PostNoise_OHL))];
Bar_OHL = bar(Means_OHL, 'grouped');
hold on;
for k = 1:length(Bar_OHL) % Apply colors to bars
    Bar_OHL(k).FaceColor = ColorAS(k, :);
end

% Calculate error bar positions
nGroups = size(Means_OHL, 1);
nBars = size(Means_OHL, 2);
GroupWidth = min(0.8, nBars/(nBars + 1.5));
for i = 1:nBars
    x = (1:nGroups) - GroupWidth/2 + (2*i-1) * GroupWidth / (2*nBars);
    errorbar(x, Means_OHL(:,i), SEM_OHL(:,i), 'k', 'linestyle', 'none');
end
hold off;

% Other settings
title('Adult Survey Scores: OHL Group', 'FontSize', 20, 'FontWeight', 'bold');
ylabel('Score', 'FontWeight','bold');
ylim([0 10]);
ax = gca;
ax.XTickLabel = {'PostQuiet', 'PostNoise'};
ax.TickDir = 'in';
legend({'Mental Demands', 'Physical Demands', 'Temporal Demands', 'Effort Demands', 'Frustration', 'Performance'}, ...
    'Location', 'northeastoutside', 'NumColumns', 1, 'Color', 'none');
set(ax, 'FontName', 'Arial', 'FontSize', 18, 'Box', 'off', 'LineWidth', 1, 'Color', 'none', 'FontWeight', 'bold');
grid on;

%% 3.2 Separate by Dumbbell Plot

ColorQuiet = [242 197 124] / 255;
ColorNoise = [66 106 90] / 255;
ColorConn = [0.4 0.4 0.4]; % Grey

X_Centers = 1:length(QuestionsNames);
Cond_Offset = 0.15;
JitterWidth = 0.03;

%% 3.2.1 ONH Plot

figure('Position', [100, 100, 1600, 700]);
ax1 = gca; hold(ax1, 'on');

X_Quiet = X_Centers - Cond_Offset; X_Noise = X_Centers + Cond_Offset;

% Loop
for i = 1:length(QuestionsNames)
    
    Q = QuestionsNames{i};
    
    QuietData = T_PostQuiet_ONH.(Q);
    NoiseData = T_PostNoise_ONH.(Q);
    
    % Conn lines
    for Subj = 1:height(T_PostQuiet_ONH)
        plot(ax1, [X_Quiet(i), X_Noise(i)], [QuietData(Subj), NoiseData(Subj)], ...
             ':', 'Color', ColorConn, 'LineWidth', 0.9, 'HandleVisibility', 'off');
    end
    
    % PostQuiet scattered
    X_ScatterQuiet = X_Quiet(i) + (rand(size(QuietData)) - 0.5) * JitterWidth;
    scatter(ax1, X_ScatterQuiet, QuietData, 85, ColorQuiet, 'filled', 'MarkerFaceAlpha', 1);
            
    % PostNoise scattered
    X_ScatterNoise = X_Noise(i) + (rand(size(NoiseData)) - 0.5) * JitterWidth;
    scatter(ax1, X_ScatterNoise, NoiseData, 85, ColorNoise, 'filled', 'MarkerFaceAlpha', 1);
            
    % Median points
    % plot(ax1, x_quiet(i), mean(data_quiet,'omitnan'), 'o', 'MarkerSize', 12, ...
    %       'MarkerFaceColor', 'w', 'MarkerEdgeColor', color_quiet*0.5, 'LineWidth', 2);
    % plot(ax1, x_noise(i), mean(data_noise,'omitnan'), 's', 'MarkerSize', 12, ...
    %       'MarkerFaceColor', 'w', 'MarkerEdgeColor', color_noise*0.5, 'LineWidth', 2);

end

% Other settings
hold(ax1, 'off');
title('Adult Survey Scores: ONH Group');
ylabel('Scores');
ylim([0 10.5]);
yticks(0:1:10);
ax1.XTick = X_Centers;
ax1.XTickLabel = {'Mental Demands', 'Physical Demands', 'Temporal Demands', 'Effort Demands', 'Frustration', 'Performance'};
legend(ax1, {'PostQuiet', 'PostNoise'}, 'Location', 'southeast', 'Box', 'off');
set(ax1, 'FontName', 'Arial', 'FontSize', 14, 'Box', 'on', 'LineWidth', 1, 'FontWeight', 'bold', 'Box', 'off');
grid off;

%% 3.2.2 OHL Plot

figure('Position', [150, 150, 1600, 700]);
ax2 = gca; hold(ax2, 'on');

% Loop
for i = 1:length(QuestionsNames)
    
    Q = QuestionsNames{i};
    
    QuietData = T_PostQuiet_OHL.(Q);
    NoiseData = T_PostNoise_OHL.(Q);
    
    % Conn lines
    for Subj = 1:height(T_PostQuiet_OHL)
        plot(ax2, [X_Quiet(i), X_Noise(i)], [QuietData(Subj), NoiseData(Subj)], ...
             ':', 'Color', ColorConn, 'LineWidth', 0.9, 'HandleVisibility', 'off');
    end
    
    % PostQuiet scattered
    X_ScatterQuiet = X_Quiet(i) + (rand(size(QuietData)) - 0.5) * JitterWidth;
    scatter(ax2, X_ScatterQuiet, QuietData, 85, ColorQuiet, 'filled', 'MarkerFaceAlpha', 1);
            
    % PostNoise scattered
    X_ScatterNoise = X_Noise(i) + (rand(size(NoiseData)) - 0.5) * JitterWidth;
    scatter(ax2, X_ScatterNoise, NoiseData, 85, ColorNoise, 'filled', 'MarkerFaceAlpha', 1);
            
    % Median points
    % plot(ax2, x_quiet(i), mean(data_quiet,'omitnan'), 'o', 'MarkerSize', 12, ...
    %       'MarkerFaceColor', 'w', 'MarkerEdgeColor', color_quiet*0.5, 'LineWidth', 2);
    % plot(ax2, x_noise(i), mean(data_noise,'omitnan'), 's', 'MarkerSize', 12, ...
    %       'MarkerFaceColor', 'w', 'MarkerEdgeColor', color_noise*0.5, 'LineWidth', 2);

end

% Other settings
hold(ax2, 'off');
title('Adult Survey Scores: OHL Group');
ylabel('Scores');
ylim([0 10.5]);
yticks(0:1:10);
ax2.XTick = X_Centers;
ax2.XTickLabel = {'Mental Demands', 'Physical Demands', 'Temporal Demands', 'Effort Demands', 'Frustration', 'Performance'};
legend(ax2, {'PostQuiet', 'PostNoise'}, 'Location', 'southeast', 'Box', 'off');
set(ax2, 'FontName', 'Arial', 'FontSize', 14, 'Box', 'on', 'LineWidth', 1, 'FontWeight', 'bold', 'Box', 'off');
grid off;
