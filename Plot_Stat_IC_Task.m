%% Plots and Stats of Inhibitory Control Task Developed by Zhou, 2022

clear; clc; 
close all;
addpath('Utils\');

Filename = 'C:\IC_Behavior.xlsx';
[~, SheetNames] = xlsfinfo(Filename);

Conds = {'PostQuiet', 'PostNoise'};

%% 1 Data Extraction

% Initialization
Res = table('Size', [length(SheetNames), 15], ...
    'VariableTypes', {'string', 'double', 'double', 'double', 'double', 'double', ...
                            'double', 'double', 'double', 'double', 'double', 'double', 'double', 'double', 'double'}, ...
    'VariableNames', {'DyadID', ...
                            'GoAcc_PostQuiet', 'GoRT_PostQuiet', 'NogoAcc_PostQuiet', 'NogoRT_PostQuiet', ...
                            'Cong4Cong5RT_PostQuiet', 'InCg4Cong5RT_PostQuiet', 'InCg4Cong5_Cong4Cong5RT_PostQuiet', ...
                            'GoAcc_PostNoise', 'GoRT_PostNoise', 'NogoAcc_PostNoise', 'NogoRT_PostNoise', ...
                            'Cong4Cong5RT_PostNoise', 'InCg4Cong5RT_PostNoise', 'InCg4Cong5_Cong4Cong5RT_PostNoise'});

% Loop
for i = 1:length(SheetNames)
    
    DyadID = SheetNames{i};
    SubjData = readtable(Filename, 'Sheet', DyadID);
    Res.DyadID(i) = string(DyadID);

    for c = 1:length(Conds)

        Curcond = Conds{c};
        SubjCData = SubjData(startsWith(SubjData.Session, Curcond), :);
    
        Is_go = strcmp(SubjCData.Conds, 'Cong'); N_go = sum(Is_go);
        Is_nogo = strcmp(SubjCData.Conds, 'InCg'); N_nogo = sum(Is_nogo);
        
        % For Cong (Go) Condition
    
        % Acc; For VERSION 1 when extracting IC data (IC_Task_GroupCleanData.m)
        % N_GoHits = sum(Is_go & strcmp(SubjCData.StimType, 'hit')); % Accuracy
        % GoAcc= N_GoHits / N_go *100;

        % Acc; For VERSION 2 when extracting IC data (IC_Task_GroupCleanData.m)
        Is_GoHits = Is_go & contains(SubjCData.StimType, 'hit'); 
        N_GoHits = sum(Is_GoHits); 
        GoAcc = N_GoHits / N_go *100;

        GoRT = SubjCData.RT(Is_go & strcmp(SubjCData.StimType, 'hit')); % RT
        Mean_GoRT = nanmean(GoRT);
        Std_GoRT = nanstd(GoRT);
        Cleaned_GoRT = GoRT(GoRT >= (Mean_GoRT - 2.5*Std_GoRT) & GoRT <= (Mean_GoRT +2.5*Std_GoRT));
    
        Mean_Cleaned_GoRT = nanmean(Cleaned_GoRT) / 10000; % Mean RT and SEM
        SEM_Cleaned_GoRT= nanstd(Cleaned_GoRT) / sqrt(sum(~isnan(Cleaned_GoRT))) / 10000;

        % For InCg (Nogo) Condition

        % Acc; For VERSION 1 when extracting IC data (IC_Task_GroupCleanData.m)
        % N_Nogo_HitAndMiss = sum(Is_nogo & (strcmp(SubjCData.StimType, 'hit') | strcmp(SubjCData.StimType, 'miss'))); % Accuracy % Debug
        % NogoAcc= N_Nogo_HitAndMiss / N_nogo*100;

        % Acc; For VERSION 2 when extracting IC data (IC_Task_GroupCleanData.m)
        Is_Nogo_Hits = Is_nogo & contains(SubjCData.StimType, 'hit');
        Is_Nogo_CorrMiss = Is_nogo & (startsWith(SubjCData.Code, 'InCong') & contains(SubjCData.StimType, 'miss'));
        N_Nogo_HitCorrMiss = sum(Is_Nogo_Hits + Is_Nogo_CorrMiss);
        NogoAcc = N_Nogo_HitCorrMiss / N_nogo *100;

        NogoRT = SubjCData.RT(Is_nogo & (strcmp(SubjCData.StimType, 'hit') | strcmp(SubjCData.StimType, 'incorrect'))); % RT
        Mean_NogoRT = nanmean(NogoRT);
        Std_NogoRT = nanstd(NogoRT);
        Cleaned_NogoRT = NogoRT(NogoRT >= (Mean_NogoRT - 2.5*Std_NogoRT) & NogoRT <= (Mean_NogoRT +2.5*Std_NogoRT));

        Mean_Cleaned_NogoRT = nanmean(Cleaned_NogoRT) / 10000; % Mean RT and SEM
        SEM_Cleaned_NogoRT= nanstd(Cleaned_NogoRT) / sqrt(sum(~isnan(Cleaned_NogoRT))) / 10000;
        
        % For normalized mean RT
        
        Cong4Cong5RT = SubjCData.RT(Is_go & SubjCData.Events == 5 & strcmp(SubjCData.StimType, 'hit')); % For Go
        Mean_Cong4Cong5RT = nanmean(Cong4Cong5RT) / 10000;

        InCg4Cong5RT = SubjCData.RT(Is_nogo & SubjCData.Events == 5 & strcmp(SubjCData.StimType, 'hit')); % For Nogo
        Mean_InCg4Cong5RT = nanmean(InCg4Cong5RT) / 10000;
        
        GrandMeanRT = mean([Cleaned_GoRT; Cleaned_NogoRT]) / 10000;
        Mean_InCg4Cong5_Cong4Cong5RT = (Mean_InCg4Cong5RT - Mean_Cong4Cong5RT) / GrandMeanRT; % Normalized
        
        Res.(['GoAcc_' Curcond])(i) = GoAcc; % Store
        Res.(['GoRT_' Curcond])(i) = Mean_Cleaned_GoRT;
        Res.(['NogoAcc_' Curcond])(i) = NogoAcc;
        Res.(['NogoRT_' Curcond])(i) = Mean_Cleaned_NogoRT;
        Res.(['Cong4Cong5RT_' Curcond])(i) = Mean_Cong4Cong5RT;
        Res.(['InCg4Cong5RT_' Curcond])(i) = Mean_InCg4Cong5RT;
        Res.(['InCg4Cong5_Cong4Cong5RT_' Curcond])(i) = Mean_InCg4Cong5_Cong4Cong5RT;

    end

end

%% 2 Stats

Res_ONH = Res(startsWith(Res.DyadID, 'ONH', 'IgnoreCase', true),:);
Res_OHL = Res(startsWith(Res.DyadID, 'OHL', 'IgnoreCase', true),:);

Groups = {Res, Res_ONH, Res_OHL}; GroupNames = {'Overall', 'ONH', 'OHL'};

%% 2.1 Acc

GoNogo_Acc_Metrics = {'GoAcc', 'NogoAcc'}; GoNogoLabels = {'Acc'};
QuietNoise_Acc_Metrics = {'GoAcc', 'NogoAcc'};

Stat_Acc = table('Size', [0,4], ...
    'VariableTypes', {'string', 'string', 'double', 'double'}, ...
    'VariableNames', {'Group', 'Comparison', 'T', 'P'}); % Initalization

% For Cong (Go) vs. InCg (NoGo)
for g = 1:length(Groups)
    
    CurData = Groups{g};
    CurGrpName = GroupNames{g};
    
    for CondCell = {'PostQuiet', 'PostNoise'}
        
        CondSuf = CondCell{1};
        
        for m = 1:size(GoNogo_Acc_Metrics, 1)
            
            Var1Name = sprintf('%s_%s', GoNogo_Acc_Metrics{m, 1}, CondSuf);
            Var2Name = sprintf('%s_%s', GoNogo_Acc_Metrics{m, 2}, CondSuf);
            
            Data1 = CurData.(Var1Name);
            Data2 = CurData.(Var2Name);
            
            [~, p, ~, stats] = ttest(Data1, Data2);
           
            CmpName = sprintf('Go vs NoGo (%s, %s)', GoNogoLabels{m}, CondSuf);
            
            OutputRow = {CurGrpName, CmpName, stats.tstat, p};
            Stat_Acc = [Stat_Acc; OutputRow];

        end

    end

end

% For PostQuiet vs. PostNoise
for g = 1:length(Groups)
    
    CurData = Groups{g};
    CurGrpName = GroupNames{g};
    
    for m = 1:length(QuietNoise_Acc_Metrics)
        
        CurMetric = QuietNoise_Acc_Metrics{m};
        
        Var1Name = sprintf('%s_PostQuiet', CurMetric);
        Var2Name = sprintf('%s_PostNoise', CurMetric);
        
        Data1 = CurData.(Var1Name);
        Data2 = CurData.(Var2Name);
        
        [~, p, ~, stats] = ttest(Data1, Data2);
        
        CmpName = sprintf('Quiet vs Noise (%s)', CurMetric);
        
        OutputRow = {CurGrpName, CmpName, stats.tstat, p};
        Stat_Acc = [Stat_Acc; OutputRow];

    end

end

Stat_Acc.AdjP = mafdr(Stat_Acc.P, 'BHFDR', true); % Apply Benjamini-Hochberg FDR

%% 2.2 Grand Mean RT

GoNogo_RT_Metrics = {'GoRT', 'NogoRT'};
QuietNoise_RT_Metrics = {'GoRT', 'NogoRT'};

Stat_RT = table('Size', [0,4], ...
    'VariableTypes', {'string', 'string', 'double', 'double'}, ...
    'VariableNames', {'Group', 'Comparison', 'T', 'P'}); % Initialization

% For Cong (Go) vs. InCg (NoGo)
for g = 1:length(Groups)
    
    CurData = Groups{g};
    CurGrpName = GroupNames{g};
    
    for CondCell = {'PostQuiet', 'PostNoise'}
        
        CondSuf = CondCell{1};
        
        Var1Name = sprintf('%s_%s', GoNogo_RT_Metrics{1}, CondSuf);
        Var2Name = sprintf('%s_%s', GoNogo_RT_Metrics{2}, CondSuf);
            
        Data1 = CurData.(Var1Name);
        Data2 = CurData.(Var2Name);
        
        [~, p, ~, stats] = ttest(Data1, Data2);
            
        CmpName = sprintf('Go vs NoGo (RT, %s)', CondSuf);
            
        OutputRow = {CurGrpName, CmpName, stats.tstat, p};
        Stat_RT = [Stat_RT; OutputRow];

    end

end

% For PostQuiet vs. PostNoise
for g = 1:length(Groups)

    CurData = Groups{g};
    CurGrpName = GroupNames{g};
    
    for m = 1:length(QuietNoise_RT_Metrics)
        
        CurMetric = QuietNoise_RT_Metrics{m};
        
        Var1Name = sprintf('%s_PostQuiet', CurMetric);
        Var2Name = sprintf('%s_PostNoise', CurMetric);
            
        Data1 = CurData.(Var1Name);
        Data2 = CurData.(Var2Name);
            
        [~, p, ~, stats] = ttest(Data1, Data2);
            
        CmpName = sprintf('Quiet vs Noise (%s)', CurMetric);
            
        OutputRow = {CurGrpName, CmpName, stats.tstat, p};
        Stat_RT = [Stat_RT; OutputRow];

    end

end

Stat_RT.AdjP = mafdr(Stat_RT.P, 'BHFDR', true); % Apply Benjamini-Hochberg FDR

%% 2.3 Normalized Mean RT

Cong4InCg5_nRT_Metrics = {'Cong4Cong5RT', 'InCg4Cong5RT'};
QuietNoise_nRT_Metrics = {'Cong4Cong5RT', 'InCg4Cong5RT', 'InCg4Cong5_Cong4Cong5RT'};

Stat_nRT = table('Size', [0,4], ...
    'VariableTypes', {'string', 'string', 'double', 'double'}, ...
    'VariableNames', {'Group', 'Comparison', 'T', 'P'}); % Initialization

% For Cong4Cong5 vs. InCg4Cong5
for g = 1:length(Groups)
    
    CurData = Groups{g};
    CurGrpName = GroupNames{g};
    
    for CondCell = {'PostQuiet', 'PostNoise'}
        
        CondSuf = CondCell{1};
        
        Var1Name = sprintf('%s_%s', Cong4InCg5_nRT_Metrics{1}, CondSuf);
        Var2Name = sprintf('%s_%s', Cong4InCg5_nRT_Metrics{2}, CondSuf);
            
        Data1 = CurData.(Var1Name);
        Data2 = CurData.(Var2Name);
            
        [~, p, ~, stats] = ttest(Data1, Data2);
            
        CmpName = sprintf('Cong4Cong5 vs InCg4Cong5 (nRT, %s)', CondSuf);
            
        OutputRow = {CurGrpName, CmpName, stats.tstat, p};
        Stat_nRT = [Stat_nRT; OutputRow];

    end

end

% For PostQuiet vs. PostNoise
for g = 1:length(Groups)
    
    CurData = Groups{g};
    CurGrpName = GroupNames{g};
    
    for m = 1:length(QuietNoise_nRT_Metrics)
        
        CurMetric = QuietNoise_nRT_Metrics{m};
        
        Var1Name = sprintf('%s_PostQuiet', CurMetric);
        Var2Name = sprintf('%s_PostNoise', CurMetric);
            
        Data1 = CurData.(Var1Name);
        Data2 = CurData.(Var2Name);
            
        [~, p, ~, stats] = ttest(Data1, Data2);
            
        CmpName = sprintf('Quiet vs Noise (%s)', CurMetric);
            
        OutputRow = {CurGrpName, CmpName, stats.tstat, p};
        Stat_nRT = [Stat_nRT; OutputRow];

    end

end

Stat_nRT.AdjP = mafdr(Stat_nRT.P, 'BHFDR', true); % Apply Benjamini-Hochberg FDR

%% 2.4 Independent t-tests for Group Comparison (ONH vs OHL)

GrpCmp_Metrics = {'GoAcc', 'NogoAcc', 'GoRT', 'NogoRT', ...
                      'Cong4Cong5RT', 'InCg4Cong5RT', 'InCg4Cong5_Cong4Cong5RT'};

Stat_Group = table('Size', [0, 4], ...
    'VariableTypes', {'string', 'string', 'double', 'double'}, ...
    'VariableNames', {'Condition', 'Metric', 'T', 'P'});

for c = {'PostQuiet', 'PostNoise'}
    
    CurCond = c{1};
    
    for m = 1:length(GrpCmp_Metrics)
        
        CurMetric = GrpCmp_Metrics{m};
        
        VarName = sprintf('%s_%s', CurMetric, CurCond);
        
        Data_ONH = Res_ONH.(VarName);
        Data_OHL = Res_OHL.(VarName);
        
        [~, p, ~, stats] = ttest2(Data_ONH, Data_OHL);
        
        clear OutputRow; OutputRow = {CurCond, CurMetric, stats.tstat, p};
        Stat_Group = [Stat_Group; OutputRow];

    end

end

Stat_Group.AdjP_BH = mafdr(Stat_Group.P, 'BHFDR', true); % Apply Benjamini-Hochberg FDR

%% 3 Plot

N_ONH = height(Res_ONH); N_OHL = height(Res_OHL);

%% 3.1 Acc

figure('Color', 'white', 'Position', [100, 100, 1400, 600]);

% ONH
ax_ONH_Acc = subplot(1, 2, 1);
p_GoNogo_Quiet_ONH_Acc = Stat_Acc.P(strcmp(Stat_Acc.Group, 'ONH') & strcmp(Stat_Acc.Comparison, 'Go vs NoGo (Acc, PostQuiet)'));
p_GoNogo_Noise_ONH_Acc = Stat_Acc.P(strcmp(Stat_Acc.Group, 'ONH') & strcmp(Stat_Acc.Comparison, 'Go vs NoGo (Acc, PostNoise)'));
p_QuietNoise_Go_ONH = Stat_Acc.P(strcmp(Stat_Acc.Group, 'ONH') & strcmp(Stat_Acc.Comparison, 'Quiet vs Noise (GoAcc)'));
p_QuietNoise_Nogo_ONH_Acc = Stat_Acc.P(strcmp(Stat_Acc.Group, 'ONH') & strcmp(Stat_Acc.Comparison, 'Quiet vs Noise (NogoAcc)'));

Plt_IC_GroupData(ax_ONH_Acc, Res_ONH, 'ONH', N_ONH, ...
                   'Accuracy: ONH Group', 'Accuracy (% Correct)', {'PostQuiet', 'PostNoise'}, [70,105], 70:10:100, ...
                   'GoAcc', 'NogoAcc', {'Go', 'NoGo'}, ...
                   p_GoNogo_Quiet_ONH_Acc, p_GoNogo_Noise_ONH_Acc, p_QuietNoise_Go_ONH, p_QuietNoise_Nogo_ONH_Acc);

% OHL
ax_OHL_Acc = subplot(1, 2, 2);
p_GoNogo_Quiet_OHL_Acc = Stat_Acc.P(strcmp(Stat_Acc.Group, 'OHL') & strcmp(Stat_Acc.Comparison, 'Go vs NoGo (Acc, PostQuiet)'));
p_GoNogo_Noise_OHL_Acc = Stat_Acc.P(strcmp(Stat_Acc.Group, 'OHL') & strcmp(Stat_Acc.Comparison, 'Go vs NoGo (Acc, PostNoise)'));
p_QuietNoise_Go_OHL_Acc = Stat_Acc.P(strcmp(Stat_Acc.Group, 'OHL') & strcmp(Stat_Acc.Comparison, 'Quiet vs Noise (GoAcc)'));
p_QuietNoise_Nogo_OHL_Acc = Stat_Acc.P(strcmp(Stat_Acc.Group, 'OHL') & strcmp(Stat_Acc.Comparison, 'Quiet vs Noise (NogoAcc)'));

Plt_IC_GroupData(ax_OHL_Acc, Res_OHL, 'OHL', N_OHL, ...
                   'Accuracy: OHL Group', 'Accuracy (% Correct)', {'PostQuiet', 'PostNoise'}, [70,105], 70:10:100, ...
                   'GoAcc', 'NogoAcc', {'Go', 'NoGo'}, ...
                   p_GoNogo_Quiet_OHL_Acc, p_GoNogo_Noise_OHL_Acc, p_QuietNoise_Go_OHL_Acc, p_QuietNoise_Nogo_OHL_Acc);

%% 3.2 Grand Mean RT

figure('Color', 'white', 'Position', [150, 150, 1400, 600]);

% ONH
ax_ONH_RT = subplot(1, 2, 1);
p_GoNogo_Quiet_ONH_RT = Stat_RT.P(strcmp(Stat_RT.Group, 'ONH') & strcmp(Stat_RT.Comparison, 'Go vs NoGo (RT, PostQuiet)'));
p_GoNogo_Noise_ONH_RT = Stat_RT.P(strcmp(Stat_RT.Group, 'ONH') & strcmp(Stat_RT.Comparison, 'Go vs NoGo (RT, PostNoise)'));
p_QuietNoise_Go_ONH_RT = Stat_RT.P(strcmp(Stat_RT.Group, 'ONH') & strcmp(Stat_RT.Comparison, 'Quiet vs Noise (GoRT)'));
p_QuietNoise_Nogo_ONH_RT = Stat_RT.P(strcmp(Stat_RT.Group, 'ONH') & strcmp(Stat_RT.Comparison, 'Quiet vs Noise (NogoRT)'));

Plt_IC_GroupData(ax_ONH_RT, Res_ONH, 'ONH', N_ONH, ...
                   'Grand Mean RT: ONH Group', 'Response Time (s)', {'PostQuiet', 'PostNoise'}, [0.3,1.3], 0.4:0.2:1.2, ...
                   'GoRT', 'NogoRT', {'Go', 'NoGo'}, ...
                   p_GoNogo_Quiet_ONH_RT, p_GoNogo_Noise_ONH_RT, p_QuietNoise_Go_ONH_RT, p_QuietNoise_Nogo_ONH_RT);

% OHL
ax_OHL_RT = subplot(1, 2, 2);
p_GoNogo_Quiet_OHL_RT = Stat_RT.P(strcmp(Stat_RT.Group, 'OHL') & strcmp(Stat_RT.Comparison, 'Go vs NoGo (RT, PostQuiet)'));
p_GoNogo_Noise_OHL_RT = Stat_RT.P(strcmp(Stat_RT.Group, 'OHL') & strcmp(Stat_RT.Comparison, 'Go vs NoGo (RT, PostNoise)'));
p_QuietNoise_Go_OHL_RT = Stat_RT.P(strcmp(Stat_RT.Group, 'OHL') & strcmp(Stat_RT.Comparison, 'Quiet vs Noise (GoRT)'));
p_QuietNoise_Nogo_OHL_RT = Stat_RT.P(strcmp(Stat_RT.Group, 'OHL') & strcmp(Stat_RT.Comparison, 'Quiet vs Noise (NogoRT)'));

Plt_IC_GroupData(ax_OHL_RT, Res_OHL, 'OHL', N_OHL, ...
                   'Grand Mean RT: OHL Group', 'Response Time (s)', {'PostQuiet', 'PostNoise'}, [0.3,1.3], 0.4:0.2:1.2, ...
                   'GoRT', 'NogoRT', {'Go', 'NoGo'}, ...
                   p_GoNogo_Quiet_OHL_RT, p_GoNogo_Noise_OHL_RT, p_QuietNoise_Go_OHL_RT, p_QuietNoise_Nogo_OHL_RT);

%% 3.3 Normalized Mean RT

figure('Color', 'white', 'Position', [200, 200, 1400, 600]);

% ONH
ax_ONH_nRT = subplot(1, 2, 1);
p_GoNogo_Quiet_ONH_nRT = Stat_nRT.P(strcmp(Stat_nRT.Group, 'ONH') & strcmp(Stat_nRT.Comparison, 'Cong4Cong5 vs InCg4Cong5 (nRT, PostQuiet)'));
p_GoNogo_Noise_ONH_nRT = Stat_nRT.P(strcmp(Stat_nRT.Group, 'ONH') & strcmp(Stat_nRT.Comparison, 'Cong4Cong5 vs InCg4Cong5 (nRT, PostNoise)'));
p_QuietNoise_Cong4Cong5_ONH_nRT = Stat_nRT.P(strcmp(Stat_nRT.Group, 'ONH') & strcmp(Stat_nRT.Comparison, 'Quiet vs Noise (Cong4Cong5RT)'));
p_QuietNoise_InCg4Cong5_ONH_nRT = Stat_nRT.P(strcmp(Stat_nRT.Group, 'ONH') & strcmp(Stat_nRT.Comparison, 'Quiet vs Noise (InCg4Cong5RT)'));

Plt_IC_GroupData(ax_ONH_nRT, Res_ONH, 'ONH', N_ONH, ...
                   'Normalized Mean RT: ONH Group', 'Normalized Response Time (s)', {'PostQuiet', 'PostNoise'}, [0.3,1.3], 0.4:0.2:1.2, ...
                   'Cong4Cong5RT', 'InCg4Cong5RT', {'Cong4Cong5', 'InCg4Cong5'}, ...
                   p_GoNogo_Quiet_ONH_nRT, p_GoNogo_Noise_ONH_nRT, p_QuietNoise_Cong4Cong5_ONH_nRT, p_QuietNoise_InCg4Cong5_ONH_nRT);

% OHL
ax_OHL_nRT = subplot(1, 2, 2);
p_GoNogo_Quiet_OHL_nRT = Stat_nRT.P(strcmp(Stat_nRT.Group, 'OHL') & strcmp(Stat_nRT.Comparison, 'Cong4Cong5 vs InCg4Cong5 (nRT, PostQuiet)'));
p_GoNogo_Noise_OHL_nRT = Stat_nRT.P(strcmp(Stat_nRT.Group, 'OHL') & strcmp(Stat_nRT.Comparison, 'Cong4Cong5 vs InCg4Cong5 (nRT, PostNoise)'));
p_QuietNoise_Cong4Cong5_OHL_nRT = Stat_nRT.P(strcmp(Stat_nRT.Group, 'OHL') & strcmp(Stat_nRT.Comparison, 'Quiet vs Noise (Cong4Cong5RT)'));
p_QuietNoise_InCg4Cong5_OHL_nRT = Stat_nRT.P(strcmp(Stat_nRT.Group, 'OHL') & strcmp(Stat_nRT.Comparison, 'Quiet vs Noise (InCg4Cong5RT)'));

Plt_IC_GroupData(ax_OHL_nRT, Res_OHL, 'OHL', N_OHL, ...
                   'Normalized Mean RT: OHL Group', 'Normalized Response Time (s)', {'PostQuiet', 'PostNoise'}, [0.3,1.3], 0.4:0.2:1.2, ...
                   'Cong4Cong5RT', 'InCg4Cong5RT', {'Cong4Cong5', 'InCg4Cong5'}, ...
                   p_GoNogo_Quiet_OHL_nRT, p_GoNogo_Noise_OHL_nRT, p_QuietNoise_Cong4Cong5_OHL_nRT, p_QuietNoise_InCg4Cong5_OHL_nRT);
