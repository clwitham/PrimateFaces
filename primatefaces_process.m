% primatefaces_process Run face detection (+ recognition) on images and/or videos
% Program called by primatefaces_setup.
%
% Permitted image formats: JPG, PNG, TIF
% Permitted video formats: AVI, MOV, MP4, WMV
%
% Face Detection
% Outputs detected faces as cropped and resized JPEG files and the original
% image or video still with faces outlined + CSV file listing all detected faces.
% 
% Face Recognition
% Outputs CSV file containing list of faces along with image file (for
% images), frame number (for videos), location and identity. Option to also
% save output as processed image or video files.


function [] = primatefaces_process(detect_var,varargin)

if nargin>1
    runrec=1; % 1 if running recognition, 0 if just detection
    recog_var=varargin{1};
else
    runrec=0;
end

godetection=1; % switch to 0 if any problems

imgfolder = uigetdir('','Select folder containing videos or images');
if imgfolder==0 % cancel if folder is invalid
    godetection=0;
else
    %% sort files into video files (permitted formats wmv, mp4, avi and mov) and image files (permitted formats jpg, png, tif)
    files = dir(imgfolder);
    files = {files(3:end).name};
    savename=cell(size(files));
    filetype=zeros(size(files));
    for n=1:length(files)
        [~,savename{n},ext] = fileparts(files{n});
        if strcmp(ext,'.jpg')||strcmp(ext,'.png')||strcmp(ext,'.tif')
            filetype(n)=1;
        elseif strcmp(ext,'.wmv')||strcmp(ext,'.mp4')||strcmp(ext,'.avi')||strcmp(ext,'.mov')
            filetype(n)=2;
        end
    end
    novids=sum(filetype==2);
    noimg=sum(filetype==1);
    noI=0;
    noV=0;
    if novids==0&&noimg==0
        errordlg('No valid image or video files'); % cancel if no valid video or image files
        uiwait
        godetection=0;
    else
        savedir=uigetdir('','Select folder to save output to'); % select output folder
        if savedir==0
            godetection=0;
        end
    end
    if novids>0&&godetection==1
        frameint=inputdlg('What interval between frames do you want to analyse (enter 1 to analyse every frame)?'); % allow user to select number of frames to analyse
        frameint=round(str2double(frameint));
        if frameint<1
            frameint=1;
        end
    end
end


if godetection
    %% Process Images
    if noimg>0
        ident=cell(100000,1); % intitalise variables for output
        locat=zeros(100000,4);
        indiv=cell(100000,1);
        totfaces=0;
        
        img=find(filetype==1);
        wb=waitbar(0,'Processing Images','CreateCancelBtn','setappdata(gcbf,''canceling'',1)');
        setappdata(wb,'canceling',0);
        
        for noI=1:length(img) % read in images one by one
            if getappdata(wb,'canceling')
                break
            end
            waitbar(noI/length(img));
            
            save_prefix=[savedir,'\',savename{noI}];
            I=imread([imgfolder,'\',files{img(noI)}]); % read in image
            isvid=0;
            process_frame % analyse frame
        end
        delete(wb);
        
        ident=ident(1:totfaces); % process output
        locat=locat(1:totfaces,:);
        locat(:,1)=round(locat(:,1)+(0.5*locat(:,3)));
        locat(:,2)=round(locat(:,2)+(0.5*locat(:,4)));
        
        if runrec
            indiv=indiv(1:totfaces);
            T=table(ident,locat(:,1),locat(:,2),indiv,'VariableNames',{'ImageFile','X','Y','Identity'}); % convert output to table
        else
            T=table(ident,locat(:,1),locat(:,2),'VariableNames',{'ImageFile','X','Y'}); % convert output to table
        end
        writetable(T,[savedir,'\Image_results.csv']) % save output table to CSV file
    end
    
    %% Process videos
    if novids>0
        vids=find(filetype==2);
        
        for noV=1:length(vids) % process videos one by one
            ident=cell(100000,1); % intitalise variables for output
            locat=zeros(100000,4);
            indiv=cell(100000,1);
            totfaces=0;
            
            
            wb=waitbar(0,['Processing Video ',num2str(noV),' of ',num2str(novids)],'CreateCancelBtn','setappdata(gcbf,''canceling'',1)');
            setappdata(wb,'canceling',0);
            video_input=VideoReader([imgfolder,'\',files{vids(noV)}]); % open video
            NOF=floor((video_input.Duration*video_input.FrameRate));
            video_input.CurrentTime=0;
            F=1;
            
            if runrec
                if recog_var.gosave % set up video save file if required
                    video_output=VideoWriter([savedir,'\',savename{vids(noV)},'_processed.mp4'],'MPEG-4');
                    video_output.FrameRate=video_input.FrameRate;
                    open(video_output);
                end
            end
            
            while F<NOF
                if getappdata(wb,'canceling')
                    break
                end
                waitbar(F/NOF)
                I=readFrame(video_input); % read in video frame
                
                if rem(F,frameint)==0
                    frameno=num2str(round(video_input.CurrentTime*video_input.FrameRate));
                    save_prefix=[savedir,'\',savename{vids(noV)},'_',frameno];
                    isvid=1;
                    process_frame % analyse frame
                end
                F=F+1; % increase position in video file by frame interval
            end
            if runrec
                if recog_var.gosave
                    close(video_output);
                end
            end
            ident=ident(1:totfaces); % process output
            locat=locat(1:totfaces,:);
            locat(:,1)=round(locat(:,1)+(0.5*locat(:,3)));
            locat(:,2)=round(locat(:,2)+(0.5*locat(:,4)));
            
            if runrec
                indiv=indiv(1:totfaces);
                T=table(ident,locat(:,1),locat(:,2),indiv,'VariableNames',{'FrameNumber','X','Y','Identity'});% convert output to table
            else
                T=table(ident,locat(:,1),locat(:,2),'VariableNames',{'FrameNumber','X','Y'});% convert output to table
            end
            writetable(T,[savedir,'\',savename{vids(noV)},'_video_results.csv']) % save output to CSV file
            
            delete(wb);
        end
    end

    h=msgbox(['Processed ', num2str(noI), ' image(s) and ', num2str(noV),' video(s)']); % output number of images and videos analysed
    uiwait(h);
    
end

    function []=process_frame
        
        NewI=I;
        
        facebox=step(detect_var.classifier.face,I);  % face detection on video frame
        nofaces=0;
        for n=1:size(facebox,1)
            % if at least one face detected isolate face from image,
            % resize to standard size and run additional feature
            % detection if required
            
            CropI=imcrop(I,facebox(n,:)); % Crop face from main image
            CropI=imresize(CropI,detect_var.outsz); % Resize face
            
            good=1;
            
            if detect_var.noclasses>1 % run if additional detectors required
                for m=2:detect_var.noclasses
                    bbox=step(detect_var.classifier.(detect_var.classes{m}),CropI); %detect feature
                    if isempty(bbox)
                        good=0;
                    end
                end
            end
            
            if good
                nofaces=nofaces+1;
                totfaces=totfaces+1;
                if isvid
                    ident{totfaces}=frameno;
                else
                    ident{totfaces}=files{img(noI)};
                end
                locat(totfaces,:)=facebox(n,:);
                
                if runrec
                    if strcmp(recog_var.model,'HOG')
                        vec=extractHOGFeatures(rgb2gray(CropI));
                    else
                        vec=extractLBPFeatures(rgb2gray(CropI),'CellSize',[10,10],'Radius',2,'NumNeighbors',8);
                    end
                    ID=predict(recog_var.obj,vec);
                    if recog_var.gosave
                        NewI = insertObjectAnnotation(NewI, 'rectangle', facebox(n,:),ID, 'Color','blue','LineWidth',4,'FontSize',18);
                    end
                    if iscell(ID)
                        indiv{totfaces}=ID{1};
                    else
                        indiv{totfaces}=ID;
                    end
                else
                    imwrite(CropI,[save_prefix,'_crop_',num2str(n),'.jpg']); % save cropped image
                    NewI=insertShape(NewI,'Rectangle',facebox(n,:),'Color','cyan','LineWidth',4); % outline face in original video frame
                end
            end
        end
        
        if runrec
            if recog_var.gosave
                if isvid
                    writeVideo(video_output,NewI)
                else
                    imwrite(NewI,[save_prefix,'_recognition.jpg']);
                end
            end
        else
            if nofaces>0 % if at least one face detected
                imwrite(NewI,[save_prefix,'_faces.jpg']); % save image or video frame as jpeg
            end
        end
    end
end