# The consistency of New Foundations

[![](https://github.com/leanprover-community/con-nf/actions/workflows/build.yml/badge.svg?branch=master)](https://github.com/leanprover-community/con-nf/actions/workflows/build.yml)

The purpose of this community-owned repository is to *digitise* some mathematical definitions, theorem statements and theorem proofs. Digitisation, or formalisation, is a process where the source material, typically a mathematical textbook or a pdf file or website or video, is transformed into definitions in a target system consisting of a computer implementation of a logical theory (such as set theory or type theory).

## The source

The definitions, theorems and proofs in this repository are taken from Randall Holmes [newattempt.pdf](https://randall-holmes.github.io/Nfproof/newattempt.pdf), claiming to prove the consistency of Quine's New Foundations axiom system.

## The target

The formal system which we are using as a target system is Lean's dependent type theory. Lean is a project being developed at Microsoft Research by Leonardo de Moura and his team. Our formalisation could not have even started without a major classical mathematical library backing it up, and so we chose Lean 3 as the engine behind the project. Note that Lean 4's type theory is the same as Lean 3's type theory, however porting 800K lines of mathematical library between languages is a *highly* nontrivial endeavour.

## How to browse this repository

### Blueprint

Below we explain how to engage with the Lean code directly.
We also provide a [blueprint](https://leanprover-community.github.io/con-nf/)
including a [dependency graph](https://leanprover-community.github.io/con-nf/dep_graph.html)
of the main ingredients in the repository.
This blueprint is developed in sync with the Lean formalization,
and will hence see frequent updates during the length of the project.

### Getting the project

At the moment, the recommended way of browsing this repository,
is by using a Lean development environment.
Crucially, this will allow you to introspect Lean's "Goal state" during proofs,
and easily jump to definitions or otherwise follow paths through the code.

We are looking into ways to setup an online interactive website
that will provide the same experience without the hassle of installing a complete
Lean development environment.

For the time being: please use the
[installation instructions](https://leanprover-community.github.io/get_started.html#regular-install)
to install Lean and a supporting toolchain.
After that, download and open a copy of the repository
by executing the following command in a terminal:
```
leanproject get con-nf
code con-nf
```
For detailed instructions on how to work with Lean projects,
see [this](https://leanprover-community.github.io/install/project.html). The script `scripts/get-cache.sh`
in the folder `con-nf` will download the `olean` files created by our continuous integration. This
will save you some time by not havig to do `leanproject build`.

### Reading the project

With the project opened in VScode,
you are all set to start exploring the code.
There are two pieces of functionality that help a lot when browsing through Lean code:

* "Go to definition": If you right-click on a name of a definition or lemma
  (such as `normal_filter`, or `clans`), then you can choose "Go to definition" from the menu,
  and you will be taken to the relevant location in the source files.
  This also works by `Ctrl`-clicking on the name.
* "Goal view": in the event that you would like to read a *proof*,
  you can step through the proof line-by-line,
  and see the internals of Lean's "brain" in the Goal window.
  If the Goal window is not open,
  you can open it by clicking on one of the icons in the top right hand corner.

### Organization of the project

* The Lean code is contained in the directory `src/`.

## Brief note on type theory

Lean is based on type theory,
which means that some things work slightly differently from set theory.
We highlight two syntactical differences.

* Firstly, the element-of relation (`∈`) plays no fundamental role.
  Instead, there is a typing judgment (`:`).

  This means that we write `x : X` to say that "`x` is a term of type `X`"
  instead of "`x` is an element of the set `X`".
  Conveniently, we can write `f : X → Y` to mean "`f` has type `X → Y`",
  in other words "`f` is a function from `X` to `Y`".

* Secondly, type theorists do not use the mapsto symbol (`↦`),
  but instead use lambda-notation.
  This means that we can define the square function on the integers via
  `λ x, x^2`, which translates to `x ↦ x^2` in set-theoretic notation.
  For more information about `λ`, see the Wikipedia page on
  [lambda calculus](https://en.wikipedia.org/wiki/Lambda_calculus).

For a more extensive discussion of type theory,
see the dedicated
[page](https://leanprover-community.github.io/lean-perfectoid-spaces/type_theory.html)
on the perfectoid project website.

## Source reference

`[newattempt]` : https://randall-holmes.github.io/Nfproof/newattempt.pdf

[newattempt]: https://randall-holmes.github.io/Nfproof/newattempt.pdf