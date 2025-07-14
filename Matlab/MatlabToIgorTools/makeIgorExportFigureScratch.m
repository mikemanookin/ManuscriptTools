figure; clf;
fig1=gca;
set(fig1,'XScale','linear','YScale','linear')
set(0, 'DefaultAxesFontSize', 12)
set(get(fig1,'XLabel'),'String','X axis')
set(get(fig1,'YLabel'),'String','Y axis')

xData = 1:100;
yData = randn(1,100);

%add a line object to the figure
line1 = line(xData,yData,'Parent',fig1);
%set line properties
set(line1,'LineStyle','-','Marker','o','Color','b','DisplayName','lineOne');

%or use this quick convenience function I use
addLineToAxis(xData,2.*yData,'lineTwo',fig1,'r','--','x')

makeAxisStruct(fig1,'fileName' ,'directoryName') %will save as 'fileName.h5'