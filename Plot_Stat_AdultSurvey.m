%% Plot and Stats of Adult Survey Score After Speech Sessions %%

clear; clc;
close all;

%% Data Extraction

% Set datapath
AS_path = 'C:\Users\Data.xlsx';
AS = detectImportOptions(AS_path, 'Sheet', 'Survey');

T = readtable(AS_path, AS);

T_PostQuiet = T(strcmp(T.Conds, 'PostQuiet'), :);
T_PostNoise = T(strcmp(T.Conds, 'PostNoise'), :);
T_PostQuiet_G1 = T_PostQuiet(startsWith(T_PostQuiet.DyadID, 'G1'), :);
T_PostQuiet_G2 = T_PostQuiet(startsWith(T_PostQuiet.DyadID, 'G2'), :);
T_PostNoise_G1 = T_PostNoise(startsWith(T_PostNoise.DyadID, 'G1'), :);
T_PostNoise_G2 = T_PostNoise(startsWith(T_PostNoise.DyadID, 'G2'), :);

QuestionsNames = {'Q1', 'Q2', 'Q3', 'Q4', 'Q5', 'Q6'};

%% Plot

ColorAS = [0.301, 0.745, 0.933;  
           0.466, 0.674, 0.188; 
           0.929, 0.694, 0.125; 
           0.494, 0.184, 0.556; 
           0.85, 0.325, 0.098;  
           0.635, 0.078, 0.184]; % Light Blue, Green, Yellow-Orange, Purple, Red-Orange, Maroon

% Section 1: G1
figure('Position', [100, 100, 800, 600]);

% Calculate means and SEM
Means_G1 = [mean(T_PostQuiet_G1{:, QuestionsNames}); 
    mean(T_PostNoise_G1{:, QuestionsNames})];
SEM_G1 = [std(T_PostQuiet_G1{:, QuestionsNames})/sqrt(height(T_PostQuiet_G1)); 
    std(T_PostNoise_G1{:, QuestionsNames})/sqrt(height(T_PostNoise_G1))];
Bar_G1 = bar(Means_G1, 'grouped');
hold on;
for k = 1:length(Bar_G1) % Apply colors to bars
    Bar_G1(k).FaceColor = ColorAS(k, :);
end

% Calculate error bar positions
nGroups = size(Means_G1, 1);
nBars = size(Means_G1, 2);
GroupWidth = min(0.8, nBars/(nBars + 1.5));
for i = 1:nBars
    x = (1:nGroups) - GroupWidth/2 + (2*i-1) * GroupWidth / (2*nBars);
    errorbar(x, Means_G1(:,i), SEM_G1(:,i), 'k', 'linestyle', 'none');
end
hold off;

% Other settings
title('Adult Survey Scores: G1 Group', 'FontSize', 16, 'FontWeight','bold');
ylabel('Score (1-10)', 'FontWeight','bold');
ylim([0 10]);
ax = gca;
ax.XTickLabel = {'PostQuiet', 'PostNoise'};
ax.TickDir = 'none';
legend(QuestionsNames, 'Location', 'northeastoutside', 'NumColumns', 1);
set(ax, 'FontName', 'Arial', 'FontSize', 10, 'Box', 'on', 'LineWidth', 1);
% grid on;

% Section 2: G2
figure('Position', [100, 100, 800, 600]);

% Calculate means and SEM
Means_G2 = [mean(T_PostQuiet_G2{:, QuestionsNames}); 
    mean(T_PostNoise_G2{:, QuestionsNames})];
SEM_G2 = [std(T_PostQuiet_G2{:, QuestionsNames})/sqrt(height(T_PostQuiet_G2)); 
    std(T_PostNoise_G2{:, QuestionsNames})/sqrt(height(T_PostNoise_G2))];
Bar_G2 = bar(Means_G2, 'grouped');
hold on;
for k = 1:length(Bar_G2) % Apply colors to bars
    Bar_G2(k).FaceColor = ColorAS(k, :);
end

% Calculate error bar positions
nGroups = size(Means_G2, 1);
nBars = size(Means_G2, 2);
GroupWidth = min(0.8, nBars/(nBars + 1.5));
for i = 1:nBars
    x = (1:nGroups) - GroupWidth/2 + (2*i-1) * GroupWidth / (2*nBars);
    errorbar(x, Means_G2(:,i), SEM_G2(:,i), 'k', 'linestyle', 'none');
end
hold off;

% Other settings
title('Adult Survey Scores: G2 Group', 'FontSize', 16, 'FontWeight','bold');
ylabel('Score (1-10)', 'FontWeight','bold');
ylim([0 10]);
ax = gca;
ax.XTickLabel = {'PostQuiet', 'PostNoise'};
ax.TickDir = 'none';
legend(QuestionsNames, 'Location', 'northeastoutside', 'NumColumns', 1);
set(ax, 'FontName', 'Arial', 'FontSize', 10, 'Box', 'on', 'LineWidth', 1);
% grid on;

%% Stats

% Section 1: Independent t-test for groupwise comparison

Res1 = table('size', [0,4], ...
    'VariableTypes', {'string', 'string', 'double', 'double'}, ...
    'VariableNames', {'Cond', 'Questions', 'T', 'P'});
RawP1 = [];

for Conds = {'PostQuiet', 'PostNoise'}

    Curcond = Conds{1};
    if strcmp(Curcond, 'PostQuiet')
        G1_data = T_PostQuiet_G1;
        G2_data = T_PostQuiet_G2;
    else
        G1_data = T_PostNoise_G1;
        G2_data = T_PostNoise_G2;
    end
    
    for i = 1:length(QuestionsNames)
        Q = QuestionsNames{i};
        [~, p, ~, stats] = ttest2(G1_data.(Q), G2_data.(Q));
        Stat_row1 = {Curcond, Q, stats.tstat, p};
        Res1 = [Res1; Stat_row1];
        RawP1 = [RawP1; p];
    end

end

Res1.AdjP = mafdr(RawP1, 'BHFDR', true); % Apply Benjamini-Hochberg FDR

%% Section 2: Paired t-test for condwise comparison

Res2 = table('size', [0,3], ...
    'VariableTypes', {'string', 'double', 'double'}, ...
    'VariableNames', {'Questions', 'T', 'P'});
RawP2 = [];
    
for i = 1:length(QuestionsNames)
        
        Q = QuestionsNames{i};
        [~, p, ~, stats] = ttest(T_PostQuiet.(Q), T_PostNoise.(Q));
        Stat_row2 = {Q, stats.tstat, p};
        Res2 = [Res2; Stat_row2];
        RawP2 = [RawP2; p];

end

Res2.AdjP = mafdr(RawP2, 'BHFDR', true); % Apply Benjamini-Hochberg FDR
