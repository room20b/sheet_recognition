function [ flags ] = get_flags(staves, staff, solid_notes )
%get_flags Takes in the note locations
%   Returns the number of flags:
% 0 - Quarter note
% 1 - Eight note (no triplets to start)
% 2 - Sixteenth note
% No 32nd notes cause that's just cruel
% return in the same format as the input: cell aray of matrices
    flags = cell(size(solid_notes));
    for i=1:length(solid_notes)
        spacing = round(mean(mean(diff(staff,1),1)));
        for j=1:size(solid_notes{i}, 1)
            % segment the note
            x = solid_notes{i}(j,2);
            note_window = ~staves{i}(:,x-spacing:x+spacing);
            
            %% FInd the stem horizontal location and whether it is above or below the note
%             stem = imerode(note_window, ones(spacing,1));
%             stats = regionprops(stem, 'Centroid');
%             
%             % Mark 0 for lower stem, 1 for upper
%             if (stats(1).Centroid(2) > solid_notes{i}(j,1))
%                 flags{i} = cat(1, flags{i}, 0);
%             else
%                 flags{i} = cat(1, flags{i}, 1);
%             end
%             proj = sum(stem,1);
%             stem_loc = find(proj == max(proj));
%             note_window(:,stem_loc) = 1;

            % Erode the image with a small disk
            SE = strel('disk', round(spacing/4));
            note_window = imerode(note_window, SE);
            CC = bwconncomp(note_window);
            flags{i}(j) = CC.NumObjects - 1;
%             imshow(note_window);
%             pause;

            
        end
    end
end

