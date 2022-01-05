module WordleSolver
    include("words.jl")

    export words, choose, constrain

    log2_safe(x) = x > 0 ? log2(x) : 0
    entropy(dist) = -sum(dist .* log2_safe.(dist))

    
    function sofar(corpus)
        is_known = [all(x[i] == corpus[1][i] for x in corpus) for i in 1:5]
        string([is_known[j] ? corpus[1][j] : '0' for j in 1:5]...)
    end

    function choose(corpus)
        if length(corpus) == 1
            return corpus[1]
        end
        word_so_far = sofar(corpus)
        has_char_in_pos = Dict()
        for i in 0:25
            char = 'a' + i
            for j in 1:5
                has_char_in_pos[char] = [sum(x[j] == char for x in corpus) for j in 1:5]
            end
        end

        best_word = ""
        best_diff_entropy = 0
        for word in corpus
            diff_entropy = 0
            seen_chars = Set()
            for (i, char) in enumerate(word)
                greens = has_char_in_pos[char][i]
                if greens == length(corpus)
                    continue
                end
                if !(char in seen_chars)
                    # a yellow check for a double letter isn't useful
                    # not strictly true, but good enough for now
                    mask = [ch != char for ch in word_so_far]
                    yellows = sum(has_char_in_pos[char][mask]) - greens
                    push!(seen_chars, char)
                else
                    yellows = 0
                end
                greys = max(length(corpus) - yellows - greens, 0) # hack
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
    function constrain(corpus, query, result)
        word_so_far = sofar(corpus)
        for (i, (char, res)) in enumerate(zip(query, result))
            if res == '0'
                mask = [ch != char for ch in word_so_far]
                corpus = filter(x -> !(char in collect(x)[mask]), corpus)
            elseif res == '1'
                corpus = filter(x -> occursin(char, x), corpus)
                corpus = filter(x -> x[i] != char, corpus)
            elseif res == '2'
                corpus = filter(x -> x[i] == char, corpus)
            end
        end
        corpus
    end
end