function Plt_IC_GroupData(ax, GroupData, GroupName, N_Subj_Group, ...
                            PlotTitle, Y_Label, X_TickLabels, Y_Limits, T_Ticks, ...
                            Var1_prefix, Var2_prefix, LegLabels, ...
                            p_GoNogo_Quiet, p_GoNogo_Noise, p_QuietNoise_1, p_QuietNoise_2)

    % Helper function to specifically plot IC task data 
    % for a single group (ONH or OHL).

    hold(ax, 'on');
    
    % General settings
    % Color1 = [0, 0.4470, 0.7410];
    % Color2 = [0.8500, 0.3250, 0.0980];
    Color1 = [255 180 217] / 255;
    Color2 = [237 137 158] / 255;

    CondOffset = 0.2;
    VarOffset = 0.05; 
    ScatterOffset = 0.06;
    JitterWidth = 0.05;
    MarkerSize = 85;
    MarkerFaceAlpha = 1;
    X_PostQuiet = 1;
    X_PostNoise = 2;

    % Extract data
    Data_Q1 = GroupData.([Var1_prefix '_PostQuiet']);
    Data_Q2 = GroupData.([Var2_prefix '_PostQuiet']);
    Data_N1 = GroupData.([Var1_prefix '_PostNoise']);
    Data_N2 = GroupData.([Var2_prefix '_PostNoise']);
    
    % Caculating mean and SEM
    Mean_Q1 = nanmean(Data_Q1); SEM_Q1 = nanstd(Data_Q1) / sqrt(N_Subj_Group);
    Mean_Q2 = nanmean(Data_Q2); SEM_Q2 = nanstd(Data_Q2) / sqrt(N_Subj_Group);
    Mean_N1 = nanmean(Data_N1); SEM_N1 = nanstd(Data_N1) / sqrt(N_Subj_Group);
    Mean_N2 = nanmean(Data_N2); SEM_N2 = nanstd(Data_N2) / sqrt(N_Subj_Group);

    % Scatter
    JitterQ = (rand(N_Subj_Group, 1) - 0.5) * JitterWidth;
    JitterN = (rand(N_Subj_Group, 1) - 0.5) * JitterWidth;
    
    X_Q1_Scatter = X_PostQuiet - CondOffset - VarOffset - ScatterOffset + JitterQ;
    X_Q2_Scatter = X_PostQuiet + CondOffset + VarOffset + ScatterOffset + JitterQ;
    X_N1_Scatter = X_PostNoise - CondOffset - VarOffset - ScatterOffset + JitterN;
    X_N2_Scatter = X_PostNoise + CondOffset + VarOffset + ScatterOffset + JitterN;
    
    h_scatter(1) = scatter(ax, X_Q1_Scatter, Data_Q1, MarkerSize, 'MarkerFaceColor', Color1, 'MarkerEdgeColor', 'none', 'MarkerFaceAlpha', MarkerFaceAlpha);
    h_scatter(2) = scatter(ax, X_Q2_Scatter, Data_Q2, MarkerSize, 'MarkerFaceColor', Color2, 'MarkerEdgeColor', 'none', 'MarkerFaceAlpha', MarkerFaceAlpha);
    scatter(ax, X_N1_Scatter, Data_N1, MarkerSize, 'MarkerFaceColor', Color1, 'MarkerEdgeColor', 'none', 'MarkerFaceAlpha', MarkerFaceAlpha);
    scatter(ax, X_N2_Scatter, Data_N2, MarkerSize, 'MarkerFaceColor', Color2, 'MarkerEdgeColor', 'none', 'MarkerFaceAlpha', MarkerFaceAlpha);

    % Errorbar
    X_Q1_Err = X_PostQuiet - CondOffset - VarOffset + ScatterOffset;
    X_Q2_Err = X_PostQuiet + CondOffset + VarOffset - ScatterOffset;
    X_N1_Err = X_PostNoise - CondOffset - VarOffset + ScatterOffset;
    X_N2_Err = X_PostNoise + CondOffset + VarOffset - ScatterOffset; 

    errorbar(ax, X_Q1_Err, Mean_Q1, SEM_Q1, 'o', 'Color', Color1, 'LineWidth', 2, 'MarkerSize', 10, 'MarkerFaceColor', Color1, 'CapSize', 8);
    errorbar(ax, X_Q2_Err, Mean_Q2, SEM_Q2, 'o', 'Color', Color2, 'LineWidth', 2, 'MarkerSize', 10, 'MarkerFaceColor', Color2, 'CapSize', 8);
    errorbar(ax, X_N1_Err, Mean_N1, SEM_N1, 'o', 'Color', Color1, 'LineWidth', 2, 'MarkerSize', 10, 'MarkerFaceColor', Color1, 'CapSize', 8);
    errorbar(ax, X_N2_Err, Mean_N2, SEM_N2, 'o', 'Color', Color2, 'LineWidth', 2, 'MarkerSize', 10, 'MarkerFaceColor', Color2, 'CapSize', 8);

    % Conn mean lines
    plot(ax, [X_Q1_Err, X_Q2_Err], [Mean_Q1, Mean_Q2], '-.', 'Color', [0.6 0.6 0.6], 'LineWidth', 1.5, 'HandleVisibility', 'off');
    plot(ax, [X_N1_Err, X_N2_Err], [Mean_N1, Mean_N2], '-.', 'Color', [0.6 0.6 0.6], 'LineWidth', 1.5, 'HandleVisibility', 'off');
    % plot(ax, [X_Q1_Err, X_N1_Err], [Mean_Q1, Mean_N1], '--', 'Color', Color1*0.8, 'LineWidth', 1, 'HandleVisibility', 'off'); % Quiet vs Noise
    % plot(ax, [X_Q2_Err, X_N2_Err], [Mean_Q2, Mean_N2], '--', 'Color', Color2*0.8, 'LineWidth', 1, 'HandleVisibility', 'off'); % Quiet vs Noise

    % Other settings
    ylabel(Y_Label, 'FontSize', 20, 'FontWeight', 'bold');
    ax.XTick = [X_PostQuiet, X_PostNoise];
    ax.XTickLabel = X_TickLabels;
    ax.XLim = [0.5, 2.5];
    ax.YLim = Y_Limits;
    ax.YTick = T_Ticks;
    
    % Legend
    legend(h_scatter, LegLabels, 'Location', 'southeast', 'FontSize', 16, 'Box', 'off');

    % Significance asterisks
    Y_range = diff(Y_Limits);
    Y_level1 = Y_Limits(2) - Y_range * 0.15; % Height 1
    Y_level2 = Y_Limits(2) - Y_range * 0.05; % Height 2

    plot_sig_line(X_Q1_Err, X_Q2_Err, Y_level1, p_GoNogo_Quiet); % Go vs. NoGo / Cong vs. InCg
    plot_sig_line(X_N1_Err, X_N2_Err, Y_level1, p_GoNogo_Noise);
    plot_sig_line(X_Q1_Err, X_N1_Err, Y_level2, p_QuietNoise_1); % Quiet vs. Noise
    plot_sig_line(X_Q2_Err, X_N2_Err, Y_level2, p_QuietNoise_2);
    
    hold(ax, 'off');
    title(PlotTitle, 'FontSize', 20, 'FontWeight', 'bold');
    set(ax, 'FontSize', 18, 'FontWeight', 'bold', 'LineWidth', 2, 'Box', 'off', 'Color', 'none', 'FontName', 'Arial');
    
end

% Function for plotting asterisks
function plot_sig_line(x1, x2, y, Pval)

    if Pval < 0.05

        ax = gca;
        y_range = diff(ax.YLim);
        h_hook = y_range * 0.02;
        line_x = [x1, x1, x2, x2];
        line_y = [y - h_hook, y, y, y - h_hook];
        plot(line_x, line_y, '-k', 'LineWidth', 2, 'HandleVisibility', 'off');
        text_offset = y_range * 0.01;

        if Pval < 0.001
            Sigtext = '***';
        elseif Pval < 0.01
            Sigtext = '**';
        else
            Sigtext = '*';
        end

        text(mean([x1, x2]), y + text_offset, Sigtext, 'FontSize', 25, ...
             'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontWeight', 'bold');

    end

end
