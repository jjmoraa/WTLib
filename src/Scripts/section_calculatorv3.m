function [ area ] = section_calculatorv3( points, thickness, sparnum, xspar, yspar,leindex)
    [innermids, sparpoints]=innergeometry(points,thickness,sparnum,xspar,yspar,leindex);

    %properties of outer ccontour
    [ geomout, inerout, cpmoout ] = polygeom( points(:,1), points(:,2) );
    %prperties of inner contour
    [ geomin, inerin, cpmoin ] = polygeom( innermids(:,1), innermids(:,2) );
    %properties of spars
    for i=1:sparnum
        fieldname=sprintf('field%d',i);
        spar=sparpoints.(fieldname);
        [ geospar(i), inerspar(i), cpmospar(i) ] = polygeom( innermids(:,1), innermids(:,2) );
    end

    area=5;
end
function [innermids, sparpoints]=innergeometry(points,thickness,sparnum,x,y,leindex)

    %This generates the normal and tangent vectors to the surface of the
    %airfoil
    for i=1:(length(points)-1)
        midpoints(i,:)=(points(i+1,:)+points(i,:))/2;
        tanVect(i,:)=points(i+1,:)-points(i,:);
        normVect(i,:)=[tanVect(i,2),-tanVect(i,1)];
    end
        midpoints(i+1,:)=midpoints(1,:);
        tanVect(i+1,:)=tanVect(1,:);
        normVect(i+1,:)=normVect(1,:);
    
    
    %This estimates inner empty part of section
    innermids=midpoints-tanVect*thickness;
    
    %This collects the spar cap points
    uppersurf=points(1:leindex,:);
    lowersurf=points(leindex:end,:);
    sparpoints=cell(1,sparnum);
    for j=1:sparnum
        pointholder=zeros(size(points));
        for i=1:leindex
            check=and(points);
            if check
                pointholder(i,:)=points(i,:);
            end
            fprintf('pass %i check %i\n',i,check)
        end
        sparpoints(j)=pointholder;
    end

end

function [ geom, iner, cpmo ] = polygeom( x, y ) 
%POLYGEOM Geometry of a planar polygon
%
%   POLYGEOM( X, Y ) returns area, X centroid,
%   Y centroid and perimeter for the planar polygon
%   specified by vertices in vectors X and Y.
%
%   [ GEOM, INER, CPMO ] = POLYGEOM( X, Y ) returns
%   area, centroid, perimeter and area moments of 
%   inertia for the polygon.
%   GEOM = [ area   X_cen  Y_cen  perimeter ]
%   INER = [ Ixx    Iyy    Ixy    Iuu    Ivv    Iuv ]
%     u,v are centroidal axes parallel to x,y axes.
%   CPMO = [ I1     ang1   I2     ang2   J ]
%     I1,I2 are centroidal principal moments about axes
%         at angles ang1,ang2.
%     ang1 and ang2 are in radians.
%     J is centroidal polar moment.  J = I1 + I2 = Iuu + Ivv
 
% H.J. Sommer III - 16.12.09 - tested under MATLAB v9.0
%
% sample data
% x = [ 2.000  0.500  4.830  6.330 ]';
% y = [ 4.000  6.598  9.098  6.500 ]';
% 3x5 test rectangle with long axis at 30 degrees
% area=15, x_cen=3.415, y_cen=6.549, perimeter=16
% Ixx=659.561, Iyy=201.173, Ixy=344.117
% Iuu=16.249, Ivv=26.247, Iuv=8.660
% I1=11.249, ang1=30deg, I2=31.247, ang2=120deg, J=42.496
%
% H.J. Sommer III, Ph.D., Professor of Mechanical Engineering, 337 Leonhard Bldg
% The Pennsylvania State University, University Park, PA  16802
% (814)863-8997  FAX (814)865-9693  hjs1-at-psu.edu  www.mne.psu.edu/sommer/
 
% begin function POLYGEOM
 
% check if inputs are same size
if ~isequal( size(x), size(y) ),
  error( 'X and Y must be the same size');
end
 
% temporarily shift data to mean of vertices for improved accuracy
xm = mean(x);
ym = mean(y);
x = x - xm;
y = y - ym;
  
% summations for CCW boundary
xp = x( [2:end 1] );
yp = y( [2:end 1] );
a = x.*yp - xp.*y;
 
A = sum( a ) /2;
xc = sum( (x+xp).*a  ) /6/A;
yc = sum( (y+yp).*a  ) /6/A;
Ixx = sum( (y.*y +y.*yp + yp.*yp).*a  ) /12;
Iyy = sum( (x.*x +x.*xp + xp.*xp).*a  ) /12;
Ixy = sum( (x.*yp +2*x.*y +2*xp.*yp + xp.*y).*a  ) /24;
 
dx = xp - x;
dy = yp - y;
P = sum( sqrt( dx.*dx +dy.*dy ) );
 
% check for CCW versus CW boundary
if A < 0,
  A = -A;
  Ixx = -Ixx;
  Iyy = -Iyy;
  Ixy = -Ixy;
end
 
% centroidal moments
Iuu = Ixx - A*yc*yc;
Ivv = Iyy - A*xc*xc;
Iuv = Ixy - A*xc*yc;
J = Iuu + Ivv;
 
% replace mean of vertices
x_cen = xc + xm;
y_cen = yc + ym;
Ixx = Iuu + A*y_cen*y_cen;
Iyy = Ivv + A*x_cen*x_cen;
Ixy = Iuv + A*x_cen*y_cen;
 
% principal moments and orientation
I = [ Iuu  -Iuv ;
     -Iuv   Ivv ];
[ eig_vec, eig_val ] = eig(I);
I1 = eig_val(1,1);
I2 = eig_val(2,2);
ang1 = atan2( eig_vec(2,1), eig_vec(1,1) );
ang2 = atan2( eig_vec(2,2), eig_vec(1,2) );
 
% return values
geom = [ A  x_cen  y_cen  P ];
iner = [ Ixx  Iyy  Ixy  Iuu  Ivv  Iuv ];
cpmo = [ I1  ang1  I2  ang2  J ];
 
% bottom of polygeom
end