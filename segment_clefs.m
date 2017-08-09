function [ clefs ] = segment_clefs( staves, staff )
%(David Joe, Vedanth Swain)
%Segments the clefs on each staff
%   Given binary matrices of staves, and the indices of the staff lines,
%   this function segments the clefs by finding the bounding regions and
%   returning them.

    % Intialize variable to store one clef for each staff
    clefs = cell(size(staves));

    % Loop through each staff
    for i = 1 : length(staves)
        
        % Invert staff and sum each column, between the top and bottom staff lines
        inverted_staff = ~staves{i};
        vertical_range = staff(1, i) : staff(5, i);
        column_sums = sum(inverted_staff(vertical_range, :), 1);
        
        % Estimate the value corresponding to an empty staff as the 0.3
        % quantile of the column sum values
        empty_staff_value = quantile(column_sums, .3);
        
        % Find the start of the staff by finding the first value greater than the empty staff value 
        start = find(column_sums > empty_staff_value, 1);
        
        % Calculate the mean spacing between staff lines by averaging
        vertical_diffs = diff(staff,1,1);
        mean_spacing = mean(mean(vertical_diffs,1));
        
        % Find the end of the clef by estimating its width to be 3 times
        % the spacing between staff lines
        ending = start + 3*mean_spacing;
    
        % Store the region corresponding to the clef
        clefs{i} = staves{i}(:, start:ending);
    end
    
end

