function [key_sigs] = classify_key(key_segment, staff, clef_labels)
    %Given a part of the image that has a key signature
    % Return the number of sharps or flats in the key signature
    % Encoded as negative numbers for flats, positive number for sharps
    %%%%%%%%%%%%%%%%%%%%%%%BUG!
    % still picks up accidentals from te line,problem if no sharps and it's
    % an F#
    key_sigs = zeros(size(key_segment));

    for i=1:length(key_segment)
        spacing = round(mean(mean(diff(staff,1),1)));
       
        % Good for detecting sharps (2 parallel lines)
        SE = ones(round(spacing),1);
        img = imerode(key_segment{i},SE);
        img = imdilate(img, SE);
        img = imdilate(img, SE);
        
        % Get index of row for the bar line / space
        if (clef_labels(i) == 0)
            sharp_positions = [staff(1,i) ...           % F#
                round((staff(2,i) + staff(3,i))/2) ...  % C#
                round(staff(1,i) - spacing/2) ...       % G#
                staff(2,i) ...                          % D#
                round((staff(3,i) + staff(4,i))/2) ...  % A#
                round((staff(1,i) + staff(2,i))/2) ...  % E#
                staff(3,i)];                            % B#
            
            flat_positions = [staff(3,i) ...            % Bb
                round((staff(1,i) + staff(2,i))/2) ...  % Eb
                round((staff(3,i) + staff(4,i))/2) ...  % Ab
                staff(2,i) ...                          % Db
                staff(4,i) ...                          % Gb
                round((staff(2,i) + staff(3,i))/2) ...  % Cb
                round((staff(4,i) + staff(5,i))/2)];    % Fb
        else
            sharp_positions = [staff(2,i) ...           % F#
                round((staff(3,i) + staff(4,i))/2) ...  % C#
                round((staff(1,i) + staff(2,i))/2) ...  % G#
                staff(3,i) ...                          % D#
                round((staff(4,i) + staff(5,i))/2) ...  % A#
                round((staff(2,i) + staff(3,i))/2) ...  % E#
                staff(4,i)];                            % B#

            flat_positions = [staff(4,i) ...            % Bb
                round((staff(2,i) + staff(3,i))/2) ...  % Eb
                round((staff(4,i) + staff(5,i))/2) ...  % Ab
                staff(3,i) ...                          % Db
                staff(5,i) ...                          % Gb
                round((staff(3,i) + staff(4,i))/2) ...  % Cb
                round(staff(5,i) + spacing/2)];         % Fb
        end
        
%         Use connected components and morphological image processing
        CC = bwconncomp(img);
%         imshow(img);
%         pause;
        masks = cell(size(key_segment));
        objs = [];
        locs = [];
        for j=1:CC.NumObjects
            mask = zeros(CC.ImageSize);
            mask(CC.PixelIdxList{j}) = 1;
            if (sum(sum(mask(sharp_positions,:))) > 0)
                masks{j} = mask;
                objs = cat(1, objs, j);
%                 imshow(mask);
%                 pause;
            end
        end
        % Analyze adjacent components
        k=1;
        for j=1:length(objs)-1
%             Look for components that are ...
            width1 = sum((sum(masks{objs(j)},1) > 0),2);
            width2 = sum((sum(masks{objs(j+1)},1) > 0),2);
            height1 = sum((sum(masks{objs(j)},2) > 0),1);
            height2 = sum((sum(masks{objs(j+1)},2) > 0),1);
            
            % Thin
            thin = ((width1/height1) < 0.15) & ((width2/height2) < 0.15);
            
            % spaced close together
            p1 = find(sum(masks{objs(j)}) > 0);
            p2 = find(sum(masks{objs(j+1)}) > 0);
            close = (p2(1)-p1(end)) < round(spacing/2);
            
            % Similar height
            sim = 1;%abs(height1 - height2) < spacing/4;
            
            % not staggered too much vertically
            height_comb = sum((sum(masks{objs(j)} | masks{objs(j+1)},2) > 0),1);
            aligned = (height_comb / min([height1 height2])) < 1.2;
        
            % Record the locations of the sharps that are detected
            if (thin & close & sim & aligned)
                rows = find(sum(masks{objs(j)},2) > 0);
                
                locs(k,:) = [round((rows(1)+rows(end))/2),...
                    find(sum(masks{objs(j)},1) > 0, 1)];
                
                k=k+1;
%                 imshow(masks{objs(j)} | masks{objs(j+1)});
%                 pause;
            end
        end
%         locs

        % make sure there isn't much white space between sharps
        valid =10;
        for h=2:size(locs,1)
            if ((locs(h,2)-locs(h-1,2)) > round(1.5*spacing))
                valid=h-1;
                break;
            end
        end
        
        % Count the number of sharps detected in valid locations
        count = 0;
        for h=1:size(locs, 1)
            if (abs(sharp_positions(h)-locs(h,1)) > 5)
                break;
            end
            count = count+1;
        end
        
        % Are there any components to the left of the key signature?
        if (size(locs,1) > 0)
            if (locs(1,2) > 2*spacing)
                valid=0;
            end
        end
        
        % Use the formations to get the actual key signature
%         unique(cols)
%         key_sigs(i) = size(locs,1);
        key_sigs(i) = min([valid,count]);
    end
        %%%%%%%%%%%%%%%%%%%%%%%%% Find Flats %%%%%%%%%%%%%%%%%%
    for i=1:length(key_segment)
        if (key_sigs(i) == 0)
%             imshow(key_segment{i});
%             pause;
            %% Erase the barlines
            locs =[];
            spacing = round(mean(mean(diff(staff,1),1)));
            
  
            % check for activity on both size
        for j=3:size(key_segment{i},2)-3
            for k=1:5
                window = [0 3 5 3 0;...
                          0 2 4 2 0;...
                          0 1 3 1 0;...
                          0 0 2 0 0;...
                          0 0 1 0 0];  

                activity_above = sum(sum(window .* key_segment{i}(staff(k,i)-4:staff(k,i),j-2:j+2)));
                activity_below = sum(sum(flipud(window) .* key_segment{i}(staff(k,i):staff(k,i)+4,j-2:j+2)));
                T = 15;
                % Erase it if there isn't enough activity
                if ((activity_above < T) && (activity_below < T))
                    key_segment{i}(staff(k,i)-4:staff(k,i)+4,j) = zeros(9,1);
                end
            end
        end
%         
%         imshow(key_segment{i});
%         pause;
            
            
            
%             SE = ones(round(1.25*spacing),1);
            SE = strel('disk', round(spacing/4));
         
%             img = imdilate(key_segment{i}, ones(2,round(spacing/2)));

            img = imdilate(key_segment{i}, SE);
            img = imerode(img, SE);
            SE = strel('disk', round(spacing/4));
            img = imerode(img, SE);
           
            
            
            
            %% collect all of the objects that fall where I'm interested
            CC = bwconncomp(img);
            img(staff(3,i),:) = 1;
%             imshow(img)
%             pause;
            
            for j=1:CC.NumObjects
                mask = zeros(CC.ImageSize);
                mask(CC.PixelIdxList{j}) = 1;
                m = sum(mask,2);
                v = sum(mask,1);
                % Loop through the flat positions
                for k=1:7
                    if (sum(m(flat_positions(k)-2:flat_positions(k)+2)) > 0)
                        f = find(m>0);
                        % approximate vertical center using the object's
                        % perimeter
                        vcom = round((f(1)+f(end))/2);
                        
                        % reject objects that are too large
                        if (sum(sum(mask)) < spacing * spacing)
                        
                        % Make sure the height of the detected object is
                        % small enough
                        
                        locs = cat(1, locs, [vcom find(v > 0, 1)]);
                        end
                    end
                end
            end
            
            %% Look through the collected components
% locs
            valid = 10;
            count = 0;
            if (size(locs,1) > 0)
                unique_locs = locs(1,:);
                % Some entries are located in the same column - remove
                % these
                for k=2:size(locs,1)
                    if (locs(k,2) ~= locs(k-1,2))
                        unique_locs = cat(1, unique_locs, locs(k,:));
                    end
                end
                

                % Make sure it starts with a plausible vertical location
                if (abs(unique_locs(1,1) - flat_positions(1)) > round(spacing/2))
                    % Try the second one if the first one is right up against
                    % the edge, it could be a remnant from the clef
                    if (unique_locs(1,2) > round(spacing/2))
%                         a = 1
                        valid = 0;
                    elseif size(unique_locs,1) > 1
                        % check the next component
                        if (abs(unique_locs(2,1) - flat_positions(1)) > round(spacing))
%                             b = 2
                            valid=0;
                        else
                            % remove the first component
                            unique_locs(1,:) = [];
%                             count = count -1;
                        end
                    end
                end
                
                count=size(unique_locs,1);
            end
            
%             make sure there isn't much white space between flats
            for h=2:size(unique_locs,1)
                if ((unique_locs(h,2)-unique_locs(h-1,2)) > round(2*spacing))
                    valid=h-1;
                    break;
                end
            end
            
            % Account for no key signature
            if (unique_locs(1,2) > 2*spacing)
%                 c = 3
                valid=0;
            end
           
            
            % Use negatives because these are flats
            key_sigs(i) = -min([valid count]);
        end
    end
    
end

