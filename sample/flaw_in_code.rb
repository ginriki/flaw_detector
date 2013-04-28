def flaw(a)
  if a
    rl = a + 1
  elsif a      #**RCN_REDUNDANT_FALSECHECK_OF_FALSE_VALUE,a,2**
    rl = 1 + a 
  else
    rl = a + 1 #**NP_ALWAYS_FALSE,a**
  end
end
