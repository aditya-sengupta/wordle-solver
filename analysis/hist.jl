using WordleSolver
using ProgressMeter

guess_numbers = zeros(Int, length(possibles.answers))

# you should be able to rewrite this loop to not do N traversals
# but that would take longer than the one time it'd take to run it
@showprogress for i in 1:length(possibles.answers)
    guess_numbers[i] = play(possibles.answers[i]; verbose=false)
end

histogram(guess_numbers; bins=[2,3,4,5,6,7].-0.5, ylabel="Count", xlabel="Number of guesses", label="")