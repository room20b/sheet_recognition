function [ staff ] = find_staff( staves )
%(David Joe, Vedanth Swain)
%Finds the indices of the staff lines
%   Given an input of binary matrices representing individual staves, this 
%   function finds the indices of the staff lines by finding the maximum
%   row sums for any 5 equally spaced rows.
%
%   This computation is done by inverting the matrices so that black
%   corresponds to 1s. Then the starting index of the first row and the 
%   spacings are varied. Row sums are calculated for the 5 selected rows,
%   and also the rows immediately above and below these selected rows, in
%   order to account for slight variations in spacing. Then maximum sum is
%   found and the corresponding indices stored in the variable staff.  

    % Initialize variables
    curr_sums = zeros(length(staves), 1);   % current sums for each staff
    max_sums = zeros(length(staves), 1);    % maximum sums for each staff
    staff = zeros(5, length(staves));       % indices of staff lines for each staff
    
    
    % Loop through each staff
    for i = 1 : length(staves)
        
        % Invert the staff and find the sum of each row
        inverted_staff = ~staves{i};
        row_sums = sum(inverted_staff, 2);
        height = length(row_sums);
        
        % Vary spacing of staff lines up to 1/5 of the height
        for spacing = 2 : height/5;
            
            % Vary starting row up to half the height
            for start = 2 : height/2;
                
                % Find indices for the staff lines, including the rows
                % above and below
                indices = (start : spacing  : start + 4*spacing);
                indices_above = (start - 1 : spacing : start - 1 + 4*spacing);
                indices_below = (start + 1 : spacing : start + 1 + 4*spacing);
                
                % Make sure indices are not out of range
                if (indices_below(5) > height)
                    break;
                end
                
                % Sum all of the selected rows, including the rows directly
                % above and below
                curr_sums(i) = sum(row_sums([indices indices_above indices_below]));
                
                % Update maximum sum and store indices
                if (curr_sums(i) > max_sums(i))
                    max_sums(i) = curr_sums(i);
                    staff(:,i) = indices;
                end               
            end
        end
    end

end

