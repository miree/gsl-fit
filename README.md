gsl-fit
=======

A command line tool, written in the D programming language, that uses GNU Scientific Library to fit function parameters to data.

Build
=====

```bash
$ dub build
```

Usage Example
=============

```bash
$ gsl-fit data.dat 'a+b*x' a=1 b=1
```
