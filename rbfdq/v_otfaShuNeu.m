%variable-order time fractional advection-diffusion equation solver
%v_otfa_de special version for air pollution modeling
% special for alpha=1, old version for internal equation at right hand term
% wrong , 0^0=1, and 0^0.5=0
% this code has successfully been used in the accepted JCP paper
clear global
clc
%close all
fprintf('+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n');
fprintf('+   RBFDQ code for PDE, the copyright: Dr Jianming Liu        +\n');
fprintf('+           Jiangsu Normal University                         +\n');
fprintf('+            Email: jmliu@jsnu.edu.cn                         +\n');
fprintf('+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n');

hold off
% test mqrbf and meshfree grid treatment
%
global ppp meshden  pointboun typPoints domain racLow racHigh
global ttt  neumannBndryStr  filenmsu2 onlyNearestNeighbor 
%%%%%%pointboun: boundary node number

%%%global n_pointPoint pointsPoint

global n_pointPoint2 pointsPoint2 su2mesh filenmsu2Sol
global mapNormalNeumBndry pointNeumboun  vecVel

meshden=0.1; %0.16, 0.08

tic
examp=1; %different case
domain=44; %1 [0,1]*[0,1],2: unit circle . 33: star with 90 degree circle
            %44 any su2 grid
su2mesh = 1;
%filenmsu2='nonRegularDom3.su2';
%filenmsu2='nonRegularN6_3.su2';
%filenmsu2='part4star.su2';
%filenmsu2='circleu1esssUni2.su2'; 
%filenmsu2='circleu1esssUni2.su2'; 
%filenmsu2='circleF00Neu.su2'; 
filenmsu2='circleF02NeuN2.su2'; 
%filenmsu2='circleF02Dir2.su2'; 
%filenmsu2='b4MatlabDir.su2'; 
%必须注意如果不是污染的例子一定需要修改while循环的Dirchlet边界条件的计算部分
%filenmsu2Sol='flowVx1Vy0p5.plt';
neumannBndryStr='NeumannBndry';  % Neumann boundary condition in su2 mesh,
                                     % boundary mark should be NeumannBndry                

if domain==1
    racLow=[0,0]; % left down
    racHigh=[1,1];  % right up
end
boundType=1;      % 1 Dirichlet
boundTypeNeumB=2; % 2 Neumann

cellBool=0; % 1: cell 0: map
HRBFDQ=0; %0: rbf dq by Shu, 1: hermite RBFDQ

onlyNearestNeighbor=0;
c=5;

boundInEq=0; % 1 include boundary point Eq, 0 no
 

meshfreeTreat;
%loadsu2CFDsol;
%return;
thet=1.0;  % theta method

npoin=size(ppp,1);
%ppp=3+ppp;
zeroORnpoin=0; %% if boundary points are included in eqs least square method is used
                                             
NtimeStep=200;
Tend=1;
dlt=Tend/NtimeStep;
Tnow=0;

unum=zeros(npoin,NtimeStep+1);
Fnum=zeros(npoin,1);

switch examp
    case 1
        kapaFun=@(x,y,t) (1  );
        vecSp1=@(x,y,t) (1 );
        vecSp2=@(x,y,t) (1 );        
        vo_alpha=@(x,y,t) (0.8-0.1*cos(x.*t).* sin(x)-0.1*cos(y.*t).*sin(y));
     %  vo_alpha=@(x,y,t) (1.0);
        sourceF=@(x,y,t) (2*t.^(2-vo_alpha(x,y,t))./gamma(3-vo_alpha(x,y,t)) ...
            +2*x+2*y-4);
        uexact=@(x,y,t) (x.^2+y.^2+t.^2);
        dfx1=@(x,y,t) (2*x);
        dfy1=@(x,y,t) (2*y);   
    case 21
        kapaFun=@(x,y,t) (0.2 );
        vecSp1=@(x,y,t) (1 );
        vecSp2=@(x,y,t) (1 );        
   %      vo_alpha=@(x,y,t) (0.55+0.45*sin(x.*y.*t));
   
     %   vo_alpha=@(x,y,t) (0.85+0.15*sin(x.*y.*t));
    %   vo_alpha=@(x,y,t) (1.0);
        vo_alpha=@(x,y,t) (0.55);
        sourceF=@(x,y,t)  (x>=3-0.5&&x<=3-0.3&&y>=3-0.5&&y<=3-0.3)*5;
        uexact=@(x,y,t) (0);
        dfx1=@(x,y,t) (0);
        dfy1=@(x,y,t) (0); 
    case 31
        gsZd=0.05;
        kapaFun=@(x,y,t) (3+t.^2);
        vecSp1=@(x,y,t) (0.0 );
        vecSp2=@(x,y,t) (0.0 );  
        vo_alpha=@(x,y,t) (0.8-0.1*cos(x.*t).* sin(x)-0.1*cos(y.*t).*sin(y)); %0.5
        bt1=0.1;
        
        gaussF=@(x,y)  ( exp( (-(x-gsZd).^2 -(y-gsZd).^2)/bt1  )   );
        uexact=@(x,y,t)  ( t.^2 .*  gaussF(x,y) );
        dudx=@(x,y,t)  (   -2*(x-gsZd)/bt1 .*uexact(x,y,t)   );
        dudy=@(x,y,t)  (   -2*(y-gsZd)/bt1 .*uexact(x,y,t)   );
        d2udxx=@(x,y,t)  (  (-2 + 4*(x-gsZd).^2 /bt1 ) /bt1 .*uexact(x,y,t) );
        d2udyy=@(x,y,t)  (  (-2 + 4*(y-gsZd).^2 /bt1 ) /bt1 .*uexact(x,y,t) );
%        daudt=@(x,y,t)  (  2.0 ./gamma( 1-vo_alpha(x,y,t) ) ./ (1-vo_alpha(x,y,t)) ...
 %          ./ (2-vo_alpha(x,y,t)) ./(t.^(vo_alpha(x,y,t))) .* uexact(x,y,t) );
       daudt=@(x,y,t)  (  2.0 ./gamma( 3-vo_alpha(x,y,t) )  ...
           ./(t.^(vo_alpha(x,y,t))) .* uexact(x,y,t) );
       
        sourceF=@(x,y,t) ( daudt(x,y,t) - kapaFun(x,y,t).*(d2udxx(x,y,t)+d2udyy(x,y,t)) );
        dfx1=@(x,y,t) dudx(x,y,t);
        dfy1=@(x,y,t) dudy(x,y,t);
        
    otherwise
        warning('Unexpected example.');
        pause;
        return;
end

muFun=@(x,y,t,dlt) (dlt.^ vo_alpha(x,y,t).* gamma(2-vo_alpha(x,y,t)));
bb=@(x,y,t,jj) ((jj+1).^(1-vo_alpha(x,y,t))-jj.^(1-vo_alpha(x,y,t)));


typPoints(pointboun)=boundType; %%all boundary points: Neumann boundary points
typPoints(pointNeumboun)=boundTypeNeumB;

pxy=cell(npoin,1);
for ipoin=1:npoin
    for jk=1:n_pointPoint2(ipoin)
       pxy{ipoin}=[pxy{ipoin}; ppp(pointsPoint2(ipoin,jk),:)];
    end
end
% numbp=size(pointboun,1);
numbp=size(pointNeumboun,1);

nmlPboun=zeros(numbp,2); %normal direction over the boundary points
for ipb=1:numbp
   % nmlPboun(ipb,:)=ppp(pointboun(ipb),:); % only right for unit circle and origin is the center 
     nmlPboun(ipb,:)=mapNormalNeumBndry(pointNeumboun(ipb));
end

tmpCell=cell(npoin,3);   %tmpCell(0(1), [... num on boundary ],  [... mqrbfNb coefficents]
for ipoin=1:npoin
    tmpCell{ipoin,1}=0;
    tmpCell{ipoin,2}=[];
    tmpCell{ipoin,3}=[];
    if typPoints(ipoin)==2
        tmpCell{ipoin,1}=1;
        tmpCell{ipoin,2}=[tmpCell{ipoin,2}, ipoin];
    end
    
    for m=1:n_pointPoint2(ipoin)
        pnb =find(pointNeumboun==pointsPoint2(ipoin,m));
        if ~isempty(pnb)
            tmpCell{ipoin,1}=1;
            tmpCell{ipoin,2}=[tmpCell{ipoin,2},pointNeumboun(pnb)];   
        end
    end    
end

% rd2= mqrbfNB(pxy1,xy1,pxynb, pxynbnor, c);
% for ipoin=1:npoin
%    if tmpCell{ipoin,1}==1
%        
%    end
%     
% end

if cellBool==0
    rdernb=cell(numbp,1);
    rdernb1=cell(numbp,1);
    rdernb2=cell(numbp,1);
    if numbp > 0
    rdernbMap=containers.Map(pointNeumboun,rdernb);
    pxynbMap=containers.Map(pointNeumboun,rdernb1);
    pxynbnorMap=containers.Map(pointNeumboun,rdernb2);
    end
end

if cellBool==1
    rdernbMap=cell(npoin,1);
    pxynbMap=cell(npoin,1);
    pxynbnorMap=cell(npoin,1);
end
           

rder=cell(npoin,1);


for ipoin=1:npoin    
    pxy11=pxy{ipoin};
    xy=ppp(ipoin,:);
    rd=mqrbf(pxy11,xy,c);
    
    rder{ipoin}=[rder{ipoin}; rd];
    
    if  typPoints(ipoin)==2
        pnxy1=pointsPoint2(ipoin,1:n_pointPoint2(ipoin));
        pxy1=ppp(pnxy1',:);
        xy1=ppp(ipoin,:);
        pxynb=[];
        pxynbnor=[];
        pxynb=[pxynb; xy1];
        %nor=(xy1-0.0)/norm(xy1);
        %nor=xy1;
        nor=mapNormalNeumBndry(ipoin);
        pxynbnor=[pxynbnor; nor];
        nnbt=1;
        % only one Neumann boundary point then comment following for loop
        for m=1:n_pointPoint2(ipoin)
            pnb =find(pointNeumboun==pointsPoint2(ipoin,m));
            if ~isempty(pnb)
                pxynb=[pxynb; ppp(pointNeumboun(pnb),:)];
             %   xytm=ppp(pointboun(pnb),:); % here circle r =1
                xytm=mapNormalNeumBndry(pointNeumboun(pnb));
                pxynbnor=[pxynbnor;xytm];
                nnbt=nnbt+1;
            end
%             if nnbt >3
%                 break;
%             end
        end
        
        rd2= mqrbfNB(pxy1,xy1,pxynb, pxynbnor, c);
        if cellBool==0
            if isKey(rdernbMap,ipoin)
                rdernbMap(ipoin)=[rdernbMap(ipoin);rd2];
                pxynbMap(ipoin)=[pxynbMap(ipoin);pxynb];
                pxynbnorMap(ipoin)=[pxynbnorMap(ipoin);pxynbnor];
            else
                disp('Wrong rdernbMap');
                pause;
            end           
        end
        
        if cellBool==1
            rdernbMap{ipoin}=[rdernbMap{ipoin};rd2];
            pxynbMap{ipoin}=[pxynbMap{ipoin};pxynb];
            pxynbnorMap{ipoin}=[pxynbnorMap{ipoin};pxynbnor];
        end                
    end
    
end
fprintf('+             Done Pre treatment for MQRBF.                   +\n');

% for ipoin=1:npoin
%     att1=rder{ipoin};
%     rt=0.0;
%     for jk=1:n_pointPoint2(ipoin)
%        rt=rt+ att1(jk,2)*af(pointsPoint2(ipoin,jk));
%     end
%     rt=rt+att1(n_pointPoint2(ipoin)+1,2)*af(ipoin);
%     cadfy1(ipoin)=rt;
%     sumerr2=sumerr2+(rt-adfy1(ipoin))^2;
%     sumexact2=sumexact2+abs(adfy1(ipoin))^2;
% end
% c---- rder(:,1) coefficients for u_x, rder(:,2) for u_y,
% c---- rder(:,3) d^2u/dx^2  rder(:,4) d^2u/dy^2   rder(:,5) d^2u/dxdy


nStep=0;
%%initial data from time =0
% for ipoin=1:npoin
%     unum(ipoin,1)=uexact(ppp(ipoin,1), ppp(ipoin,2), 0);
% end
unum(:,1)=uexact(ppp(:,1), ppp(:,2), 0);

while Tnow<Tend
   acoe=zeros(npoin,npoin);
    %000sparse matrix treatment
%     IIsp=zeros(npoin*30,1);
%     JJsp=zeros(npoin*30,1);
%     Vsp=zeros(npoin*30,1);
%     kksp=1;
    %111sparse matrix treatment
    
    Fnum=zeros(npoin,1);
    Tnow=Tnow+dlt;
    nStep=nStep+1;
    %     if Tnow>Tend
    %         break
    %     end
    
 %   nBoundEq=0;
    
    for ipoin=1:npoin
        oneMthetSource=0.0;
        if typPoints(ipoin)==0
            att1=rder{ipoin};
            acoe(ipoin,ipoin)=1;
     %000sparse matrix treatment        
%             IIsp(kksp)=ipoin;
%             JJsp(kksp)=ipoin;
%             Vsp(kksp)=1;
%             kksp=kksp+1;
     %111sparse matrix treatment   
     % 
             vecx=vecSp1(ppp(ipoin,1),ppp(ipoin,2),Tnow);
             vecy=vecSp2(ppp(ipoin,1),ppp(ipoin,2),Tnow);
  %          vecx=vecVel(ipoin,1);
  %          vecy=vecVel(ipoin,2);

            for jk=1:n_pointPoint2(ipoin)
                nbpoin=pointsPoint2(ipoin,jk);
               
                rt=-(att1(jk,3)+att1(jk,4)) ...
                    *kapaFun(ppp(ipoin,1),ppp(ipoin,2),Tnow) ...
                    +(att1(jk,1)*vecx ...
                    +att1(jk,2)*vecy);
                acoe(ipoin,nbpoin)=acoe(ipoin,nbpoin) ...
                    +rt*thet*muFun(ppp(ipoin,1),ppp(ipoin,2),Tnow,dlt);
   %000sparse matrix treatment                
%                 IIsp(kksp)=ipoin; 
%                 JJsp(kksp)= nbpoin;
%                 Vsp(kksp)=rt*thet*muFun(ppp(ipoin,1),ppp(ipoin,2),Tnow,dlt);
%                 kksp=kksp+1;
   %111sparse matrix treatment             
                oneMthetSource =oneMthetSource + unum(nbpoin,nStep)* ...
                       ((att1(jk,3)+att1(jk,4)) ...
                       *kapaFun(ppp(ipoin,1),ppp(ipoin,2),Tnow) ...
                    -(att1(jk,1)*vecx ...
                    +att1(jk,2)*vecy));
            end
            
            
            % att1(n_pointPoint2(ipoin)+1,1)
            jk=n_pointPoint2(ipoin)+1;
            
            nbpoin=ipoin;
            rt=-(att1(jk,3)+att1(jk,4)) ...
                *kapaFun(ppp(ipoin,1),ppp(ipoin,2),Tnow) ...
                +(att1(jk,1)*vecx ...
                +att1(jk,2)*vecy);
            acoe(ipoin,nbpoin)=acoe(ipoin,nbpoin) ...
               +rt*thet*muFun(ppp(ipoin,1),ppp(ipoin,2),Tnow,dlt);

   %000sparse matrix treatment                
%                 IIsp(kksp)=ipoin; 
%                 JJsp(kksp)= nbpoin;
%                 Vsp(kksp)=rt*thet*muFun(ppp(ipoin,1),ppp(ipoin,2),Tnow,dlt);
%                 kksp=kksp+1;
   %111sparse matrix treatment              
            
            oneMthetSource= oneMthetSource + unum(nbpoin,nStep)* ...
                       ((att1(jk,3)+att1(jk,4)) ...
                      *kapaFun(ppp(ipoin,1),ppp(ipoin,2),Tnow) ...
                   -(att1(jk,1)*vecx ...
                    +att1(jk,2)*vecy));
                
            oneMthetSource =oneMthetSource *(1.0 - thet) ...
                   *muFun(ppp(ipoin,1),ppp(ipoin,2),Tnow,dlt);    
                
            tmpsum=0;
            %             %nStep == k+1
            %             for itp=1:nStep-2
            %                 tmpsum=tmpsum+(bb(ppp(ipoin,1),ppp(ipoin,2),Tnow,itp) ...
            %                     -bb(ppp(ipoin,1),ppp(ipoin,2),Tnow,itp+1))*unum(ipoin,nStep-1-itp+1);
            %             end
            %             % nStep-1 ?????
            %             Fnum(ipoin)=(1-bb(ppp(ipoin,1),ppp(ipoin,2),Tnow,1)) ...
            %                 *unum(ipoin,nStep-1+1)+ tmpsum+bb(ppp(ipoin,1),ppp(ipoin,2),Tnow,nStep) ...
            %                 *unum(ipoin,0+1)+muFun(ppp(ipoin,1),ppp(ipoin,2),Tnow) ...
            %                 *sourceF(ppp(ipoin,1),ppp(ipoin,2),Tnow);
            for itp=1:nStep-1
                tmpsum=tmpsum+bb(ppp(ipoin,1),ppp(ipoin,2),Tnow,itp) ...
                    *(unum(ipoin,nStep-1-itp+2)-unum(ipoin,nStep-1-itp+1));
            end

            Fnum(ipoin)=unum(ipoin,nStep-1+1)-tmpsum+ ...
                muFun(ppp(ipoin,1),ppp(ipoin,2),Tnow,dlt) ...
                *sourceF(ppp(ipoin,1),ppp(ipoin,2),Tnow) + oneMthetSource;

%             for itp=1:nStep-1
%                 tmpsum=tmpsum+(bb(ppp(ipoin,1),ppp(ipoin,2),Tnow,nStep-itp-1) ...
%                     -bb(ppp(ipoin,1),ppp(ipoin,2),Tnow,nStep-itp)) ...
%                     *unum(ipoin,itp+1);
%             end   
%             Fnum(ipoin)=bb(ppp(ipoin,1),ppp(ipoin,2),Tnow,nStep-1) ...
%                 * unum(ipoin,1)+tmpsum+muFun(ppp(ipoin,1),ppp(ipoin,2),Tnow,dlt) ...
%                  *sourceF(ppp(ipoin,1),ppp(ipoin,2),Tnow) + oneMthetSource;

        end
        
%         if  typPoints(ipoin)==2 && boundInEq==1
%             zeroORnpoin=npoin;          
%         end
        
        
        if  typPoints(ipoin)==1
            acoe(ipoin,ipoin)=1;
            
   %000sparse matrix treatment                
%                 IIsp(kksp)=ipoin; 
%                 JJsp(kksp)= ipoin;
%                 Vsp(kksp)=1.0;
%                 kksp=kksp+1;
   %111sparse matrix treatment  
   % for Dirichlet boundary
            Fnum(ipoin)=uexact(ppp(ipoin,1),ppp(ipoin,2),Tnow);
%           Fnum(ipoin)=0.0;
%           for ljm1=1:n_pointPoint2(ipoin)
%               nppp=pointsPoint2(ipoin,ljm1);
%               Fnum(ipoin)=Fnum(ipoin)+unum(nppp,nStep)/n_pointPoint2(ipoin);
%           end
        end
        %%%neumann boundary can only do for unit circle  
        if  typPoints(ipoin)==2
            if cellBool==0
                rd2=rdernbMap(ipoin);
                pxynb=pxynbMap(ipoin);
                pxynbnor=pxynbnorMap(ipoin);
            end
            
            if cellBool==1
                rd2=rdernbMap{ipoin};
                pxynb=pxynbMap{ipoin};
                pxynbnor=pxynbnorMap{ipoin};
            end
            
           % nor=ppp(ipoin,:);
            nor=mapNormalNeumBndry(ipoin);
    %        nBoundEq=nBoundEq+1;
            %zeroORnpoin
            if HRBFDQ==1
                % rt=0.0;
                for jk=1:n_pointPoint2(ipoin)
                    %rt=rt+(rd2(jk,1)*nor(1)+rd2(jk,2)*nor(2))*af(pointsPoint2(ipoin,jk));
%                     if boundInEq==1                   
%                         acoe(zeroORnpoin+nBoundEq,pointsPoint2(ipoin,jk))=rd2(jk,1)*nor(1)+rd2(jk,2)*nor(2);
%                     else     
                        acoe(ipoin,pointsPoint2(ipoin,jk))=rd2(jk,1)*nor(1)+rd2(jk,2)*nor(2);
%                     end
                end
                % xy1=ppp(ipoin,:);
                nd=n_pointPoint2(ipoin)+1;
%                 if boundInEq==1
%                     acoe(zeroORnpoin+nBoundEq,ipoin)=rd2(nd,1)*nor(1)+rd2(nd,2)*nor(2);
%                 else
                     acoe(ipoin,ipoin)=rd2(nd,1)*nor(1)+rd2(nd,2)*nor(2);
%                end
                % npnb=size(rd2,1)-nd;
                
                npnb=size(pxynb,1);
            
                rt=0;
                for jk=1:npnb
                    tm1=dfx1(pxynb(jk,1),pxynb(jk,2),Tnow)*pxynbnor(jk,1);
                    tm2=dfy1(pxynb(jk,1),pxynb(jk,2),Tnow)*pxynbnor(jk,2);
                    rt=rt+(rd2(jk+nd,1)*nor(1)+rd2(jk+nd,2)*nor(2))*(tm1+tm2);
                end
                xy1=ppp(ipoin,:);
                tm1= dfx1(xy1(1),xy1(2),Tnow)*nor(1)+dfy1(xy1(1),xy1(2),Tnow)*nor(2);
%                 if boundInEq==1
%                     Fnum(zeroORnpoin+nBoundEq)=tm1-rt;
%                 else
                    Fnum(ipoin)=tm1-rt;
%                 end
                
            end
            
            if HRBFDQ==0
                rd3=rder{ipoin};
                for jk=1:n_pointPoint2(ipoin)
                   acoe(ipoin,pointsPoint2(ipoin,jk))= ...
                        rd3(jk,1)*nor(1)+rd3(jk,2)*nor(2);
                    
     %000sparse matrix treatment                
%                 IIsp(kksp)=ipoin; 
%                 JJsp(kksp)= pointsPoint2(ipoin,jk);
%                 Vsp(kksp)=rd3(jk,1)*nor(1)+rd3(jk,2)*nor(2);
%                 kksp=kksp+1;
     %111sparse matrix treatment     
                end
                nd=n_pointPoint2(ipoin)+1;
                
                acoe(ipoin,ipoin)=rd3(nd,1)*nor(1)+rd3(nd,2)*nor(2);
                
      %000sparse matrix treatment                
%                 IIsp(kksp)=ipoin; 
%                 JJsp(kksp)= ipoin;
%                 Vsp(kksp)=rd3(nd,1)*nor(1)+rd3(nd,2)*nor(2);
%                 kksp=kksp+1;
     %111sparse matrix treatment 
                
                xy1=ppp(ipoin,:);
                tm1= dfx1(xy1(1),xy1(2),Tnow)*nor(1)+dfy1(xy1(1),xy1(2),Tnow)*nor(2);
                
                Fnum(ipoin)=tm1;
                
            end                                      
        end
    end
      %000sparse matrix treatment 
    %  acoe=sparse(IIsp(1:kksp-1),JJsp(1:kksp-1),Vsp(1:kksp-1),npoin,npoin);
      %111sparse matrix treatment 
    
   unum(:,nStep+1)=acoe\Fnum;
%     diagacoe=zeros(npoin,npoin);
%    for jjmm=1:npoin
%        diagacoe(jjmm,jjmm)=1/acoe(jjmm,jjmm);
%    end
 %    diagacoe=pinv(diag(diag(acoe)));
% % 
% %   % unum(:,nStep+1)=pcg(acoe,Fnum,1e-6,100,diagacoe);
% %  % unum(:,nStep+1)=pinv(acoe)*Fnum;
% %  %   unum(:,nStep+1)=GuassFull(acoe,Fnum);
  %    unum(:,nStep+1)=gmres(acoe,Fnum,npoin,1e-12,150,diagacoe);

end
 %000sparse 
% condAcoe=condest(acoe,2);  
 %111sparse
 condAcoe=cond(acoe,2);        
        
uerr=unum(:,NtimeStep+1)-uexact(ppp(:,1),ppp(:,2),Tend);  
lrmserr=sqrt(sum(uerr.^2)/npoin);
lwqerr=max(abs(uerr));
l2err=sqrt(sum(uerr.^2)/sum(uexact(ppp(:,1),ppp(:,2),Tend).^2));
fprintf('+                  Done Time iteration.                       +\n');
fprintf('+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n\n');

fprintf('                   '), toc,  fprintf('                     \n')
fprintf('+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n');
    


figure(2)
hold off

plot(ppp(:,1),ppp(:,2),'b.','MarkerSize',12);
hold on
plot(ppp(pointboun,1),ppp(pointboun,2),'b.','MarkerSize',10);
plot(ppp(pointNeumboun,1),ppp(pointNeumboun,2),'r*','MarkerSize',10);
xlabel('x'); ylabel('y');

if domain==1
    axis([racLow(1),racHigh(1),racLow(2),racHigh(2)])
end
if domain ==2 ||  domain ==33 
    axis equal
end
  axis equal
figure(3)
plot3(ppp(:,1),ppp(:,2), unum(:,NtimeStep+1), 'b.','MarkerSize',15);
xlabel('x'); ylabel('y');
zlabel('u^h({\bf x}, T)');
grid on

figure(4)
plot3(ppp(:,1),ppp(:,2), abs(uerr), 'b.','MarkerSize',15);
zlabel('Error');
xlabel('x'); ylabel('y');
grid on

% 
% fid11=fopen('yuntuYaphaConst0p55.plt','w');
% nem=size(ttt,1);
% fprintf(fid11, 'TITLE="u numerical solution"\n');
% fprintf(fid11, 'VARIABLES="x","y","u(t=%.2f)","u(t= %.2f)","u(t= %.2f)","u(t= %.2f)","error", "x-velocity","y-velocity", "magnitudeV" \n',Tend,Tend/2,Tend/4,Tend/8);
% fprintf(fid11, 'ZONE N=%d,E=%d, F=FEPOINT, ET=TRIANGLE\n',npoin,nem);
% for ij=1:npoin
%     fprintf(fid11,'%f   %f   %f   %f   %f   %f    %f    %f    %f     %f\n',....
%         ppp(ij,1),ppp(ij,2),unum(ij,NtimeStep+1),unum(ij,NtimeStep/2+1),unum(ij,NtimeStep/4+1),unum(ij,NtimeStep/8+1),uerr(ij),...
%         vecVel(ij,1), vecVel(ij,2), norm(vecVel(ij,:)));
% end
% 
% for ij=1:nem
%     fprintf(fid11,'%d  %d  %d\n', ttt(ij,1),ttt(ij,2),ttt(ij,3));
% end
%     
% fclose(fid11);

