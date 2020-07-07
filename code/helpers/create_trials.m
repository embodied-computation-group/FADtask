function [trialvector, real_probability] = create_trials(probability_nasty, needed_trials)
%% function to return a trial vector of needed_trials length 
% with a given probability i.e., probability to have a nasty taste given
% a cue
% Micah Allen 2018
% Niia Nikolova 2020       
%       edited to fix bug in cases where number_nasty_trials & number_nice_trials 
%       both had rem .5, resulting in 1 trial less than desired

number_nasty_trials = needed_trials .* probability_nasty;
number_nice_trials = needed_trials .* (1-probability_nasty);

% NB. when number_nasty_trials & number_nice_trials both have rem .5, this
% gives needed_trials-1
% trialvector = [ones(1, floor(number_nasty_trials)), 2.*ones(1, floor(number_nice_trials))];

% Toss a coin, so that the 'nice' trials are rounded up half the time
coin = rand(1, 1)<.5;
if coin
    trialvector = [ones(1, floor(number_nasty_trials)), 2.*ones(1, ceil(number_nice_trials))];
else
    trialvector = [ones(1, ceil(number_nasty_trials)), 2.*ones(1, floor(number_nice_trials))];
end

real_probability = sum(trialvector==1)/numel(trialvector);


end
