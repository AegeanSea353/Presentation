%% Plot and Stats of Adult Response Accuracy Data when Conducting Speech Sessions %%

clear; clc;
close all;

%% Data Extraction

% Set datapath
AA_path = 'C:\Data.xlsx';
AA = detectImportOptions(AA_path, 'Sheet', 'SpeechSessions');

T = readtable(AA_path, AA);

Conds = {'QuietAcc', 'SoftNoiseAcc', 'LoudNoiseAcc'};

%% Plot

figure('Position', [100, 100, 1200, 600]); 
ax = gca; hold on;

% Calculate Mean and SEM
AAData = T{:, Conds};
Mean = mean(AAData, 1, 'omitnan');
Std = std(AAData, 0, 1, 'omitnan');
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
title('Response Accuracy Across Conditions', 'FontSize', 16, 'FontWeight','bold');
ylabel('Mean Accuracy', 'FontWeight','bold');
ylim([0.6 1]); % Custom
NewX_labels = replace(Conds, '_Acc', ''); NewX_labels = replace(NewX_labels, '_', ' ');
xticks(X_val);
xticklabels(NewX_labels);
xlim([0.5, length(Conds) + 0.5]);

grid(ax, 'on');
ax.GridLineStyle = '--';
ax.TickDir = 'none';
set(ax, 'FontName', 'Arial', 'FontSize', 10, 'Box', 'on', 'LineWidth', 2);

%% Stats

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
    CompNames = [CompNames; {sprintf('%s vs %s', ...
        NewX_labels{CompPairs(i,1)}, NewX_labels{CompPairs(i,2)})}];
    
end

AdjP = mafdr(RawP, 'BHFDR', true); % Apply Benjamini-Hochberg FDR
Res = table(CompNames, RawP, AdjP, ...
    'VariableNames', {'Comparison', 'RawP', 'AdjP'});
