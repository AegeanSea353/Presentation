%% Demographics %%

clear; clc;
close all;

%% 1 Data Extraction

% Set datapath
DemoGraphics_path = 'C:\Data.xlsx';
DemoGraphics = detectImportOptions(DemoGraphics_path, 'Sheet', 'Demographics');
Excluded_id = {'OHL011', 'OHL020'};

T = readtable(DemoGraphics_path, DemoGraphics);

if ~isempty(Excluded_id)
    Rows2Excluded = ismember(T.DyadID, Excluded_id);
    T(Rows2Excluded, :) = [];
else
    fprintf('No data to be excluded, skip that.')
end

T_ONH = T(startsWith(T.DyadID, 'ONH', 'IgnoreCase', true),:);
T_OHL = T(startsWith(T.DyadID, 'OHL', 'IgnoreCase', true),:);

%% 2 Stats

Stat = table('Size', [0,3], ...
    'VariableTypes', {'string', 'double', 'double'}, ...
    'VariableNames', {'Factor', 'Stat', 'P'});

%% 2.1 Age

AgeA_ONH = T_ONH.Aage; AgeA_OHL = T_OHL.Aage;
AgeC_ONH = T_ONH.Cage; AgeC_OHL = T_OHL.Cage;

[~, p_AgeA, ~, stats_AgeA] = ttest2(AgeA_ONH, AgeA_OHL);
[~, p_AgeC, ~, stats_AgeC] = ttest2(AgeC_ONH, AgeC_OHL);

OutputRow1 = {"Age of Adult", stats_AgeA.tstat, p_AgeA};
OutputRow2 = {"Age of Child", stats_AgeC.tstat, p_AgeC};
Stat = [Stat; OutputRow1; OutputRow2];

%% 2.2 Sex

SexA_ONH = T_ONH.A_sex_0_M_1_F_; SexA_OHL = T_OHL.A_sex_0_M_1_F_;
SexC_ONH = T_ONH.C_sex_0_M_1_F_; SexC_OHL = T_OHL.C_sex_0_M_1_F_;

All_SexA = [SexA_ONH; SexA_OHL];
GrpLabels_A = [repmat({'A_ONH'}, height(T_ONH),1); repmat({'A_OHL'}, height(T_OHL),1)];
All_SexC = [SexC_ONH; SexC_OHL];
GrpLabels_C = [repmat({'C_ONH'}, height(T_ONH),1); repmat({'C_OHL'}, height(T_OHL),1)];

[~, chi2_SexA, p_SexA] = crosstab(GrpLabels_A, All_SexA);
[~, chi2_SexC, p_SexC] = crosstab(GrpLabels_C, All_SexC);

clear OutputRow1; OutputRow1 = {"Sex of Adult", chi2_SexA, p_SexA};
clear OutputRow2; OutputRow2 = {"Sex of Child", chi2_SexC, p_SexC};
Stat = [Stat; OutputRow1; OutputRow2];
