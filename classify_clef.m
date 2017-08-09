function [ class ] = classify_clef(clefs, staff)
    %UNTITLED4 Returns 0, for treble clef, 1 for bass clef

    % Bass clef does not extend into the bottom space of the staff, but treble
    % does, so sum up the pixels in that bottom space

    % Not robust to any text/brackets preceding the line

    class = zeros(size(clefs));
    % Sum the pixels in the bottom space
    for i=1:length(clefs)
        % Erase the bar lines
        %         indices0 = staff(:,i) - 2; % 1 above
        indices1 = staff(:,i) - 1; % 1 below
        indices3 = staff(:,i) + 1; % 1 above
        %         indices4 = staff(:,i) + 2; % 1 below
        barless = clefs{i};
        barless([indices1 staff(:,i) indices3]) = 1;
        
%         spacing = staff(5,i) - staff(4,i)
        
        pixel_sum = sum(sum(~barless(staff(4,i)+3:staff(5,i)-3, :),1));
        
        % normalize by the height (squared?), not the width of the region in question
        area = (staff(5,i) - staff(4,i));% * size(clefs, 2);
%         pixel_sum
        class(i) = pixel_sum < area;   
        
    end
end