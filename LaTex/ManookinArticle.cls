
\typeout{Document Class `ManookinArticle' <18-April-2018>.}
\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{ManookinArticle}
  [2018/04/18 revision by RH]

\newif\ifnaturevar

%% Load base class
%\DeclareOption*{\PassOptionsToClass{\CurrentOption}{article}
%\LoadClass[letter, twoside, twocolumn]{article}
\def\@@ptsize{12pt}
\DeclareOption{8pt}{\def\@@ptsize{8pt}}
\DeclareOption{9pt}{\def\@@ptsize{9pt}}
\DeclareOption{10pt}{\def\@@ptsize{10pt}}
\DeclareOption{11pt}{\def\@@ptsize{11pt}}
\DeclareOption{12pt}{\def\@@ptsize{12pt}}
\DeclareOption{nature}{\naturevartrue}
\DeclareOption*{\PassOptionsToClass{\CurrentOption}{article}}

\ProcessOptions\relax
\LoadClass[letter, twoside, twocolumn,\@@ptsize]{article}

\RequirePackage{amsmath,amsfonts,amssymb}
\RequirePackage{mathptmx}

\RequirePackage{xcolor}
\RequirePackage{authblk}
\RequirePackage[latin1,utf8]{inputenc}
\RequirePackage[english]{babel}
\RequirePackage{lmodern}
\RequirePackage{siunitx}
\RequirePackage{textgreek}
\RequirePackage{gensymb}
\RequirePackage{textcomp}
\RequirePackage[version=4]{mhchem}
\RequirePackage[T1]{fontenc}
\RequirePackage{lettrine} % For dropped capitals
\RequirePackage[rightcaption]{sidecap} % For sidecaptions
\RequirePackage[misc]{ifsym} % For the \Letter symbol
\RequirePackage{bbding} % For the \Envelope symbol
\RequirePackage[twoside,%
				letterpaper,includeheadfoot,%
				layoutsize={8.375in,10.875in},%layoutsize={8.125in,10.875in}
                layouthoffset=0.0625in,%0.1875in
                layoutvoffset=0.0625in,%
                left=50pt,%
                right=50pt,%
                top=50pt,% 10pt provided by headsep
                bottom=50pt,%
                headheight=0pt,% No Header
                headsep=10pt,%
                footskip=25pt]{geometry}

\RequirePackage[labelfont={bf,rm},%labelfont={bf,sf}
                labelsep=period,%
                figurename=Figure]{caption}
%\RequirePackage[switch,modulo]{lineno}
\RequirePackage[switch]{lineno}
%\RequirePackage{lineno}

\DeclareUnicodeCharacter{00B0}{\degree}

%% Hyperlinking
\RequirePackage[colorlinks=true, 
                allcolors=black,
                citecolor=black,
                linkcolor=black, % This sets the color for refs/autorefs
                filecolor=black,
                urlcolor=blue,
                citecolor=black]{hyperref}
\urlstyle{same} %% rm, sf, tt, same

\RequirePackage{graphicx,xcolor}

% Fonts
%\RequirePackage[scaled]{helvet}
\renewcommand{\sfdefault}{phv}
%\RequirePackage{librebaskerville}
%\RequirePackage{baskervald}
%\RequirePackage{palatino}
\renewcommand{\rmdefault}{qpl} %qcs mbv qpl ppl
%\fontfamily{pnb}\selectfont
\renewcommand{\ttdefault}{cmtt}



%\renewcommand\rmdefault{librebaskerville}
%\renewcommand{\sfdefault}{phv}
% \renewcommand\ttdefault{lmtt}

\renewcommand{\footnotesize}{\fontsize{10pt}{12pt}\selectfont}

% Font specification for different components
\newcommand{\shorttitle}[1]{\def\@shorttitle{#1}}
\newcommand{\leadauthor}[1]{\def\@leadauthor{#1}}
\newcommand{\footerfont}{\normalfont\sffamily\fontsize{7}{9} \selectfont}
\newcommand{\titlefont}{\fontfamily{lmss}\bfseries\fontsize{12pt}{14pt}\selectfont}
\newcommand{\dropcapfont}{\fontfamily{lmss}\bfseries\fontsize{12pt}{14pt}\selectfont}
\newcommand{\datesfont}{\normalfont\sffamily\fontsize{7}{8}\selectfont}

\setlength{\affilsep}{8.5pt} % 16.5pts between base of author line and base of affil line
\renewcommand\Authfont{\normalfont\normalsize\selectfont}
\renewcommand\Affilfont{\normalfont\small\selectfont}
\makeatletter
\renewcommand\Authands{, and }

% Separate line spacing for the captions.
\captionsetup[figure]{font={stretch=1.2}} 

\topmargin      -16.0mm
\textheight       243mm
\columnsep          7mm
\headsep          6.3mm
\headheight        12pt
\lineskip           1pt
\normallineskip     1pt
% Set line spacing
\def\baselinestretch{1.4} 

% Set spacing between columns.
\setlength\columnsep{7mm}

% Set the width of the abstract box
\renewenvironment{quote}{
    \list{}{
        \leftmargin 1.5cm
        \rightmargin \leftmargin
    }
    \item\relax
}
{\endlist}

% Custom title to remove date
\def\@maketitle{%
  \newpage
  \null
  \vskip 2em%
  \begin{center}%
  \let \footnote \thanks
    {\Large\bfseries \@title \par}%
    \vskip 1.5em%
    {\large
      \lineskip .5em%
      \begin{tabular}[t]{c}%
        \@author
      \end{tabular}\par}%
    \vskip 1em%
    %{\large \@date}%
  \end{center}%
  \par
  \vskip 1.5em}

\def\keywords{%\vspace{-.3em}
\Affilfont\bfseries}
\def\endkeywords{\vspace{0.3em}\par\normalsize}

\newcommand{\at}{\makeatletter @\makeatother}
\def\corrauthor{\vspace{-.3em}
\noindent\Affilfont\bfseries  Correspondence:\itshape}
\def\endcorrauthor{\vspace{0.3em}\par\normalsize}


% \ifnaturevar
\let\orgautoref\autoref
\renewcommand{\autoref}[1]{\def\figureautorefname{\bfseries Figure}\orgautoref{#1}}
% \renewcommand{\autoref}[1]{\def\equationautorefname{Eq.}\orgautoref{#1}}
% \fi


% Abstract
\renewenvironment{abstract}
{ \vspace{-1.5cm}
    \begin{quote}
    \noindent \rule{\linewidth}{0.5pt}\par{\bfseries \MakeUppercase \abstractname.}}
    {\vspace{-1.5cm}\noindent \rule{\linewidth}{0pt}\end{quote}}

\renewenvironment{keywords}
{\begin{quote} \noindent \rule{\linewidth}{0pt}\par{\bfseries Keywords:}}
{\vspace{-1cm}\noindent \rule{\linewidth}{0pt}\end{quote}}

\renewenvironment{corrauthor}
{\vspace{-1cm}\begin{quote} \noindent \rule{\linewidth}{0pt}\par{\bfseries Correspondence:}\itshape}
{\noindent\newline \rule{\linewidth}{0.5pt}\end{quote}\vspace{0.5cm}}

% Sections
\RequirePackage{sectsty}
\sectionfont{\normalsize\normalfont\bfseries\MakeUppercase}
\renewcommand\section{\@startsection {section}{1}{\z@}%
      {-3.5ex \@plus -1ex \@minus -.2ex} % beforeskip
      {0.1ex} %{0.1ex \@plus -0.2ex} % afterskip
      {\normalfont\normalsize\bfseries\SS@sectfont}}
\subsectionfont{\normalsize\normalfont\bfseries}
\renewcommand\subsection{\@startsection{subsection}{2}{\z@}%
      {-3.25ex\@plus -1ex \@minus -.2ex}%
      {0.1ex}%
      {\normalfont\normalsize\bfseries\SS@subsectfont}}

% Undo numbering for sections.
\makeatletter
\renewcommand{\@seccntformat}[1]{}
\makeatother

% Supplementary material
\newcommand{\beginsupplement}{%
        \setcounter{table}{0}
        \renewcommand{\thetable}{S\arabic{table}}%
        \setcounter{figure}{0}
        \renewcommand{\thefigure}{S\arabic{figure}}
     }



% Bibliography
\RequirePackage{chapterbib}
\ifnaturevar
    \RequirePackage[super,comma,sort&compress]{natbib}
    \bibliographystyle{unsrtnat}
\else
    \RequirePackage{natbib}
    \bibliographystyle{apalike}
\fi
\setlength{\bibsep}{0.0pt}
\renewcommand\bibfont{\normalfont\normalsize\selectfont} 

% Equations
\makeatletter 
\renewcommand\@biblabel[1]{ #1.} % Remove brackets from label
\def\tagform@#1{\maketag@@@{(\ignorespaces#1\unskip\@@italiccorr)}}
\renewcommand{\eqref}[1]{\textup{{\normalfont Equation~\ref{#1}}\normalfont}}

% Header/Footer for page
\RequirePackage{fancyhdr} % Custom headers/footers
\pagestyle{fancy}		  % Enables the custom headers/footers
\fancyhf{}

\rhead{\small\normalfont\@leadauthor \ifnum \value{authors} > 1\hspace{2pt}\textit{et al.}\fi}
\lhead{\small\normalfont\@shorttitle}
\rfoot{\small\normalfont\today \hspace{7pt}|\hspace{7pt} \thepage}
\cfoot{}
\renewcommand{\headrulewidth}{0pt}

\fancypagestyle{plain}{
    \fancyhf{}
    \fancyfoot[R]{\small\normalfont\today \hspace{7pt}|\hspace{7pt} \thepage}
}

\endinput

