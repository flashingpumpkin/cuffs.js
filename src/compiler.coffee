define ['./ns'], (Cuffs) ->
    STOP_DESCENT = 'stop-descent-+"*' # Random string, easier equality comparison

    walk = (tree, callback)->
        # Walk a DOM tree depth first and call a callback on
        # each node. Escape current descent if the callback returns
        # STOP_DESCENT and continue with next sibling.

        recurse = (current, depth = 1)->
            stopDescent = callback current, depth

            if stopDescent != STOP_DESCENT and current.firstChild?
                recurse current.firstChild, depth + 1

            return if not current.nextSibling?
            return recurse current.nextSibling, depth
        return recurse tree.firstChild if tree.firstChild?

    return Cuffs.Compiler = {
        STOP_DESCENT: STOP_DESCENT
        walk: walk
    }
