function [ sol, other] = own_ga(rapidSettings,func)
%OWN_GA computes the minimum of the objective function defined by the
%parameter identification problem gaSettings must contain the
%fields:
%       - nbCromosomes, number of chromosome (vectors of parameters) for
%       every iterations
%       - nbCroossOver1,2, number of crossover operations applied to the
%       chromosomes
%       - nbMutations, number of mutation operations applied to the
%       chromosomes
%       - nbReproduction, number of reproduction operations applied to the
%       chromosomes
%       - limit, number of iteration to the process of the Genetic
%       Algorithm
%       - fitnessStopRatio, minimal ration currentFitness/intial_Fitness,
%       if the ratio becomes lower than this real number, the algorithm
%       exits
%       - headSize1,2,3, number of chromosomes involved respectivelly in
%       the crossovers1/2 and mutations
%       - nbReinjection, number of random chromosomes that are kept alive
%       even if not performing well
%       - nRandMin, minimum of initial particles to be generated
%       randomly, restricts the number of particles to be set on a grid
%       regularly spaced out in the parameter space, see the function
%       GenerateOrganisedSwarm
%       - p0s, matrix whose rows are different initial guesses for the
%       vector of parameters
%       - saveHist, boolean allowing to store all the best fitness and
%       particles at every iterations (get's big very quickly)

% <Rapid Parameter Identification is a toolbox for automated parameter identification>
%
% Copyright 2015 Luigi Vanfretti, Achour Amazouz, Maxime Baudette, 
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

%% fetch parameters of the GA algorithm
gaSettings=rapidSettings.gaSettings;
saveHist=rapidSettings.experimentSettings.saveHist;
nbCromosomes = gaSettings.nbCromosomes;
nbCroossOver1 = gaSettings.nbCroossOver1;
nbCroossOver2 = gaSettings.nbCroossOver2;
nbMutations = gaSettings.nbMutations;
nbReproduction = gaSettings.nbReproduction;
nbReinjection = gaSettings.nbReinjection;
headSize1 = gaSettings.headSize1;
headSize2 = gaSettings.headSize2;
headSize3 = gaSettings.headSize3;
limit = rapidSettings.experimentSettings.maxIterations; % hundred iterations, chosen randomly, the terminal condition should be better
verbose=rapidSettings.experimentSettings.verbose;
T=ChromosomeArray(nbCromosomes+2*(nbCroossOver1+nbCroossOver2)+nbMutations);
% creating the cell through initialisation of chromosomes
% should also include a grid and an initial guess just like for pso
list = generateOrganisedSwarm(nbCromosomes, gaSettings.nRandMin,rapidSettings.experimentSettings.p_min,rapidSettings.experimentSettings.p_max,rapidSettings.experimentSettings.p_0);
for k=1:length(list)
    T.createChromosome(rapidSettings.experimentSettings.p_min,rapidSettings.experimentSettings.p_max,list{k});
end
for k=1:nbCromosomes-length(list)
    T.createChromosome(rapidSettings.experimentSettings.p_min,rapidSettings.experimentSettings.p_max,[]);
end

%% compute the fitness of every generated chromosome
for k = T.pointerToLastOldChromosome+1:T.pointerToNewChromosome-1
    % debug info display
    if verbose&&mod(k,10) == 0
        sprintf(strcat('iteration ',int2str(k),' in GA initialisation'));
    end
    fitness = func(T.ChromosomeList(k).p, rapidSettings);
    T.ChromosomeList(k).fitness = fitness;
end
T.pointerToLastOldChromosome=k;
T.sort('ascend');
best = T.ChromosomeList(1).fitness;
bestP = T.ChromosomeList(1).p;
target_fitness=best*gaSettings.fitnessStopRatio;
%% Body
for iteration=1:limit
    % debug info display
    if verbose&&mod(iteration,10) == 0
        sprintf(strcat('iteration ',int2str(iteration),' in GA body'));
    end
    T.doCrossOverType1(nbCroossOver1); % Check that this is correct wrt headSize1!!! Can be mistake in original code aswell
    for k=T.pointerToLastOldChromosome+1:T.pointerToNewChromosome-1
        T.ChromosomeList(k).fitness=func(T.ChromosomeList(k).p,rapidSettings);
    end
    T.pointerToLastOldChromosome=k;
    T.doCrossOverType2(nbCroossOver2); % Check that this is correct wrt headSize2!!! Can be mistake in original code aswell
    for k=T.pointerToLastOldChromosome+1:T.pointerToNewChromosome-1
        T.ChromosomeList(k).fitness=func(T.ChromosomeList(k).p,rapidSettings);
    end
    T.pointerToLastOldChromosome=k;
    T.mutateRandomChromosomes(nbCroossOver2, iteration, limit);% Check that this is correct wrt headSize3!!! Can be mistake in original code aswell
    for k=T.pointerToLastOldChromosome+1:T.pointerToNewChromosome-1
        T.ChromosomeList(k).fitness=func(T.ChromosomeList(k).p,rapidSettings);
    end
    T.pointerToLastOldChromosome=k;
    sort(T.ChromosomeList,'ascend');
    %% Evolution: who survives to this round
    T.survivalOfTheFittest(1+nbReinjection);
    disp(['i = ' num2str(iteration) '. Best parameters: ' num2str(bestP(1,:)) ' with fitness = ' num2str(best)])
    if saveHist
        best = [best;T.ChromosomeList(1).fitness];
        bestP = [bestP;T.ChromosomeList(1).p];
    else
        best = T.ChromosomeList(1).fitness;
        bestP = T.ChromosomeList(1).p;
    end
    if best <= target_fitness
        break;
    end 
end
sol = bestP;
other.fitness = best;
other.chromosome = T.ChromosomeList;
delete(T);
end


