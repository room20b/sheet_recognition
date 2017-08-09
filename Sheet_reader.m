% Piano sheet recognition - by(David Joe, Vedanth Swain)    

    image1 = im2double(rgb2gray(imread('frere.jpg')));
    %finding the threshold of the image
    T = graythresh(image1);
    %Inverting the image (i.e. white notes&black background
    image1 = ones(size(image1)) - im2bw(image1,T);
    
    image1_orig = ones(size(image1)) - image1;
    %erode the image horizontally so the sum_pix Thresh_sum_pix remain
    image1 = imerode(image1, ones(1,round(size(image1,2)/10)));
    %dilate the image horizontally
    image1 = imdilate(image1, ones(1,round(size(image1,2)/10)));
    %summing all the pixels along rows and making a vector
    sum_pix = sum(image1,2)/size(image1,2);
    figure();
    plot(sum_pix);
    %threshold the sum_pix vector and bascally have it in binary
    %this is basically the binary histogram
    Thresh_sum_pix = im2bw(sum_pix, graythresh(sum_pix));
    figure();
    plot(sum_pix);
    title('staff lines -frere');
    %slide a bar through the column vector, used later in summin the rows
    %and finding the maximum
    spaces = zeros(size(Thresh_sum_pix));
   
    %%
    %complement of Thresh_sum_pix, we now have to erode vertically
    Comp_Thresh_sum_pix = ones(size(Thresh_sum_pix)) - Thresh_sum_pix;
    
    %%
    %if we look at Thresh_sum_pix the sum_pixs have 8 row of gap between them 
    for i = 8:round(size(image1,1)/8) 
        X = ones(i,8);
        spaces = spaces + imerode(Comp_Thresh_sum_pix, X);
    end
    figure();
    plot(spaces);
    %%
    %threshold using the median
    thresh_level = spaces .* (spaces > median(spaces));
    %%
    
    %we leave away the zeros and take 10th percentile    
    if(sum(thresh_level) > 0)
        thresh_level = sort(thresh_level((thresh_level > 0)));
        thresh_level = thresh_level(round(.1* length(thresh_level)));
    %if image is mostly blank 
    else
        %remove the entries with the maximum to get the threshold level
        clipped = spaces;
        clipped(clipped > 0.9*max(spaces)) = [];
        thresh_level = median(clipped);
    end
    %thresholding
    spaces = (spaces > thresh_level);
    %%
    %Use connected components to display the image 1 bar at a time and store the smaller image of each stave in a cell array
    Con_comp = bwconncomp(1-spaces);
    divide = zeros(size(sum_pix));
    %store the output in a cell array
    staves = cell(Con_comp.NumObjects,1);    
    for i= 1:Con_comp.NumObjects
        rows = Con_comp.PixelIdxList{i};
        max_val=max(Con_comp.PixelIdxList{i});
        min_val=min(Con_comp.PixelIdxList{i});
        T = round((max_val - min_val)/4);
        extended_rows = min(Con_comp.PixelIdxList{i}) - T : max(Con_comp.PixelIdxList{i}) + T;
       
        divide(extended_rows(1)) = 1;
        divide(extended_rows(end)) = 1;
        staves{i} = image1_orig(extended_rows,:);
        
        %use Con_comp to cut off extra white space
        collapsed = sum(~staves{i}, 1)>0;
        Con_comp_V = bwconncomp(collapsed);
        
        max_id = 1;
        max_list = 0;
        for x=1:Con_comp_V.NumObjects
            l = length(Con_comp_V.PixelIdxList{x});
            if (l < max_list)
                break;
            else
                max_id=x;
                max_list = l;
            end
        end
        %This gives us the cell array of the image1
        staves{i} = staves{i}(:, Con_comp_V.PixelIdxList{max_id});
    end
    %%
    %row numbers for the staff lines
    staff = find_staff(staves);
    
    %start of the line to get the clef
    clefs = segment_clefs(staves, staff);
    
    clef_labels = classify_clef(clefs, staff);% (S. Harris and P. Verma Code)

    %find key signature and count the number of sharps or flats
    [key_segments, dividers] = segment_keys(staves, staff);
    
    key_sigs = classify_key(key_segments, staff, clef_labels);% (S. Harris and P. Verma Code)

    %return a matrix for each stave containing the coordinates of the note
    solid_notes = find_solid_notes(staves, staff, dividers);% (S. Harris and P. Verma Code)
    
    flags = get_flags(staves, staff, solid_notes);% (S. Harris and P. Verma Code)
    
    
    %%
    %Create the matrix
    M=0;
    pos = [1,3,5,7,8,10,12,13,15,17];
    neg = [-2,-4,-5,-7,-9];
    for i=1:length(staves)
        current_staff=staff(:,i);
        for k=1:length(solid_notes{i})
            if(flags{i}(k)==1)
                dur1(k)=0.5;
            else
                dur1(k)=1;
            end
        end
        staff_width = mean(diff(current_staff));    
        sz= size(solid_notes{i});        
        for j=1:sz(1)
            loc = round((2*(current_staff(5)-solid_notes{i}(j,1)))/staff_width)
            M=M+1;
            Ampli_(M)=loc;
            dur(M)=dur1(j);       
        end
    end
    for i=1:length(Ampli_)
        if(Ampli_(i)>0)
            Ampli_1(i)=pos(Ampli_(i));
        else if(Ampli_(i)==0)
            Ampli_1(i)=0;
            else if(Ampli_(i)<=0)
                Ampli_1(i)=neg(-1*Ampli_(i));
                end
            end
        end    
    end
    Ampli_1 = convert_keysig(key_sigs,Ampli_1);% (S. Harris and P. Verma Code)
    d = 0.5;
    for i=1:length(Ampli_)
        Freq_(i,1)=440.*(1.06.^Ampli_1(i));
        Freq_(i,2)= d*dur(i);
    end
    figure();
    stem(Freq_);
    title('Frequenncies of the notes - frere');
    %Here the notes are the frequencies of the the played notes on the
    %sheet and Ampli_1 contains the amplitude of the corresponding notes.
    
    %David-comment/update the code whereever necessary, 
