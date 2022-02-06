using WordleSolver

use("wordle")

const wordlength = 5

function choose_adv(corpus)
    if length(corpus) == 1
        return corpus[1]
    end
    is_known = [all(x[i] == corpus[1][i] for x in corpus) for i in 1:wordlength]
    query_so_far = string([is_known[j] ? '2' : '0' for j in 1:wordlength]...)
    n = length(corpus)
    println(n)
    best_word = ""
    for word in possibles.words
        subcorpus = constrain(corpus, word, query_so_far)
        if (length(subcorpus) < n) && (length(subcorpus) > 0)
            println(word)
            best_word = word
            n = length(subcorpus)
        end
    end
    best_word
end

function play_adv()
    # WIP
    i = 1
    corpus = copy(possibles.answers)
    while (length(corpus) > 1)
        query = choose_adv(corpus)
        println(query)
        i += 1
        corpus = constrain(corpus, query, readline())
    end
    if (length(corpus) == 1)
        println(choose_adv(corpus))
    end
end