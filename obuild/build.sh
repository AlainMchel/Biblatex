#!/usr/bin/env bash

usage () {
echo "Usage:

build.sh help
build.sh install <version> <tds_root>
build.sh uninstall <tds_root>
build.sh builddist|builddocs|build <version>
build.sh testbibtex [file]|testbiber [file]|test [file]|testoutput 
build.sh upload <version> <targetfolder>
build.sh showdiff <filewithissues>

If <targetfolder> is missing, upload to folder \"biblatex-<version>\" folder

Examples: 
obuild/build.sh install 3.18 ~/texmf/
obuild/build.sh uninstall ~/texmf/
obuild/build.sh build 3.18
obuild/build.sh build 4.0
obuild/build.sh upload 4.0 development
obuild/build.sh upload 4.0 multiscript

\"build test\" runs all of the example files (in a temp dir) and puts errors in a log:

obuild/example_errs_biber.txt
obuild/example_errs_bibtex.txt

You should run the \"build.sh install\" before test as it uses the installed biblatex and biber

\"build testoutput\" should be run after \"test\"/\"testbibtex\"/\"testbiber\" and will compare
at a low level the differences between the reference example PDFs and those generated by the test.

"
}

if [[ ! -e obuild/build.sh ]]
then
  echo "Please run in the root of the distribution tree" 1>&2
  exit 1
fi

if [[ "$1" == "help" ]]
then
  usage
  exit 1
fi

if [[ "$1" == "uninstall" && -z "$2" ]]
then
  usage
  exit 1
fi

if [[ "$1" == "install" && ( -z "$2" || -z "$3" ) ]]
then
  usage
  exit 1
fi

if [[ "$1" == "build" && -z "$2" ]]
then
  usage
  exit 1
fi

if [[ "$1" == "upload" && -z "$2" ]]
then
  usage
  exit 1
fi

declare VERSION=$2
declare VERSIONM=$(echo -n "$VERSION" | perl -nE 'say s/^(\d+\.\d+)[a-z]/$1/r')
declare DATE=$(date '+%Y/%m/%d')
declare ERRORS=0
declare SCRIPTPATH=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)
declare PFPATH="$SCRIPTPATH/.FILEPOSTFIX"
declare PACKAGEEXT=$(cat $PFPATH)
declare PACKAGENAME="biblatex"

if [[ ! -z "$PACKAGEEXT" ]]
then
    echo -e "Using file postfix '$PACKAGEEXT' from:\n$PFPATH"
fi

if [[ "$1" == "uninstall" ]]
then
  \rm -f $2/biber/bltxml/biblatex/biblatex-examples.bltxml
  \rm -f $2/bibtex/bib/biblatex/biblatex-examples.bib
  \rm -f $2/bibtex/bst/biblatex/biblatex.bst
  \rm -f $2/doc/latex/biblatex/README
  \rm -f $2/doc/latex/biblatex/CHANGES.md
  \rm -f $2/doc/latex/biblatex/biblatex.pdf
  \rm -f $2/doc/latex/biblatex/biblatex.tex
  for file in obuild/tds/doc/latex/biblatex/examples/*
  do
     \rm -f $2/doc/latex/biblatex/examples/$(basename -- "$file")
  done
  (cd obuild/tds/tex/latex/biblatex && for file in $(find * -type f)
  do
     \rm -f $2/tex/latex/biblatex/$file
  done)
  exit 0
fi

if [[ "$1" == "upload" ]]
then
    if [[ -e obuild/biblatex-$VERSION.tds.tgz ]]
    then
      if [ -z ${3+x} ]
      then
        scp obuild/biblatex-"$VERSION".*tgz philkime,biblatex@frs.sourceforge.net:/home/frs/project/biblatex/biblatex-"$VERSIONM"/
        scp doc/latex/biblatex/CHANGES.md philkime,biblatex@frs.sourceforge.net:/home/frs/project/biblatex/biblatex-"$VERSIONM"/
      else
        scp obuild/biblatex-"$VERSION".*tgz philkime,biblatex@frs.sourceforge.net:/home/frs/project/biblatex/$3/
        scp doc/latex/biblatex/CHANGES.md philkime,biblatex@frs.sourceforge.net:/home/frs/project/biblatex/$3/
      fi
    exit 0
  fi
fi

# Copy individual files, preserving directory paths and adding any
# alternative version extension to the filename
# This is so we can build parallel installs of the package with a different name
function copy-rename-withstructure {
  for filepath in $(find $1 -type f)
  do
    basefile=$(basename -- "$filepath")
    dirname=$(dirname -- "$filepath" | sed "s|$1||")
    extension="${basefile##*.}"
    filename="${basefile%.*}"
    mkdir -p $2/$dirname
    cp $filepath $2/$dirname/${filename}${PACKAGEEXT}.$extension
  done
}  

# Copy individual files, adding any
# alternative version extension to the filename
# This is so we can build parallel installs of the package with a different name
function copy-rename {
  # Last argument is target
  local target=${@: -1}
  # All but last argument
  for filepath in ${@::${#@}}
  do
    basefile=$(basename -- "$filepath")
    extension="${basefile##*.}"
    filename="${basefile%.*}"
    cp $filepath $target/${filename}${PACKAGEEXT}.$extension
  done
}

if [[ "$1" == "builddist" || "$1" == "build" || "$1" == "install" ]]
then
  find . -name \*~ -print0 | xargs -0 rm >/dev/null 2>&1
  # tds
  [[ -e obuild/tds ]] || mkdir obuild/tds
  \rm -rf obuild/tds/*
  copy-rename-withstructure bibtex obuild/tds/bibtex
  copy-rename-withstructure biber obuild/tds/biber
  mkdir -p obuild/tds/doc/latex/$PACKAGENAME/examples
  mkdir -p obuild/tds/tex/latex/$PACKAGENAME
  cp doc/latex/biblatex/README obuild/tds/doc/latex/$PACKAGENAME/README$PACKAGEEXT
  cp doc/latex/biblatex/CHANGES.md obuild/tds/doc/latex/$PACKAGENAME/CHANGES$PACKAGEEXT.md
  cp doc/latex/biblatex/biblatex.pdf obuild/tds/doc/latex/$PACKAGENAME/$PACKAGENAME$PACKAGEEXT.pdf 2>/dev/null
  cp doc/latex/biblatex/biblatex.tex obuild/tds/doc/latex/$PACKAGENAME/$PACKAGENAME$PACKAGEEXT.tex
  copy-rename-withstructure doc/latex/biblatex/examples obuild/tds/doc/latex/$PACKAGENAME/examples
  copy-rename-withstructure tex/latex/biblatex obuild/tds/tex/latex/$PACKAGENAME
  cp obuild/tds/bibtex/bib/biblatex/biblatex-examples$PACKAGEEXT.bib obuild/tds/doc/latex/$PACKAGENAME/examples/
  cp obuild/tds/biber/bltxml/biblatex/biblatex-examples$PACKAGEEXT.bltxml obuild/tds/doc/latex/$PACKAGENAME/examples/

  # Set correct packagename in test files
  for f in obuild/tds/doc/latex/$PACKAGENAME/examples/*.tex
  do
      perl -pi -e "s/\{$PACKAGENAME\}/\{$PACKAGENAME$PACKAGEEXT\}/g" $f
  done
  
  # flat
  [[ -e obuild/flat ]] || mkdir obuild/flat
  \rm -rf obuild/flat/*
  mkdir -p obuild/flat/$PACKAGENAME/bibtex/{bib,bst}
  mkdir -p obuild/flat/$PACKAGENAME/bibtex/bib/biblatex
  mkdir -p obuild/flat/$PACKAGENAME/biber/bltxml
  mkdir -p obuild/flat/$PACKAGENAME/doc/examples
  mkdir -p obuild/flat/$PACKAGENAME/latex/{cbx,bbx,lbx}
  cp doc/latex/biblatex/README obuild/flat/$PACKAGENAME/README$PACKAGEEXT
  cp doc/latex/biblatex/CHANGES.md obuild/flat/$PACKAGENAME/CHANGES$PACKAGEEXT.md
  cp bibtex/bib/biblatex/biblatex-examples.bib obuild/flat/$PACKAGENAME/bibtex/bib/biblatex/biblatex-examples$PACKAGEEXT.bib
  cp bibtex/bib/biblatex/biblatex-examples.bib obuild/flat/$PACKAGENAME/doc/examples/biblatex-examples$PACKAGEEXT.bib
  cp biber/bltxml/biblatex/biblatex-examples.bltxml obuild/flat/$PACKAGENAME/biber/bltxml/biblatex-examples$PACKAGEEXT.bltxml
  cp biber/bltxml/biblatex/biblatex-examples.bltxml obuild/flat/$PACKAGENAME/doc/examples/biblatex-examples$PACKAGEEXT.bltxml
  cp bibtex/bst/biblatex/biblatex.bst obuild/flat/$PACKAGENAME/bibtex/bst/$PACKAGENAME$PACKAGEEXT.bst
  cp doc/latex/biblatex/biblatex.pdf obuild/flat/$PACKAGENAME/doc/$PACKAGENAME$PACKAGEEXT.pdf 2>/dev/null
  cp doc/latex/biblatex/biblatex.tex obuild/flat/$PACKAGENAME/doc/$PACKAGENAME$PACKAGEEXT.tex
  copy-rename tex/latex/biblatex/*.def obuild/flat/$PACKAGENAME/latex
  copy-rename tex/latex/biblatex/*.sty obuild/flat/$PACKAGENAME/latex
  copy-rename tex/latex/biblatex/*.cfg obuild/flat/$PACKAGENAME/latex
  copy-rename-withstructure doc/latex/biblatex/examples obuild/flat/$PACKAGENAME/doc/examples
  copy-rename-withstructure tex/latex/biblatex/cbx obuild/flat/$PACKAGENAME/latex/cbx
  copy-rename-withstructure tex/latex/biblatex/bbx obuild/flat/$PACKAGENAME/latex/bbx
  copy-rename-withstructure tex/latex/biblatex/lbx obuild/flat/$PACKAGENAME/latex/lbx

  # Set correct packagename in test files
  for f in obuild/flat/$PACKAGENAME/doc/examples/*.tex
  do
    perl -pi -e "s/\{$PACKAGENAME\}/\{$PACKAGENAME$PACKAGEEXT\}/g" $f
  done
  
  perl -pi -e "s|\\\\abx\\@date\{[^\}]+\}|\\\\abx\\@date\{$DATE\}|;s|\\\\abx\\@version\{[^\}]+\}|\\\\abx\\@version\{$VERSION\}|;" obuild/tds/tex/latex/$PACKAGENAME/biblatex$PACKAGEEXT.sty obuild/flat/$PACKAGENAME/latex/biblatex$PACKAGEEXT.sty

  # Put file postfix in places it's needed
  perl -pi -e "s/(\\\def\\\abx\\@filespf)\\{\\}/\$1\{$PACKAGEEXT\}/" obuild/tds/tex/latex/$PACKAGENAME/biblatex$PACKAGEEXT.sty obuild/flat/$PACKAGENAME/latex/biblatex$PACKAGEEXT.sty
  perl -pi -e "s/(\\\Provides(?:ExplPackage|Package|File))\s*\\{([^.}]+)(\.[^}]+)?\\}(.*)/\$1\{\$2$PACKAGEEXT\$3\}\$4/" obuild/tds/tex/latex/$PACKAGENAME/*$PACKAGEEXT.* obuild/flat/$PACKAGENAME/latex/*$PACKAGEEXT.*
  perl -pi -e "s/(\\\Provides(?:ExplPackage|Package|File))\s*\\{([^.}]+)(\.[^}]+)?\\}(.*)/\$1\{\$2$PACKAGEEXT\$3\}\$4/" obuild/tds/tex/latex/$PACKAGENAME/{cbx,bbx,lbx}/*$PACKAGEEXT.* obuild/flat/$PACKAGENAME/latex/{cbx,bbx,lbx}/*$PACKAGEEXT.*

  # Can't do in-place on windows (cygwin)
  find obuild/tds -name \*.bak -print0 | xargs -0 \rm -rf
  find obuild/tds -name auto -print0 | xargs -0 \rm -rf

  echo "Created build trees ..."
fi

if [[ "$1" == "install" ]]
then
  \cp -rf obuild/tds/* $3

  echo "Installed TDS build tree ..."
fi

if [[ "$1" == "builddocs" || "$1" == "build" ]]
then
  cd doc/latex/biblatex || exit

  perl -pi.bak -e 's|DATEMARKER|\\today|;' biblatex.tex

  lualatex --interaction=batchmode biblatex.tex
  lualatex --interaction=batchmode biblatex.tex
  lualatex --interaction=batchmode biblatex.tex

  \rm *.{aux,bbl,bcf,blg,log,run.xml,toc,out,lot} 2>/dev/null

  mv biblatex.tex.bak biblatex.tex

  cp biblatex.pdf ../../../obuild/flat/$PACKAGENAME/doc/$PACKAGENAME$PACKAGEEXT.pdf
  cd ../../.. || exit

  echo
  echo "Created main documentation ..."
fi

if [[ "$1" == "builddist" || "$1" == "build" ]]
then
  \rm -f obuild/biblatex-$VERSION.tds.tgz
  \rm -f obuild/biblatex-$VERSION.tgz
  gnutar zcf obuild/biblatex-$VERSION.tds.tgz -C obuild/tds bibtex biber doc tex
  gnutar zcf obuild/biblatex-$VERSION.tgz -C obuild/flat $PACKAGENAME

  echo "Created packages (flat and TDS) ..."
fi

if [[ "$1" == "testbiber" || "$1" == "testbibtex" || "$1" == "test" ]]
then
  [[ -e obuild/test/examples ]] || mkdir -p obuild/test/examples
  \rm -rf obuild/test/examples/*
  copy-rename doc/latex/biblatex/examples/*.tex obuild/test/examples
  copy-rename doc/latex/biblatex/examples/*.dbx obuild/test/examples
  copy-rename doc/latex/biblatex/examples/*.bib obuild/test/examples
  \rm -f obuild/test/example_errs_biber.txt
  \rm -f obuild/test/example_errs_bibtex.txt
  cd obuild/test/examples || exit

  # Make the bibtex/biber backend test files
  for f in *.tex
  do
    if [[ "$f" < 9* ]] # 9+*.tex examples require biber
    then
      mv $f ${f%$PACKAGEEXT.tex}-biber$PACKAGEEXT.tex
      sed -e 's/backend=biber/backend=bibtex/g' -e 's/\\usepackage\[utf8\]{inputenc}//g' ${f%$PACKAGEEXT.tex}-biber$PACKAGEEXT.tex > ${f%$PACKAGEEXT.tex}-bibtex$PACKAGEEXT.tex
    else
      mv $f ${f%$PACKAGEEXT.tex}-biber$PACKAGEEXT.tex
    fi
  done

  # Set correct packagename in test files
  for f in *.tex
  do
    perl -pi -e "s/\{$PACKAGENAME\}/\{$PACKAGENAME$PACKAGEEXT\}/g" $f
  done
  
  if [[ "$1" == "testbibtex" || "$1" == "test" ]]
  then
    for f in *-bibtex$PACKAGEEXT.tex
    do
      if [[ "$2" != "" && "$2" != "$f" ]]
      then
        continue
      fi
      bibtexflag=false
      echo -n "File (bibtex): $f ... "
      exec 4>&1 7>&2 # save stdout/stderr
      exec 1>/dev/null 2>&1 # redirect them from here
      # Twice due to two-pass @set handling in bibtex
      pdflatex --interaction=batchmode ${f%.tex}
      bibtex ${f%.tex}
      pdflatex --interaction=batchmode ${f%.tex}
      bibtex ${f%.tex}
      # Any refsections? If so, need extra bibtex runs
      for sec in ${f%.tex}*-blx.aux
      do
        bibtex $sec
      done
      pdflatex --interaction=batchmode ${f%.tex}
      # Need a second bibtex run to pick up set members
      if [[ $f == 20-indexing-* || $f == 21-indexing-* ]]
      then
        makeindex -o ${f%.tex}.ind ${f%.tex}.idx
        makeindex -o ${f%.tex}.nnd ${f%.tex}.ndx
        makeindex -o ${f%.tex}.tnd ${f%.tex}.tdx
      fi
      # This example uses sub-indexes
      if [[ $f == 22-indexing-* ]]
      then
          makeindex -o name-title.ind name-title.idx
          makeindex -o year-title.ind year-title.idx
      fi
      bibtex ${f%.tex}
      pdflatex --interaction=batchmode ${f%.tex}
      exec 1>&4 4>&- # restore stdout
      exec 7>&2 7>&- # restore stderr
      # Now look for latex/bibtex errors and report ...
      echo "==============================
Test file: $f

PDFLaTeX errors/warnings
------------------------"  >> ../example_errs_bibtex.txt
      # Use GNU grep to get PCREs as we want to ignore the legacy bibtex
      # warning in 3.4+
      grep -P '(?:[Ee]rror|[Ww]arning): (?!Using fall-back|prefixnumbers option|The option '\''labelprefix'\''|Empty biblist|Font|Command \\mark|Writing or overwriting file|\S+ is being set as the default font)' ${f%.tex}.log >> ../example_errs_bibtex.txt
      if [[ $? -eq 0 ]]; then bibtexflag=true; fi
      grep -E -A 3 '^!' ${f%.tex}.log >> ../example_errs_bibtex.txt
      if [[ $? -eq 0 ]]; then bibtexflag=true; fi
      echo >> ../example_errs_bibtex.txt
      echo "BibTeX errors/warnings" >> ../example_errs_bibtex.txt
      echo "---------------------" >> ../example_errs_bibtex.txt
      # Glob as we need to check all .blgs in case of refsections
      grep -i -e "(error|warning)[^\$]" ${f%.tex}*.blg >> ../example_errs_bibtex.txt
      if [[ $? -eq 0 ]]; then bibtexflag=true; fi
      echo "==============================" >> ../example_errs_bibtex.txt
      echo >> ../example_errs_bibtex.txt
      if $bibtexflag 
      then
          ERRORS=1
          echo -e "\033[0;31mERRORS\033[0m"
      else
        echo "OK"
      fi
    done
  fi

  if [[ "$1" == "testbiber" || "$1" == "test" ]]
  then
    for f in *-biber$PACKAGEEXT.tex
    do
      if [[ "$2" != "" && "$2" != "$f" ]]
      then
        continue
      fi

      biberflag=false      
      if [[ "$f" < 9* ]] # 9+*.tex examples require biber and we want UTF-8 support
      then
          declare TEXENGINE=pdflatex
          declare BIBEROPTS='--output_safechars --onlylog'
      else
          if [[ "$f" == "93-nameparts-biber$PACKAGEEXT.tex" ]] # Needs xelatex
          then
             declare TEXENGINE=xelatex
             declare BIBEROPTS='--onlylog'
          else
             declare TEXENGINE=lualatex
             declare BIBEROPTS='--onlylog'
          fi
      fi
      echo -n "File (biber): $f ... "
      exec 4>&1 7>&2 # save stdout/stderr
      exec 1>/dev/null 2>&1 # redirect them from here
      $TEXENGINE --interaction=batchmode ${f%.tex}
      # using output safechars as we are using fontenc and ascii in the test files
      # so that we can use the same test files with bibtex which only likes ascii
      # biber complains when outputting ascii from it's internal UTF-8
      biber $BIBEROPTS --onlylog ${f%.tex}
      $TEXENGINE --interaction=batchmode ${f%.tex}
      if [[ $f == 20-indexing-* || $f == 21-indexing-* ]]
      then
        makeindex -o ${f%.tex}.ind ${f%.tex}.idx
        makeindex -o ${f%.tex}.nnd ${f%.tex}.ndx
        makeindex -o ${f%.tex}.tnd ${f%.tex}.tdx
      fi
      # This example uses sub-indexes
      if [[ $f == 22-indexing-* ]]
      then
          makeindex -o name-title.ind name-title.idx
          makeindex -o year-title.ind year-title.idx
      fi
      $TEXENGINE --interaction=batchmode ${f%.tex}
      exec 1>&4 4>&- # restore stdout
      exec 7>&2 7>&- # restore stderr
  
      # Now look for latex/biber errors and report ...
      echo "==============================
Test file: $f

$TEXENGINE errors/warnings
------------------------"  >> ../example_errs_biber.txt
      grep -P '(?:[Ee]rror|[Ww]arning): (?!Using fall-back|prefixnumbers option|The option '\''labelprefix'\''|Empty biblist|Font|Command \\mark|Writing or overwriting file|\S+ is being set as the default font)' ${f%.tex}.log >> ../example_errs_biber.txt
      if [[ $? -eq 0 ]]; then biberflag=true; fi
      grep -E -A 3 '^!' ${f%.tex}.log >> ../example_errs_biber.txt
      if [[ $? -eq 0 ]]; then biberflag=true; fi
      echo >> ../example_errs_biber.txt
      echo "Biber errors/warnings" >> ../example_errs_biber.txt
      echo "---------------------" >> ../example_errs_biber.txt
      grep -i -e "(error|warn)" ${f%.tex}.blg >> ../example_errs_biber.txt
      if [[ $? -eq 0 ]]; then biberflag=true; fi
      echo "==============================" >> ../example_errs_biber.txt
      echo >> ../example_errs_biber.txt
      if $biberflag 
      then
          ERRORS=1
          echo -e "\033[0;31mERRORS\033[0m"
      else
        echo "OK"
      fi
    done
  fi
  cd ../../..
  exit $ERRORS
fi

if [[ "$1" == "testoutput" ]]
then
  mkdir -p obuild/failedpdfs
  for f in obuild/test/examples/*.pdf
  do
    echo -n "Checking `basename $f` ... "
    diff-pdf "doc/latex/biblatex/examples/`basename ${f%$PACKAGEEXT.pdf}.pdf`" $f 2>/dev/null
    if [[ $? -eq 0 ]]
    then
      echo "PASS"
    else
        ERRORS=1
        cp $f obuild/failedpdfs/
        echo -e "\033[0;31mFAIL\033[0m"
    fi
  done
  exit $ERRORS
fi
