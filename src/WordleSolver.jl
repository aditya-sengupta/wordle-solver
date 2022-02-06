module WordleSolver
    import StatsBase: countmap
    import LinearAlgebra: ⋅

    struct PossibleWords
        words::Vector{String}
        answers::Vector{String}
    end

    include("wordle.jl")
    include("wordmaster.jl")

    possibles = wordle

    function use(name)
        global possibles = eval(Symbol(name))
    end

    const wordlength = 5

    export choose, constrain, play, guess, use, possibles

    log2_safe(x) = x > 0 ? log2(x) : 0
    entropy(dist) = -sum(dist .* log2_safe.(dist))

    """
    Takes in the guessed word and the actual answer, and returns the Wordle match between them:
    0 for grey (letter i in the query isn't in answer)
    1 for yellow (letter i in the query is in the answer, in some position other than i)
    2 for green (letter i in the query is letter i in the answer)
    """
    function guess(query, answer)
        letters = countmap(answer)
    
        result = ['0' for _ in 1:wordlength]
        for i = 1:wordlength
            if answer[i] == query[i]
                result[i] = '2'
                letters[query[i]] -= 1
            end
        end

        for i = 1:wordlength
            if occursin(query[i], answer) && (result[i] != '2') && (letters[query[i]] > 0)
                result[i] = '1'
                letters[query[i]] -= 1
            end
        end
        string(result...)
    end

    """
    Maximises (a slight approximation to) the differential entropy of the guesses over the corpus.
    Takes in the corpus (a vector of Strings),
    and returns the element of possibles.words that provides the best split across it.
    """
    function choose(corpus)
        if length(corpus) <= 2
            return corpus[1]
        end
        is_known = [all(x[i] == corpus[1][i] for x in corpus) for i in 1:wordlength]
        word_so_far = string([is_known[j] ? corpus[1][j] : '0' for j in 1:wordlength]...)
        has_char_in_pos = Dict()
        for i in 0:25
            char = 'a' + i
            for j in 1:wordlength
                has_char_in_pos[char] = [sum(x[j] == char for x in corpus) for j in 1:wordlength]
            end
        end

        best_word = ""
        best_diff_entropy = 0
        for word in possibles.words
            diff_entropy = 0
            seen_chars = Set()
            for (i, char) in enumerate(word)
                greens = has_char_in_pos[char][i]
                if !(char in seen_chars)
                    # a yellow check for a double letter isn't useful
                    # not strictly true, but good enough for now
                    mask = [ch != char for ch in word_so_far]
                    yellows = sum(has_char_in_pos[char][mask]) - greens
                    push!(seen_chars, char)
                else
                    yellows = 0
                end
                greys = length(corpus) - yellows - greens
                dist = [greens, yellows, greys]
                dist = dist ./ sum(dist)
                diff_entropy += entropy(dist)
            end
            if diff_entropy > best_diff_entropy
                best_diff_entropy = diff_entropy
                best_word = word
            end
        end
        best_word
    end

    """
    Takes in the corpus, the guessed word, and the result in the form of a length-5 string: 0 for grey, 1 for yellow, 2 for green.
    Returns the corpus filtered for only the words that satisfy that query.
    """
    constrain(corpus, query, result) = filter(w -> guess(query, w) == result, corpus)
    
    function play()
        i = 1
        corpus = copy(possibles.answers)
        while (length(corpus) > 1) && (i <= 6)
            query = choose(corpus)
            println(query)
            i += 1
            corpus = constrain(corpus, query, readline())
        end
        if (length(corpus) == 1)
            println(choose(corpus))
        end
    end

    function play(answer; verbose=true)
        i = 1
        corpus = copy(possibles.answers)
        query = ""
        while (length(corpus) > 1) && (i <= 6)
            query = choose(corpus)
            if verbose
                println(query)
            end
            i += 1
            corpus = constrain(corpus, query, guess(query, answer))
        end
        if length(corpus) == 1
            if query == corpus[1]
                i -= 1
            elseif verbose
                println(corpus[1])
            end
        end
        i
    end
end