function [] = primatefaces_trainrec
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
gotrain=1;

imgdir=uigetdir('Please select directory containing images (images should be arranged as shown in user guide','Select directory');

if imgdir==0
    gotrain=0;
end

%% Ask user for location and name of file to save output to
if gotrain
    [savefname,savedir]=uiputfile({'*.mat'},'Save model as');
    if savefname==0
        gotrain=0;
    else
        i=find(savefname=='.');
        savefilename=[savedir,savefname(1:i-1)];
    end
end


%% read in training image set information
if gotrain
    trainingSet=imageSet(imgdir,'recursive');
    ids={trainingSet.Description};
    imgcount=[trainingSet.Count];
    
    if min(imgcount)<2
        warndlg('Minimum of two valid image files required per individual');
        gotrain=0;
    else
        useno=min(imgcount);
        if useno>100
            useno=100;
        end
        mb=msgbox(['Discovered ', num2str(length(ids)),' individuals, total of ', num2str(sum(imgcount)),' images with minimum of ',num2str(min(imgcount)),' images per individual. Using ',num2str(useno),' images per individual for training.']);
        uiwait(mb);
        
        choice=questdlg('Do you have a separate set of images for validation purposes (if not cross-validation will be used on the training images)','Training','Yes','No','Cancel','No');
        
        switch choice
            case 'Yes'
                imgdir=uigetdir('Please select directory containing images for validation'); % if using separate image set for validation - upload images here, program will use all images in folder for validation
                testSet=imageSet(imgdir,'recursive');
                docv=0;
            case 'No'
                docv=1;
            case 'Cancel'
                gotrain=0;
        end
    end
end

if gotrain
    recfig=figure('Name','Training Recognition Model','Menubar','none','Position',[0,0,400,500],'Units','Pixels','NumberTitle','off','Resize','off'); % create setup window
    movegui(recfig,'center')
    traintxt={'Training Recognition Model (may take some time)';'';'Processing Images'};
    rectxt=uicontrol('Parent', recfig, 'Position',[15,60,370,400],'Style','text','String',traintxt,'FontSize',10,'HorizontalAlignment','left');
    pause(1);
    
    [trainSet,~]=partition(trainingSet,useno,'randomized');
    
    if docv==1
        notr=sum([trainSet.Count]);
    else
        notr=sum([trainSet.Count])+sum([testSet.Count]);
    end
    
    no=0;
    
    face_size=zeros(notr,2);
    allfiles=cell(notr,1);
    allids=cell(notr,1);
    istrain=zeros(notr,1);
    
    for M=1:length(trainSet) % read in images for training
        for N=1:length(trainSet(M).ImageLocation)
            no=no+1;
            img_info=imfinfo(trainSet(M).ImageLocation{N});
            face_size(no,:)=[img_info.Height,img_info.Width];
            allids{no,1}=trainSet(M).Description;
            allfiles{no,1}=trainSet(M).ImageLocation{N};
            istrain(no)=1;
        end
    end
    face_size=face_size(1:no,:);
    
    if docv==0
        for M=1:length(testSet) % read in images for testing
            for N=1:length(testSet(M).ImageLocation)
                no=no+1;
                allids{no,1}=testSet(M).Description;
                allfiles{no,1}=testSet(M).ImageLocation{N};
                istrain(no)=0;
            end
        end
    end
    
    rectxt.String={'Training Recognition Model (may take some time)';'';'Extracting Features from Images'};
    pause(1);
    face_size=round(mean(face_size));
    for N=1:no
        I=imread(allfiles{N,1}); % read in image
        if ndims(I)>2 %#ok<ISMAT>
            I=rgb2gray(I); % convert to grayscale if required
        end
        I=imresize(I,face_size); % resize images to standard size
        if N==1
            hog=extractHOGFeatures(I); % extract histogram of gradients features
            lbp=extractLBPFeatures(I,'CellSize',[10,10],'Radius',2,'NumNeighbors',8);% extract local binary pattern features using 8 neighbours and radius 2
            all_hog=zeros(no,length(hog)); % initialize array for hog features
            all_lbp=zeros(no,length(lbp)); % initialize array for lbp features
            all_hog(N,:)=hog;
            all_lbp(N,:)=lbp;
        else
            all_hog(N,:)=extractHOGFeatures(I); % extract histogram of gradients features
            all_lbp(N,:)=extractLBPFeatures(I,'CellSize',[10,10],'Radius',2,'NumNeighbors',8); % extract local binary pattern features using 8 neighbours and radius 2
        end
    end
    
    istrain=istrain(1:no);
    
    
    rectxt.String={'Training Recognition Model (may take some time)';'';'Training Models'};
    pause(1);
    obj{1}=fitcecoc(all_hog(istrain==1,:),allids(istrain==1),'Coding','onevsall'); % train a model using histogram of gradients features
    obj{2}=fitcecoc(all_lbp(istrain==1,:),allids(istrain==1),'Coding','onevsall'); % train a model using local binary pattern features
    
    accuracy=zeros(1,2);
    CM=zeros(length(ids),length(ids),2);
    
    if docv
        % cross validate histogram of gradients model
        rectxt.String={'Training Recognition Model (may take some time)';'';'Running Cross-Validation'};
        pause(1);
        part_Model=crossval(obj{1},'KFold',4);
        accuracy(1)=(1-kfoldLoss(part_Model,'LossFun','ClassifError'))*100;
        [valid_pred,~]=kfoldPredict(part_Model);
        CM(:,:,1)=confusionmat(allids(istrain==1),valid_pred,'order',ids);
        
        % cross validate local binary patterns model
        part_Model=crossval(obj{2},'KFold',4);
        accuracy(2)=(1-kfoldLoss(part_Model,'LossFun','ClassifError'))*100;
        [valid_pred,~]=kfoldPredict(part_Model);
        CM(:,:,2)=confusionmat(allids(istrain==1),valid_pred,'order',ids);
        
        if ~isempty(strfind(lastwarn,'One or more folds'))
            warndlg('Issues with cross-validation due to small numbers of images per class. Reported accuracy may be invalid')
        end
    else
        rectxt.String={'Training Recognition Model (may take some time)';'';'Running Validation'};
        pause(1);
        % validate histogram of gradients model using second image set
        valid_pred=predict(obj{1},all_hog(istrain==0,:));
        accuracy(1)=sum(strcmp(valid_pred,allids(istrain==0)))./length(istrain==0)*100;
        CM(:,:,1)=confusionmat(allids(istrain==0),valid_pred,'order',ids);
        
        % validate local binary patterns model using second image set
        valid_pred=predict(obj{2},all_lbp(istrain==0,:));
        accuracy(2)=sum(strcmp(valid_pred,allids(istrain==0)))./length(istrain==0)*100;
        CM(:,:,2)=confusionmat(allids(istrain==0),valid_pred,'order',ids);
    end
    
    % choose most accurate model
    [~,i]=max(accuracy);
    if i==1
        model='HOG';
    else
        model='LBP';
    end
    
    chancelevel=100/length(ids);
    rectxt.String={'Face Recognition Model';'';...
        ['Histogram of Gradients (HOG) Model:', num2str(accuracy(1),'%.1f'),' % Accuracy'];'';...
        ['Local Binary Pattern (LBP) Model:', num2str(accuracy(2),'%.1f'),'% Accuracy'];'';...
        ['Chance Level:', num2str(chancelevel,'%.1f'),' %'];'';...
        ['Using ',model,' Model'];'';...
        ['Model saved as ', savefilename, '.mat'];'';...
        ['Confusion Matrix saved as: ', savefilename,'_confusion_matrix.csv']};
    pause(1);
    
    
    
    accuracy=accuracy(i);
    CM=CM(:,:,i);
    [p,q]=size(CM);
    CM2=zeros(p+1,q+1);
    obj=obj{i};
    
    CM_out=cell(length(ids)+1,length(ids)+1);
    CM_out(2:end,1)=ids;
    CM_out(1,2:end)=ids;
    CM_out(2:end,2:end)=num2cell(CM);
    CM_out=array2table(CM_out);
    writetable(CM_out,[savefilename,'_confusion_matrix.csv'],'WriteVariableNames',false)
    
    save([savefilename,'.mat'],'obj','CM','accuracy','model','face_size');
    
    
    
    uicontrol('Parent',recfig,'Position',[250,5,100,50],'Style','pushbutton','String','OK','Callback',@finish_train,'BackgroundColor',[0.7,0.7,0.7])
    uiwait(recfig)
    
end

    function finish_train(~,~,~)
        close(recfig)
    end
end









