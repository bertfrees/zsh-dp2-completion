zsh-dp2-completion
==================

[Zsh][] auto completion for the [Daisy Pipeline 2][pipeline] command line a.k.a. [dp2][]

Installation
------------

1.  Download `zsh-dp2-completion.zsh` (e.g. to `~/.zsh-dp2-completion.zsh`) and put the following line in your `.zshrc`:

        source ~/.zsh-dp2-completion.zsh
 
    Or, use it as a [oh-my-zsh][] plugin:

        cd $ZSH
        git submodule add git@github.com:bertfrees/zsh-dp2-completion.git custom/plugins/zsh-dp2-completion

    ... and enable it in your `.zshrc`:

        plugins=(... zsh-dp2-completion)

2. Make sure `dp2` is on your $PATH.

Author
------

+ [Bert Frees][bert]

[zsh]: http://www.zsh.org/
[pipeline]: http://code.google.com/p/daisy-pipeline/
[dp2]: https://github.com/daisy-consortium/pipeline-cli
[oh-my-zsh]: https://github.com/robbyrussell/oh-my-zsh
[bert]: http://github.com/bertfrees
