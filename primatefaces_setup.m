% primatefaces_setup Set up parameters for running face detection or
% face detection and recognition. Program called by primatefaces_main.
%
% 1) Face Detection:
% User is given choice of creating a new setup or loading an existing one.
% If creating a new setup user is asked for the name of the face detection
% model (an xml file), the threshold for face detection (betweeen 1 and 24
% where 1 is low) and the minimum size face that should be detected. They
% will then be asked whether they want to load additional feature
% detectors.
%
% 2) Additional Feature Detectors
%
%
% 3) Face Recognition
% User is asked to select the face recognition model file (.mat extension)
% and what output they prefer. Basic output are text files listing the
% location and identity of each face detected (for video files this will
% also include the frame number). Additional option to save the
% processed images/videos. Each image or video frame in these processed
% files will show any detected faces along with the identity.



function [] = primatefaces_setup(flag)

godetection=0;
choice=questdlg('Do you want to create a new detection setup or load an existing one?','Setup','Create New','Load Existing','Create New');

if ~isempty(choice)
    godetection=1;
    switch choice
        case 'Create New'
            [xmlfile,xmlfold]=uigetfile({'.xml'},'Select face detection model'); % load detection model
            if xmlfile~=0
                fh=fopen([xmlfold,'\',xmlfile],'r');
                if fh~=-1
                    isdone=0;
                    while isdone<2
                        a=fgetl(fh);
                        i=find(a=='<');
                        j=find(a=='>');
                        if ~isempty(i)&&~isempty(j)
                            a2=a(i(1)+1:j(1)-1);
                            if strcmp(a2,'height')
                                detect_var.size(1)=str2double(a(j(1)+1:i(2)-1)); % check size of detection model
                                isdone=isdone+1;
                            elseif strcmp(a2,'width')
                                detect_var.size(2)=str2double(a(j(1)+1:i(2)-1)); % check size of detection model
                                isdone=isdone+1;
                            end
                        end
                    end
                    
                    fclose(fh);
                    
                    thresh = inputdlg('Set threshold for face detection (value between 1 and 24)','Threshold'); % get threshold for face detection
                    if isempty(thresh)
                        detect_var.threshold=8;
                    else
                        detect_var.threshold=round(str2double(thresh)); % set threshold for face detection
                        if isnan(detect_var.threshold)
                            detect_var.threshold=8;
                        end
                        if detect_var.threshold<1
                            detect_var.threshold=1;
                        elseif detect_var.threshold>24
                            detect_var.threshold=24;
                        end
                    end
                    minsz = inputdlg('Set minimum face size for detection','Minimum Size'); % get minimum size for detection
                    if isempty(minsz)
                        detect_var.minsz=detect_var.size;
                    else
                        minsz=round(str2double(minsz));
                        if isnan(detect_var.threshold)
                            detect_var.minsz=detect_var.size;
                        else
                            if minsz<max(detect_var.size)
                                detect_var.minsz=detect_var.size;
                            else
                                [~,i]=max(detect_var.size);
                                detect_var.minsz(i)=minsz;
                                j=setdiff(1:2,i);
                                detect_var.minsz(j)=round((minsz./detect_var.size(i)).*detect_var.size(j));
                            end
                        end
                    end
                    try
                        detect_var.classifier.face = vision.CascadeObjectDetector([xmlfold,'\',xmlfile],'MergeThreshold',detect_var.threshold,'MinSize',detect_var.minsz);% create cascade object detector with chosen settings
                    catch
                        warndlg('Unable to load face detector')
                        godetection=0;
                    end
                else
                    detect_var.classifier.face='';
                end
                
                detect_var.classes{1}='face';
                detect_var.noclasses=1;
                
                %% load additional detectors
                if godetection
                    button=questdlg('Do you want to load additional feature detectors (e.g. eyes)?');
                    switch button
                        case 'Yes', addclassifiers;
                        case 'Cancel',release(detect_var.classifier.face);
                    end
                    
                    
                    p=detect_var.size(1);
                    q=detect_var.size(2);
                    ratio=100./max([p,q]);
                    detect_var.outsz=round([p,q].*ratio);
                    
                    [detfile,detfold]=uiputfile({'.mat'},'Save setup file as');
                    if detfile~=0
                        save([detfold,'\',detfile],'detect_var'); % save setup file
                    end
                end
            else
                godetection=0;
            end
            
            
        case 'Load Existing'
            %% load existing setup file
            [detfile,detfold]=uigetfile({'.mat'},'Load face detection setup');
            if detfile~=0
                goodfile=1;
                try
                    A=load([detfold,'\',detfile]);
                catch
                    warndlg('Invalid file')
                    goodfile=0;
                end
                if goodfile
                    detect_var=A.detect_var;
                    godetection=1;
                end
            end
    end
end

if flag==1 % face detection only
    if godetection
        primatefaces_process(detect_var)
    end
else % face dectection and recognition
    if godetection
        [recfile,recfold]=uigetfile({'.mat'},'Select face recognition model'); % load face recognition model
        if recfile~=0
            A=load([recfold,'\',recfile]);
            try
                recog_var.model=A.model;
            catch
                warndlg('Invalid Recognition Model')
                godetection=0;
            end
            recog_var.obj=A.obj;
            recog_var.face_size=A.face_size; % set model parameters
        else
            godetection=0;
        end
    end
    
    if godetection
        choice=questdlg('Do you want to save output as video/images (in addition to CSV file)?','Save Output','Yes','No','Yes'); % allow user to choose if they want to save output as image/video files (in addition to text file)
        if strcmp(choice,'Yes')
            recog_var.gosave=1;
        else
            recog_var.gosave=0;
        end
        primatefaces_process(detect_var,recog_var)
    end
end

%% add additional feature detectors function
    function addclassifiers
        goadd=1;
        while goadd
            startclass
        end
        function startclass
            [xmlfile,xmlfold]=uigetfile({'.xml'},'Select additional feature detection model'); % load additional detection model
            if xmlfile~=0
                addclass=1;
                detname = inputdlg('Enter name of detector (no spaces)');
                if ~isempty(detname)
                    detname = matlab.lang.makeValidName(detname{1});
                else
                    detname = matlab.lang.makeValidName('');
                end
                
                thresh = inputdlg(['Set threshold for ',detname,' detection (value between 1 and 5)'],'Threshold'); % get threshold for face detection
                    if isempty(thresh)
                        thresh=1;
                    else
                        thresh=round(str2double(thresh)); % set threshold for face detection
                        if isnan(thresh)
                            thresh=1;
                        end
                        if thresh<1
                            thresh=1;
                        elseif thresh>5
                            thresh=5;
                        end
                    end
                try
                    detect_var.classifier.(detname) = vision.CascadeObjectDetector([xmlfold,'\',xmlfile],'MergeThreshold',thresh);
                catch
                    warndlg('Unable to load detector')
                    addclass=0;
                end
                
                if addclass
                    detect_var.noclasses=detect_var.noclasses+1;
                    detect_var.classes{detect_var.noclasses}=detname;
                end
            end
            
            choice=questdlg('Do you want to add another feature detector?','','Yes','No','No');
            if strcmp(choice,'No')
                goadd=0;
            end
        end
    end

end