clear all
InputDir = 'TSR/input';
load('matlab.mat')

InputSet = imageDatastore(InputDir,   'IncludeSubfolders', true, 'LabelSource', 'foldernames');
totalfiles = numel(InputSet.Files);
% Start Video
v = VideoWriter('VideoOutput_11','MPEG-4');
v.FrameRate = 30;
open(v);
for frameNum = 2000:2861
    I = readimage(InputSet,frameNum);
    %     G = gpuArray(I);
    I = imresize(I, 0.65);
    J = imadjust(I,stretchlim(I),[]);
    %% Filtering and HSV Conversion
    I = imgaussfilt(J);
    %% Apply masks
    [B_BW, MaskedBlue] = BlueMask(I);
    [R_BW, MaskedRed] = RedMask(I);
    
    
    %% Morphing Operation
    % For Blue
    B_I3 = bwareaopen(B_BW,50);
    
    %For Red
    R_I3 = bwareaopen(R_BW,20);
    
    % Combining Both
    FinalImage = B_I3 | R_I3;
    
    stat = regionprops(FinalImage,'boundingbox', 'Area','Extent','Image');
    imshow(I); hold on;
    for cnt = 1 : numel(stat)
        if(stat(cnt).Area > 100 && stat(cnt).Extent > 0.4)
            bb = stat(cnt).BoundingBox;
            AspectRatio = (bb(3)/bb(4));
            if(AspectRatio > 0.7 && AspectRatio < 1.2)
                bb(1) = bb(1) - 1;
                bb(2) = bb(2) + 1;
                bb(3) = bb(3)+1;
                bb(4) = bb(4)+1;
                Sample = imcrop(J,bb);
                rectangle('position',bb,'edgecolor','r','linewidth',2);
                GraySample = rgb2gray(Sample);
                ReSizedSample =imresize(GraySample, [64,64]);
                features = extractHOGFeatures(ReSizedSample,'CellSize',[4,4]);
                prediction = predict(classifier, features);
                %                 disp(prediction);
                target = char(prediction);
                f = dir(strcat('TSR/Training/',target));
                TargetImageLoc = strcat('TSR/Training/',target,'/', f(4).name);
                detectedSign = imread(TargetImageLoc);
                detectedSign = imresize(detectedSign, [64,64]);
                a = (bb(1)-63);
                b =(bb(2) + 63);
                imagesc([a bb(1)], [bb(2) b], detectedSign)
            end
        end
    end
    drawnow
    frame = getframe(gcf); % 'gcf' can handle if you zoom in to take a movie.
    writeVideo(v, frame);
end
close(v);
