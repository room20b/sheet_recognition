function [ solid_notes ] = find_solid_notes(staves, staff, dividers)
%find_solid_notes retrieves the coordinates of all of the solid black music
%notes

    solid_notes = cell(size(staves));
    for i=1:length(staves)
        spacing = round(mean(mean(diff(staff,1),1)));
        solid_notes{i} = ~staves{i};
        
        % erode the image using a small circle
        SE = strel('disk', round(spacing/4));
        solid_notes{i} = imerode(solid_notes{i}, SE);
        solid_notes{i} = imdilate(solid_notes{i}, SE);
       
        % Look at connected components
        CC = bwconncomp(solid_notes{i});
        stats = regionprops(CC, 'Eccentricity', 'Area', 'Centroid');
        objs = [];
        areas = [];
        matches = zeros(CC.ImageSize);
        
        for j=1:CC.NumObjects
            % Reject components that are less than half the note area
%             if (stats(j).Area < 0.125*spacing*spacing)
%                 continue;
%             end
            
            % Keep the slghtly eccentric circles that aren't too close to
%            the clef
            if (stats(j).Eccentricity < 0.8 && ...
                    stats(j).Eccentricity > .6 && ...
                    stats(j).Centroid(1) > dividers(i)) % has to bee past the clef
                objs = cat(1, objs, j);
                areas = [areas ; stats(j).Area];
            end
        end

        %% Remove the objects whose areas are too small
        if (std(areas) > 0.25*spacing)
            objs = objs(areas > (median(areas) - 1.75*std(areas)));
        end
        
        solid_notes{i} = zeros(length(objs),2);
        for j=1:length(objs)
            matches(CC.PixelIdxList{objs(j)}) = 1;
            solid_notes{i}(j,:) = stats(objs(j)).Centroid;
        end
        % Flip so that the first item is the y coordinate (row)
        % and the second is the x coordinate (col)
        solid_notes{i} = fliplr(solid_notes{i});
        
        r = double(staves{i} | matches);
        g = double(staves{i} & ~matches);
        b = double(staves{i} & ~matches);
        
        colorimg = cat(3, r,g,b);
%         imshow(colorimg);
%         pause;
    end
end

