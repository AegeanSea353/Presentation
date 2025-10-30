function T = ReadLogFile(log_filepath, csv_filepath)
% Read Presentation log file directly as tab-delimited
% Also saves a properly formatted CSV file
% Returns a table or empty table if failed

    try
        All_lines = readlines(log_filepath);
        
        % Find the header row and end row
        Header_row_index = find(startsWith(All_lines, 'Subject'), 1, 'first');
        End_row_index = find(startsWith(All_lines, 'Visual picture detection failed'));
        
        Valid_lines = All_lines(Header_row_index : End_row_index-1);
        
        % Remove empty lines
        Valid_lines = Valid_lines(strlength(Valid_lines) > 0);
        
        % Write to temporary file
        temp_file = tempname;
        writelines(Valid_lines, temp_file);
        
        % Read as tab-delimited table
        T = readtable(temp_file, 'Delimiter', '\t', 'PreserveVariableNames', true);
        
        % Clean up temp file
        delete(temp_file);
        
        % Save as CSV
        writetable(T, csv_filepath);
        
    catch ME
        fprintf('Error reading log file: %s\n', log_filepath);
        fprintf('Info: %s\n', ME.message);
        T = table();
    end

end