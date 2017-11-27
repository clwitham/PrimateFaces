% primatefaces_traindet Train a new detector for either face or facial
% features. Called by primatefaces_main.
%
% Requirements:
% 1) Positive Folder: folder containing only images of the feature (e.g.
% face or eye) that you want to detect.
% 2) Negative Folder: folder containing negative images i.e. images that do
% not contain feature of interest. May include natural scenes, enclosure
% backgrounds etc.

function [] = primatefaces_traindet

%% Ask user for location of folder containing positive images
positive_folder=uigetdir('','Select folder containing positive images');

%% read in positive images one by one, check size and set up positive instances variable for cascade classification. Also create average image.
if positive_folder~=0
    images = dir(positive_folder);
    images = {images(3:end).name};
    im_size=zeros(2,length(images));
    noim=0;
    
    for n=1:length(images)
        [~,~,ext] = fileparts(images{n});
        if strcmp(ext,'.jpg')||strcmp(ext,'.png')||strcmp(ext,'.tif')
            A=[positive_folder,'\',images{n}];
            img_info=imfinfo(A);
            noim=noim+1;
            im_size(:,noim)=[img_info.Height,img_info.Width];
            detect_var.positiveInstances(noim).imageFilename=A;
            detect_var.positiveInstances(noim).objectBoundingBoxes=[1,1,img_info.Width,img_info.Height];
            
        end
    end
    im_size=im_size(:,1:noim);
    [pix,i]=min(im_size(1,:).*im_size(2,:));
    im_size=im_size(:,i);
    if pix>600
        r=im_size(1)/im_size(2);
        d=max(im_size);
        if (r>0.5)&&(r<2)
            ratio=d./24;
        else
            ratio=d./40;
        end
        im_size=im_size./ratio;
    end
    im_size=round(im_size);
    detect_var.im_size(1,1)=im_size(1);
    detect_var.im_size(1,2)=im_size(2);
    godetect=1;
else
    godetect=0;
end

%% Ask user for location of folder containing negative images
if godetect
    negative_folder=uigetdir('','Select folder containing negative images');
    if negative_folder==0
        godetect=0;
    end
    detect_var.negativeFolder=negative_folder;
end

%% Ask user for location and name of file to save output to
if godetect
    [detect_var.savefile,detect_var.savedir]=uiputfile({'*.xml'},'Save detector as');
    if detect_var.savefile==0
        godetect=0;
    end
end

%% train detector using information above
if godetect
    %show information screen
    detfig=figure('Name','Training Detector','Menubar','none','Position',[0,0,400,250],'Units','Pixels','NumberTitle','off','Resize','off'); % create setup window
    movegui(detfig,'center')
    traintxt={'Training Detector (may take some time)';['Size:', num2str(im_size(1)),' x ',num2str(im_size(2))];['NumCascadeStages: ','40'],;['FeatureType: ','LBP']};
    dettxt=uicontrol('Parent', detfig, 'Position',[5,60,390,180],'Style','text','String',traintxt,'FontSize',10);
    figexist=1;
    pause(1);
    
    % train the object (face or other features) detector
    origdir=cd;
    cd(detect_var.savedir);
    trainCascadeObjectDetector(detect_var.savefile,detect_var.positiveInstances,detect_var.negativeFolder,...
        'NumCascadeStages',40,...
        'FeatureType','LBP',...
        'ObjectTrainingSize',detect_var.im_size,...
        'NegativeSamplesFactor',2,...
        'FalseAlarmRate',0.5,...
        'TruePositiveRate',0.995);
    
    
    % check if training is complete and if so display completed screen
    fh=fopen(detect_var.savefile,'r');
    if fh~=-1
        isdone=0;
        while ~isdone
            a=fgetl(fh);
            i=find(a=='<');
            j=find(a=='>');
            if ~isempty(i)&&~isempty(j)
                a2=a(i(1)+1:j(1)-1);
                if strcmp(a2,'stageNum')
                    numStages=str2double(a(j(1)+1:i(2)-1));
                    isdone=1;
                end
            end
        end
        fclose(fh);
        detect_var.trained=1;
        try
            dettxt.String={['Cascade object detector trained with ', num2str(numStages),' stages'];['Detector saved as ',detect_var.savefile]};
        catch
            figexist=0;
        end
    else
        try
            dettxt.String='Error in training';
        catch
            figexist=0;
        end
    end
    
    cd(origdir)
    if figexist
        uicontrol('Parent',detfig,'Position',[250,5,100,50],'Style','pushbutton','String','OK','Callback',@finish_train,'BackgroundColor',[0.7,0.7,0.7])
        uiwait(detfig)
    end
end

    function finish_train(~,~,~)
        close(detfig)
    end
end