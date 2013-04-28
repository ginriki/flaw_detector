module FlawDetector
  MESSAGE_IDS = {
    "RCN_REDUNDANT_FALSECHECK_WOULD_HAVE_BEEN_A_NPE" => { # @todo rewrite it to meaningful message
      :short_desc => "Falsecheck of value previously dereferenced",
      :long_desc => "Falsecheck of %{0} at %{1} of value previously dereferenced in %{2}",
      :details => "A value is checked here to see whether it is false, but this value can't be false because it was previously dereferenced and if it were false a false pointer exception would have occurred at the earlier dereference. Essentially, this code and the previous dereference disagree as to whether this value is allowed to be false. Either the check is redundant or the previous dereference is erroneous."
    },
    "RCN_REDUNDANT_FALSECHECK_OF_FALSE_VALUE" => {
      :short_desc => "Redundant falsecheck of value known to be false",
      :long_desc => "Redundant falsecheck of %{0} which is known to be false in LINE:%{1}",
      :details => "This method contains a redundant check of a known false value against the constant false."
    },
    "RCN_REDUNDANT_FALSECHECK_OF_TRUE_VALUE" => {
      :short_desc => "Redundant falsecheck of value known to be false",
      :long_desc => "Redundant falsecheck of %{0} which is known to be false in LINE:%{1}",
      :details => "This method contains a redundant check of a known false value against the constant false."
    },
    "NP_ALWAYS_FALSE" => {
      :short_desc => "False value missing method received",
      :long_desc => "False value missing method received in %{0}",
      :details => "A false value, which is NilClass or FalseClass, is received missing method here. This will lead to a NoMethodError when the code is executed."
    },
    "NP_FALSE_ON_SOME_PATH" =>{ # @todo rewrite it to meaningful message
      :short_desc => "Possible false pointer dereference",
      :long_desc => "Possible false pointer dereference in %{0}",
      :details => "There is a branch of statement that, if executed, guarantees that a false value will be dereferenced, which would generate a RuntimeError when the code is executed. Of course, the problem might be that the branch or statement is infeasible and that the false pointer exception can't ever be executed; deciding that is beyond the ability of FlawDetector."
    }
  }

  def make_info(params={})
    info = {}
    info[:msgid] = params[:msgid]
    info[:file] = params[:file]
    info[:line] = params[:line]
    hash = {}
    params[:params].each_with_index do |elem, index|
      hash["%{#{index}}"] = elem
    end
    pattern = Regexp.new(hash.keys.map{|n| Regexp.escape(n)}.join("|"))
    info[:short_desc] = MESSAGE_IDS[info[:msgid]][:short_desc].gsub(pattern, hash)
    info[:long_desc] = MESSAGE_IDS[info[:msgid]][:long_desc].gsub(pattern, hash)
    info[:details] = MESSAGE_IDS[info[:msgid]][:details].gsub(pattern, hash)
    return info                            
  end
end
