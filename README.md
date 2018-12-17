# NAME

App::CpanTestReport - Search for CPAN Testers reports by module, distribution or author.

# SYNOPSIS

    $ ./script/cpantestreport daemon --listen http://*:3000

# DESCRIPTION

[App::CpanTestReport](https://metacpan.org/pod/App::CpanTestReport) is a web page where you can search for CPAN Testers
reports by module, distribution or author and see test reports created by
[http://cpantesters.org/](http://cpantesters.org/).

# RESOURCES

- /

    Show a search page.

- /search

    Alias for "/".

- /search?q=JHTHORSEN
- /search?author=JHTHORSEN

    Redirects to author search results.

- /search?dist=Mojolicious
- /search?dist=Mojolicious-8.01
- /search?q=Mojolicious
- /search?q=Mojolicious-8.01

    Redirects to dist search results.

- /author/JHTHORSEN

    Show a summary of all the dists for a given author.

- /dist/Mojolicious

    Redirects to the latest version of [Mojolicious](https://metacpan.org/pod/Mojolicious)

- /dist/Mojolicious-8.01

    Show search results for [Mojolicious](https://metacpan.org/pod/Mojolicious) version 8.01.

- /report/57fffae2-689f-1015-8f24-a8e65f496936

    Show a given test report.

# METHODS

## startup

Called by [Mojolicious](https://metacpan.org/pod/Mojolicious) to start up the web server.

# AUTHOR

Jan Henning Thorsen

# COPYRIGHT AND LICENSE

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

# SEE ALSO

[http://api.cpantesters.org/](http://api.cpantesters.org/),
[https://api.metacpan.org/](https://api.metacpan.org/) and
[https://github.com/cpan-testers/cpantesters-web](https://github.com/cpan-testers/cpantesters-web).
