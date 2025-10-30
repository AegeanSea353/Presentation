%% Plot and Stats of Adult Response Accuracy Data when Conducting Speech Sessions %%

clear; clc;
close all;

%% 1 Data Extraction

% Set datapath
AA_path = 'C:\Data.xlsx';
AA = detectImportOptions(AA_path, 'Sheet', 'AdultSpeechSessions');

T = readtable(AA_path, AA);

Conds = {'QuietQAcc', 'SoftNoiseQAcc', 'LoudNoiseQAcc'};
XLabels = replace(Conds, '_Acc', ''); XLabels = replace(XLabels, '_', ' ');

%% 2 Stats

% Conduct Repeated Measures ANOVA
RM_formula = sprintf('%s-%s ~ 1', Conds{1}, Conds{end});
WithinDesign = table(categorical((1:length(Conds))'), 'VariableNames', {'Condition'});
RM = fitrm(T, RM_formula, 'WithinDesign', WithinDesign);
Res_RManova = ranova(RM);

% Post-hoc tests
CompPairs = nchoosek(1:length(Conds), 2);
RawP = [];
CompNames = {};

for i = 1:size(CompPairs, 1)
    
    Col1Name = Conds{CompPairs(i, 1)};
    Col2Name = Conds{CompPairs(i, 2)};
    
    [~, p] = ttest(T.(Col1Name), T.(Col2Name));
    RawP = [RawP; p];
    CompNames = [CompNames; {sprintf('%s vs %s', XLabels{CompPairs(i,1)}, XLabels{CompPairs(i,2)})}];
    
end

% Apply Benjamini-Hochberg FDR
AdjP = mafdr(RawP, 'BHFDR', true);

Res = table(CompNames, RawP, AdjP, ...
    'VariableNames', {'Comparison', 'RawP', 'AdjP'});

%% 3 Plot (Errorbared)

figure('Position', [100, 100, 1200, 600]); 
ax = gca; hold on; 

% Calculate Mean and SEM
AAData = T{:, Conds};
Mean = mean(AAData, 1, 'omitnan') *100;
Std = std(AAData, 0, 1, 'omitnan')*100;
n = sum(~isnan(AAData), 1);
SEM = Std ./ sqrt(n);

% Line Plot with Error Bars
X_val = 1:length(Conds);
errorbar(ax, X_val, Mean, SEM, ...
    'o-', ...                          
    'Color', [0, 0.4470, 0.7410], ...  
    'LineWidth', 2, ...               
    'MarkerSize', 10, ...             
    'MarkerFaceColor', 'w', ...   
    'CapSize', 15);               

% Other settings
title('Response Accuracy Across Conditions');
ylabel('Accuracy (% Correct)');
ylim([60 105]); % Custom
X_TickLabels = {'Quiet', 'Soft Noise', 'Loud Noise'};
xticks(X_val);
xticklabels(X_TickLabels);
xlim([0.5, length(Conds)+0.5]);

grid off;
ax.YTick = [70 80 90 100];
set(ax, 'FontName', 'Arial', 'FontSize', 20, 'Box', 'off', 'LineWidth', 2, 'FontWeight','bold');

%% 3 Plot (Scattered)

figure('Position', [100, 100, 1000, 700]); 
ax1 = gca; hold on; 

Colors = [[255 200 0]/255;
          [77 139 49]/255;
          [30 33 43]/255];

X_Centers = 1:length(Conds);
JitterWidth = 0.2;
MeanAcc = nan(1, length(Conds)); % Intialization

% Scatter
for i = 1:length(Conds)
    
    CurCond = Conds{i};
    AccData = T.(CurCond);

    X_Scatter = X_Centers(i) + (rand(size(AccData)) - 0.8) * JitterWidth;
    scatter(ax1, X_Scatter, AccData*100, 100, Colors(i,:), 'filled', 'MarkerFaceAlpha', 1);

    MeanAcc(i) = mean(AccData)*100; 

end

% Other settings
hold off;
title('Response Accuracy Across Conditions');
ylabel('Accuracy (% Correct)');
ylim([28 104]);
X_TickLabels = {'Quiet', 'Soft Noise', 'Loud Noise'};
xticks(X_Centers);
xticklabels(X_TickLabels);
xlim([0.5, length(Conds)+0.5]);
ax1.YTick = [33.3, 50, 66.7, 100]; % Custom
grid off;
legend(ax1, X_TickLabels, 'Location', 'best', 'Box', 'off');
set(ax1, 'FontName', 'Arial', 'FontSize', 20, 'Box', 'off', 'LineWidth', 2, 'FontWeight','bold');
