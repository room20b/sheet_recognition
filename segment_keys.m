function [keys, divider] = segment_keys(staves, staff)
%(David Joe, Vedanth Swain)
    % Initialize variables
    keys = cell(size(staves));
    divider = zeros(size(staves));
    
    for i = 1 : length(staves)
        %% Get the start of the line -> start
        % Erase the bar lines
        indices = staff(:,i);
        indices_above = staff(:,i) - 1; % 1 below
        indices_below = staff(:,i) + 1; % 1 above
        
        barless = staves{i};
        barless([indices indices_above indices_below], :) = 1;

        imshow(barless);
        
        
        % Invert staff and sum each column, between the top and bottom staff lines
        inverted_barless = ~barless;
        vertical_range = staff(1, i) : staff(5, i);
        column_sums = sum(inverted_barless(vertical_range, :), 1);
        
        % Estimate the value corresponding to an empty staff as the 0.3
        % quantile of the column sum values
        empty_staff_value = quantile(column_sums, .3);
        
        % Find the start of the staff by finding the first value greater than the empty staff value 
        start = find(column_sums > empty_staff_value, 1);
        
        % Calculate the mean spacing between staff lines by averaging
        vertical_diffs = diff(staff,1,1);
        mean_spacing = mean(mean(vertical_diffs,1));
        
        spacing = round(mean(mean(diff(staff,1),1)));
        collapsed = sum(~barless(staff(1,i): staff(5,i), :), 1);
        
        % Find the horizontal start of the bar line
        T = quantile(collapsed, .3);
        start0 = find(collapsed > T, 1);
        

        %% Use the center of mass of the first square 
        % to get partway through the clef
        clef = ~staves{i}(staff(1,i):staff(5,i), start0:start0 + 3*spacing);
        com = cumsum(sum(clef,1) / sum(sum(clef)));
        start1 = find(com > 0.5, 1);
        collapsed = collapsed(start0 + start1:round(.75*end));
        keys{i} = ~staves{i}(:, start0+start1:end);
        
        %% erase the bars
        new_start = start0 + start1;
        barless = keys{i}(:, 1:round(.75*end));
            % check for activity on both size
        for j=3:size(keys{i},2)-3
            for k=1:5
                window = [0 3 5 3 0;...
                          0 2 4 2 0;...
                          0 1 3 1 0;...
                          0 0 2 0 0;...
                          0 0 1 0 0];  

                activity_above = sum(sum(window .* keys{i}(staff(k,i)-4:staff(k,i),j-2:j+2)));
                activity_below = sum(sum(flipud(window) .* keys{i}(staff(k,i):staff(k,i)+4,j-2:j+2)));
                T = 15;
                % Erase it if there isn't enough activity
                if ((activity_above < T) && (activity_below < T))
                    barless(staff(k,i)-4:staff(k,i)+4,j) = zeros(9,1);
                end
            end
        end
%         imshow(barless);
%         pause;
        
        %% Find the first blank staff space
        collapsed = sum(barless,1);
%         (staff(1,i): staff(5,i))
%         collapsed = collapsed(new_start:round(.75* size(staves{i},2)));
        
%         T = quantile(collapsed, 0.01);
        start2 = find(collapsed == 0);
%         start2 = find(collapsed < T);
        if (length(start2) < 1)
            start2 = round(spacing/2);
        else
            start2 = start2(1);
        end
        divider(i) = start0 + start1 + start2;
        keys{i} = keys{i}(:, start2:start2 + 10*spacing);     

    end
end