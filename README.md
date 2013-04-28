FlawDetector [![Build Status](https://secure.travis-ci.org/ginriki/flaw_detector.png)][Continuous Integration]
=============
FlawDetector is a tool to detect ruby code's flaw with static analysis.
To detect code's flaw, it analyze RubyVM bytecode which is compiled from ruby code.

FlawDetector is similer to FindBugs which is a tool to detect java code's flaw.
For details of FindBugs, refer to references section in this text file.

Usage
-------
```shell
  flaw_detector [-f outfille] [--help] rbfile ...
```

Example
-------
```shell
$ flaw_detector -f result.csv sample/flaw_in_code.rb
```

Command Result
-------
Currently, FlawDetector supports only CSV format result.
Result examples is as follows:
```file
$ cat result.csv
msgid,file,line,short_desc,long_desc,details
RCN_REDUNDANT_FALSECHECK_OF_FALSE_VALUE,sample/flaw_in_code.rb,4,Redundant falsecheck of value known to be false,Redundant falsecheck of a which is known to be false in LINE:2,This method contains a redundant check of a known false value against the constant false.
NP_ALWAYS_FALSE,sample/flaw_in_code.rb,7,False value missing method received,False value missing method received in a,"A false value, which is NilClass or FalseClass, is received missing method here. This will lead to a NoMethodError when the code is executed."
```

Each line represents a flaw.
If you want to know how flaw can be shown in result, refer to lib/message.rb

Fix and Recheck
------
You should fix source code and recheck it by FlawDetector until "OK" is displaied
```file
$ emacs sample/flaw_in_code.rb
$ cat sample/flaw_in_code.rb
def no_flaw(a)
  if a
    rl = a + 1
  else
    rl = a.to_i + 1
  end
end
$ flaw_detector sample/flaw_in_code.rb
OK
$
```

References
------
 * http://findbugs.sourceforge.net/findbugs2.html
