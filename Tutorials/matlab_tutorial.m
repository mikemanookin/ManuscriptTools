
out_dir = '~/Documents/Tutorials/';

num_cells = 12;
num_contrasts = 6;
contrasts = linspace(0,1,num_contrasts);

scatter_data = rand(num_cells, num_contrasts);

figure(100); clf;
hold on
line(contrasts, mean(scatter_data,1), 'DisplayName', 'dataM', 'Color', 'k', 'LineStyle', '-', 'Marker', 'o', 'LineWidth', 2);
line(contrasts, std(scatter_data,[],1), 'DisplayName', 'dataE', 'Color', 'k', 'LineStyle', '-', 'Marker', 'o', 'LineWidth', 2);
hold off;
xlabel('contrast'); ylabel('spikes/s');
makeAxisStruct(gca, 'TestCRF', 'basedir', out_dir);

% subplot(222)
% hold on
% for jj = 1 : 12
%     line(t, avgCycle(jj,:), 'DisplayName', ['data',num2str(uRad(jj))], 'Color', 'k', 'LineStyle', '-', 'Marker', 'none', 'LineWidth', 2);
% end
% line(t(onSamp([1,1,2,2,1])), [0,1,1,0,0]*max(avgCycle(:)), 'DisplayName', 'on', 'Color', 'k', 'LineStyle', '-', 'Marker', 'none', 'LineWidth', 2);
% line(t(offSamp([1,1,2,2,1])), [0,1,1,0,0]*max(avgCycle(:)), 'DisplayName', 'off', 'Color', 'k', 'LineStyle', '-', 'Marker', 'none', 'LineWidth', 2);
% hold off;
% xlabel('time (s)'); ylabel('pA');
% if outputIgor
%     makeAxisStruct(gca, 'BroadThornyCycle', 'basedir', out_dir);
% end
