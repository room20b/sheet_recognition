
function [ note_distances ] = convert_keysig(key_sig, notes )
%Apply the key signature to the note distances from the base of the staff

% flats0 = [4,7,3,6,2,5,1];
flats = [7,12,5,10,3,8,1];
% sharps0 = [8,5,9,6,3,7,4];
sharps = [13,8,15,10,5,12,7];

for i=1:abs(key_sig)
    if (key_sig > 0)
        for j=1:length(notes)
            if ((notes(j) == sharps(i)) || (notes(j) == sharps(i)-12))
                notes(j) = notes(j) + 1;
            end
        end
    elseif (key_sig < 0)
        for j=1:length(notes)
            if ((notes(j) == flats(i)) || (notes(j) == flats(i)-12))
                notes(j) = notes(j) - 1;
            end
        end
    end
end

note_distances = notes;

end

