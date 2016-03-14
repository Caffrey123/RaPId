function [sol, historic] = own_cfapso(rapidSettings,func)
%OWN_PSO Applies the particle swar optimisation function OWN_PSO and
%applies it to the parameter identification problem specified.
%   Takes as argument the settings struct in which the data to be matched
%   by the parameter estimation was integrated by the function rapid.m It
%   starts by generating nb_particle particles (value set in
%   settings.pso_options). The initial particles are partly randomlu chosen
%   and partly spans the parameter space, being regularly spaced out within
%   the bounds specified by p_min and p_max the objective function is
%   evaluated at every iterations, after each has been given a speed which
%   is determined by random parameters and influenced by the position of
%   the overall best solution found and the particle personal best position
%   The function returns the historic of all the best position and best
%   fitness at every iteration of the process and the swarm at final time
%   if required.
%
%   settings should include a struct field name pso_options containing:
%       - w: inertia weight - multiplier on the contribution of the last sample of the
%            particle's speed to it's next sample
%       - self_coeff: self-recognition coefficient - multiplier on the contribution of the distance to the
%           particle's personal best position to the next sample of
%           the speed
%       - social_coeff: social coefficient - multiplier on the contribution of the distance to the swarm's
%           overall best position to the next sample of the speed
%       - limit: number maximal of iterations in the speeds updates
%       - fitnessStopRatio: the algorithm stops if the best fitness reaches
%           initialFitness*fitnessStopRatio
%       - nb_particles: number of particles in the swarm
%       - nRandMin, minimum of initial particles to be generated
%       randomly, restricts the number of particles to be set on a grid
%       regularly spaced out in the parameter space, see function
%       generateOrganisedSwarm
%       - p0s, matrix whose rows are different initial guesses for the
%       vector of parameters
%       - saveHist, boolean allowing to store all the best fitness and
%       particles at every iterations (get's big very quickly)

%% <Rapid Parameter Identification is a toolbox for automated parameter identification>
%
% Copyright 2016-2015 Luigi Vanfretti, Achour Amazouz, Maxime Baudette, 
% Tetiana Bogodorova, Jan Lavenius, Tin Rabuzin, Giuseppe Laera, 
% Francisco Gomez-Lopez
% 
% The authors can be contacted by email: luigiv at kth dot se
% 
% This file is part of Rapid Parameter Identification ("RaPId") .
% 
% RaPId is free software: you can redistribute it and/or modify
% it under the terms of the GNU Lesser General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% RaPId is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU Lesser General Public License for more details.
% 
% You should have received a copy of the GNU Lesser General Public License
% along with RaPId.  If not, see <http://www.gnu.org/licenses/>.

%% initialize settings
wmin = rapidSettings.psoSettings.w_min;
wmax = rapidSettings.psoSettings.w_max;
self_coeff = rapidSettings.psoSettings.self_coeff;
social_coeff = rapidSettings.psoSettings.social_coeff;
limit = rapidSettings.experimentSettings.maxIterations;
nb_particles=rapidSettings.psoSettings.nb_particles;
verbose=rapidSettings.experimentSettings.verbose; % used to decide if displaying progress
debugging=0; % set to 1 for troubleshooting the code
if rapidSettings.experimentSettings.saveHist %pre-allocate for speed
    best_fitness_history = zeros(limit,1); % pre-allocate vector 
    best_parameters_history = zeros(limit,length(rapidSettings.experimentSettings.p_0)); % pre-allocate array
    improved_at_iterations=best_fitness_history; % pre-allocate vector 
end
if social_coeff+self_coeff <4 %the acceleration coefficients should be over 4 to guarantee stability
   self_coeff=1.55+rand;  %random number between 1.55 and 2.55
   social_coeff=4.1-self_coeff; %number between 1.55 and 2.55  
end
phi=social_coeff+self_coeff;    
constriction=2/abs(2-phi-sqrt(phi^2 - 4*phi));   %constriction factor 
%% Initalization of the swarm: give positions & fitness to all particles
list = generateOrganisedSwarm( nb_particles, rapidSettings.psoSettings.nRandMin,rapidSettings.experimentSettings.p_min,rapidSettings.experimentSettings.p_max,rapidSettings.experimentSettings.p_0);
swarm=ParticleArray(nb_particles);
list=[list; cell(nb_particles-length(list),1)];
for k = 1:nb_particles
    swarm.createParticle(rapidSettings.experimentSettings.p_min,rapidSettings.experimentSettings.p_max,list{k});
end
fitnesses = swarm.calculateFitnesses(@(x)(func(x,rapidSettings))); %calculate fitnesses
[global_best_fitness,global_best_pos,newbest]=swarm.updateGlobalBest();
best_parameters_history(1,:) = global_best_pos;
best_fitness_history(1,:) = global_best_fitness;
improved_at_iterations(1) = 1;
if verbose
    disp(['i = 0. Best parameters: ' num2str(global_best_pos) ' with fitness = ' num2str(global_best_fitness)])
end
% we should modify this to include the possibility of having a grid along
% with the randomly drawn particles

target_fitness=best_fitness_history(1)*rapidSettings.psoSettings.fitnessStopRatio;
%% Algorithm's main body
for iteration=1:limit 
    if debugging&&mod(iteration,10) == 0 % debug info display
        sprintf(strcat('iteration ',int2str(iteration),' in pso body'));
    end
    wt=wmax-((wmax-wmin)*iteration/limit);   % calculate new inertia
    swarm.updateCFASpeed(constriction,wt,self_coeff,social_coeff); % update the particles's speeds
    swarm.updatePositions(); % change the position
    fitnesses = swarm.calculateFitnesses(@(x)(func(x,rapidSettings))); %calculate fitnesses
    [global_best_fitness,global_best_pos,newbest]=swarm.updateGlobalBest();
    if newbest
        best_fitness_history(iteration) = global_best_fitness;
        if verbose
            disp(['i = ' num2str(iteration) '. Best parameters: ' num2str(global_best_pos) ' with fitness = ' num2str(global_best_fitness)])
        end
        if rapidSettings.experimentSettings.saveHist
            best_parameters_history(iteration,:) = global_best_pos;
            best_fitness_history(iteration)=global_best_fitness;
            improved_at_iterations(iteration) = iteration;
        else
            improved_at_iterations = iteration;
        end
    end

    if global_best_fitness <= target_fitness % speed update loop
        break;
    end
end  
%% Finish and return results
if ~rapidSettings.experimentSettings.saveHist
    best_fitness_history=global_best_fitness;
    best_parameters_history=global_best_pos;
end
sol = global_best_pos;
historic.best_H = best_fitness_history;
historic.bestP_H = best_parameters_history;
historic.improvement_at_iterations=improved_at_iterations;
historic.swarm = swarm;
end


