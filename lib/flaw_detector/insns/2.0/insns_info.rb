module FlawDetector
  module InsnsInfo
    VM_CALL_ARGS_BLOCKARG = (0x01 << 2)

    NOP = 0
    GETLOCAL = 1
    SETLOCAL = 2
    GETSPECIAL = 3
    SETSPECIAL = 4
    GETINSTANCEVARIABLE = 5
    SETINSTANCEVARIABLE = 6
    GETCLASSVARIABLE = 7
    SETCLASSVARIABLE = 8
    GETCONSTANT = 9
    SETCONSTANT = 10
    GETGLOBAL = 11
    SETGLOBAL = 12
    PUTNIL = 13
    PUTSELF = 14
    PUTOBJECT = 15
    PUTSPECIALOBJECT = 16
    PUTISEQ = 17
    PUTSTRING = 18
    CONCATSTRINGS = 19
    TOSTRING = 20
    TOREGEXP = 21
    NEWARRAY = 22
    DUPARRAY = 23
    EXPANDARRAY = 24
    CONCATARRAY = 25
    SPLATARRAY = 26
    NEWHASH = 27
    NEWRANGE = 28
    POP = 29
    DUP = 30
    DUPN = 31
    SWAP = 32
    REPUT = 33
    TOPN = 34
    SETN = 35
    ADJUSTSTACK = 36
    DEFINED = 37
    CHECKMATCH = 38
    TRACE = 39
    DEFINECLASS = 40
    SEND = 41
    OPT_SEND_SIMPLE = 42
    INVOKESUPER = 43
    INVOKEBLOCK = 44
    LEAVE = 45
    THROW = 46
    JUMP = 47
    BRANCHIF = 48
    BRANCHUNLESS = 49
    GETINLINECACHE = 50
    ONCEINLINECACHE = 51
    SETINLINECACHE = 52
    OPT_CASE_DISPATCH = 53
    OPT_PLUS = 54
    OPT_MINUS = 55
    OPT_MULT = 56
    OPT_DIV = 57
    OPT_MOD = 58
    OPT_EQ = 59
    OPT_NEQ = 60
    OPT_LT = 61
    OPT_LE = 62
    OPT_GT = 63
    OPT_GE = 64
    OPT_LTLT = 65
    OPT_AREF = 66
    OPT_ASET = 67
    OPT_LENGTH = 68
    OPT_SIZE = 69
    OPT_EMPTY_P = 70
    OPT_SUCC = 71
    OPT_NOT = 72
    OPT_REGEXPMATCH1 = 73
    OPT_REGEXPMATCH2 = 74
    OPT_CALL_C_FUNCTION = 75
    BITBLT = 76
    ANSWER = 77
    GETLOCAL_OP__WC__0 = 78
    GETLOCAL_OP__WC__1 = 79
    SETLOCAL_OP__WC__0 = 80
    SETLOCAL_OP__WC__1 = 81
    PUTOBJECT_OP_INT2FIX_O_0_C_ = 82
    PUTOBJECT_OP_INT2FIX_O_1_C_ = 83
    VM_INSTRUCTION_SIZE = 84

    RET_NUM = [
               0,
               1,
               0,
               1,
               0,
               1,
               0,
               1,
               0,
               1,
               0,
               1,
               0,
               1,
               1,
               1,
               1,
               1,
               1,
               1,
               1,
               1,
               1,
               1,
               1,
               1,
               1,
               1,
               1,
               0,
               2,
               1,
               2,
               1,
               1,
               1,
               1,
               1,
               1,
               0,
               1,
               1,
               1,
               1,
               1,
               1,
               1,
               0,
               0,
               0,
               1,
               1,
               1,
               0,
               1,
               1,
               1,
               1,
               1,
               1,
               1,
               1,
               1,
               1,
               1,
               1,
               1,
               1,
               1,
               1,
               1,
               1,
               1,
               1,
               1,
               0,
               1,
               1,
               1,
               1,
               0,
               0,
               1,
               1,
              ]  

    def insn_num(insn_name)
      return RubyVM::INSTRUCTION_NAMES.index(insn_name.to_s)
    end

    def insn_ret_num(opcode_index)
      return RET_NUM[opcode_index]
    end

    def insn_stack_increase(opcode_index, opes) 
      depth = 0
      case opcode_index
      when NOP
        return depth + 0
      when GETLOCAL
        return depth + 1
      when SETLOCAL
        return depth + -1
      when GETSPECIAL
        return depth + 1
      when SETSPECIAL
        return depth + -1
      when GETINSTANCEVARIABLE
        return depth + 1
      when SETINSTANCEVARIABLE
        return depth + -1
      when GETCLASSVARIABLE
        return depth + 1
      when SETCLASSVARIABLE
        return depth + -1
      when GETCONSTANT
        return depth + 0
      when SETCONSTANT
        return depth + -2
      when GETGLOBAL
        return depth + 1
      when SETGLOBAL
        return depth + -1
      when PUTNIL
        return depth + 1
      when PUTSELF
        return depth + 1
      when PUTOBJECT
        return depth + 1
      when PUTSPECIALOBJECT
        return depth + 1
      when PUTISEQ
        return depth + 1
      when PUTSTRING
        return depth + 1
      when CONCATSTRINGS
        inc = 0
        num = opes[0]
        inc += 1 - num
        return depth + inc
      when TOSTRING
        return depth + 0
      when TOREGEXP
        inc = 0
        cnt = opes[1]
        inc += 1 - cnt
        return depth + inc
      when NEWARRAY
        inc = 0
        num = opes[0]
        inc += 1 - num
        return depth + inc
      when DUPARRAY
        return depth + 1
      when EXPANDARRAY
        inc = 0
        num = opes[0]
        flag = opes[1]
        inc += num - 1 + (flag % 2)
        return depth + inc
      when CONCATARRAY
        return depth + -1
      when SPLATARRAY
        return depth + 0
      when NEWHASH
        inc = 0
        num = opes[0]
        inc += 1 - num
        return depth + inc
      when NEWRANGE
        return depth + -1
      when POP
        return depth + -1
      when DUP
        return depth + 1
      when DUPN
        inc = 0
        n = opes[0]
        inc += n
        return depth + inc
      when SWAP
        return depth + 0
      when REPUT
        inc = 0
        inc += 0
        return depth + inc
      when TOPN
        inc = 0
        inc += 1
        return depth + inc
      when SETN
        inc = 0
        inc += 0
        return depth + inc
      when ADJUSTSTACK
        inc = 0
        n = opes[0]
        inc -= n
        return depth + inc
      when DEFINED
        return depth + 0
      when CHECKMATCH
        return depth + -1
      when TRACE
        return depth + 0
      when DEFINECLASS
        return depth + -1
      when SEND
        inc = -opes[0][:orig_argc]
        inc += -1 if (opes[0][:flag] & VM_CALL_ARGS_BLOCKARG) != 0
        return depth + inc
      when OPT_SEND_SIMPLE
        inc = -opes[0][:orig_argc]
        return depth + inc
      when INVOKESUPER
        inc = -opes[0][:orig_argc]
        inc += -1 if (opes[0][:flag] & VM_CALL_ARGS_BLOCKARG) != 0
        return depth + inc
      when INVOKEBLOCK
        inc = 1-opes[0][:orig_argc]
        return depth + inc
      when LEAVE
        return depth + 0
      when THROW
        return depth + 0
      when JUMP
        return depth + 0
      when BRANCHIF
        return depth + -1
      when BRANCHUNLESS
        return depth + -1
      when GETINLINECACHE
        return depth + 1
      when ONCEINLINECACHE
        return depth + 1
      when SETINLINECACHE
        return depth + 0
      when OPT_CASE_DISPATCH
        inc = 0
        inc += -1
        return depth + inc
      when OPT_PLUS
        return depth + -1
      when OPT_MINUS
        return depth + -1
      when OPT_MULT
        return depth + -1
      when OPT_DIV
        return depth + -1
      when OPT_MOD
        return depth + -1
      when OPT_EQ
        return depth + -1
      when OPT_NEQ
        return depth + -1
      when OPT_LT
        return depth + -1
      when OPT_LE
        return depth + -1
      when OPT_GT
        return depth + -1
      when OPT_GE
        return depth + -1
      when OPT_LTLT
        return depth + -1
      when OPT_AREF
        return depth + -1
      when OPT_ASET
        return depth + -2
      when OPT_LENGTH
        return depth + 0
      when OPT_SIZE
        return depth + 0
      when OPT_EMPTY_P
        return depth + 0
      when OPT_SUCC
        return depth + 0
      when OPT_NOT
        return depth + 0
      when OPT_REGEXPMATCH1
        return depth + 0
      when OPT_REGEXPMATCH2
        return depth + -1
      when OPT_CALL_C_FUNCTION
        return depth + 0
      when BITBLT
        return depth + 1
      when ANSWER
        return depth + 1
      when GETLOCAL_OP__WC__0
        return depth + 1
      when GETLOCAL_OP__WC__1
        return depth + 1
      when SETLOCAL_OP__WC__0
        return depth + -1
      when SETLOCAL_OP__WC__1
        return depth + -1
      when PUTOBJECT_OP_INT2FIX_O_0_C_
        return depth + 1
      when PUTOBJECT_OP_INT2FIX_O_1_C_
        return depth + 1
      end
    end
    module_function :insn_num, :insn_ret_num, :insn_stack_increase
  end
end

