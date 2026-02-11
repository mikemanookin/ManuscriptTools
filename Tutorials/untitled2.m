

calibration_dir = '/Users/michaelmanookin/Documents/GitRepos/Symphony2/calibration-resources/rigs/tiny_mea/';

led_names = {'red', 'green', 'blue'};
led_

ii = 2;
cal = importdata([calibration_dir,'lightcrafter_below_',led_names{ii},'_spectrum.txt']);




% Extract the wavelength and intensity data from the calibration structure
wavelength = cal(:, 1);
intensity = cal(:, 2);

