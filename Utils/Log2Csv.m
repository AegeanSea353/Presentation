
function Suc = Log2Csv(log_filepath, csv_filepath)
 
% Convert Log to Csv format applied to Presentation software.
% Import Presentation data, find the key lines, convert it from tab-separated format 
% to comma-separated format and save it as a new .csv file.
%
% Input:
% log_filepath: set your log path 
% csv_filepath: set your csv path for final output
%
% Output:
% Suc: Convert sucessfully (true) or not (false)

    Suc = false;

    try
        
        All_lines = readlines(log_filepath);

        % Find the header row and end row
        Header_row_index = find(startsWith(All_lines, 'Subject'), 1, 'first');
        End_row_index = find(startsWith(All_lines, 'Visual picture detection failed')); % Custom settings
        
        Valid_lines = All_lines(Header_row_index : End_row_index-1);
        Csv_lines = strings(size(Valid_lines));
        
        for i = 1:length(Valid_lines)
            Csv_lines(i) = strrep(Valid_lines(i), sprintf('\t'), ',');
        end
        
        writelines(Csv_lines, csv_filepath);
        
        Suc = true;

    catch ME

        fprintf('Error occurred during conversion: %s\n', log_filepath);
        fprintf('Info: %s\n', ME.message);
        
    end

end
