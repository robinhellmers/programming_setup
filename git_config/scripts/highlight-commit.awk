#!/usr/bin/nawk -f

BEGIN {
    n = split(commits,arrayCommits," ");
    background="145;0;0"
    foreground="255;255;255"
}
{
    # Compare with every given input e.g. commit id
    for (i=1; i <= n; i++) {
        if (match($0,arrayCommits[i])) {
            # Remove any ANSI color escape sequence for matching row
            gsub("\x1b\\[[0-9;]*m","",$0)
            # Create ANSI color escape sequence for whole row
            $0 = sprintf("\x1b[48;2;%sm\x1b[38;2;%sm%s\x1b[0m\x1b[0m",
                         background,
                         foreground,
                         $0);
            break;
        }
    }
    printf("%s\n", $0);z
}
