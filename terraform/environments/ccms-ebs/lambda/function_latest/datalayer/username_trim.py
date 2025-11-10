def username_trim(username: str, maximum: int = 16) -> str:
    """Ensure length of dot-separated username is within required maximum.
    If too long, first remove characters perferentially from right-end of each name,
    starting from left-hand name but never reducing name to less than one character,
    e.g. if max is 8:
        a.bcdefgh becomes a.bcdefg
        ab.cdefgh becomes a.cdefgh
        abc.defgh becomes ab.defgh
    This can't work in some circumstances (e.g. many dots), so also apply slice to
    string after applying the reduction to ensure within maximum.
    """
    excess = len(username) - maximum
    if excess > 0:
        username = reduce_username_length(username, excess)
        username = username[:maximum]
    return username


def reduce_username_length(username: str, excess: int) -> str:
    names = username.split(".")
    for ni, name, in enumerate(names):
        if excess < 1:
            break
        reduction_potential = len(name) - 1
        if reduction_potential > 0:
            if excess <= reduction_potential:
                names[ni] = name[:-excess]
                break
            else:
                names[ni] = name[:-reduction_potential]
                excess -= reduction_potential
    return ".".join(names)
